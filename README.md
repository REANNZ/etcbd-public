
#  eduroam tools container-based deployment #

## Overall considerations

The ancilliary tools package comprises three separate tools:
* admintool
* metrics
* monitoring

Each of the tools is (at the moment) designed to run in an isolated environment - so on a separate docker host.

Please create three separate VMs with Docker, one for each of the tools.

## Preliminaries

Install and configure Docker.  Please follow https://docs.docker.com/engine/installation/

## Basic setup

On each of the VMs, start by cloning the git repository:

    git clone https://github.com/REANNZ/etcbd-public

# Deploying admintool

Modify the ````admintool.env```` file with deployment parameters - override at least the following values:

* SITE_PUBLIC_HOSTNAME: the hostname this site will be visible as
* LOGSTASH_HOST: the hostname the metrics tools will be visible as
* ADMIN_EMAIL: where to send notifications
* EMAIL_* settings to match the local environment (server name, port, TLS and authentication settings)
* SERVER_EMAIL: outgoing email address to use in notifications
* ALL PASSWORDS (administrator, db connection and postgres master password)
* GOOGLE_KEY/GOOGLE_SECRET - provide Key + corresponding secret for an API credential (see below on configuring this one)
* Configure other prameters to match the deployment (REALM_*, TIME_ZONE, MAP_CENTER_*)
  * This includes the optional import of existing data (default imports REANNZ data)

This file is used by both the containers to populate runtime configuration and by a one-off script to populate the database.

Use Docker-compose to start the containers:

    cd etcbd-public/admintool
    docker-compose build && docker-compose up -d

Run the setup script:

    ./admintool-setup.sh admintool.env

Optional: Install proper SSL certificates into /var/lib/docker/host-volumes/admintool-apache-certs/server.{crt,key}


# Deploying monitoring tools

Modify the ````icinga.env```` file with deployment parameters - override at least the following values:

* SITE_PUBLIC_HOSTNAME: the hostname this site will be visible as
* ICINGA_ADMIN_EMAIL: where to send notifications
* EMAIL_* settings to match the local environment (server name, port, TLS and authentication settings)
* ALL PASSWORDS (administrator, db connection and postgres master password)

This file is used by both the containers to populate runtime configuration and by a one-off script to populate the database.

Use Docker-compose to start the containers:

    cd etcbd-public/icinga
    docker-compose build && docker-compose up -d

Run the setup script:

    ./icinga-setup.sh icinga.env

Optional: Install proper SSL certificates into /var/lib/docker/host-volumes/icinga-apache-certs/server.{crt,key}

# Deploying metrics tools

Use Docker-compose to start the containers:

    cd etcbd-public/elk
    docker-compose build && docker-compose up -d


# Appendix: Google Login

To get the Google credential (key+secret) to use in the admintool, do the following in the Google Developer Console:

* Start at http://console.developers.google.com/
* Create a new project
* From the main menu, select the API Manager
* Select Credentials
* Configure the OAuth consent screen with how the application shouldb be described to the user (at least, set Product name)
* Create a new Credential as an OAuth Client ID for a web application
* Add the Authorized redirect URI for your application - the form is (substitute your real hostname here):

        https://admin.example.org/accounts/complete/google-oauth2/

* After saving, this gives you the Client ID and secret (use these as the GOOGLE_KEY and GOOGLE_SECRET)

