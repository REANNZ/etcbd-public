
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

ElasicSearch needs one system-level setting tuned: `vm.max_map_count` needs to
be increased from the default 65530 to 262144.
Without this setting in place, ElasticSearch fails to start.
To change the setting both in the currently booted system and to make it apply
after a reboot, run (as root):

    sysctl -w vm.max_map_count=262144
    echo "vm.max_map_count = 262144" > /etc/sysctl.d/70-elasticsearch.conf

And now, back in `etcbd-public/elk`, use Docker-compose to start the containers:

    docker-compose up -d
    docker-compose logs -f

And we now also need to run the setup script that initializes the ELK system:

    cd ~/etcbd-public/elk
    ./elk-setup.sh

We now have the metrics tools running, but we need to push some data into the tools before we can explore them.

NOTE: the setup script also creates an *index pattern* in Kibana, telling Kibana where to find your data.  However, this may fail if there are no data in ElasicSearch yet, so you may have to reinitialize Kibana after some initial data is ingested into ElasticSearch.  You can re-run the setup script with:

    ./elk-setup.sh --force

Note that the `--force` flag deletes all Kibana settings - but the initial ones get loaded again by the setup script.  And the actual data in ElasicSearch stays intact.

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

# Prepare Admintool to generate configuration for monitoring tools

## Preparing Icinga configuration in Admintool

In the next section, we will be deploying the monitoring tools (Icinga).
The monitoring tools will be loading the configuration generated by the
Admintool.  We need to configure this before we proceed to installing the
monitoring tools.

The generated configuration will:
* Define an Icinga Host for each NRO Radius server.
* Define an Icinga Host for each Institutional Radius server.
* Configure a Ping connectivity check for each server.
* If supported by the Radius server, generate a Radius Status Check for the server.
* For each Monitored Realm with authentication configured, there will be:
  * A service check through each NRO server.
  * Optionally, also a separate service check directly through each Institutional Radius server that is listed as a proxy for the Institutional Realm.
* Each service check will be configured with Notifications to Contacts associated with Institution the Institutional Realm being checked belongs to.
* For each Institutional Radius server, the Notifications would also go to all Contacts associated with all Institutions the server is associated with.

There is a number of configuration variables in `admintool.env` that control how the configuration will be generated:
* `NRO_SERVERS` specifies the list of NRO servers (short identifiers) - example: `NRO_SERVERS=server1 server2`.  In this lab, we only have one server, so we'll go with just `NRO_SERVERS=nrad1`, using `nrad1` as the short identifier.
* For each server, there should be a set of variables using the short server identifier as part of the name:
  * `NRO_SERVER_HOSTNAME_serverid`: the hostname (or IP address) to use for server checks (so `NRO_SERVER_HOSTNAME_nrad1=xx-nrad1.tein.aarnet.edu.au`)
  * `NRO_SERVER_SECRET_servererid`: the Radius secret to use with the server (so e.g. `NRO_SERVER_SECRET_nrad1=radius-secret` - has to match your `radsecproxy.conf`)
  * `NRO_SERVER_PORT_serverid`: the Radius port number to use with this server (Optional, defaults to 1812 ... so you can skip this one)
  * `NRO_SERVER_STATUS_serverid`: should be set to `True` if the server supports Radius Status checks (Optional, defaults to False).  Radsecproxy supports Status messages, so `NRO_SERVER_STATUS_nrad1=True`
* `ICINGA_CONF_REQUEST_CUI`: should be set to `True` if the eduroam login checks should request the Chargeable User Identity (CUI) attribute (Optional, defaults to True)
* `ICINGA_CONF_OPERATOR_NAME`: the Operator Name to use in the eduroam login checks (Optional, no operator name is passed if not specified).
* `ICINGA_CONF_VERBOSITY`: the verbosity level in eduroam login checks.  (Optional, defaults to 1.  Level of at least 1 is needed to see the CUI returned by the check.  Values can range from 0 to 2).
* `ICINGA_CONF_GENERATE_INSTSERVER_CHECKS`: Should the generated configuration include the institutional server checks? (Optional, defaults to False).
* `ICINGA_CONF_NOTIFY_INST_CONTACTS`: Should the generated configuration notify institutional contacts - for server and monitored realm checks? (Optional, defaults to True).  This setting gives the option to disable all Notifications sent to institional contacts if not desired - in which case alerts would go only to the nominated NRO email address given in the Monitoring tools configuration.

* Update Admintool to pick up the changed configuration:

        docker-compose up -d

As a final step, prepare the account Icinga would use to create the configuration:

* Log into the Admintool admin interface at https://xx-rad1.tein.aarnet.edu.au/admin/ as the administrator (with the username and password created earlier).
* Select `Users` from the list of tables to administer.
* Use the `Add user` button to bring up the user creation form.
* Enter the username and password
  * The sample Monitoring configuration uses `confuser` as the username
  * We recommend generating the password, e.g. with `openssl rand -base64 12``
* Use the `Save and continue editing` button to get to the next screen with additional details
  * In the list of `Available user permissions`, select all three `edumanage | Monitored Realm (local authn)` permissions and add them to the `Chosen user permissions`.  (The permission to access the monitoring credentials is internally used to represent as permission to access the monitoring configuration).
  * Select `Save` to store the permissions.
* We also recommend to create a `User Profile` entry for this user account - to keep the internal database consistent with assumptions the DjNRO code makes:
  * Select `User Profiles` from the list of tables to administer (navigate back to the `Home` screen to get the list of tables).
  * Use the `Add User Profile` button to bring up the user profile creation form.
  * Select the user just created in the above step as the user.
  * Select an institution (the NRO organisation would do) to associate the user with.
  * Leave the "Is social active" option unchecked.
    * This way, the account does NOT get permission to administer the institution - but a user profile is created, making the internal database consistent.
  * Save the user profile.

Now you should be able to access the monitoring configuration at https://admin.example.org/icingaconf with this account.  (And it is also accessible under the administrator account).

## Entering data for monitoring configuration into the Admintool.

The following information needs to be entered into the Admintool in order to
generate the monitoring configuration.  Due to dependencies between different
data objects, we recommend entering the data in the order given here.

All of the data can be entered at https://xx-rad1.tein.aarnet.edu.au/admin/

* Add an *Institution* - select the NRO Realm, entity type and enter the English name of the Institution.
* Add at least one *Contact* for the institution (not that Contacts can be reused across institutions).
* Add an *Institution Details* object: select the Institution it belongs to, enter Address details and select at least one Contact.
* Add the *Institution's Realms*: enter the Realm name, select the Institution and select the institution's radius server that the NRO radius server should be proxying to.
* Add an *Institution Monitored Realm* entry: select the Institution's Realm and select "Local account authentication" as the Monitor type (the only available entry).
* Add a *Monitored Realm (local authn)* entry: select the Monitored Realm and select the EAP method, phase2 authentication, username and password to match the institution's radius server settings.  For the `freeradius-eduroam` server deployed during this workshop, use:
  * EAP-Method: `PEAP`
  * Phase2: `MS-CHAPv2`
  * Username: fully scoped username, so e.g. testuser@xeap.sg
  * Password: as per your freeradius server settings.

Entering all of the above should be sufficient for the Admintool to generate monitoring checks for Icinga - both via the NRO servers and directly through the Institution's servers.

# Deploying monitoring tools

Modify the ````icinga.env```` file (in `etcbd-public/icinga`) with deployment parameters - override at least the following values:

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

Use Docker-compose to start the containers and watch the logs:

    cd etcbd-public/icinga
    docker-compose up -d
    docker-compose logs -f

And in another session, run the setup script:

    cd etcbd-public/icinga
    ./icinga-setup.sh icinga.env

Please note: the `icinga-setup.sh` script should be run only once.
Repeated runs of the script would lead to unpredictable results (some database structures populated multiple times).

Note: Icinga will be using the configuration as generated by the Admintool.
When the settings change in Admintool, Icinga would only see the changes next
time it fetches the configuration.  This defaults to happen every hour.  To
trigger an immediate reload, either restart the container, or send it the
"Hang-up" (HUP) signal:

    docker kill --signal HUP icinga

# Confirm all services report OK in icingaweb #

Now explore the monitoring tools at https://xx-rad1.tein.aarnet.edu.au:8443/ (and log in as ````admin```` with the password selected above).

* Please confirm all services are reporting OK.  Troubleshoot any issues.

* Please test sending alerts works all fine - send a test message for one of the services.

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


# Bonus Question: Google Maps API keys

The Admintool uses the Google Maps Javascript API to render the service
location points on maps provided by Google.

As of June 22, 2016, the Google Maps Javascript API now requires an API key.
Any new services deployed after this date (as determined by the domain
registration date) require an API key.  On such services, without an API key,
the map view displays an error and the Javascript console shows messages
indicating an API key is missing.  However, even if your service is working
without an API key, we strongly recommend to configure one, as Google may in
the future decide to make this mandatory for all services.  You can find more
details about the API change itself in the original
[Google Announcement](http://googlegeodevelopers.blogspot.co.nz/2016/06/building-for-scale-updates-to-google.html).

To create a Google Maps API key:
* Start at the Google Developer Console: http://console.developers.google.com/
* Open the project you created earlier for configuring Google Login (or create a new one if you have not configured Google Login yet).
* From the main menu (top-left corner), select the `APIs & Services` and then `Library`
* Search for `Google Maps JavaScript API` and `Enable` this for your project.
* In the navigation side-bar on the left, select Credentials
* From `Create credentials`, select `API key` and then `Browser key`
* Pick a name for your credential - e.g., `Browser key - Google Maps JavaScript API`
* Enter the name of your website as the accepted referrer.  This would be the hostname you entered as SITE_PUBLIC_HOSTNAME in your `admintool.env` - e.g.:

        xx-rad1.tein.aarnet.edu.au

* After saving, the Google Developer Console gives you the API key - configure this in the `GOOGLE_API_KEY` setting in `admintool.env`
* Restart the admintool with the new setttings:

        cd etcbd-public/admintool
        docker-compose stop
        docker-compose up -d

# Bonus Question: Become an institutional administrator in Admintool

* Open the admintool in a browser: https://xx-rad1.tein.aarnet.edu.au/

* Navigate to Manage => Google and log in with your Google account.

* Select an institution and apply to become an administrator.

* Check your email and as the NRO admin, approve your own request.

* Now revisit the admin tool and through the manage menu, manage your own institution.


# Bonus Question: Connect national radius server to ELK

You have earlier deployed the national radius server with Docker.

You can now link it into the metrics tools - so that radius logs get pushed into the metrics tools.

We have prepapred the log collection tool `filebeat` configured for collecting radsecproxy logs as a Docker container - and also prepared a `docker-compose.yml` file setting all the required parameters.  The `docker-compose.yml` file is included in the same git repository `etcbd-public` which you've already used on the other server for deploying the Ancillary services - but we now need it on the national radius server.

* Clone this repository here:

        git clone https://github.com/REANNZ/etcbd-public.git
        cd etcbd-public/filebeat-radsecproxy/

* Customize `filebeat-radsecproxy.env`:
  * Set `LOGSTASH_HOST` to the name of the host where your ELK deployment is running - so `xx-rad1.tein.aarnet.edu.au` in this case.
  * Set `RADIUS_SERVER_HOSTNAME` to the name of the host where radsecproxy is running - so this host (`xx-nrad1.tein.aarnet.edu.au`).  (This will be used in the metadata of the log messages).

* And in `global-env.env`:
  * Set `TZ` to the same timezone as your radsecproxy.  This is important for getting timestamps processed correctly.
  * And set `LANG` to your preferred locale (or you can leave this one as is).

* Use Docker-compose to start the containers:

        docker-compose up -d

* Now check your radius server and the filebeat container are operating normally:

        docker-compose logs -f

* Check metrics now see the usage data from your server: https://xx-rad1.tein.aarnet.edu.au:9443/
  * Explore raw data ("Discover")
  * Visualizations
  * Dashboards
  * NOTE: you may have to make Kibana rescan the available after ingesting first set of data.  While this can be also done inside Kibana, you can also re-run the setup script (on the host where the metrics tools are deployed)  with:

          ./elk-setup.sh --force



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

