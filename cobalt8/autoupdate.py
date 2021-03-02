import requests
import subprocess
import os

about = {}
with open(os.path.join(os.path.dirname(__file__), "__version__.py")) as f:
    exec(f.read(), about)


class Updater:
    def needs_update(self):
        current_version = about["__version__"]
        
        r = requests.get('https://raw.githubusercontent.com/8o-COLLECTIVE/cobalt8/production/cobalt8/__version__.py')
        print(r.text)
        latest_version = r.text.split('\n')[3]
        if current_commit == latest_commit:
            return False
        else:
            return True


    def update(self):
        print("An update is available. Updating now.")
        proc = subprocess.Popen(["python3", "-m", "pip", "install", "git+https://github.com/8o-COLLECTIVE/cobalt8.git@production"], shell=False)
        proc.communicate()
        return proc.returncode
