module RailsBase
  MAJOR = '0'
  MINOR = '41'
  PATCH = '0'
  VERSION = "#{MAJOR}.#{MINOR}.#{PATCH}"

  def self.print_version
    $stdout.puts VERSION
  end
end
