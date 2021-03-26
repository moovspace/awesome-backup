#!/bin/bash
# Backup script
# Script create cron job in: /etc/cron.d (backup once a day at 23:00)

# Mysql pass
MYSQL_PASS="toor"

# Copy tar to user directory: /home/<USER>/backup
USER="debian"

# backuped directories: /etc /var/www/html
BACKUP_DIRS="/etc /var/www/html"

# Variables, don't touch
COPY_TO_DIR="/home/${USER}/backup"
DAY=$(date +%Y-%m-%d)
BACKUP_FILE="backup-${DAY}.tar.gz"
BACKUP_DIR="backup-${DAY}"


if [ ! -d /home/${USER} ]; then
    echo ""
    echo "!!! User does not exists in home dir !!!"
    echo "!!! Change home dir user and mysql database password in script !!!"
    echo ""
    exit 1
fi

# Create dir
mkdir -p ${BACKUP_DIR}

# Permissions
chown -R ${USER}:${USER} ${BACKUP_DIR}
chmod -R 2700 ${BACKUP_DIR}

# Go to dir
cd ${BACKUP_DIR}

# Backup db
sudo mysqldump -u root -p${MYSQL_PASS} --add-drop-database --add-drop-table --add-locks --all-databases > databases.sql

# Backup files and sql file: /etc /var/www/html databases.sql
tar -cvpzf ${BACKUP_FILE} ${BACKUP_DIRS} databases.sql

# Create dir
mkdir -p ${COPY_TO_DIR}

# Copy to
cp ${BACKUP_FILE} ${COPY_TO_DIR}

# Permissions
chown -R ${USER}:${USER} ${COPY_TO_DIR}
chmod -R 2700 ${COPY_TO_DIR}

# Tar test
if [ -f ${COPY_TO_DIR}/${BACKUP_FILE} ]; then
    echo ""
    echo "!!! Backup file copied to: ${COPY_TO_DIR}/${BACKUP_FILE}"
    echo ""
else
    echo "!!! Backup file error !!!"
fi

# Mysql test
if [ -f all_databases.sql ]; then
    echo ""
    echo "!!! Mysql database backup created in tar backup file"
    echo ""
else
    echo "!!! Mysql backup database error"
fi

# Back to dir
cd ..

# Remove backup dir
if [ -d ${BACKUP_DIR} ]; then
    rm -rf ${BACKUP_DIR}
fi

# Create dir
sudo mkdir -p "/etc/cron-scripts"

# Copy script executed script
cp $(readlink -f $0) /etc/cron-scripts/awesome-backup.sh

if [ ! -f /etc/cron.d/awesome-backup-cron.sh ]; then
# Add script
echo "SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 23 * * * /etc/cron-scripts/awesome-backup.sh >/dev/null 2>&1
" > /etc/cron.d/awesome-backup-cron.sh
# Allow run cron
chmod +x /etc/cron-scripts/awesome-backup.sh
fi

# Test cron job
if [ -f /etc/cron.d/awesome-backup-cron.sh ]; then
    echo ""
    echo "!!! Backup once a day at 23:00 cron job added to: /etc/cron.d/awesome-backup-cron.sh"
    echo ""
else
    echo "!!! Cron job not added"
fi
