# frozen_string_literal: true

class DropLobjectTitles < ActiveRecord::Migration
  def change
    drop_table :lobject_titles
  end
end
