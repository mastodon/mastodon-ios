source "https://rubygems.org"

gem "xcpretty"
gem "abbrev" # Required for Ruby 3.4+ compatibility

# Fastlane
gem "fastlane"
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
