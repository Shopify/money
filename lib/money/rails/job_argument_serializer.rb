# frozen_string_literal: true

class Money
  module Rails
    class JobArgumentSerializer < ::ActiveJob::Serializers::ObjectSerializer
      def serialize(money)
        super("value" => money.value.to_s, "currency" => money.currency.iso_code)
      end

      def deserialize(hash)
        Money.new(hash["value"], hash["currency"])
      end

      private

      def klass
        Money
      end
    end
  end
end

