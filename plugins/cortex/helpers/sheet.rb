module AresMUSH
  module Cortex
    DICE_SIZES = [4, 6, 8, 10, 12].freeze
    SHEET_SECTIONS = %w(attributes skills distinctions resources signature_assets powers temporary_assets complications).freeze

    def self.default_sheet
      {
        "attributes" => build_trait_list(Global.read_config("cortex", "attributes"), 6),
        "skills" => build_trait_list(Global.read_config("cortex", "skills"), 4),
        "distinctions" => build_trait_list(Global.read_config("cortex", "distinctions"), 8),
        "resources" => [],
        "signature_assets" => [],
        "powers" => [],
        "temporary_assets" => [],
        "complications" => []
      }
    end

    def self.sheet_for(char)
      sheet = char.cortex_sheet
      if (!sheet || sheet.empty?)
        sheet = initialize_sheet(char)
      else
        sheet = normalize_sheet(sheet)
      end
      sheet
    end

    def self.initialize_sheet(char)
      sheet = default_sheet
      char.update(cortex_sheet: sheet)
      Global.logger.debug "Initialized Cortex sheet for #{char.name}"
      sheet
    end

    def self.reset_sheet_to_defaults(char)
      initialize_sheet(char)
    end

    def self.normalize_sheet(sheet)
      normalized = {}
      SHEET_SECTIONS.each do |section|
        normalized[section] = normalize_list((sheet[section] || sheet[section.to_sym]))
      end
      normalized
    end

    def self.validate_sheet(sheet)
      errors = []
      SHEET_SECTIONS.each do |section|
        list = sheet[section] || []
        if (!list.respond_to?(:each))
          errors << t('cortex.invalid_section', :section => section)
          next
        end
        list.each do |item|
          name = item["name"]
          die = item["die"]
          if (name.blank? || die.blank?)
            errors << t('cortex.invalid_trait', :section => section)
            break
          end
          if (!valid_die?(die))
            errors << t('cortex.invalid_die', :die => die)
            break
          end
        end
      end
      errors
    end

    def self.normalize_list(list)
      return [] if !list
      list.map do |item|
        next if !item
        name = item["name"] || item[:name]
        die = item["die"] || item[:die]
        desc = item["desc"] || item[:desc]
        die = normalize_die(die)
        next if name.blank? || die.blank?
        { "name" => name.strip, "die" => die, "desc" => desc ? desc.strip : "" }
      end.compact
    end

    def self.build_trait_list(config_list, default_die)
      list = (config_list || []).map do |item|
        if (item.is_a?(Hash))
          name = item["name"] || item[:name]
          die = item["die"] || item[:die] || "d#{default_die}"
          desc = item["desc"] || item[:desc] || ""
        else
          name = item
          die = "d#{default_die}"
          desc = ""
        end
        next if name.blank?
        { "name" => name, "die" => normalize_die(die), "desc" => desc }
      end.compact
      normalize_list(list)
    end

    def self.normalize_die(die)
      return nil if die.blank?
      d = die.to_s.strip.downcase
      d = "d#{d}" if d =~ /^\d+$/
      return nil if d !~ /^d\d+$/
      size = d[1..-1].to_i
      return nil if !DICE_SIZES.include?(size)
      "d#{size}"
    end

    def self.valid_die?(die)
      !normalize_die(die).blank?
    end
  end
end
