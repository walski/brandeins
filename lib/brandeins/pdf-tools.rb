module BrandEins
  module PdfTools
    attr_reader :pdf_tools, :pdf_tool

    def self.get_pdf_tool(env = nil)
      @env = Hash.new
      env = Hash.new if env.nil?
      @env[:os] = env[:os] || RUBY_PLATFORM

      @pdf_tools ||= _init_pdf_tools
      @pdf_tool ||= @pdf_tools.first.new if @pdf_tools.length > 0
    end

    class Template
      attr_accessor :cmd, :args, :noop

      def available?
        _cmd_available? @cmd, @noop
      end

      def merge_pdf_files(pdf_files, target_pdf)
        begin
          pdf_files_arg = pdf_files.map {|pdf_file| "'#{pdf_file}'" }.join ' '
          args = self.args.join(' ').gsub(/__pdf_files__/, pdf_files_arg).gsub(/__target_pdf__/, target_pdf)
          puts "executing: #{@cmd} #{args}"
          _exec("#{@cmd} #{args}")
        rescue Exception => e
          puts "error: #{e.inspect}"
          return false
        end
        return true
      end

      private
      def _exec (cmd)
        IO.popen(cmd)# { |f| puts f.gets }
      end

      def _cmd_available? (cmd, args)
        begin
          open("|#{cmd} #{args}").close
        rescue Exception
          return false
        end
        return true
      end
    end

    class TemplateWin < Template; end
    class TemplateOSX < Template; end

    class PdftkOSX < TemplateOSX
      def initialize
        @cmd  = 'pdftk'
        @args = ['__pdf_files__', 'output', '__target_pdf__']
        @noop = ['--version']
      end
    end

    class GhostscriptWin < TemplateWin
      def initialize
        @cmd  = 'gswin64c.exe'
        @args = ['-dNOPAUSE', '-dBATCH', '-sDEVICE=pdfwrite', '-sOutputFile=__target_pdf__', '__pdf_files__']
        @noop = ['--version']
      end
    end

    private
    def self._init_pdf_tools
      @pdf_tools = Array.new
      if @env[:os].include? 'w32'
        return _get_subclasses TemplateWin
      elsif @env[:os].include? 'darwin'
        return _get_subclasses TemplateOSX
      else
        return nil
      end
    end

    def self._get_subclasses(klass)
      classes = []
      klass.subclasses.each do |sklass|
        classes << sklass.new
      end
    end
  end
end

class Class
  def subclasses
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
end