Money.class_eval do
  ACTIVESUPPORT_AVAILABLE = defined?(ActiveSupport)

  def self.deprecate(message)
    ACTIVESUPPORT_AVAILABLE ? ActiveSupport::Deprecation.warn(message) : warn("DEPRECATION WARNING: #{message}")
  end
end
