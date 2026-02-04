module AresMUSH
  module Organisations
    class OrgInfoTemplate < ErbTemplateRenderer
      
      attr_accessor :org, :members
      
      def initialize(org, members)
        @org = org
        @members = members
        super File.dirname(__FILE__) + "/org_info.erb"
      end
      
      def org_name
        org['name']
      end
      
      def description
        org['description'] || ''
      end
      
      def wiki
        org['wiki'] || ''
      end
      
      def member_list
        members.map { |m| m.name }.join(", ")
      end
      
      def member_count
        members.count
      end
    end
  end
end
