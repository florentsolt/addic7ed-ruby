#!/usr/bin/env ruby

# Ruby modules
require 'open-uri'
require 'optparse'
require 'net/http'
# Bundler
require 'rubygems'
require 'bundler/setup'
Bundler.require
# Local modules
require './lib/addic7ed-errors'
require './lib/addic7ed-common'
require './lib/addic7ed-filename'
require './lib/addic7ed-episode'
require './lib/addic7ed-subtitle'

VERSION='0.0.6'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: addic7ed.rb [options] <file1> [<file2>, <file3>, ...]"

  opts.on("-l [LANGUAGE]", "--language [LANGUAGE]", "Language code to look subtitles for (default: French)") do |l|
    options[:language] = l
  end

  opts.on("-a", "--all-subtitles", "Display all available subtitles") do |a|
    options[:all] = a
  end

  opts.on("-n", "--do-not-download", "Do not download the subtitle") do |n|
    options[:nodownload] = n
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-q", "--quiet", "Run without output (cron-mode)") do |q|
    options[:quiet] = q
  end

  opts.on("-d", "--debug", "Debug mode [do not use]") do |d|
    options[:debug] = d
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

  opts.on_tail("-L", "--list-languages", "List all available languages") do
    puts "All available languages (with their corresponding ISO code):"
    Addic7ed::LANGUAGES.each do |lang, infos|
      puts "#{lang}:\t#{infos[:name]}"
    end
    exit
  end

  opts.on_tail("-V", "--version", "Show version number") do
    puts "This is addic7ed-ruby version #{VERSION} by Michael Baudino (https://github.com/michaelbaudino)"
    puts "Licensed under the terms of the MIT License"
    exit
  end
end.parse!

options[:filenames] = ARGV
options[:language] ||= 'fr'

# Main loop over mandatory arguments (e.g. filenames)

options[:filenames].each do |filename|
  unless File.file? filename or options[:debug]
    puts "Warning: #{filename} does not exist or is not a regular file. Skipping." unless options[:quiet]
    next
  end

  begin
    ep = Addic7ed::Episode.new(filename)
    puts "Searching subtitles for #{ep.filename.basename}" if options[:verbose]
    puts ep.filename.inspect.gsub(/^/, '  ') if options[:verbose]
    ep.subtitles(options[:language])
    if options[:all] or options[:verbose]
      puts 'Available subtitles:'.gsub(/^/, options[:verbose] ? '  ' : '')
      ep.subtitles(options[:language]).each do |sub|
        puts "#{sub}".gsub(/^/, options[:verbose] ? '    ' : '  ')
      end
      next if options[:all]
    end
    ep.best_subtitle(options[:language])
    if options[:verbose]
      puts '  Best subtitle:'
      puts "    #{ep.best_subtitle(options[:language])}"
    end
    unless options[:nodownload]
      ep.download_best_subtitle!(options[:language])
      puts "New subtitle downloaded for #{filename}.\nEnjoy your show :-)".gsub(/^/, options[:verbose] ? '  ' : '')
    end
  rescue Addic7ed::InvalidFilename
    puts "#{filename} does not seem to be a valid TV show filename. Skipping.".gsub(/^/, options[:verbose] ? '  ' : '') unless options[:quiet]
    next
  rescue Addic7ed::ShowNotFound
    puts "Show not found on Addic7ed : #{ep.filename.showname}. Skipping.".gsub(/^/, options[:verbose] ? '  ' : '') unless options[:quiet]
    next
  rescue Addic7ed::EpisodeNotFound
    puts "Episode not found on Addic7ed : #{ep.filename.showname} S#{ep.filename.season}E#{ep.filename.episode}. Skipping.".gsub(/^/, options[:verbose] ? '  ' : '') unless options[:quiet]
    next
  rescue Addic7ed::LanguageNotSupported
    puts "Addic7ed does not support language '#{options[:language]}'. Exiting.".gsub(/^/, options[:verbose] ? '  ' : '') unless options[:quiet]
    break
  rescue Addic7ed::ParsingError
    puts "HTML parsing failed. Either you've found a bug (please submit an issue) or Addic7ed website has been updated and cannot be crawled anymore (in this case, please wait for an update or submit a pull request). Skipping.".gsub(/^/, options[:verbose] ? '  ' : '') unless options[:quiet]
    next
  rescue Addic7ed::NoSubtitleFound
    puts "No (acceptable) subtitle has been found on Addic7ed for #{filename}. Maybe try again later.".gsub(/^/, options[:verbose] ? '  ' : '') unless options[:quiet]
    next
  rescue Addic7ed::DownloadError
    puts "The subtitle could not be downloaded. Skipping.".gsub(/^/, options[:verbose] ? '  ' : '') unless options[:quiet]
    next
  rescue Addic7ed::SubtitleCannotBeSaved
    puts "The downloaded subtitle could not be saved as #{ep.filename.to_s.gsub(/\.\w{3}$/, '.srt')}. Skipping.".gsub(/^/, options[:verbose] ? '  ' : '') unless options[:quiet]
    next
  rescue Addic7ed::WTFError => e
    puts "WTF (I sincerely have no idea what I'm doing): #{e.message}".gsub(/^/, options[:verbose] ? '  ' : '') unless options[:quiet]
    next
  end

end