Output output/calculated_attr.gif
Require echo
Require nvim

Set Shell "bash"
Set PlaybackSpeed 1.0
Set TypingSpeed 50ms
Set FontSize 32
Set FontFamily "VictorMono Nerd Font"
Set Width 1200
Set Height 600
Set Theme TokyoNight
Set Padding 0
Hide
Type@1ms "nvim -n calculated_attr.ex" Enter
Sleep 30s
# Type@1ms ":Screenkey" Enter
Show
Type "/:but" Sleep 500ms Enter
Type "oatt"
Hide
Sleep 5s
Show
Sleep 5s Ctrl+Y
Type ":total" Sleep 500ms Ctrl+K
Type ":integer calc" Sleep 5s Ctrl+Y
Type "assigns.price - assigns.discount"
Sleep 5s
