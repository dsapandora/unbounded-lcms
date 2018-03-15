# frozen_string_literal: true

FactoryGirl.define do
  factory :common_core_standard do
    subject { %w(ela math).sample }
  end
end
