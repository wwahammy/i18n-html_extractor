module I18n
  module HTMLExtractor
    module Match
      class NodeMatch
        attr_reader :document, :text

        def initialize(document, text)
          @document = document
          @text = text
        end

        def translation_key_object
          "t(\".#{key}\")"
        end

        def replace_text!
          raise NotImplementedError
        end

        attr_writer :key

        def key
          @key ||= make_key_from(text)
        end

        def make_key_from(string)
          string.parameterize.underscore.slice(0..39)
        end
      end
    end
  end
end
