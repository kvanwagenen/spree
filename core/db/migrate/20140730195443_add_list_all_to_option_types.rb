class AddListAllToOptionTypes < ActiveRecord::Migration
  def change
    add_column :spree_option_types, :list_all, :boolean, :default => false
  end
end
