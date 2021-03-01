@echo off	

set COBALT='\033[0;34mcobalt\033[0m'

set COBALT_GIT_RAW="https://raw.githubusercontent.com/8o-COLLECTIVE/cobalt/master/src"

set COBALT_INSTALL_DIR="C:\Program Files\cobalt"

net session >nul 2>&1
if errorlevel 1 (
    echo Failure: Please restart your command prompt with administrator permissions. You can do this by searching for CMD, right clicking on it, and selecting the administrator option.
    GOTO :EOF
)

::check for python3 here
python --version 2>NUL
if errorlevel 1 goto NOPYTHON

:CONTINUE
::check for cURL (less important as win10 is shipped with curl)

if not exist %COBALT_INSTALL_DIR%\NUL md %COBALT_INSTALL_DIR%

cd %COBALT_INSTALL_DIR%

curl -fsSL "%COBALT_GIT_RAW%/cobalt.py" -o cobalt.py
curl -fsSL "%COBALT_GIT_RAW%/aes.py" -o aes.py
curl -fsSL "%COBALT_GIT_RAW%/pyperclip.py" -o pyperclip.py

python -m pip install nuitka

python -m nuitka --follow-imports cobalt.py --output-dir build/ -o cobalt.exe

echo %PATH%|find /i "%COBALT_INSTALL_DIR:"=%">nul  || set path=%PATH%;%COBALT_INSTALL_DIR%

GOTO :EOF
:NOPYTHON
setlocal
set version=3.9.2
set installer=python-%version%-amd64.exe
set installerlink=https://www.python.org/ftp/python/%version%/%installer%
echo "Python 3 not found. Installing %installerlink%"
echo "This may take a while..."

curl %installerlink% -o $installer$
%installer% /passive InstallAllUsers=1 PrependPath=1 Include_test=0 Include_doc=0 SimpleInstall=1 Include_tools=0 Include_tcltk=0

endlocal

GOTO CONTINUE


