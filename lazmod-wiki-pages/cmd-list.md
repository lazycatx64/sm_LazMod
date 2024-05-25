# Command Lists

Most commands can also be used as Say Commands.\
sm_count -> !count

( ) = Required\
[ ] = Optional

Admin flag can refer to this page: [Adding Admins - AlliedModders Wiki](https://wiki.alliedmods.net/Adding_Admins_(SourceMod)#Levels)

## Player Commands

### Core commands

**Command**|**Permission**|**Usage**|**Description**
-|:-:|-|-
sm_count|all|sm_count|Display current prop count of server and players
sm_version|all|sm_version|Display current version of LazMod
sm_info|all|sm_info|Show info of a prop

### Prop spawning commands

**Command**|**Permission**|**Usage**|**Description**
-|:-:|-|-
sm_spawn|all|sm_spawn (name)|Spawn a physics prop with given spawn name
sm_spawnf|all|sm_spawnf (name)|Spawn a freezed physics prop with given spawn name
sm_spawnd|all|sm_spawnd (name)|Spawn a dynamic prop with given spawn name
sm_spawnragdoll|all|sm_spawnragdoll (name)|Spawn a ragdoll prop with given spawn name
sm_spawnmodel|generic|sm_spawnmodel (model)|Spawn a physics prop with given model name
sm_spawnmodelf|generic|sm_spawnmodelf (model)|Spawn a freezed physics prop with given model name
sm_spawnmodeld|generic|sm_spawnmodeld (model)|Spawn a dynamic prop with given model name
sm_stack|all|sm_stack (amount) [x] [y] [z]|Stacks a prop with given amount and direction
sm_extand|all|sm_extand (amount) [x] [y] [z]|Use sm_extend on first two prop, will create third one by same distance

### Door spawning commands

**Command**|**Permission**|**Usage**|**Description**
-|:-:|-|-
sm_ddoor|all|sm_ddoor (door type\|option)|Spawn a dyamic door and controled by buttons
sm_pdoor|all|sm_pdoor|(WIP) Spawn a regular door

### Prop manipulating commands

**Command**|**Permission**|**Usage**|**Description**
-|:-:|-|-
sm_freezeprop|all|sm_freezeprop|Freezes the prop
sm_unfreezeprop|all|sm_unfreezeprop|Unfreezes the prop
sm_rotate|all|sm_rotate (x) [y] [z]|Rotates the prop by given angle
sm_angles|all|sm_angles (x) [y] [z]|Sets the prop anlges directly
sm_stand|all|sm_stand|Reset the prop anlges to 0
sm_fx|all|sm_fx (fx)|Sets the effect of the prop. [Render FX](https://developer.valvesoftware.com/wiki/Template:KV_Render_FX)
sm_color|all|sm_color (R) [G] [B]|Sets the color of the prop.
sm_alpha|all|sm_alpha (0~255)|Sets the transparency of the prop
sm_move|all|sm_move (X) [Y] [Z]|Moves the prop by given amount
sm_align|all|sm_align (set\|x\|y\|z)|Align the prop by refering another prop's position
sm_center|all|sm_center|Moves a prop to the exact middle of the other two props
sm_nobreak|all|sm_nobreak|(WIP) Makes a prop wont break by damage
sm_unnobreak|all|sm_unnobreak|(WIP) Cancel the effect of no break
sm_skin|all|sm_skin (#)|Change skin of a prop (not every prop have multiple skins)
sm_light|all|sm_light (range) [R] [G] [B] [brightness]|Create a light by given color
sm_setmass|all|sm_setmass (mass)|Set the mass of a prop
sm_scale|all|sm_scale (scale)|(WIP) Scale the model size
sm_weld|all|sm_weld|Weld two props together
sm_setparent|all|sm_setparent|Select a prop to be setparented to
sm_parent|all|sm_parent|Select a prop to be setparented from
sm_clearparent|all|sm_clearparent|Clear parent a prop
sm_setowner|generic|sm_setowner (#id\|name)|Set the owner of a prop
sm_ent_fire|cheats|sm_ent_fire|(WIP) Replicates ent_fire. still working on !activator and other targeting stuff
sm_getname|cheats|sm_getname|Gets prop targetname and classname
sm_input|cheats|sm_input (input) [value]|Calls the input on a prop
sm_output|cheats|sm_output (output) [value]|Sets the output or set keyvalue of a prop

Note: SourceMod uses sm_freeze to freeze players, so we cannot use that.

### Prop removing commands

**Command**|**Permission**|**Usage**|**Description**
-|:-:|-|-
sm_del|all|sm_del|Removes the prop you are looking at
sm_delall|all|sm_delall|Remove all your props
sm_fdelall|all|sm_fdelall (#id\|name)|Force remove a player's props
sm_delr|all|sm_delr|Draw a cube and remove props inside
sm_dels|all|sm_dels|Shoots a beam that pull props in the range and remove them
sm_dels2|all|sm_dels2|Shoots a beam that pull props and players in the range, removes props and kills players

### Prop grabent/copyent commands

**Command**|**Permission**|**Usage**|**Description**
-|:-:|-|-
+grabent|all|+grabent [freeze]|Grabents a prop, if use +grabent 1, prop will also be freezed when released
+copyent|all|+copyent [freeze]|Copyents a prop, if use +copyent 1, prop will also be freezed when released

### SaveSpawn commands

**Command**|**Permission**|**Usage**|**Description**
-|:-:|-|-
sm_ss|all|sm_ss (mode) [name]|The savespawn system
sm_ss|all|sm_ss save (name)|Saves currently spawned props with given name, existing save can be replaced
sm_ss|all|sm_ss load (name)|Loads a save
sm_ss|all|sm_ss info (name)|Shows info of a save
sm_ss|all|sm_ss delete (name)|Delete a save
sm_ss|all|sm_ss list|List all saves you have

### NoKill commands

**Command**|**Permission**|**Usage**|**Description**
-|:-:|-|-
sm_nokill|all|sm_nokill|Enable/disable nokill mode to prevent damages from other player
sm_nokill|generic|sm_nokill (#id\|name) [1/0]|Sets a player's nokill mode

### Movement commands

**Command**|**Permission**|**Usage**|**Description**
-|:-:|-|-
+sprint|all|+sprint|Sprint with 3x speed!
+lightspeed|all|+lightspeed|Sprint with 10x speed!
sm_fly|all|sm_fly|Enables noclip
sm_tp|generic|sm_tp|(WIP) Teleports yourself or other player to target
sm_bring|generic|sm_bring|(WIP) Brings a player to you


## Admin Commands

### Beams

**Command**|**Permission**|**Usage**|**Description**
-|:-:|-|-
sm_deathray|generic|sm_deathray|Shoots an explosive ray
sm_droct|generic|sm_droct|Shoots a beam that pulls everything then push them away

### Blacklist

**Command**|**Permission**|**Usage**|**Description**
-|:-:|-|-
sm_bl|generic|sm_bl (#id\|name)|Add player to LazMod blacklist to prevent them from using LazMod commands
sm_unbl|generic|sm_unbl (#id\|name)|Remove player from blacklist

### Misc

**Command**|**Permission**|**Usage**|**Description**
-|:-:|-|-
sm_team|generic|sm_team (#id\|name) (teamid)|Force a player to join a team
sm_delay|ban|sm_delay (time in sec) (command)|Execute a command after a peroid of time
sm_hurt|ban|sm_hurt (dmg) (range) (type) [classname] [parent]|EXPERIMENTAL: Creates a point_hurt that do damage



