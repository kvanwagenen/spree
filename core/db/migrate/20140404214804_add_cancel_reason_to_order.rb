class AddCancelReasonToOrder < ActiveRecord::Migration
  def change
    add_column :spree_orders, :cancel_reason, :string
  end
end
