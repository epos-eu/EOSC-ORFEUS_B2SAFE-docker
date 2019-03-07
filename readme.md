
########################################################
## build and run B2Safe all-in-one (with icat database)##
########################################################


disclaimer: every name and directory are not mandatory (except for the database) they could be whatever.

1) 
build an image within irods and icat postrgesql:
===============================================

docker build -t "b2safe_aio:4.1.1" .
(4.1.1 is B2Safe version)

2)
launch the all-in-one container:
===============================

docker run -it --name eudat_b2safe  -v /data/b2safe_icat_db:/var/lib/postg2safe -v /mnt/seedstore_nfs:/var/lib/datairods -v /opt/eudat/b2safeRules:/var/lib/irods/myrules -v /opt/eudat/b2safeVault:/var/lib/irods/Vault -p 1247:1247 -p 1248:1248 -p 5432:5432 -p 20000-20199:20000-20199   b2safe_aio:4.1.1 /bin/bash


there are several volumes (host directory) mounted on container, they are:

Database data-directory:
<host path> : <container path>
/data/b2safe_icat_db:/var/lib/postg2safe

Repository of Mseed files:
/mnt/seedstore_nfs:/var/lib/datairods

directory of rules:
/opt/eudat/b2safeRules:/var/lib/irods/myrules

Vault directory (the directory used by irods to store files - not for our case but useful)
/opt/eudat/b2safeVault:/var/lib/irods/Vault

in order to make persistent all data inside irods and icat db;
the rules directory is used to update some script , if needed, without touch the container.

 after docker container is started you are into container:

3) 
SETUP iRODS as data-provider:
============================

inside container::-----------
-----------------------------

move data-dir postgres:
======================
be aware --> 
mounted dir::/data/b2safe_icat_db  
inside dir::/var/lib/postg2safe 
postgres dir: /var/lib/postgresql

service postgresql  stop

(apt-get install rsync - if needed)
mkdir /var/lib/postg2safe
chown -R postgres:postgres /var/lib/postg2safe/
rsync -av /var/lib/postgresql/ /var/lib/postg2safe/
mv /var/lib/postgresql/10/main/ /var/lib/postgresql/10/main.bak

vi /etc/postgresql/10/main/postgresql.conf 

line:
41    data_directory = '/var/lib/postgresql/10/main'     --> 1 data_directory = '/var/lib/postg2safe/10/main'  <-- NB! : new path *postg2safe*  old path  *postgresql*




service postgresql start

prep ICAT::-----------
----------------------



::inside psql:

from root become postgres user
su - postgres

psql

postgres=# create user irods with password 'sdor';
CREATE ROLE

postgres=# create database "ICAT";
CREATE DATABASE

postgres=# grant all privileges on database "ICAT" to irods;
GRANT
postgres=# 

exit


-------------eventually restore


postgresql restore old b2safe_icat::-----------
psql -h localhost -U irods -d "ICAT_BKP1" <  /var/lib/irods/myrules/mydb-irods422_dump.sql




setup irods::-----------
------------------------
from root

python /var/lib/irods/scripts/setup_irods.py

reply on interactive installation:

user:irods password:xxxx 

-------------------------------------------
"zone_key": "XXXXXXXX_ZONE_SID"
"negotiation_key": "XXXXXXXX_byte_key_for_agent__conn",
"server_control_plane_key": "XXXXXXXX__32byte_ctrl_plane_key"
"xmsg_port": 1279,
"zone_auth_scheme": "native",
"zone_name": "XXXXXXXX",
"zone_port": 1247,
"zone_user": "XXXXXXXX"

4)
start IRODS:
===========

become irods user
su - irods

cd /var/lib/irods
./irodsctl start

5)
check IRODS:
=========================

(su - irods)

iinit
(pswd)

ils 
/INGV/home/rods
--> irods works!


6) B2SAFE & B2HANDLE:
====================

### Make packages

check install.conf into /opt/eudat/b2safe/B2SAFE-core/packaging if is correctly setting - permission owner (irods)
chek owner and permission in /opt/eudat/cert/ (owner : irods  - 0644)

su - irods
cd /opt/eudat/b2safe/B2SAFE-core/packaging
./create_deb_package.sh
sudo dpkg -i /home/irods/debbuild/irods-eudat-b2safe_4.1-1.deb


# install/configure B2Safe as the user who runs iRODS
sudo -s source /etc/irods/service_account.config
cd /opt/eudat/b2safe/B2SAFE-core/packaging
 ./install.sh
 ATTENTION-> password for EPIC prefix required! XXXXXXXX

# install B2HANDLE
cd /opt/eudat/B2HANDLE/dist/
 sudo easy_install b2handle-1.1.1-py2.7.egg


7) check B2Safe B2Handle:
=========================

# B2Safe::

cd /opt/eudat/b2safe/B2SAFE-core/rules

irule -vF eudatGetV.r

--> B2Safe works!


# B2Handle::

/opt/eudat/b2safe/cmd/epicclient.py os /opt/eudat/b2safe/conf/credentials create www.test-b2safe1.com

/opt/eudat/b2safe/cmd/epicclient2.py os /opt/eudat/b2safe/conf/credentials create www.Bella-b2safe3.com

REMEMBER-> copy epicclient2.py on epicclient.py 'couse B2SAFE use only epicclient.py 

--> B2Handle works!



8) build Federation
===================

in server_config.json add:


     "federation": [
         {
        "catalog_provider_hosts": [ "remote.address.federated.node"],
        "zone_name": "XXXXXXXX",
        "zone_key": "XXXXXXXX_ZONE_SID",
        "negotiation_key": "XXXXXXXX_32_byte_key_for_agent__conn"
        }
     ],



make remote Zone and User:
 iadmin mkzone XXXXXXXX remote remote.address.federated.node
 iadmin mkuser zzzz#XXXXX rodsuser

grant to remote user
 ichmod -rV own zzzz#XXXXX /XXXXX/home/zzzz
 ichmod -rV inherit /XXXXX/home/zzzz

add password
moduser Name#Zone(zzzz#XXXXX) password -newValue




