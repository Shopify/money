module MoneyColumn
  class Railtie < Rails::Railtie
    ActiveSupport.on_load :active_record do
      ActiveRecord::Base.extend(MoneyColumn::ActiveRecordHooks)
    end
  end
end
