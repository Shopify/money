module MoneyAccessor
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def money_accessor(*columns)
      Array(columns).flatten.each do |name|
        define_method(name) do
          value = _money_get(name)
          value.blank? ? nil : Money.new(value)
        end

        define_method("#{name}=") do |value|
          if value.blank? || !value.respond_to?(:to_money)
            _money_set(name, nil)
            nil
          else
            money = value.to_money
            _money_set(name, money.value)
            money
          end
        end
      end
    end
  end

  private
  
  def _money_set(ivar, value)
    if self.is_a?(Struct)
      self[ivar] = value
    else
      instance_variable_set("@#{ivar}", value)
    end
  end

  def _money_get(ivar)
    if self.is_a?(Struct)
      self[ivar]
    else
      instance_variable_get("@#{ivar}")
    end
  end
end
