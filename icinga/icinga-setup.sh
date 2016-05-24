#!/bin/bash

# Load the local deployment environment variables
# (and filtre the syntax to quote the values first)
eval $( cat "$@" | sed 's/=\(.*\)/="\1"/' )

# Create databases in the Icinga Postgres Instance
# Run a command in the Postgres database to create the role and database
# Equivalant to:
#     psql --command="create role $DB_USER with login encrypted password '$DB_PASSWORD' ;"
#     psql --command="create database $DB_NAME with owner $DB_USER encoding 'UTF8';"

# Icinga2 database

docker exec postgres-icinga gosu postgres psql --command="create role $ICINGA_DB_USER with login encrypted password '$ICINGA_DB_PASSWORD' ;"
docker exec postgres-icinga gosu postgres psql --command="create database $ICINGA_DB_NAME with owner $ICINGA_DB_USER;"

# Populate structure - invoke psql on postgres host directly
{ echo "set role $ICINGA_DB_USER;" ; docker exec icinga cat /usr/share/icinga2-ido-pgsql/schema/pgsql.sql ; } | docker exec -i postgres-icinga gosu postgres psql icinga

# Icingaweb2 database

docker exec postgres-icinga gosu postgres psql --command="create role $ICINGAWEB2_DB_USER with login encrypted password '$ICINGAWEB2_DB_PASSWORD' ;"
docker exec postgres-icinga gosu postgres psql --command="create database $ICINGAWEB2_DB_NAME with owner $ICINGAWEB2_DB_USER;"

# Populate structure - invoke psql on postgres host directly
{ echo "set role $ICINGAWEB2_DB_USER;" ; docker exec icingaweb cat /usr/share/icingaweb2/etc/schema/pgsql.schema.sql ; } | docker exec -i postgres-icinga gosu postgres psql icingaweb2

# Create the admin user
ICINGAWEB2_ADMIN_PASSWORD_HASH=$( openssl passwd -1 "$ICINGAWEB2_ADMIN_PASSWORD" )
docker exec -i postgres-icinga gosu postgres psql icingaweb2 <<-EOF
	INSERT INTO icingaweb_user (name, active, password_hash) VALUES ('$ICINGAWEB2_ADMIN_USER', 1, DECODE('$ICINGAWEB2_ADMIN_PASSWORD_HASH', 'escape'));
	INSERT INTO icingaweb_group (name) VALUES ('Administrators');
	INSERT INTO icingaweb_group_membership (group_id, username) VALUES (1, '$ICINGAWEB2_ADMIN_USER');
EOF

