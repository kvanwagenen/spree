class AddSyncedAtToOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :synced_at, :datetime
  end
end
