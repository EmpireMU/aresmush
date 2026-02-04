module AresMUSH
  module Cortex
    class CortexRollRequestHandler
      def handle(request)
        error = Website.check_login(request)
        return error if error

        parsed = Cortex.parse_web_roll(request)
        return parsed if parsed[:error]

        parsed[:result]
      end
    end
  end
end
