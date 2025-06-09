class CreateCandles < ActiveRecord::Migration[7.1]
  def change
    create_table :candles do |t|
      t.date :date
      t.float :open
      t.float :high
      t.float :low
      t.float :close
      t.float :volume

      t.timestamps
    end
  end
end
