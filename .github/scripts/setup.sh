#!/bin/bash

# Install Ruby Bundler
gem install bundler:2.3.11

# Install Ruby Gems
bundle install

# stub keys. DO NOT use in production
bundle exec pod keys set notification_endpoint "<endpoint>"
bundle exec pod keys set notification_endpoint_debug "<endpoint>"

bundle exec pod install
