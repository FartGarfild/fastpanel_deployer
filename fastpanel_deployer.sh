#!/bin/bash

# Змінні
SITE_ARCHIVE_DIR="/var/www/fastuser/data/backup/2024.07.27_20-21-28_test_91.247.37.42/" # Сюди прописати шлях до резервної копії
DB_ARCHIVE_DIR="$SITE_ARCHIVE_DIR"
# Користувач FastPanel у якому будть створені усі сайти
USER="fastuser"

DB_PASSWORD_FILE="db_passwords.txt"

extract_name() {
  local filename=$(basename -- "$1")
  local name="${filename%.*.*}"
  echo "$name"
}

# Де буде створено файл з паролями від БД.
rm -f /home/$DB_PASSWORD_FILE
touch /home/$DB_PASSWORD_FILE

for site_archive in "$SITE_ARCHIVE_DIR"/*.tar.gz; do
  DOMAIN=$(extract_name "$site_archive")
  SITE_DIR="/var/www/$USER/data/www/$DOMAIN/"
  
  echo "Створення сайту: $DOMAIN"
  
  mkdir -p "$SITE_DIR"
  tar -xzvf "$site_archive" -C "$SITE_DIR"
  
 # Додавання сайту в FastPanel
   /usr/local/fastpanel2/fastpanel sites create --server-name="$DOMAIN" --owner="$USER"
done

for db_archive in "$DB_ARCHIVE_DIR"/*.sql.gz; do
  DB_NAME=$(extract_name "$db_archive")
  DB_USER="$DB_NAME"
  DB_PASSWORD=$(openssl rand -base64 12)
  
  echo "Створення БД: $DB_NAME"
 
 #Додавання БД в панель
  /usr/local/fastpanel2/fastpanel databases create --server=1 --name="$DB_NAME" --username="$DB_USER" --password="$DB_PASSWORD"
  
  zcat "$db_archive" | mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME"
  
 #  Запис паролів в файл
  echo "Database: $DB_NAME, User: $DB_USER, Password: $DB_PASSWORD" >> $DB_PASSWORD_FILE
done

echo "Готово. Всі саайти створено, паролі від БД можете знайти за шляхом /home/$DB_PASSWORD_FILE."
