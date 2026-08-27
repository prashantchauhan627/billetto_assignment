class CreateVoteCounts < ActiveRecord::Migration[7.2]
  def change
    create_table :vote_counts do |t|
      t.references :event, null: false, foreign_key: true, index: { unique: true }
      t.integer :upvotes, null: false, default: 0
      t.integer :downvotes, null: false, default: 0
      t.jsonb :votes_by_user, null: false, default: {}

      t.timestamps
    end
  end
end
