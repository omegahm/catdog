class DefaultGamesToRulesVersion2 < ActiveRecord::Migration[8.1]
  def change
    change_column_default :games, :rules_version, from: 1, to: 2
  end
end
