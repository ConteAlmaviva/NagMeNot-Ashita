This is functionally equivalent to RubenatorX's NagMeNot addon for Windower, but rewritten using an alternate method for Ashita. When the "For your safety, it is recommended..." message enters your chat log, it hits enter twice; the first time passes through the message in the log, and the second confirms on the default response (No) in the menu. 
Dependencies: The only dependency is the WindowerInput plugin, which I believe is included in Eden's install by default as well as other private servers.

Instructions: Create a folder called nagmenot in Ashita\addons, place `nagmenot.lua` in it, and place the script `nagmenot.txt` in your Ashita\scripts directory. In-game, type `/addon load nagmenot`. 

By default, the addon is enabled when it is loaded, but if you want to temporarily disable it (because you actually do want to set your home point at the mog house) you can type `/nmn off` and then re-enable with `/nmn on` (or just reload the addon).
