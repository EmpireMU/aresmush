require 'json'
require 'date'

module AresMUSH
  module Importers
    class CharacterImporter
      DEFAULT_CURRENT_DATE = Date.new(632, 8, 10)

      def initialize(path, overwrite: false, dry_run: false)
        @path = path
        @overwrite = overwrite
        @dry_run = dry_run
        @created = 0
        @updated = 0
        @skipped = 0
        @errors = 0
      end

      def run
        data = JSON.parse(File.read(@path))
        characters = data['characters'] || data

        characters.each do |char_data|
          import_character(char_data)
        end

        print_summary
      end

      private

      def import_character(char_data)
        name = char_data['name']
        return if name.blank?

        char = Character.find_one_by_name(name)
        if char
          if @overwrite
            unless @dry_run
              update_character(char, char_data)
            end
            @updated += 1
          else
            @skipped += 1
          end
        else
          unless @dry_run
            char = Character.create(name: name)
            update_character(char, char_data)
          end
          @created += 1
        end
      rescue Exception => e
        @errors += 1
        Global.logger.error "Error importing character #{name}: #{e} backtrace=#{e.backtrace[0,5]}"
      end

      def update_character(char, data)
        update_demographics(char, data)
        update_description(char, data)
        update_profile(char, data)
        update_cortex(char, data)
        update_organisations(char, data)
        update_status(char, data)
      end

      def update_demographics(char, data)
        set_demo(char, 'full name', data['full_name'])
        set_demo(char, 'gender', data['gender'])
        set_demo(char, 'realm', data['realm'])

        birthdate = compute_birthdate(data['birthday'], data['age'])
        set_demo(char, 'birthdate', birthdate) if birthdate
      end

      def update_description(char, data)
        desc = data['desc']
        char.update(description: desc) if desc
      end

      def update_profile(char, data)
        profile = {}
        profile['Background'] = data['background'] if present?(data['background'])
        profile['Personality'] = data['personality'] if present?(data['personality'])
        profile['Notable Traits'] = data['notable_traits'] if present?(data['notable_traits'])
        profile['Special Effects'] = data['special_effects'] if present?(data['special_effects'])
        profile['Secrets'] = data['secret_information'] if present?(data['secret_information'])

        return if profile.empty?

        order = profile.keys
        char.update(profile_order: order)
        char.set_profile(profile, system_character)
      end

      def update_cortex(char, data)
        cortex = data['cortex'] || {}
        sheet = {
          "attributes" => cortex['attributes'] || [],
          "skills" => cortex['skills'] || [],
          "distinctions" => cortex['distinctions'] || [],
          "resources" => cortex['resources'] || [],
          "signature_assets" => cortex['signature_assets'] || [],
          "powers" => cortex['powers'] || [],
          "temporary_assets" => cortex['temporary_assets'] || [],
          "complications" => cortex['complications'] || []
        }

        sheet = Cortex.normalize_sheet(sheet)
        char.update(cortex_sheet: sheet)

        plot_points = cortex['plot_points']
        char.update(cortex_plot_points: plot_points) if plot_points
      end

      def update_organisations(char, data)
        orgs = data['organisations'] || []
        valid_orgs = Organisations.all_organisations
        filtered = orgs.select { |o| valid_orgs.any? { |v| v.casecmp(o.to_s).zero? } }
        char.update(organisations: filtered)
      end

      def update_status(char, data)
        status = (data['status'] || '').downcase
        case status
        when 'available'
          char.update(idle_state: 'Roster', roster_played: false)
          remove_role(char, 'approved')
        when 'gone'
          char.update(idle_state: 'Gone')
          remove_role(char, 'approved')
        when 'active'
          char.update(idle_state: nil)
          add_role(char, 'approved')
          char.update(approved_at: Time.now)
        else
          # unfinished/unknown -> leave as-is
        end
      end

      def add_role(char, role_name)
        role = Role.find_one_by_name(role_name)
        return if !role
        char.roles.add(role) if !char.has_role?(role)
      end

      def remove_role(char, role_name)
        role = Role.find_one_by_name(role_name)
        return if !role
        char.roles.delete(role) if char.has_role?(role)
      end

      def set_demo(char, key, value)
        return if value.blank?
        if key == 'birthdate' && !value.is_a?(Date)
          return
        end
        char.update_demographic(key, value)
      end

      def compute_birthdate(birthday_str, age_value)
        return nil if birthday_str.blank? || age_value.blank?

        day, month = parse_birthday(birthday_str)
        return nil if !day || !month

        age = age_value.to_i
        return nil if age <= 0

        current = DEFAULT_CURRENT_DATE
        year = current.year - age
        if (month > current.month) || (month == current.month && day > current.day)
          year -= 1
        end

        Date.new(year, month, day)
      rescue
        nil
      end

      def parse_birthday(birthday_str)
        return nil, nil if birthday_str.blank?
        text = birthday_str.to_s.strip
        match = text.match(/(\d{1,2})\s+([A-Za-z]+)/)
        return nil, nil if !match

        day = match[1].to_i
        month = month_number(match[2])
        return nil, nil if !month
        return day, month
      end

      def month_number(name)
        months = {
          'january' => 1, 'february' => 2, 'march' => 3, 'april' => 4,
          'may' => 5, 'june' => 6, 'july' => 7, 'august' => 8,
          'september' => 9, 'october' => 10, 'november' => 11, 'december' => 12
        }
        months[name.downcase]
      end

      def present?(value)
        !value.nil? && !value.to_s.strip.empty?
      end

      def system_character
        Game.master.system_character
      end

      def print_summary
        puts "Character import complete."
        puts "Created: #{@created}"
        puts "Updated: #{@updated}"
        puts "Skipped: #{@skipped}"
        puts "Errors: #{@errors}"
      end
    end
  end
end

param = ENV['ares_rake_param']
default_path = File.expand_path(File.join(AresMUSH.game_path, '..', 'ares_export', 'characters.json'))

path = default_path
overwrite = false
dry_run = false

if param && !param.strip.empty?
  parts = param.split(/\s+/)
  path = parts.shift
  overwrite = parts.include?('--overwrite')
  dry_run = parts.include?('--dry-run')
end

if !File.exist?(path)
  puts "Import file not found: #{path}"
  puts "Usage: bin/script import_characters_export [/path/to/characters.json] [--overwrite] [--dry-run]"
  exit 1
end

AresMUSH::Importers::CharacterImporter.new(path, overwrite: overwrite, dry_run: dry_run).run
