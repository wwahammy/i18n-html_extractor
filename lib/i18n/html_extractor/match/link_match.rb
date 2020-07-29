require 'parser/current'

module I18n
  module HTMLExtractor
    module Match
      class LinkMatch < BaseMatch

        REGEXP = /(?<before>.*)!@!=link_to (?<link_name>.*?)(,\s*(?<extras>.*))?!@!(?<after>.*)/m

        REGEXP_INNER = /(?<before>.*)!@!=(?<inner>.*?)!@!(?<after>.*)/m

        attr_accessor :regexp
        attr_accessor :key
        attr_accessor :links
        attr_accessor :raw

        def self.create(document, node)
          # ignore if we're not a link
          is_link, inner, arg = is_link? node.text
          return [nil] unless is_link

          link = [nil]

          if arg.type == :send
            _, name_value = arg.to_a
            if ignore? name_value
              replace_node_text! document, node, /!@!.*!@!/, inner
            else
              link = create_link document, node, PlainLinkMatch
            end
          else
            link = create_link document, node, LinkMatch
          end

          link
        end

        def self.is_link?(text)
          match = text.match REGEXP_INNER
          return false if match.nil?

          inner = match.named_captures["inner"]
          parsed = Parser::CurrentRuby.parse inner
          _, value, arg = parsed.to_a

          return (parsed&.type == :send && value == :link_to), inner, arg
        end

        def self.ignore?(value)
          value == :t || value == :translate || value == :it
        end

        def self.create_link(document, node, type)
          match = find_match node.text
          return [ nil ] if match.nil?

          content = match_to_a match

          # check to see if we have more
          while (before = find_match match[:before]).present?
            content = match_to_a(before).concat(content)
            match = before
          end

          [ type.new(document, node, content, REGEXP) ]
        end

        def self.find_match(text)
          match = text.match(REGEXP)
          return nil if match.nil?
          puts "matched: #{text}"
          captures = match.named_captures.symbolize_keys
          is_link, _, arg = is_link? text
          captures[:it_link] = is_link && arg.type != :send
          captures
        end

        def self.match_to_a(match)
          [ match[:before], { name: match[:link_name].gsub(/["']/, ""), extras: match[:extras], it_link: match[:it_link] }, match[:after] ]
        end

        def initialize(document, node, content, regexp)
          @regexp = regexp
          text = parameterise_string(content)
          # When we call new here to create a Match, we need to pass the whole text that key will translate to.
          # That will include the interpolations, e.g. %{link:My cool link}
          super document, node, text
        end

        def parameterise_string(content)
          @links = []
          @key = ""
          parameterised = ""
          content.each do |c|
            if c.is_a? String
              @key << "#{c} "
              parameterised << c
            else
              @key << c[:name]
              link_name_key = make_key_from c[:name]
              parameterised << "%{#{link_name_key}:#{c[:name]}}"
              c[:name_key] = link_name_key
              @links << c
              @raw = @raw || !c[:it_link]
            end
          end

          @key = make_key_from @key

          parameterised
        end

        def translation_key_object
          # Because the key adder doesn't know about `it`, we have to remove the i
          # The !i! will get replaced with a regular i after we add the key, returning the method to `it`
          t = "!i!t(\".#{key}\""
          t = "raw " << t if raw
          links.each do |link|
            if link[:it_link]
              t << ", #{link[:name_key]}: It.link(#{link[:extras]})"
            else
              t << ", #{link[:name_key]}: link_to(#{link[:name]}, #{link[:extras]})"
            end
          end
          t << ")"
        end

        def self.replace_node_text!(document, node, regexp, inner)
          key = SecureRandom.uuid
          document.erb_directives[key] = inner
          node.content = node.content.gsub(regexp, "@@=#{key}@@") # This will be replaced with <%= inner => at the end when saving the file
        end

        def replace_text!
          LinkMatch.replace_node_text! document, node, regexp, translation_key_object
        end
      end

      class PlainLinkMatch < LinkMatch
        def parameterise_string(content)
          super content
          "#{content.first}%{#{content.second[:name_key]}}#{content.third}".strip
        end

        def translation_key_object
          link_params = links.first[:name]
          link_params = "#{link_params}, #{links.first[:extras]}" if links.first[:extras].present?
          "raw t(\".#{key}\", #{links.first[:name_key]}: link_to(#{link_params}))"
        end
      end
    end
  end
end

