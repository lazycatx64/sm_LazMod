

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
ConVar g_hCvarAllowFly
ConVar g_hCvarAdminBypassOwner
ConVar g_hCvarAdminBypassAutokick
ConVar g_hCvarMaxPropServer
ConVar g_hCvarMaxPropAdmin
ConVar g_hCvarMaxRagdollAdmin
ConVar g_hCvarMaxPropPlayer
ConVar g_hCvarMaxRagdollPlayer

ModStatus g_enCvarModEnabled
bool g_bCvarAllowNonOwner
bool g_bCvarAllowFly
bool g_bCvarAdminBypassOwner
bool g_bCvarAdminBypassAutokick
int g_iCvarMaxPropServer
int g_iCvarMaxPropAdmin
int g_iCvarMaxRagdollAdmin
int g_iCvarMaxPropPlayer
int g_iCvarMaxRagdollPlayer

public Plugin myinfo = {
	name = "LazMod Core",
	author = "LaZycAt, hjkwe654",
	description = "LazMod Core",
	version = LAZMOD_VER,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max) {
	RegPluginLibrary("build_test")
	
	CreateNative("LM_CreateEntity",			Native_CreateEntity)
	CreateNative("LM_GetFrontSpawnPos",		Native_GetFrontSpawnPos)
	CreateNative("LM_GetClientAimPosNormal",Native_GetClientAimPosNormal)

	CreateNative("LM_SetEntityOwner",		Native_SetEntityOwner)
	CreateNative("LM_GetEntityOwner",		Native_GetEntityOwner)
	CreateNative("LM_IsEntityOwner",		Native_IsEntityOwner)

	CreateNative("LM_AllowToLazMod",		Native_AllowToLazMod)
	CreateNative("LM_AllowFly",				Native_AllowFly)

	CreateNative("LM_IsClientValid",		Native_IsClientValid)
	CreateNative("LM_IsAdmin",				Native_IsAdmin)

	CreateNative("LM_IsFuncProp", 			Native_IsFuncProp)
	CreateNative("LM_IsNpc",				Native_IsNpc)
	CreateNative("LM_IsPlayer",				Native_IsPlayer)

	CreateNative("LM_SetSpawnLimit",		Native_SetSpawnLimit)
	CreateNative("LM_LogCmd",				Native_LogCmd)
	CreateNative("LM_PrintToChat",			Native_PrintToChat)
	CreateNative("LM_PrintToAll",			Native_PrintToAll)
	CreateNative("LM_GetClientAimEntity",	Native_GetClientAimEntity)

	
	return APLRes_Success
}

public OnPluginStart() {

	g_hCvarModEnabled = CreateConVar("lm_enable", "2", "Enable the LazMod. 2=For All, 1=Admins Only, 0=Disabled.", FCVAR_NOTIFY, true, 0.0, true, 2.0)
	g_hCvarModEnabled.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarModEnabled)

	g_hCvarAllowNonOwner = CreateConVar("lm_allow_nonowner", "0", "Players can control non-owner props (usually map props)", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarAllowNonOwner.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarAllowNonOwner)

	g_hCvarAllowFly = CreateConVar("lm_allow_fly", "1", "Players can use !fly to noclip", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarAllowFly.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarAllowFly)
	
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

	g_hCvarMaxRagdollAdmin = CreateConVar("lm_maxragdoll_admin", "10", "Admin ragdoll spawn limit.", FCVAR_NOTIFY, true, 0.0)
	g_hCvarMaxRagdollAdmin.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMaxRagdollAdmin)

	g_hCvarMaxPropPlayer = CreateConVar("lm_maxprop_player", "700", "Player prop spawn limit.", FCVAR_NOTIFY, true, 0.0)
	g_hCvarMaxPropPlayer.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMaxPropPlayer)

	g_hCvarMaxRagdollPlayer = CreateConVar("lm_maxragdoll_player", "5", "Player ragdoll spawn limit.", FCVAR_NOTIFY, true, 0.0)
	g_hCvarMaxRagdollPlayer.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMaxRagdollPlayer)
	

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
	else if (convar == g_hCvarAllowFly)
		g_bCvarAllowFly = g_hCvarAllowFly.BoolValue
	else if (convar == g_hCvarAdminBypassOwner)
		g_bCvarAdminBypassOwner = g_hCvarAdminBypassOwner.BoolValue
	else if (convar == g_hCvarAdminBypassAutokick) {
		g_bCvarAdminBypassAutokick = g_hCvarAdminBypassAutokick.BoolValue
		if (g_bCvarAdminBypassAutokick) {
			for (int i = 0; i < MaxClients; i++) {
				if (LM_IsClientValid(i, i) && LM_IsAdmin(i))
					DisableAutokick(i)
			}
		}
	}
		
	else if (convar == g_hCvarMaxPropServer)
		g_iCvarMaxPropServer = g_hCvarMaxPropServer.IntValue
	else if (convar == g_hCvarMaxPropAdmin)
		g_iCvarMaxPropAdmin = g_hCvarMaxPropAdmin.IntValue
	else if (convar == g_hCvarMaxRagdollAdmin)
		g_iCvarMaxRagdollAdmin = g_hCvarMaxRagdollAdmin.IntValue
	else if (convar == g_hCvarMaxPropPlayer)
		g_iCvarMaxPropPlayer = g_hCvarMaxPropPlayer.IntValue
	else if (convar == g_hCvarMaxRagdollPlayer)
		g_iCvarMaxRagdollPlayer = g_hCvarMaxRagdollPlayer.IntValue
}

public OnClientPutInServer(int plyClient) {
	if (!g_bCvarAdminBypassAutokick || !LM_IsAdmin(plyClient))
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
	
	LM_PrintToChat(plyClient, "Your Limit: %i/%i [Ragdoll: %i/%i]", g_iPropCurrent[plyClient],(LM_IsAdmin(plyClient) ? g_iCvarMaxPropAdmin : g_iCvarMaxPropPlayer), g_iDollCurrent[plyClient], (LM_IsAdmin(plyClient) ? g_iCvarMaxRagdollAdmin : g_iCvarMaxRagdollPlayer))
	LM_PrintToChat(plyClient, "Server Limit: %i/%i (%i/%i edicts)",  g_iServerCurrent, g_iCvarMaxPropServer, GetEntityCount(), LM_GetMaxEdict())
	if (LM_IsAdmin(plyClient)) {
		for (int i = 1; i < MaxClients; i++) {
			if (LM_IsClientValid(i, i) && plyClient != i)
				LM_PrintToChat(plyClient, "%N: %i/%i [Ragdoll: %i/%i]", i, g_iPropCurrent[i], (LM_IsAdmin(i) ? g_iCvarMaxPropAdmin : g_iCvarMaxPropPlayer), g_iDollCurrent[i], (LM_IsAdmin(i) ? g_iCvarMaxRagdollAdmin : g_iCvarMaxRagdollPlayer))
		
		}
	}

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_count", szArgs)
	return Plugin_Handled
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

	int entProp = -1
	entProp = CreateEntityByName(szClass)
	if (entProp == -1)
		return -1

	if (!StrEqual(szModel, "") && !IsModelPrecached(szModel) && PrecacheModel(szModel) == 0) {
		RemoveEdict(entProp)
		return -1
	}
	DispatchKeyValue(entProp, "model", szModel)

	if (plyClient != -1 && !LM_SetEntityOwner(entProp, plyClient, StrEqual(szClass, "prop_ragdoll", false))) {
		RemoveEdict(entProp)
		return -1
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



Native_SetEntityOwner(Handle hPlugin, iNumParams) {
	int entProp = GetNativeCell(1)
	int plyClient = GetNativeCell(2)
	bool bIsDoll = false
	
	if (iNumParams >= 3)
		bIsDoll = GetNativeCell(3)
	
	if (plyClient == -1) {
		g_entPropOwner[entProp] = -1
		return true
	}

	if (!IsValidEntity(entProp)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity id %i is invalid.", entProp)
		return false
	}
		
	if (!LM_IsClientValid(plyClient, plyClient)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not in game.", plyClient)
		return false
	}
		
	if (LM_IsPlayer(entProp)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Not allowed to set owner to a player. Client:%i, Ent:%i", plyClient, entProp)
		return false
	}
	
	if (!LM_CheckMaxEdict()) {
		LM_PrintToAll("TOO MUCH ENTITIES.")
		return false
	}

	if (g_iServerCurrent >= g_iCvarMaxPropServer) {
		LM_PrintToChat(plyClient, "The number of prop has reached the server limit.")
		return false
	}

	if (bIsDoll) {
		if (g_iDollCurrent[plyClient] < (LM_IsAdmin(plyClient) ? g_iCvarMaxRagdollAdmin : g_iCvarMaxRagdollPlayer)) {
			g_iDollCurrent[plyClient] += 1
			g_iPropCurrent[plyClient] += 1
		} else {
			LM_PrintToChat(plyClient, "Your dolls has reached the limit.")
			return false
		}
	} else {
		if (g_iPropCurrent[plyClient] < (LM_IsAdmin(plyClient) ? g_iCvarMaxPropAdmin : g_iCvarMaxPropPlayer))
			g_iPropCurrent[plyClient] += 1
		else {
			LM_PrintToChat(plyClient, "Your props has reached the limit.")
			return false
		}
	}
	g_entPropOwner[entProp] = plyClient
	g_iServerCurrent += 1
	return true
}

Native_GetEntityOwner(Handle hPlugin, iNumParams) {
	int entProp = GetNativeCell(1)
	if (IsValidEntity(entProp))
		return g_entPropOwner[entProp]
	else {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity id %i is invalid.", entProp)
		return -1
	}
}

Native_SetSpawnLimit(Handle hPlugin, iNumParams) {
	int plyTarget = GetNativeCell(1)
	int iAmount = GetNativeCell(2)
	int bIsDoll = false
	
	if (iNumParams >= 3)
		bIsDoll = GetNativeCell(3)
	
	if (iAmount == 0) {
		if (bIsDoll) {
			g_iServerCurrent -= g_iDollCurrent[plyTarget]
			g_iPropCurrent[plyTarget] -= g_iDollCurrent[plyTarget]
			g_iDollCurrent[plyTarget] = 0
		} else {
			g_iServerCurrent -= g_iPropCurrent[plyTarget]
			g_iPropCurrent[plyTarget] = 0
		}
	} else {
		if (bIsDoll) {
			if(g_iDollCurrent[plyTarget] > 0)
				g_iDollCurrent[plyTarget] += iAmount
		}
		if (g_iPropCurrent[plyTarget] > 0)
			g_iPropCurrent[plyTarget] += iAmount
		if (g_iServerCurrent > 0)
			g_iServerCurrent += iAmount
	}
	if (g_iDollCurrent[plyTarget] < 0)
		g_iDollCurrent[plyTarget] = 0
	if (g_iPropCurrent[plyTarget] < 0)
		g_iPropCurrent[plyTarget] = 0
	if (g_iServerCurrent < 0)
		g_iServerCurrent = 0
}

Native_AllowToLazMod(Handle hPlugin, iNumParams) {

	int plyClient = GetNativeCell(1)

	if (!IsClientConnected(plyClient)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not connected.", plyClient)
		return -1
	}

	switch (g_enCvarModEnabled) {
		case LAZMOD_DISABLED: {
			LM_PrintToChat(plyClient, "LazMod is not available or disabled!")
			return false
		}
		case LAZMOD_ADMINONLY: {
			if (!LM_IsAdmin(plyClient)) {
				LM_PrintToChat(plyClient, "LazMod is not available or disabled.")
				return false
			} else
				return true
		}
		case LAZMOD_ENABLED: {
			return true
		}
		default:
			return true
	}
	
}

Native_AllowFly(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)
	if (!IsClientConnected(plyClient)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not connected.", plyClient)
		return -1
	}

	AdminId adminId = GetUserAdmin(plyClient)
	if (!g_bCvarAllowFly && GetAdminFlag(adminId, Admin_Custom1) == false) {
		LM_PrintToChat(plyClient, "Fly is not available or disabled.")
		return false
	} else
		return true
	
	
}

Native_IsAdmin(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)

	if (!IsClientConnected(plyClient)){
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not connected.", plyClient)
		return -1
	}

	new AdminId:Aid = GetUserAdmin(plyClient)
	if (GetAdminFlag(Aid, Admin_Ban))
		return true
	else
		return false
	
	
}

Native_GetClientAimEntity(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)
	bool bShowMsg = GetNativeCell(2)
	bool bIncClient = false
	float vOrigin[3], vAngles[3]
	GetClientEyePosition(plyClient, vOrigin)
	GetClientEyeAngles(plyClient, vAngles)
	
	if (iNumParams >= 3)
		bIncClient = GetNativeCell(3)
	
	// Command Range Limit
	{
		/*
		float AnglesVec[3], float EndPoint[3], float Distance
		if (LM_IsAdmin(Client))
			Distance = 50000.0
		else
			Distance = 1000.0
		GetClientEyeAngles(Client,vAngles)
		GetClientEyePosition(Client,vOrigin)
		GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR)

		EndPoint[0] = vOrigin[0] + (AnglesVec[0]*Distance)
		EndPoint[1] = vOrigin[1] + (AnglesVec[1]*Distance)
		EndPoint[2] = vOrigin[2] + (AnglesVec[2]*Distance)
		Handle trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_SHOT, RayType_EndPoint, TraceEntityFilter, Client)
		*/
	}
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilter, plyClient)
	
	if (TR_DidHit(trace)) {
		int entProp = TR_GetEntityIndex(trace)
		
		if (entProp > 0 && IsValidEntity(entProp)) {
			if(!bIncClient) {
				if (!(LM_IsPlayer(entProp))) {
					CloseHandle(trace)
					return entProp
				}
			} else {
				CloseHandle(trace)
				return entProp
			}
		}
	}
	
	if (bShowMsg)
		LM_PrintToChat(plyClient, "You dont have a target or target invalid.")
	
	CloseHandle(trace)
	return -1
}
bool TraceEntityFilter(entity, mask, any data) {
    return data != entity
}

Native_IsEntityOwner(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)
	int entProp = GetNativeCell(2)
	bool bIngoreCvar = false
	
	if (iNumParams >= 3)
		bIngoreCvar = GetNativeCell(3)
	
	if (LM_IsAdmin(plyClient) && g_bCvarAdminBypassOwner)
		return true

	if (LM_GetEntityOwner(entProp) == plyClient)
		return true

	if (LM_IsPlayer(entProp) && (!LM_IsAdmin(plyClient) || !g_bCvarAdminBypassOwner)) {
		LM_PrintToChat(plyClient, "You are not allowed to do this to players!")
		return false
	}

	if (LM_GetEntityOwner(entProp) == -1 && (bIngoreCvar || g_bCvarAllowNonOwner))
		return true

	LM_PrintToChat(plyClient, "This prop does not belong to you!")
	return false
}

Native_LogCmd(Handle hPlugin, iNumParams) {
	new Client = GetNativeCell(1)
	char szCmd[33], szArgs[128]
	GetNativeString(2, szCmd, sizeof(szCmd))
	GetNativeString(3, szArgs, sizeof(szArgs))
	
	static char szLogPath[64]
	char szTime[16], szName[33], szAuthid[33]
	
	FormatTime(szTime, sizeof(szTime), "%Y-%m-%d")
	GetClientName(Client, szName, sizeof(szName))
	GetClientAuthId(Client, AuthId_Steam2, szAuthid, sizeof(szAuthid))
	
	BuildPath(Path_SM, szLogPath, 64, "logs/LazMod-%s.log", szTime)
	
	if (StrEqual(szArgs, "")) {
		LogToFile(szLogPath, "\"%s\" (%s) Cmd: %s", szName, szAuthid, szCmd)
		LogToGame("\"%s\" (%s) Cmd: %s", szName, szAuthid, szCmd)
	} else {
		LogToFile(szLogPath, "\"%s\" (%s) Cmd: %s, Args:%s", szName, szAuthid, szCmd, szArgs)
		LogToGame("\"%s\" (%s) Cmd: %s, Args:%s", szName, szAuthid, szCmd, szArgs)
	}
}

Native_PrintToChat(Handle hPlugin, iNumParams) {
	char szMsg[192]
	int written
	FormatNativeString(0, 2, 3, sizeof(szMsg), written, szMsg)
	if (GetNativeCell(1) > 0)
		PrintToChat(GetNativeCell(1), "%s %s", MSGTAG, szMsg)
}

Native_PrintToAll(Handle hPlugin, iNumParams) {
	char szMsg[192]
	int written
	FormatNativeString(0, 1, 2, sizeof(szMsg), written, szMsg)
	PrintToChatAll("%s %s", MSGTAG, szMsg)
}

Native_IsClientValid(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)
	int plyTarget = GetNativeCell(2)
	bool IsAlive, ReplyTarget
	if (iNumParams == 3)
		IsAlive = GetNativeCell(3)
	if (iNumParams == 4)
		ReplyTarget = GetNativeCell(4)
	
	if (plyTarget < 1 || plyTarget > MAXPLAYERS)
		return false
	if (!IsClientInGame(plyTarget))
		return false
	else if (IsAlive) {
		if (!IsPlayerAlive(plyTarget)) {
			if (ReplyTarget) 
				LM_PrintToChat(plyClient, "This command can only be used on alive players.")
			else
				LM_PrintToChat(plyClient, "You cannot use the command while dead.")
			
			return false
		}
	}
	return true
}

Native_IsFuncProp(Handle hPlugin, iNumParams) {
	char szClass[32]
	int entProp = GetNativeCell(1)
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	if (StrContains(szClass, "func_", false) == 0 && !StrEqual(szClass, "func_physbox"))
		return true
	return false
}

Native_IsNpc(Handle hPlugin, iNumParams) {
	char szClass[32]
	int entProp = GetNativeCell(1)
	GetEdictClassname(entProp, szClass, sizeof(szClass))
	if (StrContains(szClass, "npc_", false) == 0)
		return true
	return false
}

Native_IsPlayer(Handle hPlugin, iNumParams) {
	int entProp = GetNativeCell(1)
	if (GetEntityFlags(entProp) & (FL_CLIENT | FL_FAKECLIENT))
		return true
	return false
}
