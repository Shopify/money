# frozen_string_literal: true

require 'yaml'

class Money
  class Currency
    module Loader
      class << self
        def load_currencies
          currency_data_path = File.expand_path("../../../../config", __FILE__)

          currencies = {}
          currencies.merge! YAML.load_file("#{currency_data_path}/currency_historic.yml")
          currencies.merge! YAML.load_file("#{currency_data_path}/currency_non_iso.yml")
          currencies.merge! YAML.load_file("#{currency_data_path}/currency_iso.yml")
          deep_deduplicate!(currencies)
        end

        private

        def deep_deduplicate!(data)
          case data
          when Hash
            return data if data.frozen?
            data.transform_keys! { |k| deep_deduplicate!(k) }
            data.transform_values! { |v| deep_deduplicate!(v) }
            data.freeze
          when Array
            return data if data.frozen?
            data.map! { |d| deep_deduplicate!(d) }.freeze
          when String
            -data
          else
            data.freeze
          end
        end
      end
    end
  end
end
