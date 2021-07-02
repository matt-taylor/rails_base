module RailsBase
  MAJOR = '0'
  MINOR = '52'
  PATCH = '0'
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}"

  def self.print_version
    $stdout.puts VERSION
  end
end
