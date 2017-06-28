Money.class_eval do
  ACTIVESUPPORT_AVAILABLE = defined?(ActiveSupport)

  def self.deprecate(message)
    ACTIVESUPPORT_AVAILABLE ? ActiveSupport::Deprecation.warn("#{message}\n") : warn("DEPRECATION WARNING: #{message}\n")
  end
end
