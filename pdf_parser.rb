require 'pdf/reader'

class PdfParser
  
  attr_accessor :content

  def initialize(file)
    content_io=StringIO.new
    receiver=PDF::Reader::TextReceiver.new content_io
    PDF::Reader.file(file, receiver)
    @content=content_io.string
  end
  
  # Called when page parsing starts
  def end_page(arg = nil)
  end

  def show_text(string, *params)
    @content = "" if @content.nil?
    @content << string
  end

  # there's a few text callbacks, so make sure we process them all
  alias :super_show_text :show_text
  alias :move_to_next_line_and_show_text :show_text
  alias :set_spacing_next_line_show_text :show_text

  def show_text_with_positioning(*params)
    params = params.first
    params.each { |str| show_text(str) if str.kind_of?(String)}
  end
end
