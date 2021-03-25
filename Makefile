.PHONY: build run

build:
	docker-compose build

bundle: #
	docker-compose run engine bundle install

setup: build bundle db_reset annotate clean up # Set up the service

db_reset: # Blows away db and sets it up with seed data
	docker-compose run engine bin/rails db:reset

migrate: # Blows away db and sets it up with seed data
	docker-compose run engine bin/rails db:migrate

setup_db: # sets up db from empty state
	docker-compose run engine bin/rails db:setup

rspec: # runs the test suite
	docker-compose run engine ./bin/test

bash: # get a bash container
	docker-compose run engine bash

bash_test: # get a bash container
	docker-compose run -e RAILS_ENV=test engine bash

annotate: # annotate models
	docker-compose run engine bundle exec annotate --models

up: clear_pid # start the services
	docker-compose up -d

down: # Bring down the service
	docker-compose down

clean: # Clean up stopped/exited containers
	docker-compose rm -f

ps: # show running containers for the service
	docker-compose ps

c console: # open up a console
	docker-compose run engine bin/rails c

clear_pid:
	docker-compose run engine rm -f tmp/pids/server.pid

s server: up
	docker attach rails_base_engine_1
