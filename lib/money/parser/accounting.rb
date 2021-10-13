# frozen_string_literal: true
class Money
  module Parser
    class Accounting < Fuzzy
      def parse(input, currency = nil, **options)
        # set () to mean negativity. ignore $
        super(input.gsub(/\(\$?(.*?)\)/, '-\1'), currency, **options)
      end
    end
  end
end
