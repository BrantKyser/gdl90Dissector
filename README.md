# gdl90Dissector
Wireshark Dissector for GDL 90 Messages

Launch Wireshark with the following to use this dissector
```bash
$ wireshark -X lua_script:gdl90Dissector.lua
```
On Windows you can install the Lua file to an appropriate plugin directory, e.g. `C:\Program Files\Wireshark\plugins\2.0.4\gdl90`. Once installed, restart Wireshark or reload Lua plugins with Analyze->Reload Lua Plugins (Ctrl+Shift+L).

[GDL 90 Data Interface Specification](http://www.faa.gov/nextgen/programs/adsb/wsa/media/GDL90_Public_ICD_RevA.PDF)
