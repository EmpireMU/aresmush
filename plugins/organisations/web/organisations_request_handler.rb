module AresMUSH
  module Organisations
    class OrganisationsRequestHandler
      def handle(request)
        orgs = Organisations.all_organisations
        
        organisations = orgs.map do |org_name|
          org = Organisations.get_organisation(org_name)
          members = Organisations.get_members(org_name)
          {
            name: org_name,
            description: org['description'] || '',
            wiki: org['wiki'] || '',
            member_count: members.count
          }
        end
        
        { organisations: organisations }
      end
    end
  end
end
