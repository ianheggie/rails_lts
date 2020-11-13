module MissingSourceFileSupport
  module IsMissing
    def is_missing?(path)
      path.gsub(/\.rb$/, '') == self.path.gsub(/\.rb$/, '')
    end
  end

  module Regexps
    REGEXPS = [
      [/^cannot load such file -- (.+)$/i, 1],
      [/^no such file to load -- (.+)$/i, 1],
      [/^Missing \w+ (file\s*)?([^\s]+.rb)$/i, 2],
      [/^Missing API definition file in (.+)$/i, 1]
    ]
  end
end

if RUBY_VERSION < '2.6'

  class MissingSourceFile < LoadError #:nodoc:
    include MissingSourceFileSupport::IsMissing
    include MissingSourceFileSupport::Regexps unless defined?(REGEXPS)

    attr_reader :path
    def initialize(message, path)
      super(message)
      @path = path
    end

    def self.from_message(message)
      REGEXPS.each do |regexp, capture|
        match = regexp.match(message)
        return MissingSourceFile.new(message, match[capture]) unless match.nil?
      end
      nil
    end
  end

  module ActiveSupport #:nodoc:
    module CoreExtensions #:nodoc:
      module LoadErrorExtensions #:nodoc:
        module LoadErrorClassMethods #:nodoc:
          def new(*args)
            (self == LoadError && MissingSourceFile.from_message(args.first)) || super
          end
        end
        ::LoadError.extend(LoadErrorClassMethods)
      end
    end
  end

else

  class LoadError
    module PathFromMessage
      def path
        super || path_from_message
      end

      private

      def path_from_message
        LoadError::REGEXPS.each do |regexp, capture|
          match = regexp.match(message)
          return match[capture] if match
        end
        nil # no match
      end
    end

    prepend PathFromMessage
    include MissingSourceFileSupport::IsMissing
    include MissingSourceFileSupport::Regexps unless defined?(REGEXPS)
  end

  MissingSourceFile = LoadError

end
