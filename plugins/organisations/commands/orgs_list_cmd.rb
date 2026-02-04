module AresMUSH
  module Organisations
    class OrgsListCmd
      include CommandHandler
      
      def handle
        orgs = Organisations.all_organisations
        template = OrgsListTemplate.new orgs
        client.emit template.render
      end
    end
  end
end
