class AddImageUrlToMunicipalities < ActiveRecord::Migration[7.1]
  def change
    add_column :municipalities, :image_url, :string
  end
end
