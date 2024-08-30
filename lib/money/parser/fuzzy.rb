# frozen_string_literal: true
class Money
  module Parser
    class Fuzzy
      class MoneyFormatError < ArgumentError; end

      MARKS = %w[. , · ’ ˙ '] + [' ']

      ESCAPED_MARKS = Regexp.escape(MARKS.join)
      ESCAPED_NON_SPACE_MARKS = Regexp.escape((MARKS - [' ']).join)
      ESCAPED_NON_DOT_MARKS = Regexp.escape((MARKS - ['.']).join)
      ESCAPED_NON_COMMA_MARKS = Regexp.escape((MARKS - [',']).join)

      NUMERIC_REGEX = /(
        [\+\-]?
        [\d#{ESCAPED_NON_SPACE_MARKS}][\d#{ESCAPED_MARKS}]*
      )/ix

      # 1,234,567.89
      DOT_DECIMAL_REGEX = /\A
        [\+\-]?
        (?:
          (?:\d+)
          (?:[#{ESCAPED_NON_DOT_MARKS}]\d{3})+
          (?:\.\d{2,})?
        )
      \z/ix

      # 1.234.567,89
      COMMA_DECIMAL_REGEX = /\A
        [\+\-]?
        (?:
          (?:\d+)
          (?:[#{ESCAPED_NON_COMMA_MARKS}]\d{3})+
          (?:\,\d{2,})?
        )
      \z/ix

      # 12,34,567.89
      INDIAN_NUMERIC_REGEX = /\A
        [\+\-]?
        (?:
          (?:\d+)
          (?:\,\d{2})+
          (?:\,\d{3})
          (?:\.\d{2})?
        )
      \z/ix

      # 1,1123,4567.89
      CHINESE_NUMERIC_REGEX = /\A
        [\+\-]?
        (?:
          (?:\d+)
          (?:\,\d{4})+
          (?:\.\d{2})?
        )
      \z/ix

      def self.parse(input, currency = nil, **options)
        new.parse(input, currency, **options)
      end

      # Parses an input string and attempts to find the decimal separator based on certain heuristics, like the amount
      # decimals for the fractional part a currency has or the incorrect notion a currency has a defined decimal
      # separator (this is a property of the locale). While these heuristics can lead to the expected result for some
      # cases, the other cases can lead to surprising results such as parsed amounts being 1000x larger than intended.
      # @deprecated Use {LocaleAware.parse} or {Simple.parse} instead.
      # @param input [String]
      # @param currency [String, Money::Currency, nil]
      # @param strict [Boolean]
      # @return [Money]
      # @raise [MoneyFormatError]
      def parse(input, currency = nil, strict: false)
        currency = Money::Helpers.value_to_currency(currency)
        amount = extract_amount_from_string(input, currency, strict)
        Money.new(amount, currency)
      end

      private

      def extract_amount_from_string(input, currency, strict)
        unless input.is_a?(String)
          return input
        end

        if input.strip.empty?
          return '0'
        end

        number = input.scan(NUMERIC_REGEX).flatten.first
        number = number.to_s.strip

        if number.empty?
          if !strict
            return '0'
          else
            raise MoneyFormatError, "invalid money string: #{input}"
          end
        end

        marks = number.scan(/[#{ESCAPED_MARKS}]/).flatten
        if marks.empty?
          return number
        end

        if marks.size == 1
          return normalize_number(number, marks, currency)
        end

        # remove end of string mark
        number.sub!(/[#{ESCAPED_MARKS}]\z/, '')

        if amount = number[DOT_DECIMAL_REGEX] || number[INDIAN_NUMERIC_REGEX] || number[CHINESE_NUMERIC_REGEX]
          return amount.tr(ESCAPED_NON_DOT_MARKS, '')
        end

        if amount = number[COMMA_DECIMAL_REGEX]
          return amount.tr(ESCAPED_NON_COMMA_MARKS, '').sub(',', '.')
        end

        if strict
          raise MoneyFormatError, "invalid money string: #{input}"
        end

        normalize_number(number, marks, currency)
      end

      def normalize_number(number, marks, currency)
        digits = number.rpartition(marks.last)
        digits.first.tr!(ESCAPED_MARKS, '')

        if last_digits_decimals?(digits, marks, currency)
          "#{digits.first}.#{digits.last}"
        else
          "#{digits.first}#{digits.last}"
        end
      end

      def last_digits_decimals?(digits, marks, currency)
        # Grouping marks are always different from decimal marks
        # Example: 1,234,456
        *other_marks, last_mark = marks
        other_marks.uniq!
        if other_marks.size == 1
          return other_marks.first != last_mark
        end

        # Thousands always have more than 2 digits
        # Example: 1,23 must be 1 dollar and 23 cents
        if digits.last.size < 3
          return !digits.last.empty?
        end

        # 0 before the final mark indicates last digits are decimals
        # Example: 0,23
        if digits.first.to_i.zero?
          return true
        end

        # The last mark matches the one used by the provided currency to delimiter decimals
        currency.decimal_mark == last_mark
      end
    end
  end
end
