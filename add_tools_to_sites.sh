#!/bin/bash

cd "`dirname "$0"`"

export SELF=$0

java -cp "lib/*:dist/*" org.jruby.Main --1.9 ruby/add_tools_to_sites.rb ${1+"$@"}
