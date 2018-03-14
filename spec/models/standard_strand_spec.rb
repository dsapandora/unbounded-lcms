# frozen_string_literal: true

require 'rails_helper'

describe StandardStrand do
  it 'has valid factory' do
    expect(build :standard_strand).to be_valid
  end
end
