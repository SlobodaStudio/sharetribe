class AddNegotiablePriceToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :negotiable_price, :boolean, default: false
  end
end
