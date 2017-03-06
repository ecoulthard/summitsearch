class AddComputedValue1ToFeature < ActiveRecord::Migration
  def change
    add_column :features, :computed_value1, :decimal
    add_column :features, :computed_value2, :decimal
    add_index :features, :computed_value1
    add_index :features, :computed_value2
  end
end
