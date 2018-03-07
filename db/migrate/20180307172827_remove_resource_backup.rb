class RemoveResourceBackup < ActiveRecord::Migration
  def change
    drop_table :resource_backups
  end
end
