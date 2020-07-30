module I18n
  module HTMLExtractor
    module Match
      class InterpolatedPlainTextMatch < PlainTextMatch
        INTERPOLABLE_DIRECTIVE_MATCH = /@@=(?<inner>.*?)@@/

        def self.create(document, node)
          return nil if node.name.start_with?('script')
          return nil if node.text.match(/!@!=/)
          return [InterpolatedPlainTextMatch.new(document, node)] if node.text.match(INTERPOLABLE_DIRECTIVE_MATCH)
          return nil
        end

        def initialize(document, node)
          text = parameterise_string document, node.text
          node.content = text
          # When we call new here to create a Match, we need to pass the whole text that key will translate to.
          # That will include the interpolations, e.g. %{current_user_name}
          super document, node, text
        end

        # handle the individual case first, then we can handle the multiple case
        def parameterise_string(document, text)
          match = text.match(INTERPOLABLE_DIRECTIVE_MATCH)

          @directives = {}
          directive = document.erb_directives.delete(match[:inner])
          key = make_key_from directive
          @directives[key] = directive
          text.gsub! match.to_s, "%{#{key}}"

          text.strip
        end

        def translation_key_object
          t = "t(\".#{key}\""

          @directives.each do |key, value|
            t << ", #{key}: #{value}"
          end

          t << ")"

          t
        end
      end
    end
  end
end

