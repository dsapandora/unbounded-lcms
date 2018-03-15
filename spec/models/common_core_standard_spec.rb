# frozen_string_literal: true

require 'rails_helper'

describe CommonCoreStandard do
  it 'has valid factory' do
    expect(build :common_core_standard).to be_valid
  end

  describe '.find_by_name_or_synonym' do
    let(:cc_standard) { create :common_core_standard, name: name }
    let(:name) { Faker::Lorem.word }

    before { cc_standard }

    subject { described_class.find_by_name_or_synonym name.capitalize }

    it 'looks for by downcased name' do
      expect(subject).to eq cc_standard
    end

    context 'when by name there is no results' do
      let(:cc_standard) { create :common_core_standard, alt_names: [name] }
      let(:name) { 'alternative' }

      it 'looks for by alternative names' do
        expect(subject).to eq cc_standard
      end
    end
  end

  describe '#generate_alt_names' do
    let(:cc_standard) { create :common_core_standard, name: "#{prefix}hs#{name}" }
    let(:name) { "#{name_clear}#{name_dashed}#{name_letter}" }
    let(:name_clear) { Faker::Lorem.word }
    let(:name_dashed) { '-4-b' }
    let(:name_letter) { '.3a' }
    let(:prefix) { described_class::CCSS_PREFIXES.sample }

    before { cc_standard.generate_alt_names }

    it 'replaces CCSS prefixes' do
      expect(cc_standard.alt_names.join).to_not include prefix
    end

    it 'adds copy of name without HS prefix if placed in the beginning' do
      expect(cc_standard.alt_names).to include name.gsub('hs', '')
    end

    it 'expands letters with dots if placed at the end of the name' do
      expect(cc_standard.alt_names.join).to include '3.a'
    end

    it 'adds copy of name with dashes replaced to dots' do
      expect(cc_standard.alt_names.join).to include name_dashed.tr('-', '.')
    end

    it 'adds copy of name with subject' do
      expect(cc_standard.alt_names).to include "#{cc_standard.subject}.#{name.tr('-', '.')}"
    end

    context 'when name contain MATH and there are 3 dots in the name' do
      let(:cc_standard) { create :common_core_standard, name: name, subject: 'math' }
      let(:name) { 'math5.oa.b.3' }
      let(:name_clear) { '5.oa.3' }

      it 'adds copy of name without cluster' do
        expect(cc_standard.alt_names.join(' ')).to include name_clear
      end
    end
  end
end
