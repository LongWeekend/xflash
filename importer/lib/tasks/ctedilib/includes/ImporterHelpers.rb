module ImporterHelpers
  ## Append text to file using sed
  def append_text_to_file(text, filename)
    `sed -e '$a\\
#{text}' #{filename} > #{filename}.tmptmp`
    `cp #{filename}.tmptmp #{filename}` # CP to original file
    File.delete("#{filename}.tmptmp") # Delete temporary file
  end

  ## Prepend text to file using sed
  def prepend_text_to_file(text, filename)
    `sed -e '1i\\
#{text}' #{filename} > #{filename}.tmptmp`
    `cp #{filename}.tmptmp #{filename}` # CP to original file
    File.delete("#{filename}.tmptmp") # Delete temporary file
  end
end
