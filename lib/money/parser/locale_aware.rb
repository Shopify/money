# frozen_string_literal: true
class Money
  module Parser
    class LocaleAware
      @decimal_separator_resolver = ->() { ::I18n.translate("number.currency.format.separator") }

      class << self
        # The +Proc+ called to get the current locale decimal separator. Defaults to the same lookup ActionView's
        # +number_to_currency+ helper will use to format the monetary amount for display.
        def decimal_separator_resolver
          @decimal_separator_resolver
        end

        # Set the default +Proc+ to determine the current locale decimal separator.
        #
        # @example
        #   Money::Parser::LocaleAware.decimal_separator_resolver =
        #     ->() { MyFormattingLibrary.current_locale.decimal.separator }
        def decimal_separator_resolver=(proc)
          @decimal_separator_resolver = proc
        end

        # Parses an input string, normalizing some non-ASCII characters to their equivalent ASCII, then discarding any
        # character that is not a digit, hyphen-minus or the decimal separator. To prevent user confusion, make sure
        # that formatted Money strings can be parsed back into equivalent Money objects.
        #
        # @param input [String]
        # @param currency [String, Money::Currency]
        # @param strict [Boolean]
        # @param decimal_separator [String]
        # @return [Money, nil]
        def parse(input, currency, strict: false, decimal_separator: decimal_separator_resolver.call)
          raise ArgumentError, "decimal separator cannot be nil" unless decimal_separator

          currency = Money::Helpers.value_to_currency(currency)
          return unless currency

          normalized_input = input
            .tr('－０-９．，、､', '-0-9.,,,')
            .gsub(/[^\d\-#{Regexp.escape(decimal_separator)}]/, '')
            .gsub(decimal_separator, '.')
          amount = BigDecimal(normalized_input, exception: false)
          if amount
            Money.new(amount, currency)
          elsif strict
            raise ArgumentError, "unable to parse input=\"#{input}\" currency=\"#{currency}\""
          end
        end
      end
    end
  end
end
