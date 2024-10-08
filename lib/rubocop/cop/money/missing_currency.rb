# frozen_string_literal: true

module RuboCop
  module Cop
    module Money
      class MissingCurrency < Cop
        # `Money.new()` without a currency argument cannot guarantee correctness:
        # - no error raised for cross-currency computation (e.g. 5 CAD + 5 USD)
        # - #subunits returns wrong values for 0 and 3 decimals currencies
        #
        # @example
        #   # bad
        #   Money.new(123.45)
        #   Money.new
        #   "1,234.50".to_money
        #
        #   # good
        #   Money.new(123.45, 'CAD')
        #   "1,234.50".to_money('CAD')
        #

        def_node_matcher :money_new, <<~PATTERN
          (send (const {nil? cbase} :Money) {:new :from_amount :from_cents} $...)
        PATTERN

        def_node_matcher :to_money_without_currency?, <<~PATTERN
          ({send csend} _ :to_money)
        PATTERN

        def_node_matcher :to_money_block?, <<~PATTERN
          (send _ _ (block_pass (sym :to_money)))
        PATTERN

        def on_send(node)
          money_new(node) do |amount, currency_arg|
            return if amount&.splat_type?
            return if currency_arg

            add_offense(node, message: 'Money is missing currency argument')
          end

          if to_money_block?(node) || to_money_without_currency?(node)
            add_offense(node, message: 'to_money is missing currency argument')
          end
        end
        alias_method :on_csend, :on_send

        def autocorrect(node)
          receiver, method, _ = *node

          lambda do |corrector|
            money_new(node) do |amount, currency_arg|
              return if currency_arg

              corrector.replace(
                node.loc.expression,
                "#{receiver.source}.#{method}(#{amount&.source || 0}, #{replacement_currency})",
              )
            end

            if to_money_without_currency?(node)
              corrector.insert_after(node.loc.expression, "(#{replacement_currency})")
            elsif to_money_block?(node)
              corrector.replace(
                node.loc.expression,
                "#{receiver.source}.#{method} { |x| x.to_money(#{replacement_currency}) }",
              )
            end
          end
        end

        private

        def replacement_currency
          if cop_config['ReplacementCurrency']
            "'#{cop_config["ReplacementCurrency"]}'"
          else
            'Money::NULL_CURRENCY'
          end
        end
      end
    end
  end
end
