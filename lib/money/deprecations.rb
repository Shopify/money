# frozen_string_literal: true

Money.class_eval do
  ACTIVE_SUPPORT_DEFINED = defined?(ActiveSupport)
  DEPRECATION_STACKTRACE_LENGTH = 5

  def self.active_support_deprecator
    @active_support_deprecator ||= begin
      next_major_version = Money::VERSION.split(".").first.to_i + 1
      ActiveSupport::Deprecation.new("#{next_major_version}.0.0", "Shopify/Money")
    end
  end

  def self.deprecate(message)
    if ACTIVE_SUPPORT_DEFINED
      active_support_deprecator.warn("[Shopify/Money] #{message}\n", caller_stack)
    else
      Kernel.warn("DEPRECATION WARNING: [Shopify/Money] #{message}\n")
    end
  end

  # :nocov:
  if Thread.respond_to?(:each_caller_location)
    def self.caller_stack
      stack = []
      Thread.each_caller_location do |location|
        stack << location unless location.path.include?('gems/shopify-money')
        break if stack.length == DEPRECATION_STACKTRACE_LENGTH
      end
      stack
    end
  else
    def self.caller_stack
      caller_locations(2, DEPRECATION_STACKTRACE_LENGTH * 2).reject do |location|
        location.path.include?('gems/shopify-money')
      end
    end
  end
  # :nocov:
end
