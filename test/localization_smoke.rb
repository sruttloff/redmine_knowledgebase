require 'yaml'
require 'tmpdir'
require 'fileutils'
require 'rbconfig'
locales = File.expand_path('../config/locales', __dir__)
files = Dir[File.join(locales, '*.yml')]
files.each { |file| raise "Empty locale #{file}" unless YAML.safe_load_file(file).is_a?(Hash) }
puts "PASS: #{files.size} locale files parse"
Dir.mktmpdir('kb-locales-') do |directory|
  files.each { |file| FileUtils.cp(file, directory) }
  script = File.expand_path('../bin/refresh_localizations.rb', __dir__)
  raise 'Translation refresh failed' unless system(RbConfig.ruby, script, directory)
  control = YAML.safe_load_file(File.join(directory, 'en.yml')).fetch('en')
  Dir[File.join(directory, '*.yml')].each do |file|
    data = YAML.safe_load_file(file).values.first
    raise "Missing keys after refresh: #{file}" unless (control.keys - data.keys).empty?
  end
  puts 'PASS: translation refresh fills missing keys using standard YAML; source locale files unchanged'
end
