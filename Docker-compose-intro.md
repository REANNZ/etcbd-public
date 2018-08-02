
# Docker-compose #

Docker-compose sits on top of docker and creates high-level abstractions - services composed of a number of Docker containers, setting parameters that would otherwise be passed to Docker on the command-line:

* Names of images
* Names of containers
* Environment variables
* Port bindings
* Volume bindings
* Container links
* ... and other tweaks

In our deployments, customizable parameters are in separate environment variable files referenced from the docker-compose files.

Once you customize the variables (the env_file makes them separate from the code), you can then:

* Start everything up (interactively) and watch the console:

        docker-compose up

* Cancel this session with Ctrl-C

* Start again in the background (detached):

        docker-compose up -d

* Watch the logs with:

        docker-compose logs -f

(and again escape with Ctrl-C - this time just detaching)

* Stop and remove the containers:

        docker-compose stop
        docker-compose rm -f -v

* Up again:

        docker-compose up

* Fetch updated images:

        docker-compose pull

* Update (re-create) the running containers:

        docker-compose up

Note: ````docker-compose up```` updates (re-creates) the container whenever anything changes, otherwise just make sure the container is started. So if a new image is ready (pulled) or the environment variables file has changed, it would get re-created.

