# frozen_string_literal: true

class DropLobjectDescriptions < ActiveRecord::Migration
  def change
    drop_table :lobject_descriptions
  end
end
