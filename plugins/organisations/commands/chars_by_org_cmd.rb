module AresMUSH
  module Organisations
    class CharsByOrgCmd
      include CommandHandler
      
      def handle
        orgs = Organisations.all_organisations
        template = CharsByOrgTemplate.new orgs
        client.emit template.render
      end
    end
  end
end
