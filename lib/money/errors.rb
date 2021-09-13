# frozen_string_literal: true
class Money
  class Error < StandardError
  end

  class IncompatibleCurrencyError < Error
  end

  class ParserError < Error
  end
end
