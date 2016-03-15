#encoding: utf-8
require 'fileutils'

namespace :metadata do
   desc "Create the metatdata range dirs (src=digiserv-prodution mount)"
   task :range  => :environment do
      src = ENV['src']
      raise "SRC is required" if src.nil?
      root_dir = File.join(src, "metadata")
      rd = File.join(root_dir, "0001-0999")
      FileUtils.mkdir rd if !File.directory?(rd)
      start = 1000
      while start<=39000 do
         rd = File.join(root_dir, "#{start}-#{start+999}")
         FileUtils.mkdir rd if !File.directory?(rd)
         start += 1000
      end
   end
end
