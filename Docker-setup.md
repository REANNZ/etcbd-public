
# Install Docker #

* Do not install Docker from Ubuntu repositories - these are lagging behind current Docker releases

* Instead, follow the Docker CE Ubuntu Installation [https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository](instructions)

* For Ubuntu 18.04 (Bionic), this means the following steps (running them as `root` - e.g., via `sudo -i`):

  * Pre-requisite: update packages on your system:

          apt-get update
          apt-get upgrade
          apt-get autoremove

  * Install packages needed for adding a new (signed) repository:

          apt-get install curl ca-certificates gnupg software-properties-common

  * Add the Docker GPG key:

          curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

  * Add the Docker package repository:

          add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
          apt-get update

  * Install Docker CE itself (this also auto-starts the daemon)

          apt-get install docker-ce

  * Add your user account (`admin`) to Docker group for direct access:

          usermod -aG docker admin

# Install Docker Compose #

Official Docker Compose Install manual is at https://docs.docker.com/compose/install/ ...  where the command to run is:

    curl -L -o /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m`
    chmod +x /usr/local/bin/docker-compose

(The URL being fetched is actually https://github.com/docker/compose/releases/download/1.6.2/docker-compose-Linux-x86_64 and it fetches an ELF-64 binary)

