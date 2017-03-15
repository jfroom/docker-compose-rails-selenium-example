# Overview
This is a Rails demo project demonstrating 3 things. 

How to:
- Use Docker Compose 3 for local Rails development & Travis CI tests
- Cache bundler gems into a Docker volume which can persist across builds
- Configure a Selenium standalone instance with Capaybara for acceptance tests

If you are new to Docker & Rails, or the issues surrounding the items mentioned above — start with the articles in [Resources](#resources). This is not a beginners tutorial. The insights I've covering here took me a while to grasp — so I'm sharing in case someone else finds it useful.


# Getting started

## Required

1. Install [Docker](https://www.docker.com/) 17.03.0-ce+. This should also install Docker Compose 1.11.2+.
2. Verify versions: `docker -v; docker-compose -v;`

## Recommended
2. Install [VNC Viewer](https://www.realvnc.com/download/viewer/) to view & interact with selenium sessions that would otherwise be headless.


# Rails app

This base Rails app is very simple. 
- Was setup with `rails new app --skip-active-record`. I skipped the database setup to keep this demo slim.
- It has one root path route to the welcome controller which has a "Hello World!" in `views/welcome/index.html.erb`


# Basic Docker Commands

### First run

`docker-commpose build`

### Run

`docker-compose up` Will install all the gems, and launch the web server.

`open http://localhost:3000` Once the server is up, the root page can be seen on your local machine.

### Test

`docker compose test` Ensure the services are already 'up' in another terminal, or in detached mode, before running tests.

`vnc://localhost:5900 password:secret` To interactive with and debug Selenium sessions, use VNC to connect to the Selenium service. [VNC Viewer](https://www.realvnc.com/download/viewer/) works well, and on OS X Screen Sharing app is built-in.

# Docker Setup

## Docker's Bundler Cache

[Bundler](http://bundler.io/) installs and keeps track of all the gem libraries. Keeping docker container build times low is not trivial when bundler is involved. It took some time & research to optimize bundler's cache, so is worth an explanation. Credit to the unboxed team for this [bundler cache technique](https://unboxed.co/blog/docker-re-bundling/) — I've made some changes to make it compatible for Docker Compose 3 (which doesn't support `volume_from`.

The `web` service uses the `Dockerfile` to build itself. It defines an `ENTRYPOINT ["/docker-entrypoint.sh"]` bash script which will run the initial `bundle install`. Gems are stored in a docker volume called `bundle_cache` (see `docker-compose.yml`). When any gems are added to the `Gemfile`, this entrypoint script will notice and install them into the cache volume. Because of the entrypoint, there is no need to call a special command to do this other than `docker-compose up`. This technique is unique because the cache volume will persist across docker image changes, which reduces build times (and increases sanity) during local development. 

## Docker & Rails

- The muliline `services:web:command` that starts the develoment (port 3000) & test (port 3001) servers. We could move that into a script file, but I sort of like having less files to chase down. Running two servers with Puma to make it easier to run CI, and debug the test environment IMHO.
- `docker-compose.override.yml` exposes web ports to host machine so you can visit 'http://localhost:3000' for development server, and 'http://localhost:3001' for test server. This file is automatically used during a standard 'docker-compose up'. See Travis CI section for why the ports had to be split out into an override file.

## Docker & Selenium

- `Gemfile` has `selenium-webdriver` and `minitest-rails-capybara` in the `:test` group.
- `docker-compose.yml` defines:
  - `services:selenium` with a chrome standalone instance
  - Several enviornment variables which help link Capybara to the Docker network: `SELENIUM_HOST SELENIUM_PORT TEST_APP_HOST TEST_PORT`
- `test/test_helper.rb` uses these variables in the Capybara configuration.
- `test/acceptance/welcome_page_test.rb` shows a simple test case to visit the root path, and confirm 'Hello World!' is rendered.
- The VNC ability described above in the comamands section is really useful for debugging.


## Docker & Travis CI

- 'docker-compose.ci.yml' configures ports that are only exposed to the Docker network — not to the host machine. Travis was blocking some of the external ports. This override file is executed in `travis.yml` like this: `docker-compose -f docker-compose.yml -f docker-compose.ci.yml up`


# References
If you are new to Docker & Rails, or the issues surrounding the items mentioned above — start with these articles:

- [Dockerize a Rails 5, Postgres, Redis, Sidekiq and Action Cable Application with Docker Compose](https://nickjanetakis.com/blog/dockerize-a-rails-5-postgres-redis-sidekiq-action-cable-app-with-docker-compose] (Nick Janetakis)
- [Dockerized Rails Capybara Tests On Top Of Selenium](http://www.alfredo.motta.name/dockerized-rails-capybara-tests-on-top-of-selenium/) (Alfredo Motta)
- [Docker container for running browser tests](https://medium.com/@georgediaz/docker-container-for-running-browser-tests-9b234e68f83c#.r0y2gwkns)(George Diaz)
- [Make bundler fast again in Docker Compose](http://bradgessler.com/articles/docker-bundler/)(Brad Gessler)
- [Development Re-bundling in Dockerland](https://unboxed.co/blog/docker-re-bundling/)(Charlie Egan)

