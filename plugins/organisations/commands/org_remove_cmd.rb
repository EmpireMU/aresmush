module AresMUSH
  module Organisations
    class OrgRemoveCmd
      include CommandHandler
      
      attr_accessor :target, :org_name
      
      def parse_args
        args = cmd.parse_args(ArgParser.arg1_equals_arg2)
        self.target = titlecase_arg(args.arg1)
        self.org_name = titlecase_arg(args.arg2)
      end
      
      def required_args
        [ self.target, self.org_name ]
      end
      
      def check_can_manage
        return t('dispatcher.not_allowed') if !Organisations.can_manage_orgs?(enactor)
        return nil
      end
      
      def handle
        org = Organisations.get_organisation(self.org_name)
        
        if (!org)
          client.emit_failure t('organisations.invalid_org')
          return
        end
        
        ClassTargetFinder.with_a_character(self.target, client, enactor) do |model|
          if (!model.in_organisation?(org['name']))
            client.emit_failure t('organisations.not_member', :name => model.name, :org => org['name'])
            return
          end
          
          model.remove_from_organisation(org['name'])
          client.emit_success t('organisations.removed', :name => model.name, :org => org['name'])
        end
      end
    end
  end
end
