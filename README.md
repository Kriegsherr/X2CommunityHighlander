# X2CommunityHighlander

Welcome to the X2CommunityHighlander Github project. This is where the work happens.
This file will be very bare-bones as of now, but should be filled up quickly.

# TODO

* Prepare first release
* Get work done on the Highlander

# What IS the X2CommunityHighlander

A Highlander is a XComGame replacement, which replaces the code of the Vanilla
game, without requiring any ModClassOverrides to do so. As implied by the name,
there can only be one Highlander, so it's important to make a highlander address
as many modding use cases as possible, as well as incorporating bugfixes that
would require class overrides to implement.

The X2CommunityHighlander is built off of the hard work of the Pavonis
Interactive team and their Long War 2 Highlander. We will endeavour to maintain
compatibility with all hooks the Long War 2 depends on, however for now the
Community Highlander and Long War 2 are mutually exclusive because the
LW2 Highlander is built into the mod, and there can only be one.

# Contributing

The base repository has two branches: `master` and `LWReleases` (for now).
Changes to the Community Highlander should be developed on a new branch (which can be a fork) and will be merged into `master`.
Updates to the LWS Highlander will get added to the `LWReleases` branch (which should be renamed), and then merged into `master`.
This should help to ensure that the Highlander stays generally compatible with LW2 and can be used as a replacement Highlander.

## When contributing, please

* use the code style that is generally used in the XCOM 2 codebase:
  * use tabs
  * use new lines for braces
  * use appropriate spacing
  * use braces even for one-line if/else bodies
  
The following code should illustrate all of this:

    static function CompleteStrategyFromTacticalTransfer()
    {
    	local XComOnlineEventMgr EventManager;
    	local array<X2DownloadableContentInfo> DLCInfos;
    	local int i;

    	UpdateSkyranger();
    	CleanupProxyVips();
    	ProcessMissionResults();
    	SquadTacticalToStrategyTransfer();

    	EventManager = `ONLINEEVENTMGR;
    	DLCInfos = EventManager.GetDLCInfos(false);
    	for (i = 0; i < DLCInfos.Length; ++i)
    	{
    		DLCInfos[i].OnPostMission();
    	}
    }

## Documenting your Contributions

Generally Highlander Changes will be weaved through vanilla code in ways that
require us to keep close track of what code changes what vanilla behaviour, and
for what purpose. To do this, we comment code precisely to match with issues
created on Github at:

https://github.com/X2CommunityCore/X2CommunityHighlander/issues

Before committing code it must belong to some issue, either check for an issue
it is relevant to, or create a new issue.

Any code you write should be marked with the issue it addresses, either as
a single line comment, or as a start and end block. Don't forget to mark any
variables added for that issue as well.

    static function CompleteStrategyFromTacticalTransfer()
    {
    	// Variables for Issue #928
    	local XComOnlineEventMgr EventManager;
    	local array<X2DownloadableContentInfo> DLCInfos;
    	local int i;

    	UpdateSkyranger();
    	CleanupProxyVips();
    	ProcessMissionResults(); // Issue #345 - does an extra thing
    	SquadTacticalToStrategyTransfer();

    	EventManager = `ONLINEEVENTMGR;
    	// Start Issue #928
    	DLCInfos = EventManager.GetDLCInfos(false);
    	for (i = 0; i < DLCInfos.Length; ++i)
    	{
    		DLCInfos[i].OnPostMission();
    	}
    	// End Issue #928
    }

We should be able to find every line of code related to an issue by searching
for "Issue #928" (or whatever) through the codebase. In addition, any commits
related to that issue should also have the issue number marked in the same way.

# Building

Building for development and final release requires additional work beyond the
standard build process using ModBuddy, because XComGame replacements only work
with -noseekfreeloading enabled, or what's called a cooked release package.

All references to the root steam directory will made as %STEAMLIBRARY%, you
should replace them with your actual steam directory, such as: "D:/SteamLibrary"
or whatever.

Most of this information comes from Abe Clancy's excellent post on the Nexus
Forums:

https://forums.nexusmods.com/index.php?/topic/3868395-highlander-mods-modding-native-classes-and-core-packages-xcomgameupk-etc/

It goes into far more detail than this guide if you're interested.

## Using noseekfreeloading

Before using noseekfreeloading a few things need to be done to ensure it
actually runs without crashing.

After you've installed the XCOM 2 SDK, it's important you ensure symlinks from
the main XCOM2 folder point to the same folders within the SDK. Delete the following folders/links if they exist:

```
%STEAMLIBRARY%\steamapps\common\XCOM 2\XComGame\Content
%STEAMLIBRARY%\steamapps\common\XCOM 2\XComGame\Script
%STEAMLIBRARY%\steamapps\common\XCOM 2\Engine\Content
%STEAMLIBRARY%\steamapps\common\XCOM 2\Engine\EditorResources
```

...and then open a command line as an administrator and run the following
commands:

```
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\XComGame\Content" "%STEAMLIBRARY%\steamapps\common\XCOM 2 SDK\XComGame\Content"
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\XComGame\Script" "%STEAMLIBRARY%\steamapps\common\XCOM 2 SDK\XComGame\Script"
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\Engine\Content" "%STEAMLIBRARY%\steamapps\common\XCOM 2 SDK\Engine\Content"
mklink /J "%STEAMLIBRARY%\steamapps\common\XCOM 2\Engine\EditorResources" "%STEAMLIBRARY%\steamapps\common\XCOM 2 SDK\Engine\EditorResources"
```

Finally, you must take some additional steps to ensure the DLC doesn't crash
XCOM whilst using -noseekfreeloading. You have a few options:

- disable the DLC
- remove the cooked maps from the templates, you can do so using a mod zipped in
  this folder (RunUncookedWithDLC.zip)
- copy DLC packages from CookedPCConsole to the uncooked content folder

Ensure while running uncooked you never run DLC armors or promote a spark,
because the game will lock up.

Once you have handled the DLC, you're ready to go. Build the mod as usual
through ModBuddy. The Highlander mod can be loaded uncooked by running XCOM
with the following command (in the command prompt):

```
"%STEAMLIBRARY%\steamapps\common\XCOM 2\Binaries\Win64\Launcher\ModLauncherWPF.exe" -allowconsole -log -autodebug -noseekfreeloading
```

If all goes well, you should get the usual XCOM Launcher, so you can enable
X2CommunityHighlander (and RunUncookedWithDLC if required) and run the game like
normal.

## Cooking a Final Release

### One-time preparation

A few files need to be copied into the SDK for you to successfully cook the
Highlander. Check the folder
`%STEAMLIBRARY%\steamapps\common\XCOM 2\XComGame\CookedPCConsole` 
and copy the following files to
`%STEAMLIBRARY%\steamapps\common\XCOM 2 SDK\XComGame\Published\CookedPCConsole`:

```
GuidCache.upk
GlobalPersistentCookerData.upk
PersistentCookerShaderData.bin
*.tfc
```

### Cooking

Start off building the mod through ModBuddy as per normal. After that, you need
to enter the command line and run the following commands:

```
"%STEAMLIBRARY%\steamapps\common\XCOM 2 SDK\Binaries\Win64\XComGame.exe" make -final_release -full
"%STEAMLIBRARY%\steamapps\common\XCOM 2 SDK\Binaries\Win64\XComGame.exe" CookPackages -platform=pcconsole -final_release -quickanddirty -modcook -sha -multilanguagecook=INT+FRA+ITA+DEU+RUS+POL+KOR+ESN -singlethread
```

The process will create a cooked pair of files for your XComGame replacement at
`%STEAMLIBRARY%\steamapps\common\XCOM 2 SDK\XComGame\Published\CookedPCConsole`: 
```
XComGame.upk
XComGame.upk.uncompressed_size
```

Copy those files into a folder called `CookedPCConsole` inside the mod's output 
folder. You will need to delete `Script\XComGame.u`, now that we've put the
cooked script file in it's place.

Once you've done all that, the mod should now run in vanilla XCOM. Note that all
logging statements will be stripped from the Cooked version, so don't expect to
see any of your script logs.

Sound like a lot to do manually every time you build? Sure is, so we've put
together a little batch file that will do it all for you. Copy
CookCommunityHighlander.bat to the SteamLibrary folder (the folder that
contains steamapps), and provided both XCOM 2 and the SDK are in that library
you're good to go. You will need to close the extra window that shows for the
two build tasks though.


# Building Against the Highlander

Making new mods against the Highlander needs a small amount of work done to
ensure you can use any new classes or methods implemented. The SDK uses the
contents of `XCOM 2 SDK\Development\SrcOrig` to compile against files not in the
mod itself. 

Backup that folder as it contains the vanilla source files, and then copy the
highlander's Src folder into it. Be aware that if you make a mod that uses any
new functions or variables, it will crash Vanilla XCOM 2, guaranteed.

If your mod uses the methods or functions provided by Long War 2's Highlander,
things should still work fine.
