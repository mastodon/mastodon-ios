#!/bin/zsh

# Xcode Cloud scripts

set -xeu
set -o pipefail

# list hardware
system_profiler SPSoftwareDataType SPHardwareDataType

echo $PWD
cd $CI_WORKSPACE
echo $PWD

# install rbenv
brew install rbenv
which ruby
echo 'eval "$(rbenv init -)"' >> ~/.zprofile
source ~/.zprofile
which ruby

# by pass the openssl cannot build issue
# https://github.com/rbenv/ruby-build/discussions/1853#discussioncomment-2146106
brew cleanup openssl@3.0
brew uninstall openssl@3.0
rm -rf  /opt/homebrew/etc/openssl@3

brew install openssl@1.1

export PATH="/opt/homebrew/opt/openssl@1.1/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/opt/homebrew/opt/openssl@1.1"
source ~/.zshrc

CONFIGURE_OPTS=--with-openssl-dir=`brew --prefix openssl@1.1` CFLAGS="-Wno-error=implicit-function-declaration" rbenv install 3.0.3

# install ruby 3.0.3
# rbenv install 3.0.3
rbenv global 3.0.3
ruby --version

# install bundle gem
gem install bundler

# setup gems
bundle install

bundle exec arkana
bundle exec pod install
