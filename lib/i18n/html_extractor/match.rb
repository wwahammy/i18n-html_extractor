require 'i18n/html_extractor/match/node_match'
require 'i18n/html_extractor/match/base_match'
require 'i18n/html_extractor/match/erb_directive_match'
require 'i18n/html_extractor/match/link_match'
require 'i18n/html_extractor/match/placeholder_match'
require 'i18n/html_extractor/match/plain_text_match'

module I18n
  module HTMLExtractor
    module Match
      class Finder
        attr_reader :document

        def initialize(document)
          @document = document
        end

        def matches
          [:link_nodes, :erb_nodes, :plain_text_nodes, :form_fields].map do |method_to_call|
            Thread.new { send(method_to_call, document) }
          end.map(&:value).flatten
        end

        private

        def link_nodes(document)
          leaf_nodes(document).map! { |node| LinkMatch.create(document, node) }.flatten.compact
        end

        def erb_nodes(document)
          document.erb_directives.map do |fragment_id, _|
            ErbDirectiveMatch.create(document, fragment_id)
          end.flatten.compact
        end

        def plain_text_nodes(document)
          leaf_nodes(document).map! { |node| PlainTextMatch.create(document, node) }.flatten.compact
        end

        def form_fields(document)
          document.css('textarea[placeholder],input[placeholder]').select { |input| input['placeholder'].present? }
                  .reject { |n| n['placeholder'] =~ /\@\@(=?)[a-z0-9\-]+\@\@/ }
                  .map! do |node|
            PlaceholderMatch.create(document, node)
          end.flatten.compact
        end

        def leaf_nodes(document)
          document.css('*:not(:has(*))').select { |n| n.text.present? }
        end
      end
    end
  end
end
