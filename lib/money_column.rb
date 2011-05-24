module MoneyColumn
  def self.included(base)
    base.extend(ClassMethods)
  end                   
  
  module ClassMethods
    
    def money_column(*columns)
      
      [columns].flatten.each do |name|
        define_method(name) do
          value = read_attribute(name)
          value.blank? ? nil : Money.new(read_attribute(name))
        end
        
        define_method("#{name}_before_type_cast") do
          send(name) && sprintf("%.2f", send(name))
        end
        
        define_method("#{name}=") do |value|
          if value.blank?
            write_attribute(name, nil)
            nil
          else
            money = value.to_money
            write_attribute(name, money.value)
            money
          end
        end        
      end
    end
  end
end