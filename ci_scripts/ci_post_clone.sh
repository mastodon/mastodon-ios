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

# workaround default installation location cannot access without sudo problem
echo 'export GEM_HOME=$HOME/gems' >>~/.bash_profile
echo 'export PATH=$HOME/gems/bin:$PATH' >>~/.bash_profile
export GEM_HOME=$HOME/gems
export PATH="$GEM_HOME/bin:$PATH"

# install bundle gem
gem install bundler --install-dir $GEM_HOME

# setup gems
bundle install

bundle exec arkana
bundle exec pod install
