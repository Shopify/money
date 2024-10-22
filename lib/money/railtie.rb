# frozen_string_literal: true

class Money
  class Railtie < Rails::Railtie
    initializer "shopify-money.setup_active_job_serializer" do
      ActiveSupport.on_load(:active_job) do
        if defined?(ActiveJob::Serializers)
          require_relative "rails/job_argument_serializer"
          ActiveJob::Serializers.add_serializers(::Money::Rails::JobArgumentSerializer)
        end
      end
    end

    initializer "shopify-money.setup_locale_aware_parser" do
      ActiveSupport.on_load(:action_view) do
        Money::Parser::LocaleAware.decimal_separator_resolver =
          -> { ::I18n.translate("number.currency.format.separator") }
      end
    end
  end
end
