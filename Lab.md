
#  Eduroam Ancillary Services: Lab exercises #

In these exercises, you should develop familiarity with Docker, Docker-compose, and with the three key Eduroam Ancillary Services: admintool, metrics and monitoring.  You should learn how to customize and deploy these tools with Docker.  And you should get to a running configuration of these tools.

You can see more about the tools in the main [README.md](README.md) - but please return here for instructions.

# Docker 101 #

Install and configure Docker.  Please follow our [Docker setup instructions](Docker-setup.md).

Please become familer with Docker by following our [Docker introduction](Docker-intro.md).

# Sysadmin 101 #

On these VMs, you will need to configure a mail server: please follow our [mail server configuration instructions](README.md#preliminaries---mail-server) and returh here.

TODO: set VM hostname

# Admintool - basic installation #

# Eduroam ancillary tools: Basic setup

Start by cloning the git repository with deployment packages for all of the ancillary services - and navigate into the admintool specific directory:

    git clone https://github.com/REANNZ/etcbd-public
    cd etcbd-public/admintool

# Deploying admintool - first iteration

Modify the ````admintool.env```` file with deployment parameters - override at least the following values:

* Pick your own admin password: ````ADMIN_PASSWORD````
* Pick internal DB passwords: ````DB_PASSWORD````, ````POSTGRES_PASSWORD````
* ````SITE_PUBLIC_HOSTNAME````: the hostname this site will be visible as.  Enter your VM hostname: ````xeap-wsNN.aarnet.edu.au````
* ````LOGSTASH_HOST```` is where your metrics will run - the same VM
* ````EMAIL_HOST```` - configure to use your VM.  Leave other ````EMAIL_*```` settings unset.
* ````SERVER_EMAIL```` - From: address in outgoing emails.  Pick your own.
* ````ADMIN_EMAIL```` - administrator email address to receive notifications / approval requests.  Enter your own email address.
* ````REALM_COUNTRY_CODE```` / ````REALM_COUNTRY_NAME```` - your eduroam country
* ````TIME_ZONE```` - your local timezone (for the DjNRO web application)
* ````MAP_CENTER_LAT````, ````MAP_CENTER_LONG```` - pick your location
* ````REALM_EXISTING_DATA_URL```` - leave in to import REANNZ data, set to blank to start with an empty database
 
And in global-env.env, customize system-level ````TZ```` and ````LANG```` as preferred.

For now, leave out ````GOOGLE_SECRET```` ````GOOGLE_KEY```` - these will be configured in a later exercises to enable login.

The ````admintool.env```` is used by both the containers to populate runtime configuration and by a one-off script to populate the database.

Use Docker-compose to start the containers:

    docker-compose up

And in another session, run the setup script:

    cd etcbd-public/admintool
    ./admintool-setup.sh admintool.env

# Admintool lab exercise: explore admintool and add your own organization.

Navigate to http://xeap-wsNN.aarnet.edu.au - you will need to accept the SSL certificate warning.

# Docker-compose 101 

At this point, please become familiar with Docker-compose by following our [Introduction to Docker-compose](Docker-compose-intro.md):



# Deploying metrics tools

The metrics tools are using the ELK stack (ElasticSearch, Logstash, Kibana) - and are also deployed with Docker.

The only configuration parameters is the system-wide global.env - which can be customized the same way as done for the admintool.

Use Docker-compose to start the containers (copying over global.env from admintool):

    cd etcbd-public/elk
    cp ../admintoool/global-env.env .
    docker-compose up -d

This gets the metrics tools running, but we need to push some data into the tools before we can explore them.


# Connect admintool to ELK

We have provided a standalone module that can push Apache logs from the admintool into the metrics tool.  While this is primarily a proof of concept, this may provide valueable insight into the use of the admintool as well.

The shipping of logs is done by filebeat - which has been prepared as a container configured to run as part of the admintool.

* Navigate into the admintool directory (````~/etcbd-public/admintool````) and in the ````docker-compose.yml```` file, uncomment the ````filebeat```` container (remove the leading ````#```` character from all start .

* Tell docker-compose to pull the image for the filebeat container

         cd ~/etcbd-public
         docker-compose pull

* Use docker-compose to start the filebeat container:

         docker-compose up -d

* And watch the logs:

         docker-compose logs


# Explore ELK (metrics tools) #

Now that we have at least the Apache data being pushed into ELK, start exploring the Metrics tools at http://xeap-wsNN.aarnet.edu.au:5601/

* On first access, you will need to create an index - just push the Create Index button

* Explore the log messages received - and the fields they are parsed by


# Deploying monitoring tools

Modify the ````icinga.env```` file with deployment parameters - override at least the following values:

* Pick your own admin password: ````ICINGAWEB2_ADMIN_PASSWORD````
* Pick internal DB passwords: ````ICINGA_DB_PASSWORD````, ````ICINGAWEB2_DB_PASSWORD````, ````POSTGRES_PASSWORD````
* ````SITE_PUBLIC_HOSTNAME````: the hostname this site will be visible as.  Enter your VM hostname: ````xeap-wsNN.aarnet.edu.au````
* ````EMAIL_HOST```` - configure to use your VM.  Leave other ````EMAIL_*```` settings unset.
* ````EMAIL_FROM```` - From: address in outgoing emails.  Pick your own.
* ````ICINGA_ADMIN_EMAIL```` - administrator email address to receive notifications.  Enter your own email address.

This file is used by both the containers to populate runtime configuration and by a one-off script to populate the database.
 
Additionally, in global-env.env, customize system-level ````TZ```` and ````LANG```` as preferred - or you can copy over global.env from admintool:

    cd etcbd-public/icinga
    cp ../admintoool/global-env.env .

Use Docker-compose to start the containers:

    cd etcbd-public/icinga
    docker-compose up

And in another session, run the setup script:

    cd etcbd-public/icinga
    ./icinga-setup.sh icinga.env

# Monitoring the institutional radius server

The monitoring tools (Icinga) come with functionality for monitoring a radius server.

In ````icinga.env````, make sure these parameters (````EDUROAM_*````) match the settings of your institutional freeradius server.  They come with the same defaults - so just make the same changes as on your freeradius server.

After updating this file, restart the containers with:

    cd etcbd-public/icinga
    docker-compose stop
    docker-compose up -d

# Confirm all services report OK in icingaweb #

Now explore the monitoring tools at https://xeap-wsNN.aarnet.edu.au:8443/ (and log in as ````admin```` with the password selected above).

* Please confirm all services are reporting OK.  Troubleshoot any issues.

* Please test sending alerts works all fine - send a test message for one of the services.


# Bonus Question: Configuring Google Login for Admintool

To enable Google login in the Admintool, you first need to register your application with Google and get an application key and a secret to use.

To get the Google credential (key+secret) to use in the admintool, do the following in the Google Developer Console:

* Start at http://console.developers.google.com/
* Create a new project
* From the main menu, select the API Manager
* Select Credentials
* Configure the OAuth consent screen with how the application should be described to the user (at least, set Product name)
* Create a new Credential as an OAuth Client ID for a web application
* Add the Authorized redirect URI for your application - the form is (substitute your real hostname here):

        https://xeap-wsNN.aarnet.edu.au/accounts/complete/google-oauth2/

* After saving, this gives you the Client ID and secret (use these as the GOOGLE_KEY and GOOGLE_SECRET)

* Go again to the admintool deployment directory (````~/etcbc-public/admintool````) and enter these into ````admintool.env````.
* Now, restart the admintool with the new setttings:

        cd etcbd-public/admintool
        docker-compose stop
        docker-compose up -d

# Bonus Question: Become an institutional administrator in Admintool

TODO

# Bonus Question: Connect radius server to ELK (switch to docker-compose)

TODO

# Extra Credit Bonus Question: Commit your local config changes (except passwords) into git

TODO

# Extra Credit Bonus Question: Clone our public repo on github and push your changes there

TODO

