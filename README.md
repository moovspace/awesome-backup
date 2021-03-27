# Vps backup script
Vps backup script (mysql databases and dirs: /etc/ /var/www/html).

### Run script as root user
```
# Login as root
su

# Run script
sudo bash awesome-script.sh
```

### The cron job will be located in 
/etc/cron.d/awesome-backup-cron
```
# cron job
/etc/cron.d/awesome-backup-cron

# cron job runing script from
/etc/cron-scripts/awesome-backup.sh
```

### Directory owner and permissions
Force owner and permission on directory
```bash
chown -R username:username /home/username/backup
chmod -R 2770 /home/username/backup
```
