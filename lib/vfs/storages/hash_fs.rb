# 
# Dirty and uneficient In Memory FS, mainly for tests.
# 
module Vfs
  module Storages
    class HashFs < Hash
      # def initialize
      
      def initialize
        super
        self['/'] = {dir: true}
      end
      
      def driver
        self
      end
      
      # 
      # Attributes
      # 
      def attributes path
        base, name = split_path path
      
        # if path == '/'
        #   return {dir: true, file: false}
        # end
        # 
        stat = cd(base)[name]
        attrs = {}
        attrs[:file] = !!stat[:file]
        attrs[:dir] = !!stat[:dir]
        attrs
      rescue Exception
        nil
      end
      
      def set_attributes path, attrs      
        raise 'not supported'
      end
      
      
      # 
      # File
      #       
      def read_file path, &block
        base, name = split_path path
        assert cd(base)[name], :include?, :file
        block.call cd(base)[name][:content]
      end
      
      def write_file path, append, &block
        base, name = split_path path
                    
        os = if append
          file = cd(base)[name]
          file ? file[:content] : ''
        else
          assert_not cd(base), :include?, name
          ''
        end
        callback = -> buff {os << buff}       
        block.call callback

        cd(base)[name] = {file: true, content: os}
      end
      
      def delete_file path
        base, name = split_path path
        assert cd(base)[name], :include?, :file
        cd(base).delete name
      end
      
      # def move_file path
      #   raise 'not supported'
      # end
    
      
      # 
      # Dir
      #
      def create_dir path
        base, name = split_path path
        assert_not cd(base), :include?, name
        cd(base)[name] = {dir: true}
      end
    
      def delete_dir path
        base, name = split_path path        
        assert cd(base)[name], :include?, :dir
        cd(base).delete name
      end      
      
      # def move_dir path
      #   raise 'not supported'
      # end
      
      def each path, &block
        base, name = split_path path
        assert cd(base)[name], :include?, :dir
        cd(base)[name].each do |relative_name, content|
          next if relative_name.is_a? Symbol
          if content[:dir]
            block.call relative_name, :dir
          else
            block.call relative_name, :file
          end
        end
      end
      
      # def upload_directory from_local_path, to_remote_path
      #   FileUtils.cp_r from_local_path, to_remote_path
      # end
      # 
      # def download_directory from_remote_path, to_local_path
      #   FileUtils.cp_r from_remote_path, to_local_path
      # end
      
      
      # 
      # tmp
      # 
      def tmp &block
        tmp_dir = "/tmp_#{rand(10**6)}"
        create_dir tmp_dir
        if block
          begin
            block.call tmp_dir
          ensure
            delete_dir tmp_dir
          end
        else          
          tmp_dir
        end
      end
      
      def to_s
        'hash_fs'
      end
      
      protected
        def assert obj, method, arg          
          raise "#{obj} should #{method} #{arg}" unless obj.send method, arg
        end
        
        def assert_not obj, method, arg
          raise "#{obj} should not #{method} #{arg}" if obj.send method, arg
        end
      
        def split_path path
          parts = path[1..-1].split('/')
          parts.unshift '/'
          name = parts.pop          
          return parts, name
        end
      
        def cd parts
          current = self
          iterator = parts.clone
          while iterator.first
            current = current[iterator.first]
            iterator.shift
          end    
          current
        end
    end
  end
end