# frozen_string_literal: true

class DropLrDocumentLogs < ActiveRecord::Migration
  def change
    drop_table :lr_document_logs
  end
end
