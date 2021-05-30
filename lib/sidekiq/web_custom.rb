# frozen_string_literal: true
require 'byebug'
require_relative 'web_custom/version'

# require sidekiq/web first to ensure web_Action will prepend correctly
require 'sidekiq/web'
require 'sidekiq/web_custom/web_action'
require 'sidekiq/web_custom/queue'

module Sidekiq
  module WebCustom
    class Error < StandardError; end

    def self.available_actions_mapping
      @available_actions_mapping ||= Dir["#{actions_root}/*.erb"].map do |erb_path|
        [File.basename(erb_path).split('.')[0].to_sym, erb_path]
      end.to_h
    end

    def self.local_erb_mapping
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

    ::Sidekiq::WebAction.prepend WebAction
    ::Sidekiq::Queue.prepend Queue
  end
end
# Sidekiq::WebCustom.local_erb_mapping
# byebug
