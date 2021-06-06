.PHONY: bash build bundle rspec

APP_NAME?=app
SIDEKIQ_NAME?=sidekiq

build: #: Build the containers that we'll need
	docker-compose build --pull

bash: #: Get a bash prompt on the core container
	docker-compose run --rm -e RAILS_ENV=development $(APP_NAME) bash

bash_test: #: Get a test bash prompt on the core container
	docker-compose run --rm -e RAILS_ENV=test $(APP_NAME) bash

s develop server start: clear_pid kill_sidekiq #: Start the web app server and restart the sidekiq session
	docker-compose -f docker-compose.yml run --rm --service-ports $(APP_NAME)

clear_pid: #: clear pid in the event of a crash
	rm -f dummy_rails/tmp/pids/server.pid

kill_sidekiq:
	docker-compose stop $(SIDEKIQ_NAME)

sidekiq: kill_sidekiq # start a detached version of sidekiq
	docker-compose -f docker-compose.yml run -d --rm $(SIDEKIQ_NAME)

down: #: Bring down the service -- Destroys everything in redis and all containers
	docker-compose down

clean: #: Clean up stopped/exited containers
	docker-compose rm -f

add_jobs: #: Randomly add jobs to every queue defined in dummy app
	docker-compose run --rm $(APP_NAME) bin/rails runner 'lib/load_random_workers.rb'

bundle: #: install gems for Dummy App with
	docker-compose run --rm $(APP_NAME) bundle install
