# frozen_string_literal: true

class Money
  module Rails
    class JobArgumentSerializer < ::ActiveJob::Serializers::ObjectSerializer
      def serialize(money)
        attributes = { "value" => money.value.to_s("F"), "currency" => money.currency.iso_code }
        attributes["decimal_precision"] = money.decimal_precision if money.explicit_decimal_precision?
        super(attributes)
      end

      def deserialize(hash)
        Money.new(hash["value"], hash["currency"], decimal_precision: hash["decimal_precision"])
      end

      def klass
        Money
      end
    end
  end
end
