require "yaml"
require "fileutils"
require "tempfile"
require "logger"
require "ruby/plugin"
require "ruby/plugin/util"

module JMA::Plugin
  class Store
    def initialize(config)
      @linkprefix = File.expand_path(config[:linkprefix])
      @root = File.expand_path(config[:root])
      defaultlog = Logger.new(STDOUT)
      defaultlog.level = Logger::DEBUG
      @log = config[:log] || defaultlog
      @log.debug("initialize...")
      if File.exist?(@root)
        @log.debug("found exist store:#{@root}")
        unless File.exist?(File.join(@root,"version"))
          File.open(File.join(@root,"version"),"w") {|io| 
            io.print JMA::Plugin::VERSION 
          }
        end
        version = File.read(File.join(@root,"version"))
        @log.debug("version:#{version}")
      else
        @log.debug("not found exist store")
        @log.debug("create store:#{@root},versioning:#{JMA::Plugin::VERSION}")
        FileUtils.mkdir_p(@root)
        File.open(File.join(@root,"version"),"w") {|io| io.print JMA::Plugin::VERSION }
      end
      unless File.exist?(@linkprefix)
        @log.debug("create linkprefix dir:#{@linkprefix}")
        FileUtils.mkdir_p(@linkprefix)
      end
      
      @cachedir = FileUtils.mkdir_p(File.join(@root,"cache"))
    end

    def install(name,version,path)
      @log.debug("install #{name}-#{version}")
      begin
        tmpdir = JMA::Plugin::Util::extract_tar(path)
        tmpstoredir = File.join(tmpdir,"#{name}-#{version}")
        raise "can not find contents" unless File.exist?(tmpstoredir)
        preinst = File.join(tmpstoredir,"meta","preinst")
        if File.exist?(preinst)
          @log.debug("exec #{preinst}")
          JMA::Plugin::Util::exec_script(preinst,name,version) 
          @log.debug("exec #{preinst} end")
        end

        storedir = File.join(@root,"#{name}-#{version}") 
        # for ruby-1.8.5 FileUtils#mv bug
        #FileUtils.move(tmpstoredir,storedir)
        FileUtils.cp_r(tmpstoredir,@root)

        postinst = File.join(storedir,"meta","postinst")
        if File.exist?(postinst)
          @log.debug("exec #{postinst}")
          JMA::Plugin::Util::exec_script(postinst,name,version)
          @log.debug("exec #{postinst} end")
        end
      rescue Exception => ex
        @log.debug("install failed:" + ex)
        FileUtils.rm_rf(storedir) if storedir
        raise ex
      ensure
        FileUtils.rm_rf(tmpdir) if tmpdir
      end
      @log.debug("install #{name}-#{version} end")
    end

    def uninstall(name, version)
      @log.debug("uninstall #{name}-#{version}")
      begin
        storedir = File.join(@root,"#{name}-#{version}") 
        raise "package #{name}-#{version} is not installed" unless File.exist?(storedir)
        prerm = File.join(storedir,"meta","prerm")
        _postrm = File.join(storedir,"meta","postrm")
        postrm = nil
        if File.exist?(_postrm)
          postrm = Tempfile.new("jma_plugin_postrm",Dir.tmpdir)
          postrm.write(File.read(_postrm))
          postrm.close
          FileUtils.chmod(0755,postrm.path)
        end

        if File.exist?(prerm)
          @log.debug("exec #{prerm}")
          JMA::Plugin::Util::exec_script(prerm,name,version) 
          @log.debug("exec #{prerm} end")
        end

        FileUtils.rm_rf(storedir)
 
        if postrm
          @log.debug("exec #{postrm.path}")
          JMA::Plugin::Util::exec_script(postrm.path,name,version)
          @log.debug("exec #{postrm.path} end")
        end
      rescue Exception => ex
        @log.debug("uninstall failed:" + ex)
        raise ex
      ensure
        postrm.close(true) if postrm
      end
      @log.debug("uninstall #{name}-#{version} end")
    end
 
    def link(name,version)
      @log.debug("link #{name}-#{version}")
      begin
        storedir = File.join(@root,"#{name}-#{version}") 
        raise "package #{name}-#{version} is not installed" unless File.exist?(storedir)
        link = File.join(storedir,"meta","link")
        raise "link file not found:#{link}" unless File.exist?(link)
        dotlinked = File.join(storedir,".linked")
        raise "#{name}-#{version} already linked" if File.exist?(dotlinked)
        list = YAML.load(File.read(link))
        prelink = File.join(storedir,"meta","prelink")
        if File.exist?(prelink)
          @log.debug("exec #{prelink}")
          JMA::Plugin::Util::exec_script(prelink,name,version) 
          @log.debug("exec #{prelink} end")
        end
        linked = []
        begin
          list.each_with_index{|l,i|
              index = i
              from = File.join(storedir,l[0])
              to = File.expand_path(File.join(@linkprefix,l[1]))
              to = File.join(to,File.basename(l[0])) if File.exist?(to)
              unless to.index(@linkprefix) == 0
                raise "invalid link #{l[0]} to #{l[1]}, over linkprefix violation"
              end
              FileUtils.symlink(from,to)
              linked << to
          }
          postlink = File.join(storedir,"meta","postlink")
          if File.exist?(postlink)
            @log.debug("exec #{postlink}")
            JMA::Plugin::Util::exec_script(postlink,name,version) 
            @log.debug("exec #{postlink} end")
          end
        rescue Exception => ex
          linked.each{|f| FileUtils.rm_f(f) }
          raise ex
        end
        FileUtils.touch(dotlinked)
      rescue Exception => ex
        @log.debug("link failed:" + ex)
        raise ex
      end
      @log.debug("link #{name}-#{version} end")
    end

    def unlink(name,version)
      @log.debug("unlink #{name}-#{version}")
      begin
        storedir = File.join(@root,"#{name}-#{version}") 
        raise "package #{name}-#{version} is not installed" unless File.exist?(storedir)
        link = File.join(storedir,"meta","link")
        raise "link file not found:#{link}" unless File.exist?(link)
        dotlinked = File.join(storedir,".linked")
        raise "#{name}-#{version} not linked" unless File.exist?(dotlinked)
        list = YAML.load(File.read(link))
        preunlink = File.join(storedir,"meta","preunlink")
        if File.exist?(preunlink)
          @log.debug("exec #{preunlink}")
          JMA::Plugin::Util::exec_script(preunlink,name,version) 
          @log.debug("exec #{preunlink} end")
        end
        list.each{|l|
          begin
            to = File.expand_path(File.join(@linkprefix,l[1]))
            to = File.join(to,File.basename(l[0])) if File.ftype(to) == "directory"
            unless to.index(@linkprefix) == 0
              raise "invalid link #{l[0]} to #{l[1]}, over linkprefix violation"
            end
            FileUtils.rm_f(to)
          rescue Exception => ex
            next
          end
        }
        FileUtils.rm_f(dotlinked)
        postunlink = File.join(storedir,"meta","postunlink")
        if File.exist?(postunlink)
          @log.debug("exec #{postunlink}")
          JMA::Plugin::Util::exec_script(postunlink,name,version) 
          @log.debug("exec #{postunlink} end")
        end
      rescue Errno::ENOENT => ex
        @log.debug("unlink failed:" + ex)
        raise "#{name}-#{version} not linked"
      rescue Exception => ex
        @log.debug("unlink failed:" + ex)
        raise ex
      end
      @log.debug("unlink #{name}-#{version} end")
    end

    def create_cache_file(fname,data)
      path = File.join(@cachedir,fname)
      FileUtils.rm_f(path) if File.exist?(path)
      File.open(path,"w"){|io|
        io.print(data)
      }
      return path
    end

    def list_file(name,version)
      @log.debug("list_file #{name}-#{version}")
      storedir = File.join(@root,"#{name}-#{version}") 
      raise "package #{name}-#{version} is not installed" unless File.exist?(storedir)
      list = Dir.glob(File.join(storedir,"**","*")).sort.select{|l| File.ftype(l) == "file"}
      @log.debug("list_file #{name}-#{version} end")
      return list
    end

    def list_link(name,version)
      @log.debug("list_link #{name}-#{version}")
      link_list = []
      begin
        storedir = File.join(@root,"#{name}-#{version}") 
        raise "package #{name}-#{version} is not installed" unless File.exist?(storedir)
        raise "package #{name}-#{version} is not linked" unless File.exist?(File.join(storedir,".linked"))
        link = File.join(storedir,"meta","link")
        raise "link file not found:#{link}" unless File.exist?(link)
        list = YAML.load(File.read(link))
        list.each{|l|
          to = File.expand_path(File.join(@linkprefix,l[1]))
          to = File.join(to,File.basename(l[0])) if File.ftype(to) == "directory"
          link_list << to
        }
        link_list.sort!
      rescue Exception => ex
        @log.debug("list_link failed:" + ex)
        raise ex
      end
      @log.debug("list_link #{name}-#{version} end")
      return link_list
    end

    def clean_cache
      Dir.glob(File.join(@cachedir,"*")){|path| FileUtils.rm_f(path)}
    end

  end
end
