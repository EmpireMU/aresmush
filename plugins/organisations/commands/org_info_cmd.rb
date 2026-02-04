module AresMUSH
  module Organisations
    class OrgInfoCmd
      include CommandHandler
      
      attr_accessor :org_name
      
      def parse_args
        self.org_name = titlecase_arg(cmd.args)
      end
      
      def required_args
        [ self.org_name ]
      end
      
      def handle
        org = Organisations.get_organisation(self.org_name)
        
        if (!org)
          client.emit_failure t('organisations.invalid_org')
          return
        end
        
        members = Organisations.get_members(org['name'])
        template = OrgInfoTemplate.new org, members
        client.emit template.render
      end
    end
  end
end
