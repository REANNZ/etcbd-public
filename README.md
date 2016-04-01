
#  Eduroam tools container-based deployment: Overall considerations #

The ancilliary tools package consists of three separate sets of tools:
* admintool
* metrics
* monitoring

Each of the tools is (at the moment) designed to run in an isolated environment.  They can be run on a single docker host by mapping each to a different port.  The configuration files provided here are designed this way:

* Admintool runs on ports 80 and 443 (HTTP and HTTPS)
* Monitoring tools run on ports 8080 and 8443 (HTTP and HTTPS)
* Metrics runs on port 5601 (plain HTTP only)

# ChangeLog

Changes to this document since the workshop at APAN41 in Manilla, January 2016.

* 2016-04-01: Added Update instructions.
* 2016-04-01: Added this ChangeLog section.
* 2016-03-08: Added documentation for passing arbitrary configuration options to Admintool.
* 2016-03-08: Added configurable login methods for Admintool.
* 2016-02-25: Added ADMINTOOL_SECRET_KEY environment variable.
* 2016-02-15: Added ADMINTOOL_DEBUG environment variable.
* 2016-02-15: Clarified deployment instructions.
* 2016-02-15: Added missing instructions to enable Google+API.

# Preliminaries - Docker

Install and configure Docker.  Please follow our [Docker setup instructions](Docker-setup.md).

Please become familer with Docker by following our [Docker introduction](Docker-intro.md).

# Preliminaries - Mail server

Some of the tools (admintool and monitoring) will need to send outgoing email.  Please make sure you have the details of an SMTP ready - either one provided by your systems administrator, or one running on the local system.

# Eduroam ancillary tools: Basic setup

NOTE: For the XeAP workshop at APAN41, please follow instructions in [Lab.md](Lab.md)

The installation instructions here are ment for deployment at your institution - the ones in [Lab.md](Lab.md) are targeted for the lab VMs.

On each of the VMs, start by cloning the git repository:

    git clone https://github.com/REANNZ/etcbd-public

# Deploying admintool

Modify the ````admintool.env```` file with deployment parameters - override at least the following values:

* Pick your own admin password: ````ADMIN_PASSWORD````
* Pick internal DB passwords: ````DB_PASSWORD````, ````POSTGRES_PASSWORD````
  * Generate these with: ````openssl rand -base64 12````
* ````SITE_PUBLIC_HOSTNAME````: the hostname this site will be visible as.
* ````LOGSTASH_HOST````: the hostname the metrics tools will be visible as.
* ````EMAIL_*```` settings to match the local environment (server name, port, TLS and authentication settings)
* ````SERVER_EMAIL````: From: email address to use in outgoing notifications.
* ````ADMIN_EMAIL````: where to send NRO admin notifications.
* ````REALM_COUNTRY_CODE```` / ````REALM_COUNTRY_NAME```` - your eduroam country
* ````TIME_ZONE```` - your local timezone (for the DjNRO web application)
* ````MAP_CENTER_LAT````, ````MAP_CENTER_LONG```` - pick your location
* ````REALM_EXISTING_DATA_URL````: In a real deployment, set this to blank (````REALM_EXISTING_DATA_URL=````) to start with an empty database.  Leaving it with the value provided would import REANNZ data - suitable for a test environment.
* ````GOOGLE_KEY````/````GOOGLE_SECRET```` - provide Key + corresponding secret for an API credential (see below on configuring these settings)
* ````ADMINTOOL_SECRET_KEY````: this should be a long and random string used internall by the admintool.
  * Please generate this value with: ````openssl rand -base64 48````
* ````ADMINTOOL_DEBUG````: for troubleshooting, uncomment the existing line: ````ADMINTOOL_DEBUG=True```` - but remember to comment it out again (or change to False or blank) after done with the troubleshooting.
* ````ADMINTOOL_LOGIN_METHODS````: enter a space-separated list of login methods to enable.
  * Choose from:
    * shibboleth: SAML Login with Shibboleth SP via an identity federation.  Not supported yet.
    * locallogin: Local accounts on the admin tool instance.
    * google-oauth2: Login with a Google account.  Only works for applications registered with Google - see below on enabling Google login.
    * google-plus: Login with a Google account via Google Plus.  May be used as an alternative to Google OAuth2.  Also only works for applications registered with Google - see below on enabling Google login.
    * yahoo: Login with a Yahoo account.  No registration needed.
    * amazon: Login with an Amazon account.  Registration needed.
    * docker: Login with a Docker account.  Registration needed.
    * dropbox-oauth2: Login with a Dropbox account.  Registration needed.
    * facebook: Login with a Facebook account.  Registration needed.
    * launchpad: Login with an UbuntuOne/Launchpad account.  No registration needed.
    * linkedin-oatuh2: Login with a LinkedIn account.  Registration needed.
    * meetup: Login with a MeetUp account.  Registration needed.
    * twitter: Login with a Twitter account.  Registration needed.
  * Please note that many of these login methods require registration with the target site, and also need configuring the API key and secret received as part of the registration.  Please see the [Python Social Auth Backends documentation](https://python-social-auth.readthedocs.org/en/latest/backends/) for the exact settings required.
* Additional settings: it is also possible to pass any arbitrary settings for the Admintool (or its underlying module) by prefixing the setting with ````ADMINTOOL_EXTRA_SETTINGS_````.  This would be relevant for passing configuration entries to the login methods configured above - especially SECRET and KEY settings for login methods requiring these.  Example: to pass settings required by [Twitter](https://python-social-auth.readthedocs.org/en/latest/backends/twitter.html), add them as:

        ADMINTOOL_EXTRA_SETTINGS_SOCIAL_AUTH_TWITTER_KEY=93randomClientId
        ADMINTOOL_EXTRA_SETTINGS_SOCIAL_AUTH_TWITTER_SECRET=ev3nM0r3S3cr3tK3y

Note this file (````admintool.env````) is used both by containers to populate runtime configuration and by a one-off script to populate the database.

As an additional step, in ````global-env.env````, customize system-level ````TZ```` and ````LANG```` as desired.

Use Docker-compose to start the containers:

    cd etcbd-public/admintool
    docker-compose up -d

Run the setup script:

    ./admintool-setup.sh admintool.env

At this point, please become familiar with Docker-compose by following our [Introduction to Docker-compose](Docker-compose-intro.md):

Optional: Install proper SSL certificates into /var/lib/docker/host-volumes/admintool-apache-certs/server.{crt,key}


# Deploying monitoring tools

Modify the ````icinga.env```` file with deployment parameters - override at least the following values:

* Pick your own admin password: ````ICINGAWEB2_ADMIN_PASSWORD````
* Pick internal DB passwords: ````ICINGA_DB_PASSWORD````, ````ICINGAWEB2_DB_PASSWORD````, ````POSTGRES_PASSWORD````
  * Generate these with: ````openssl rand -base64 12````
* ````SITE_PUBLIC_HOSTNAME````: the hostname this site will be visible as
* ````ICINGA_ADMIN_EMAIL````: where to send notifications
* ````EMAIL_*```` settings to match the local environment (server name, port, TLS and authentication settings)
* ````EMAIL_FROM```` - From: address to use in outgoing notification emails.

This file is used by both the containers to populate runtime configuration and by a one-off script to populate the database.

Additionally, in ````global-env.env````, customize system-level ````TZ```` and ````LANG```` as preferred - or you can copy over global.env from admintool:

    cd etcbd-public/icinga
    cp ../admintoool/global-env.env .

Use Docker-compose to start the containers:

    cd etcbd-public/icinga
    docker-compose up -d

Run the setup script:

    ./icinga-setup.sh icinga.env

Optional: Install proper SSL certificates into /var/lib/docker/host-volumes/icinga-apache-certs/server.{crt,key}

# Deploying metrics tools

Use Docker-compose to start the containers (copying over ````global-env.env```` from admintool):

    cd etcbd-public/elk
    cp ../admintoool/global-env.env .
    docker-compose up -d


# Updating deployed tools

Over time, these tools will receive updates - as upstream software releases new
version, as new features are developed, or as bugs and security issues are
fixed.

The updates would target both the container images and the files driving the
images contained in these repositories.

It is essential to install these updates to continue operating these tools in a reliable and secure manner.

## Updating Docker files

The first step is to pull updates to the Docker (and docker-compose) files driving the tools - i.e., this repository:

    cd etcbd-public
    git fetch --verbose --all
    git merge origin/master

If the above commands succeed, this part is completed.  Git may fail with an error message like:

````
error: Your local changes to the following files would be overwritten by merge:
        admintool/admintool.env
        Please, commit your changes or stash them before you can merge.
        Aborting
````

In that case:

* Save your changes to the file(s) affected into the git "stash" with: `git stash save`
* Now merge the updates to the original (unmodified) files: `git merge origin/master`
* Now bring back the changes from the stash: `git stash pop`
* Git tries to merge the local modifications into the updated files.
* If this succeeds without encountering any conflicts, this step is done.
* If git reports conflicts - like:

        $ git stash pop
        Auto-merging admintool/admintool.env
        CONFLICT (content): Merge conflict in admintool/admintool.env

* It is necessary to manually resolve the conflict.  Edit the file and manually merge the updates (typically adding new settings) with local modifications (customizations of existing settings).  The file would contain fragments from both versions, separated by clearly visible demarcation lines:

        <<<<<<< Updated upstream
        #ADMINTOOL_DEBUG=True
        ADMINTOOL_LOGIN_METHODS=google-oauth2 launchpad yahoo
        # choose from:
        #    shibboleth, locallogin, google-oauth2, google-plus, yahoo, amazon,
        #    docker, dropbox-oauth2, facebook, launchpad, linkedin-oauth2,
        #    meetup, twitter

        # Add any additional settings by prefixing them with ADMINTOOL_EXTRA_SETTINGS_
        # Example:
        #ADMINTOOL_EXTRA_SETTINGS_SOCIAL_AUTH_TWITTER_KEY=93randomClientId
        #ADMINTOOL_EXTRA_SETTINGS_SOCIAL_AUTH_TWITTER_SECRET=ev3nM0r3S3cr3tK3y
        =======
        ADMINTOOL_DEBUG=True
        >>>>>>> Stashed changes

* As part of resolving the conflict, remove also the demarcation lines.  In this example, the ADMINTOOL_DEBUG setting was modified (uncommented) in the local file, while right on the following line, new settings were added in the upstream.  The correct resolution of thi confict is:

        ADMINTOOL_DEBUG=True
        ADMINTOOL_LOGIN_METHODS=google-oauth2 launchpad yahoo
        # choose from:
        #    shibboleth, locallogin, google-oauth2, google-plus, yahoo, amazon,
        #    docker, dropbox-oauth2, facebook, launchpad, linkedin-oauth2,
        #    meetup, twitter

        # Add any additional settings by prefixing them with ADMINTOOL_EXTRA_SETTINGS_
        # Example:
        #ADMINTOOL_EXTRA_SETTINGS_SOCIAL_AUTH_TWITTER_KEY=93randomClientId
        #ADMINTOOL_EXTRA_SETTINGS_SOCIAL_AUTH_TWITTER_SECRET=ev3nM0r3S3cr3tK3y

* After editing the file, indicate to Git the conflict has been resolved: `git reset`
* And dropped the stashed copy of the local modifications (git kept it because it ran into the conflict): `git stash drop`

## Updating docker containers

After updating the files driving the tools:

* Go into the respective directory (repeat for all of the three tools the updates apply to): `cd admintool`
* Pull the updated container images: `docker-compose pull`
* Restart the containers from updated images: `docker-compose up -d`
* Optionally, watch the logs (leave with Ctrl-C): `docker-compose logs`

# Appendix: Google Login

To get the Google credential (key+secret) to use in the admintool, do the following in the Google Developer Console:

* Start at http://console.developers.google.com/
* Create a new project
* From the main menu, select the API Manager
* In the list of available Google APIs, search for ````Google+ API```` and Enable this for your project.
* In the top-level API manager menu, select Credentials
* Configure the OAuth consent screen with how the application should be described to the user (at least, set Product name)
* Create a new Credential as an OAuth Client ID for a web application
* Add the Authorized redirect URI for your application - the form is (substitute your real hostname here):

        https://admin.example.org/accounts/complete/google-oauth2/

* After saving, this gives you the Client ID and secret (use these as the GOOGLE_KEY and GOOGLE_SECRET)

