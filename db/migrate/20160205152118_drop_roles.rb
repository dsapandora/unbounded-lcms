# frozen_string_literal: true

class DropRoles < ActiveRecord::Migration
  def change
    drop_table :user_roles
    drop_table :roles
  end
end
