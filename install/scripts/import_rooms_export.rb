require 'json'

module AresMUSH
  module Importers
    class RoomImporter
      def initialize(path, overwrite: false, dry_run: false)
        @path = path
        @overwrite = overwrite
        @dry_run = dry_run
        @created = 0
        @updated = 0
        @skipped = 0
        @errors = 0
        @exit_created = 0
        @exit_updated = 0
        @exit_skipped = 0
        @exit_errors = 0
        @room_map = {}
        @area_map = {}
      end

      def run
        data = JSON.parse(File.read(@path))
        rooms = data['rooms'] || []
        exits = data['exits'] || []

        import_rooms(rooms)
        import_exits(exits)
        print_summary
      end

      private

      def import_rooms(rooms)
        rooms.each do |room_data|
          name = (room_data['name'] || '').strip
          next if name.blank?

          area = find_or_create_area(room_data['area'])
          room = find_room(name, area)

          if room
            if @overwrite
              update_room(room, room_data, area) unless @dry_run
              @updated += 1
            else
              @skipped += 1
            end
          else
            unless @dry_run
              room = Room.create(name: name, area: area)
              update_room(room, room_data, area)
            end
            @created += 1
          end

          room_id = room_data['id'].to_s
          @room_map[room_id] = room if room_id.present? && room
        rescue Exception => e
          @errors += 1
          Global.logger.error "Error importing room #{name}: #{e} backtrace=#{e.backtrace[0,5]}"
        end
      end

      def update_room(room, data, area)
        updates = {}
        desc = data['desc']
        updates[:description] = desc if present?(desc)
        updates[:shortdesc] = data['shortdesc'] if present?(data['shortdesc'])
        updates[:room_type] = data['room_type'] if present?(data['room_type'])
        updates[:room_icon] = data['room_icon'] if present?(data['room_icon'])

        grid_x = data['grid_x']
        grid_y = data['grid_y']
        updates[:room_grid_x] = grid_x if present?(grid_x)
        updates[:room_grid_y] = grid_y if present?(grid_y)

        updates[:area] = area if area
        room.update(updates) if !updates.empty?
      end

      def import_exits(exits)
        exits.each do |exit_data|
          name = (exit_data['name'] || '').strip
          next if name.blank?

          source_id = exit_data['source_id'].to_s
          source = @room_map[source_id]
          if !source
            @exit_errors += 1
            next
          end

          dest_id = exit_data['dest_id'].to_s
          dest = @room_map[dest_id] if dest_id.present?

          existing = source.exits.select { |e| e.name_upcase == name.upcase }.first

          if existing
            if @overwrite
              update_exit(existing, exit_data, dest) unless @dry_run
              @exit_updated += 1
            else
              @exit_skipped += 1
            end
          else
            unless @dry_run
              AresMUSH::Exit.create(name: name, source: source, dest: dest)
              created = source.exits.select { |e| e.name_upcase == name.upcase }.first
              update_exit(created, exit_data, dest) if created
            end
            @exit_created += 1
          end
        rescue Exception => e
          @exit_errors += 1
          Global.logger.error "Error importing exit #{name}: #{e} backtrace=#{e.backtrace[0,5]}"
        end
      end

      def update_exit(exit_obj, data, dest)
        updates = {}
        alias_name = data['alias']
        aliases = data['aliases']
        if alias_name.blank? && aliases.is_a?(Array) && !aliases.empty?
          alias_name = aliases.first
        end
        updates[:alias] = alias_name if present?(alias_name)
        updates[:description] = data['desc'] if present?(data['desc'])
        updates[:shortdesc] = data['shortdesc'] if present?(data['shortdesc'])
        updates[:dest] = dest if dest
        exit_obj.update(updates) if !updates.empty?
      end

      def find_room(name, area)
        if area
          return area.rooms.select { |r| r.name.casecmp(name).zero? }.first
        end
        Room.find_one_by_name(name)
      end

      def find_or_create_area(name)
        return nil if name.blank?
        normalized = name.strip
        return nil if normalized.empty?

        area = @area_map[normalized]
        return area if area

        area = Area.find(name_upcase: normalized.upcase).first
        if !area && !@dry_run
          area = Area.create(name: normalized)
        end

        @area_map[normalized] = area if area
        area
      end

      def present?(value)
        !value.nil? && !value.to_s.strip.empty?
      end

      def print_summary
        puts "Room import complete."
        puts "Rooms created: #{@created}"
        puts "Rooms updated: #{@updated}"
        puts "Rooms skipped: #{@skipped}"
        puts "Room errors: #{@errors}"
        puts "Exits created: #{@exit_created}"
        puts "Exits updated: #{@exit_updated}"
        puts "Exits skipped: #{@exit_skipped}"
        puts "Exit errors: #{@exit_errors}"
      end
    end
  end
end

param = ENV['ares_rake_param']
default_path = File.expand_path(File.join(AresMUSH.game_path, '..', 'ares_export', 'rooms.json'))

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
  puts "Usage: bin/script import_rooms_export [/path/to/rooms.json] [--overwrite] [--dry-run]"
  exit 1
end

AresMUSH::Importers::RoomImporter.new(path, overwrite: overwrite, dry_run: dry_run).run
