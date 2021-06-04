.PHONY: bash build bundle rspec

APP_NAME?=app
SIDEKIQ_NAME?=sidekiq

build: #: Build the containers that we'll need
	docker-compose build --pull

bash: #: Get a bash prompt on the core container
	docker-compose run --rm -e RAILS_ENV=development $(APP_NAME) bash

bash_test: #: Get a test bash prompt on the core container
	docker-compose run --rm -e RAILS_ENV=test $(APP_NAME) bash

s develop server start: clear_pid kill_sidekiq #: Start the web app server
	docker-compose -f docker-compose.yml run --rm --service-ports $(APP_NAME)

clear_pid: #: clear pid in the event of a crash
	rm -f dummy_rails/tmp/pids/server.pid

kill_sidekiq:
	docker-compose stop $(SIDEKIQ_NAME)

roll_sidekiq: kill_sidekiq
	docker-compose -f docker-compose.yml run -d --rm $(SIDEKIQ_NAME)

down: #: Bring down the service -- Destroys everything
	docker-compose down

clean: #: Clean up stopped/exited containers
	docker-compose rm -f
