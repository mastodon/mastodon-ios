#!/bin/bash

sudo gem install cocoapods-keys

# stub keys. DO NOT use in production
sudo pod keys set notification_endpoint "<endpoint>"
sudo pod keys set notification_endpoint_debug "<endpoint>"

sudo pod install
