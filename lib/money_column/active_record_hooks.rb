module MoneyColumn
  module ActiveRecordHooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def money_column(*columns, currency_column: 'currency')
        Array(columns).flatten.each do |name|
          define_method(name) do
            value = read_attribute(name)
            return nil if value.blank?
            currency = read_attribute(currency_column)
            Money.new(value, currency)
          end

          define_method("#{name}_before_type_cast") do
            send(name) && sprintf("%.2f", send(name))
          end

          define_method("#{name}=") do |value|
            if value.blank? || !value.respond_to?(:to_money)
              write_attribute(name, nil)
              nil
            else
              money = value.to_money
              currency = read_attribute(currency_column)

              if money.currency && Currency.find(currency) != money.currency
                Money.deprecate("currency mismatch between #{currency || 'nil'} and #{money.currency || 'nil'}.")
              end

              write_attribute(name, money.value)
              money
            end
          end
        end
      end
    end
  end
end
