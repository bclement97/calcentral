module Eft
  class MyEftEnrollment < UserSpecificModel
    include Cache::CachedFeed
    include Cache::JsonifiedFeed
    include Cache::FeedExceptionsHandled
    include Cache::UserCacheExpiry
    include CampusSolutions::CampusSolutionsIdRequired
    include Proxies::HttpClient
    include Proxies::Mockable
    include ClassLogger

    def initialize(uid, options={})
      super(uid, options)
      @settings = Settings.eft_proxy
      @fake = (options[:fake] != nil) ? options[:fake] : @settings.fake
      initialize_mocks if @fake
    end

    def default_message_on_exception
      "Failed to connect with EFT system"
    end

    def lookup_student_id
      if @uid
        @campus_solutions_id = CalnetCrosswalk::ByUid.new(user_id: @uid).lookup_campus_solutions_id
      end
    end

    def get_feed_internal
      return {} if @campus_solutions_id.nil? || !Settings.features.cs_billing
      get_parsed_response
    end

    def get_parsed_response
      lookup_student_id
      url = "#{@settings.base_url}eft_status?studentId=#{@campus_solutions_id}"
      logger.info "get_parsed_response: Fake = #{@fake}; Making request to #{url} on behalf of user #{@uid}; cache expiration #{self.class.expires_in}"
      response = get_response(
        url,
        headers: {"token" => "#{@settings.token}"},
        on_error: {rescue_status: 404}
      )
      feed = {statusCode: response.code}
      if response.code == 404
        logger.debug "404 response from EFT Enrollment API for user #{@uid}"
        response["errorMessage"] ? feed.merge(errorMessage: response["errorMessage"]) : feed.merge(errorMessage: "No EFT data could be found for your account")
      else
        logger.debug "EFT remote response: #{response.inspect}"
        feed.merge response.parsed_response
      end
    end

    def mock_json
      read_file('fixtures', 'json', 'eft_enrollment.json')
    end

  end
end
