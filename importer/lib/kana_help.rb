#
# kana_help.rb
#

module KanaHelp
  
  ### (str) hankaku_kuuhaku : force UTF8 and replace ZENKAKU spaces with hankaku ones
  def hankaku_kuuhaku(str ="")
    return "" if str.length < 1
    return Kconv.toutf8(str).gsub(/\xE3\x80\x80/, " ").strip
  end

  ### (str) quote_zenkaku : quote string in ASCII or zenkaku quotes as appropriate
  def quote_zenkaku(str)
    if str.mbchar? >= 0
      "「" + str + "」"
    else
      "'" + str + "'"
    end
  end

  ### (utf8_str) make_utf8 : converts anything to utf8 using Kconv (iconv library)
  def make_utf8(str)
    return Kconv.toutf8(str.strip)
  end

  def to_utf8_strip(str)
    return Kconv.toutf8((str.nil? ? "" : str).strip)
  end

	module_function :hankaku_kuuhaku, :quote_zenkaku, :make_utf8
end
