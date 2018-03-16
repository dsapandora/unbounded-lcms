# frozen_string_literal: true

module Search
  class ElasticSearchDocument
    # return the corresponding repository
    def self.repository
      @repository ||= ::Search::Repository.new
    end

    def repository
      self.class.repository
    end

    def index!
      repository.save self
    end

    def delete!
      repository.delete self
    end

    # Default search
    #
    # term: [String || Nil]
    #   - [Nil]    : return a match_all query
    #   - [String] : perform a `fts_query` on the repository
    #
    # options: [Hash]
    #   - per_page : number os results per page
    #   - page     : results page number
    #   - <filter> : any doc specific filters, e.g: 'grade', 'subject', etc
    #
    def self.search(term, options = {})
      return [] unless repository.index_exists?

      query = if term.present?
                repository.fts_query(term, options)
              else
                repository.all_query(options)
              end
      repository.search query
    end
  end
end
