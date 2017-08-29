module MoneyColumn
  module ActiveRecordHooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    def reload(*)
      clear_money_column_cache
      super
    end

    def initialize_dup(*)
      @money_column_cache = {}
      super
    end

    private

    def clear_money_column_cache
      @money_column_cache.clear if persisted?
    end

    def init_internals
      @money_column_cache = {}
      super
    end

    module ClassMethods
      def money_column(*columns, currency_column: nil, currency: nil)
        raise ArgumentError, 'cannot set both currency_column and a fixed currency' if currency && currency_column
        raise ArgumentError, 'must set one of :currency_column or :currency options' unless currency || currency_column

        if currency
          currency_object = Money::Currency.find!(currency).to_s
        else
          define_method "#{currency_column}=" do |value|
            @money_column_cache.clear
            super(value)
          end
        end

        columns.flatten.each do |column|
          money_column_reader(column, currency_column, currency_object)
          money_column_writer(column, currency_column, currency_object)
        end
      end

      private

      def money_column_reader(column, currency_column, currency_object)
        define_method column do
          return @money_column_cache[column] if @money_column_cache[column]
          return unless value = read_attribute(column)
          iso = currency_object || try(currency_column)
          @money_column_cache[column] = Money.new(value, iso)
        end
      end

      def money_column_writer(column, currency_column, currency_object)
        define_method "#{column}=" do |money|
          if money.blank?
            write_attribute(column, nil)
            return @money_column_cache[column] = nil
          end
          money = money.to_money
          currency_db = Money::Helpers.value_to_currency(currency_object || try(currency_column))

          unless currency_db && currency_db.compatible?(money.currency)
            Money.deprecate("[money_column] currency mismatch between #{currency_db} and #{money.currency}.")
          end
          write_attribute(column, money.value)
          @money_column_cache[column] = Money.new(money.value, currency_db)
        end
      end
    end
  end
end
