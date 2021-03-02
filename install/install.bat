@echo off

::check for python3 here
python --version 2>NUL
if errorlevel 1 goto NOPYTHON

:CONTINUE
pip install cobalt8

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


