module I18n
  module HTMLExtractor
    module Match
      class PlainTextMatch < BaseMatch
        INTERPOLABLE_DIRECTIVE_MATCH = /@@=(?<inner>.*?)@@/
        NON_INTERPOLABLE_DIRECTIVE_MATCH = /@@[a-z0-9\-]+@@/

        def self.create(document, node)
          return nil if node.name.start_with?('script')
          return nil if node.text.match(/!@!=/)
          # If we can interpolate, do so
          return [InterpolatedPlainTextMatch.new(document, node)] if node.text.match(INTERPOLABLE_DIRECTIVE_MATCH)
          node.text.split(NON_INTERPOLABLE_DIRECTIVE_MATCH).map! do |text|
            new(document, node, text.strip) unless text.blank?
          end
        end

        def replace_text!
          key = SecureRandom.uuid
          document.erb_directives[key] = translation_key_object
          node.content = node.content.gsub(text, "@@=#{key}@@")
        end
      end

      class InterpolatedPlainTextMatch < PlainTextMatch
        def initialize(document, node)
          text = parameterise_string document, node.text
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

          text
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
