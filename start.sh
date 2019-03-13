#!/bin/bash
# start eudat_b2safe

docker start eudat_b2safe

docker exec -it eudat_b2safe bash -c 'service postgresql start'

# until docker exec -it --user postgres eudat_b2safe psql -c "select 1" > /dev/null 2>&1; do sleep 2; done

docker exec -it --user irods eudat_b2safe /var/lib/irods/irodsctl start
