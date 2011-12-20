module EasyMeCab

  class MeCab
  
    def initialize(option)
      @path = "d:/MeCab/bin/mecab.exe" # MeCab‚Ö‚ÌƒpƒX
      @option = option
    end
  
    def parse_f(s)
      cmd_string = [@path, @option, s].join(" ")
      word_list = []
      io = IO.popen(cmd_string, "r")
      until io.eof?
        word_list.concat io.gets.split(' ')
      end
      return word_list
    end

    def parse_s(s)
      cmd_string = [@path, @option, s].join(" ")
      word_list = []
      io = IO.popen(cmd_string, "r")
      until io.eof?
        word_list.concat io.gets.split(' ')
      end
      return word_list
    end

  end

end