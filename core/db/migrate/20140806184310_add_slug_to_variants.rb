class AddSlugToVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :slug, :string, :default => nil
  end
end
