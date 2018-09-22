import qualified Codec.Binary.UTF8.String as UTF8
import Data.Maybe
import Graphics.X11.ExtraTypes
import System.IO
import System.Exit
--import ViewDoc

import XMonad
import XMonad.Actions.CycleWS
import XMonad.Actions.SpawnOn
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.Place
import XMonad.Hooks.SetWMName
import XMonad.Layout.Fullscreen
import XMonad.Layout.Gaps
import XMonad.Layout.IndependentScreens
import XMonad.Layout.NoBorders
import XMonad.Layout.Spacing
import XMonad.Util.Cursor
import XMonad.Util.EZConfig (additionalKeys)
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.WorkspaceCompare

import qualified XMonad.Hooks.EwmhDesktops as E
import qualified XMonad.StackSet as W
import qualified Data.Map        as M

import qualified DBus as D
import qualified DBus.Client as D

------------------------------------------------------------------------
-- Terminal
-- The preferred terminal program, which is used in a binding below and
-- by certain contrib modules.

myTerminal = "urxvt"
myScreensaver = "/usr/bin/gnome-screensaver-command --lock"
mySelectScreenshot = "select-screenshot"
myScreenshot = "screenshot"
myLauncher = "/home/craigferguson/repos/dotfiles/rofi/menu/run"
mySystemMenu = "/home/craigferguson/repos/dotfiles/rofi/menu/system"

------------------------------------------------------------------------
-- Workspaces
-- The default number of workspaces (virtual screens) and their names.

myWorkspaces = clickable workspaces
  where clickable l =
          [ "<action=xdotool key super+" ++ show i ++ " button=1>" ++ ws ++ "</action>"
          | (i,ws) <- zip ([1..9] ++ [0]) l ]
        workspaces = zipWith makeLabel [1..10] icons
        makeLabel index icon = show index ++ ": <fn=1>" ++ icon : "</fn> "
        icons = [ '\xf269', '\xf120', '\xf121', '\xf128', '\xf128',
                  '\xf128', '\xf128', '\xf128', '\xf1b6', '\xf1bc' ]

------------------------------------------------------------------------
-- Scratchpads
-- The default number of workspaces (virtual screens) and their names.




-----------------------------------------------------------------------
-- Window rules
-- Execute arbitrary actions and WindowSet manipulations when managing
-- a new window. You can use this to, for example, always float a
-- particular program, or have a client always appear on a particular
-- workspace.
--
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.

myManageHook :: ManageHook
myManageHook = manageSpawn
--           <+> manageDocks
--           <+> manageScratchPad
           <+> composeAll [
                 isDialog                        --> placeHook (fixed (0.5, 0.5)),
                 className =? "Firefox"          --> doShift (head myWorkspaces),
                 className =? "Atom"             --> doShift (myWorkspaces !! 2),
                 className =? "Emacs"            --> doShift (myWorkspaces !! 2),
                 className =? "Spotify"          --> doShift (myWorkspaces !! 9),
                 resource  =? "desktop_window"   --> doIgnore,
                 className =? "Gimp"             --> doFloat,
                 className =? "Oblogout"         --> doFloat,
                 className =? "Vlc"              --> doShift (myWorkspaces !! 8),
                 className =? "Zeal"             --> doFloat,
                 isFullscreen                    --> (doF W.focusDown <+> doFullFloat)]

------------------------------------------------------------------------
-- Layouts
-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.

myLayout = myGaps (Tall 10 (3/100) (1/2))
       ||| noBorders (fullscreenFull Full)
  where myGaps = lessBorders OnlyFloat
               . avoidStruts
               . spacing 5
               . gaps [(U,5), (D,5), (R,5), (L,5)]

------------------------------------------------------------------------
-- Colors and borders

--myNormalBorderColor  = "#AD795B"
--myNormalBorderColor  = "#D39A78"
myNormalBorderColor = "#2F343F"
--myNormalBorderColor = "#B8CDD4"
--myNormalBorderColor = "#9aebf9"
myFocusedBorderColor = "#B8CDD4"

-- Color of current window title in xmobar.
xmobarTitleColor = "#FFB6B0"

-- Color of current workspace in xmobar.
xmobarCurrentWorkspaceColor = "#Af745f"
--xmobarCurrentWorkspaceColor = "#58EBED"

myBorderWidth = 3


------------------------------------------------------------------------
-- Key bindings
--
-- modMask lets you specify which modkey you want to use. The default
-- is mod1Mask ("left alt").  You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. The
-- "windows key" is usually mod4Mask.

myModMask = mod4Mask

mySink = "alsa_output.pci-0000_00_1f.3.analog-stereo"

myKeys conf@XConfig {XMonad.modMask = modMask} = M.fromList $ [

    ((modMask, xK_Return),
     spawn $ XMonad.terminal conf),

    ((modMask .|. controlMask, xK_l),
     spawn myScreensaver),

    ((modMask, xK_d),
     spawn myLauncher),

    ((modMask, xK_BackSpace),
     spawn mySystemMenu),

    ((modMask .|. shiftMask, xK_p),
     spawn mySelectScreenshot),

    ((modMask .|. controlMask .|. shiftMask, xK_p),
     spawn myScreenshot)

     -- Multimedia keys
    , ((0, xF86XK_AudioMute), spawn $  "pactl set-sink-mute " ++ mySink ++ " toggle")
    , ((0, xF86XK_AudioLowerVolume), spawn $  "pactl set-sink-mute " ++ mySink ++ " false; pactl set-sink-volume " ++ mySink ++ " -5%")
    , ((0, xF86XK_AudioRaiseVolume), spawn $  "pactl set-sink-mute " ++ mySink ++ " false; pactl set-sink-volume " ++ mySink ++ " +5%")
    , ((0, xF86XK_MonBrightnessDown), spawn "xbacklight -dec 10"),

    ((0, xF86XK_MonBrightnessUp),
     spawn "xbacklight -inc 10"),

    ((0, xF86XK_AudioPrev),
     spawn "playerctl previous"),

    ((0, xF86XK_AudioPlay),
     spawn "playerctl play-pause"),

    ((0, xF86XK_AudioNext),
     spawn "playerctl next"),

    ((modMask .|. shiftMask, xK_Tab), moveToNextNonEmptyNoWrap),

    ((modMask .|. shiftMask .|. mod1Mask, xK_Tab), moveToPrevNonEmptyNoWrap),

    ((modMask, xK_e), moveTo Next EmptyWS),

    ((modMask .|. mod1Mask, xK_w), toggleHDMI),

    -- Bindings for xmonad-session
    -- ((modm, xK_s), toggleSaveState),

    -- ((modm .|. shiftMask, xK_s), launchDocuments),

    ((modMask, xK_q),
     kill),

    -- Cycle through the available layout algorithms
    ((modMask, xK_Right),
     sendMessage NextLayout),

    --  Reset the layouts on the current workspace to default
    ((modMask .|. shiftMask, xK_space),
     setLayout $ XMonad.layoutHook conf),

    -- Resize viewed windows to the correct size
    ((modMask, xK_n),
     refresh),

    -- Move focus to the next window
    ((modMask, xK_Tab),
     windows W.focusDown),

    -- Move focus to the next window
    ((modMask, xK_j),
     windows W.focusDown),

    -- Move focus to the previous window
    ((modMask, xK_k),
     windows W.focusUp),

    -- Move focus to the master window
    ((modMask, xK_m),
     windows W.focusMaster),

    -- Swap the focused window and the master window
    ((modMask .|. shiftMask, xK_Return),
     windows W.swapMaster),

    -- Swap the focused window with the next window
    ((modMask .|. shiftMask, xK_j),
     windows W.swapDown),

    -- Swap the focused window with the previous window
    ((modMask .|. shiftMask, xK_k),
     windows W.swapUp),

    -- Shrink the master area
    ((modMask, xK_h),
     sendMessage Shrink),

    -- Expand the master area
    ((modMask, xK_l),
     sendMessage Expand),

    -- Push window back into tiling
    ((modMask, xK_t),
     withFocused $ windows . W.sink),

    -- Increment the number of windows in the master area
    ((modMask, xK_comma),
     sendMessage (IncMasterN 1)),

    -- Decrement the number of windows in the master area
    ((modMask, xK_period),
     sendMessage (IncMasterN (-1))),

    -- Quit xmonad
    ((modMask .|. shiftMask, xK_F2),
     io exitSuccess),

    -- Restart xmonad
    ((modMask, xK_F2),
     restart "xmonad" True)
  ]
  ++

  -- mod-[1..9], Switch to workspace N
  -- mod-shift-[1..9], Move client to workspace N
  [((m .|. modMask, k), windows $ f i)
      | (i, k) <- zip (XMonad.workspaces conf) ([xK_1 .. xK_9] ++ [xK_0])
      , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]

compareToCurrent :: X (WindowSpace -> Ordering)
compareToCurrent =
    do comp <- getWsCompare
       ws <- gets windowset
       let cur = W.workspace (W.current ws)
       return $ comp (W.tag cur) . W.tag

greaterNonEmptyWs =
    do comp <- compareToCurrent
       return (\w -> comp w == LT && isJust (W.stack w))

lessNonEmptyWs =
    do comp <- compareToCurrent
       return (\w -> comp w == GT && isJust (W.stack w))

moveToNextNonEmptyNoWrap = moveTo Next (WSIs greaterNonEmptyWs)
moveToPrevNonEmptyNoWrap = moveTo Prev (WSIs lessNonEmptyWs)

toggleHDMI = do
  count <- countScreens
  spawn $ "echo " ++ show count ++ " >> ~/test.txt"
  if count > 1
    then spawn "xrandr --output HDMI1 --off"
    else spawn "sleep 0.3; xrandr --output HDMI1 --auto --right-of eDP1"

------------------------------------------------------------------------
-- Mouse bindings
--
-- Focus rules
-- True if your focus should follow your mouse cursor.

myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

myMouseBindings XConfig {XMonad.modMask = modMask} = M.fromList
  [
    -- Set the window to floating mode and move by dragging
    ((modMask, button1),
     \w -> focus w >> mouseMoveWindow w),

    -- Raise the window to the top of the stack
    ((modMask, button2),
       \w -> focus w >> windows W.swapMaster),

    -- Set the window to floating mode and resize by dragging
    ((modMask, button3),
       \w -> focus w >> mouseResizeWindow w)
  ]

------------------------------------------------------------------------
-- Startup hook
-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.

myStartupHook = --spawn "source ~/.fehbg"
            -- spawn "compton --backend glx --vsync opengl -fcCz -l -17 -t -17" --shadow-red 0.35 --shadow-green 0.92 --shadow-blue 0.93" --f
            spawn "compton --backend glx -f" --f
			<+> spawn "$HOME/.config/polybar/start"
            <+> setDefaultCursor xC_left_ptr
            -- <+> spawn "xsetroot -solid '#F5F6F7'"
            -- <+> spawn "xinput --set-prop 13 290 1"
            -- <+> spawn "xinput --set-prop 13 302 0"
            -- <+> spawn "~/bin/libinput-gestures"
            -- <+> spawn "xrandr --output HDMI1 --off"
            -- <+> spawn "xrandr --output HDMI1 --auto --right-of eDP1"
            -- <+> setWMName "LG3D"
            -- <+> spawn "firefox"

-----------------------------------------------------------------------
-- Log hook

main :: IO ()
main = do
    dbus <- D.connectSession
    -- Request access to the DBus name
    D.requestName dbus (D.busName_ "org.xmonad.Log")
        [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]

    xmonad $ def { logHook = dynamicLogWithPP (myLogHook dbus) }

-- Override the PP values as you would otherwise, adding colors etc depending
-- on  the statusbar used
myLogHook :: D.Client -> PP
myLogHook dbus = def { ppOutput = dbusOutput dbus }

-- Emit a DBus signal on log updates
dbusOutput :: D.Client -> String -> IO ()
dbusOutput dbus str = do
    let signal = (D.signal objectPath interfaceName memberName) {
            D.signalBody = [D.toVariant $ UTF8.decodeString str]
        }
    D.emit dbus signal
  where
    objectPath = D.objectPath_ "/org/xmonad/Log"
    interfaceName = D.interfaceName_ "org.xmonad.Log"
    memberName = D.memberName_ "Update"

------------------------------------------------------------------------
-- Run xmonad with all the defaults we set up.

-- main = do
--     xmproc <- spawnPipe "xmobar -d ~/.xmonad/xmobar.hs"
--     xmonad $ docks defaults {
--       logHook = myLogHook xmproc
--     }
--
------------------------------------------------------------------------
-- Combine it all together
-- A structure containing your configuration settings, overriding
-- fields in the default config. Any you don't override, will
-- use the defaults defined in xmonad/XMonad/Config.hs
--
-- No need to modify this.

defaults = def {
    -- simple stuff
    terminal           = myTerminal,
    focusFollowsMouse  = myFocusFollowsMouse,
    borderWidth        = myBorderWidth,
    modMask            = myModMask,
    workspaces         = myWorkspaces,
    normalBorderColor  = myNormalBorderColor,
    focusedBorderColor = myFocusedBorderColor,

    -- key bindings
    keys               = myKeys,
    mouseBindings      = myMouseBindings,

    -- hooks, layouts
    layoutHook         = myLayout,
    manageHook         = myManageHook,
    startupHook        = myStartupHook,
    handleEventHook    = E.fullscreenEventHook
}
