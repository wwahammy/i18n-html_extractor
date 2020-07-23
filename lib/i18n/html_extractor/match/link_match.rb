require 'parser/current'

module I18n
  module HTMLExtractor
    module Match
      class LinkMatch < BaseMatch
        ORIGINAL_LINK_REGEXPS = [
            [/^([ \t]*link_to )(("[^"]+")|('[^']+'))/, '\1%s', 2],
            [/^([ \t]*link_to (.*),[ ]?title:[ ]?)(("[^"]+")|('[^']+'))/, '\1%s', 3],
        ].freeze

        REGEXPS = [
            [/(?<before>.*)!@!=link_to (?<link_name>.*?)(,\s*(?<extras>.*))?!@!(?<after>.*)/m]
        ].freeze

        REGEXP_INNER = /(?<before>.*)!@!=(?<inner>.*?)!@!(?<after>.*)/m

        attr_accessor :regexp
        attr_accessor :original_link_name
        attr_accessor :link_name
        attr_accessor :extras

        def self.create_link(document, node, type)
          REGEXPS.map do |r|
            regexp = r[0]
            match = node.text.match(regexp)

            if match.nil?
              nil
            else
              puts "matched: #{node.text}"
              type.new document, node, match.named_captures.symbolize_keys, regexp
            end
          end
        end

        def self.create(document, node)
          match = node.text.match REGEXP_INNER

          return [nil] if match.nil? # we probs want to return nil rather than an array of nil, this is just to pass current tests

          inner = match.named_captures["inner"]
          parsed = Parser::CurrentRuby.parse inner
          _, value, arg = parsed.to_a

          # ignore if we're not a method or variable
          return [nil] unless parsed.type == :send
          if value == :link_to
            puts parsed
            if arg.type == :send
              _, name_value = arg.to_a
              if ignore? name_value
                replace_node_text! document, node, /!@!.*!@!/, inner
                return [nil]
              else
                create_link document, node, PlainLinkMatch
              end
            else
              create_link document, node, LinkMatch
            end
          elsif ignore? value
            return [nil] # is this what we want to do here
          else
            return [nil]
          end
        end

        def self.ignore?(value)
          value == :t || value == :translate || value == :it
        end

        def initialize(document, node, matches, regexp)
          @regexp = regexp
          text = parameterise_string(matches)
          # When we call new here to create a Match, we need to pass the whole text that key will translate to.
          # That will include the interpolations, e.g. %{link:My cool link}
          super document, node, text
        end

        def parameterise_string(matches)
          @original_link_name = matches[:link_name]
          @link_name = make_key_from original_link_name
          @extras = matches[:extras]

          @key = make_key_from "#{matches[:before]} #{original_link_name} #{matches[:after]}"

          "#{matches[:before]}%{#{@link_name}:#{original_link_name}}#{matches[:after]}".strip
        end

        def translation_key_object
          # Because the key adder doesn't know about `it`, we have to remove the i
          # The !i! will get replaced with a regular i after we add the key, returning the method to `it`
          "!i!t(\".#{key}\", #{link_name}: It.link(#{extras}))"
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
        def parameterise_string(matches)
          super matches
          "#{matches[:before]}%{#{link_name}}#{matches[:after]}".strip
        end

        def translation_key_object
          link_params = original_link_name
          link_params = "#{link_params}, #{extras}" if extras.present?
          "raw t(\".#{key}\", #{link_name}: link_to(#{link_params}))"
        end
      end
    end
  end
end

