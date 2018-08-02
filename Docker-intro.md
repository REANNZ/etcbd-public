
# Docker - brief introduction #

Docker is a platform for packaging and shipping applications with all of their dependencies - and running them as lightweight processes (as opposed to virtual machines).

Docker containers run off container images and are managed by the Docker daemon running on the Docker host (either a VM or a physical system).

* Install Docker first by following [these instructions](Docker-setup.md)

* Run a simple interactive container with Debian Linux: 

        docker run -it --name my_debian debian:stretch bash

  * When exiting the shell running in the container, the container stops, but stays on the system (see below)

* Start an Apache web server as a detached container (and map port 8080 on the Docker host to port 80 on the container):

        docker run -d --name my_apache -p 8080:80 httpd:2.4

  * Try accessing the apache container:

          wget -q http://localhost:8080/ -O -

* Check the list of running containers:

        docker ps

* Check the list of all containers:

        docker ps -a

* Stop the Apache container:

        docker stop my_apache

* Remove both of the containers with:

        docker rm -v my_debian my_apache

* See list of locally available Docker images:

        docker images

* See list of ALL locally available Docker images (including intermediate layers):

        docker images -a

* Remove the local images used above:

        docker rmi httpd:2.4 debian:stretch


Please see https://github.com/wsargent/docker-cheat-sheet for more examples.

