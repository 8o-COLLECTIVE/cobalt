from git import Repo
import subprocess
import os


class Updater:
    def __init__(self):
        dir_path = os.path.dirname(os.path.realpath(__file__))
        self.repo = Repo(dir_path + "/../")


    def needs_update(self):
        current_commit = self.repo.head.commit
        latest_commit = self.repo.heads.development.commit
        if current_commit == latest_commit:
            return False
        else:
            return True


    def update(self):
        print("An update is available. Updating now.")
        proc = subprocess.Popen(["python3", "-m", "pip", "install", "cobalt8"], shell=False)
        proc.communicate()
        return proc.exitcode
