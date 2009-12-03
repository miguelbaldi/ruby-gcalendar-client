# Unix Console Style
# You can use this module to apply a style on the terminal
#
# <b>DON'T WORK ON WINDOWS (Only on *nix Terminal)</b>

module UnixConsoleStyler
  class StyleNotFoundException < Exception; end

  # Availables Styles
  STYLE = {
      :default    =>    "\033[0m",
    	# styles
    	:bold       =>    "\033[1m",
    	:underline  =>    "\033[4m",
    	:blink      =>    "\033[5m",
    	:reverse    =>    "\033[7m",
    	:concealed  =>    "\033[8m",
    	# font colors
    	:black      =>    "\033[30m",
    	:red        =>    "\033[31m",
    	:green      =>    "\033[32m",
    	:yellow     =>    "\033[33m",
    	:blue       =>    "\033[34m",
    	:magenta    =>    "\033[35m",
    	:cyan       =>    "\033[36m",
    	:white      =>    "\033[37m",
    	# background colors
    	:on_black   =>    "\033[40m",
    	:on_red     =>    "\033[41m",
    	:on_green   =>    "\033[42m",
    	:on_yellow  =>    "\033[43m",
    	:on_blue    =>    "\033[44m",
    	:on_magenta =>    "\033[45m",
    	:on_cyan    =>    "\033[46m",
    	:on_white   =>    "\033[47m" }

  # Methods to use if you want to apply a style
  def UnixConsoleStyler::apply_style(style)
    if STYLE.has_key? style
      STDOUT.write STYLE[style]
    else
      raise StyleNotFoundException, "Style #{style} not found"
    end
  end

end
