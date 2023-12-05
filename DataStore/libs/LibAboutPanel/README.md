
What it does
------------

Lib About Panel is a small library which will add an about panel to your Blizzard interface options. You can specify whether or not to have the panel linked to a main panel, or just have it created separately. It will populate the fields of the about panel from the fields located in your ToC.

Where to get it
---------------

-   [CurseForge] - Often Beta quality
-   [Curse] - Most updated stable version

How to get it to work
---------------------

To create the about panel, just add the following line of code into your
mod:

`LibStub("LibAboutPanel").new(parentframe, addonname)`

It will also return the frame so you can call it like:

`frame = LibStub("LibAboutPanel").new(parentframe, addonname)`

The parentframe option may be nil, in which case it will not anchor the
about panel to any frame. Otherwise, it will anchor the about frame to
that frame.

The second option is the name of your add-on. This is mandatory as the
about panel will pull all information from this add-ons ToC.

The ToC fields which the add-on reads are:

 `"Notes"`  
 `"Version"`  
 `"Author"`  
 `"X-Author-Faction"`  
 `"X-Author-Server"`  
 `"X-Category"`  
 `"X-License"`  
 `"X-Email"`  
 `"X-Website"`  
 `"X-Credits"`  
 `"X-Localizations"`  
 `"X-BugReport"`  

It will only read fields when they exist, and skip them if they do not exist.

Example Code
------------

**ToC File:**

 `## Title: Alt-Tabber`  
 `## Notes: Plays a noise when you're alt-tabbed for a ready check (even when sound is turned off)`  

 `## Author: Ackis`  
 `## X-Author-Server: Fake Server`  
 `## X-Author-Faction: Horde`  
 `## eMail: Fake e-Mail`  
 `## X-License: MIT modified with notification clause`  
  
 `## Interface: 70300`  
 `## Version: 1.2`  
 `## X-Category: Raid`  
 `## X-Localizations: enUS`  
 `## X-Website: `[`http://www.wowwiki.com/AltTabber/`]  
 `## X-Feedback: `[`http://www.curse.com/downloads/details/12774/`]

**Load the panel in LUA code not attached to anything:**

`LibStub("LibAboutPanel").new(nil, "AltTabber")`

**Load the panel in LUA code attached to other panels:**

`self.optionsFrame[L["About"]] = LibStub("LibAboutPanel").new("Ackis Recipe List", "Ackis Recipe List")`

Known Issues
------------
All known issues will be kept at the [CurseForge][1] tracker.

Please use the [CurseForge][1] tracker to file bug reports.

Wish List
---------

Please use the [CurseForge][1] tracker to add suggestions and feature
requests.

Bug Reporting
-------------

Please use the [CurseForge][1] tracker to file bug reports.

  [CurseForge]: http://wow.curseforge.com/projects/libaboutpanel/files/
  [Curse]: http://wow.curse.com/downloads/wow-addons/details/libaboutpanel.aspx
  [`http://www.wowwiki.com/AltTabber/`]: http://www.wowwiki.com/AltTabber/
  [`http://www.curse.com/downloads/details/12774/`]: http://www.curse.com/downloads/details/12774/
  [1]: http://wow.curseforge.com/projects/libaboutpanel/tickets/
