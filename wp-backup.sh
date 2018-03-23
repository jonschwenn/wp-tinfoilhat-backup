#!/usr/bin/env bash
# Script to backup WordPress to multiple locations
# Read the README.md to ensure proper configuration
# https://github.com/jonschwenn/wp-tinfoilhat-backup
set -eo pipefail
readonly SCRIPT_NAME=$(basename $0)

# SET THESE VARIABLES
# ---------------------------------------------------------------------
# Directory for all backups to be stored locally
BACKUP_DIR=/root/backups
# Directory for WordPress
# Only single WordPress instance is allowed in this version
WP_DIR=/var/www/html
# How many local copies should be saved (in days)
COPIES=14
# S3 Bucket location
# Leave Blank to disable S3 Sync
S3CMD_BUCKET=
# Remote Host (SSH Keys need to be configured)
# Leave Blank to disable Remote Host
REMOTE_HOST=
REMOTE_USER=root
REMOTE_PORT=22
REMOTE_PATH=/root/www-backups
# ---------------------------------------------------------------------

get_db_name (){
WP_CONFIG=$(find $WP_DIR -name wp-config.php)
DB_NAME=$(grep DB_NAME $WP_CONFIG | cut -d \' -f 4)
}

check_s3cmd (){
echo "TODO: Prevalidate s3cmd"

}

check_remotehost(){
echo  "TODO: Prevalidate remote host connection"
}

create_backup (){
# Setup Backup Directory
if [ ! -d "$BACKUP_DIR" ]
then
  mkdir -p $BACKUP_DIR
fi
cd $BACKUP_DIR
mkdir backup-$(date +%Y-%m-%d)
cd backup-$(date +%Y-%m-%d)

# Backup Database
get_db_name "$@"
mysqldump --opt -Q $DB_NAME > database-$(date +%Y-%m-%d).sql || \
err "ERROR: Database Backup Failed"

# Backup Site Files
tar -czf site-$(date +%Y-%m-%d).tar.gz $WP_DIR || \
err "ERROR: Site File Backup Failed"

# Create Final Backup File
cd $BACKUP_DIR
tar -cf backup-$(date +%Y-%m-%d).tar backup-$(date +%Y-%m-%d) && \
log "Backup backup-$(date +%Y-%m-%d).tar Created" || \
err "ERROR: Backup Process Failed"
}

remote_sync (){

scp -P$REMOTE_PORT $BACKUP_DIR/backup-$(date +%Y-%m-%d).tar $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH && \
log "Backup Sent to Remote Host" || \
err "ERROR: Remote Host Process Failed"
}

s3cmd_sync (){

# Send copy to S3cmd configured object storage
s3cmd put $BACKUP_DIR/backup-$(date +%Y-%m-%d).tar s3://$S3CMD_BUCKET  && \
log "Backup Sent to Object Storage" || \
err "ERROR: Object Storage Process Failed"
}

cleanup (){
# Cleanup Backup Working Directory
cd $BACKUP_DIR
rm -rf backup-$(date +%Y-%m-%d)
# Cleanup old copies
if [ $(ls -t | sed -e '1,'"$COPIES"'d' | wc -l) -ge  1  ]
then
ls -t | sed -e '1,'"$COPIES"'d' | xargs -d '\n' rm && \
log "Cleanup Process for Backups older than $COPIES days completed"
else
log "Cleanup Process found backups older than $COPIES days "
fi

}

log() {
  echo "$@"
  logger -p user.notice -t $SCRIPT_NAME "$@"
}

err() {
  echo "$@" >&2
  logger -p user.error -t $SCRIPT_NAME "$@"
}

main() {
  get_db_name &&
  create_backup &&
  remote_sync &&
  s3cmd_sync &&
  cleanup
}

main "$@"
