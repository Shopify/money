# frozen_string_literal: true
require 'spec_helper'
require 'tempfile'

RSpec.describe Money::Currency::Loader do

  describe 'load_currencies' do
    it 'loads the iso currency file' do
      expect(subject.load_currencies['usd']['iso_code']).to eq('USD')
      expect(subject.load_currencies['usd']['symbol']).to eq('$')
      expect(subject.load_currencies['usd']['subunit_to_unit']).to eq(100)
      expect(subject.load_currencies['usd']['smallest_denomination']).to eq(1)
    end

    it 'loads the non iso currency file' do
      expect(subject.load_currencies['jep']['iso_code']).to eq('JEP')
    end

    it 'loads the historic iso currency file' do
      expect(subject.load_currencies['eek']['iso_code']).to eq('EEK')
    end
  end

  describe 'load_crypto_currencies' do
    it 'loads the crypto currency file' do
      expect(subject.load_crypto_currencies['usdc']['iso_code']).to eq('USDC')
      expect(subject.load_crypto_currencies['usdc']['name']).to eq('USD Coin')
      expect(subject.load_crypto_currencies['usdc']['symbol']).to eq('USDC')
      expect(subject.load_crypto_currencies['usdc']['disambiguate_symbol']).to eq('USDC')
      expect(subject.load_crypto_currencies['usdc']['subunit_to_unit']).to eq(100)
      expect(subject.load_crypto_currencies['usdc']['smallest_denomination']).to eq(1)
    end

    it 'returns frozen and deduplicated data' do
      currencies = subject.load_crypto_currencies
      expect(currencies).to be_frozen
      expect(currencies['usdc']).to be_frozen
      expect(currencies['usdc']['iso_code']).to be_frozen
    end
  end

  describe 'load_custom_currencies' do
    it 'loads custom currencies from the given path' do
      file = Tempfile.new(['custom_currencies', '.yml'])
      file.write({
        "credits" => {
          "iso_code" => "CREDITS",
          "name" => "Loyalty Points",
          "symbol" => "CR",
          "disambiguate_symbol" => "CR",
          "subunit_to_unit" => 1,
          "smallest_denomination" => 1,
          "decimal_mark" => "."
        }
      }.to_yaml)
      file.close

      currencies = subject.load_custom_currencies(file.path)
      expect(currencies['credits']['iso_code']).to eq('CREDITS')
      expect(currencies['credits']['name']).to eq('Loyalty Points')
      expect(currencies['credits']['symbol']).to eq('CR')
      expect(currencies['credits']['subunit_to_unit']).to eq(1)
    ensure
      file.unlink
    end

    it 'raises ArgumentError when file does not exist' do
      expect {
        subject.load_custom_currencies('/nonexistent/path.yml')
      }.to raise_error(ArgumentError, /not found/)
    end

    it 'returns frozen and deduplicated data' do
      file = Tempfile.new(['custom_currencies', '.yml'])
      file.write({
        "credits" => {
          "iso_code" => "CREDITS",
          "name" => "Loyalty Points",
          "symbol" => "CR",
          "disambiguate_symbol" => "CR",
          "subunit_to_unit" => 1,
          "smallest_denomination" => 1,
          "decimal_mark" => "."
        }
      }.to_yaml)
      file.close

      currencies = subject.load_custom_currencies(file.path)
      expect(currencies).to be_frozen
      expect(currencies['credits']).to be_frozen
      expect(currencies['credits']['iso_code']).to be_frozen
    ensure
      file.unlink
    end
  end
end
