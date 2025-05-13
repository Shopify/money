# frozen_string_literal: true
require 'spec_helper'

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
    

    context "with experimental: true" do
      it "loads crypto currencies" do
        currencies = Money::Currency::Loader.load_currencies(experimental: true)
        expect(currencies["usdc"]["iso_code"]).to eq("USDC")
      end

      it "still loads regular currencies" do
        currencies = Money::Currency::Loader.load_currencies(experimental: true)
        expect(currencies["usd"]["iso_code"]).to eq("USD")
      end
    end

    context "with experimental: false" do
      it "does not load crypto currencies" do
        currencies = Money::Currency::Loader.load_currencies(experimental: false)
        expect(currencies["usdc"]).to be_nil
      end
    end
  end
end
