import os
from getpass import getpass

def get_user_config():
    print("=== MedicalSoft Installer Configuration ===\n")

    db_host = input("Database Host [127.0.0.1]: ") or "127.0.0.1"
    db_port = input("Database Port [3306]: ") or "3306"
    db_name = input("Database Name [medicalsoft]: ") or "medicalsoft"
    db_user = input("Database User [root]: ") or "root"
    db_password = getpass("Database Password: ")

    install_path = input("Installation Path [/var/www/html/clinicsoft]: ") or "/var/www/html/clinicsoft"

    github_token = getpass("GitHub Personal Access Token: ")
    github_repo = input("GitHub Repository URL [https://github.com/judelFintch/medicalsoft.git]: ") or "https://github.com/judelFintch/medicalsoft.git"

    return {
        "DB_HOST": db_host,
        "DB_PORT": db_port,
        "DB_NAME": db_name,
        "DB_USER": db_user,
        "DB_PASSWORD": db_password,
        "INSTALL_PATH": install_path,
        "GITHUB_TOKEN": github_token,
        "GITHUB_REPO": github_repo
    }