module Addic7ed
  class Subtitle

    attr_reader :version, :language, :status, :via, :downloads
    attr_accessor :url

    def initialize(options = {})
      @version   = options[:version]
      @language  = options[:language]
      @status    = options[:status]
      @url       = options[:url]
      @via       = options[:via]
      @downloads = options[:downloads].to_i || 0
      normalize_version!
    end

    def to_s
      "#{url}\t->\t#{version} (#{language}, #{status}) [#{downloads} downloads]#{" (via #{via})" if via}"
    end

    def works_for?(version = '')
      is_completed? and is_compatible_with? version
    end

    def can_replace?(other_subtitle)
      return false unless is_completed?
      return true if other_subtitle.nil?
      language == other_subtitle.language &&
      is_compatible_with?(other_subtitle.version) &&
      is_more_popular_than?(other_subtitle)
    end

    def is_featured?
      via == "http://addic7ed.com"
    end

    def is_completed?
      status == 'Completed'
    end

  protected

    def normalize_version!
      @version ||= ""
      @version.gsub!(/^Version */i, '')
      @version.gsub!(/720p/i,       '')
      @version.gsub!(/hdtv/i,       '')
      @version.gsub!(/proper/i,     '')
      @version.gsub!(/rerip/i,      '')
      @version.gsub!(/x\.?264/i,    '')
      @version.gsub!(/^[- \.]*/,    '')
      @version.gsub!(/[- \.]*$/,    '')
      @version.upcase!
    end

    def is_compatible_with?(other_version)
      self.version == other_version ||
      COMPATIBILITY_720P[self.version] == other_version ||
      COMPATIBILITY_720P[other_version] == self.version
    end

    def is_more_popular_than?(other_subtitle)
      return true  if other_subtitle.nil?
      return false if other_subtitle.is_featured?
      return self.downloads > other_subtitle.downloads
    end

  end
end
