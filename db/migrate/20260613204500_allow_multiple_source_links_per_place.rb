class AllowMultipleSourceLinksPerPlace < ActiveRecord::Migration[8.1]
  def up
    remove_index :place_source_links, :place_id if index_exists?(:place_source_links, :place_id, unique: true)
    add_index :place_source_links, :place_id unless index_exists?(:place_source_links, :place_id)
  end

  def down
    remove_index :place_source_links, :place_id if index_exists?(:place_source_links, :place_id)
    add_index :place_source_links, :place_id, unique: true unless index_exists?(:place_source_links, :place_id)
  end
end
