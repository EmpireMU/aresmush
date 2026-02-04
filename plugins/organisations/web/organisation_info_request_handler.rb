module AresMUSH
  module Organisations
    class OrganisationInfoRequestHandler
      def handle(request)
        org_name = request.args[:name]
        
        org = Organisations.get_organisation(org_name)
        
        if (!org)
          return { error: t('organisations.invalid_org') }
        end
        
        members = Organisations.get_members(org['name'])
        
        {
          name: org['name'],
          description: org['description'] || '',
          wiki: org['wiki'] || '',
          members: members.map { |m| { 
            name: m.name, 
            id: m.id,
            icon: Website.icon_for_char(m)
          }}
        }
      end
    end
  end
end
