module Tarchiver
  
  class Constants
  
    BLOCKSIZE_TO_READ = 1024 * 1000
    
    EXTENSIONS = [:tar, :tgz]
    
    DEFAULT_ARCHIVE_NAME = 'archive'
    
    MESSAGES = {
      input_not_sane: 'Could not make sense of the input. Please check your settings carefully and try again.',
      start_archiving: "Starting archiving...",
      start_tarballing: "Creating tar...",
      start_compressing: "Starting compression...",
      done: "... done.",
      start_cleaning: "Cleaning up...",
      completed_archiving: "Archiving complete.",
      failed_archiving: "Unarchiving failed for the following reason:",
    }
    
    DEFAULT_ARCHIVE_OPTIONS = {
      delete_input_on_success: false,
      blocksize: BLOCKSIZE_TO_READ,
      verbose: false,
      content_only: false,
      relative_to_top_dir: true,
      create_sub_archives: false,
      custom_archive_name: nil,
      archive_type: :tgz,
      compressor: Tarchiver::Gzipper,
      add_timestamp: false,
      raise_errors: false
    }
    
    DEFAULT_UNARCHIVE_OPTIONS = {
      delete_input_on_success: false, 
      blocksize: BLOCKSIZE_TO_READ,
      compressor: Tarchiver::Gzipper,
      verbose: false,
      raise_errors: false
    }
  end
  
end