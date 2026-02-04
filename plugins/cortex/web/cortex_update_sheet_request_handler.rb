module AresMUSH
  module Cortex
    class CortexUpdateSheetRequestHandler
      def handle(request)
        enactor = request.enactor
        char = Character.find_one_by_name request.args['id']

        if (!char)
          return { error: t('webportal.not_found') }
        end

        error = Website.check_login(request)
        return error if error

        if (!Cortex.can_manage_sheet?(enactor, char))
          return { error: t('cortex.not_allowed') }
        end

        sheet = request.args['sheet'] || {}
        plot_points = request.args['plot_points']

        normalized = Cortex.normalize_sheet(sheet)
        errors = Cortex.validate_sheet(normalized)
        if (errors.any?)
          return { error: errors.join(" ") }
        end

        updates = { cortex_sheet: normalized }
        if (!plot_points.nil?)
          updates[:cortex_plot_points] = plot_points.to_i
        end
        char.update(updates)

        {
          sheet: normalized,
          plot_points: char.cortex_plot_points || 0
        }
      end
    end
  end
end
