
#  Eduroam Ancillary Services: Lab exercises #

In these exercises, you should develop familiarity with Docker, Docker-compose, and with the three key Eduroam Ancillary Services: admintool, metrics and monitoring.  You should learn how to customize and deploy these tools with Docker.  And you should get to a running configuration of these tools.

Please note: these instructions are meant only to be used as part of the eduroam tutorial at APAN46.

For production deployment of the eduroam tools, please follow the instructions
in the main [README.md](README.md) file - these instructions are targeted at
production deployment and are kept up to date with the development of the
eduroam tools.

#  Eduroam tools container-based deployment: Overall considerations #

The ancilliary tools package consists of three separate sets of tools:
* admintool
* metrics
* monitoring

Each of the tools is (at the moment) designed to run in an isolated environment.  They can be run on a single docker host by mapping each to a different port.  The configuration files provided here are designed this way:

* Admintool runs on ports 80 and 443 (HTTP and HTTPS)
* Monitoring tools run on ports 8080 and 8443 (HTTP and HTTPS)
* Metrics tools runs on ports 9080 and 9443 (HTTP and HTTPS)

# Docker 101 #

Install and configure Docker.  Please follow our [Docker setup instructions](Docker-setup.md).

Please become familer with Docker by following our [Docker introduction](Docker-intro.md).


# Sysadmin 101 #

Some of the tools (admintool and monitoring) will need to send outgoing email.  On these VMs, the easiest solution is to configure a local mail server (postfix) to deliver the outgoing emails.  You can then use the VM as the mail server when configuring the admintool and the monitoring tools.

Run the following commands as root - e.g., via ````sudo -s````:

* Install postfix:

        apt-get install postfix

* When prompted:
  * Select `Internet Site` (direct mail delivery)
  * And for `System mail name`, enter the hostname of your system - e.g.:

          Mail host name: xx-rad1.tein.aarnet.edu.au

* Edit ````/etc/postfix/main.cf```` and add ````172.16.0.0/12```` to ````mynetworks```` (to permit all internal virtual networks created by Docker to send mail via this server)
* Reload postfix:

        service postfix reload

* Allow Docker containers to reach SMTP on the VM:

        ufw allow proto tcp from 172.16.0.0/12 to any port 25

# Eduroam ancillary tools: Basic setup

Start by cloning the git repository with deployment packages for all of the ancillary services - and navigate into the admintool specific directory:

    git clone https://github.com/REANNZ/etcbd-public
    cd etcbd-public/admintool


# Deploying admintool - first iteration

Modify the ````admintool.env```` file with deployment parameters - override at least the following values:

* Pick your own admin password: ````ADMIN_PASSWORD````
* Pick internal DB passwords: ````DB_PASSWORD````, ````POSTGRES_PASSWORD````
  * Generate these with: ````openssl rand -base64 12````
* ````SITE_PUBLIC_HOSTNAME````: the hostname this site will be visible as.  Enter your VM hostname: `xx--rad1.tein.aarnet.edu.au`
* ````LOGSTASH_HOST```` is where your metrics will run - the same VM
* ````EMAIL_HOST```` - configure to use your VM.  Leave other ````EMAIL_*```` settings unset.
* ````SERVER_EMAIL```` - From: address in outgoing emails.  Pick your own.
* ````ADMIN_EMAIL```` - administrator email address to receive notifications / approval requests.  Enter your own email address.
* ````REALM_COUNTRY_CODE```` / ````REALM_COUNTRY_NAME```` - your eduroam country
* ````TIME_ZONE```` - your local timezone (for the DjNRO web application)
* ````REALM_EXISTING_DATA_URL```` - leave blank to start with an empty databas, or set to `https://member.eduroam.net.nz/general/institution.xml` to import REANNZ data
 
And in ````global-env.env````, customize system-level ````TZ```` and ````LANG```` as preferred.

For now, leave out `GOOGLE_SECRET` `GOOGLE_KEY` and `GOOGLE_API_KEY` - these will be configured in a later exercise (to enable login via Google and to properly configure Google Maps).

The ````admintool.env```` is used by both the containers to populate runtime configuration and by a one-off script to populate the database.

Use Docker-compose to start the containers:

    docker-compose up -d
    docker-compose logs -f

And in another session, run the setup script:

    cd etcbd-public/admintool
    ./admintool-setup.sh admintool.env

Please note: the `admintool-setup.sh` script should be run only once.
Repeated runs of the script would lead to unpredictable results (some database structures populated multiple times).

# Admintool lab exercise: explore admintool and add your own institution.

* Navigate to https://xx-rad1.tein.aarnet.edu.au/ - you will need to accept the SSL certificate warning.
  * This gives you the user view.
  * Explore.
  * Do not worry about the Google Maps "Development only" warning - we will fix this later by adding an API key.

* Navigate to https://xx-rad1.tein.aarnet.edu.au/admin/ and log in with the admin username and password as selected above.
  * This gives you the NRO admin view.
  * As the NRO operator, create your own institution.


# Docker-compose 101 

At this point, please become familiar with Docker-compose by following our [Introduction to Docker-compose](Docker-compose-intro.md):


# Deploying metrics tools

The metrics tools are using the ELK stack (ElasticSearch, Logstash, Kibana) - and are also deployed with Docker.

There are a few settings to configure: start by copying over `global-env.env` from Admintool:

    cd ~/etcbd-public/elk
    cp ../admintoool/global-env.env .

Modify the `elk.env` file with deployment parameters - override at least the following values:

* Pick your own admin password: ````ADMIN_PASSWORD````
* `SITE_PUBLIC_HOSTNAME`: the hostname this site will be visible as.  Enter your VM hostname: `xx--rad1.tein.aarnet.edu.au`
* `LOCAL_COUNTRY`: two-letter country code of the local country (for metrics to identify domestic and international visitors and remote sites).
* `INST_NAMES`: white-space delimited list of domain names of institutions to generate per-instititon dashboard and visualizations for.

Use Docker-compose to start the containers:

    docker-compose up -d
    docker-compose logs -f

And we now also need to run the setup script that initializes the ELK system:

    cd ~/etcbd-public/elk
    ./elk-setup.sh

We now have the metrics tools running, but we need to push some data into the tools before we can explore them.


# Connect admintool to ELK

We have provided a standalone module that can push Apache logs from the admintool into the metrics tool.  While this is primarily a proof of concept, this may provide valueable insight into the use of the admintool as well.

The shipping of logs is done by filebeat - which has been prepared as a container configured to run as part of the admintool.

* Navigate into the admintool directory (`~/etcbd-public/admintool`) and in the `docker-compose.yml` file, uncomment the `filebeat` container (remove the leading `#` character from all start of all lines in that section.

* Tell docker-compose to pull the image for the filebeat container

         cd ~/etcbd-public/admintool
         docker-compose pull

* Use docker-compose to start the filebeat container:

         docker-compose up -d

* And watch the logs:

         docker-compose logs -f


# Explore ELK (metrics tools) #

Now that we can have at least the Apache data being pushed into ELK, start exploring the Metrics tools at https://xx-rad1.tein.aarnet.edu.au:9443/

At the same time, browse the Admintool at https://xx-rad1.tein.aarnet.edu.au/

You should be receiving messages from the Admintool into ELK.  Explore the log messages received - and the fields they are parsed by.


# Deploying monitoring tools

Modify the ````icinga.env```` file with deployment parameters - override at least the following values:

* Pick your own admin password: ````ICINGAWEB2_ADMIN_PASSWORD````
* Pick internal DB passwords: ````ICINGA_DB_PASSWORD````, ````ICINGAWEB2_DB_PASSWORD````, ````POSTGRES_PASSWORD````
  * Generate these with: ````openssl rand -base64 12````
* ````SITE_PUBLIC_HOSTNAME````: the hostname this site will be visible as.  Enter your VM hostname: `xx-rad1.tein.aarnet.edu.au`
* ````EMAIL_HOST```` - configure to use your VM (`xx-rad1.tein.aarnet.edu.au).  Leave other ````EMAIL_*```` settings unset.
* ````EMAIL_FROM```` - From: address in outgoing emails.  Pick your own.
* ````ICINGA_ADMIN_EMAIL```` - administrator email address to receive notifications.  Enter your own email address.
* The following settings configure how Icinga fetches the configuration generated by the Admintool:
 * `CONF_URL_LIST`: the URL (possibly a list of URLs) to fetch configuration from.  Should be https://xx-rad1.tein.aarnet.edu.au/icingaconf
 * `CONF_URL_USER`: the username to use to authenticate to the configuration URL.
 * `CONF_URL_PASSWORD`: the password to use to authenticate to the configuration URL.
 * `CONF_REFRESH_INTERVAL`: the time period (in seconds) to wait before reloading the configuration from the URL.  Defaults to 3600 (1 hour).
 * `WGET_EXTRA_OPTS`: additional options to passs to `wget` when fetcing the configuration.  This needs in particular to take care of `wget` establishing trust for the certificate presented by the server.
   * If the Admintool is using a self-signed automatically generated certificate (during the Lab, it is), the quick way forward is to instruct `wget` to blindly accept any certificate - but as this creates serious security risks.  It's OK now during the lab, but it MUST NOT be used in production.  The setting is: `WGET_EXTRA_OPTS=--no-check-certificate`
   * The main documentation in [README.md](README.md) has details on more secure options.

The `icinga.env` file is used both by the containers to populate runtime configuration and by a one-off script to populate the database.
 
Additionally, in ````global-env.env````, customize system-level ````TZ```` and ````LANG```` as preferred - or you can copy over global.env from admintool:

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

* To enable status in your freeradius IRS (manual install), add the following to ````/etc/freeradius/sites-available/eduroam```` (in authorize section): 

        # respond to the Status-Server request.
        Autz-Type Status-Server {
            ok
        }

# Bonus Question: Configuring Google Login for Admintool

To enable Google login in the Admintool, you first need to register your application with Google and get an application key and a secret to use.

To get the Google credential (key+secret) to use in the admintool, do the following in the Google Developer Console:

* Start at http://console.developers.google.com/
* Create a new project
* From the main menu (top-left corner), select the `APIs & Services` and then `Library`
* In the list of available Google APIs, search for `Google+ API` and `Enable` this API for your project.
* From the main menu (again, top-left corner), select again `APIs & Services` and then `Credentials`
* Configure the `OAuth consent screen` with how the application should be described to the user (at least, set Product name)
* On the `Credentials` tab, create a new `Credential` as an `OAuth Client ID` for a web application
* Add the Authorized redirect URI for your application - the URL should have the following form is (substitute your real hostname here):

        https://xx-rad1.tein.aarnet.edu.au/accounts/complete/google-oauth2/

* After saving, this gives you the Client ID and secret (use these as the GOOGLE_KEY and GOOGLE_SECRET)

* Go again to the admintool deployment directory (````~/etcbc-public/admintool````) and enter these into ````admintool.env````.
* Now, restart the admintool with the new setttings:

        cd etcbd-public/admintool
        docker-compose stop
        docker-compose up -d


# Bonus Question: Become an institutional administrator in Admintool

* Open the admintool in a browser: https://xeap-wsNN.aarnet.edu.au/

* Navigate to Manage => Google and log in with your Google account.

* Select an institution and apply to become an administrator.

* Check your email and as the NRO admin, approve your own request.

* Now revisit the admin tool and through the manage menu, manage your own institution.


# Bonus Question: Connect radius server to ELK (switch to docker-compose)

You have earlier deployed the institutional radius server with Docker.

You can now re-deploy it to run with Docker-compose and link into the metrics tools - so that radius logs get pushed into the metrics tools.

* Shut down the existing freeradius-docker container:

        docker stop freeradius-docker
        docker rm -v freeradius-docker

* Clone the eduroam-freeradius-docker repository and navigate into th AncillaryToolIntegration directory there:

        git clone https://github.com/spgreen/eduroam-freeradius-docker.git
        cd eduroam-freeradius-docker/AncillaryToolIntegration

* Customize ````freeradius-eduroam.env```` with the same parameters as what you've done earlier in ````eduroam-freeradius-docker-public/restart_eduroamFreeRADIUS.sh````
  * Hint: you can see the differences by opening an additional ssh session and running

          cd eduroam-freeradius-docker-public
          git diff

* Customize ````filebeat-radius.env```` - set:
  * ````LOGSTASH_HOST```` to the hostname of your metrics server - the same VM name, xeap-wsNN.aarnet.edu.au
  * ````RADIUS_SERVER_HOSTNAME```` to what hostname should the radius server logs be associated with.  You can again enter your VM name, xeap-wsNN.aarnet.edu.au

* And in ````global-env.env````, customize system-level ````TZ```` and ````LANG```` as preferred - or you can copy over global.env from admintool:

        cp ~/etcbd-public/admintoool/global-env.env .

  * Note: the timezone setting here will be used to interpret the timezone on the radius logs.

* Use Docker-compose to start the containers:

        docker-compose up -d

* Now check your radius server and the filebeat container are operating normally:

        docker-compose logs -f

* Check monitoring is still reporting your radius server as operational: https://xeap-wsNN.aarnet.edu.au:8443/

* Check metrics now see the usage data from your server: http://xeap-wsNN.aarnet.edu.au:5601/



# Extra Credit Bonus Question: Commit your local config changes (except passwords) into git

We use git for versioning all of our code - container image source code, deployment scripts, even this documentation.  You can version configuration files too.

The way you fetched the deployment files, you cloned a git repository (created a local copy).

Navigate into ````~/etcbc-public```` and explore:

    git status
    git diff

You can now commit your config file changes into your local copy of the repository:
(But do not add the parts that contain passwords...).

    git add -p
    git commit

And you can now review the status after the change

    git status
    git log
    git diff HEAD~1..HEAD

You can find git command reference at https://git-scm.com/docs


# Extra Credit Bonus Question: Clone our public repo on github and push your changes there

We use github for storing our git repositories and for collaborating on projects.

On github, you can Fork a repository - create a copy hosted on Github and linked with the original repository.

* Navigate to https://github.com/REANNZ/etcbd-public
* Log into your github account (or create one - it's free!)
* Fork the repository into your account

You can now:
* Get the link to your repository: something like ````https://github.com/<your-username>/etcbc-public.git````
* Add this as an additional remote repository into your local copy on the lab VM:

        git remote add mycopy https://github.com/<your-username>/etcbc-public.git


* And you can now push the ````master```` branch (trunk of the repository) into your repository:

        git push mycopy master

* Now your configuration is versioned and kept in the cloud - you can clone your own copy later.

