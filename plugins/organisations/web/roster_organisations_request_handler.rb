module AresMUSH
  module Organisations
    class RosterOrganisationsRequestHandler
      def handle(request)
        # Get the organisation filter from request, if any
        args = request.args || {}
        filter_org = args[:organisation]
        
        fields = Global.read_config("idle", "roster_fields").select { |f| f['field'] != 'name' }
        titles = fields.map { |f| f['title'] }
        
        # Get all roster characters
        all_chars = Character.all.select { |c| c.on_roster? }
        
        # Filter by organisation if specified
        if filter_org && !filter_org.blank?
          chars = all_chars.select { |c| c.in_organisation?(filter_org) }
          
          roster = [{
            key: filter_org.parameterize(),
            name: filter_org,
            active_class: "active",
            chars: chars.sort_by { |c| c.name }.map { |c| build_profile(c, fields) }
          }]
        else
          # "All" tab first (default), then group by organisations
          roster = [{
            key: "all",
            name: "All",
            active_class: "active",
            chars: all_chars.sort_by { |c| c.name }.map { |c| build_profile(c, fields) }
          }]
          orgs = Organisations.all_organisations
          orgs.each do |org|
            members = Organisations.get_members(org)
            roster_members = members.select { |c| c.on_roster? }
            if roster_members.any?
              roster << {
                key: org.parameterize(),
                name: org,
                active_class: "",
                chars: roster_members.sort_by { |c| c.name }.map { |c| build_profile(c, fields) }
              }
            end
          end
          no_org_chars = all_chars.reject { |c| c.organisation_names.any? }
          if no_org_chars.any?
            roster << {
              key: "no-organisation",
              name: "No Organisation",
              active_class: "",
              chars: no_org_chars.sort_by { |c| c.name }.map { |c| build_profile(c, fields) }
            }
          end
        end
        
        {
          roster: roster,
          titles: titles,
          organisations: Organisations.all_organisations
        }
      end
      
      def build_profile(char, field_config)
        demographics = {}
        Demographics.visible_demographics(char, nil).each { |d| 
            demographics[d.downcase] = char.demographic(d)
          }
        
        if (Ranks.is_enabled?)
          demographics['rank'] = char.rank
        end
          
        demographics['age'] = char.age
        demographics['birthdate'] = char.formatted_birthdate
        
        groups = {}
        
        Demographics.all_groups.keys.each { |g| 
          groups[g.downcase] = char.group(g)  
          }
        
        fields = {}
        field_config.each do |config|
          field = config["field"]
          title = config["title"]
          value = config["value"]

          fields[title] = Profile.general_field(char, field, value)
        end
        
        organisations = char.organisation_names
          
          {
            name: char.name,
            id: char.id,
            profile_title: Ranks.is_enabled? ? Profile.profile_title(char) : char.fullname,
            fields: fields,
            icon: Website.icon_for_char(char),
            roster_notes: Website.format_markdown_for_html(char.roster_notes || ""),
            previously_played: char.roster_played,
            app_required: Idle.roster_app_required?(char),
            contact: char.roster_contact,
            groups: groups,
            demographics: demographics,
            organisations: organisations,
            app_pending: char.roster_job ? true: false
        }        
      end
      
    end
  end
end
