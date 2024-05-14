
#define LAZMOD_VER "1.0.0"
#define MAX_HOOK_ENTITIES 4096

#include <lazmod_ents>
#include <lazmod_msg>
#include <lazmod_stocks>

enum ModStatus {
	LAZMOD_DISABLED = 0,
	LAZMOD_ADMINONLY = 1,
	LAZMOD_ENABLED = 2
}

/**
 * Create an entity and finish other basic stuff in one line.
 * 
 * @param plyClient			Client to assign the owner if needed
 * @param szClass			Classname for entity to create
 * @param szModel			Model name
 * @param vOrigin			Entity will put there after spawn
 * @param vAngles			Entity will set to that angles after spawn
 * 
 * @return 					Entity index, -1 if failed to create entity.
 */
native int LM_CreateEntity(const int plyClient = -1, const char[] szClass, const char[] szModel = "",
							const float vOrigin[3] = NULL_VECTOR, const float vAngles[3] = NULL_VECTOR, const bool bSpawn = false)

/**
 * Get the spawn pos in front of player.
 * 
 * @param plyClient			Client to assign the owner if needed
 * @param vPropOrigin		Origin for new entity to spawn
 */
native int LM_GetFrontSpawnPos(const int plyClient = -1, float vPropOrigin[3])

/**
 * Get aim pos with hit surface angles.
 * 
 * @param plyClient			Client to assign the owner if needed
 * @param vOrigin			Origin of aim pos
 * @param vAngles			Angles of hit surface
 */
native int LM_GetClientAimPosNormal(const int plyClient = -1, float vOrigin[3], float vAngles[3])

/**
 * Register an entity owner.
 * 
 * @param entProp			Entity index.
 * @param plyClient			Client index.
 * @param Doll				Is prop_ragdoll?
 * @return					Ture on success. False on failure.
 */
native bool LM_SetEntOwner(const int entProp, const int plyClient, bool bIsDoll = false)

/**
 * Get an entity owner.
 * 
 * @param entProp			Entity index.
 * @return					-1 on failure. Any other value indicates a Entity index owner.
 */
native int LM_GetEntOwner(const int entProp)

/**
 * Get an entity of owner is equal client.
 * 
 * @param plyClient			Client index.
 * @param entProp			Entity index.
 * @param bIgnoreCvar		Ignore 'lm_nonowner' cvar?
 * @return					True on owner. False on not.
 */
native bool LM_IsEntOwner(const int plyClient, const int entProp, bool bIgnoreCvar = false)

/**
 * Set client props limit.
 *
 * @param plyClient			Client index.
 * @param amount			Amount to increase or decrease. If amount = 0 then set limit to 0.
 * @param Doll				Is prop_ragdoll?
 * @noreturn
 */
native int LM_SetSpawnLimit(const int plyClient, const int iAmount, bool bIsDoll = false)

/**
 * Check client can use BuildMod.
 * 
 * @param plyClient			Client index.
 * @return					True on success. False on failure.
 */
native bool LM_AllowToLazMod(const int plyClient)

/**
 * Check client can use Fly.
 * 
 * @param plyClient			Client index.
 * @return					True on success. False on failure.
 */
native bool LM_AllowFly(const int plyClient)

/**
 * Get client admin.
 * 
 * @param plyClient			Client index.
 * @return					True on admin. False on not.
 */
native bool LM_IsClientAdmin(const int plyClient)

/**
 * Get client aim entity.
 * 
 * @param plyClient			Client index.
 * @param show_message		Show a message when entity invalid?
 * @param included_clients	Allow native to getting clients?
 * @return					-1 on failure. Any other value indicates a Entity index.
 */
native int LM_GetClientAimEntity(const int plyClient, bool show_message = true, bool included_clients = false)

/**
 * Logging commands and args.
 * 
 * @param plyClient			Client index.
 * @param command			Command to log.
 * @param args				Args to log.
 * @noreturn
 */
native void LM_LogCmd(const int plyClient, const char[] command, const char[] args)

/**
 * Check if client is blacklisted.
 *
 * @param plyClient			Client index.
 * @return					True on blacklisted. False on not.
 */
native bool LM_IsBlacklisted(const int plyClient)

/**
 * Check is target client valid.
 *
 * @param plyClient			Client index.
 * @param plyTarget			Target index.
 * @param bIsAlive			Check is target alive.
 * @param plyReply			True to reply the result to target instead.
 * @return					True if target valid. Otherwise false.
 */
native bool LM_IsClientValid(const int plyClient, const int plyTarget, bool bIsAlive = false, bool plyReply = false)
