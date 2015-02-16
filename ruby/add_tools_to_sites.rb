#!/usr/bin/env ruby

require 'rubygems'
require 'java'
require 'csv'

require_relative 'sakaiws'


def main

  if ARGV.length != 2
    puts <<EOF
Usage: #{ENV.fetch("SELF", $0)} <config.rb> <input.csv>

input.csv is a comma-separated file with rows like this:

  site_id,tool_id,page_title,tool_title,force

If the "force" column contains the string "yes", "true" or "1", the tool will be
added to the site irrespective of whether there's already an instance of that
tool_id there.  Otherwise, the tool will only be added if there isn't one
already.

For example a file like:

  38dec74d-ad79-490e-a0cd-3ccd09275e14,sakai.podcasts,Podcasts,Podcasts
  38dec74d-ad79-490e-a0cd-3ccd09275e14,sakai.podcasts,Podcasts,Podcasts

will add the Podcasts tool once at most, while:

  38dec74d-ad79-490e-a0cd-3ccd09275e14,sakai.podcasts,Podcasts,Podcasts,true
  38dec74d-ad79-490e-a0cd-3ccd09275e14,sakai.podcasts,Podcasts,Podcasts,true

will add two instances of the tool.

EOF
    exit
  end

  (config, csv_file) = ARGV


  require File.absolute_path(config)
  ws = SakaiWS.new(CONFIG[:sakai_admin_user], CONFIG[:sakai_admin_pass], CONFIG[:sakai_url])

  CSV.foreach(csv_file) do |row|
    (site_id, tool_id, page_title, tool_title, force) = row.map(&:strip)

    if ['yes', 'true', '1'].include?("#{force}".downcase) ||  !ws.site_has_tool?(site_id, tool_id)
      $stderr.puts("Adding tool with #{row.inspect}")
      puts ws.add_tool_and_page_to_site(site_id, page_title, tool_title, tool_id)
    end
  end
end


main
