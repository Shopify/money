module MoneyColumn
  module ActiveRecordHooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    def reload(*)
      clear_money_column_cache if persisted?
      super
    end

    def initialize_dup(*)
      @money_column_cache = {}
      super
    end

    private

    def clear_money_column_cache
      @money_column_cache.clear
    end

    def init_internals
      @money_column_cache = {}
      super
    end

    def read_money_attribute(column)
      column = column.to_s
      options = self.class.money_column_options[column]

      return @money_column_cache[column] if @money_column_cache[column]

      value = self[column]

      return if value.nil? && !options[:coerce_null]

      @money_column_cache[column] = Money.new(value, options[:currency] || send(options[:currency_column]))
    end

    def write_money_attribute(column, money)
      column = column.to_s
      options = self.class.money_column_options[column]

      @money_column_cache[column] = nil

      if money.blank?
        return self[column] = nil
      end

      currency_raw_source = options[:currency] || (send(options[:currency_column]) rescue nil)
      currency_source = Money::Helpers.value_to_currency(currency_raw_source)

      if !money.is_a?(Money)
        return self[column] = Money.new(money, currency_source).value
      end

      if currency_raw_source && !currency_source.compatible?(money.currency)
        Money.deprecate("[money_column] currency mismatch between #{currency_source} and #{money.currency}.")
      end

      self[column] = money.value
      self[options[:currency_column]] = money.currency.to_s unless options[:currency_read_only] || money.no_currency?
    end

    module ClassMethods
      attr_reader :money_column_options

      def money_column(*columns, currency_column: nil, currency: nil, currency_read_only: false, coerce_null: false)
        @money_column_options ||= {}

        options = normalize_money_column_options(
          currency_column: currency_column,
          currency: currency,
          currency_read_only: currency_read_only,
          coerce_null: coerce_null
        )

        if options[:currency_column]
          clear_cache_on_currency_change(options[:currency_column])
        end

        columns.flatten.each do |column|
          column_string = column.to_s.freeze

          @money_column_options[column_string] = options

          attribute(column_string, MoneyColumn::ActiveRecordType.new)

          define_method column do
            read_money_attribute(column_string)
          end

          define_method "#{column}=" do |money|
            write_money_attribute(column_string, money)
          end
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
        return if money_column_options.any? { |_, opt| opt[:currency_column] == currency_column }

        define_method "#{currency_column}=" do |value|
          clear_money_column_cache
          super(value)
        end
      end
    end
  end
end
