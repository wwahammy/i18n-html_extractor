module I18n
  module HTMLExtractor
    module Match
      class LinkMatch < BaseMatch
        ORIGINAL_LINK_REGEXPS = [
            [/^([ \t]*link_to )(("[^"]+")|('[^']+'))/, '\1%s', 2],
            [/^([ \t]*link_to (.*),[ ]?title:[ ]?)(("[^"]+")|('[^']+'))/, '\1%s', 3],
        ].freeze

        REGEXPS = [
            [/(?<before>.*)!@!(?<link_name>.*?),\s*(?<extras>.*)!@!(?<after>.*)/]
        ]

        attr_accessor :link_name
        attr_accessor :extras

        def self.create(document, node)
          REGEXPS.map do |r|
            match = node.text.match(r[0])

            if match.nil?
              nil
            else
              puts "matched: #{node.text}"
              new document, node, match.named_captures.symbolize_keys
            end
          end
        end

        def initialize(document, node, matches)
          text = parameterise_string(matches)
          # When we call new here to create a Match, we need to pass the whole text that key will translate to.
          # That will include the interpolations, e.g. %{link:My cool link}
          super document, node, text
        end

        def parameterise_string(matches)
          @link_name = make_key_from matches[:link_name]
          @extras = matches[:extras]

          @key = make_key_from "#{matches[:before]} #{matches[:link_name]} #{matches[:after]}"

          "#{matches[:before]}%{#{@link_name}:#{matches[:link_name]}}#{matches[:after]}"
        end


        def translation_key_object
          "it(\".#{key}\", #{link_name}: It.link(#{extras}))"
        end

        def replace_text!
          key = SecureRandom.uuid
          document.erb_directives[key] = translation_key_object
          node.content = node.content.gsub(text, "@@=#{key}@@") # This will be replaced with <%= translation_key_object => at the end when saving the file
        end
      end
    end
  end
end

