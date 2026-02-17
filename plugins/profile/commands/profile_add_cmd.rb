module AresMUSH
  module Profile
    class ProfileAddCmd
      include CommandHandler
      
      attr_accessor :field, :value

      def parse_args
        args = cmd.parse_args(ArgParser.arg1_equals_arg2)
        self.field = titlecase_arg(args.arg1)
        self.value = args.arg2
      end
      
      def required_args
        [ self.field, self.value ]
      end

      def check_can_edit_section
        return nil if Profile.can_edit_profile_section?(enactor, self.field)
        return t('profile.section_restricted', :field => self.field)
      end
      
      def handle
        profile = enactor.profile
        profile[self.field] = self.value
        enactor.set_profile(profile, enactor)
        
        Achievements.award_achievement(enactor, "profile_edit")
        
        client.emit_success t('profile.custom_profile_set', :field => self.field)
      end
    end
  end
end