class AddHotSeatToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :hot_seat, :boolean, null: false, default: false
  end
end
