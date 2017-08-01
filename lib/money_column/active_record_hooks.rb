module MoneyColumn
  module ActiveRecordHooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def money_column(*columns, currency_column: :currency, currency: false)
        raise ArgumentError, 'cannot set both currency_column and a fixed currency' if currency_column && currency

        columns = columns.flatten
        if currency_column
          columns.each do |column|
            composed_of(
              column.to_sym,
              class_name: 'Money',
              mapping: [[column.to_s, 'value'], [currency_column.to_s, 'currency']]
            )
          end
        elsif currency
          columns.each do |column|
            composed_of(
              column.to_sym,
              class_name: 'Money',
              mapping: [column.to_s, 'value'],
              constructor: proc { |value| Money.new(value, currency) }
            )
          end
        else
          raise ArgumentError, 'need to set either currency_column or currency'
        end
      end
    end
  end
end
