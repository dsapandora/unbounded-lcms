# frozen_string_literal: true

require 'rails_helper'

describe Download do
  it 'has valid factory' do
    expect(build :download).to be_valid
  end

  context 'cannot be created without' do
    it 'title' do
      obj = build :download, title: nil
      expect(obj).to_not be_valid
    end

    context 'when no file passed in' do
      it 'url' do
        obj = build :download, url: nil
        expect(obj).to_not be_valid
      end
    end

    context 'when no url passed in' do
      it 'file' do
        obj = build :download, url: nil
        expect(obj).to_not be_valid
      end
    end
  end

  describe '#attachment_url' do
    let(:download) { create :download, url: "#{prefix}url/path" }
    let(:prefix) { Download::URL_PUBLIC_PREFIX }

    subject { download.attachment_url }

    it 'subs specific public prefix' do
      expect(subject).to_not include prefix
    end

    context 'when url is absent' do
      let(:download) { build :download, file: file, url: nil }
      let(:file) { double }
      let(:url) { Faker::Internet.url }

      before do
        allow(download).to receive(:file).and_return(file)
        allow(file).to receive(:url).and_return(url)
      end

      it 'returns url of the file' do
        expect(subject).to eq url
      end
    end
  end

  describe '#s3_filename' do
    let(:download) { create :download, url: url }
    let(:url) { Faker::Internet.url }

    it 'returns base name of the attachment url' do
      expect(download.s3_filename).to eq File.basename(url)
    end
  end
end
