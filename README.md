[![Build Status](https://travis-ci.org/bartkamphorst/tarchiver.svg?branch=master)](https://travis-ci.org/bartkamphorst/tarchiver)
[![Coverage Status](https://coveralls.io/repos/bartkamphorst/tarchiver/badge.svg?branch=master&service=github)](https://coveralls.io/github/bartkamphorst/tarchiver?branch=master)
[![Gem Version](https://badge.fury.io/rb/tarchiver.png)](http://badge.fury.io/rb/tarchiver)

# Tarchiver

A high-level tar and tgz archiver. Designed for ease of use with acceptable memory footprint (reading and writing in blocks of configurable size).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tarchiver'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install tarchiver

## Usage
### Archiving
```ruby
Tarchiver::Archiver.archive(archive_dir) # outputs archive to working directory
# Returns archive path on success and nil on failure, unless options[:raise_errors] is enabled
Tarchiver::Archiver.archive(archive_dir, output_dir, options)
```
### Unarchiving
```ruby
Tarchiver::Archiver.unarchive(archive_path) # outputs output to working directory
# Returns output path on success and nil on failure, unless options[:raise_errors] is enabled
Tarchiver::Archiver.unarchive(archive_path, unpack_path, options)
```

### Options
```ruby
{
  delete_input_on_success: false,
  blocksize: 1024000,
  verbose: false,
  content_only: false,
  relative_to_top_dir: true,
  custom_archive_name: nil,
  archive_type: :tgz,
  compressor: Tarchiver::Gzipper,
  add_timestamp: false,
  raise_errors: false
}
```
See Tarchiver::Constants.

### Custom Compressor

1. Subclass Tarchiver::Compressor (MyCompressor < Tarchiver::Compressor)
2. Implement `compress` and `open` class methods
3. Set options[:compressor] to MyCompressor
4. Profit

## Contributing

1. Fork it ( https://github.com/bartkamphorst/tarchiver/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
