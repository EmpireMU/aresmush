module AresMUSH
  module Organisations
    
    def self.can_manage_orgs?(actor)
      actor && actor.has_permission?("manage_organisations")
    end
    
    def self.all_organisations
      config = Global.read_config("organisations", "organisations") || {}
      config.keys.sort
    end
    
    def self.get_organisation(name)
      return nil if !name
      config = Global.read_config("organisations", "organisations") || {}
      key = config.keys.find { |k| k.downcase == name.downcase }
      return nil if !key
      config[key].merge({ 'name' => key })
    end
    
    def self.organisation_description(name)
      org = get_organisation(name)
      return nil if !org
      org['description'] || ""
    end
    
    def self.organisation_wiki(name)
      org = get_organisation(name)
      return nil if !org
      org['wiki'] || ""
    end
    
    def self.get_members(org_name)
      Character.all.select { |c| c.in_organisation?(org_name) }
        .sort_by { |c| c.name }
    end
    
    def self.get_all_members_by_org
      orgs = {}
      all_organisations.each do |org|
        orgs[org] = get_members(org)
      end
      orgs
    end
    
    def self.build_web_org_data(char)
      char.organisation_names.map do |org_name|
        org = get_organisation(org_name)
        {
          name: org_name,
          description: org ? org['description'] : '',
          wiki: org ? org['wiki'] : ''
        }
      end
    end
    
  end
end
