#!/bin/bash
set -u

if [[ ! -t 0 || -n "${CI-}" ]]; then
  NONINTERACTIVE=1
fi

abort() {
  printf "%s\n" "$1"
  exit 1
}

# First check OS.
OS="$(uname)"
if [[ "$OS" == "Linux" ]]; then
  COBALT_ON_LINUX=1
elif [[ "$OS" != "Darwin" ]]; then
  abort "This install script does not support non-*nix operating systems."
fi

# Required installation paths.
if [[ -z "${COBALT_ON_LINUX-}" ]]; then
  UNAME_MACHINE="$(/usr/bin/uname -m)"

  if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    # On ARM macOS, this script installs to /opt/cobalt only
    COBALT_PREFIX="/opt/cobalt"
    COBALT_REPOSITORY="${COBALT_PREFIX}"
  else
    # On Intel macOS, this script installs to /usr/local only
    COBALT_PREFIX="/usr/local"
    COBALT_REPOSITORY="${COBALT_PREFIX}/cobalt"
  fi

  STAT="stat -f"
  CHOWN="/usr/sbin/chown"
  CHGRP="/usr/bin/chgrp"
  GROUP="admin"
  TOUCH="/usr/bin/touch"
else
  UNAME_MACHINE="$(uname -m)"

  # On Linux, it installs to /home/cobalt/.cobalt if you have sudo access
  # else ~/.cobalt (which is unsupported).
  COBALT_PREFIX_DEFAULT="/home/cobalt/.cobalt"

  STAT="stat --printf"
  CHOWN="/bin/chown"
  CHGRP="/bin/chgrp"
  GROUP="$(id -gn)"
  TOUCH="/bin/touch"
fi
COBALT_GIT_RAW="https://raw.githubusercontent.com/8o-COLLECTIVE/cobalt/master/src"

# string formatters
if [[ -t 1 ]]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_green="$(tty_mkbold 32)"
tty_yellow="$(tty_mkbold 33)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

COBALT="${tty_blue}cobalt${tty_reset}"

have_sudo_access() {
  local -a args
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    args=("-A")
  elif [[ -n "${NONINTERACTIVE-}" ]]; then
    args=("-n")
  fi

  if [[ -z "${HAVE_SUDO_ACCESS-}" ]]; then
    if [[ -n "${args[*]-}" ]]; then
      SUDO="/usr/bin/sudo ${args[*]}"
    else
      SUDO="/usr/bin/sudo"
    fi
    if [[ -n "${NONINTERACTIVE-}" ]]; then
      ${SUDO} -l mkdir &>/dev/null
    else
      ${SUDO} -v && ${SUDO} -l mkdir &>/dev/null
    fi
    HAVE_SUDO_ACCESS="$?"
  fi

  if [[ -z "${COBALT_ON_LINUX-}" ]] && [[ "$HAVE_SUDO_ACCESS" -ne 0 ]]; then
    abort "Need sudo access on macOS (e.g. the user $USER needs to be an Administrator)!"
  fi

  return "$HAVE_SUDO_ACCESS"
}

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"; do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

info() {
  printf "\n${tty_yellow}%s\n${tty_reset}" "$(chomp "$1")"
}

success() {
  printf "${tty_green}%s\n${tty_reset}" "$(chomp "$1")"
}

warn() {
  printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")"
}

execute() {
  if ! "$@"; then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

execute_sudo() {
  local -a args=("$@")
  if have_sudo_access; then
    if [[ -n "${SUDO_ASKPASS-}" ]]; then
      args=("-A" "${args[@]}")
    fi
    info "/usr/bin/sudo" "${args[@]}"
    execute "/usr/bin/sudo" "${args[@]}"
  else
    info "${args[@]}"
    execute "${args[@]}"
  fi
}

getc() {
  local save_state
  save_state=$(/bin/stty -g)
  /bin/stty raw -echo
  IFS= read -r -n 1 -d '' "$@"
  /bin/stty "$save_state"
}

major_minor() {
  echo "${1%%.*}.$(x="${1#*.}"; echo "${x%%.*}")"
}

get_permission() {
  $STAT "%A" "$1"
}

user_only_chmod() {
  [[ -d "$1" ]] && [[ "$(get_permission "$1")" != "755" ]]
}

exists_but_not_writable() {
  [[ -e "$1" ]] && ! [[ -r "$1" && -w "$1" && -x "$1" ]]
}

get_owner() {
  $STAT "%u" "$1"
}

file_not_owned() {
  [[ "$(get_owner "$1")" != "$(id -u)" ]]
}

get_group() {
  $STAT "%g" "$1"
}

file_not_grpowned() {
  [[ " $(id -G "$USER") " != *" $(get_group "$1") "*  ]]
}

no_usable_python() {
  (command -v python3 >/dev/null 2>&1)
  return $?
}

if [[ -n "${COBALT_ON_LINUX-}" ]] && [[ -n $(no_usable_python) ]]
then
    abort "$(cat <<-EOFABORT
	${COBALT} requires Python 3, which was not found on your system.
	EOFABORT
    )"
fi

# USER isn't always set so provide a fall back for the installer and subprocesses.
if [[ -z "${USER-}" ]]; then
  USER="$(chomp "$(id -un)")"
  export USER
fi

# Invalidate sudo timestamp before exiting (if it wasn't active before).
if ! /usr/bin/sudo -n -v 2>/dev/null; then
  trap '/usr/bin/sudo -k' EXIT
fi

# Things can fail later if `pwd` doesn't exist.
# Also sudo prints a warning message for no good reason
cd "/usr" || exit 1

####################################################################### script
if ! command -v curl >/dev/null; then
    abort "$(cat <<EOABORT
You must install cURL before installing cobalt. Wait, how did you get here?
EOABORT
)"
fi

# shellcheck disable=SC2016
info 'Checking for sudo access (which may request your password).'

if [[ -z "${COBALT_ON_LINUX-}" ]]; then
  have_sudo_access
else
  if [[ -n "${NONINTERACTIVE-}" ]] ||
     [[ -w "${COBALT_PREFIX_DEFAULT}" ]] ||
     [[ -w "/home/cobalt" ]] ||
     [[ -w "/home" ]]; then
    COBALT_PREFIX="$COBALT_PREFIX_DEFAULT"
  else
    trap exit SIGINT
    if ! /usr/bin/sudo -n -v &>/dev/null; then
      info "Select the ${COBALT} installation directory"
      echo "- ${tty_bold}Enter your password${tty_reset} to install to ${tty_underline}${COBALT_PREFIX_DEFAULT}${tty_reset} (${tty_bold}recommended${tty_reset})"
      echo "- ${tty_bold}Press Control-D${tty_reset} to install to ${tty_underline}$HOME/.cobalt${tty_reset}"
      echo "- ${tty_bold}Press Control-C${tty_reset} to cancel installation"
    fi
    if have_sudo_access; then
      COBALT_PREFIX="$COBALT_PREFIX_DEFAULT"
    else
      COBALT_PREFIX="$HOME/.cobalt"
    fi
    trap - SIGINT
  fi
  COBALT_REPOSITORY="${COBALT_PREFIX}/cobalt"
fi

if [[ "${EUID:-${UID}}" == "0" ]]; then
  abort "Don't run this as root!"
elif [[ -d "${COBALT_PREFIX}" && ! -x "${COBALT_PREFIX}" ]]; then
  abort "$(cat <<EOABORT
The ${COBALT} prefix, ${COBALT_PREFIX}, exists but is not searchable.
If this is not intentional, please restore the default permissions and
try running the installer again:
    sudo chmod 775 ${COBALT_PREFIX}
EOABORT
)"
fi

if [[ -z "${COBALT_ON_LINUX-}" ]]; then
  # On macOS, support 64-bit Intel and ARM
  if [[ "$UNAME_MACHINE" != "arm64" ]] && [[ "$UNAME_MACHINE" != "x86_64" ]]; then
    abort "${COBALT} is only supported on Intel and ARM processors."
  fi
else
  # On Linux, support only 64-bit Intel
  if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    abort "$(cat <<EOABORT
${COBALT} on Linux is not supported on ARM processors.
EOABORT
)"
  elif [[ "$UNAME_MACHINE" != "x86_64" ]]; then
    abort "${COBALT} on Linux is only supported on Intel processors."
  fi
fi

info "This script will install:"
echo "${COBALT_PREFIX}/bin/cobalt"
echo "${COBALT_REPOSITORY}"

directories=(bin etc include lib sbin share opt var
             Frameworks
             bin/cobalt)
group_chmods=()
for dir in "${directories[@]}"; do
  if exists_but_not_writable "${COBALT_PREFIX}/${dir}"; then
    group_chmods+=("${COBALT_PREFIX}/${dir}")
  fi
done

# zsh refuses to read from these directories if group writable
directories=(share/zsh share/zsh/site-functions)
zsh_dirs=()
for dir in "${directories[@]}"; do
  zsh_dirs+=("${COBALT_PREFIX}/${dir}")
done

directories=(bin etc include lib sbin share var opt
             Frameworks)
mkdirs=()
for dir in "${directories[@]}"; do
  if ! [[ -d "${COBALT_PREFIX}/${dir}" ]]; then
    mkdirs+=("${COBALT_PREFIX}/${dir}")
  fi
done

user_chmods=()
if [[ "${#zsh_dirs[@]}" -gt 0 ]]; then
  for dir in "${zsh_dirs[@]}"; do
    if user_only_chmod "${dir}"; then
      user_chmods+=("${dir}")
    fi
  done
fi

chmods=()
if [[ "${#group_chmods[@]}" -gt 0 ]]; then
  chmods+=("${group_chmods[@]}")
fi
if [[ "${#user_chmods[@]}" -gt 0 ]]; then
  chmods+=("${user_chmods[@]}")
fi

chowns=()
chgrps=()
if [[ "${#chmods[@]}" -gt 0 ]]; then
  for dir in "${chmods[@]}"; do
    if file_not_owned "${dir}"; then
      chowns+=("${dir}")
    fi
    if file_not_grpowned "${dir}"; then
      chgrps+=("${dir}")
    fi
  done
fi

if [[ "${#group_chmods[@]}" -gt 0 ]]; then
  info "The following existing directories will be made group writable:"
  printf "%s\n" "${group_chmods[@]}"
fi
if [[ "${#user_chmods[@]}" -gt 0 ]]; then
  info "The following existing directories will be made writable by user only:"
  printf "%s\n" "${user_chmods[@]}"
fi
if [[ "${#chowns[@]}" -gt 0 ]]; then
  info "The following existing directories will have their owner set to ${tty_underline}${USER}${tty_reset}:"
  printf "%s\n" "${chowns[@]}"
fi
if [[ "${#chgrps[@]}" -gt 0 ]]; then
  info "The following existing directories will have their group set to ${tty_underline}${GROUP}${tty_reset}:"
  printf "%s\n" "${chgrps[@]}"
fi
if [[ "${#mkdirs[@]}" -gt 0 ]]; then
  info "The following new directories will be created:"
  printf "%s\n" "${mkdirs[@]}"
fi

if [[ -d "${COBALT_PREFIX}" ]]; then
  if [[ "${#chmods[@]}" -gt 0 ]]; then
    execute_sudo "/bin/chmod" "u+rwx" "${chmods[@]}"
  fi
  if [[ "${#group_chmods[@]}" -gt 0 ]]; then
    execute_sudo "/bin/chmod" "g+rwx" "${group_chmods[@]}"
  fi
  if [[ "${#user_chmods[@]}" -gt 0 ]]; then
    execute_sudo "/bin/chmod" "755" "${user_chmods[@]}"
  fi
  if [[ "${#chowns[@]}" -gt 0 ]]; then
    execute_sudo "$CHOWN" "$USER" "${chowns[@]}"
  fi
  if [[ "${#chgrps[@]}" -gt 0 ]]; then
    execute_sudo "$CHGRP" "$GROUP" "${chgrps[@]}"
  fi
else
  execute_sudo "/bin/mkdir" "-p" "${COBALT_PREFIX}"
  if [[ -z "${COBALT_ON_LINUX-}" ]]; then
    execute_sudo "$CHOWN" "root:wheel" "${COBALT_PREFIX}"
  else
    execute_sudo "$CHOWN" "$USER:$GROUP" "${COBALT_PREFIX}"
  fi
fi

if [[ "${#mkdirs[@]}" -gt 0 ]]; then
  execute_sudo "/bin/mkdir" "-p" "${mkdirs[@]}"
  execute_sudo "/bin/chmod" "g+rwx" "${mkdirs[@]}"
  execute_sudo "$CHOWN" "$USER" "${mkdirs[@]}"
  execute_sudo "$CHGRP" "$GROUP" "${mkdirs[@]}"
fi

if ! [[ -d "${COBALT_REPOSITORY}" ]]; then
  execute_sudo "/bin/mkdir" "-p" "${COBALT_REPOSITORY}"
fi
execute_sudo "$CHOWN" "-R" "$USER:$GROUP" "${COBALT_REPOSITORY}"

echo "Downloading and installing ${COBALT}..."
(
  cd "${COBALT_REPOSITORY}" >/dev/null || return
  
  # avoid git because we don't need it :sunglasses:

  execute "curl" "-fsSL" "${COBALT_GIT_RAW}/aes.py" "-o" "aes.py"
  execute "curl" "-fsSL" "${COBALT_GIT_RAW}/cobalt.py" "-o" "cobalt.py"
  execute "curl" "-fsSL" "${COBALT_GIT_RAW}/pyperclip.py" "-o" "pyperclip.py"
  
  execute "mkdir" "-p" "bin/"
  execute "cp" "cobalt.py" "bin/cobalt"
  execute "cp" "aes.py" "bin/aes.py"
  execute "cp" "pyperclip.py" "bin/pyperclip.py"
  execute "/bin/chmod" "+x" "bin/cobalt"

  if [[ "${COBALT_REPOSITORY}" != "${COBALT_PREFIX}" ]]; then
    execute "ln" "-sf" "${COBALT_REPOSITORY}/bin/cobalt" "${COBALT_PREFIX}/bin/cobalt"
  fi
) || exit 1

if [[ ":${PATH}:" != *":${COBALT_PREFIX}/bin:"* ]]; then
  warn "${COBALT_PREFIX}/bin is not in your PATH."
fi

success "Installation successful."
echo

# Use the shell's audible bell.
if [[ -t 1 ]]; then
  printf "\a"
fi

info "Next steps:"
if [[ "$UNAME_MACHINE" == "arm64" ]] || [[ -n "${COBALT_ON_LINUX-}" ]]; then
  case "$SHELL" in
    */bash*)
      if [[ -r "$HOME/.bash_profile" ]]; then
        shell_profile="$HOME/.bash_profile"
      else
        shell_profile="$HOME/.profile"
      fi
      ;;
    */zsh*)
      shell_profile="$HOME/.zprofile"
      ;;
    *)
      shell_profile="$HOME/.profile"
      ;;
  esac

  cat <<EOS
- Add ${COBALT} to your ${tty_bold}PATH${tty_reset} in ${tty_underline}${shell_profile}${tty_reset}:
    echo 'eval \$(${COBALT_PREFIX}/bin/cobalt shellenv)' >> ${shell_profile}
    eval \$(${COBALT_PREFIX}/bin/cobalt shellenv)
EOS
fi

echo "${COBALT} is now installed. Begin by typing ${COBALT}."
