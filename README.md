# B2SAFE All-in-One Docker container

This is a whole B2SAFE environment in a single Docker container, and with a simplified scripted deployment procedure. It includes PostgreSQL, the ICAT database for iRODS, iRODS itself, and B2HANDLE.

The Docker container created is named `eudat_b2safe` and publishes ports 1247, 1248, 5432, and the range 20000-20199. There are several volumes (host directories) mounted on container, they are (in the form `host_directory:container_directory`):

* Database data directory: `/data/b2safe_icat_db:/var/lib/postg2safe`

* Repository of miniSEED files: `/mnt/seedstore_nfs:/var/lib/datairods`

* Rules directory: `/opt/eudat/b2safeRules:/var/lib/irods/myrules`

* Vault directory (the directory used by irods to store files - not for our case but useful) `/opt/eudat/b2safeVault:/var/lib/irods/Vault`

These volumes are mounted in order to make persistent all data inside iRODS and ICAT, the rules directory can be also used to update scripts, if needed, without going inside the container. All of this is defined in the `docker run` command of `setup.sh`.

## Prerequisites

Since the whole service is fitted inside a Docker container, the only prerequisite is Docker itself.

## Deployment

The service is configured and launched with just a few steps:

1. Copy the `.pem` certificate files to `cert_ca/`, `cert_key/`, and `cert_only/` directories.

1. Fill in the username and password for the irods database user, in the line 26 of `installer.sh`.

1. Run the setup script `setup.sh`. This will build the Docker container, launch it, and then install iRODS, B2SAFE and B2HANDLE into it.
<br>The iRODS setup will interactively ask for user input on its configuration. For more information about these values, see the [iRODS beginner training](https://github.com/irods/irods_training/tree/ugm2018/beginner).
<br>For most variables, the default values should be used, but we want to call special attention to a few of them. Database username and password must be the same defined in the preceding step, in `installer.sh`. For iRODS user and server's administrator username, the default values should be used, `irods` and `rods`, respectively. iRODS server's administrator password must be defined and kept safe. It is also important to keep the iRODS server's zone, negotiation and control plane keys, because they will be used for federation.

1. Start up the iRODS service, by running `start.sh`. 

It is possible to check if iRODS is running, with the following command:
```
docker exec -it --user irods eudat_b2safe ils
```
Its response should be something like `/tempZone/home/rods`.
