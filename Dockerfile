## simple irods-B2Safe all in one
## docker build -t "b2safe_aio:4.1.1" .


FROM ubuntu:16.04
MAINTAINER massimo.fares@ingv.it

RUN apt-get update

###
### base ###
###

RUN apt-get update && apt-get install -y lsb-core 
RUN apt-get install -y wget git rsync
RUN apt-get install -y apt-transport-https 
RUN apt-get install -y sudo vim
RUN apt-get install -y ca-certificates


###
### postgresql ###
###

RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
RUN apt-get -y update
RUN apt-get -y upgrade
RUN sudo apt-get install -y postgresql postgresql-contrib libpq-dev pgadmin3

###
### irods-server ####
###
RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | sudo apt-key add -
RUN echo "deb [arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/renci-irods.list
RUN sudo apt-get update
RUN sudo apt-get install -y irods-server irods-database-plugin-postgres


###
### B2Safe & B2Handle ####
###

### Prerequisites

RUN sudo apt-get install -y python-pip
RUN sudo pip install queuelib
RUN sudo pip install dweepy
RUN sudo pip install psycopg2-binary
RUN sudo apt-get install -y python-lxml
RUN sudo apt-get install -y python-defusedxml
RUN sudo apt-get install -y python-httplib2
RUN sudo apt-get install -y python-simplejson

### make irods user

RUN adduser --disabled-password --gecos '' irods
RUN adduser irods sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


### clone B2Safe

RUN mkdir -p /opt/eudat/b2safe
WORKDIR /opt/eudat/b2safe
RUN git clone https://github.com/EUDAT-B2SAFE/B2SAFE-core
WORKDIR /opt/eudat/b2safe/B2SAFE-core/packaging
USER irods
RUN ./create_deb_package.sh
USER root

### clone B2Handle

WORKDIR /opt/eudat
RUN git clone https://github.com/EUDAT-B2SAFE/B2HANDLE
WORKDIR /opt/eudat/B2HANDLE/
RUN python setup.py bdist_egg


### config & certs
RUN chown -R irods:irods /opt/eudat
USER irods
RUN mkdir -p /opt/eudat/cert

COPY conf/install.conf    /opt/eudat/b2safe/B2SAFE-core/packaging
# RUN chown irods:irods /opt/eudat/b2safe/B2SAFE-core/packaging/install.conf

COPY cert_key/*.pem    /opt/eudat/cert 
COPY cert_only/*.pem    /opt/eudat/cert
COPY cert_ca/*.pem    /opt/eudat/cert
# RUN chmod 0644 /opt/eudat/cert/*.pem

USER root

COPY installer.sh /root/installer.sh
RUN chmod +x /root/installer.sh

WORKDIR /root


EXPOSE 5432 1247 1248 20000-20199
