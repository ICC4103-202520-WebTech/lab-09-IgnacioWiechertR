Deployment Report: Rails Application Implementation with Kamal

Project: lab-09-IgnacioWiechertR Server: 104.248.177.200 (DigitalOcean) Key Technologies: Ruby on Rails, Kamal, Docker, PostgreSQL

Introduction

This document details the deployment process of a Ruby on Rails application from a local development environment to a production server (DigitalOcean Droplet) using the Kamal deployment tool. The report covers the initial environment setup, dependency installation, database configuration, and the resolution of several critical issues encountered during the process.

Phase 1: Local Environment and Server Setup

The process began with configuring Kamal on the development machine and preparing the target server with Docker.

1.1. Kamal Initialization (Local)

The first step was to install and initialize Kamal in the local project:

gem install kamal kamal init

1.2. Docker Installation and Configuration (Server)

The target server required Docker. The initial installation failed while trying to locate the docker-buildx-plugin package, indicating that the standard Ubuntu repositories did not contain the necessary dependencies.

Resolution: Docker's official repositories were added to the server:

1. Install prerequisites for HTTPS repositories
sudo apt-get install ca-certificates curl gnupg lsb-release

2. Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

3. Set up the "stable" repository
echo

"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu

$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

4. Install Docker dependencies
sudo apt update sudo apt install docker-buildx-plugin

1.3. Docker Permissions Issue (Server)

After installation, server connectivity was verified (ssh root@104.248.177.200), and Docker was confirmed to be installed (docker ps). However, permission issues arose when trying to run Docker commands as a non-root user.

Resolution: The local user (ignac) was added to the docker group on the server, eliminating the need for sudo with every Docker command.

Checked if the group existed (getent group docker) or created it (sudo groupadd docker)
sudo usermod -aG docker $USER

Phase 2: Provisioning the PostgreSQL Database

The application required a PostgreSQL database, which was not pre-installed on the server.

2.1. PostgreSQL Installation (Server)

The PostgreSQL service was installed directly on the host operating system:

sudo apt install -y postgresql

2.2. Remote Access Configuration

By default, PostgreSQL only listens for localhost connections. It needed to be configured to accept connections from the application's Docker container.

Resolution: Two key PostgreSQL configuration files were modified:

postgresql.conf: The listen_addresses directive was updated to accept connections from any IP.

File: /etc/postgresql/17/main/postgresql.conf

Change: listen_addresses = '*'

pg_hba.conf: A rule was added to allow md5 authentication from all IP addresses. While this configuration is highly permissive and not recommended for critical production environments, it was a necessary step to validate connectivity during debugging.

File: /etc/postgresql/17/main/pg_hba.conf

Line Added: host all all 0.0.0.0/0 md5

After the changes, the service was restarted:

systemctl restart postgresql

2.3. Database Creation and Verification

The production database was created, and access was verified locally on the server:

Create the database and user (assumed from connection string)
sudo -u postgres psql CREATE DATABASE lab09_production; CREATE USER lab09 WITH PASSWORD '1234'; GRANT ALL PRIVILEGES ON DATABASE lab09_production TO lab09;

Verify connectivity on the host
psql "postgres://lab09:1234@127.0.0.1:5432/lab09_production"

This local verification on the server was successful.

Phase 3: Kamal Application Configuration

With the server services ready, configuration focused on Kamal's config/deploy.yml file and credential management.

3.1. Server Provisioning and SSH

A new SSH key pair was generated (ssh-keygen), and the public key (~/.ssh/id_ed25519.pub) was added to the DigitalOcean Droplet to allow passwordless authentication.

3.2. deploy.yml Configuration

Several key modifications were made to config/deploy.yml:

Server IP was set: servers: web: - 104.248.177.200

SSL was disabled: proxy: ssl: false

Proxy host was set to the IP: host: 104.248.177.200

Registry credentials were updated to point to a Docker Hub repository (https://www.google.com/search?q=registry.hub.docker.com).

3.3. Dockerfile Context Issue

During initial kamal setup attempts, the image build failed, reporting it could not locate the Dockerfile despite its existence in the project root.

Resolution: The issue was resolved by explicitly specifying the context and Dockerfile paths in config/deploy.yml, forcing Kamal to recognize them:

builder: context: . dockerfile: ./Dockerfile

3.4. Credential Management (Secrets)

Credentials (RAILS_MASTER_KEY, DATABASE_URL, and Docker Hub credentials) were managed using Kamal's secrets system. The RAILS_MASTER_KEY was obtained with bin/rails credentials:show.

Phase 4: Deployment and Critical Issue Resolution

The kamal deploy command was executed, but the application failed to boot, leading to an intensive debugging phase.

Problem 1: DATABASE_URL Error (Connection Refused)

Although the initial deployment seemed to work, application logs showed the web container could not connect to the database and was stuck in a restart loop.

Diagnosis: Analysis of the credentials revealed the DATABASE_URL configured locally (and pushed to the server) was: postgres://lab09:1234@127.0.0.1:5432/lab09_production

Problem Analysis: This is a common container networking error. The host 127.0.0.1 (localhost) inside the application container refers to the container itself, not the host server where the PostgreSQL service resides.

Resolution: The DATABASE_URL was corrected in the local .env file to point to the server's public IP, allowing the container to resolve the address correctly:

export DATABASE_URL="postgres://lab09:1234@104.248.177.200:5432/lab09_production"

After a kamal env push and kamal deploy, the application successfully connected to the database.

Problem 2: Form POST Failure (InvalidAuthenticityToken)

The application was deployed and accessible at http://104.248.177.200. However, all forms using POST (specifically Devise's "Log In" and "Sign Up") were failing.

Diagnosis: Analysis of the Rails logs (kamal app logs -f) revealed the underlying error: ActionController::InvalidAuthenticityToken (HTTP Origin header (http://104.248.177.200) didn't match request.base_url (https://104.248.177.200))

Problem Analysis: The default Rails production configuration (config/environments/production.rb) includes config.assume_ssl = true. This instructs Rails to assume it is behind an SSL proxy, causing it to generate its base_url as https://...

The browser, accessing via http://..., sent an Origin header of http://.... When Rails compared the Origin (http) with its base_url (https), the mismatch caused the CSRF protection to block the request.

Resolution: Given that this deployment was not using SSL, the Rails configuration needed to be aligned with the environment's reality. config/environments/production.rb was modified to disable SSL assumptions:

config/environments/production.rb
Changed from 'true' to 'false'
config.assume_ssl = false

Confirmed this line was also 'false'
config.force_ssl = false

Important Note: All configuration file changes had to be committed to the local repository before running kamal deploy to ensure Kamal would build a new image with the applied changes.

Conclusion

After modifying the SSL configuration in the production environment and redeploying, the discrepancy between the Origin and base_url was resolved. The authentication forms began working correctly, and the application became fully operational on the server.

The entire process highlights the critical importance of network configuration (public IPs vs. localhost) and the need for a coherent SSL configuration across the entire stack (Proxy, Kamal, and Rails) to prevent CSRF security conflicts.

Additional Resource

During the debugging phase, the following resource was instrumental in identifying and resolving several of the issues encountered:

https://www.youtube.com/watch?v=sPUk9-1WVXI