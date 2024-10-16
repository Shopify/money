# frozen_string_literal: true

Money.class_eval do
  ACTIVE_SUPPORT_DEFINED = defined?(ActiveSupport)

  def self.active_support_deprecator
    @active_support_deprecator ||= begin
      next_major_version = Money::VERSION.split(".").first.to_i + 1
      ActiveSupport::Deprecation.new("#{next_major_version}.0.0", "Shopify/Money")
    end
  end

  def self.deprecate(message)
    if ACTIVE_SUPPORT_DEFINED
      external_callstack = caller_locations(1, 10).reject do |location|
        location.path.include?('gems/shopify-money')
      end
      active_support_deprecator.warn("[Shopify/Money] #{message}\n", external_callstack)
    else
      Kernel.warn("DEPRECATION WARNING: [Shopify/Money] #{message}\n")
    end
  end
end
