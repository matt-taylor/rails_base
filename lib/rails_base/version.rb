module RailsBase
  MAJOR = '1'
  MINOR = '0'
  PATCH = '1'
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}"

  def self.print_version
    $stdout.puts VERSION
  end
end
