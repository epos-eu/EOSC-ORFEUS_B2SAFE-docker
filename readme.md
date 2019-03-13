# B2SAFE All-in-One Docker container

This is a whole B2SAFE environment in a single Docker container. It includes PostgreSQL, the ICAT database for iRODS, iRODS itself, and B2HANDLE.

## Setup and deployment

note: every name and directory are not mandatory (except for the database) they could be whatever.

### 1) Build the Docker image
```
docker build -t "b2safe_aio:4.1.1" .
```
(4.1.1 is the B2SAFE version)

### 2) Launch the container
```
docker run -it --name eudat_b2safe  -v /data/b2safe_icat_db:/var/lib/postg2safe -v /mnt/seedstore_nfs:/var/lib/datairods -v /opt/eudat/b2safeRules:/var/lib/irods/myrules -v /opt/eudat/b2safeVault:/var/lib/irods/Vault -p 1247:1247 -p 1248:1248 -p 5432:5432 -p 20000-20199:20000-20199   b2safe_aio:4.1.1 /bin/bash
```

There are several volumes (host directories) mounted on container, they are:

* Database data directory: `/data/b2safe_icat_db:/var/lib/postg2safe`

* Repository of miniSEED files: `/mnt/seedstore_nfs:/var/lib/datairods`

* Rules directory: `/opt/eudat/b2safeRules:/var/lib/irods/myrules`

* Vault directory (the directory used by irods to store files - not for our case but useful) `/opt/eudat/b2safeVault:/var/lib/irods/Vault`

These volumes are mounted in order to make persistent all data inside iRODS and ICAT, the rules directory can be also used to update scripts, if needed, without going inside the container.

After the Docker container is started, the command prompt is into the container. From this point on, all commands are input from insite the container.

### 3) Setup ICAT and iRODS

First, configure PostgreSQL to use `/var/lib/postg2safe` as its data directory, instead of the default `/var/lib/postgresql`.

Start by stopping the `postgresql` service, creating the new directory, and backing up the old one:
```
service postgresql  stop

mkdir /var/lib/postg2safe
chown -R postgres:postgres /var/lib/postg2safe/
rsync -av /var/lib/postgresql/ /var/lib/postg2safe/
mv /var/lib/postgresql/10/main/ /var/lib/postgresql/10/main.bak
```

Then, edit the file `/etc/postgresql/10/main/postgresql.conf`. In the line 41, replace
```
data_directory = '/var/lib/postgresql/10/main'
```
with
```
data_directory = '/var/lib/postg2safe/10/main'
```

Finally, restart PostgreSQL.
```
service postgresql start
```

The next step it to prepare the `ICAT` database that will be used by iRODS. As the `postgres` user, launch the `psql` console and create the database:

```
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
```

eventually restore
```
postgresql restore old b2safe_icat
psql -h localhost -U irods -d "ICAT_BKP1" <  /var/lib/irods/myrules/mydb-irods422_dump.sql
```

Now, we are ready to setup iRODS. Back as the root user, launch the setup script with
```
python /var/lib/irods/scripts/setup_irods.py
```

This script interactively asks for a number of answers about the installation.

reply on interactive installation:
```
user:irods password:xxxx 
```
be aware for these values
```
-------------------------------------------
"zone_key": "XXXXXXXX_ZONE_SID"
"negotiation_key": "XXXXXXXX_byte_key_for_agent__conn",
"server_control_plane_key": "XXXXXXXX__32byte_ctrl_plane_key"
"xmsg_port": 1279,
"zone_auth_scheme": "native",
"zone_name": "XXXXXXXX",
"zone_port": 1247,
"zone_user": "XXXXXXXX"
```

### 4) Start iRODS

Become the `irods` user and start the service:

```
su - irods

cd /var/lib/irods
./irodsctl start
```

### 5) Check iRODS status

In order to test if the setup is successful, log into iRODS and try an iCommand:
```
su - irods

iinit
(pswd)

ils 
/INGV/home/rods
```
--> irods works!

### 6) Setup B2SAFE and B2HANDLE

Again as `irods`, build the B2SAFE package.

check install.conf into /opt/eudat/b2safe/B2SAFE-core/packaging if is correctly setting - permission owner (irods)
chek owner and permission in /opt/eudat/cert/ (owner : irods  - 0644)

```
su - irods
cd /opt/eudat/b2safe/B2SAFE-core/packaging
./create_deb_package.sh
sudo dpkg -i /home/irods/debbuild/irods-eudat-b2safe_4.1-1.deb
```

Then install/configure B2SAFE:
```
sudo -s source /etc/irods/service_account.config
cd /opt/eudat/b2safe/B2SAFE-core/packaging
./install.sh
```

ATTENTION-> password for EPIC prefix required! XXXXXXXX

To install B2HANDLE, we use an `.egg` Easy Install package:
```
cd /opt/eudat/B2HANDLE/dist/
sudo easy_install b2handle-1.1.1-py2.7.egg
```

### 7) Check B2SAFE and B2HANDLE status

To check the status of B2SAFE, run a basic rule:
```
cd /opt/eudat/b2safe/B2SAFE-core/rules
irule -vF eudatGetV.r
```

To check the status of B2HANDLE, run the two EPIC client scripts:
```
/opt/eudat/b2safe/cmd/epicclient.py os /opt/eudat/b2safe/conf/credentials create www.test-b2safe1.com
/opt/eudat/b2safe/cmd/epicclient2.py os /opt/eudat/b2safe/conf/credentials create www.Bella-b2safe3.com
```

REMEMBER-> copy epicclient2.py on epicclient.py 'couse B2SAFE use only epicclient.py 

--> B2Handle works!



### 8) Build Federation

in server_config.json add:

```
     "federation": [
         {
        "catalog_provider_hosts": [ "remote.address.federated.node"],
        "zone_name": "XXXXXXXX",
        "zone_key": "XXXXXXXX_ZONE_SID",
        "negotiation_key": "XXXXXXXX_32_byte_key_for_agent__conn"
        }
     ],

```

make remote Zone and User:
```
 iadmin mkzone XXXXXXXX remote remote.address.federated.node
 iadmin mkuser zzzz#XXXXX rodsuser
```

grant to remote user
```
 ichmod -rV own zzzz#XXXXX /XXXXX/home/zzzz
 ichmod -rV inherit /XXXXX/home/zzzz
```

add password
```
moduser Name#Zone(zzzz#XXXXX) password -newValue
```
