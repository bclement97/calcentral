module CampusSolutions
  class NameDelete < DeletingProxy

    include ProfileFeatureFlagged

    def initialize(options = {})
      super(Settings.campus_solutions_proxy, options)
      initialize_mocks if @fake
    end

    def self.field_mappings
      @field_mappings ||= FieldMapping.to_hash(
        [
          FieldMapping.required(:type, :TYPE)
        ]
      )
    end

    def xml_filename
      'name_delete.xml'
    end

    def response_root_xml_node
      'NAMES_DELETE_RESPONSE'
    end

    def default_post_params
      # TODO ID is hardcoded until we can use ID crosswalk service to convert CalNet ID to CS Student ID
      {
        EMPLID: '25738808'
      }
    end

    def url
      "#{@settings.base_url}/UC_CC_PERS_NAME.v1/name/delete"
    end

  end
end
