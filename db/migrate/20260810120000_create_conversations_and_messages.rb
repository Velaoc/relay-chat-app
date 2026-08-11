class CreateConversationsAndMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false, default: "New chat"
      t.timestamps
    end

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.timestamps
    end

    add_index :messages, %i[conversation_id created_at]
    add_index :conversations, %i[user_id updated_at]
  end
end
