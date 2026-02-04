module AresMUSH
  module Organisations
    class CharOrgsTemplate < ErbTemplateRenderer
      
      attr_accessor :char
      
      def initialize(char)
        @char = char
        super File.dirname(__FILE__) + "/char_orgs.erb"
      end
      
      def char_name
        char.name
      end
      
      def org_list
        if char.organisation_names.empty?
          return t('organisations.not_in_any', :name => char.name)
        end
        
        orgs = char.organisation_names.map do |org_name|
          org = Organisations.get_organisation(org_name)
          desc = org ? org['description'] : ''
          "%xh#{org_name}%xn - #{desc}"
        end
        orgs.join("\n")
      end
    end
  end
end
