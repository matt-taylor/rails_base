require 'sidekiq/web_custom'

Rails.application.routes.draw do
   mount Sidekiq::Web => '/'
end
