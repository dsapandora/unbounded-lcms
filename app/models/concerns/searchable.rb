require 'active_support/concern'

module Searchable
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_indexing

    after_commit :index_document, on: [:create, :update], unless: :skip_indexing?
    after_commit :delete_document, on: :destroy, unless: :skip_indexing?

    def index_document
      begin
        doc = Search::Document.build_from self
        search_repo.save(doc)
      rescue Faraday::ConnectionFailed; end
    end

    def delete_document
      begin
        doc = Search::Document.build_from self
        search_repo.delete(doc)
      rescue Faraday::ConnectionFailed; end
    end

    def search_repo
      @@search_repo ||= Search::Repository.new
    end

    def self.search(term, options={})
      Search::Document.search term, options.merge!(model_type: self.name.underscore)
    end

    def skip_indexing?
      !!skip_indexing || !search_repo.index_exists?
    end

  end
end
