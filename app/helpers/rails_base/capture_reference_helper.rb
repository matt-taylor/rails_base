module RailsBase
  module CaptureReferenceHelper
    CAPTURE_CONTROLLER_PATH = :referer_controller_path
    CAPTURE_ACTION_NAME = :referer_action_name
    CAPTURE_REFERRED_PATH = :referer_referred_path

    def authenticate_user!
      # only if request is a get and not authenticated
      capture_reference if request.method == 'GET' && !warden.authenticated?
      super()
    end

    def capture_reference
      return unless use_capture_reference?

      session[CAPTURE_CONTROLLER_PATH] = controller_path
      session[CAPTURE_ACTION_NAME] = action_name
      session[CAPTURE_REFERRED_PATH] = request.path
    end

    def capture_clear_reference_from_sesssion!
      session[CAPTURE_CONTROLLER_PATH] = nil
      session[CAPTURE_ACTION_NAME] = nil
      session[CAPTURE_REFERRED_PATH] = nil
    end

    def use_capture_reference?
      RailsBase.config.login_behavior.fallback_to_referred
    end

    def reference_redirect
      { controller: session[CAPTURE_CONTROLLER_PATH], action: session[CAPTURE_ACTION_NAME], path: session[CAPTURE_REFERRED_PATH] }
    end

    def capture_and_clear_reference_redirect!
      temp = reference_redirect
      capture_clear_reference_from_sesssion!
      temp[:path]
    end

    def redirect_from_reference
      return nil unless use_capture_reference?

      capture_and_clear_reference_redirect!
    end
  end
end
