#!/bin/bash

if [ $# -eq 0 ] ; then
    echo "Usage: $0 environment_file(s).."
    exit 1
fi
# Load the local deployment environment variables
# (and filtre the syntax to quote the values first)
eval $( cat "$@" | sed 's/=\(.*\)/="\1"/' )



# Create databases in the Postgres Image
# Run a command in the Postgres database to create the role and database
# Equivalant to:
#   create role djnrodev with login encrypted password 'djnrodev';
#   create database djnrodev with owner djnrodev;

docker exec postgres gosu postgres psql --command="create role $DB_USER with login encrypted password '$DB_PASSWORD' ;"
docker exec postgres gosu postgres psql --command="create database $DB_NAME with owner $DB_USER;"

# Initialize database on the Django side - and create super user
docker exec djnro /envwrap.sh ./manage.py migrate
docker exec djnro /envwrap.sh ./manage.py createsuperuser --noinput --username "$ADMIN_USERNAME" --email "$ADMIN_EMAIL"
docker exec -it djnro /envwrap.sh ./manage.py changepassword "$ADMIN_USERNAME" <<-EOF
	$ADMIN_PASSWORD
	$ADMIN_PASSWORD
EOF

# load django fixtures - initial data
docker exec djnro /envwrap.sh ./manage.py loaddata initial_data/fixtures_manual.xml

# run fetch-kml one-off:
docker exec djnro /envwrap.sh ./manage.py fetch_kml

# create initial realm
docker exec -i djnro /envwrap.sh ./manage.py shell <<-EOF
	from edumanage.models import Realm, Name_i18n
	r=Realm(country="$REALM_COUNTRY_CODE")
	r.save()
	rn=Name_i18n(content_object=r,name="$NRO_INST_NAME",lang="en")
	rn.save()
	exit()
EOF

# Configure the name of the Django site
docker exec -i djnro /envwrap.sh ./manage.py shell <<-EOF
	from django.contrib.sites.models import Site
	site = Site.objects.get(name="example.com")
	site.name="$SITE_PUBLIC_HOSTNAME"
	site.domain="$SITE_PUBLIC_HOSTNAME"
	site.save()
	exit()
EOF

# import initial data
if [ -n "$REALM_EXISTING_DATA_URL" ] ; then
    # NOTE: this exact spelling
    docker exec djnro curl -o djnro/institution.xml "$REALM_EXISTING_DATA_URL"
    docker exec djnro /envwrap.sh ./manage.py parse_institution_xml --verbosity=0 djnro/institution.xml
fi

