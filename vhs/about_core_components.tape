Output output/about_core_components.gif
Require echo
Require nvim

Set Shell "bash"
Set PlaybackSpeed 1.0
Set TypingSpeed 50ms
Set FontSize 30
Set FontFamily "VictorMono Nerd Font"
Set Width 1200
Set Height 800
Set Theme TokyoNight
Set Padding 0
Hide
Type@1ms "nvim -n about_core_components.ex" Enter
Sleep 30s
# Type@1ms ":Screenkey" Enter
Show
Sleep 2s
Type "ggjouse Pyro," Enter
Type "comp"
Hide
Sleep 10s
Show
Sleep 1s Ctrl+Y
Type "[SimpleButton]," Enter
Type "css_s" Sleep 1s Ctrl+Y
Type "tailwind" Enter Enter
Type "comp" Sleep 1s Ctrl+Y
Type "comp" Sleep 1s Ctrl+Y
Type ":button d" Sleep 1s Ctrl+Y
Type "at" Sleep 1s Ctrl+Y
Type ":icon_name" Sleep 1s Ctrl+K
Type `:string, default: "arrow-top-right-on-square"` Enter
Type "css" Sleep 1s Ctrl+Y
Type ":wrapper_class" Sleep 1s Ctrl+K
Type `"px-2 py-1"` Enter
Type "temp" Sleep 1s Ctrl+Y
Type "<div class={@wrapper_class}>" Enter
Type "<button class={@class}>" Enter
Type "<%= render_slot(@inner_block) %>" Enter
Type "<.icon name={@icon_name} />" Enter
Type "</button>" Enter
Type "</div>" Escape
Type " f"
Sleep 5s
