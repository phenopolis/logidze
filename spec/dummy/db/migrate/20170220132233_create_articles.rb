class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :title
      t.integer :rating
      t.boolean :active
      t.references :user, foreign_key: true
      t.jsonb :log_data

      t.timestamps null: false
    end
  end
end
