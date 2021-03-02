from git import Repo
import subprocess

class Updater:
    def __init__(self):
        self.repo = Repo("../")

    def needs_update(self):
        current_commit = self.repo.head.commit
        latest_commit = self.repo.heads.development.commit
        if current_commit == latest_commit:
            return False
        else:
            return True

    def update(self):
        proc = subprocess.Popen(["python3", "-m", "pip", "install", "cobalt8"], shell=False)
        proc.communicate()
        return proc.exitcode
