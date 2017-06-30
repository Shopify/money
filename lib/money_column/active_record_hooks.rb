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

              if money.currency
                currency = Money::Currency.find(read_attribute(currency_column) || Money.default_currency)
                if currency != money.currency
                  Money.deprecate("[money_column] currency mismatch between #{currency || 'nil'} and #{money.currency || 'nil'}.")
                end
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
