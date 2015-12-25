require 'rubygems/package'
require 'pathname'

module Tarchiver
  class Archiver

    def self.archive(archive_input, output_directory='.', opts={})
      messages = Tarchiver::Constants::MESSAGES
      # Sanitize input
      options = Tarchiver::Helpers.sanitize_options(Tarchiver::Constants::DEFAULT_ARCHIVE_OPTIONS.merge(opts))
      archive_name, relative_to, to_archive = Tarchiver::Helpers.sanitize_input(archive_input, options)

      return Tarchiver::Helpers.terminate(nil, options) unless archive_name
      archive_path = ::File.join(output_directory, archive_name)
      
      # Prepare for tarballing
      puts messages[:start_archiving] if options[:verbose]
      puts messages[:start_tarballing] if options[:verbose]
      Tarchiver::Helpers.prepare_for_tarchiving(archive_path)
      tar_path = Tarchiver::Tarballer.tar(to_archive, archive_name, relative_to, output_directory, options)
      
      # Return on failure
      return Tarchiver::Helpers.terminate(nil, options) unless tar_path
      
      puts messages[:done] if options[:verbose]

      # Intermittent cleanup
      Tarchiver::Helpers.cleanup(archive_input, nil, options)
      
      # Return if no compression was requested
      
      return tar_path if options[:archive_type] == :tar
      
      # Compress
      puts messages[:start_compressing] if options[:verbose]
      compressed_archive_path = options[:compressor].compress(archive_path, tar_path, options)
      puts messages[:done] if options[:verbose]
      
      # Cleanup
      puts messages[:start_cleaning] if options[:verbose]
      Tarchiver::Helpers.cleanup(archive_input, tar_path, options)
      puts messages[:done] if options[:verbose]
      puts messages[:completed_archiving] if options[:verbose]
      
      # Return
      ::File.exists?(compressed_archive_path) ? compressed_archive_path : Tarchiver::Helpers.terminate(nil, options)
    end # archive
    
    def self.unarchive(archive, output_directory='.', opts={})
      options = Tarchiver::Constants::DEFAULT_UNARCHIVE_OPTIONS.merge(opts)
      archive_type = Tarchiver::Helpers.determine_archive_type(archive)
      begin
        io = case archive_type 
        when :tar
          ::File.open(archive)
        when :compressed
          options[:compressor].open(archive)
        end
      
      Gem::Package::TarReader.new(io) do |tar|
        tar.each do |entry|
         dir = ::File.join(output_directory, ::File.dirname(entry.full_name))
         path = ::File.join(output_directory, entry.full_name)
         if entry.directory?
           FileUtils.mkdir_p(dir, mode: entry.header.mode, verbose: false)
         elsif entry.header.typeflag == '2' #Symlink!
            ::File.symlink(entry.header.linkname, path) 
         elsif entry.file?
           FileUtils.mkdir_p(dir, verbose: false) unless ::File.directory?(dir)
           ::File.open(path, "wb") do |file|
             while buffer = entry.read(options[:blocksize])
               file.write(buffer)
             end
           end
           FileUtils.chmod(entry.header.mode, path, verbose: false)
         end
        end
      end
      ::File.delete(archive) if ::File.exists?(archive) && options[:delete_input_on_success]
      output_directory
      rescue => error
       puts "#{messages[:failed_archiving]}\n#{error.message}" if options[:verbose]
       Tarchiver::Helpers.terminate(error, options)
      end
    end #unarchive

  end # Archiver
  
end # Tarchiver