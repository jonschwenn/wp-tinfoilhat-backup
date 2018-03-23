# A.B.B.
Always be backing-up.  

Let's imagine you have a WordPress site running on a server. You want to backup your WordPress site because it's important to you and you'd hate to loose posts, images, or even worse - customer orders if you use WP for e-commerce. There are many ways to back it up and most of those include plugins which are simple to use.

Instead of taking a backup using a WordPress plugin which lives inside of WordPress, here is a basic script that is configured to do a daily backup of the WordPress sites and copy them to multiple locations as well as keeping a set number of historical copies locally on the server.

### Prerequisites
---
1. WordPress running on a LAMP (Linux, Apache, MySQL, PHP) server
2. Populate your username and password for MySQL in ~/.my.cnf
3. s3cmd installed and configured
  * DigitalOcean Spaces is a great low-cost option for Object storage.
  * [Here is a tutorial](https://www.digitalocean.com/community/tutorials/how-to-configure-s3cmd-2-x-to-manage-digitalocean-spaces) on how to install s3cmd and configure it for DigitalOcean Spaces
4. A remote host configured with SSH Key authentication if a remote host destination is used

### Setup
---
- Copy the script file or script contents to your server
- Set the variables in the script file:
```
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
```
- Make your script executable:
```
$sudo chmod a+x /root/wp-backup.sh
```
- Add a crontab entry to automate the script. _This example would run the script at 4am server time daily:_
```
$crontab -e

0 4 * * * /root/wp-backup.sh >/dev/null 2>&1
```

_Periodically clearing out old backups will be needed for a Remote Host and/or Object Storage bucket.  That's another script._
