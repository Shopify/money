# frozen_string_literal: true

module RuboCop
  module Cop
    module Money
      class ZeroMoney < Cop
        # `Money.zero` and it's alias `empty`, with or without currency
        # argument is removed in favour of the more explicit Money.new
        # syntax. Supplying it with a real currency is preferred for
        # additional currency safety checks.
        #
        # If no currency was supplied, it defaults to
        # Money::NULL_CURRENCY which was the default setting of
        # Money.default_currency and should effectively be the same. The cop
        # can be configured with a ReplacementCurrency in case that is more
        # appropriate for your application.
        #
        # @example
        #
        #   # bad
        #   Money.zero
        #
        #   # good when configured with `ReplacementCurrency: CAD`
        #   Money.new(0, 'CAD')
        #

        MSG = 'Money.zero is removed, use `Money.new(0, %<currency>s)`.'

        def_node_matcher :money_zero, <<~PATTERN
          (send (const {nil? cbase} :Money) {:zero :empty} $...)
        PATTERN

        def on_send(node)
          money_zero(node) do |currency_arg|
            add_offense(node, message: format(MSG, currency: replacement_currency(currency_arg)))
          end
        end

        def autocorrect(node)
          receiver, _ = *node

          lambda do |corrector|
            money_zero(node) do |currency_arg|
              replacement_currency = replacement_currency(currency_arg)

              corrector.replace(
                node.loc.expression,
                "#{receiver.source}.new(0, #{replacement_currency})",
              )
            end
          end
        end

        private

        def replacement_currency(currency_arg)
          return currency_arg.first.source unless currency_arg.empty?
          return "'#{cop_config["ReplacementCurrency"]}'" if cop_config['ReplacementCurrency']

          'Money::NULL_CURRENCY'
        end
      end
    end
  end
end
