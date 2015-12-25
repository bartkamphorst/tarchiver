module Tarchiver
  class Gzipper < Tarchiver::Compressor
  
    def self.compress(archive_path, tar_path, options)
      tgz_path = "#{archive_path}.tgz"
      begin
        Zlib::GzipWriter.open(tgz_path) do |gz|
          ::File.open(tar_path, "rb") do |tar|
            while buffer = tar.read(options[:blocksize])
              gz.write(buffer)
            end
          end
        end
      rescue => error
        puts "GZip could not complete zipping for the following reason:\n#{error.message}" if options[:verbose]
        return Tarchiver::Helpers.terminate(error, options)
      end
      tgz_path
    end
    
    def self.open(path)
      Zlib::GzipReader.open(path)
    end
    
    
  end  
end