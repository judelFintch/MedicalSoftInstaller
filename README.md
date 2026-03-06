# MedicalSoftInstaller
MedicalSoftInstaller is a complete installation script for setting up the **MedicalSoft**
MedicalSoftInstaller is a complete installation script for setting up the **MedicalSoft** web application on a new server. It automates the installation of Apache, MySQL, PHP, and the Laravel project, and guides the user through configuration securely.

---

## Features

- Installs and configures Apache, MySQL, and PHP.
- Clones the MedicalSoft project from GitHub using a personal access token.
- Sets up file permissions and environment variables.
- Allows the user to input database credentials and GitHub token.
- Checks if MedicalSoft is already installed and asks for confirmation before reinstalling.
- Provides a graphical interface for easy installation (optional).
- Secure and user-friendly.

---

## Requirements

- Ubuntu 20.04 or newer
- Root or sudo access
- Internet connection
- Git installed
- A GitHub personal access token (for private repositories)

---

## Usage

1. Clone the installer repository:

```bash
git clone https://github.com/<username>/MedicalSoftInstaller.git
cd MedicalSoftInstaller
