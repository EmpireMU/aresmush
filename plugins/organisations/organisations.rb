$:.unshift File.dirname(__FILE__)

module AresMUSH
  module Organisations
    def self.plugin_dir
      File.dirname(__FILE__)
    end
 
    def self.shortcuts
      Global.read_config("organisations", "shortcuts")
    end
 
    def self.get_cmd_handler(client, cmd, enactor)
      case cmd.root
      when "org", "organisation"
        case cmd.switch
        when "add"
          return OrgAddCmd
        when "remove"
          return OrgRemoveCmd
        when "members"
          return OrgMembersCmd
        when "chars"
          return CharsByOrgCmd
        when nil
          if (cmd.args)
            return OrgInfoCmd
          else
            return OrgsListCmd
          end
        end
      when "orgs", "organisations"
        if (cmd.args)
          return OrgCharCmd
        else
          return OrgsListCmd
        end
      end
      
      nil
    end
    
    def self.get_web_request_handler(request)
      case request.cmd
      when "organisations"
        return OrganisationsRequestHandler
      when "organisationInfo"
        return OrganisationInfoRequestHandler
      when "organisationMembers"
        return OrganisationMembersRequestHandler
      when "rosterByOrganisation"
        return RosterOrganisationsRequestHandler
      when "charactersByOrganisation"
        return CharactersByOrgRequestHandler
      end
      nil
    end
    
    def self.check_config
      validator = OrganisationsConfigValidator.new
      validator.validate
    end
    
  end
end
