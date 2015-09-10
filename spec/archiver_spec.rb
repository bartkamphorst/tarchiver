require 'spec_helper'

describe Tarchiver::Archiver do
  
  before(:each) do
    @tmp_dir = Dir.mktmpdir("tarchiver-rspec")
    @unpack_path = File.join(@tmp_dir, 'unpacked')
    FileUtils.mkdir_p(@unpack_path)
  end

  let(:test_dir_src) {File.join(File.dirname(__FILE__), 'fixtures', 'test_dir')}
  let(:archive_dir) {FileUtils.cp_r(test_dir_src, @tmp_dir); File.join(@tmp_dir, 'test_dir')}
  let(:file_path) {File.join(archive_dir, 'deconstructions.txt') }
   
  context "archiving" do
    
    let(:default_options) { Tarchiver::Constants::DEFAULT_ARCHIVE_OPTIONS }
    
    it 'accepts file path input' do
      _, to_archive = Tarchiver::Helpers.send(:sanitize_input, file_path, default_options)
      expect(to_archive).to eq([file_path])
    end

    it 'accepts dir path input' do
      _, to_archive = Tarchiver::Helpers.send(:sanitize_input, archive_dir, default_options)
      expect(to_archive).not_to be_nil
    end
      
    it 'accepts enumerator input' do
      enum = Dir.glob(File.join(archive_dir, '*'))
      _, to_archive = Tarchiver::Helpers.send(:sanitize_input, enum, default_options)
      expect(to_archive).not_to be_nil
    end
    
    it 'adds a timestamp to the archive name' do
      opts = default_options.merge({add_timestamp: true})
      archive_name, _ = Tarchiver::Helpers.send(:sanitize_input, archive_dir, opts)
      expect(archive_name).to match(/test_dir-[0-9]+/)
    end
    
    it 'checks valid blocksize input' do
      [1024, '1024'].each do |bs|
        opts = default_options.merge({blocksize: bs})
        options = Tarchiver::Helpers.send(:sanitize_options, opts)
        expect(options[:blocksize]).to be(1024)
      end
      opts = default_options.merge({blocksize: '1024T'})
      expect{ Tarchiver::Helpers.send(:sanitize_options, opts) }.to raise_error(ArgumentError)
    end
    
    it 'checks validity of archive_type' do
      [:tar, :tgz].each do |type|
        opts = default_options.merge({archive_type: type})
        options = Tarchiver::Helpers.send(:sanitize_options, opts)
        expect(options[:archive_type]).to be(type)
      end
      opts = default_options.merge({archive_type: 'tar.gz', raise_errors: true})
      expect{ Tarchiver::Helpers.send(:sanitize_options, opts) }.to raise_error(ArgumentError)
    end
    
    context "Creating tarball" do
      let(:options) {default_options.merge({archive_type: :tar})}
      
      it 'returns filepath on success' do
        archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, options)
        expect(archive_path).to eq(File.join(@tmp_dir, 'test_dir.tar'))
      end
      
      it 'only includes the top directory of absolute paths' do
        archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, options)
        expect(inspect_archive(archive_path)).to include(/^test_dir.+homer-excited.png$/)  
      end
      
      it 'includes full paths' do
        opts = options.merge({relative_to_top_dir: false})
        archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, opts)
        expect(inspect_archive(archive_path)).to include(/^.*homer-excited.png$/)  
      end
      
      it 'only includes the contents of a directory' do
        opts = options.merge({contents_only: true})
        archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, opts)
        expect(inspect_archive(archive_path)).to include(/^homer-excited.png$/)  
      end
      
      it 'includes symlinks' do
        FileUtils.ln_s(File.join(archive_dir, 'materialist.txt'), File.join(archive_dir, 'symlink_to_materialist.txt'))
        archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, options)
        expect(inspect_archive(archive_path)).to include(/symlink_to_materialist.txt$/)  
        File.unlink(File.join(archive_dir, 'symlink_to_materialist.txt'))
      end
      
      it 'returns nil on failure' do
        archive_path = Tarchiver::Archiver.archive(File.join(archive_dir, 'nonexistent'), @tmp_dir, options)
        expect(archive_path).to be_nil
      end
      
      it 'raises errors if raising is enabled' do
        opts = options.merge({raise_errors: true})
        expect{ Tarchiver::Archiver.archive(File.join(archive_dir, 'nonexistent'), @tmp_dir, opts) }.to raise_error(ArgumentError)
        unwritable_dir = File.join(@tmp_dir, 'unwritable')
        FileUtils.mkdir_p(unwritable_dir, mode: 0600)
        expect{ Tarchiver::Archiver.archive(archive_dir, unwritable_dir, opts) }.to raise_error(Errno::EACCES)
      end
      
      it 'has a custom archive name' do
        opts = options.merge({custom_archive_name: 'rspec-archive'})
        archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, opts)
        expect(archive_path).to eq(File.join(@tmp_dir, 'rspec-archive.tar'))
      end
      
      it 'cleans up the input' do
        opts = options.merge({delete_input_on_success: true})
        dir = archive_dir
        archive_path = Tarchiver::Archiver.archive(dir, @tmp_dir, opts)
        expect(File.exists?(dir)).to be false
      end
      
    end
    
    context "compressing" do
      
      let(:default_options) { Tarchiver::Constants::DEFAULT_ARCHIVE_OPTIONS }
      
      it 'creates a tgz file' do
        archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, default_options)
        expect(archive_path).to eq(File.join(@tmp_dir, 'test_dir.tgz'))
      end
      
      it 'terminates in a controlled way on errors' do
        expect(default_options[:compressor].send(:compress, File.join(@tmp_dir, 'fake_path'), File.join(@tmp_dir, 'fake_path'), default_options)).to be_nil
        opts = default_options.merge({raise_errors: true})
        expect{ opts[:compressor].send(:compress, File.join(@tmp_dir, 'fake_path'), File.join(@tmp_dir, 'fake_path'), opts)}.to raise_error(Errno::ENOENT)
      end
      
      it 'must use a subclass of Compressor' do
        opts = default_options.merge({compressor: Tarchiver::Compressor})
        expect{ Tarchiver::Archiver.archive(archive_dir, @tmp_dir, opts) }.to raise_error(NotImplementedError)
        expect{ Tarchiver::Archiver.unarchive('test_dir.tgz', nil, opts) }.to raise_error(NotImplementedError)
      end
      
      it 'cleans up the tarball' do
        archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, default_options)
        tar_path = File.join(File.dirname(archive_path), 'test_dir.tar')
        expect(File.exists?(tar_path)).to be false
      end
      
      it 'cleans up everything' do
        opts = default_options.merge({delete_input_on_success: true})
        dir = archive_dir
        archive_path = Tarchiver::Archiver.archive(dir, @tmp_dir, opts)
        tar_path = File.join(File.dirname(archive_path), 'test_dir.tar')
        expect(File.exists?(dir)).to be false
        expect(File.exists?(tar_path)).to be false
      end
      
    end

  end
  
  context "unarchiving" do
    
    let(:default_options) { Tarchiver::Constants::DEFAULT_UNARCHIVE_OPTIONS }
    
    it 'reads a tgz' do
      archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, default_options)
      # FileUtils.mkdir_p(unpack_path)
      output = Tarchiver::Archiver.unarchive(archive_path, @unpack_path)
      expect(Dir.glob(File.join(output, '**', '*')).size).to be(8)
    end
    
    it 'reads a tar.gz' do
      archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, default_options)
      tar_gz_path = File.join(File.dirname(archive_path), 'test_dir.tar.gz')
      FileUtils.mv(archive_path, tar_gz_path)
      output = Tarchiver::Archiver.unarchive(tar_gz_path, @unpack_path)
      expect(Dir.glob(File.join(output, '**', '*')).size).to be(8)
    end
    
    it 'reads a tar' do
      opts = default_options.merge({archive_type: :tar})
      archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, opts)
      output = Tarchiver::Archiver.unarchive(archive_path, @unpack_path)
      expect(Dir.glob(File.join(output, '**', '*')).size).to be(8)
    end
    
    it 'writes symlinks' do
      FileUtils.ln_s(File.join(archive_dir, 'materialist.txt'), File.join(archive_dir, 'symlink_to_materialist.txt'))
      archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, default_options)
      output = Tarchiver::Archiver.unarchive(archive_path, @unpack_path)
      skip "TarWriter does not support symlinks. They are included as regular files."
      expect(File.symlink?(File.join(output, 'symlink_to_materialist.txt'))).to be true
    end
    
    it 'cleans up the input' do
      opts = default_options.merge({delete_input_on_success: true})
      archive_path = Tarchiver::Archiver.archive(archive_dir, @tmp_dir, default_options)
      output = Tarchiver::Archiver.unarchive(archive_path, @unpack_path, opts)
      expect(File.exist?(archive_path)).to be false
    end
    
    it 'terminates in a controlled way on errors' do
      output = Tarchiver::Archiver.unarchive('fake_path', @unpack_path)
      expect(output).to be_nil
      opts = default_options.merge({raise_errors: true})
      expect{ output = Tarchiver::Archiver.unarchive('fake_path', @unpack_path, opts)}.to raise_error(NoMethodError)
    end
    
  end
    
  after(:each) do
    FileUtils.remove_entry_secure(@tmp_dir)
  end
  
end