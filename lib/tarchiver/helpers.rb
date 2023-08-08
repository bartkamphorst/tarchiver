module Tarchiver
  class Helpers
    
    def self.sanitize_input(input, options)
      if input.is_a? Enumerable
        archive_name = self.determine_archive_name(input, :enumerable, options)
        to_archive = input
        relative_to = nil
      elsif ::File.file?(input)
        archive_name = self.determine_archive_name(input, :file, options)
        to_archive = [input]
        relative_to = ::File.basename(input)
      elsif ::File.directory?(input)
        archive_name = self.determine_archive_name(input, :directory, options)
        to_archive = ::Dir.glob(File.join(input, '**', '*'), ::File::FNM_DOTMATCH)
        relative_to = ::File.basename(input)
      else
        terminate(ArgumentError.new(Tarchiver::Constants::MESSAGES[:input_not_sane]), options)
      end
      return archive_name, relative_to, to_archive
    end
    
    def self.sanitize_options(options)
      # Ensure that blocksize is an integer
      options[:blocksize] = Integer(options[:blocksize])
      # Ensure valid archive extension
      terminate(ArgumentError.new, options) unless Tarchiver::Constants::EXTENSIONS.include?(options[:archive_type])
      options
    end
    
    def self.prepare_for_tarchiving(archive_path)
      FileUtils.mkdir_p(File.dirname(archive_path), verbose: false) unless ::File.directory?(::File.dirname(archive_path))
    end
    
    def self.determine_archive_name(input, input_type, options)
      if options[:custom_archive_name]
        return options[:add_timestamp] ? "#{options[:custom_archive_name]}-#{Time.now.to_i}" : options[:custom_archive_name]
      end
      if input_type == :enumerable
        name = Tarchiver::Constants::DEFAULT_ARCHIVE_NAME
      else
        name = ::File.basename(input)
      end
      options[:add_timestamp] ? "#{name}-#{Time.now.to_i}" : name
    end
    
    def self.determine_archive_type(archive)
      if archive.match(/tar$/)
        :tar
      elsif archive.match(/gz$/)
        :compressed
      end
      
    end
    
    def self.cleanup(archive_input, tar_path, options)
      ::File.delete(tar_path) if tar_path && ::File.exist?(tar_path)
      FileUtils.rm_rf(archive_input) if options[:delete_input_on_success]
    end    
    
    def self.terminate(error=nil, options)
      raise error if error && options[:raise_errors]
      nil
    end
    
  end # Helpers
end # Tarchiver
