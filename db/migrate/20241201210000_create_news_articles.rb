class CreateNewsArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :news_articles do |t|
      t.string :title
      t.text :description
      t.string :url
      t.datetime :published_at
      t.references :municipality, null: false, foreign_key: true

      t.timestamps
    end
  end
end
