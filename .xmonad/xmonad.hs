-- -*- haskell -*-
import Monad (liftM)
import XMonad
import XMonad.Core
import System.Exit
import qualified XMonad.StackSet as W
import qualified Data.Map        as M
import XMonad.Layout.Tabbed
import XMonad.Layout.ResizableTile
import XMonad.Layout.Grid
import XMonad.Layout.Magnifier
import XMonad.Layout.TabBarDecoration
import XMonad.Layout.NoBorders
import XMonad.Actions.CycleWS
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.EwmhDesktops
import XMonad.Actions.DwmPromote
import XMonad.Actions.UpdatePointer
import XMonad.Hooks.UrgencyHook
import XMonad.Util.Run (spawnPipe)
import System.IO 
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Util.WorkspaceCompare
import XMonad.Util.EZConfig
import XMonad.Actions.Warp
import Data.Ratio
import XMonad.Hooks.ManageDocks

myTerminal      = "urxvt"
myScreenLock    = "/usr/bin/gnome-screensaver-command -l"
myBorderWidth   = 1
myModMask       = mod4Mask
myNumlockMask   = mod2Mask
myWorkspaces    = ["α", "β" ,"γ", "δ", "ε", "ζ", "η", "θ", "ι"] 
myNormalBorderColor  = "#111"
myFocusedBorderColor = "cadetblue3"
 
myKeys = \conf -> mkKeymap conf $
                [ ("M-S-<Return>", spawn $ XMonad.terminal conf)
                , ("C-S-<Esc>",    spawn $ myScreenLock)
                , ("M-C-<Esc>",    spawn $ "xkill")
                , ("M-<Space>",    sendMessage NextLayout)
                , ("M-S-<Space>",  setLayout $ XMonad.layoutHook conf)
                , ("M-n",          refresh)
                , ("M-S-c",        kill)
                , ("M-<Tab>",      windows W.focusDown)
                , ("M-k",          windows W.focusDown)
                , ("M-S-<Tab>",    windows W.focusUp)
                , ("M-j",          windows W.focusUp)
                , ("M-m",          windows W.focusMaster)
                , ("M-S-k",        windows W.swapDown)
                , ("M-S-j",        windows W.swapUp)
                , ("M-b",          sendMessage ToggleStruts)
                , ("M-h",          sendMessage Shrink)
                , ("M-l",          sendMessage Expand)
                , ("M-t",          withFocused $ windows . W.sink)
                , ("M-,",          sendMessage (IncMasterN 1))
                , ("M-.",          sendMessage (IncMasterN (-1)))
                , ("M-S-q",        io (exitWith ExitSuccess))
                , ("M-q",          restart "xmonad" True)
                , ("M-p",          shellPrompt oxyXPConfig)
                , ("M-o",          shellPrompt oxyXPConfig)
                , ("M-S-<Right>",  shiftToNext >> nextWS)
                , ("M-S-<Left>",   shiftToPrev >> prevWS) 
                , ("M-<Down>",     nextScreen)
                , ("M-S-<Down>",   shiftNextScreen >> nextScreen)
                , ("M-<Left>",     prevNonEmptyWS )
                , ("M-C-k",        prevNonEmptyWS )
                , ("M-<Right>",    nextNonEmptyWS )
                , ("M-C-j",        nextNonEmptyWS )
                , ("M-s",          swapNextScreen)
                , ("M-<Up>",       swapNextScreen)
                , ("M-a",          sendMessage MirrorShrink)
                , ("M-y",          sendMessage MirrorExpand)
                , ("M-<Return>",   dwmpromote)
                , ("M-x M-c",      kill)
                , ("M-x c",        kill)
                , ("M-x M-x",      nextScreen)
                , ("M-u M-x M-x",  swapNextScreen)
                , ("M-x e",        spawn "xemacs")
                , ("M-x f",        spawn "firefox")
                , ("M-x v",        spawn "gvim")
                , ("M-x s",        spawn "env WINEPREFIX=\"/home/mtah/.wine\" wine \"C:\\Program Files\\Spotify\\spotify.exe\"")
                , ("M-x p",        spawn "pidgin")
                , ("M-x t",        spawn "skype")
		, ("M-x n",	   spawn "nautilus")
		, ("M-x <Return>", spawn $ XMonad.terminal conf)
                , ("M-w",          sendMessage MagnifyMore)
                , ("M-e",          sendMessage MagnifyLess)
                , ("M-<",          warpToWindow (1%10) (1%10)) -- Move pointer to currently focused window
                ]
                ++
                [ (m ++ i, windows $ f j)
                    | (i, j) <- zip (map show [1..9]) (XMonad.workspaces conf)
                    , (m, f) <- [("M-", W.view), ("M-S-", W.shift)]
                ]
    where 
      nextNonEmptyWS = moveTo Next (WSIs (liftM (not .) isVisible))
      prevNonEmptyWS = moveTo Prev (WSIs (liftM (not .) isVisible))
 
isVisible :: X (WindowSpace -> Bool)
isVisible = do
  vs <- gets (map (W.tag . W.workspace) . W.visible . windowset)
  return (\w -> (W.tag w) `elem` vs)
 
-- Config for Prompt
oxyXPConfig :: XPConfig
oxyXPConfig = defaultXPConfig { font              = "xft:Consolas-12"
                              , bgColor           = "Aquamarine3"
                              , fgColor           = "black"
                              , fgHLight          = "black"
                              , bgHLight          = "darkslategray4"
                              , borderColor       = "black"
                              , promptBorderWidth = 1
                              , position          = Top
                              , height            = 24
                              , defaultText       = []
                              }
 
myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList $
    -- mod-button1, Set the window to floating mode and move by dragging
    [ ((modMask, button1), (\w -> focus w >> mouseMoveWindow w))
    -- mod-button2, Raise the window to the top of the stack
    , ((modMask, button2), (\w -> focus w >> windows W.swapMaster))
    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modMask, button3), (\w -> focus w >> mouseResizeWindow w))
    -- you may also bind events to the mouse scroll wheel (button4 and button5)
    -- cycle focus
    , ((modMask, button4), (\_ -> windows W.focusUp))
    , ((modMask, button5), (\_ -> windows W.focusDown))
    -- cycle through workspaces
    , ((controlMask .|. modMask, button5), nextNonEmptyWS)
    , ((controlMask .|. modMask, button4), prevNonEmptyWS)
    ]
    where 
      nextNonEmptyWS = \_ -> moveTo Next (WSIs (liftM (not .) isVisible))
      prevNonEmptyWS = \_ -> moveTo Prev (WSIs (liftM (not .) isVisible))
 
myLayout = avoidStruts (tabs ||| tiled ||| Mirror tiled ||| magnify Grid ||| noBorders Full) ||| Full
  where
     -- default tiling algorithm partitions the screen into two panes
     tiled   = ResizableTall nmaster delta ratio []
     -- The default number of windows in the master pane
     nmaster = 1
     -- Default proportion of screen occupied by master pane
     ratio   = 8 % 13
     -- Percent of screen to increment by when resizing panes
     delta   = 3 % 100
     -- tabbed layout
     tabs = tabbed shrinkText oxyDarkTheme
     -- magnification in grid
     magnify = magnifiercz (13%10)
 
-- Configuration for Tabbed
oxyTheme :: Theme
oxyTheme = defaultTheme { inactiveBorderColor = "#000"
                        , activeBorderColor = myFocusedBorderColor
                        , activeColor = "aquamarine3"
                        , inactiveColor = "DarkSlateGray4"
                        , inactiveTextColor = "#222"
                        , activeTextColor = "#222"
                        , fontName = "xft:Consolas-10:bold"
                        , decoHeight = 18
                        , urgentColor = "#000"
                        , urgentTextColor = "#63b8ff"
                        }
 
oxyDarkTheme :: Theme
oxyDarkTheme = defaultTheme { inactiveBorderColor = "#777"
                            , activeBorderColor = myFocusedBorderColor
                            , activeColor = "#000"
                            , inactiveColor = "#444"
                            , inactiveTextColor = "aquamarine4"
                            , activeTextColor = "aquamarine1"
                            , fontName = "xft:Dejavu Sans Mono-8"
                            , decoHeight = 15 
                            , urgentColor = "#000"
                            , urgentTextColor = "#63b8ff"
                        }
 
myManageHook = composeAll
 [ resource  =? "desktop_window"    --> doIgnore
 , title     =? "Wine System Tray"  --> doIgnore ] <+> manageDocks
 
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = False
 
------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.
 
-- Run xmonad with the settings you specify. No need to modify this.
--
main = do
  xmonad $ withUrgencyHook NoUrgencyHook $ defaults
 
defaults = defaultConfig {
      -- simple stuff
        terminal           = myTerminal,
        focusFollowsMouse  = myFocusFollowsMouse,
        borderWidth        = myBorderWidth,
        modMask            = myModMask,
        numlockMask        = myNumlockMask,
        workspaces         = myWorkspaces,
        normalBorderColor  = myNormalBorderColor,
        focusedBorderColor = myFocusedBorderColor,
      -- key bindings
        keys               = myKeys,
        mouseBindings      = myMouseBindings,
      -- hooks, layouts
        layoutHook         = myLayout,
        manageHook         = myManageHook 
    }
