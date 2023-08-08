class RemoveCategoriesFromEntries < ActiveRecord::Migration[7.0]
  def change
    remove_column :entries, :categories
  end
end
