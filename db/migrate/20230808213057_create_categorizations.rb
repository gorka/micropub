class CreateCategorizations < ActiveRecord::Migration[7.0]
  def change
    create_table :categorizations do |t|
      t.belongs_to :category, null: false, foreign_key: true
      t.references :categorizable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
