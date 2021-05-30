# frozen_string_literal: true

module Sidekiq
  module WebCustom
    module WebAction
      OVERWRITE_VALUE = '__sidekiq_web_custom_replacement__'

      def self.local_erbs
        @local_erbs ||= "#{File.expand_path("#{File.dirname(__FILE__)}/..")}/views"
      end

      def erb(content, options = {})
        if content.is_a?(Symbol) && Sidekiq::WebCustom.local_erb_mapping[content].present?
          src_file_replacement(content)
          unless respond_to?(:"_erb_#{content}")
            file_name = Sidekiq::WebCustom.local_erb_mapping[content]
            src = ERB.new(src_file_replacement(content)).src
            WebAction.class_eval("def _erb_#{content}\n#{src}\n end", file_name)
          end
        end
        super(content, options)
      end

      def src_file_replacement(content)
        file_name = Sidekiq::WebCustom.local_erb_mapping[content]
        contents = File.read(file_name)
        actions = Sidekiq::WebCustom.available_actions_mapping.map do |action, action_path|
          File.read(action_path)
        end.join(" ")
        contents.gsub(OVERWRITE_VALUE, actions)
      end
    end
  end
end
