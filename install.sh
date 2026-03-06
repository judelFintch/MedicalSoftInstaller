#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$1"; }

require_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required but not installed." >&2
    exit 1
  fi
}

is_ubuntu() {
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    [ "${ID:-}" = "ubuntu" ] || return 1
  else
    return 1
  fi
}

prompt() {
  local var_name="$1"; shift
  local prompt_text="$1"; shift
  local default_value="$1"; shift || true
  local value
  if [ -n "$default_value" ]; then
    read -r -p "$prompt_text [$default_value]: " value
    value="${value:-$default_value}"
  else
    read -r -p "$prompt_text: " value
  fi
  printf -v "$var_name" '%s' "$value"
}

random_password() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 18
  else
    date +%s | sha256sum | cut -c1-24
  fi
}

log "Welcome to MedicalSoft quick install"

if ! is_ubuntu; then
  echo "This installer is tested on Ubuntu 20.04+ only." >&2
  echo "Abort to avoid breaking your system." >&2
  exit 1
fi

require_sudo

prompt INSTALL_PATH "Installation path" "/var/www/medicalsoft"
prompt REPO_URL "Git repository URL" "https://github.com/judelFintch/medicalsoft.git"
GIT_TOKEN=""
read -r -s -p "GitHub token (leave empty if repo is public): " GIT_TOKEN
echo ""
prompt DB_NAME "Database name" "medicalsoft"
prompt DB_USER "Database user" "medicalsoft"
DB_PASS="$(random_password)"

echo "\nA database user will be created with this password:"
echo "$DB_PASS"

echo "\nOptional (for HTTPS):"
prompt DOMAIN "Domain name (leave empty to skip SSL)" ""
EMAIL=""
if [ -n "$DOMAIN" ]; then
  prompt EMAIL "Email for Let's Encrypt" "admin@$DOMAIN"
fi

log "Installing system packages"
sudo apt update
sudo apt install -y apache2 mysql-server git curl unzip openssl
sudo apt install -y php php-mysql php-xml php-mbstring php-curl php-zip php-gd

if ! command -v composer >/dev/null 2>&1; then
  log "Installing Composer"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  rm -f composer-setup.php
fi

log "Preparing database"
sudo mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"
sudo mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo mysql -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"

if [ -d "$INSTALL_PATH" ]; then
  echo "\n$INSTALL_PATH already exists."
  read -r -p "Do you want to replace it? [y/N]: " confirm
  if [ "${confirm,,}" != "y" ]; then
    echo "Installation aborted."
    exit 0
  fi
  BACKUP_PATH="${INSTALL_PATH}.bak-$(date +%Y%m%d-%H%M%S)"
  echo "Creating backup at: $BACKUP_PATH"
  sudo mv "$INSTALL_PATH" "$BACKUP_PATH"
fi

log "Cloning application"
if [ -n "$GIT_TOKEN" ] && [[ "$REPO_URL" == https://* ]]; then
  ASKPASS_FILE="$(mktemp)"
  cat <<'ASKPASS' > "$ASKPASS_FILE"
#!/usr/bin/env bash
echo "$GIT_TOKEN"
ASKPASS
  chmod 700 "$ASKPASS_FILE"
  # Use GIT_ASKPASS to avoid putting token in URL or history
  sudo -E env GIT_ASKPASS="$ASKPASS_FILE" GIT_TERMINAL_PROMPT=0 git clone "$REPO_URL" "$INSTALL_PATH"
  rm -f "$ASKPASS_FILE"
else
  sudo git clone "$REPO_URL" "$INSTALL_PATH"
fi

log "Installing application dependencies"
sudo chown -R "$USER":"$USER" "$INSTALL_PATH"
cd "$INSTALL_PATH"
composer install --no-interaction --prefer-dist --no-dev

if [ -f .env.example ]; then
  cp .env.example .env
else
  cat <<'ENVFILE' > .env
APP_NAME=MedicalSoft
APP_ENV=production
APP_DEBUG=false
APP_URL=http://localhost

LOG_CHANNEL=stack

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=medicalsoft
DB_USERNAME=medicalsoft
DB_PASSWORD=

CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
ENVFILE
fi

# Update .env database values
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env

php artisan key:generate --force
php artisan migrate --force || true

sudo chown -R www-data:www-data "$INSTALL_PATH"
sudo find "$INSTALL_PATH" -type f -exec chmod 644 {} \;
sudo find "$INSTALL_PATH" -type d -exec chmod 755 {} \;

log "Configuring Apache"
sudo a2enmod rewrite
VHOST="/etc/apache2/sites-available/medicalsoft.conf"
APP_URL="http://localhost"
SERVER_NAME=""
if [ -n "$DOMAIN" ]; then
  SERVER_NAME="ServerName $DOMAIN"
  APP_URL="https://$DOMAIN"
fi

sudo bash -c "cat > $VHOST" <<'VHOSTCONF'
<VirtualHost *:80>
    __SERVER_NAME__
    DocumentRoot __INSTALL_PATH__/public
    <Directory __INSTALL_PATH__/public>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/medicalsoft_error.log
    CustomLog ${APACHE_LOG_DIR}/medicalsoft_access.log combined
</VirtualHost>
VHOSTCONF

sudo sed -i "s|__SERVER_NAME__|$SERVER_NAME|" "$VHOST"
sudo sed -i "s|__INSTALL_PATH__|$INSTALL_PATH|" "$VHOST"

sudo a2ensite medicalsoft.conf
sudo a2dissite 000-default.conf >/dev/null 2>&1 || true
sudo systemctl reload apache2

sed -i "s|^APP_URL=.*|APP_URL=$APP_URL|" .env

if [ -n "$DOMAIN" ] && [ -n "$EMAIL" ]; then
  log "Setting up SSL with Let's Encrypt"
  sudo apt install -y certbot python3-certbot-apache
  sudo certbot --apache -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive
fi

log "Done"
echo "MedicalSoft is installed in: $INSTALL_PATH"
echo "Database: $DB_NAME"
echo "DB user: $DB_USER"
echo "DB password: $DB_PASS"
if [ -n "$DOMAIN" ]; then
  echo "URL: $APP_URL"
else
  echo "URL: http://localhost (or your server IP)"
fi
