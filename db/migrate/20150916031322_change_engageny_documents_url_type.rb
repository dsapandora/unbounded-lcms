# frozen_string_literal: true

class ChangeEngagenyDocumentsUrlType < ActiveRecord::Migration
  def change
    change_column :engageny_documents, :url, :text
  end
end
