from git import Repo
from sys import platform
import subprocess

class Updater:
    def __init__(self):
        self.repo = Repo("../")
        self.os = check_os()

    def needs_update(self):
        current_commit = self.repo.head.commit
        latest_commit = repo.heads.development.commit
        if current_commit == latest_commit:
            return False
        else:
            return True

    def check_os(self):
        if sys.platform == "linux" or platform == "linux2" or sys.platform == "darwin":
            return "unix"
        elif sys.platform == "win32":
            return "windows"
            
    def update(self):
        if self.os == "unix":
            proc = subprocess.Popen(["/bin/bash", "-c", "\"$(curl -fsSL https://raw.githubusercontent.com/8o-COLLECTIVE/cobalt/master/install/install.sh)\""], shell=False)
        if self.os == "windows":
            proc = subprocess.Popen(["powershell.exe", "\"cmd.exe \c \"$(curl -fsSL https://raw.githubusercontent.com/8o-COLLECTIVE/cobalt/master/install/install.bat)\"\""], shell=False)
        proc.communicate()
