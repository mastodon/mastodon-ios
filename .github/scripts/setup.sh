#!/bin/bash

sudo gem install cocoapods-keys

# stub keys. DO NOT use in production
pod keys set notification_endpoint "<endpoint>"
pod keys set notification_endpoint_debug "<endpoint>"

sudo pod install
