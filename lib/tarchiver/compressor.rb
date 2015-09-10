module Tarchiver
  class Compressor
    
    def self.compress(archive_path, tar_path, options)
      raise NotImplementedError
    end

    def self.open(path)
      raise NotImplementedError
    end
    
  end
end