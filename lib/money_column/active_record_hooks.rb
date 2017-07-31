module MoneyColumn
  module ActiveRecordHooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def money_column(*columns, currency: :currency)
        columns = columns.flatten

        if currency.is_a?(Symbol)
          columns.each do |column|
            composed_of(
              column.to_sym,
              class_name: 'Money',
              mapping: [[column.to_s, 'value'], [currency.to_s, 'currency']]
            )
          end
        else
          columns.each do |column|
            composed_of(
              column.to_sym,
              class_name: 'Money',
              mapping: [column.to_s, 'value'],
              constructor: proc { |value| Money.new(value, currency) }
            )
          end
        end
      end
    end
  end
end
