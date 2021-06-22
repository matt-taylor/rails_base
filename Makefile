.PHONY: build run

build:
	docker-compose build

bundle: #
	docker-compose run engine bundle install

setup: build bundle db_reset annotate clean # Set up the service

db_reset: # Blows away db and sets it up with seed data
	docker-compose run --rm engine bin/rails db:reset

migrate: # Blows away db and sets it up with seed data
	docker-compose run --rm engine bin/rails db:migrate

setup_db: # sets up db from empty state
	docker-compose run --rm engine bin/rails db:setup

rspec: # runs the test suite
	docker-compose run --rm -e RAILS_ENV=test engine bin/test

bash: # get a bash container
	docker-compose run --rm -e RACK_ENV=development engine bash

bash_test: # get a bash container
	docker-compose run --rm -e RACK_ENV=test engine bash

annotate: # annotate models
	docker-compose run --rm -e RACK_ENV=development engine bundle exec annotate --models

down: # Bring down the service
	docker-compose down

clean: # Clean up stopped/exited containers
	docker-compose rm -f

ps: # show running containers for the service
	docker-compose ps

c console: # open up a console
	docker-compose run --rm engine bin/rails c

clear_pid:
	rm -f tmp/pids/server.pid

s server: halt_shit
	docker-compose run --rm -e RACK_ENV=development --service-ports engine

sk server_with_sidekiq: halt_shit
	docker-compose run --rm -e RACK_ENV=development --service-ports engine_with_sidekiq

print_version:
	docker-compose run --rm engine bin/version

publish:
	docker-compose run --rm engine bin/publish

halt_shit: stop_app stop_app_with_sidekiq stop_sidekiq clear_pid

stop_app:
	docker-compose stop engine

stop_app_with_sidekiq:
	docker-compose stop engine_with_sidekiq

stop_sidekiq:
	docker-compose stop sidekiq

