#!/bin/bash

# workaround https://github.com/CocoaPods/CocoaPods/issues/11355
# sed -i '' $'1s/^/source "https:\\/\\/github.com\\/CocoaPods\\/Specs.git"\\\n\\\n/' Podfile

# Install Ruby Bundler
gem install bundler:2.3.11

# Install Ruby Gems
bundle install

# Setup notification endpoint
bundle exec arkana

bundle exec pod install
