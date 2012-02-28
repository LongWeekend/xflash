#!/bin/bash
export RVM_SRC=/Users/phooze/.rvm/src/ruby-1.9.3-p0
# Note, your source path should be something like /home/user/.rvm/src/ruby-1.9.3-p0

gem install archive-tar-minitar
gem install ruby_core_source-0.1.5.gem -- --with-ruby-include=/$RVM_SRC
gem install linecache19-0.5.13.gem -- --with-ruby-include=/$RVM_SRC
gem install ruby-debug-base19-0.11.26.gem -- --with-ruby-include=/$RVM_SRC
gem install ruby-debug19-0.11.6.gem -- --with-ruby-include=/$RVM_SRC
