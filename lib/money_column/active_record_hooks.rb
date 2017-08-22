module MoneyColumn
  module ActiveRecordHooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def money_column(*columns, currency_column: nil, currency: nil, currency_read_only: false)
        raise ArgumentError, 'cannot set both currency_column and a fixed currency' if currency && currency_column

        if currency
          currency = Money::Currency.find!(currency).to_s
        else
          currency_column ||= 'currency'
        end

        columns.flatten.each do |column|
          if currency_read_only || currency
            define_method column do
              return instance_variable_get("@#{column}") if instance_variable_defined?("@#{column}")
              value = read_attribute(column)
              iso = currency || read_attribute(currency_column)
              instance_variable_set("@#{column}", value ? Money.new(value, iso) : nil)
            end

            define_method "#{column}=" do |money|
              if money.nil?
                write_attribute(column, nil)
                return instance_variable_set("@#{column}",  nil)
              end

              currency_db = currency || read_attribute(currency_column)
              if currency_db != money.currency.to_s
                Money.deprecate("[money_column] currency mismatch between #{currency_db} and #{money.currency}.")
              end
              write_attribute(column, money.value)
              instance_variable_set("@#{column}",  Money.new(money.value, currency_db))
            end
          else
            composed_of(
              column.to_sym,
              class_name: 'Money',
              mapping: [[column.to_s, 'value'], [currency_column.to_s, 'currency']],
              allow_nil: true
            )
          end
        end
      end
    end
  end
end
