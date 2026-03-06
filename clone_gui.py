import os
import subprocess
import sys
from install_config import get_user_config

def check_installation(path):
    if os.path.exists(path):
        confirm = input(f"{path} already exists. Do you want to reinstall? [y/N]: ").lower()
        if confirm != 'y':
            print("Installation aborted.")
            sys.exit(0)
        else:
            print("Removing existing directory...")
            subprocess.run(["sudo", "rm", "-rf", path])

def clone_project(repo_url, install_path, token):
    print(f"\nCloning {repo_url} into {install_path}...")
    # Insert token into URL for authentication
    if "https://" in repo_url:
        repo_url = repo_url.replace("https://", f"https://{token}@")
    subprocess.run(["sudo", "git", "clone", repo_url, install_path], check=True)
    print("Cloning completed.\n")

def install_dependencies():
    print("Installing required packages...")
    subprocess.run(["sudo", "apt", "update"])
    subprocess.run(["sudo", "apt", "install", "-y", "apache2", "mysql-server", "php", "php-mysql", "git", "python3-pip"])
    subprocess.run([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
    print("Dependencies installed.\n")

def main():
    install_dependencies()
    config = get_user_config()
    check_installation(config["INSTALL_PATH"])
    clone_project(config["GITHUB_REPO"], config["INSTALL_PATH"], config["GITHUB_TOKEN"])
    print("MedicalSoft installation completed successfully!")

if __name__ == "__main__":
    main()