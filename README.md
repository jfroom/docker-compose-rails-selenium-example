# docker-compose-rails-selenium [![Build Status](https://travis-ci.org/jfroom/docker-compose-rails-selenium.svg?branch=master)](https://travis-ci.org/jfroom/docker-compose-rails-selenium)

Just a few Docker Compose 3 techniques for integrating:
- Rails 5.0 development & Travis CI tests
- Caching of bundler gems into a Docker volume which persists across builds and Gemfile changes
- A Selenium Chrome standalone instance running Capybara tests, and a VNC connection to interact with the test browser session

These insights took a while to grasp — so I'm sharing in case someone else finds it useful.

New to Docker & Rails? Unfamiliar with the issues surrounding the topics above? Start with the links in [References](#references).

# Getting started

## Required

1. Install [Docker](https://www.docker.com/) 17.03.0-ce+. This should also install Docker Compose 1.11.2+.
2. Verify versions: `docker -v; docker-compose -v;`

## Recommended
1. Install [VNC Viewer](https://www.realvnc.com/download/viewer/) to view & interact with selenium sessions that would otherwise be headless.

# Rails app

This base Rails app is very simple since the focus here is on docker. 
- Was setup with `rails new app --skip-active-record`. The database was skipped to stay lightweight.
- It has one root path route to the WelcomeController which renders "Hello World!" from `views/welcome/index.html.erb`

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

## Docker & Bundler Cache

[Bundler](http://bundler.io/) installs and keeps track of all the gem libraries. Keeping docker container build times low is not trivial when bundler is involved. It took some time & research to optimize bundler's cache, so is worth an explanation. Credit to the unboxed team for this [bundler cache technique](https://unboxed.co/blog/docker-re-bundling/) — I've made some changes to make it compatible for Docker Compose 3 (which doesn't support `volume_from`). The gist of it:

`Dockerfile`:
- `ENTRYPOINT ["/docker-entrypoint.sh"]` allows a shell script to run before any relative containers execute a command.
- `ENV BUNDLE_PATH=/bundle BUNDLE_BIN=/bundle/bin GEM_HOME=/bundle` configures a new installation path for future bundler installs, and binstubs.
- `ENV PATH="${BUNDLE_BIN}:${PATH}"` allows bundler's binstubs to be executed without `bundle exec` (i.e. `puma`)

`docker-entrypoint.sh`:
- Ensures all gems are installed before the web services boot up. This happens everytime `docker-compose up` executes.
- Gems are installed to `/bundle` in the docker instance because of the defined `BUNDLE_PATH` env var above.
- `bundle install --binstubs="$BUNDLE_BIN"` installs the gems and stub commands are available because they were defined on PATH above.

`docker-compose.yml`:
- `version: '3.1'` Volume syntax changed a bit between 2 and 3 (volume_from was removed)
- `services:web:volumes:` defines `bundle_cache:/bundle`, and then `volumes:bundle_cache` persists it across builds. **This reduces build times for local development. :tada:** 
- When installing a new gem, or changing branches which have different gems — just stop the docker services and restart it. Or execute `bundle install` on the container. The old gems are already cached, and only new gems will be installed.

## Docker & Rails

`docker-compose.yml`
- Has a muliline `services:web:command` that starts the develoment (port 3000) & test (port 3001) servers. 
This could move that into a script file, but I like having a flatter architecture and less files to chase down.
- Runs dedicated test server which is bound to the test database to debug the test environment, and fewer differences between dev & CI environments.

`docker-compose.override.yml`
- Exposes web ports to host machine so you can visit 'http://localhost:3000' for development server, and 'http://localhost:3001' for test server. 
- This file is automatically used during a standard `docker-compose up`. 
- See Travis CI section for why the ports had to be split out into an override file.

## Docker & Selenium

`Gemfile`
- Has `selenium-webdriver` and `minitest-rails-capybara` in the `:test` group.

`docker-compose.yml`
- Defines `services:selenium` with the `selenium/standalone-chrome-debug` image
- The VNC service included with the debug is really useful for debugging (see commands section).
- Defines several enviornment variables which help link Capybara to the Docker network: `SELENIUM_HOST SELENIUM_PORT TEST_APP_HOST TEST_PORT`

`test/test_helper.rb`
- Uses the env variables defined above in the Capybara configuration.

`test/acceptance/welcome_page_test.rb`
Shows a simple test case to visit the root path, and confirms **'Hello World!'** is rendered.

## Docker & Travis CI

`docker-compose.ci.yml`
- Configures ports that are only exposed to the Docker network — not to the host machine. Travis was blocking some of the external ports.  
- This override file is executed in `.travis.yml` as: `docker-compose -f docker-compose.yml -f docker-compose.ci.yml up`

# References
New to Docker & Rails? Unfamiliar with the issues surrounding the topics above? Start here. Much of this repo is an derivative & build upon the content of these quality resources:

Docker & Rails:
- [Dockerize a Rails 5, Postgres, Redis, Sidekiq and Action Cable Application with Docker Compose](https://nickjanetakis.com/blog/dockerize-a-rails-5-postgres-redis-sidekiq-action-cable-app-with-docker-compose) (Nick Janetakis)

Docker & Bundler:
- [Make bundler fast again in Docker Compose](http://bradgessler.com/articles/docker-bundler/) (Brad Gessler)
- [Development Re-bundling in Dockerland](https://unboxed.co/blog/docker-re-bundling/) (Charlie Egan)

Docker & Selenium:
- [Dockerized Rails Capybara Tests On Top Of Selenium](http://www.alfredo.motta.name/dockerized-rails-capybara-tests-on-top-of-selenium/) (Alfredo Motta)
- [Docker container for running browser tests](https://medium.com/@georgediaz/docker-container-for-running-browser-tests-9b234e68f83c) (George Diaz)

Docker & Travis:
- [Travis - Using Docker in Builds](https://docs.travis-ci.com/user/docker/) (TravisCI)
- [Managing Docker & Docker Compose versions on Travis](https://graysonkoonce.com/managing-docker-and-docker-compose-versions-on-travis-ci/) (Grayson Koonce)

# License
Copyright © JFMK, LLC Released under the [MIT License](https://github.com/jfroom/docker-compose-rails-selenium/blob/master/LICENSE).
