class AddPublicProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string
    add_column :users, :bio, :text
    add_reference :users, :profile_photo_asset, type: :uuid, foreign_key: { to_table: :assets }

    add_index :users,
      "LOWER(username)",
      unique: true,
      where: "username IS NOT NULL",
      name: "index_users_on_lower_username"
  end
end
