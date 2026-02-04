module AresMUSH
  module Organisations
    
    def self.build_web_profile_data(char, viewer)
      {
        organisations: build_web_org_list(char)
      }
    end
    
    def self.build_web_org_list(char)
      char.organisation_names.sort.map do |org_name|
        org = Organisations.get_organisation(org_name)
        {
          name: org_name,
          description: org ? org['description'] : '',
          wiki: org ? org['wiki'] : ''
        }
      end
    end
    
  end
end
