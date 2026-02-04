$:.unshift File.dirname(__FILE__)

module AresMUSH
  module Cortex
    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.get_web_request_handler(request)
      case request.cmd
      when "cortexUpdateSheet"
        return CortexUpdateSheetRequestHandler
      when "cortexRoll"
        return CortexRollRequestHandler
      when "cortexAddSceneRoll"
        return CortexAddSceneRollRequestHandler
      when "cortexAddJobRoll"
        return CortexAddJobRollRequestHandler
      end
      nil
    end

    def self.build_web_char_data(char, viewer)
      Cortex::WebCharDataBuilder.new.build(char, viewer)
    end

    def self.can_manage_sheet?(viewer, char)
      return false if !viewer
      viewer.id == char.id || viewer.has_permission?("manage_game")
    end

    def self.can_view_sheet?(viewer, char)
      return true if Global.read_config("cortex", "public_sheets")
      can_manage_sheet?(viewer, char)
    end

    def self.is_enabled?
      Manage.is_extra_installed?("cortex")
    end
  end
end
