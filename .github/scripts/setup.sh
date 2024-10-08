#!/bin/bash

brew install swiftgen@6.6.2
brew install sourcery@2.1.3

# Install Ruby Bundler
gem install bundler:2.5.21

# Install Ruby Gems
bundle install

git diff | cat

# Setup notification endpoint
bundle exec arkana
