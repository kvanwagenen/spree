class AddFulfillmentCostToVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :fulfillment_cost, :decimal, default: 0, precision: 8, scale: 2
  end
end
