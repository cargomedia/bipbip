#!/usr/bin/env bash

set -e
wait-for-it mysql:3306
wait-for-it redis:6379
wait-for-it memcached:11211
bundle exec rake
