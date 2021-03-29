module RailsBase
  MAJOR = '0'
  MINOR = '4'
  PATCH = '1'
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}"

  def self.print_version
    $stdout.puts VERSION
  end
end
