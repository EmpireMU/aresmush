module AresMUSH
  module Organisations
    class CharsByOrgTemplate < ErbTemplateRenderer
      
      attr_accessor :orgs
      
      def initialize(orgs)
        @orgs = orgs
        super File.dirname(__FILE__) + "/chars_by_org.erb"
      end
      
      def org_list
        list = []
        chars = Chargen.approved_chars
        
        orgs.each do |org_name|
          members = chars.select { |c| c.in_organisation?(org_name) }
          
          if members.any?
            list << {
              name: org_name,
              members: members.sort_by { |c| c.name }
            }
          end
        end
        list
      end
    end
  end
end
