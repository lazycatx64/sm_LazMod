

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>

#if LAZMOD_API_VER < 3
	#error "build.inc is outdated. please update before compiling"
#endif





int g_iPropCurrent[MAXPLAYERS]
int g_iDollCurrent[MAXPLAYERS]
int g_iServerCurrent
int g_iEntOwner[MAX_HOOK_ENTITIES] = {-1,...}

Handle g_hCvarLazModEnabled		= INVALID_HANDLE
Handle g_hCvarNonOwner		= INVALID_HANDLE
Handle g_hCvarFly			= INVALID_HANDLE
Handle g_hCvarClPropLimit	= INVALID_HANDLE
Handle g_hCvarClDollLimit	= INVALID_HANDLE
Handle g_hCvarServerLimit	= INVALID_HANDLE

int g_iCvarLazModEnabled
int g_iCvarNonOwner
int g_iCvarFly
int g_iCvarClPropLimit[MAXPLAYERS]
int g_iCvarClDollLimit
int g_iCvarServerLimit

public Plugin myinfo = {
	name = "LazMod Core",
	author = "LaZycAt, hjkwe654",
	description = "LazMod Core",
	version = LAZMOD_VER,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max) {
	RegPluginLibrary("build_test")
	
	CreateNative("LM_SetEntityOwner",		Native_SetEntityOwner)
	CreateNative("LM_GetEntityOwner",		Native_GetEntityOwner)
	CreateNative("LM_IsEntityOwner",		Native_IsEntityOwner)

	CreateNative("LM_AllowToLazMod",		Native_AllowToLazMod)
	CreateNative("LM_AllowFly",			Native_AllowFly)

	CreateNative("LM_IsClientValid",	Native_IsClientValid)
	CreateNative("LM_IsAdmin",			Native_IsAdmin)

	CreateNative("LM_IsFuncProp", 		Native_IsFuncProp)
	CreateNative("LM_IsNpc",			Native_IsNpc)
	CreateNative("LM_IsPlayer",			Native_IsPlayer)

	CreateNative("LM_SetSpawnLimit",	Native_SetSpawnLimit)
	CreateNative("LM_LogCmd",			Native_LogCmd)
	CreateNative("LM_PrintToChat",		Native_PrintToChat)
	CreateNative("LM_PrintToAll",		Native_PrintToAll)
	CreateNative("LM_GetClientAimEntity",	Native_GetClientAimEntity)

	
	return APLRes_Success
}

public OnPluginStart() {	
	g_hCvarLazModEnabled = CreateConVar("lm_enable", "2", "Enable the LazMod. 2=For All, 1=Admins Only, 0=Disabled.", FCVAR_NOTIFY, true, 0.0, true, 2.0)
	g_hCvarNonOwner		= CreateConVar("lm_nonowner", "0", "Switch non-admin player can control non-owner props or not", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarFly			= CreateConVar("lm_fly", "1", "Switch non-admin player can use !fly to noclip or not", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarClPropLimit	= CreateConVar("lm_props", "500", "Player prop spawn limit.", FCVAR_NOTIFY, true, 0.0)
	g_hCvarClDollLimit	= CreateConVar("lm_dolls", "10", "Player doll spawn limit.", FCVAR_NOTIFY, true, 0.0)
	g_hCvarServerLimit	= CreateConVar("lm_maxprops", "2000", "Total prop spawn limit.", FCVAR_NOTIFY, true, 0.0, true, 3000.0)
	RegAdminCmd("sm_version", Command_Version, 0, "Show Lazmod Core version")
	RegAdminCmd("sm_count", Command_SpawnCount, 0, "Show how many entities are you spawned.")
	
	g_iCvarLazModEnabled = GetConVarInt(g_hCvarLazModEnabled)
	g_iCvarNonOwner = GetConVarBool(g_hCvarNonOwner)
	g_iCvarFly = GetConVarBool(g_hCvarFly)
	for (int i = 0; i < MAXPLAYERS; i++)
		g_iCvarClPropLimit[i] = GetConVarInt(g_hCvarClPropLimit)
	g_iCvarClDollLimit = GetConVarInt(g_hCvarClDollLimit)
	g_iCvarServerLimit = GetConVarInt(g_hCvarServerLimit)

	HookConVarChange(g_hCvarLazModEnabled, Hook_CvarLazModEnabled)
	HookConVarChange(g_hCvarNonOwner, Hook_CvarNonOwner)
	HookConVarChange(g_hCvarFly, Hook_CvarFly)
	HookConVarChange(g_hCvarClPropLimit, Hook_CvarClPropLimit)
	HookConVarChange(g_hCvarClDollLimit, Hook_CvarClDollLimit)
	HookConVarChange(g_hCvarServerLimit, Hook_CvarServerLimit)
	

	// ServerCommand("gamedesc_override \"BuildMod %s\"", LAZMOD_VER)
	PrintToServer( "LazMod Core loaded!" )
	PrintToServer( "Max Entities %d", GetMaxEntities() )

	
}

public OnMapStart() {
	LM_FirstRun()
}

public Hook_CvarLazModEnabled(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarLazModEnabled = GetConVarInt(g_hCvarLazModEnabled)
}

public Hook_CvarNonOwner(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarNonOwner = GetConVarBool(g_hCvarNonOwner)
}

public Hook_CvarFly(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarFly = GetConVarBool(g_hCvarFly)
}

public Hook_CvarClPropLimit(Handle convar, const char[] oldValue, const char[] newValue) {
	for (int i = 0; i < MAXPLAYERS; i++)
		g_iCvarClPropLimit[i] = GetConVarInt(g_hCvarClPropLimit)
}

public Hook_CvarClDollLimit(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarClDollLimit = GetConVarInt(g_hCvarClDollLimit)
}

public Hook_CvarServerLimit(Handle convar, const char[] oldValue, const char[] newValue) {
	g_iCvarServerLimit = GetConVarInt(g_hCvarServerLimit)
}

public Action Command_Version(plyClient, args) {
	LM_PrintToChat(plyClient, "LazMod Core version: %s", LAZMOD_VER)
	return Plugin_Handled
}

public Action Command_SpawnCount(plyClient, args) {
	if (!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient))
		return Plugin_Handled
		
	LM_PrintToChat(plyClient, "Your Limit: %i/%i [Ragdoll: %i/%i]", g_iPropCurrent[plyClient], g_iCvarClPropLimit[plyClient], g_iDollCurrent[plyClient], g_iCvarClDollLimit)
	LM_PrintToChat(plyClient, "Server Limit: %i/%i (%i/%i edicts)",  g_iServerCurrent, g_iCvarServerLimit, GetEntityCount(), LM_GetMaxEdict())
	if (LM_IsAdmin(plyClient)) {
		for (int i = 1; i < MaxClients; i++) {
			if (LM_IsClientValid(i, i) && plyClient != i)
				LM_PrintToChat(plyClient, "%N: %i/%i [Ragdoll: %i/%i]", i, g_iPropCurrent[i], g_iCvarClPropLimit[i], g_iDollCurrent[i], g_iCvarClDollLimit)
		
		}
	}

	char szArgs[128]
	GetCmdArgString(szArgs, sizeof(szArgs))
	LM_LogCmd(plyClient, "sm_count", szArgs)
	return Plugin_Handled
}

Native_SetEntityOwner(Handle hPlugin, iNumParams) {
	int entProp = GetNativeCell(1)
	int plyClient = GetNativeCell(2)
	bool bIsDoll = false
	
	if (iNumParams >= 3)
		bIsDoll = GetNativeCell(3)
	
	if (plyClient == -1) {
		g_iEntOwner[entProp] = -1
		return true
	}
	if (IsValidEntity(entProp) && LM_IsClientValid(plyClient, plyClient)) {
		if (!LM_CheckMaxEdict()) {
			LM_PrintToAll("TOO MUCH ENTITIES.")
			return false

		} else if (g_iServerCurrent < g_iCvarServerLimit) {
			if (bIsDoll) {
				if (g_iDollCurrent[plyClient] < g_iCvarClDollLimit) {
					g_iDollCurrent[plyClient] += 1
					g_iPropCurrent[plyClient] += 1
				} else {
					LM_PrintToChat(plyClient, "Your dolls has reached the limit.")
					return false
				}
			} else {
				if (g_iPropCurrent[plyClient] < g_iCvarClPropLimit[plyClient])
					g_iPropCurrent[plyClient] += 1
				else {
					LM_PrintToChat(plyClient, "Your props has reached the limit.")
					return false
				}
			}
			g_iEntOwner[entProp] = plyClient
			g_iServerCurrent += 1
			return true
		} else {
			LM_PrintToChat(plyClient, "The number of prop has reached the server limit.")
			return false
		}
	}
	
	if (!IsValidEntity(entProp))
		ThrowNativeError(SP_ERROR_NATIVE, "Entity id %i is invalid.", entProp)
		
	if (!LM_IsClientValid(plyClient, plyClient))
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not in game.", plyClient)
		
	return -1
}

Native_GetEntityOwner(Handle hPlugin, iNumParams) {
	new iEnt = GetNativeCell(1)
	if (IsValidEntity(iEnt))
		return g_iEntOwner[iEnt]
	else {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity id %i is invalid.", iEnt)
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

	switch (g_iCvarLazModEnabled) {
		case 0: {
			LM_PrintToChat(plyClient, "LazMod is not available or disabled!")
			return false
		}
		case 1: {
			if (!LM_IsAdmin(plyClient)) {
				LM_PrintToChat(plyClient, "LazMod is not available or disabled.")
				return false
			} else
				return true
		}
		default: return true
	}
	
}

Native_AllowFly(Handle hPlugin, iNumParams) {
	int plyClient = GetNativeCell(1)
	if (!IsClientConnected(plyClient)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not connected.", plyClient)
		return -1
	}

	AdminId adminId = GetUserAdmin(plyClient)
	if (!g_iCvarFly && GetAdminFlag(adminId, Admin_Custom1) == false) {
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
	
	if (LM_IsAdmin(plyClient))
		return true

	if (LM_GetEntityOwner(entProp) == plyClient)
		return true

	if (LM_IsPlayer(entProp) && !LM_IsAdmin(plyClient)) {
		LM_PrintToChat(plyClient, "You are not allowed to do this to players!")
		return false
	}

	if (LM_GetEntityOwner(entProp) == -1 && (bIngoreCvar || g_iCvarNonOwner))
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
