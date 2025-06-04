# frozen_string_literal: true

class Money
  module Converters
    class << self
      def subunit_converters
        @subunit_converters ||= {}
      end

      def register(key, klass)
        subunit_converters[key.to_sym] = klass
      end

      def for(format)
        format ||= Money::Config.current.default_subunit_format

        if (klass = subunit_converters[format.to_sym])
          klass.new
        else
          raise(ArgumentError, "unknown format: '#{format}'")
        end
      end
    end
  end
end
