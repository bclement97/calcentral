module CampusSolutions
  class Proxy < BaseProxy

    include ClassLogger
    include Cache::UserCacheExpiry
    include Proxies::MockableXml

    APP_ID = 'campussolutions'
    APP_NAME = 'Campus Solutions'

    def instance_key
      @uid
    end

    def xml_filename
      ''
    end

    def mock_xml
      read_file('fixtures', 'xml', 'campus_solutions', xml_filename)
    end

    def get
      internal_response = self.class.smart_fetch_from_cache(id: instance_key) do
        get_internal
      end
      if internal_response[:noStudentId] || internal_response[:statusCode] < 400
        internal_response
      else
        {
          errored: true
        }
      end
    end

    def get_internal
      logger.info "Fake = #{@fake}; Making request to #{url} on behalf of user #{@uid}; cache expiration #{self.class.expires_in}"
      response = get_response(url, request_options)
      logger.debug "Remote server status #{response.code}, Body = #{response.body}"
      feed = build_feed response
      if feed.blank?
        logger.error "Build_feed returned nothing; falling back on parsed response"
        feed = response.parsed_response
      end
      {
        statusCode: response.code,
        feed: convert_feed_keys(feed)
      }
    end

    def convert_feed_keys(feed)
      HashConverter.downcase_and_camelize(feed)
    end

    def url
      @settings.base_url
    end

    def request_options
      {
        query: {
          'SCC_PROFILE_ID' => @uid,
          'languageCd' => 'ENG'
        }
      }
    end

    def build_feed(response)
      response.parsed_response
    end

  end
end
