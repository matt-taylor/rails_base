module RailsBase
  MAJOR = '0'
  MINOR = '75'
  PATCH = '5'
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}"

  def self.print_version
    $stdout.puts VERSION
  end
end
