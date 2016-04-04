
# Install Docker #

* Do not install Docker from Ubuntu repositories - these are really ancient versions (1.4 / 1.5)

* Instead, follow https://docs.docker.com/engine/installation/ubuntulinux/

* For Ubuntu 14.04 (Trusty), this means the following steps:

  * Add the Docker package repository:

          apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
          echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main' > /etc/apt/sources.list.d/docker.list
          apt-get update

  * Make sure the extra kernel modules package (with the AUFS driver) is installed:

          apt-get install linux-image-extra-$(uname -r)

  * Install Docker Engine itself (this also auto-starts the daemon)

          apt-get install docker-engine

  * Add your user account to Docker group for direct access:

          usermod -aG docker xeap

# Install Docker Compose #

Official Docker Compose Install manual at https://docs.docker.com/compose/install/ redirects Ubuntu users to https://github.com/docker/compose/releases ...  where the command to run is:

    curl -L -o /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/1.6.2/docker-compose-`uname -s`-`uname -m`
    chmod +x /usr/local/bin/docker-compose

(The URL being fetched is actually https://github.com/docker/compose/releases/download/1.6.2/docker-compose-Linux-x86_64 and it fetches an ELF-64 binary)

