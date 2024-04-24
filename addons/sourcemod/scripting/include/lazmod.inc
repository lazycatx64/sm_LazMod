
#define LAZMOD_API_VER 3
#define LAZMOD_VER "1.0.0"
#define MAX_HOOK_ENTITIES 4096
#define MSGTAG "\x01[\x04LM\x01]"

/**
 * Register an entity owner.
 * 
 * @param entProp			Entity index.
 * @param plyClient			Client index.
 * @param Doll				Is prop_ragdoll?
 * @return					Ture on success. False on failure.
 */
native bool LM_SetEntityOwner(entProp, plyClient, bool Doll = false)

/**
 * Get an entity owner.
 * 
 * @param entProp			Entity index.
 * @return					-1 on failure. Any other value indicates a Entity index owner.
 */
native LM_GetEntityOwner(entProp)

/**
 * Set client props limit.
 *
 * @param plyClient			Client index.
 * @param amount			Amount to increase or decrease. If amount = 0 then set limit to 0.
 * @param Doll				Is prop_ragdoll?
 * @noreturn
 */
native LM_SetSpawnLimit(int plyClient, amount, bool Doll = false)

/**
 * Check client can use BuildMod.
 * 
 * @param plyClient			Client index.
 * @return					True on success. False on failure.
 */
native bool LM_AllowToUse(int plyClient)

/**
 * Check client can use Fly.
 * 
 * @param plyClient			Client index.
 * @return					True on success. False on failure.
 */
native bool LM_AllowFly(int plyClient)

/**
 * Get client admin.
 * 
 * @param plyClient			Client index.
 * @return					True on admin. False on not.
 */
native bool LM_IsAdmin(int plyClient)

/**
 * Get client aim entity.
 * 
 * @param plyClient			Client index.
 * @param show_message		Show a message when entity invalid?
 * @param included_clients	Allow native to getting clients?
 * @return					-1 on failure. Any other value indicates a Entity index.
 */
native LM_GetClientAimEntity(int plyClient, bool show_message = true, bool included_clients = false)

/**
 * Get an entity of owner is equal client.
 * 
 * @param plyClient			Client index.
 * @param entProp			Entity index.
 * @param bIngoreCvar		Ingore 'bm_nonowner' cvar?
 * @return					True on owner. False on not.
 */
native bool LM_IsEntityOwner(int plyClient, entProp, bool bIngoreCvar = false)

/**
 * Logging commands and args.
 * 
 * @param plyClient			Client index.
 * @param command			Command to log.
 * @param args				Args to log.
 * @noreturn
 */
native LM_LogCmd(int plyClient, const char[] command, const char[] args)

/**
 * Prints a message with the BuildMod tag.
 *
 * @param plyClient			Client index.
 * @param format			Formatting rules.
 * @param ...				Variable number of format parameters.
 * @noreturn
 */
native LM_PrintToChat(int plyClient, const char[] format, any ...)

/**
 * Prints a message to all clients with the BuildMod tag.
 *
 * @param format			Formatting rules.
 * @param ...				Variable number of format parameters.
 * @noreturn
 */
native LM_PrintToAll(const char[] format, any ...)

/**
 * Add client to blacklist.
 *
 * @param plyClient			Client index.
 * @return					True on success. False on failure.
 */
native LM_AddBlacklist(int plyClient)

/**
 * Remove client from blacklist.
 *
 * @param plyClient			Client index.
 * @return					True on success. False on failure.
 */
native LM_RemoveBlacklist(int plyClient)

/**
 * Check if client is blacklisted.
 *
 * @param plyClient			Client index.
 * @return					True on blacklisted. False on not.
 */
native bool LM_IsBlacklisted(int plyClient)

/**
 * Check is target client valid.
 *
 * @param plyClient			Client index.
 * @param plyTarget			Target index.
 * @param bIsAlive			Check is target alive.
 * @param plyReply			True to reply the result to target instead.
 * @return					True if target valid. Otherwise false.
 */
native bool LM_IsClientValid(int plyClient, int plyTarget, bool bIsAlive = false, bool plyReply = false)

/**
 * Check if a prop is a Func_ prop
 *
 * @param entProp			Entity index.
 * @return					True if func, false otherwise.
 */
native bool LM_IsFuncProp(int entProp)

/**
 * Check if a prop is a Func_ prop
 *
 * @param entProp			Entity index.
 * @return					True if NPC, false otherwise.
 */
native bool LM_IsNpc(int entProp)

/**
 * Check if a prop is a Player
 *
 * @param entProp			Entity index.
 * @return					True if Player, false otherwise.
 */
native bool LM_IsPlayer(int entProp)
