# frozen_string_literal: true

require 'byebug'
require_relative 'web_custom/version'

# require sidekiq/web first to ensure web_Action will prepend correctly
require 'sidekiq/web'
require 'sidekiq/web_custom/configuration'
require 'sidekiq/web_custom/web_action'
require 'sidekiq/web_custom/queue'
require 'sidekiq/web_custom/job'
require 'sidekiq/web_custom/web_app'

module Sidekiq
  module WebCustom
    class Error < StandardError; end
    class ArgumentError < Error; end
    class FileNotFound < Error; end
    class StopExecution < Error; end
    class ExecutionTimeExceeded < Error; end

    BREAK_BIT = '__sidekiq-web_custom-breakbit__'

    def self.default_available_actions_mapping
      @available_actions_mapping ||= begin
        temp = {}
        Dir["#{actions_root}/**/*.erb"].map do |erb_path|
          base_path = File.basename(erb_path).split('.')[0]
          second_half = erb_path.split(actions_root)[1]
          action_type = second_half.split(base_path)[0]
          action_type = action_type.delete('/').to_sym
          temp[action_type] ||= {}
          temp[action_type][base_path.to_sym] = erb_path
        end
        temp
      end
    end

    def self.default_local_erb_mapping
      @local_erb_mapping ||=  Dir["#{local_erbs_root}/*.erb"].map do |erb_path|
        [File.basename(erb_path).split('.')[0].to_sym, erb_path]
      end.to_h
    end

    def self.actions_root
      @actions_root ||= "#{local_erbs_root}/actions"
    end

    def self.local_erbs_root
      @local_erbs_root ||= "#{root_path}/views"
    end

    def self.root_path
      @root_path ||= File.dirname(__FILE__)
    end

    def self.config
      @config ||= Configuration.new.tap do |t|
        t.merge(base: :actions, params: default_available_actions_mapping)
        t.merge(base: :local_erbs, params: default_local_erb_mapping)
      end
    end

    def self.configure
      yield config if block_given?

      config.validate!
      __inject_dependencies
    end

    def self.local_erb_mapping
      config.local_erbs
    end

    private

    def self.__inject_dependencies
      return if @__already_called

      @__already_called = true
      ::Sidekiq::WebAction.prepend WebAction
      ::Sidekiq::Queue.prepend Queue
      ::Sidekiq::Job.prepend Job
      ::Sidekiq::Web.register WebApp
    end
  end
end

# dependent the error classes loaded on boot, requie after code is loaded
require 'sidekiq/web_custom/timeout'
