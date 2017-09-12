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
  end

  describe 'load_currency_normalization_map' do
    let(:mapping_inputs) { subject.load_currency_normalization_map.keys }
    let(:mapping_outputs) { subject.load_currency_normalization_map.values }
    let(:known_currencies) { subject.load_currencies.keys.map(&:upcase) }

    it 'loads the normalization mapping file' do
      expect(subject.load_currency_normalization_map['NTD']).to eq('TWD')
    end

    it 'maps to known codes in the currency files' do
      expect(known_currencies).to include(*mapping_outputs)
    end

    it 'does not map already known codes in the currency files' do
      expect(known_currencies).to_not include(*mapping_inputs)
    end

    it 'does not map to another code that needs mapping' do
      expect(mapping_inputs).to_not include(*mapping_outputs)
    end
  end
end
