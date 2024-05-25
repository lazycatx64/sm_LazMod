

#include <sourcemod>
#include <sdktools>

#include <vphysics>

#include <lazmod>



int g_iPropCurrent[MAXPLAYERS]
int g_iDollCurrent[MAXPLAYERS]
int g_iServerCurrent
int g_entPropOwner[MAX_HOOK_ENTITIES]

ConVar g_hCvarModEnabled
ConVar g_hCvarAllowNonOwner
ConVar g_hCvarAdminBypassOwner
ConVar g_hCvarAdminBypassAutokick
ConVar g_hCvarMaxPropServer
ConVar g_hCvarMaxPropAdmin
ConVar g_hCvarMaxDollAdmin
ConVar g_hCvarMaxPropPlayer
ConVar g_hCvarMaxDollPlayer

ModStatus g_enCvarModEnabled
bool g_bCvarAllowNonOwner
bool g_bCvarAdminBypassOwner
bool g_bCvarAdminBypassAutokick
int g_iCvarMaxPropServer
int g_iCvarMaxPropAdmin
int g_iCvarMaxDollAdmin
int g_iCvarMaxPropPlayer
int g_iCvarMaxDollPlayer

public Plugin myinfo = {
	name = "LazMod Core",
	author = "LaZycAt, hjkwe654",
	description = "LazMod Core",
	version = LAZMOD_VER,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max) {

	CreateNative("LM_AllowToLazMod",		Native_AllowToLazMod)
	
	CreateNative("LM_CreateEntity",			Native_CreateEntity)
	CreateNative("LM_GetFrontSpawnPos",		Native_GetFrontSpawnPos)
	CreateNative("LM_GetClientAimPosNormal",Native_GetClientAimPosNormal)

	CreateNative("LM_SetEntOwner",			Native_SetEntOwner)
	CreateNative("LM_GetEntOwner",			Native_GetEntOwner)
	CreateNative("LM_IsEntOwner",			Native_IsEntOwner)


	CreateNative("LM_AddClientPropCount",	Native_AddClientSpawnCount)
	CreateNative("LM_GetClientPropCount",	Native_GetClientSpawnCount)
	CreateNative("LM_SetClientPropCount",	Native_SetClientSpawnCount)

	return APLRes_Success
}

public OnPluginStart() {

	g_hCvarModEnabled = CreateConVar("lm_enable", "2", "Enable the LazMod. 2=For All, 1=Admins Only, 0=Disabled.", FCVAR_NOTIFY, true, 0.0, true, 2.0)
	g_hCvarModEnabled.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarModEnabled)

	g_hCvarAllowNonOwner = CreateConVar("lm_allow_nonowner", "0", "Players can control non-owner props (usually map props)", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarAllowNonOwner.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarAllowNonOwner)

	g_hCvarAdminBypassOwner = CreateConVar("lm_admin_bypass_owner", "1", "Admins bypass ownership so they can control all props", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarAdminBypassOwner.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarAdminBypassOwner)

	g_hCvarAdminBypassAutokick = CreateConVar("lm_admin_bypass_autokick", "1", "Admins autokick will disabled automatically when join server.", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarAdminBypassAutokick.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarAdminBypassAutokick)



	g_hCvarMaxPropServer = CreateConVar("lm_maxprop_server", "2000", "Total prop spawn limit including ragdolls. (Cannot exceed engine-defined upper limit)", FCVAR_NOTIFY, true, 0.0)
	g_hCvarMaxPropServer.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMaxPropServer)

	g_hCvarMaxPropAdmin = CreateConVar("lm_maxprop_admin", "2000", "Admin prop spawn limit.", FCVAR_NOTIFY, true, 0.0)
	g_hCvarMaxPropAdmin.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMaxPropAdmin)

	g_hCvarMaxDollAdmin = CreateConVar("lm_maxragdoll_admin", "10", "Admin ragdoll spawn limit.", FCVAR_NOTIFY, true, 0.0)
	g_hCvarMaxDollAdmin.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMaxDollAdmin)

	g_hCvarMaxPropPlayer = CreateConVar("lm_maxprop_player", "700", "Player prop spawn limit.", FCVAR_NOTIFY, true, 0.0)
	g_hCvarMaxPropPlayer.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMaxPropPlayer)

	g_hCvarMaxDollPlayer = CreateConVar("lm_maxragdoll_player", "5", "Player ragdoll spawn limit.", FCVAR_NOTIFY, true, 0.0)
	g_hCvarMaxDollPlayer.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMaxDollPlayer)
	

	RegAdminCmd("sm_version", Command_Version, 0, "Show Lazmod Core version")
	RegAdminCmd("sm_count", Command_SpawnCount, 0, "Show how many entities are you spawned.")
	
	PrintToServer( "LazMod Core loaded!" )
	PrintToServer( "Max Entities %d", GetMaxEntities() )

	
}

public OnMapStart() {
	LM_FirstRun()
	for (int i = 0; i < sizeof(g_entPropOwner); i++)
		g_entPropOwner[i] = -1
}

Hook_CvarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	CvarChanged(convar)
}
void CvarChanged(Handle convar) {
	if (convar == g_hCvarModEnabled)
		g_enCvarModEnabled = view_as<ModStatus>(g_hCvarModEnabled.IntValue)
	else if (convar == g_hCvarAllowNonOwner)
		g_bCvarAllowNonOwner = g_hCvarAllowNonOwner.BoolValue
	else if (convar == g_hCvarAdminBypassOwner)
		g_bCvarAdminBypassOwner = g_hCvarAdminBypassOwner.BoolValue
	else if (convar == g_hCvarAdminBypassAutokick) {
		g_bCvarAdminBypassAutokick = g_hCvarAdminBypassAutokick.BoolValue
		if (g_bCvarAdminBypassAutokick) {
			for (int i = 0; i < MaxClients; i++) {
				if (LM_IsClientValid(i, i) && LM_IsClientAdmin(i))
					DisableAutokick(i)
			}
		}
	}
		
	else if (convar == g_hCvarMaxPropServer)
		g_iCvarMaxPropServer = g_hCvarMaxPropServer.IntValue
	else if (convar == g_hCvarMaxPropAdmin)
		g_iCvarMaxPropAdmin = g_hCvarMaxPropAdmin.IntValue
	else if (convar == g_hCvarMaxDollAdmin)
		g_iCvarMaxDollAdmin = g_hCvarMaxDollAdmin.IntValue
	else if (convar == g_hCvarMaxPropPlayer)
		g_iCvarMaxPropPlayer = g_hCvarMaxPropPlayer.IntValue
	else if (convar == g_hCvarMaxDollPlayer)
		g_iCvarMaxDollPlayer = g_hCvarMaxDollPlayer.IntValue
}

public OnClientPutInServer(int plyClient) {
	if (!g_bCvarAdminBypassAutokick || !LM_IsClientAdmin(plyClient))
		return
		
	DisableAutokick(plyClient)
}
void DisableAutokick(int plyClient = -1) {
	int iUserId = GetClientUserId(plyClient)
	ServerCommand("mp_disable_autokick %d", iUserId)
	LogToGame("[LazMod] Auto-kick disabled for %L", plyClient)
}

public Action Command_Version(plyClient, args) {
	LM_PrintToChat(plyClient, "LazMod Core version: %s", LAZMOD_VER)
	return Plugin_Handled
}

public Action Command_SpawnCount(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient))
		return Plugin_Handled
	
	LM_PrintToChat(plyClient, "Your Limit: %i/%i [Ragdoll: %i/%i]", g_iPropCurrent[plyClient],(LM_IsClientAdmin(plyClient) ? g_iCvarMaxPropAdmin : g_iCvarMaxPropPlayer), g_iDollCurrent[plyClient], (LM_IsClientAdmin(plyClient) ? g_iCvarMaxDollAdmin : g_iCvarMaxDollPlayer))
	LM_PrintToChat(plyClient, "Server Limit: %i/%i (%i/%i edicts)",  g_iServerCurrent, g_iCvarMaxPropServer, GetEntityCount(), LM_GetMaxEdict())
	if (LM_IsClientAdmin(plyClient)) {
		for (int i = 1; i < MaxClients; i++) {
			if (LM_IsClientValid(i, i) && plyClient != i)
				LM_PrintToChat(plyClient, "%N: %i/%i [Ragdoll: %i/%i]", i, g_iPropCurrent[i], (LM_IsClientAdmin(i) ? g_iCvarMaxPropAdmin : g_iCvarMaxPropPlayer), g_iDollCurrent[i], (LM_IsClientAdmin(i) ? g_iCvarMaxDollAdmin : g_iCvarMaxDollPlayer))
		
		}
	}

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_count", szArgs)
	return Plugin_Handled
}



Native_AllowToLazMod(Handle hPlugin, iNumParams) {

	int plyClient = GetNativeCell(1)
	bool bReply = GetNativeCell(2)

	if (!IsClientConnected(plyClient)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not connected.", plyClient)
	}

	switch (g_enCvarModEnabled) {
		case LAZMOD_DISABLED: {
			if (bReply)
				LM_PrintToChat(plyClient, "LazMod is not available or disabled!")
			return false
		}
		case LAZMOD_ADMINONLY: {
			if (!LM_IsClientAdmin(plyClient)) {
				if (bReply)
					LM_PrintToChat(plyClient, "LazMod is not available or disabled.")
				return false
			} else
				return true
		}
		case LAZMOD_ENABLED: {
			return true
		}
	}
	
}



Native_CreateEntity(Handle hPlugin, iNumParams) {
	
	char szClass[32], szModel[128]
	float vOrigin[3], vAngles[3]
	int plyClient
	bool bSpawn

	plyClient = GetNativeCell(1)
	GetNativeString(2, szClass, sizeof(szClass))
	GetNativeString(3, szModel, sizeof(szModel))
	GetNativeArray(4, vOrigin, sizeof(vOrigin))
	GetNativeArray(5, vAngles, sizeof(vAngles))
	bSpawn = GetNativeCell(6)

	if (!LM_CheckMaxEdict()) {
		LM_PrintToAll("TOO MUCH ENTITIES!!!")
		return -2
	}

	if (g_iServerCurrent + 1 > g_iCvarMaxPropServer) {
		if (plyClient == -1)
			LM_PrintToAll("The number of prop has reached the server limit.")
		else
			LM_PrintToChat(plyClient, "The number of prop has reached the server limit.")
		return -3
	}

	int entProp = -1
	entProp = CreateEntityByName(szClass)
	if (entProp == -1)
		return -1

	if (!StrEqual(szModel, "") && !IsModelPrecached(szModel) && PrecacheModel(szModel) == 0) {
		RemoveEdict(entProp)
		return -1
	}
	DispatchKeyValue(entProp, "model", szModel)

	if (plyClient != -1 && !LM_SetEntOwner(entProp, plyClient, StrEqual(szClass, "prop_ragdoll", false))) {
		RemoveEdict(entProp)
		return -4
	}

	if (StrEqual(szClass, "prop_dynamic") || StrEqual(szClass, "prop_dynamic_override"))
		LM_SetEntSolidType(entProp, SOLID_VPHYSICS)

	if (bSpawn)
		DispatchSpawn(entProp)

	TeleportEntity(entProp, vOrigin, vAngles)

	return entProp
}

Native_GetFrontSpawnPos(Handle hPlugin, iNumParams) {
	
	int plyClient = GetNativeCell(1)
	float vClientOrigin[3], vClientAngles[3], vPropOrigin[3], fRadiansX, fRadiansY

	GetClientEyePosition(plyClient, vClientOrigin)
	GetClientEyeAngles(plyClient, vClientAngles)
	
	fRadiansX = DegToRad(vClientAngles[0])
	fRadiansY = DegToRad(vClientAngles[1])
	
	vPropOrigin[0] = vClientOrigin[0] + (100 * Cosine(fRadiansY) * Cosine(fRadiansX))
	vPropOrigin[1] = vClientOrigin[1] + (100 * Sine(fRadiansY) * Cosine(fRadiansX))
	vPropOrigin[2] = vClientOrigin[2] - 20

	SetNativeArray(2, vPropOrigin, sizeof(vPropOrigin))
}

Native_GetClientAimPosNormal(Handle hPlugin, iNumParams) {
	
	int plyClient = GetNativeCell(1)
	float vClientOrigin[3], vClientAngles[3], vOrigin[3], vSurfaceAngles[3]

	GetClientEyePosition(plyClient, vClientOrigin)
	GetClientEyeAngles(plyClient, vClientAngles)
	Handle trace = TR_TraceRayFilterEx(vClientOrigin, vClientAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterOnlyVPhysics)
	if (TR_DidHit(trace)) {
		float vHitNormal[3]
		TR_GetEndPosition(vOrigin, trace)
		TR_GetPlaneNormal(trace, vHitNormal)
		GetVectorAngles(vHitNormal, vSurfaceAngles)
		vSurfaceAngles[0] += 90
	}
	
	SetNativeArray(2, vOrigin, sizeof(vOrigin))
	SetNativeArray(3, vSurfaceAngles, sizeof(vSurfaceAngles))
}
bool TraceEntityFilterOnlyVPhysics(entity, contentsMask) {
    return ((entity > MaxClients) && Phys_IsPhysicsObject(entity))
}




Native_SetEntOwner(Handle hPlugin, iNumParams) {
	int entProp   = GetNativeCell(1)
	int plyClient = GetNativeCell(2)
	bool bIsDoll  = GetNativeCell(3)
	
	if (plyClient == -1) {
		g_entPropOwner[entProp] = -1
		return true
	}

	if (plyClient != -1 && !IsValidEntity(entProp)) {
		g_entPropOwner[entProp] = -1
		ThrowNativeError(SP_ERROR_NATIVE, "Entity id %i is invalid.", entProp)
		return false
	}
		
	if (!LM_IsClientValid(plyClient, plyClient)) {
		g_entPropOwner[entProp] = -1
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not in game.", plyClient)
		return false
	}
		
	if (LM_IsEntPlayer(entProp)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Not allowed to set owner to a player. Client:%i, Ent:%i", plyClient, entProp)
		return false
	}
	
	if (g_entPropOwner[entProp] != -1 && LM_IsClientValid(g_entPropOwner[entProp], g_entPropOwner[entProp]))
		LM_AddClientPropCount(g_entPropOwner[entProp], -1, bIsDoll)

	if (LM_AddClientPropCount(plyClient, 1, bIsDoll))
		g_entPropOwner[entProp] = plyClient
	else
		return false

	return true
}

Native_GetEntOwner(Handle hPlugin, iNumParams) {
	int entProp = GetNativeCell(1)
	if (IsValidEntity(entProp))
		return g_entPropOwner[entProp]
	else {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity id %i is invalid.", entProp)
		return -1
	}
}

Native_IsEntOwner(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)
	int entProp = GetNativeCell(2)
	bool bIngoreCvar = false
	
	if (iNumParams >= 3)
		bIngoreCvar = GetNativeCell(3)
	
	if (LM_IsClientAdmin(plyClient) && g_bCvarAdminBypassOwner)
		return true

	if (LM_GetEntOwner(entProp) == plyClient)
		return true

	if (LM_IsEntPlayer(entProp) && (!LM_IsClientAdmin(plyClient) || !g_bCvarAdminBypassOwner)) {
		LM_PrintToChat(plyClient, "You are not allowed to do this to players!")
		return false
	}

	if (LM_GetEntOwner(entProp) == -1 && (bIngoreCvar || g_bCvarAllowNonOwner))
		return true

	LM_PrintToChat(plyClient, "This prop does not belong to you!")
	return false
}




Native_AddClientSpawnCount(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)
	int iAmount = GetNativeCell(2)
	bool bIsDoll = GetNativeCell(3)
	
	if (bIsDoll) {
		if (LM_IsClientAdmin(plyClient)) {
			if (g_iDollCurrent[plyClient] + iAmount > g_iCvarMaxDollAdmin || g_iPropCurrent[plyClient] + iAmount > g_iCvarMaxPropAdmin) {
				LM_PrintToChat(plyClient, "You have reached the ragdoll spawn limit.")
				return false
			}
		} else {
			if (g_iDollCurrent[plyClient] + iAmount > g_iCvarMaxDollPlayer || g_iPropCurrent[plyClient] + iAmount > g_iCvarMaxPropPlayer) {
				LM_PrintToChat(plyClient, "You have reached the ragdoll spawn limit.")
				return false
			}
		}
		g_iDollCurrent[plyClient] = (g_iDollCurrent[plyClient] + iAmount < 0) ? 0 : g_iDollCurrent[plyClient] + iAmount
	}

	if (LM_IsClientAdmin(plyClient)) {
		if (g_iPropCurrent[plyClient] + iAmount > g_iCvarMaxPropAdmin) {
			LM_PrintToChat(plyClient, "You have reached the prop spawn limit.")
			return false
		}
	} else {
		if (g_iPropCurrent[plyClient] + iAmount > g_iCvarMaxPropPlayer) {
			LM_PrintToChat(plyClient, "You have reached the prop spawn limit.")
			return false
		}
	}
	g_iPropCurrent[plyClient] = (g_iPropCurrent[plyClient] + iAmount < 0) ? 0 : g_iPropCurrent[plyClient] + iAmount
	g_iServerCurrent = (g_iServerCurrent + iAmount < 0) ? 0 : g_iServerCurrent + iAmount
	
	return true
}

Native_GetClientSpawnCount(Handle hPlugin, iNumParams) {
	int plyTarget = GetNativeCell(1)
	bool bIsDoll = GetNativeCell(2)

	if (bIsDoll)
		return g_iDollCurrent[plyTarget]
	else
		return g_iPropCurrent[plyTarget]

}

Native_SetClientSpawnCount(Handle hPlugin, iNumParams) {
	int plyTarget = GetNativeCell(1)
	int iNewValue = GetNativeCell(2)
	bool bIsDoll = GetNativeCell(3)

	if (bIsDoll) {
		g_iServerCurrent          -= g_iDollCurrent[plyTarget] - iNewValue
		g_iPropCurrent[plyTarget] -= g_iDollCurrent[plyTarget] - iNewValue
		g_iDollCurrent[plyTarget]  = iNewValue
	} else {
		g_iServerCurrent          -= g_iPropCurrent[plyTarget] - iNewValue
		g_iPropCurrent[plyTarget]  = iNewValue
	}

	g_iServerCurrent = (iNewValue < 0) ? 0 : iNewValue

}







