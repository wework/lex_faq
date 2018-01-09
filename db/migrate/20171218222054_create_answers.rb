class CreateAnswers < ActiveRecord::Migration[5.1]
  def change
    create_table :answers do |t|
      t.jsonb :utterances, nil: false
      t.text :response, nil: false
      t.string :name, nil: false

      t.timestamps
    end
  end
end
