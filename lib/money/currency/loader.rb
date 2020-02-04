# frozen_string_literal: true
require 'json'

class Money
  class Currency
    module Loader
      extend self

      CURRENCY_DATA_PATH = File.expand_path("../../../../config", __FILE__)

      def load_currencies
        currencies = {}
        currencies.merge! parse_currency_file("currency_historic.json")
        currencies.merge! parse_currency_file("currency_non_iso.json")
        currencies.merge! parse_currency_file("currency_iso.json")
      end

      private

      def parse_currency_file(filename)
        json = File.read("#{CURRENCY_DATA_PATH}/#{filename}")
        json.force_encoding(::Encoding::UTF_8) if defined?(::Encoding)
        JSON.parse(json)
      end
    end
  end
end
