#!/bin/bash
# installer 4 b2safe 

#just in case
#apt-get install -y rsync

# move ICAT outside container
#
mkdir /var/lib/icat_db
chown -R postgres:postgres /var/lib/icat_db/
rsync -av /var/lib/postgresql/ /var/lib/icat_db/
mv /var/lib/postgresql/11/main/ /var/lib/postgresql/11/main.bak
# modify DB path
sed -i -E "s/(data_directory.+)postgresql(.+\/main)/\1icat_db\2/" /etc/postgresql/11/main/postgresql.conf

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

# su - irods
sudo -u irods cd /opt/eudat/b2safe/B2SAFE-core/packaging
sudo -u irods  ./create_deb_package.sh
sudo dpkg -i /home/irods/debbuild/irods-eudat-b2safe_4.1-1.deb


# install/configure B2Safe as the user who runs iRODS
sudo -s source /etc/irods/service_account.config
sudo -u irods cd /opt/eudat/b2safe/B2SAFE-core/packaging
sudo -u irods  ./install.sh
# ATTENTION-> password for EPIC prefix required! XXXXXXXX

# install B2HANDLE
cd /opt/eudat/B2HANDLE/dist/
sudo easy_install b2handle-1.1.1-py2.7.egg

#copy epicclient ok
cp /opt/eudat/b2safe/B2SAFE-core/cmd/epicclient2.py /opt/eudat/b2safe/B2SAFE-core/cmd/epicclient.py


# stop database
service postgresql stop

# 
echo ''
echo ' launch b2safe stack with ./start.sh '
echo ''
