require 'pdf/reader'

class PdfParser
  
  attr_accessor :content

  def initialize(file)
    content_io=StringIO.new
    receiver=PDF::Reader::TextReceiver.new content_io
    PDF::Reader.file(file, receiver)
    @content=content_io.string
  end
end
