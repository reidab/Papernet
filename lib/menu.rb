module HotCocoa
  def application_menu
    menu do |main|
      main.submenu :apple do |apple|
        apple.item :about, :title => "About #{NSApp.name}"
        apple.separator
        apple.item :preferences, :key => ","
        apple.separator
        apple.submenu :services
        apple.separator
        apple.item :hide, :title => "Hide #{NSApp.name}", :key => "h"
        apple.item :hide_others, :title => "Hide Others", :key => "h", :modifiers => [:command, :alt]
        apple.item :show_all, :title => "Show All"
        apple.separator
        apple.item :quit, :title => "Quit #{NSApp.name}", :key => "q"
      end
      main.submenu :file do |file|
        file.item :new, :key => "n"
        file.item :open, :key => "o"
        file.item :open_location, :key => "l"
      end
      main.submenu :edit do |edit|
        edit.item :undo, :key => "z", :modifiers => [:command], :action => "undo:"
        edit.item :redo, :key => "z", :modifiers => [:command, :shift], :action => "redo:"
        edit.separator
        edit.item :cut, :key => "x", :action => "cut:"
        edit.item :copy, :key => "c", :action => "copy:"
        edit.item :paste, :key => "v", :action => "paste:"
        edit.item :select_all, :key => 'a', :action => 'selectAll:'
      end
      main.submenu :view do |view|
        view.item :show_web_view, :key => '1'
        view.item :show_pdf_view, :key => '2'
        view.item :reset_split_view, :key => '3'
        view.separator
        view.item :stop, :key => '.'
        view.item :reload, :title => "Reload Page", :key => 'r'
        view.item :back, :key => '['
        view.item :forward, :key => ']'
      end
      main.submenu :window do |win|
        win.item :minimize, :key => "m"
        win.item :zoom
        win.separator
        win.item :bring_all_to_front, :title => "Bring All to Front", :key => "o"
      end
      main.submenu :help do |help|
        help.item :help, :title => "#{NSApp.name} Help"
      end
    end
  end
end
