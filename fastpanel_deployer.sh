#!/bin/bash

# Директории с архивами
SITE_ARCHIVE_DIR="/var/www/fastuser/data/backup/2024.07.27_20-21-28_test_91.247.37.42/"  # Директория с архивами сайтов
DB_ARCHIVE_DIR="/var/www/fastuser/data/backup/2024.07.27_20-21-28_test_91.247.37.42/"    # Директория с архивами баз данных

# Имя пользователя для всех сайтов
USER="fastuser"

# Файл для сохранения паролей баз данных
DB_PASSWORD_FILE="db_passwords.txt"

# Функция для извлечения имени без расширения
extract_name() {
  local filename=$(basename -- "$1")
  local name="${filename%.*.*}"
  echo "$name"
}

# Удаление старого файла с паролями и создание нового
rm -f /home/$DB_PASSWORD_FILE
touch /home/$DB_PASSWORD_FILE

# Обработка архивов сайтов
for site_archive in "$SITE_ARCHIVE_DIR"/*.tar.gz; do
  DOMAIN=$(extract_name "$site_archive")
  mkdir /var/www/$USER/data/www2 # тимчасова директорія, тому що FastPanel створює в архіві директорію з повним шляхом.
  SITE_DIR="/var/www/$USER/data/www2/$DOMAIN/"
  mv /var/www/$USER/data/www2/*/var/www/*/data/www/* /var/www/$USER/data/www/
  echo "Создание сайта: $DOMAIN"
  
  # Создание директории сайта и распаковка файлов
  mkdir -p "$SITE_DIR"
  tar -xzvf "$site_archive" -C "$SITE_DIR"
  
 # Создание сайта в FastPanel
   /usr/local/fastpanel2/fastpanel sites create --server-name="$DOMAIN" --owner="$USER"
done

# Обработка архивов баз данных
for db_archive in "$DB_ARCHIVE_DIR"/*.sql.gz; do
  DB_NAME=$(extract_name "$db_archive")
  DB_USER="$DB_NAME"
  DB_PASSWORD=$(openssl rand -base64 12)
  
  echo "Создание базы данных: $DB_NAME"
 
 #Создание БД через панель
  /usr/local/fastpanel2/fastpanel databases create --server=1 --name="$DB_NAME" --username="$DB_USER" --password="$DB_PASSWORD"
  
 # Импорт базы данных из архива .sql.gz
  zcat "$db_archive" | mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME"
  
 # Запись информации о базе данных и пароле в файл
  echo "Database: $DB_NAME, User: $DB_USER, Password: $DB_PASSWORD" >> /home/$DB_PASSWORD_FILE
done

echo "Все сайты и базы данных успешно созданы. Пароли сохранены в $DB_PASSWORD_FILE."

