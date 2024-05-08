
#define LAZMOD_VER "1.0.0"
#define MAX_HOOK_ENTITIES 4096
#define MSGTAG "\x01[\x04LM\x01]"

#include <lazmod_ents>
#include <lazmod_stocks>

enum ModStatus {
	LAZMOD_DISABLED = 0,
	LAZMOD_ADMINONLY = 1,
	LAZMOD_ENABLED = 2
}

/**
 * Create an entity and finish other basic stuff in one line.
 * Note: Not DispatchSpawn() yet!
 * 
 * @param plyClient			Client to assign the owner if needed
 * @param szClass			Classname for entity to create
 * @param szModel			Model name
 * @param vOrigin			Entity will put there after spawn
 * @param vAngles			Entity will set to that angles after spawn
 * 
 * @return 					Entity index, -1 if failed to create entity.
 */
native int LM_CreateEntity(const int plyClient = -1, const char[] szClass, const char[] szModel = "", const float vOrigin[3] = NULL_VECTOR, const float vAngles[3] = NULL_VECTOR)

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
native bool LM_AllowToLazMod(int plyClient)

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
 * @param bIgnoreCvar		Ignore 'lm_nonowner' cvar?
 * @return					True on owner. False on not.
 */
native bool LM_IsEntityOwner(int plyClient, entProp, bool bIgnoreCvar = false)

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
