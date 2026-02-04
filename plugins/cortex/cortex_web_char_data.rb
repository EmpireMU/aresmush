module AresMUSH
  module Cortex
    class WebCharDataBuilder
      def build(char, viewer)
        show_sheet = Cortex.can_view_sheet?(viewer, char)
        can_manage = Cortex.can_manage_sheet?(viewer, char)

        {
          show_sheet: show_sheet,
          can_manage: can_manage,
          sheet: show_sheet ? Cortex.sheet_for(char) : nil,
          plot_points: char.cortex_plot_points || 0,
          dice_sizes: Cortex::DICE_SIZES
        }
      end
    end
  end
end
