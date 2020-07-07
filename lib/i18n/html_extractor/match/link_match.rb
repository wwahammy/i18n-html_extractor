module I18n
  module HTMLExtractor
    module Match
      class LinkMatch < ErbDirectiveMatch
        REGEXPS = [
            [/^([ \t]*link_to )(("[^"]+")|('[^']+'))/, '\1%s', 2],
            [/^([ \t]*link_to (.*),[ ]?title:[ ]?)(("[^"]+")|('[^']+'))/, '\1%s', 3],
        ].freeze

        def self.regex
          REGEXPS
        end
      end
    end
  end
end

