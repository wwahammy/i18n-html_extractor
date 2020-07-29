require 'nokogiri'

module I18n
  module HTMLExtractor
    class ErbDocument
      INLINE_ERB_REGEXPS = [
        I18n::HTMLExtractor::TwoWayRegexp.new(/<%= link_to (?<inner_text>.+?) %>/m, /!@!=link_to (?<inner_text>.+)!@!/m)
      ].freeze

      ERB_REGEXPS = [
        I18n::HTMLExtractor::TwoWayRegexp.new(/<%= (?<inner_text>.+?) %>/m, /@@=(?<inner_text>[a-z0-9\-]+)@@/m),
        I18n::HTMLExtractor::TwoWayRegexp.new(/<% #(?<inner_text>.+?) %>/m, /@@#(?<inner_text>[a-z0-9\-]+)@@/m),
        I18n::HTMLExtractor::TwoWayRegexp.new(/<%#(?<inner_text>.+?) %>/m, /@@#(?<inner_text>[a-z0-9\-]+)@@/m),
        I18n::HTMLExtractor::TwoWayRegexp.new(/<%- (?<inner_text>.+?) %>/m, /@@-(?<inner_text>[a-z0-9\-]+)@@/m),
        I18n::HTMLExtractor::TwoWayRegexp.new(/<% (?<inner_text>.+?) %>/m, /@@(?<inner_text>[a-z0-9\-]+)@@/m)
      ].freeze

      attr_reader :erb_directives
      def initialize(document, erb_directives)
        @document = document
        @erb_directives = erb_directives
      end

      def save!(filename)
        File.open(filename, 'w') do |f|
          result = @document.to_html(indent: 2, encoding: 'UTF-8')
          ERB_REGEXPS.each do |regexp|
            regexp.inverse_replace!(result) do |string_format, data|
              string_format % { inner_text: erb_directives[data[:inner_text]] }
            end
          end

          # deal with any leftover inline links, i.e. ones not in blocks
          INLINE_ERB_REGEXPS.each do |regexp|
            regexp.inverse_replace!(result) do |string_format, data|
              string_format % { inner_text: data[:inner_text] }
            end
          end
          f.write result
        end
      end

      def replace_its!(filename)
        IO.write(filename, File.open(filename) do |f|
            f.read.gsub(/!i!/, "i")
          end
        )
      end

      def method_missing(name, *args, &block)
        @document.public_send(name, *args, &block) if @document.respond_to? name
      end

      class <<self
        def parse(filename, verbose: false)
          file_content = ''
          File.open(filename) do |file|
            file.read(nil, file_content)
            return parse_string(file_content, verbose: verbose)
          end
        end

        def parse_string(string, verbose: false)
          extract_inline_erb_directives! INLINE_ERB_REGEXPS, string
          erb_directives = extract_erb_directives! ERB_REGEXPS, string
          document = create_document(string)
          log_errors(document.errors, string) if verbose
          ErbDocument.new(document, erb_directives)
        end

        private

        def create_document(file_content)
          if file_content.start_with?('<!DOCTYPE')
            Nokogiri::HTML(file_content)
          else
            Nokogiri::HTML.fragment(file_content)
          end
        end

        def log_errors(errors, file_content)
          return if errors.empty?
          text = file_content.split("\n")
          errors.each do |e|
            puts "Error at line #{e.line}: #{e}".red
            puts text[e.line - 1]
          end
        end

        def extract_inline_erb_directives!(regexps, text)
          regexps.each do |regexp|
            regexp.replace!(text) do |string_format, data|
              string_format % { inner_text: data[:inner_text] }
            end
          end
        end

        def extract_erb_directives!(regexps, text)
          erb_directives = {}

          regexps.each do |regexp|
            regexp.replace!(text) do |string_format, data|
              key = SecureRandom.uuid
              erb_directives[key] = data[:inner_text]
              string_format % { inner_text: key }
            end
          end
          erb_directives
        end
      end
    end
  end
end
