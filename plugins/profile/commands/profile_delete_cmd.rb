module AresMUSH
  module Profile
    class ProfileDeleteCmd
      include CommandHandler
      
      attr_accessor :field
     
      def parse_args
        self.field = titlecase_arg(cmd.args)
      end
      
      def required_args
        [ self.field ]
      end

      def check_can_edit_section
        return nil if Profile.can_edit_profile_section?(enactor, self.field)
        return t('profile.section_restricted', :field => self.field)
      end
      
      def handle
        profile = enactor.profile
        profile.delete self.field
        enactor.set_profile(profile, enactor)
        client.emit_success t('profile.custom_profile_cleared', :field => self.field)
      end
    end
  end
end