Money.class_eval do
  ACTIVE_SUPPORT_DEFINED = defined?(ActiveSupport)

  def self.active_support_deprecator
    @active_support_deprecator ||= ActiveSupport::Deprecation.new('1.0.0', 'Shopify/Money')
  end

  def self.deprecate(message)
    if ACTIVE_SUPPORT_DEFINED
      active_support_deprecator.warn("[Shopify/Money] #{message}\n")
    else
      Kernel.warn("DEPRECATION WARNING: [Shopify/Money] #{message}\n")
    end
  end
end
