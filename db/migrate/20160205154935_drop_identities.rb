# frozen_string_literal: true

class DropIdentities < ActiveRecord::Migration
  def change
    drop_table :lobject_identities
    drop_table :identities
  end
end
