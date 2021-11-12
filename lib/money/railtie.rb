# frozen_string_literal: true

class Money
  class Railtie < Rails::Railtie
    initializer "shopify-money.setup_active_job_serializer" do
      ActiveSupport.on_load :active_job do
        require_relative "rails/job_argument_serializer"
        ActiveJob::Serializers.add_serializers ::Money::Rails::JobArgumentSerializer
      end
    end
  end
end
