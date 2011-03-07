class PapernetWindow
  include HotCocoa
  
  FULL={:expand => [:width,:height]}
  SHOW=[0,0,0,100]

  def initialize(app, options = {})
    @application = app

    window_options = {:frame => [20, 20, 900, 600], :title => "Papernet"}.merge(options)
    @window = window(window_options) do |win|
      win.cascadeTopLeftFromPoint([20,20])
      win.toolbar = toolbar(:default => [navigation_item, reload_item, location_item, view_item],
                            :display => :icon)

      win.view = @split_view = split_view(:layout => FULL, :frame => SHOW) do |split|
        split.horizontal = false
        split << html_pane
        # split << split_view(:layout => FULL, :frame => SHOW) do |layout|
        #   layout << pdf_options_pane
        #   layout << pdf_pane
        # end
        split << pdf_pane
      end

      NotificationListener.new(:sent_by => @split_view, :named => "NSSplitViewDidResizeSubviewsNotification") do
        splitViewDidResizeSubviews
      end

      reset_split_view

      win.will_close { @application.destroy_window(self) }
    end
  end

  # Pass missing methods along to the underlying hotcocoa window representation
  def method_missing(*args)
    @window.send(*args)
  end

  # Content Areas
  def html_pane
    @html_pane ||= web_view(:layout => FULL) do |web|
      web.url="http://google.com"
      web.frameLoadDelegate=self
      web.setEditingDelegate self
    end
  end

  def pdf_pane
    @pdf_pane ||= pdf_view(:layout => FULL) do |pdf|
      pdf.setAutoScales true
      pdf.delegate = self
    end
  end

  def pdf_options_pane
    @pdf_options_pane ||= view(:frame => [0,0,0,100], :layout => {:expand => :width}) do |pdf_options|
      pdf_options << box(:frame => [0,0,100,50])
    end
  end

  # Toolbar Items
  def navigation_item
    @navigation_item ||= toolbar_item(:label => 'Navigation') do |item|
      # Why do I have to set this manually??
      item.setMinSize [10, 30]
      item.setMaxSize [47, 30]

      item.view = navigation_control
    end
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
          when 0 then back
          when 1 then forward
        end
      end
    end
  end

  def reload_item
    @reload_item ||= toolbar_item(:label => "Reload") do |item|
      item.view = reload_button
      item.setToolTip "Reload Page"
    end
  end

  def reload_button
    @reload_button ||= button(:title => '↻', :bezel => :textured_rounded) {|b| b.on_action{ reload }}
  end

  def location_item
    @location_item ||= toolbar_item(:label => 'Location') do |item|
      item.setMinSize [200, 20]
      item.setMaxSize [5000, 20]
      item.view = location_bar
    end
  end

  def location_bar
    @location_bar ||= text_field(:frame => [0,0,400,20]) do |field|
      field.on_action do |f|
        url = field.stringValue
        url = URI.parse(url).scheme.nil? ? "http://#{url}" : url
        html_pane.url = url
        @window.makeFirstResponder html_pane
      end
    end
  end

  def view_item
    @view_item ||= toolbar_item(:label => 'View') do |item|
      # Why do I have to set this manually??
      item.setMinSize [10, 30]
      item.setMaxSize [150, 30]

      item.view = view_control
    end
  end

  def view_control
    @view_control ||= segmented_control(:segments => [
      {:label => 'Web'},
      {:label => 'Print'},
      {:label => 'Split'}
    ]) do |seg|
      seg.setSelectedSegment 2
      seg.setSegmentStyle NSSegmentStyleTexturedRounded
      seg.on_action do
        case view_control .selected_segment.number
          when 0 then show_web_view
          when 1 then show_pdf_view
          when 2 then reset_split_view
        end
      end
    end
  end

  # Event Handlers
  def show_web_view
    view_control.setSelectedSegment 0
    @split_view.setPosition @split_view.maxPossiblePositionOfDividerAtIndex(0), ofDividerAtIndex:0
  end

  def show_pdf_view
    view_control.setSelectedSegment 1
    @split_view.setPosition @split_view.minPossiblePositionOfDividerAtIndex(0), ofDividerAtIndex:0
  end

  def reset_split_view
    view_control.setSelectedSegment 2
    @split_view.setPosition @split_view.bounds.size.width * (3.0/5.0), ofDividerAtIndex:0
  end

  def reload
    html_pane.reload nil
  end

  def back
    html_pane.goBack
  end

  def forward
    html_pane.goForward
  end

  def focus_location_bar
    @window.makeFirstResponder(location_bar)
  end

  def update_print_view(options = {})
    tmp_print_path = Tempfile.new(["papernet", ".pdf"]).path
    options = {'paginate' => true}.merge(options)

    print_info = NSPrintInfo.sharedPrintInfo
    view_to_print = html_pane.mainFrame.frameView.documentView

    if options['paginate']
      print_info.setJobDisposition NSPrintSaveJob
      print_info.setVerticallyCentered false
      print_info.dictionary.setObject tmp_print_path, forKey:NSPrintSavePath
      print_info.dictionary.setObject "Letter", forKey:NSPrintPaperName
      operation = NSPrintOperation.printOperationWithView view_to_print, printInfo: print_info
      operation.setShowPanels false
      operation.runOperation
      pdf_pane.document = "file://#{tmp_print_path}"
    else
      pdf_data = NSMutableData.new
      operation = NSPrintOperation.PDFOperationWithView(
                    view_to_print,
                    insideRect: view_to_print.bounds,
                    toData: pdf_data,
                    printInfo:print_info
                  )
      operation.runOperation
      pdf_pane.document = PDFDocument.alloc.initWithData(pdf_data)
    end

    File.delete(tmp_print_path)
  end

  # WebView Delegate

  # Update the location bar when we click a link or get redirected
  def webView(webview, didStartProvisionalLoadForFrame:frame)
    if webview == html_pane && frame == webview.mainFrame
      url = frame.provisionalDataSource.request.URL.absoluteString
      location_bar.text = url
    end
  end

  def webView(webview, didFinishLoadForFrame:frame)
    if webview == html_pane && frame == webview.mainFrame
      navigation_control.setEnabled html_pane.canGoBack, forSegment:0
      navigation_control.setEnabled html_pane.canGoForward, forSegment:1
      update_print_view
    end
  end

  def webView(webview, didReceiveTitle:title, forFrame:frame)
    if webview == html_pane && frame == webview.mainFrame
      @window.title = title
    end
  end

  def webViewDidChange
    update_print_view
  end

  # SplitView Delegate
  def splitViewDidResizeSubviews
    if pdf_pane.bounds.size.width == 0.0
      view_control.setSelectedSegment 0
    elsif html_pane.bounds.size.width == 0.0
      view_control.setSelectedSegment 1
    else
      view_control.setSelectedSegment 2
    end
  end

  # PDFView Delegate

  # ZOMG the PDFs NSPrintOperation produces have clickable links in them, so…
  def PDFViewWillClickOnLink(pdfview, withURL:url)
    html_pane.url = url
  end
  
end
