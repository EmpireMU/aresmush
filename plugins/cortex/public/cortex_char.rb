module AresMUSH
  class Character
    attribute :cortex_sheet, :type => DataType::Hash, :default => {}
    attribute :cortex_plot_points, :type => DataType::Integer, :default => 1
  end
end
