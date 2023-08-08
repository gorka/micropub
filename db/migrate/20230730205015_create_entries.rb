class CreateEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :entries do |t|
      t.string :name
      t.string :summary
      t.text :content, null: false
      t.datetime :published_at
      t.string :categories

      t.timestamps
    end
  end
end
