
#  Eduroam tools container-based deployment: Overall considerations #

The ancilliary tools package consists of three separate sets of tools:
* admintool
* metrics
* monitoring

Each of the tools is (at the moment) designed to run in an isolated environment.  They can be run on a single docker host by mapping each to a different port.  The configuration files provided here are designed this way:

* Admintool runs on ports 80 and 443 (HTTP and HTTPS)
* Monitoring tools run on ports 8080 and 8443 (HTTP and HTTPS)
* Metrics runs on port 5601 (plain HTTP only)

# Preliminaries - Docker

Install and configure Docker.  Please follow our [Docker setup instructions](Docker-setup.md).

Please become familer with Docker by following our [Docker introduction](Docker-intro.md).

# Preliminaries - Mail server

Some of the tools (admintool and monitoring) will need to send outgoing email.  On these VMs, the easiest solution is to configure a local mail server (postfix) to deliver the outgoing emails.  You can then use the VM as the mail server when configuring the admintool and the monitoring tools.

* Install postfix:

        apt-get install postfix

* When prompted, enter:

        Mail host name: xeap-ws23.aarnet.edu.au

* Edit ````/etc/postfix/main.cf```` and add ````172.17.0.0/16```` to ````mynetworks````
* Reload postfix:

        service postfix reload


# Eduroam ancillary tools: Basic setup

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
    docker-compose up -d

Run the setup script:

    ./admintool-setup.sh admintool.env

At this point, please become familiar with Docker-compose by following our [Introduction to Docker-compose](Docker-compose-intro.md):

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
    docker-compose up -d

Run the setup script:

    ./icinga-setup.sh icinga.env

Optional: Install proper SSL certificates into /var/lib/docker/host-volumes/icinga-apache-certs/server.{crt,key}

# Deploying metrics tools

Use Docker-compose to start the containers:

    cd etcbd-public/elk
    docker-compose up -d


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

