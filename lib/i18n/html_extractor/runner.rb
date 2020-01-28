module I18n
  module HTMLExtractor
    class Runner
      EXCLUDED_KEYS = ['', 'x', 'nbsp', '&times;'].freeze

      def initialize(args = {})
        @files = file_list_from_pattern(args[:file_pattern])
      end

      def run
        @files.lazy.each do |file|
          document = I18n::HTMLExtractor::ErbDocument.parse file
          nodes_to_translate(document).each do |node|
            puts "Found \"#{node.text}\" in #{file}:#{node.text}".green

            unless skip_node?(node)
              node.replace_text!
              document.save!(file)
              add_translation! I18n.default_locale, node.key, node.text
            end
          end

        end
      end

      private

      def skip_node?(node)
        EXCLUDED_KEYS.include?(node.key)
      end

      def file_list_from_pattern(pattern)
        if pattern.present?
          Dir[Rails.root.join(pattern)]
        else
          Dir[Rails.root.join('app', 'views', '**', '*.erb')]
        end
      end

      def add_translation!(locale, key, value)
        new_keys = i18n.missing_keys(locales: [locale]).set_each_value!(value)
        i18n.data.merge! new_keys
        puts "Added t(.'#{key}'), translated in #{locale} as #{value}:".green
        puts new_keys.inspect
      end

      def i18n
        I18n::Tasks::BaseTask.new
      end

      def nodes_to_translate(document)
        Match::Finder.new(document).matches
      end
    end
  end
end
