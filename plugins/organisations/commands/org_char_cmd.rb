module AresMUSH
  module Organisations
    class OrgCharCmd
      include CommandHandler
      
      attr_accessor :target
      
      def parse_args
        self.target = titlecase_arg(cmd.args)
      end
      
      def required_args
        [ self.target ]
      end
      
      def handle
        ClassTargetFinder.with_a_character(self.target, client, enactor) do |model|
          template = CharOrgsTemplate.new model
          client.emit template.render
        end
      end
    end
  end
end
