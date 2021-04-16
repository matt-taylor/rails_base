module RailsBase::Authentication
  class SingleSignOnVerify < RailsBase::ServiceBase
    delegate :data, to: :context
    delegate :reason, to: :context
    delegate :bypass, to: :context

    def call
      datum = find_data_point
      context.data = datum
      if bypass
        context.should_fail = !datum[:valid]
        context.url_redirect = datum[:extra] || RailsBase.url_routes.authenticated_root_path
        log(level: :info, msg: "sending full data point. bypass set to true")
        return
      end

      context.sign_in = false
      if datum[:valid]
        context.sign_in = true
        context.url_redirect = datum[:extra] || RailsBase.url_routes.authenticated_root_path
        context.user = datum[:user]
      else
        context.url_redirect = datum[:extra] || RailsBase.url_routes.unauthenticated_root_path
        context.fail!(message: "Authorization token error: #{datum[:invalid_reason].join(',')}")
      end
    end

    def find_data_point
      params = {
        data: data,
        reason: reason,
        access_count: !(bypass || false)
      }
      ShortLivedData.find_datum(params)
    end

    def validate!
      raise "Expected data to be a String. Received #{data.class}" unless data.is_a? String
      raise "Expected reason to be a String. Received #{reason.class}" unless reason.is_a? String
    end
  end
end
