#!/bin/bash

# Varriables
SITE_ARCHIVE_DIR="/var/www/fastuser/data/backup/"  
DB_ARCHIVE_DIR="$SITE_ARCHIVE_DIR"    
USER="fastuser"

# Password file 
DB_PASSWORD_FILE="db_passwords.txt"

extract_name() {
  local filename=$(basename -- "$1")
  local name="${filename%.*.*}"
  echo "$name"
}

rm -f /home/$DB_PASSWORD_FILE
touch /home/$DB_PASSWORD_FILE


for site_archive in "$SITE_ARCHIVE_DIR"/*.tar.gz; do
  DOMAIN=$(extract_name "$site_archive")
  mkdir /var/www/$USER/data/www2 # TMP dir for correct unzipping
  SITE_DIR="/var/www/$USER/data/www2/$DOMAIN/"
  mv /var/www/$USER/data/www2/*/var/www/*/data/www/* /var/www/$USER/data/www/
  echo "Site created: $DOMAIN"
  
  mkdir -p "$SITE_DIR"
  tar -xzvf "$site_archive" -C "$SITE_DIR"
  
 # Crtating site in FastPanel
   /usr/local/fastpanel2/fastpanel sites create --server-name="$DOMAIN" --owner="$USER"
done

# DATABASES
for db_archive in "$DB_ARCHIVE_DIR"/*.sql.gz; do
  DB_NAME=$(extract_name "$db_archive")
  DB_USER="$DB_NAME"
  DB_PASSWORD=$(openssl rand -base64 12)
  /usr/local/fastpanel2/fastpanel databases create --server=1 --name="$DB_NAME" --username="$DB_USER" --password="$DB_PASSWORD"
  echo "Creating database: $DB_NAME"
  
  
  zcat "$db_archive" | mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME"  #Без zczt никак
  
 # Password file
  echo "Database: $DB_NAME, User: $DB_USER, Password: $DB_PASSWORD" >> /home/$DB_PASSWORD_FILE
done

echo "All sites created. You can look up the passwords in the file /home/$DB_PASSWORD_FILE."

