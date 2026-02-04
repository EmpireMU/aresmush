module AresMUSH
  module Organisations
    class OrganisationMembersRequestHandler
      def handle(request)
        org_name = request.args[:name]
        
        org = Organisations.get_organisation(org_name)
        
        if (!org)
          return { error: t('organisations.invalid_org') }
        end
        
        members = Organisations.get_members(org['name'])
        
        {
          org: org['name'],
          members: members.map { |m| { 
            name: m.name, 
            id: m.id,
            icon: Website.icon_for_char(m),
            profile_title: Profile.profile_title(m)
          }}
        }
      end
    end
  end
end
