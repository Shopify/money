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
              currency = Money::Helpers.value_to_currency(read_attribute(currency_column))

              unless currency.compatible?(money.currency)
                Money.deprecate("[money_column] currency mismatch between #{currency} and #{money.currency}.")
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
