module MoneyAccessor
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def money_accessor(*columns)
      variable_get = self <= Struct ? :[]  : :instance_variable_get
      variable_set = self <= Struct ? :[]= : :instance_variable_set

      Array(columns).flatten.each do |name|
        variable_name = self <= Struct ? name : "@#{name}"

        define_method(name) do
          value = public_send(variable_get, variable_name)
          value.blank? ? nil : Money.from_amount(value)
        end

        define_method("#{name}=") do |value|
          if value.blank? || !value.respond_to?(:to_money)
            public_send(variable_set, variable_name, nil)
            nil
          else
            money = value.to_money
            public_send(variable_set, variable_name, money.value)
            money
          end
        end
      end
    end
  end
end
