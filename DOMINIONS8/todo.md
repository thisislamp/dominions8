# TODO list

## Features to add
- Proper design doc/plan (needs vc)
- Basic game features
  - proper main menu
  - settings menu
  - keybinds?
- Multiplayer support
- Dedicated server mode (build?)


## Things to change/refactor

### Misc
- Eventually change window mode settings
  - mode -> viewport
  - aspect -> expand
- Error code translation helper

### UI
- Figure out how to have a background in a not-dumb way
- Work on Console
  - Rework into window
  - Finish command handler system
- Work on DebugMenu
  - rework into window
- Work on CombatLog
  - rework into window
  - Make the checkboxes work
  - Add detail mode
  - Maybe not run as an autoload but added by GameMap
- Flesh out main menu when we actually have things to add to it
- Settings menu
- Fix dumb things in InternalWindow
  - remove name field
  - maybe remove content node field

### Code
- Finish reworking units into BaseUnit
  - Fix (implement) pathing into waypoint checkpoint zones
  - Figure out some way to deal with movement state
- Change debug key stuff to use a Debug something singleton and signals
- Write Logger


## Bugs

### Gameplay
- Tower projectiles can clip a unit to the side but don't disappear
  - Probably only happens in the old version


## Design bikeshed
### TODO

- Spawn controller
  - Should the nexus handle spawns like it does currently?
      - Conclusion: Maybe, it'll be changed to the card system eventually
    - Does this mean there can be only one nexus?
      - Conclusion: Likely, but not certain.
    - Or is there a selection state, e.g. SC2
      - Conclusion: Unlikely, but not impossible.

### Done

- Waypoint system
  - Jump to towers vs line on map
    - Conclusion: change it to line waypoints
- Lanes
  - Are there always going to be three (3) lanes?
    - Conclusion: No
  - Where the Lane enum, if any, lives. (map?)
    - Conclusion: Remove enum
  - How to represent arbitrary lanes
    - Conclusion: Lane node



# Notes
## Execution order
https://www.reddit.com/r/godot/comments/112w2zt/notes_on_event_execution_order_with_a_side_dose/

So today I sat down and decided I was going to work on my player character graphics. Six hours later I had several notes, two bug reports, and far better understanding of Godot's main loop. My player character is still being represented by a 32x32 pixel sketch.

I'll cut right to the meat. Godot's main loop (which I will hereafter refer to as a "frame"), generally speaking, looks like this:

1. For each input event:
  - Call `_input` on every node, bottom to top
  - Call `_unhandled_input` on every node, bottom to top
  - If at any point the event is marked as handled, continue to the next event
2. Calculate how many physics frames we have to process (Possibly none!)
3. For each physics frame:
  - Emit the `physics_frame` signal from the scene tree
  - For each node, sorted first by process priority, then top to bottom:
    - Call `_physics_process`
    - Call `_notification(NOTIFICATION_PHYSICS_PROCESS)`
  - Run all deferred functions (`_draw`, `call_deferred`, `set_deferred`, `queue_free`)
4. Emit the `process_frame` signal from the scene tree
5. For each node, sorted first by process priority, then top to bottom:
  - Call `_process`
  - Call `_notification(NOTIFICATION_PROCESS)`
6. Run all deferred functions (`_draw`, `call_deferred`, `set_deferred`, `queue_free`)


There are several things of note here:
- The order of input -> physics -> process is explicit
- The input-to-process ratio is always 1:1, it's the physics frames that vary in number
- The signals are emitted and resolved before any processes are handled
- The notifications, on the other hand, are woven in after each process call
- Process priority only seems to affect `_process` and `_physics_process`
- Draw can be called multiple times a frame (this was one of the bugs)
- Deferred calls happen multiple times per frame
- You can actually call `set_input_as_handled` on `_unhandled_input`, though you probably shouldn't

I also verified a few other things:

- `_init` is a constructor and happens the moment you call `new` or `instantiate`
- `_ready` happens only once, _after_ `_enter_tree`, which happens as soon as you call `add_child`
- if you call `request_ready`, ready won't trigger until after `_enter_tree` happens again
- `@onready` assignments happen before each individual `_ready` call - they're effectively just shorthand for putting the assignments in your `_ready` function at the very beginning

A curious note about `_ready`: It's commonly understood that `_ready` is, like the input functions, called in reverse order. This is **not** the case. `_ready` is called in *recursive order*. As an example, imagine a tree of 7 nodes: one root with two children, and each of those children have two children of their own. The call order would look like this:

    7
    --3
      --1
      --2
    --6
      --4
      --5

It is, in a sense, top to bottom - it just has recursive requirements. In practice, this makes little difference, but it may be important if you really care about sibling initialization order. Oh, and, incidentally, `_init`'s order is top to bottom.

Finally, some notes about Input.

Generally, all input is front-loaded. I noticed that occasionally mouse positions would shift slightly between `_physics_process` calls (which may actually be a bug), but besides that, all the meat happens at the beginning of the frame. What's interesting is the nature of `Input.is_action_just_pressed` - it seems to remember the pressed state of a given action in the last frame or physics frame, and then compares it to the current pressed state. If it went from up to down, it counts as just pressed. For the inverse, just released.

The reason this is relevant is that, in times of frame rate drops, it's possible to press and release a key between input cycles. This can mean that if you're relying on `Input.is_action_just_pressed` to detect key presses, you can conceivably get dropped inputs.

Input events, however, always process. If you press jump three times between frames, you're getting three input events. Also, within an input function, you don't actually need to rely on the `Input` class to do input checking: You can call `event.is_action_pressed` within `_unhandled_input` to determine if the event corresponds to a given action. As an added bonus, that even catches events bound to the mouse wheel (for those who don't know, the mouse wheel clicks only trigger released events, not pressed events. If you've been confounded by your inability to program a zoom, there's your explanation).

I hope this has been useful to some poor bastard browsing through google trying to figure out when his code is going to actually run. If anybody has questions, I'll try and answer them, even if you're reading this 6 months from now, I'll probably be able to give you an answer.

Now if you'll excuse me, I have a player character sprite to avoid working on.


--------------------------------------------------------------------

