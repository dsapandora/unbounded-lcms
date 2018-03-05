# frozen_string_literal: true

class AddBreadcrumbTitleToCurriculums < ActiveRecord::Migration
  def change
    add_column :curriculums, :breadcrumb_title, :string
  end
end
