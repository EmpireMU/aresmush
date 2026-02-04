module AresMUSH
  module Organisations
    class OrgsListTemplate < ErbTemplateRenderer
      
      attr_accessor :orgs
      
      def initialize(orgs)
        @orgs = orgs
        super File.dirname(__FILE__) + "/orgs_list.erb"
      end
      
      def organisation_list
        list = []
        orgs.each do |org_name|
          org = Organisations.get_organisation(org_name)
          members = Organisations.get_members(org_name)
          list << {
            name: org_name,
            description: org['description'] || '',
            member_count: members.count
          }
        end
        list
      end
    end
  end
end
