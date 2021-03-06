# frozen_string_literal: true

class AddIndecesToLrDocuments < ActiveRecord::Migration
  def change
    add_index :lr_documents, :conformed_at
    add_index :lr_documents, :format_parsed_at
  end
end
