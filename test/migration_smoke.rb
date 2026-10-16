# Standalone MySQL migration check. Only generated kb_migration_* databases are used.
# KNOWLEDGEBASE_MIGRATION_DATABASE_URL must identify a local administrative connection.
require 'active_record'
require 'securerandom'
STDOUT.sync = true
ActiveRecord::Migration.verbose = false
ActiveRecord::Base.establish_connection(ENV.fetch('KNOWLEDGEBASE_MIGRATION_DATABASE_URL'))
admin_config = ActiveRecord::Base.connection_db_config.configuration_hash
migration_files = Dir[File.expand_path('../db/migrate/*.rb', __dir__)].sort
migration_files.each { |file| require file }
migrations = migration_files.map { |file| File.basename(file, '.rb').sub(/^\d+_/, '').camelize.constantize.new }
%w[fresh legacy_tags].each do |scenario|
  database = "kb_migration_#{SecureRandom.hex(8)}"
  raise 'Invalid temporary database name' unless /\Akb_migration_[0-9a-f]{16}\z/.match?(database)
  begin
    ActiveRecord::Base.connection.create_database(database, charset: 'utf8mb4')
    ActiveRecord::Base.establish_connection(admin_config.merge(database: database))
    connection = ActiveRecord::Base.connection
    if scenario == 'legacy_tags'
      connection.create_table(:tags) { |t| t.string :name }
      connection.create_table(:taggings) do |t|
        t.integer :tag_id
        t.integer :taggable_id
        t.string :taggable_type
      end
      connection.execute "INSERT INTO tags (id, name) VALUES (1, 'Existing issue tag')"
      connection.execute "INSERT INTO taggings (tag_id, taggable_id, taggable_type) VALUES (1, 123, 'Issue')"
    end
    migrations.each { |migration| migration.migrate(:up) }
    raise 'Missing modern tag counter' unless connection.column_exists?(:tags, :taggings_count)
    raise 'Missing shared tenant column' unless connection.column_exists?(:taggings, :tenant)
    raise 'IPv6 address truncated' unless connection.columns(:viewings).find { |column| column.name == 'ip' }.limit == 45
    if scenario == 'legacy_tags'
      raise 'Existing tags lost' unless connection.select_value('SELECT name FROM tags WHERE id = 1') == 'Existing issue tag'
      raise 'Existing tag counter not rebuilt' unless connection.select_value('SELECT taggings_count FROM tags WHERE id = 1') == 1
    end
    migrations.last.migrate(:up)
    migrations.reverse_each { |migration| migration.migrate(:down) }
    raise 'Shared tag tables removed' unless connection.table_exists?(:tags) && connection.table_exists?(:taggings)
    if scenario == 'legacy_tags'
      raise 'Foreign plugin tagging removed on uninstall' unless connection.select_value("SELECT COUNT(*) FROM taggings WHERE taggable_type = 'Issue'") == 1
    end
    puts "PASS: #{scenario}: installation, additive upgrade, repeated upgrade, IPv6, uninstall preserves shared tags"
  ensure
    ActiveRecord::Base.establish_connection(admin_config)
    ActiveRecord::Base.connection.drop_database(database)
  end
end
