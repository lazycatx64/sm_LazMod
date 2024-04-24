#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>

#if LAZMOD_API_VER < 3
	#error "build.inc is outdated. please update before compiling"
#endif

#define MSGTAG "\x01[\x04BuildMod\x01]"

new bool:g_bClientLang[MAXPLAYERS];
new Handle:g_hCookieClientLang;

new g_iPropCurrent[MAXPLAYERS];
new g_iDollCurrent[MAXPLAYERS];
new g_iServerCurrent;
new g_iEntOwner[MAX_HOOK_ENTITIES] = {-1,...};

new Handle:g_hBlackListArray;
new Handle:g_hCvarSwitch		= INVALID_HANDLE;
new Handle:g_hCvarNonOwner		= INVALID_HANDLE;
new Handle:g_hCvarFly			= INVALID_HANDLE;
new Handle:g_hCvarClPropLimit	= INVALID_HANDLE;
new Handle:g_hCvarClDollLimit	= INVALID_HANDLE;
new Handle:g_hCvarServerLimit	= INVALID_HANDLE;

new g_iCvarEnabled;
new g_iCvarNonOwner;
new g_iCvarFly;
new g_iCvarClPropLimit[MAXPLAYERS];
new g_iCvarClDollLimit;
new g_iCvarServerLimit;

public Plugin:myinfo = {
	name = "LazMod Core",
	author = "LaZycAt, hjkwe654",
	description = "LazMod Core",
	version = LAZMOD_VER,
	url = ""
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	RegPluginLibrary("build_test");
	
	CreateNative("LM_SetEntityOwner", Native_RegisterOwner);
	CreateNative("LM_GetEntityOwner", Native_ReturnOwner);
	CreateNative("LM_SetLimit", Native_SetLimit);
	CreateNative("LM_AllowToUse", Native_AllowToUse);
	CreateNative("LM_AllowFly", Native_AllowFly);
	CreateNative("LM_IsAdmin", Native_IsAdmin);
	CreateNative("LM_ClientAimEntity", Native_ClientAimEntity);
	CreateNative("LM_IsEntityOwner", Native_IsOwner);
	CreateNative("LM_Logging", Native_LogCmds);
	CreateNative("LM_PrintToChat", Native_PrintToChat);
	CreateNative("LM_PrintToAll", Native_PrintToAll);
	CreateNative("LM_AddBlacklist", Native_AddBlacklist);
	CreateNative("LM_RemoveBlacklist", Native_RemoveBlacklist);
	CreateNative("LM_IsBlacklisted", Native_IsBlacklisted);
	CreateNative("LM_IsClientValid", Native_IsClientValid);
	
	return APLRes_Success;
}

public OnPluginStart() {	
	g_hCvarSwitch		= CreateConVar("lm_buildmod", "2", "Enable the LazMod. 2=For All, 1=Admins Only, 0=Disabled", 0, true, 0.0, true, 2.0);
	g_hCvarNonOwner		= CreateConVar("lm_nonowner", "0", "Switch non-admin player can control non-owner props or not", 0, true, 0.0, true, 1.0);
	g_hCvarFly			= CreateConVar("lm_fly", "1", "Switch non-admin player can use !fly to noclip or not", 0, true, 0.0, true, 1.0);
	g_hCvarClPropLimit	= CreateConVar("lm_prop", "700", "Player prop spawn limit.", 0, true, 0.0);
	g_hCvarClDollLimit	= CreateConVar("lm_doll", "10", "Player doll spawn limit.", 0, true, 0.0);
	g_hCvarServerLimit	= CreateConVar("lm_maxprops", "2000", "Limit server-side prop.", 0, true, 0.0, true, 3000.0);
	RegAdminCmd("sm_version", Command_Version, 0, "Show BuildMod Core version");
	RegAdminCmd("sm_my", Command_SpawnCount, 0, "Show how many entities are you spawned.");
	
	g_iCvarEnabled = GetConVarInt(g_hCvarSwitch);
	g_iCvarNonOwner = GetConVarBool(g_hCvarNonOwner);
	g_iCvarFly = GetConVarBool(g_hCvarFly);
	for (new i = 0; i < MAXPLAYERS; i++)
		g_iCvarClPropLimit[i] = GetConVarInt(g_hCvarClPropLimit);
	g_iCvarClDollLimit = GetConVarInt(g_hCvarClDollLimit);
	g_iCvarServerLimit = GetConVarInt(g_hCvarServerLimit);

	HookConVarChange(g_hCvarSwitch, Hook_CvarEnabled);
	HookConVarChange(g_hCvarNonOwner, Hook_CvarNonOwner);
	HookConVarChange(g_hCvarFly, Hook_CvarFly);
	HookConVarChange(g_hCvarClPropLimit, Hook_CvarClPropLimit);
	HookConVarChange(g_hCvarClDollLimit, Hook_CvarClDollLimit);
	HookConVarChange(g_hCvarServerLimit, Hook_CvarServerLimit);
	
	g_hCookieClientLang = RegClientCookie("cookie_BuildModClientLang", "BuildMod Client Language.", CookieAccess_Private);
	ServerCommand("gamedesc_override \"BuildMod %s\"", LAZMOD_VER);
	g_hBlackListArray = CreateArray(33, 128);	// 33 arrays, every array size is 128
	ReadBlackList();
}

public OnMapStart() {
	Build_FirstRun();
}

public Action:OnClientCommand(Client, args) {
	if (Client > 0) {
		if (LM_IsClientValid(Client, Client)) {
			new String:Lang[8];
			GetClientCookie(Client, g_hCookieClientLang, Lang, sizeof(Lang));
			if (StrEqual(Lang, "1"))
				g_bClientLang[Client] = true;
			else
				g_bClientLang[Client] = false;
		}
	}
}

public Hook_CvarEnabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iCvarEnabled = GetConVarInt(g_hCvarSwitch);
}

public Hook_CvarNonOwner(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iCvarNonOwner = GetConVarBool(g_hCvarNonOwner);
}

public Hook_CvarFly(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iCvarFly = GetConVarBool(g_hCvarFly);
}

public Hook_CvarClPropLimit(Handle:convar, const String:oldValue[], const String:newValue[]) {
	for (new i = 0; i < MAXPLAYERS; i++)
		g_iCvarClPropLimit[i] = GetConVarInt(g_hCvarClPropLimit);
}

public Hook_CvarClDollLimit(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iCvarClDollLimit = GetConVarInt(g_hCvarClDollLimit);
}

public Hook_CvarServerLimit(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iCvarServerLimit = GetConVarInt(g_hCvarServerLimit);
}

public Action:Command_Version(Client, args) {
	if (g_bClientLang[Client])
		LM_PrintToChat(Client, "BuildMod 系統核心版本: %s", LAZMOD_VER);
	else
		LM_PrintToChat(Client, "BuildMod Core version: %s", LAZMOD_VER);
	return Plugin_Handled;
}

public Action:Command_SpawnCount(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled;
		
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_my", szArgs);
	if (g_bClientLang[Client])
		LM_PrintToChat(Client, "你的上限: %i/%i [人偶: %i/%i], 伺服器上限: %i/%i", g_iPropCurrent[Client], g_iCvarClPropLimit[Client], g_iDollCurrent[Client], g_iCvarClDollLimit, g_iServerCurrent, g_iCvarServerLimit);
	else
		LM_PrintToChat(Client, "Your Limit: %i/%i [Ragdoll: %i/%i], Server Limit: %i/%i", g_iPropCurrent[Client], g_iCvarClPropLimit[Client], g_iDollCurrent[Client], g_iCvarClDollLimit, g_iServerCurrent, g_iCvarServerLimit);
	if (LM_IsAdmin(Client)) {
		for (new i = 1; i < MaxClients; i++) {
			if (LM_IsClientValid(i, i) && Client != i) {
				if (g_bClientLang[Client])
					LM_PrintToChat(Client, "%N: %i/%i [人偶: %i/%i]", i, g_iPropCurrent[i], g_iCvarClPropLimit[i], g_iDollCurrent[i], g_iCvarClDollLimit);
				else
					LM_PrintToChat(Client, "%N: %i/%i [Ragdoll: %i/%i]", i, g_iPropCurrent[i], g_iCvarClPropLimit[i], g_iDollCurrent[i], g_iCvarClDollLimit);
			}
		}
	}
	return Plugin_Handled;
}

public Native_RegisterOwner(Handle:hPlugin, iNumParams) {
	new iEnt = GetNativeCell(1);
	new Client = GetNativeCell(2);
	new bool:bIsDoll = false;
	
	if (iNumParams >= 3)
		bIsDoll = GetNativeCell(3);
	
	if (Client == -1) {
		g_iEntOwner[iEnt] = -1;
		return true;
	}
	if (IsValidEntity(iEnt) && LM_IsClientValid(Client, Client)) {
		if (g_iServerCurrent < g_iCvarServerLimit) {
			if (bIsDoll) {
				if (g_iDollCurrent[Client] < g_iCvarClDollLimit) {
					g_iDollCurrent[Client] += 1;
					g_iPropCurrent[Client] += 1;
				} else {
					if (g_bClientLang[Client])
						LM_PrintToChat(Client, "你的人偶數量已達上限.");
					else
						LM_PrintToChat(Client, "Your dolls limit reach maximum.");
					return false;
				}
			} else {
				if (g_iPropCurrent[Client] < g_iCvarClPropLimit[Client])
					g_iPropCurrent[Client] += 1;
				else {
					if (g_bClientLang[Client])
						LM_PrintToChat(Client, "你的物件數量已達上限.");
					else
						LM_PrintToChat(Client, "Your props limit reach maximum.");
					return false;
				}
			}
			g_iEntOwner[iEnt] = Client;
			g_iServerCurrent += 1;
			return true;
		} else {
			if (g_bClientLang[Client])
				LM_PrintToChat(Client, "伺服器總物件數量已達總上限.");
			else
				LM_PrintToChat(Client, "Server props limit reach maximum.");
			return false;
		}
	}
	
	if (!IsValidEntity(iEnt))
		ThrowNativeError(SP_ERROR_NATIVE, "Entity id %i is invalid.", iEnt);
		
	if (!LM_IsClientValid(Client, Client))
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not in game.", Client);
		
	return -1;
}

public Native_ReturnOwner(Handle:hPlugin, iNumParams) {
	new iEnt = GetNativeCell(1);
	if (IsValidEntity(iEnt))
		return g_iEntOwner[iEnt];
	else {
		ThrowNativeError(SP_ERROR_NATIVE, "Entity id %i is invalid.", iEnt);
		return -1;
	}
}

public Native_SetLimit(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);
	new Amount = GetNativeCell(2);
	new bIsDoll = false;
	
	if (iNumParams >= 3)
		bIsDoll = GetNativeCell(3);
	
	if (Amount == 0) {
		if (bIsDoll) {
			g_iServerCurrent -= g_iDollCurrent[Client];
			g_iPropCurrent[Client] -= g_iDollCurrent[Client];
			g_iDollCurrent[Client] = 0;
		} else {
			g_iServerCurrent -= g_iPropCurrent[Client];
			g_iPropCurrent[Client] = 0;
		}
	} else {
		if (bIsDoll) {
			if(g_iDollCurrent[Client] > 0)
				g_iDollCurrent[Client] += Amount;
		}
		if (g_iPropCurrent[Client] > 0)
			g_iPropCurrent[Client] += Amount;
		if (g_iServerCurrent > 0)
			g_iServerCurrent += Amount;
	}
	if (g_iDollCurrent[Client] < 0)
		g_iDollCurrent[Client] = 0;
	if (g_iPropCurrent[Client] < 0)
		g_iPropCurrent[Client] = 0;
	if (g_iServerCurrent < 0)
		g_iServerCurrent = 0;
}

public Native_AllowToUse(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);


	if (!IsClientConnected(Client)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not connected.", Client);
		return -1;
	}

	switch (g_iCvarEnabled) {
		case 0: {
			// if (g_bClientLang[Client])
			// 	LM_PrintToChat(Client, "BuildMod 目前不能使用或已關閉!");
			// else
				LM_PrintToChat(Client, "BuildMod is not available or disabled!");
			return false;
		}
		case 1: {
			if (!LM_IsAdmin(Client)) {
				// if (g_bClientLang[Client])
				// 	LM_PrintToChat(Client, "BuildMod 目前不能使用或已關閉.");
				// else
					LM_PrintToChat(Client, "BuildMod is not available or disabled.");
				return false;
			} else
				return true;
		}
		default: return true;
	}
	
}

public Native_AllowFly(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);
	if (IsClientConnected(Client)) {
		new AdminId:Aid = GetUserAdmin(Client);
		if (!g_iCvarFly && GetAdminFlag(Aid, ADMFLAG_CUSTOM1) == false) {
			// if (g_bClientLang[Client])
			// 	LM_PrintToChat(Client, "Fly 目前不能使用或已關閉.");
			// else
				LM_PrintToChat(Client, "Fly is not available or disabled.");
			return false;
		} else
			return true;
	}
	
	ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not connected.", Client);
	return -1;
}

public Native_IsAdmin(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);
	new bool:bLevel2 = false;
	
	if (iNumParams >= 2)
		bLevel2 = GetNativeCell(2);
	
	if (IsClientConnected(Client)) {
		new AdminId:Aid = GetUserAdmin(Client);
		if (GetAdminFlag(Aid, (bLevel2) ? Admin_Custom1 : Admin_Ban))
			return true;
		else
			return false;
	} else {
		ThrowNativeError(SP_ERROR_NATIVE, "Client id %i is not connected.", Client);
		return -1;
	}
}

public Native_ClientAimEntity(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);
	new bool:bShowMsg = GetNativeCell(2);
	new bool:bIncClient = false;
	new Float:vOrigin[3], Float:vAngles[3];
	GetClientEyePosition(Client, vOrigin);
	GetClientEyeAngles(Client, vAngles);
	
	if (iNumParams >= 3)
		bIncClient = GetNativeCell(3);
	
	// Command Range Limit
	{
		/*
		new Float:AnglesVec[3], Float:EndPoint[3], Float:Distance;
		if (LM_IsAdmin(Client))
			Distance = 50000.0;
		else
			Distance = 1000.0;
		GetClientEyeAngles(Client,vAngles);
		GetClientEyePosition(Client,vOrigin);
		GetAngleVectors(vAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);

		EndPoint[0] = vOrigin[0] + (AnglesVec[0]*Distance);
		EndPoint[1] = vOrigin[1] + (AnglesVec[1]*Distance);
		EndPoint[2] = vOrigin[2] + (AnglesVec[2]*Distance);
		new Handle:trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_SHOT, RayType_EndPoint, TraceEntityFilter, Client);
		*/
	}
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilter, Client);
	
	if (TR_DidHit(trace)) {
		new iEntity = TR_GetEntityIndex(trace);
		
		if (iEntity > 0 && IsValidEntity(iEntity)) {
			if(!bIncClient) {
				if (!(GetEntityFlags(iEntity) & (FL_CLIENT | FL_FAKECLIENT))) {
					CloseHandle(trace);
					return iEntity;
				}
			} else {
				CloseHandle(trace);
				return iEntity;
			}
		}
	}
	
	if (bShowMsg) {
		// if (g_bClientLang[Client])
		// 	LM_PrintToChat(Client, "你未瞄準任何目標或目標無效.");
		// else
			LM_PrintToChat(Client, "You dont have a target or target invalid.");
	}
	CloseHandle(trace);
	return -1;
}

public bool:TraceEntityFilter(entity, mask, any:data) {
    return data != entity;
}

public Native_IsOwner(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);
	new iEnt = GetNativeCell(2);
	new bool:bIngoreCvar = false;
	
	if (iNumParams >= 3)
		bIngoreCvar = GetNativeCell(3);
	
	if (LM_GetEntityOwner(iEnt) != Client) {
		if (!LM_IsAdmin(Client)) {
			if (GetEntityFlags(iEnt) & (FL_CLIENT | FL_FAKECLIENT)) {
				if (g_bClientLang[Client])
					LM_PrintToChat(Client, "你沒有權限對玩家使用此指令!");
				else
					LM_PrintToChat(Client, "You are not allowed to do this to players!");
				return false;
			}
			if (LM_GetEntityOwner(iEnt) == -1) {
				if (!bIngoreCvar) {
					if (!g_iCvarNonOwner) {
						if (g_bClientLang[Client])
							LM_PrintToChat(Client, "該物件不屬於你!");
						else
							LM_PrintToChat(Client, "You don't own this prop!");
						return false;
					} else
						return true;
				} else
					return true;
			} else {
				if (g_bClientLang[Client])
					LM_PrintToChat(Client, "該物件不屬於你!");
				else
					LM_PrintToChat(Client, "You don't own this prop!");
				return false;
			}
		} else
			return true;
	} else
		return true;
}

public Native_LogCmds(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);
	new String:szCmd[33], String:szArgs[128];
	GetNativeString(2, szCmd, sizeof(szCmd));
	GetNativeString(3, szArgs, sizeof(szArgs));
	
	static String:szLogPath[64];
	new String:szTime[16], String:szName[33], String:szAuthid[33];
	
	FormatTime(szTime, sizeof(szTime), "%Y-%m-%d");
	GetClientName(Client, szName, sizeof(szName));
	GetClientAuthId(Client, AuthId_Steam2, szAuthid, sizeof(szAuthid));
	
	BuildPath(Path_SM, szLogPath, 64, "logs/LazMod-%s.log", szTime);
	
	if (StrEqual(szArgs, "")) {
		LogToFile(szLogPath, "\"%s\" (%s) Cmd: %s", szName, szAuthid, szCmd);
		LogToGame("\"%s\" (%s) Cmd: %s", szName, szAuthid, szCmd);
	} else {
		LogToFile(szLogPath, "\"%s\" (%s) Cmd: %s, Args:%s", szName, szAuthid, szCmd, szArgs);
		LogToGame("\"%s\" (%s) Cmd: %s, Args:%s", szName, szAuthid, szCmd, szArgs);
	}
}

public Native_PrintToChat(Handle:hPlugin, iNumParams) {
	new String:szMsg[192], written;
	FormatNativeString(0, 2, 3, sizeof(szMsg), written, szMsg);
	if (GetNativeCell(1) > 0)
		PrintToChat(GetNativeCell(1), "%s %s", MSGTAG, szMsg);
}

public Native_PrintToAll(Handle:hPlugin, iNumParams) {
	new String:szMsg[192], written;
	FormatNativeString(0, 1, 2, sizeof(szMsg), written, szMsg);
	PrintToChatAll("%s%s", MSGTAG, szMsg);
}

public Native_IsClientValid(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);
	new iTarget = GetNativeCell(2);
	new bool:IsAlive, bool:ReplyTarget;
	if (iNumParams == 3)
		IsAlive = GetNativeCell(3);
	if (iNumParams == 4)
		ReplyTarget = GetNativeCell(4);
	
	if (iTarget < 1 || iTarget > 32)
		return false;
	if (!IsClientInGame(iTarget))
		return false;
	else if (IsAlive) {
		if (!IsPlayerAlive(iTarget)) {
			if (ReplyTarget) {
				if (g_bClientLang[Client])
					LM_PrintToChat(Client, "無法在目標玩家死亡狀態下使用.");
				else
					LM_PrintToChat(Client, "This command can only be used on alive players.");
			} else {
				if (g_bClientLang[Client])
					LM_PrintToChat(Client, "你無法在死亡狀態下使用此指令.");
				else
					LM_PrintToChat(Client, "You cannot use the command if you dead.");
			}
			return false;
		}
	}
	return true;
}

public Native_AddBlacklist(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);
	new String:szAuthid[33], String:szName[33], String:WriteToArray[128], String:szData[128];
	GetClientAuthId(Client, AuthId_Steam2, szAuthid, sizeof(szAuthid));
	GetClientName(Client, szName, sizeof(szName));
	
	new i;
	for (i = 0; i < GetArraySize(g_hBlackListArray); i++) {
		GetArrayString(g_hBlackListArray , i, szData, sizeof(szData));
		if(StrEqual(szData, ""))
			break;
	}
	
	Format(WriteToArray, sizeof(WriteToArray), "\"%s\"\t\t// %s\n", szAuthid, szName);
	if (SetArrayString(g_hBlackListArray, i, WriteToArray)) {
		WriteBlacklist()
		return true;
	}

	return false;
}

public Native_RemoveBlacklist(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);
	new String:szAuthid[33], String:szName[33], String:szData[128];
	GetClientAuthId(Client, AuthId_Steam2, szAuthid, sizeof(szAuthid));
	GetClientName(Client, szName, sizeof(szName));
	
	new i;
	for (i = 0; i < GetArraySize(g_hBlackListArray); i++) {
		GetArrayString(g_hBlackListArray , i, szData, sizeof(szData));
		if(StrContains(szData, szAuthid) != -1) {
			RemoveFromArray(g_hBlackListArray, i);
			WriteBlacklist()
			return true;
		}
	}
	
	return false;
}

public Native_IsBlacklisted(Handle:hPlugin, iNumParams) {
	new Client = GetNativeCell(1);
	new String:szAuthid[33], String:szData[128];
	new bool:bIsBlacklisted = false;
	GetClientAuthId(Client, AuthId_Steam2, szAuthid, sizeof(szAuthid));

	for(new i = 0; i < GetArraySize(g_hBlackListArray); i++) {
		GetArrayString(g_hBlackListArray , i, szData, sizeof(szData));
		if(StrContains(szData, szAuthid) != -1) {
			bIsBlacklisted = true;
			break;
		}
	}
	
	if(bIsBlacklisted) {
		// if (g_bClientLang[Client]) {
		// 	LM_PrintToChat(Client, "你被加入黑名單了 :(");
		// 	LM_PrintToChat(Client, "你可以請管理員解除你的黑名單 :(");
		// } else {
			LM_PrintToChat(Client, "You have been blacklisted, so you cannot use LazMod :(");
			LM_PrintToChat(Client, "Ask admins to unblacklist you :(");
		// }
		return true;
	}
	
	return false;
}

private ReadBlackList() {
	new String:szFile[128];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/lazmod/blacklist.ini");
	
	new Handle:hFile = OpenFile(szFile, "r");
	if (hFile == INVALID_HANDLE)
		return;
	
	new iClients = 0;
	while (!IsEndOfFile(hFile))
	{
		new String:szLine[255];
		if (!ReadFileLine(hFile, szLine, sizeof(szLine)))
			break;
			
		SetArrayString(g_hBlackListArray, iClients++, szLine);
	}
	CloseHandle(hFile);
}

private WriteBlacklist() {
	new String:szFile[128], String:szData[64];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/lazmod/blacklist.ini");
	
	new Handle:hFile = OpenFile(szFile, "w");
	if (hFile == INVALID_HANDLE)
		return false;
	
	for (new i = 0; i < GetArraySize(g_hBlackListArray); i++) {
		GetArrayString(g_hBlackListArray , i, szData, sizeof(szData));
		if(StrContains(szData, "STEAM_") != -1)
			WriteFileString(hFile, szData, false);
	}
	
	CloseHandle(hFile);
	return true;
}
