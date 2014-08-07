class AddTotalOnHandToVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :total_on_hand, :integer, :default => 0
  end
end
