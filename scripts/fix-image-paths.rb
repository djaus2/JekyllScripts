#!/usr/bin/env ruby

require 'fileutils'

docs_dir = "_docs"

Dir.glob("#{docs_dir}/*.md").each do |file|
  next if file == "#{docs_dir}/README.md"
  
  content = File.read(file)
  
  # Replace image references to use the correct path
  # Change img_...png to ../docs/img_...png
  content.gsub!(/!\[([^\]]*)\]\((img_.*\.png)\)/) do |match|
    alt_text = $1
    image_name = $2
    "![#{alt_text}](../docs/#{image_name})"
  end
  
  File.write(file, content)
  puts "Updated image paths in #{file}"
end

puts "Image paths updated in all documentation files!"
