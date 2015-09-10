require 'simplecov'
SimpleCov.start

require 'tarchiver'
require 'tmpdir'

def inspect_archive(archive_path)
  Gem::Package::TarReader.new(File.open(archive_path)) { |tar| return tar.map(&:full_name) }
end