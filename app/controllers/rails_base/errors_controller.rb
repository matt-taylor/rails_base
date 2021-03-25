module RailsBase
  class ErrorsController < ::ApplicationController
    before_action :set_variable

    def not_found
      @status = 404
      @message = "The Page can't be found"
      render_it
    end

    def unacceptable
      @status = 422
      @message = "Client Error. Please retry"
      render_it
    end

    def internal_error
      @status = 500
      @message = "An Internal Error has occured"
      render_it
    end

    private

    def render_it
      respond_to do |format|
        format.html { render status: @status }
      end
    end

    def set_variable
      @error_page = true
    end
  end
end
