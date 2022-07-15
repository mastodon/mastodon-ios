#!/bin/zsh

# Xcode Cloud scripts

set -xeu
set -o pipefail

# list hardware
system_profiler SPSoftwareDataType SPHardwareDataType

echo $PWD
cd $CI_WORKSPACE
echo $PWD

# install ruby from homebrew
brew install ruby
ruby --version

# install bundle gem
gem install bundler

# setup gems
bundle install

bundle exec arkana
bundle exec pod install
