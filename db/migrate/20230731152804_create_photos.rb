class CreatePhotos < ActiveRecord::Migration[7.0]
  def change
    create_table :photos do |t|
      t.belongs_to :entry, foreign_key: true
      t.string :src
      t.string :alt

      t.timestamps
    end
  end
end
