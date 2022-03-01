require 'switch_user'

module RailsBase::Admin
  class ActionHelper
    ACTIONS_KEY = "___all_actions_#{(rand*10**10).to_i}___"
    CONTROLLER_ACTIONS_KEY = "___all_controller_actions__#{(rand*10**10).to_i}___"
    DEFAULT_ALLOWED_KLASSES = [ApplicationController, RailsBaseApplicationController, ::SwitchUserController]
    class << self
      def allowed_inherited_klasses
        DEFAULT_ALLOWED_KLASSES + (@allowed_klasses || [])
      end

      def add_inherited_klasses(klass)
        @allowed_klasses ||= []
        @allowed_klasses << klass
      end

      def clear_inherited_klasses!
        @allowed_klasses = nil
      end

      def add(instance)
        @actions ||= {}
        @all_actions ||= []
        @default_actions ||= []

        @all_actions << [instance]
        @default_actions << [instance]

        controller = instance.controller
        action = instance.action
        if controller.nil?
          @actions[ACTIONS_KEY] ||= []
          @actions[ACTIONS_KEY] << instance
          return
        end

        @actions[controller.to_s] ||= {}

        if action
           @actions[controller.to_s][action.to_s] ||= []
           @actions[controller.to_s][action.to_s] <<  instance
        else
          @actions[controller.to_s][CONTROLLER_ACTIONS_KEY] ||= []
          @actions[controller.to_s][CONTROLLER_ACTIONS_KEY] << instance
        end
      end

      def actions
        @actions
      end

      def reset!
        @actions = nil
        @all_actions = nil
        @default_actions.each { |instance| add(instance) }
      end
    end

    class InvalidControllerError < StandardError; end;
    class InvalidActionError < StandardError; end;
    class InvalidTitleError < StandardError; end;

    attr_accessor :controller, :action, :proc, :title, :default
    # controller is the controller class inherited by RailsBaseApplicationController
    # action is the method name on the controller
    # title should be the AdminAction.action
    # if proc available,
    # => |session, admin_user, user, title, struct|
    # => RailsBase::AdminStruct has methods original_attribute and new_attribute
    # => Expected return
    # => { admin_user, user, action, original_attribute, new_attribute, change_to }
    def initialize(controller: nil, action: nil, title: nil, default: false, proc: nil)
      @controller = controller
      @action = action
      @title = title
      @proc = proc
      valid_controller!
      valid_action!
      valid_title!
    end

    def add!
      self.class.add(self)
    end

    def call(req:, params:, admin_user:, user:, struct: nil)
      # byebug
      if proc
        action_params = proc.call(req, params, admin_user, user, title, struct)
        return if action_params.nil?

        AdminAction.action(**action_params)
      else
        default_call(request: request, admin_user: admin_user, user: user, struct: struct)
      end

    rescue StandardError => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace)
      Rails.logger.error("Trapping Error from AdminActionHelper.")
    end

    private

    def default_call(session:, admin_user:, user:, struct: nil)
      action_params = {
        admin_user: admin_user,
        user: user,
        action: title,
        change_from: struct&.original_attribute,
        change_to: struct&.new_attribute,
      }
      AdminAction.action(**action_params)
    end

    def valid_controller!
      return if self.class.allowed_inherited_klasses.include?(controller.superclass)

      raise InvalidControllerError, "@controller does not inherit #{self.class.allowed_inherited_klasses}"
    end

    def valid_action!
      return if action.nil?
      return if controller.instance_methods.map(&:to_s).include?(action.to_s)

      puts controller.instance_methods
      raise InvalidActionError, "#{controller} does not respond to #{action}"
    end

    def valid_title!
      return unless title.nil? && proc.nil?

      raise InvalidTitleError, "Missing title and proc. 1 or the other needs to be present"
    end
  end
end
