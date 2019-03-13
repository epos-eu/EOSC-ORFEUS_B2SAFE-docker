#!/bin/bash
# setup b2safe all 


docker build -t "b2safe_aio:4.1.1" .


docker run -it --name eudat_b2safe  -v /data/b2safe_icat_db:/var/lib/icat_db -v /mnt/seedstore_nfs:/var/lib/datairods -v /opt/eudat/b2safeRules:/var/lib/irods/myrules -v /opt/eudat/b2safeVault:/var/lib/irods/Vault -p 1247:1247 -p 1248:1248 -p 5432:5432 -p 20000-20199:20000-20199   b2safe_aio:4.1.1 bash -c '/root/installer.sh'



