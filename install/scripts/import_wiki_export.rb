require 'json'

module AresMUSH
  module Website
    class WikiExportImporter
      def initialize(path, overwrite: false, dry_run: false)
        @path = path
        @overwrite = overwrite
        @dry_run = dry_run
        @created = 0
        @updated = 0
        @skipped = 0
        @restricted = []
      end

      def run
        data = JSON.parse(File.read(@path))
        pages = data['pages'] || []

        pages.each do |page_data|
          import_page(page_data)
        end

        print_summary
      end

      private

      def import_page(page_data)
        slug = page_data['slug']
        title = page_data['title'] || slug || "Untitled"
        name = slug || WikiPage.sanitize_page_name(title)
        content = page_data['content'] || ""

        tags = []
        tags << page_data['category'] if page_data['category'] && !page_data['category'].empty?
        tags << page_data['subcategory'] if page_data['subcategory'] && !page_data['subcategory'].empty?

        page = WikiPage.find_by_name_or_id(name)
        if page
          if @overwrite
            unless @dry_run
              page.update(title: title)
              WikiPageVersion.create(wiki_page: page, text: content, character: Game.master.system_character)
              Website.update_tags(page, tags)
            end
            @updated += 1
          else
            @skipped += 1
          end
        else
          unless @dry_run
            page = WikiPage.create(title: title, name: name)
            WikiPageVersion.create(wiki_page: page, text: content, character: Game.master.system_character)
            Website.update_tags(page, tags)
          end
          @created += 1
        end

        if page_data['is_public'] == false
          @restricted << name
        end
      end

      def print_summary
        puts "Wiki import complete."
        puts "Created: #{@created}"
        puts "Updated: #{@updated}"
        puts "Skipped: #{@skipped}"

        if @restricted.any?
          puts ""
          puts "Pages marked non-public in export (consider adding to website.restricted_pages):"
          @restricted.each { |name| puts "  - #{name}" }
        end
      end
    end
  end
end

param = ENV['ares_rake_param']
default_path = File.expand_path(File.join(AresMUSH.game_path, '..', 'ares_export', 'wiki_data.json'))

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
  puts "Usage: bin/script import_wiki_export [/path/to/wiki_data.json] [--overwrite] [--dry-run]"
  exit 1
end

AresMUSH::Website::WikiExportImporter.new(path, overwrite: overwrite, dry_run: dry_run).run
