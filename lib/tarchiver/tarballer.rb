module Tarchiver
  class Tarballer
    
    def self.tar(to_archive, archive_name, relative_to, output_directory='.', options)
       archive_path = ::File.join(output_directory, "#{archive_name}.tar")
       enumerable = relative_to.nil?
       begin
         ::File.open(archive_path, "wb") do |file|
           Gem::Package::TarWriter.new(file) do |tar|
             to_archive.each do |entry|
               if enumerable
                 # Enumerable input, determine relative_to on the fly
                 relative_to = ::File.directory?(entry) ? ::File.basename(entry) : ::File.basename(::File.dirname(entry))
               end
               next if entry.match(/\.+$/)
               # if archive_name == Tarchiver::Constants::DEFAULT_ARCHIVE_NAME || options[:relative_to_top_dir] == false
               if options[:relative_to_top_dir] == false
                 path = entry
               else
                 path = entry.match(/#{relative_to}.*/).to_s
                 path = path.match(/#{relative_to}\/(.*)$/)[1] if options[:contents_only]
               end
               mode = ::File.stat(entry).mode
               if ::File.directory?(entry)
                 tar.mkdir(path, mode)
               else
                 tar.add_file(path, mode) do |io|
                   # Read file and write in chunks
                   ::File.open(entry, 'rb') do |file|
                     while buffer = file.read(options[:blocksize])
                       io.write(buffer)
                     end
                   end
                 end
               end
             end
           end
         end
       rescue => error
         puts "Tar could not complete tarring for the following reason:\n#{error.message}" if options[:verbose]
         Tarchiver::Helpers.terminate(error, options)
       end
       archive_path
     end # tar
     
  end
end