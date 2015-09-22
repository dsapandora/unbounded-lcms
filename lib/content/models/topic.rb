require 'content/models/concerns/canonicable'
require 'content/models/concerns/normalizable'

module Content
  module Models
    class Topic < ActiveRecord::Base
      include Canonicable
      include Normalizable
      normalize_attr :name, ->(val) { val.strip.downcase }

      validates :name, presence: true

      default_scope { order(:name) }
    end
  end
end
