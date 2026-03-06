# MedicalSoftInstaller
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

## Usage (Step by Step)

### 1) Connect to your Linux server
Open a terminal and connect via SSH:

```bash
ssh user@your-server-ip
```

### Alternative (Local Server)
If the server is local (same machine), you do not need SSH. Just open a terminal and continue from step 2.

### 2) Download the installer

```bash
git clone https://github.com/<username>/MedicalSoftInstaller.git
cd MedicalSoftInstaller
```

### 3) Run the installer

```bash
./install.sh
```

### 4) Answer the prompts
The script asks for:

- Installation path (default: `/var/www/medicalsoft`)
- Git repository URL (default points to MedicalSoft)
- GitHub token (hidden input; leave empty if repo is public)
- Database name and user (defaults: `medicalsoft`)
- Optional domain name (for HTTPS)
- Optional email for Let's Encrypt (if a domain is provided)

### 5) What the script does for you

- Installs Apache, MySQL, PHP, Composer, and required PHP extensions
- Creates the database and user
- Clones the MedicalSoft app
- Creates `.env` and generates the Laravel `APP_KEY`
- Runs database migrations (best effort)
- Configures Apache virtual host
- Enables HTTPS if a domain is provided

### 6) Final result
At the end, the script prints:

- The installation path
- Database name and user
- Database password
- Access URL (`http://server-ip` or `https://your-domain`)

### Reinstall behavior (safe)
If the installation folder already exists, the script creates a backup instead of deleting it:

```
/var/www/medicalsoft.bak-YYYYmmdd-HHMMSS
```

---

## Distribute a Single Executable (.run)

For non-technical users, you can publish a single executable installer (`.run`) as a GitHub Release asset.

### 1) Build the `.run` installer

```bash
./pack_installer.sh
```

This generates:
```
dist/medicalsoft-installer.run
```

### 2) Create a GitHub Release and upload the file

```bash
gh release create v1.0.0 dist/medicalsoft-installer.run -t "MedicalSoft Installer v1.0.0"
```

### 3) User download + install

```bash
chmod +x medicalsoft-installer.run
./medicalsoft-installer.run
```

The `.run` file simply launches `install.sh` with the same prompts.
