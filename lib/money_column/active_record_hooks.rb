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
      def money_column(*columns, currency_column: nil, currency: nil, currency_read_only: false, coerce_null: false)
        options = normalize_money_column_options(
          currency_column: currency_column,
          currency: currency,
          currency_read_only: currency_read_only,
          coerce_null: coerce_null
        )

        args.flatten.each do |column|
          column_string = column.to_s.freeze
          attribute(column_string, MoneyColumn::ActiveRecordType.new)
          money_column_reader(column_string, options[:currency_column], options[:currency], options[:coerce_null])
          money_column_writer(column_string, options[:currency_column], options[:currency], options[:currency_read_only])
        end
      end

      private

      def normalize_money_column_options(options)
        raise ArgumentError, 'cannot set both :currency_column and :currency options' if options[:currency] && options[:currency_column]
        raise ArgumentError, 'must set one of :currency_column or :currency options' unless options[:currency] || options[:currency_column]

        if options[:currency]
          options[:currency] = Money::Currency.find!(options[:currency]).to_s.freeze
          options[:currency_read_only] = true
        end

        if options[:currency_column]
          options[:currency_column] = options[:currency_column].to_s.freeze
        end
        options
      end

      def clear_cache_on_currency_change(currency_column)
        define_method "#{currency_column}=" do |value|
          @money_column_cache.clear
          super(value)
        end
      end

      def money_column_reader(column, currency_column, currency_iso, coerce_null)
        define_method column do
          return @money_column_cache[column] if @money_column_cache[column]
          value = read_attribute(column)
          return if value.nil? && !coerce_null
          iso = currency_iso || send(currency_column)
          @money_column_cache[column] = Money.new(value, iso)
        end
      end

      def money_column_writer(column, currency_column, currency_iso, currency_read_only)
        define_method "#{column}=" do |money|
          @money_column_cache[column] = nil

          if money.blank?
            write_attribute(column, nil)
            return nil
          end

          currency_raw_source = currency_iso || (send(currency_column) rescue nil)
          currency_source = Money::Helpers.value_to_currency(currency_raw_source)

          if !money.is_a?(Money)
            return write_attribute(column, Money.new(money, currency_source).value)
          end

          if currency_raw_source && !currency_source.compatible?(money.currency)
            Money.deprecate("[money_column] currency mismatch between #{currency_source} and #{money.currency}.")
          end

          write_attribute(column, money.value)
          write_attribute(currency_column, money.currency.to_s) unless currency_read_only || money.no_currency?
        end
      end
    end
  end
end
