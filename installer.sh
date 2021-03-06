#!/bin/bash
# installer 4 b2safe 

#just in case
#apt-get install -y rsync

# check if root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
# move ICAT outside container
#
mkdir /var/lib/icat_db
chown -R postgres:postgres /var/lib/icat_db/
rsync -av /var/lib/postgresql/ /var/lib/icat_db/
# make a bkup old dir
db_dir=$(find /var/lib/postgresql/ -mindepth 1 -maxdepth 1 -type d)
mv $db_dir/main/ $db_dir/main.bak
# modify DB path
dir=$(find /etc/postgresql/ -mindepth 1 -maxdepth 1 -type d)
sed -i -E "s/(data_directory.+)postgresql(.+\/main)/\1icat_db\2/" $dir/main/postgresql.conf

# start database
#
service postgresql start

# prep ICAT
# 
cd /var/lib/postgresql
sudo -u postgres psql -c "CREATE USER irods WITH PASSWORD 'irods' " 
sudo -u postgres psql -c 'CREATE DATABASE "ICAT" ' 
sudo -u postgres psql -c 'GRANT ALL PRIVILEGES ON DATABASE "ICAT" TO irods ' 

# install iRODS
#
python /var/lib/irods/scripts/setup_irods.py

# answer interactive iRODS installation
#

### Make packages 4 B2HANDLE & B2SAFE
#
# check install.conf into /opt/eudat/b2safe/B2SAFE-core/packaging if is correctly setting - permission owner (irods)
chown irods:irods /opt/eudat/b2safe/B2SAFE-core/packaging/install.conf
# chek owner and permission in /opt/eudat/cert/ (owner : irods  - 0644)
chmod 0644 /opt/eudat/cert/*.pem

# B2SAFE
echo '**start b2safe'
pack=$(find /home/irods/debbuild/ -mindepth 1 -maxdepth 1 -type f)
dpkg -i $pack

echo '**packaging b2safe'
# install/configure B2Safe as the user who runs iRODS
sudo -s source /etc/irods/service_account.config
cd /opt/eudat/b2safe/B2SAFE-core/packaging
sudo -H -u irods bash -c './install.sh'

# ATTENTION-> password for EPIC prefix required! XXXXXXXX

# install B2HANDLE
echo '**start b2handle'
cd /opt/eudat/B2HANDLE/dist/
packhandle=$(find /opt/eudat/B2HANDLE/dist/ -mindepth 1 -maxdepth 1 -type f)
b2handle=$(basename $packhandle)
easy_install $b2handle


#copy epicclient ok
cp /opt/eudat/b2safe/B2SAFE-core/cmd/epicclient2.py /opt/eudat/b2safe/B2SAFE-core/cmd/epicclient.py


# stop database
sudo service postgresql stop

# 
echo ''
echo ' launch b2safe stack with ./start.sh '
echo ''


