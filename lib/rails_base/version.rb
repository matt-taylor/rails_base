module RailsBase
  MAJOR = '0'
  MINOR = '3'
  PATCH = '2'
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}"

  def self.print_version
    $stdout.puts VERSION
  end
end
