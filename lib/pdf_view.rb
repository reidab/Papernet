HotCocoa::Mappings.map :pdf_view => :PDFView, :framework => :quartz do

 defaults :layout => {}, :frame => DefaultEmptyRect

 def init_with_options(pdf_view, options)
   pdf_view.initWithFrame(options.delete(:frame))
 end

 custom_methods do

   def document=(doc)
     doc = doc.kind_of?(String) ? PDFDocument.alloc.initWithURL(NSURL.alloc.initWithString(doc)) : doc
     setDocument(doc)
   end

 end

end