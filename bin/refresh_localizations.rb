#!/usr/bin/env ruby
# Copyright (c) 2011 Alex Bevilacqua
# Refresh missing translation keys and sort them using Ruby's standard YAML library.
require 'yaml'

locale_directory = File.expand_path(ARGV.fetch(0, '../config/locales'), __dir__)
control = YAML.safe_load_file(File.join(locale_directory, 'en.yml')).fetch('en')
Dir[File.join(locale_directory, '*.yml')].sort.each do |path|
  data = YAML.safe_load_file(path)
  locale = data.keys.first
  data[locale] = control.merge(data.fetch(locale)).sort.to_h
  File.write(path, YAML.dump(data), encoding: 'UTF-8')
end
