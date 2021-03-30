module RailsBase
  class ErrorsController < ApplicationController
    before_action :set_variable

    def not_found
      @status = 404
      @message = "The Page can't be found"
      render template: 'rails_base/errors/not_found'
    end

    def unacceptable
      @status = 422
      @message = "Client Error. Please retry"
      render template: 'rails_base/errors/unacceptable'
    end

    def internal_error
      @status = 500
      @message = "An Internal Error has occured"
      render template: 'rails_base/errors/internal_error'
    end

    private

    def set_variable
      @error_page = true
    end
  end
end
