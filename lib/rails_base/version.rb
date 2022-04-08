module RailsBase
  MAJOR = '0'
  MINOR = '70'
  PATCH = '1'
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}.pre"

  def self.print_version
    $stdout.puts VERSION
  end
end
