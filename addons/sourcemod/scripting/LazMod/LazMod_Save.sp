

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>



Handle g_hFile[MAXPLAYERS]
char g_szFileName[128][MAXPLAYERS]
char g_szListName[128]

bool g_bListExist = true
bool g_bIsRunning[MAXPLAYERS] = {false, ...}
int g_iCount[MAXPLAYERS]
int g_iError[MAXPLAYERS]
int g_iTryCount[MAXPLAYERS]

new Symbol[] = {
	'	',
	'\\',
	'/',
	' ',
	'~',
	'`',
	'?',
	'!',
	'@',
	'#',
	'$',
	'%',
	'^',
	'&',
	'*',
	'|',
	':',
	';',
	',',
	'.',
	'<',
	'>',
	'(',
	')',
	'{',
	'}',
	'[',
	']'
}

public Plugin myinfo = {
	name = "LazMod - SaveSystem",
	author = "LaZy cAt",
	description = "Saves the building progress.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	RegAdminCmd("sm_ss", Command_SaveSystem, ADMFLAG_CUSTOM1, "Save system ftw.")
	BuildPath(Path_SM, g_szListName, sizeof(g_szListName), "data/lazmodsaves/list.txt")
	if (!FileExists(g_szListName)) {
		g_bListExist = false
		LogError("list.txt is not exist!")
	}
	
	PrintToServer( "LazMod Save loaded!" )
}

public Action Command_SaveSystem(plyClient, args) {
	if (!g_bListExist) {
		LogError("list.txt is not exist!")
		LM_PrintToChat(plyClient, "Error: 0x00005E")
		LM_PrintToChat(plyClient, "Something went wrong! Please contact the admin")
		return Plugin_Handled
	}
	
	if (g_bIsRunning[plyClient]) {
		LM_PrintToChat(plyClient, "Process is already running. Please Wait...")
		return Plugin_Handled
	}
	if (!LM_AllowToUse(plyClient) || LM_IsBlacklisted(plyClient) && LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	
	char szMode[16], szSaveName[32], szSteamID[32]
	GetCmdArg(1, szMode, sizeof(szMode))
	GetCmdArg(2, szSaveName, sizeof(szSaveName))
	GetClientAuthId(plyClient, AuthId_Steam2, szSteamID, sizeof(szSteamID))
	ReplaceString(szSteamID, sizeof(szSteamID), ":", "-")
	ReplaceString(szSteamID, sizeof(szSteamID), "STEAM_", "")
	g_szFileName[plyClient] = ""
	BuildPath(Path_SM, g_szFileName[plyClient], sizeof(g_szFileName), "data/lazmodsaves/%s@%s", szSteamID, szSaveName)
	g_hFile[plyClient] = INVALID_HANDLE
	g_iTryCount[plyClient] = 0
	g_iCount[plyClient] = 0
	g_iError[plyClient] = 0
	
	if ((StrEqual(szMode, "save") || StrEqual(szMode, "load") || StrEqual(szMode, "delete")) && args > 1) {
		if (!Save_CheckSaveName(plyClient, szSaveName))
			return Plugin_Handled
			
		if (StrEqual(szMode, "save")) {
			if (FileExists(g_szFileName[plyClient])) {
				LM_PrintToChat(plyClient, "The save already exists. Replacing old save...")
					
				if (!DeleteFile(g_szFileName[plyClient])) {
					LM_PrintToChat(plyClient, "Replace failed! Save process abort!")
					return Plugin_Handled
				}
			}
			LM_PrintToChat(plyClient, "Saving the props. Please Wait...")
			g_bIsRunning[plyClient] = true
			
			Handle hSavePack
			CreateDataTimer(0.001, Timer_Save, hSavePack)
			WritePackCell(hSavePack, plyClient)
			WritePackString(hSavePack, szMode)
			WritePackString(hSavePack, szSaveName)
			WritePackString(hSavePack, szSteamID)
			return Plugin_Handled
		} else if (StrEqual(szMode, "load")) {
			if (!FileExists(g_szFileName[plyClient])) {
				LM_PrintToChat(plyClient, "The save does not exist.")
			} else {
				LM_PrintToChat(plyClient, "Loading the content. Please Wait...")
				g_bIsRunning[plyClient] = true
				
				Handle hLoadPack
				CreateDataTimer(0.01, Timer_Load, hLoadPack)
				WritePackCell(hLoadPack, plyClient)
				WritePackString(hLoadPack, szSteamID)
			}
			return Plugin_Handled
		} else if (StrEqual(szMode, "delete")) {
			if (FileExists(g_szFileName[plyClient])) {
				if (DeleteFile(g_szFileName[plyClient])) {
					LM_PrintToChat(plyClient, "Delete save successfully.")
					CheckSaveList(plyClient, szMode, szSaveName, szSteamID)
				} else {
					LM_PrintToChat(plyClient, "Delete save failed!")
				}
			} else {
				LM_PrintToChat(plyClient, "The save does not exist.")
			}
			return Plugin_Handled
		}
		return Plugin_Handled
	} else if (StrEqual(szMode, "list")) {
		Handle hListPack
		CreateDataTimer(0.01, Timer_List, hListPack)
		WritePackCell(hListPack, plyClient)
		WritePackString(hListPack, szSteamID)
		return Plugin_Handled
	}

	LM_PrintToChat(plyClient, " Usage:")
	LM_PrintToChat(plyClient, " !ss save <SaveName>")
	LM_PrintToChat(plyClient, " !ss load <SaveName>")
	LM_PrintToChat(plyClient, " !ss delete <SaveName>")
	LM_PrintToChat(plyClient, " !ss list")
	return Plugin_Handled
}

public Action Timer_Save(Handle Timer, Handle hDataPack) {
	ResetPack(hDataPack)
	char szMode[16], szSaveName[32], szSteamID[32]
	ResetPack(hDataPack)
	int plyClient = ReadPackCell(hDataPack)
	ReadPackString(hDataPack, szMode, sizeof(szMode))
	ReadPackString(hDataPack, szSaveName, sizeof(szSaveName))
	ReadPackString(hDataPack, szSteamID, sizeof(szSteamID))
	
	if (!LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	
	if (g_hFile[plyClient] == INVALID_HANDLE) {
		g_hFile[plyClient] = OpenFile(g_szFileName[plyClient], "w")
		g_iTryCount[plyClient]++
		if (g_iTryCount[plyClient] < 3) {
			Handle hNewPack
			CreateDataTimer(0.2, Timer_Save, hNewPack)
			WritePackCell(hNewPack, plyClient)
			WritePackString(hNewPack, szMode)
			WritePackString(hNewPack, szSaveName)
			WritePackString(hNewPack, szSteamID)
		} else {
			LM_PrintToChat(plyClient, "Unable to create the save! Contact admins!")
			g_hFile[plyClient] = INVALID_HANDLE
			g_iTryCount[plyClient] = 0
		}
	} else {
		char szTime[16], szClass[32], szModel[128]
		float fOrigin[3], fAngles[3]
		int iOrigin[3], iAngles[3]
		int iHealth, iCount = 0
		FormatTime(szTime, sizeof(szTime), "%Y/%m/%d")
		WriteFileLine(g_hFile[plyClient], ";---------- File Create : [%s] ----------||", szTime)
		WriteFileLine(g_hFile[plyClient], ";---------- BY: %N <%s> ----------||", plyClient, szSteamID)
		for (int i = 0; i < MAX_HOOK_ENTITIES; i++) {
			if (IsValidEdict(i)) {
				GetEdictClassname(i, szClass, sizeof(szClass))
				if ((StrContains(szClass, "prop_dynamic") >= 0 || StrContains(szClass, "prop_physics") >= 0) && !StrEqual(szClass, "prop_ragdoll") && LM_GetEntityOwner(i) == plyClient) {
					GetEntPropString(i, Prop_Data, "m_ModelName", szModel, sizeof(szModel))
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fOrigin)
					GetEntPropVector(i, Prop_Data, "m_angRotation", fAngles)
					for (int j = 0; j < 3; j++) {
						iOrigin[j] = RoundToNearest(fOrigin[j])
						iAngles[j] = RoundToNearest(fAngles[j])
					}
					iHealth = GetEntProp(i, Prop_Data, "m_iHealth", 4)
					if (iHealth > 100000000)
						iHealth = 2
					else if (iHealth > 0)
						iHealth = 1
					else
						iHealth = 0
					g_iCount[plyClient]++
					WriteFileLine(g_hFile[plyClient], "ent%i %s %s %i %i %i %i %i %i %i", g_iCount[plyClient], szClass, szModel, iOrigin[0], iOrigin[1], iOrigin[2], iAngles[0], iAngles[1], iAngles[2], iHealth)
				}
			}
		}
		WriteFileLine(g_hFile[plyClient], ";---------- File End | %i Props ----------||", iCount)
		
		FlushFile(g_hFile[plyClient])
		CloseHandle(g_hFile[plyClient])
		g_bIsRunning[plyClient] = false
		if (g_iCount[plyClient] > 0) {
			LM_PrintToChat(plyClient, "Saved %i prop(s) with savename '%s'", g_iCount[plyClient], szSaveName)
			g_iCount[plyClient] = 0
			CheckSaveList(plyClient, szMode, szSaveName, szSteamID)
		} else {
			LM_PrintToChat(plyClient, "Nothing to save.")
			DeleteFile(g_szFileName[plyClient])
		}
	}
	return Plugin_Handled
}

public Action Timer_Load(Handle Timer, Handle hDataPack) {
	ResetPack(hDataPack)
	char szSteamID[32]
	int Client = ReadPackCell(hDataPack)
	bool bRegOwnerError = false
	ReadPackString(hDataPack, szSteamID, sizeof(szSteamID))
	
	if (!LM_IsClientValid(Client, Client))
		return Plugin_Handled
	
	if (g_hFile[Client] == INVALID_HANDLE) {
		g_hFile[Client] = OpenFile(g_szFileName[Client], "r")
		g_iTryCount[Client]++
		if (g_iTryCount[Client] < 3) {
			Handle hNewPack
			CreateDataTimer(0.2, Timer_Load, hNewPack)
			WritePackCell(hNewPack, Client)
			WritePackString(hNewPack, szSteamID)
		} else {
			LM_PrintToChat(Client, "Save found but unable to load! Contact admins!")
			g_hFile[Client] = INVALID_HANDLE
			g_iTryCount[Client] = 0
			return Plugin_Handled
		}
	} else {
		char szLoadString[255]
		if (ReadFileLine(g_hFile[Client], szLoadString, sizeof(szLoadString))) {
			if (StrContains(szLoadString, "ent") != -1) {
				int entLoadEntity = -1
				char szBuffer[10][255], szClass[32], szModel[128]
				float fOrigin[3], fAngles[3]
				int iHealth
				ExplodeString(szLoadString, " ", szBuffer, 10, 255)
				Format(szClass, sizeof(szClass), "%s", szBuffer[1])
				Format(szModel, sizeof(szModel), "%s", szBuffer[2])
				fOrigin[0] = StringToFloat(szBuffer[3])
				fOrigin[1] = StringToFloat(szBuffer[4])
				fOrigin[2] = StringToFloat(szBuffer[5])
				fAngles[0] = StringToFloat(szBuffer[6])
				fAngles[1] = StringToFloat(szBuffer[7])
				fAngles[2] = StringToFloat(szBuffer[8])
				iHealth = StringToInt(szBuffer[9])
				if (iHealth == 2)
					iHealth = 999999999
				if (iHealth == 1)
					iHealth = 50
				if (StrContains(szClass, "prop_dynamic") >= 0) {
					entLoadEntity = CreateEntityByName("prop_dynamic_override")
					SetEntProp(entLoadEntity, Prop_Send, "m_nSolidType", 6)
					SetEntProp(entLoadEntity, Prop_Data, "m_nSolidType", 6)
				} else if (StrEqual(szClass, "prop_physics"))
					entLoadEntity = CreateEntityByName("prop_physics_override")
				else if (StrContains(szClass, "prop_physics") >= 0)
					entLoadEntity = CreateEntityByName(szClass)
				else
					g_iError[Client]++
				
				if (entLoadEntity != -1) {
					if (LM_SetEntityOwner(entLoadEntity, Client)) {
						if (!IsModelPrecached(szModel))
							PrecacheModel(szModel)
						DispatchKeyValue(entLoadEntity, "model", szModel)
						TeleportEntity(entLoadEntity, fOrigin, fAngles, NULL_VECTOR)
						DispatchSpawn(entLoadEntity)
						SetVariantInt(iHealth)
						AcceptEntityInput(entLoadEntity, "sethealth", -1)
						AcceptEntityInput(entLoadEntity, "disablemotion", -1)
						g_iCount[Client]++
					} else {
						RemoveEdict(entLoadEntity)
						bRegOwnerError = true
					}
				}
			}
		}
	}
	if (!IsEndOfFile(g_hFile[Client]) && !bRegOwnerError) {
		Handle hNewPack
		CreateDataTimer(0.05, Timer_Load, hNewPack)
		WritePackCell(hNewPack, Client)
		WritePackString(hNewPack, szSteamID)
	} else {
		CloseHandle(g_hFile[Client])
		g_bIsRunning[Client] = false
		LM_PrintToChat(Client, "Loaded %i props, failed to load %i props", g_iCount[Client], g_iError[Client])
		g_iCount[Client] = 0
		g_iError[Client] = 0
	}
	return Plugin_Handled
}

public Action Timer_List(Handle Timer, Handle hDataPack) {
	ResetPack(hDataPack)
	char szSteamID[32]
	new Client = ReadPackCell(hDataPack)
	ReadPackString(hDataPack, szSteamID, sizeof(szSteamID))
	
	if (!LM_IsClientValid(Client, Client))
		return Plugin_Handled
	
	if (g_hFile[Client] == INVALID_HANDLE) {
		g_hFile[Client] = OpenFile(g_szListName, "r")
		g_iTryCount[Client]++
		if (g_iTryCount[Client] < 3) {
			Handle hNewPack
			CreateDataTimer(0.2, Timer_List, hNewPack)
			WritePackCell(hNewPack, Client)
			WritePackString(hNewPack, szSteamID)
		} else {
			LM_PrintToChat(Client, "Unable to list the save! Contact admins!")
			g_hFile[Client] = INVALID_HANDLE
			g_iTryCount[Client] = 0
			return Plugin_Handled
		}
	} else {
		char szListString[255], szBuffer[3][128], szSaveName[32], szTime[16]
		PrintToChat(Client, "|| [SaveName] | [Date]")
		
		while (!IsEndOfFile(g_hFile[Client])) {
			if (ReadFileLine(g_hFile[Client], szListString, sizeof(szListString))) {
				if (StrContains(szListString, szSteamID) != -1) {
					ExplodeString(szListString, " ", szBuffer, 3, 128)
					Format(szSaveName, sizeof(szSaveName), "%s", szBuffer[1])
					Format(szTime, sizeof(szTime), "%s", szBuffer[2])
					PrintToChat(Client, "|| %s | %s", szSaveName, szTime)
					g_iCount[Client]++
				}
			}
		}
		CloseHandle(g_hFile[Client])
		g_bIsRunning[Client] = false
		if (g_iCount[Client] == 0) {
			LM_PrintToChat(Client, "You don't have any save.")
		} else {
			LM_PrintToChat(Client, "You have %i save(s).", g_iCount[Client])
			g_iCount[Client] = 0
		}
	}
	return Plugin_Handled
}

stock Save_CheckSaveName(Client, char Check[32]) {
	if (strlen(Check) > 32) {
		LM_PrintToChat(Client, "The max SaveName length is 32!")
		return false
	}
		
	for (int i = 0; i < sizeof(Symbol); i++) {
		if (FindCharInString(Check, Symbol[i]) != -1) {
			LM_PrintToChat(Client, "Symbols is not allowed in SaveName!")
			return false
		}
	}
	return true
}

public CheckSaveList(Client, char[] szMode, char[] szSaveName, char[] szSteamID) {
	g_hFile[Client] = OpenFile(g_szListName, "a+")
	if (g_hFile[Client] == INVALID_HANDLE)
		return -1
	if (StrEqual(szMode, "save")) {
		char szListString[255], szBuffer[3][255]
		while (!IsEndOfFile(g_hFile[Client]))	{
			if (ReadFileLine(g_hFile[Client], szListString, sizeof(szListString))) {
				ExplodeString(szListString, " ", szBuffer, 3, 255)
				if (StrEqual(szSteamID, szBuffer[0]) && StrEqual(szSaveName, szBuffer[1])) {
					CloseHandle(g_hFile[Client])
					return true
				}
			}
		}
		char szTime[64]
		FormatTime(szTime, sizeof(szTime), "%Y/%m/%d")
		WriteFileLine(g_hFile[Client], "%s %s %s \t\t//%N", szSteamID, szSaveName, szTime, Client)
		PrintToConsole(Client, "%s %s %s \t\t//%N", szSteamID, szSaveName, szTime, Client)
		FlushFile(g_hFile[Client])
		CloseHandle(g_hFile[Client])
		return false
	} else if (StrEqual(szMode, "delete")) {
		char szArrayString[64][128], szArrayBuffer[64][3][128]
		for (int i = 0; i < 64; i++) {
			ReadFileLine(g_hFile[Client], szArrayString[i], sizeof(szArrayString))
			ExplodeString(szArrayString[i], " ", szArrayBuffer[i], 3, sizeof(szArrayBuffer))
			if (StrEqual(szSteamID, szArrayBuffer[i][0]) && StrEqual(szSaveName, szArrayBuffer[i][1]))
				szArrayString[i] = ""
				
			if (IsEndOfFile(g_hFile[Client]))
				break
		}
		CloseHandle(g_hFile[Client])
		if (!DeleteFile(g_szListName))
			return -1
		
		SortStrings(szArrayString, sizeof(szArrayString))
		g_hFile[Client] = OpenFile(g_szListName, "w+")
		for (int i = 0; i < 64; i++) {
			if (StrContains(szArrayString[i], "0-") == 0)
				WriteFileLine(g_hFile[Client], "%s", szArrayString[i])
		}
		FlushFile(g_hFile[Client])
		CloseHandle(g_hFile[Client])
		return true
	}
	CloseHandle(g_hFile[Client])
	return -1
}


