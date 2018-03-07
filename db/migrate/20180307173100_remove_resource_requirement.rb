class RemoveResourceRequirement < ActiveRecord::Migration
  def change
    drop_table :resource_requirements
  end
end
