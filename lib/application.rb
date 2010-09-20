require 'rubygems'
require 'hotcocoa'
require 'uri'

require 'lib/pdf_view'
framework 'webkit'
framework 'quartz'

class Application 
  include HotCocoa
  
  FULL={:expand => [:width,:height]}
  SHOW=[0,0,0,100]
  
  def start
    application :name => "Papernet" do |app|
      app.delegate = self
      
      @window = window :frame => [20, 20, 900, 600], :title => "Papernet" do |win|
        
        navigation_item = toolbar_item(:label => 'Navigation') do |item|
          # Why do I have to set this manually??
          item.setMinSize [10, 30]
          item.setMaxSize [47, 30]
          
          item.view = navigation_control
        end
        
        reload_item = toolbar_item(:label => "Reload") do |item|
          item.view = reload_button
          item.setToolTip "Reload Page"
        end
        
        location_item = toolbar_item(:label => 'Location') do |item|
          item.setMinSize [200, 20]
          item.setMaxSize [5000, 20]
          item.view = location_bar
        end
                          
        view_item = toolbar_item(:label => 'View') do |item|
          # Why do I have to set this manually??
          item.setMinSize [10, 30]
          item.setMaxSize [150, 30]
          
          item.view = view_control
        end
        
        win.toolbar = @toolbar = toolbar(:default => [navigation_item, reload_item, location_item, view_item], :display => :icon)
         
        win.view = @split_view = split_view(:layout => FULL, :frame => SHOW) do |split|
          split.delegate = self
          split.horizontal = false
          split << html_pane
          split << pdf_pane
        end
        
        # win.will_close { exit }
      end
    end
  end
  
  def splitViewDidResizeSubviews
    
  end
  
  def on_test_window_stuff(menu)
    NSApp.keyWindow.title = "TEST'D!"
  end
  
  def on_reload(menu=nil)
    html_pane.reload nil
  end
  
  def on_back(menu=nil)
    html_pane.goBack
  end
  
  def on_forward(menu=nil)
    html_pane.goForward
  end
  
  # file/open
  def on_open(menu)
  end
  
  def on_open_location(menu)
    @window.makeFirstResponder location_bar
  end
  
  # file/new 
  def on_new(menu)
  end
  
  def on_show_web_view(menu=nil)
    @split_view.setPosition @split_view.bounds.size.width, ofDividerAtIndex:0
  end
  
  def on_show_pdf_view(menu=nil)
    @split_view.setPosition 0, ofDividerAtIndex:0
  end
  
  def on_reset_split_view(menu=nil)
    @split_view.setPosition @split_view.bounds.size.width / 2, ofDividerAtIndex:0
  end
  
  # help menu item
  def on_help(menu)
  end
  
  # This is commented out, so the minimize menu item is disabled
  #def on_minimize(menu)
  #end
  
  # window/zoom
  def on_zoom(menu)
  end
  
  # window/bring_all_to_front
  def on_bring_all_to_front(menu)
  end
  
  def webView(webview, didStartProvisionalLoadForFrame:frame)
    if webview == html_pane && frame == webview.mainFrame
      url = frame.provisionalDataSource.request.URL.absoluteString
      location_bar.text = url
    end
  end
  
  def html_pane
    @html_pane ||= web_view(:layout => FULL) do |web|
                    web.url="http://google.com"
                    web.frameLoadDelegate=self
                    
                    web.on_notification do |notification|
                      if "WebProgressStartedNotification" == notification.name
                        # location_bar.text = html_pane.mainFrameURL
                      end
                      if "WebProgressFinishedNotification" == notification.name
                        navigation_control.setEnabled html_pane.canGoBack, forSegment:0
                        navigation_control.setEnabled html_pane.canGoForward, forSegment:1
                      end
                      if %w(WebProgressFinishedNotification WebViewDidChangeNotification).include? notification.name
                        print_html_pane
                      end
                    end
                  end
  end
  
  def pdf_pane
    # @pdf_pane ||= web_view(:layout => FULL) do |pdf|
    #                   pdf.mainFrame.loadHTMLString PDF_START, baseURL: nil
    #                   pdf.frameLoadDelegate=self
    #                 end
    @pdf_pane ||= pdf_view(:layout => FULL) do |pdf|
                    pdf.setAutoScales true
                    pdf.delegate = self
                  end
  end
  
  # def print_html_pane_unpaginated
  #   dlog "print_html_pane"
  #   print_info = NSPrintInfo.sharedPrintInfo
  #   
  #   dlog print_info.dictionary
  #   
  #   view_to_print = html_pane.mainFrame.frameView.documentView
  #   pdf_data = NSMutableData.new
  #   operation = NSPrintOperation.PDFOperationWithView view_to_print, insideRect: view_to_print.bounds, toData: pdf_data, printInfo:print_info
  #   # print_operation.setShowPanels false
  #   operation.runOperation
  #   
  #   pdf_pane.mainFrame.loadData pdf_data, MIMEType:'application/pdf', textEncodingName:'utf-8', baseURL:nil
  # end
  
  def print_html_pane
    print_info = NSPrintInfo.sharedPrintInfo
    print_info.setJobDisposition NSPrintSaveJob
    print_info.setVerticallyCentered false
    print_info.dictionary.setObject "/Users/reidab/Desktop/web2.pdf", forKey:NSPrintSavePath
    print_info.dictionary.setObject "Letter", forKey:NSPrintPaperName
    
    view_to_print = html_pane.mainFrame.frameView.documentView
    operation = NSPrintOperation.printOperationWithView view_to_print, printInfo: print_info
    operation.setShowPanels false
    operation.runOperation
    
    pdf_pane.document="file:///Users/reidab/Desktop/web2.pdf"
  end
  
  private
  
  def location_bar
    @location_bar ||= text_field(:frame => [0,0,400,20]) do |field|
                        field.on_action{|f|
                          url = field.stringValue
                          url = URI.parse(url).scheme.nil? ? "http://#{url}" : url
                          html_pane.url = url
                          @window.makeFirstResponder html_pane
                        }
                      end
  end
  
  def reload_button
    @reload_button ||= button(:title => '↻', :bezel => :textured_rounded) {|b| b.on_action{ on_reload }}
  end
  
  def navigation_control
    @navigation_control ||= segmented_control(:segments => [
      {:label => '◀', :width => 20},
      {:label => '▶', :width => 20}
    ]) do |seg|
      seg.setSegmentStyle NSSegmentStyleTexturedRounded
      seg.cell.setTrackingMode NSSegmentSwitchTrackingMomentary
      seg.cell.setToolTip:"Back", forSegment:0
      seg.cell.setToolTip:"Forward", forSegment:1
      
      seg.on_action do
        case navigation_control.selected_segment.number
          when 0 then on_back
          when 1 then on_forward
        end
      end
    end
  end
  
  def view_control
    @view_control ||= segmented_control(:segments => [
      {:label => 'Web'},
      {:label => 'Print'},
      {:label => 'Split'}
    ]) do |seg|
      seg.on_action do
        case view_control .selected_segment.number
          when 0 then on_show_web_view
          when 1 then on_show_pdf_view
          when 2 then on_reset_split_view
        end
      end
    end
  end
  
  def dlog(message)
    puts '='*80
    puts message
    puts '='*80
  end
end

Application.new.start