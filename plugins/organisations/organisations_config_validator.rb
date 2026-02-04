module AresMUSH
  module Organisations
    class OrganisationsConfigValidator
      attr_accessor :validator
      
      def initialize
        @validator = Manage::ConfigValidator.new("organisations")
      end
      
      def validate
        @validator.require_hash('organisations')
        @validator.require_hash('shortcuts')
        
        begin
          orgs = Global.read_config('organisations', 'organisations')
          if (orgs.empty?)
            @validator.add_error "organisations:organisations must have at least one organisation defined."
          end
          
          orgs.each do |name, data|
            if (!data.is_a?(Hash))
              @validator.add_error "organisations:organisations:#{name} must be a hash with description and wiki fields."
            elsif (!data['description'])
              @validator.add_error "organisations:organisations:#{name} is missing a description field."
            end
          end
          
        rescue Exception => ex
          @validator.add_error "Unknown organisations config error. Fix other errors first and try again. #{ex} #{ex.backtrace[0, 3]}"
        end
        
        @validator.errors
      end

    end
  end
end
