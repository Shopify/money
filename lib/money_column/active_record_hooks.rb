# frozen_string_literal: true

module MoneyColumn
  class Error < StandardError; end
  class CurrencyReadOnlyError < Error; end
  class CurrencyMismatchError < Error; end

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

      if money.is_a?(Money)
        write_currency(column, money, options)
      end

      self[column] = Money::Helpers.value_to_decimal(money)
    end

    def write_currency(column, money, options)
      currency_column = options[:currency_column]

      if options[:currency]
        validate_hardcoded_currency_compatibility!(column, money, options[:currency])
        return
      end

      if options[:currency_read_only]
        validate_currency_compatibility!(column, money, currency_column)
        return
      end

      if currency_column && !money.no_currency?
        self[currency_column] = money.currency.to_s
      end
    end

    def read_currency_column(currency_column)
      if @money_raw_new_attributes&.key?(currency_column.to_sym)
        # currency column in the process of being updated
        return @money_raw_new_attributes[currency_column.to_sym]
      end

      try(currency_column)
    end

    def validate_hardcoded_currency_compatibility!(column, money, expected_currency)
      return if money.currency.compatible?(Money::Helpers.value_to_currency(expected_currency))

      msg = "Invalid #{column}: attempting to write a money object with currency '#{money.currency}' to a record with hard-coded currency '#{expected_currency}'."
      if Money::Config.current.legacy_deprecations
        Money.deprecate(msg)
      else
        raise MoneyColumn::CurrencyMismatchError, msg
      end
    end

    def validate_currency_compatibility!(column, money, currency_column)
      current_currency = read_currency_column(currency_column)
      return if current_currency.nil? || money.currency.compatible?(Money::Helpers.value_to_currency(current_currency))

      msg = "Invalid #{column}: attempting to write a money object with currency '#{money.currency}' to a record with currency '#{current_currency}'. " \
        "If you do want to change the record's currency, either remove `currency_read_only` or update the record's currency manually"

      if Money::Config.current.legacy_deprecations
        Money.deprecate(msg)
      else
        raise MoneyColumn::CurrencyReadOnlyError, msg
      end
    end

    def _assign_attributes(new_attributes)
      @money_raw_new_attributes = new_attributes.symbolize_keys
      super
    ensure
      @money_raw_new_attributes = nil
    end

    module ClassMethods
      attr_reader :money_column_options

      def money_column(*columns, currency_column: nil, currency: nil, currency_read_only: false, coerce_null: false)
        @money_column_options ||= {}

        options = normalize_money_column_options(
          currency_column: currency_column,
          currency: currency,
          currency_read_only: currency_read_only,
          coerce_null: coerce_null,
        )

        if options[:currency_column]
          clear_cache_on_currency_change(options[:currency_column])
        end

        columns.flatten.each do |column|
          column_string = column.to_s.freeze

          @money_column_options[column_string] = options

          attribute(column_string, MoneyColumn::ActiveRecordType.new)

          define_method(column) do
            read_money_attribute(column_string)
          end

          define_method("#{column}=") do |money|
            write_money_attribute(column_string, money)
          end
        end
      end

      private

      def normalize_money_column_options(options)
        raise ArgumentError,
          'cannot set both :currency_column and :currency options' if options[:currency] && options[:currency_column]
        raise ArgumentError,
          'must set one of :currency_column or :currency options' unless options[:currency] || options[:currency_column]

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

        define_method("#{currency_column}=") do |value|
          clear_money_column_cache
          super(value)
        end
      end

      def inherited(subclass)
        subclass.instance_variable_set('@money_column_options', money_column_options.dup) if money_column_options
        super
      end
    end
  end
end
