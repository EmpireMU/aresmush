module AresMUSH
  class Character
    attribute :organisations, :type => DataType::Array, :default => []
    
    def organisation_names
      self.organisations || []
    end
    
    def in_organisation?(org_name)
      return false if !org_name
      self.organisations.any? { |o| o.downcase == org_name.downcase }
    end
    
    def add_to_organisation(org_name)
      return if self.in_organisation?(org_name)
      orgs = self.organisations
      orgs << org_name
      self.update(organisations: orgs.uniq)
    end
    
    def remove_from_organisation(org_name)
      orgs = self.organisations.reject { |o| o.downcase == org_name.downcase }
      self.update(organisations: orgs)
    end
  end
end
