module AresMUSH
  module Website
    module GlossaryHelper
      
      # Constants
      GLOSSARY_BUTTON_TAG = '<button type="button" class="glossary-term"'
      GLOSSARY_BUTTON_CLOSE_TAG = '</button>'
      
      # Main method: applies glossary highlighting to HTML content
      # Returns modified HTML with glossary buttons
      def self.apply_glossary(html_content)
        return html_content if html_content.nil? || html_content.empty?
        
        terms = load_glossary_terms
        return html_content if terms.empty?
        
        # Track which terms we've already replaced (one per term per document)
        replaced_term_keys = Set.new
        result = html_content.dup
        
        terms.each do |entry|
          all_terms = entry[:terms]
          first_match = nil
          
          # Try to match any of the terms
          all_terms.each do |search_term|
            # Skip if we've already replaced this specific term
            term_key = normalize_term_key(search_term, entry[:case_sensitive])
            next if replaced_term_keys.include?(term_key)
            
            # Build the pattern for this term
            pattern = Regexp.escape(search_term)
            flags = entry[:case_sensitive] ? 0 : Regexp::IGNORECASE
            
            # Only match whole words using word boundaries
            regex = Regexp.new("\\b#{pattern}\\b", flags)
            
            # Find all matches
            result.to_enum(:scan, regex).each do |m|
              match_pos = Regexp.last_match.begin(0)
              match_end = Regexp.last_match.end(0)
              matched_text = Regexp.last_match[0]
              
              # Skip matches inside HTML tags
              next if inside_html_tag?(result, match_pos)
              
              # Skip matches inside existing glossary buttons
              next if inside_glossary_button?(result, match_pos)
              
              # Keep the earliest match, or longest if at same position
              if first_match.nil? || 
                 match_pos < first_match[:pos] ||
                 (match_pos == first_match[:pos] && matched_text.length > first_match[:text].length)
                first_match = {
                  pos: match_pos,
                  end_pos: match_end,
                  text: matched_text
                }
              end
            end
          end
          
          # If we found a match, replace it
          if first_match
            replacement = create_glossary_button(first_match[:text], entry)
            result = result[0...first_match[:pos]] + replacement + result[first_match[:end_pos]..-1]
            
            # Mark all aliases of this term as replaced
            all_terms.each do |term_value|
              replaced_term_keys.add(normalize_term_key(term_value, entry[:case_sensitive]))
            end
          end
        end
        
        result
      end
      
      private
      
      # Load glossary terms from config
      def self.load_glossary_terms
        config = Global.read_config('glossary', 'terms') || []
        
        terms = config.select { |t| t['is_active'] != false }
                      .map { |t| process_term_entry(t) }
                      .compact  # Remove nil entries from invalid terms
                      .sort_by { |t| [-t[:priority], -t[:term_length]] }
        
        terms
      end
      
      # Process a single term entry from config
      def self.process_term_entry(term_config)
        primary_term = term_config['term']
        
        # Validate primary term exists
        if primary_term.nil? || primary_term.to_s.strip.empty?
          Global.logger.warn "Glossary term with missing or empty 'term' field, skipping"
          return nil
        end
        
        aliases = term_config['aliases'] || []
        all_terms = [primary_term] + aliases
        
        {
          terms: all_terms,
          title: primary_term,
          description: term_config['description'] || '',
          link_url: term_config['link_url'] || '',
          link_text: term_config['link_text'] || 'Learn more',
          case_sensitive: term_config['case_sensitive'] || false,
          priority: term_config['priority'] || 0,
          term_length: primary_term.length
        }
      end
      
      # Normalize term text for deduplication
      def self.normalize_term_key(term_text, case_sensitive)
        case_sensitive ? term_text : term_text.downcase
      end
      
      # Check if a position is inside an HTML tag
      def self.inside_html_tag?(text, pos)
        text_before = text[0...pos]
        last_open = text_before.rindex('<') || -1
        last_close = text_before.rindex('>') || -1
        last_open > last_close
      end
      
      # Check if a position is inside an existing glossary button
      def self.inside_glossary_button?(text, pos)
        # Look backwards for glossary button start
        text_before = text[0...pos]
        last_button = text_before.rindex(GLOSSARY_BUTTON_TAG)
        return false if last_button.nil?
        
        # Find where the button tag ends
        button_tag_end = text.index('>', last_button)
        return false if button_tag_end.nil? || button_tag_end >= pos
        
        # Check if we're before the closing </button>
        button_close = text.index(GLOSSARY_BUTTON_CLOSE_TAG, button_tag_end)
        button_close.nil? || pos < button_close
      end
      
      # Generate the HTML button with data attributes
      def self.create_glossary_button(matched_text, entry)
        unique_id = SecureRandom.hex(8)
        trigger_id = "glossary-trigger-#{unique_id}"
        popover_id = "glossary-popover-#{unique_id}"
        
        # Escape HTML in attributes
        matched_escaped = CGI.escapeHTML(matched_text)
        title_escaped = CGI.escapeHTML(entry[:title])
        description_escaped = CGI.escapeHTML(entry[:description])
        
        data_attrs = {
          'data-glossary-term' => matched_escaped,
          'data-glossary-title' => title_escaped,
          'data-glossary-desc' => description_escaped,
          'data-glossary-popover-id' => popover_id
        }
        
        if !entry[:link_url].empty?
          data_attrs['data-glossary-url'] = CGI.escapeHTML(entry[:link_url])
          data_attrs['data-glossary-link-text'] = CGI.escapeHTML(entry[:link_text])
        end
        
        data_attr_string = data_attrs.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
        
        "<button type=\"button\" class=\"glossary-term\" id=\"#{trigger_id}\" " +
        "aria-haspopup=\"dialog\" aria-expanded=\"false\" aria-controls=\"#{popover_id}\" " +
        "#{data_attr_string}>#{CGI.escapeHTML(matched_text)}</button>"
      end
      
    end
  end
end
