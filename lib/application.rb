require 'rubygems'
require 'hotcocoa'
require 'uri'

require 'lib/pdf_view'
require 'lib/papernet_window'
require 'tempfile'
framework 'webkit'
framework 'quartz'

class Application 
  include HotCocoa
  
  def start
    # It's a developer tool, so enable the web inspector by default.
    NSUserDefaults.standardUserDefaults.registerDefaults("WebKitDeveloperExtras" => true)

    application :name => "Papernet" do |app|
      app.delegate = self
      @windows = []
      create_window
    end
  end
  
  def create_window
    @windows << PapernetWindow.new(self) || @windows.first
  end
  
  def destroy_window(win)
    @windows.delete(win)
  end
  
  def main_papernet_window
    @windows.find{|w| w.isMainWindow}
  end

  # define blank menu handlers for pass-through events


  def on_reload(menu=nil)
    win = main_papernet_window
    win.reload if win
  end
  
  def on_back(menu=nil)
    win = main_papernet_window
    win.back if win
  end
  
  def on_forward(menu=nil)
    win = main_papernet_window
    win.forward if win
  end
  
  # file/open
  # def on_open(menu)
  # end
  
  def on_open_location(menu)
    create_window unless main_papernet_window
    main_papernet_window.focus_location_bar
  end
  
  def on_open_location(menu)
    create_window unless main_papernet_window
    main_papernet_window.focus_location_bar
  end
  
  # file/new 
  def on_new(menu)
    create_window
  end

  def on_close(menu);
    win = main_papernet_window
    win.close if win
  end
  
  def on_show_web_view(menu=nil)
    win = main_papernet_window
    win.show_web_view if win
  end
  
  def on_show_pdf_view(menu=nil)
    win = main_papernet_window
    win.show_pdf_view if win
  end
  
  def on_save_as_pdf(menu=nil)
    win = main_papernet_window
    if win
      dialog = NSSavePanel.new
      dialog.allowedFileTypes = ["pdf"]
      if dialog.runModal == NSOKButton
        win.pdf_pane.document.writeToFile(dialog.filename)
      end
    end
  end    
  
  def on_reset_split_view(menu=nil)
    win = main_papernet_window
    win.reset_split_view if win
  end
  
  # help menu item
  # def on_help(menu)
  #   end
  
  # window/minimize
  def on_minimize(menu)
  end
  
  # window/zoom
  def on_zoom(menu)
  end
  
  # window/bring_all_to_front
  def on_bring_all_to_front(menu)
  end
  
  private
  
  def dlog(message)
    puts '='*80
    puts message
    puts '='*80
  end
end

Application.new.start
