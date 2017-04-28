module MoneyColumn
  class Railtie < Rails::Railtie
    ActiveSupport.on_load :active_record do
      ActiveRecord::Base.send(:include, MoneyColumn::ActiveRecordHooks)
    end
  end
end
