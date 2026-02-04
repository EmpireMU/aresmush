module AresMUSH
  module Organisations
    class CharactersByOrgRequestHandler
      def handle(request)
        # Get active (approved) characters
        chars = Chargen.approved_chars
        
        orgs = Organisations.all_organisations
        
        org_groups = []
        orgs.each do |org_name|
          members = chars.select { |c| c.in_organisation?(org_name) }
          
          if members.any?
            org_groups << {
              name: org_name,
              key: org_name.parameterize,
              chars: members.sort_by { |c| c.name }.map { |c| build_char_data(c) }
            }
          end
        end
        
        # Add characters not in any organisation
        no_org_chars = chars.reject { |c| c.organisation_names.any? }
        if no_org_chars.any?
          org_groups << {
            name: "No Organisation",
            key: "no-organisation",
            chars: no_org_chars.sort_by { |c| c.name }.map { |c| build_char_data(c) }
          }
        end
        
        {
          organisations: org_groups,
          all_orgs: orgs
        }
      end
      
      def build_char_data(char)
        {
          name: char.name,
          id: char.id,
          icon: Website.icon_for_char(char),
          profile_title: Profile.profile_title(char),
          organisations: char.organisation_names,
          demographic: char.demographic('gender'),
          group: char.group('Faction')
        }
      end
    end
  end
end
