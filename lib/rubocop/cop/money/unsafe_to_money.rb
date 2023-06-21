
module RuboCop
  module Cop
    module Money
      # Prevents the use of `to_money` because it has inconsistent behaviour.
      # Use `Money.new` instead.
      #
      # @example
      #  # bad
      #  "2.000".to_money("USD")     #<Money value:2000.00 currency:USD>
      #
      #  # good
      #  Money.new("2.000", "USD")   #<Money value:2.00 currency:USD>
      class UnsafeToMoney < Cop
        MSG = '`to_money` has inconsistent behaviour. Use `Money.new` instead.'.freeze

        def on_send(node)
          return unless node.method?(:to_money)
          return if node.receiver.nil? || node.receiver.is_a?(AST::NumericNode)

          add_offense(node, location: :selector)
        end

        def autocorrect(node)
          lambda do |corrector|
            receiver = node.receiver.source
            args = node.arguments.map(&:source)
            args.prepend(receiver)
            corrector.replace(node.loc.expression, "Money.new(#{args.join(', ')})")
          end
        end
      end
    end
  end
end
