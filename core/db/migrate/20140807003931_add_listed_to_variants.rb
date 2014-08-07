class AddListedToVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :listed, :boolean, :default => true
  end
end
