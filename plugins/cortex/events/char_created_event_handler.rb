module AresMUSH
  module Cortex
    class CortexCharCreatedEventHandler
      def on_event(event)
        char = Character[event.char_id]
        return if !char
        Cortex.initialize_sheet(char)
      end
    end
  end
end
