#!/usr/bin/env ruby

require 'fileutils'

docs_dir = "_docs"

Dir.glob("#{docs_dir}/*.md").each do |file|
  next if file == "#{docs_dir}/README.md"
  
  content = File.read(file)
  
  # Skip if file already has front matter
  next if content.start_with?('---')
  
  filename = File.basename(file, '.md')
  title = filename.gsub('-', ' ').split.map(&:capitalize).join(' ')
  
  front_matter = <<~FRONT
    ---
    layout: default
    title: "#{title}"
    date: 2026-03-19 19:50:00
    tags: documentation
    permalink: /docs/#{filename}.html
    ---
    
  FRONT
  
  File.write(file, front_matter + content)
  puts "Added front matter to #{file}"
end

puts "Front matter added to all documentation files!"
