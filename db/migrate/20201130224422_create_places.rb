class CreatePlaces < ActiveRecord::Migration[5.2]
  def change
    create_table :places do |t|
      t.string :city_name
      t.string :zip_code
      t.string :address
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
