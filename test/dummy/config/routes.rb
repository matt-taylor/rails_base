require 'sidekiq/web' if ENV['USE_SIDEKIQ']

Rails.application.routes.draw do
  mount RailsBase::Engine => '/'
  mount Sidekiq::Web => '/sidekiq' if ENV['USE_SIDEKIQ']
end
