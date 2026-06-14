class ChangePlacesStatusDefaultToPublished < ActiveRecord::Migration[8.1]
  def change
    change_column_default :places, :status, from: "draft", to: "published"
  end
end
