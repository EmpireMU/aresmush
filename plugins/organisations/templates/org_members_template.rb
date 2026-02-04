module AresMUSH
  module Organisations
    class OrgMembersTemplate < ErbTemplateRenderer
      
      attr_accessor :org, :members
      
      def initialize(org, members)
        @org = org
        @members = members
        super File.dirname(__FILE__) + "/org_members.erb"
      end
      
      def org_name
        org['name']
      end
      
      def member_list
        if members.empty?
          return t('organisations.no_members')
        end
        members.map { |m| m.name }.join(", ")
      end
    end
  end
end
