class AddImageUrlToMunicipalities < ActiveRecord::Migration[7.0]
  def change
    add_column :municipalities, :image_url, :string
  end
end
