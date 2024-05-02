

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <regex>

#include <vphysics>
#include <smlib>

#include <lazmod>
#include <lazmod_stocks>


Handle g_hFile[MAXPLAYERS]
char g_szFileName[128][MAXPLAYERS]
char g_szListName[128]

bool g_bIsRunning[MAXPLAYERS] = {false, ...}
int g_iCount[MAXPLAYERS]
int g_iError[MAXPLAYERS]
int g_iTryCount[MAXPLAYERS]

char g_szDataTypes[9][16] = {
    "classname",
    "model",
    "origin",
    "angles",
    "rendercolor",
    "alpha",
    "ncself",
    "health",
    "moveable"
}



public Plugin myinfo = {
	name = "LazMod - SaveSpawn",
	author = "LaZy cAt",
	description = "Saves the building progress.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	RegAdminCmd("sm_ss", Command_SaveSpawn, ADMFLAG_CUSTOM1, "Save system ftw.")


	PrintToServer( "LazMod Save loaded!" )
}

public Action Command_SaveSpawn(plyClient, args) {



	
	if (g_bIsRunning[plyClient]) {
		LM_PrintToChat(plyClient, "Process is already running. Please Wait...")
		return Plugin_Handled
	}
	if (!LM_AllowToUse(plyClient) || LM_IsBlacklisted(plyClient) && LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	
	char szMode[8], szSaveName[32], szSteamID[32]
	GetCmdArg(1, szMode, sizeof(szMode))
	GetCmdArg(2, szSaveName, sizeof(szSaveName))
	GetClientAuthId(plyClient, AuthId_Steam2, szSteamID, sizeof(szSteamID))
	ReplaceString(szSteamID, sizeof(szSteamID), ":", "-")
	// ReplaceString(szSteamID, sizeof(szSteamID), "STEAM_", "")
	g_szFileName[plyClient] = ""
	BuildPath(Path_SM, g_szFileName[plyClient], sizeof(g_szFileName), "data/lazmodsaves/%s#%s.csv", szSteamID, szSaveName)
	LM_PrintToChat(plyClient, "%s", g_szFileName[plyClient])
	g_hFile[plyClient] = INVALID_HANDLE
	g_iTryCount[plyClient] = 0
	g_iCount[plyClient] = 0
	g_iError[plyClient] = 0
	
	String_ToLower(szMode, szMode, sizeof(szMode))

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
				WritePackString(hLoadPack, "0")
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
		SaveSpawn_List(plyClient)
		return Plugin_Handled
	}

	SaveSpawn_Usage(plyClient)

	return Plugin_Handled
}

void SaveSpawn_Usage(int plyClient) {
	LM_PrintToChat(plyClient, " Usage:")
	LM_PrintToChat(plyClient, " Save name can only be letters and numbers.")
	LM_PrintToChat(plyClient, " !ss save <SaveName>")
	LM_PrintToChat(plyClient, " !ss load <SaveName>")
	LM_PrintToChat(plyClient, " !ss info <SaveName>")
	LM_PrintToChat(plyClient, " !ss delete <SaveName>")
	LM_PrintToChat(plyClient, " !ss list")
	
}

void SaveSpawn_Save(int plyClient, char[] szSaveName) {
	// Handle hListPack
	// char szSteamID[32]
	// GetClientAuthId(plyClient, AuthId_Steam2, szSteamID, sizeof(szSteamID))
	// ReplaceString(szSteamID, sizeof(szSteamID), ":", "-")

}

void SaveSpawn_Load(int plyClient, char[] szSaveName) {
	// Handle hListPack
	// char szSteamID[32]
	// GetClientAuthId(plyClient, AuthId_Steam2, szSteamID, sizeof(szSteamID))
	// ReplaceString(szSteamID, sizeof(szSteamID), ":", "-")
	
}

void SaveSpawn_Info(int plyClient, char[] szSaveName) {
	// char[] input = "[1,2,3,4,5]";
	// JSON_Array original = view_as<JSON_Array>(json_decode(input));
	// PrintToServer("write to file %b ", original.WriteToFile(szListName));

	// JSON_Object read = json_read_from_file(szListName);
	// PrintToServer("read from file %b", read != null);
	
	// // _json_encode(read);

	// // Test_AssertStringsEqual("input matches output", input, json_encode_output);

	// json_cleanup_and_delete(original);
	// json_cleanup_and_delete(read);
	
}

void SaveSpawn_Delete(int plyClient, char[] szSaveName) {
	// Handle hListPack
	// char szSteamID[32]
	// GetClientAuthId(plyClient, AuthId_Steam2, szSteamID, sizeof(szSteamID))
	// ReplaceString(szSteamID, sizeof(szSteamID), ":", "-")
	
}

void SaveSpawn_List(int plyClient) {
	// Handle hListPack
	// char szSteamID[32]
	// GetClientAuthId(plyClient, AuthId_Steam2, szSteamID, sizeof(szSteamID))
	// ReplaceString(szSteamID, sizeof(szSteamID), ":", "-")
	// CreateDataTimer(0.01, Timer_List, hListPack)
	// WritePackCell(hListPack, plyClient)
	// WritePackString(hListPack, szSteamID)
}


public Action Timer_Save(Handle hTimer, Handle hDataPack) {
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

public Action Timer_Load(Handle hTimer, Handle hDataPack) {
	ResetPack(hDataPack)
	char szSteamID[32], szDataHeader[255]
	bool bRegOwnerError = false
	int plyClient = ReadPackCell(hDataPack)
	ReadPackString(hDataPack, szSteamID, sizeof(szSteamID))
	ReadPackString(hDataPack, szDataHeader, sizeof(szDataHeader))
	
	if (!LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	
	if (g_hFile[plyClient] == INVALID_HANDLE) {
		g_hFile[plyClient] = OpenFile(g_szFileName[plyClient], "r")
		g_iTryCount[plyClient]++
		if (g_iTryCount[plyClient] < 3) {
			Handle hNewPack
			CreateDataTimer(0.2, Timer_Load, hNewPack)
			WritePackCell(hNewPack, plyClient)
			WritePackString(hNewPack, szSteamID)
			WritePackString(hNewPack, szDataHeader)
		} else {
			LM_PrintToChat(plyClient, "Save found but unable to load! Contact admins!")
			g_hFile[plyClient] = INVALID_HANDLE
			g_iTryCount[plyClient] = 0
			return Plugin_Handled
		}
	} else {
		char szLoadString[255]
		if (ReadFileLine(g_hFile[plyClient], szLoadString, sizeof(szLoadString))) {
			
			if (String_StartsWith(szLoadString, "###")) {
				// pass
				
			} else if (String_StartsWith(szLoadString, "#")) {
				char szBuffer[2][255]
				ReplaceString(szLoadString, sizeof(szLoadString), "# ", "")

				ExplodeString(szLoadString, "\t", szBuffer, sizeof(szBuffer), sizeof(szBuffer[]))
				String_Trim(szBuffer[1], szBuffer[1], sizeof(szBuffer[]))
				if (String_StartsWith(szBuffer[0], "propcount"))
					LM_PrintToChat(plyClient, "Found %s props in save, start loading...", szBuffer[1] )

			} else if (StrContains(szLoadString, "classname") != -1 && StrContains(szLoadString, "origin") != -1) {
				// Makes sure data loaded in correct order
				szDataHeader = szLoadString
				
			} else if (StrContains(szLoadString, "prop_physics") != -1 || StrContains(szLoadString, "prop_dynamic") != -1) {
				int entLoadEntity = -1
				char szDataBuffer[9][255], szHeaderBuffer[9][255], szClass[32], szModel[128], szColor[16], szAlpha[4]
				char szOrigin[3][16], szAngles[3][16]
				float vOrigin[3], vAngles[3]
				int iNCself, iHealth, iMoveable
				ExplodeString(szDataHeader, "\t", szHeaderBuffer, 9, 255)
				ExplodeString(szLoadString, "\t", szDataBuffer, 9, 255)

				for (new i = 0; i < sizeof(szDataBuffer); i++) {
					if (StrEqual(szHeaderBuffer[i], "classname")) {
						Format(szClass, sizeof(szClass), "%s", szDataBuffer[i])
					} else if (StrEqual(szHeaderBuffer[i], "model")) {
						Format(szModel, sizeof(szModel), "%s", szDataBuffer[i])
					} else if (StrEqual(szHeaderBuffer[i], "origin")) {
						ExplodeString(szDataBuffer[i], ",", szOrigin, sizeof(szOrigin), sizeof(szOrigin[]))
						vOrigin[0] = StringToFloat(szOrigin[0])
						vOrigin[1] = StringToFloat(szOrigin[1])
						vOrigin[2] = StringToFloat(szOrigin[2])
					} else if (StrEqual(szHeaderBuffer[i], "angles")) {
						ExplodeString(szDataBuffer[i], ",", szAngles, sizeof(szAngles), sizeof(szAngles[]))
						vAngles[0] = StringToFloat(szAngles[0])
						vAngles[1] = StringToFloat(szAngles[1])
						vAngles[2] = StringToFloat(szAngles[2])
					} else if (StrEqual(szHeaderBuffer[i], "rendercolor")) {
						if (strlen(szDataBuffer[i]) < 1)
							szDataBuffer[i] = "255 255 255"
						Format(szColor, sizeof(szColor), "%s", szDataBuffer[i])
					} else if (StrEqual(szHeaderBuffer[i], "alpha")) {
						if (strlen(szDataBuffer[i]) < 1)
							szDataBuffer[i] = "255"
						Format(szAlpha, sizeof(szAlpha), "%s", szDataBuffer[i])
					} else if (StrEqual(szHeaderBuffer[i], "ncself")) {
						if (strlen(szDataBuffer[i]) < 1)
							szDataBuffer[i] = "0"
						iNCself = StringToInt(szDataBuffer[i])
					} else if (StrEqual(szHeaderBuffer[i], "health")) {
						if (strlen(szDataBuffer[i]) < 1)
							szDataBuffer[i] = "0"
						iHealth = StringToInt(szDataBuffer[i])
					} else if (StrEqual(szHeaderBuffer[i], "moveable")) {
						if (strlen(szDataBuffer[i]) < 1)
							szDataBuffer[i] = "0"
						iMoveable = StringToInt(szDataBuffer[i])
					}
				}
				
				// if (iHealth == 2)
				// 	iHealth = 999999999
				// if (iHealth == 1)
				// 	iHealth = 50
				
				if (StrEqual(szClass, "prop_dynamic")) {
					entLoadEntity = CreateEntityByName("prop_dynamic_override")
					SetEntProp(entLoadEntity, Prop_Send, "m_nSolidType", 6)
					SetEntProp(entLoadEntity, Prop_Data, "m_nSolidType", 6)
				} else if (StrEqual(szClass, "prop_physics")) {
					entLoadEntity = CreateEntityByName("prop_physics_override")
				} else {
					g_iError[plyClient]++
				}
				
				if (entLoadEntity != -1) {
					if (LM_SetEntityOwner(entLoadEntity, plyClient)) {
						if (!IsModelPrecached(szModel))
							PrecacheModel(szModel)
						DispatchKeyValue(entLoadEntity, "model", szModel)
						DispatchKeyValue(entLoadEntity, "rendermode", "5")
						DispatchKeyValue(entLoadEntity, "rendercolor", szColor)
						DispatchKeyValue(entLoadEntity, "renderamt", szAlpha)
						TeleportEntity(entLoadEntity, vOrigin, vAngles, NULL_VECTOR)
						DispatchSpawn(entLoadEntity)
						// SetVariantInt(iHealth)
						// AcceptEntityInput(entLoadEntity, "sethealth", -1)
						AcceptEntityInput(entLoadEntity, "disablemotion", -1)
						g_iCount[plyClient]++
						if (g_iCount[plyClient] % 100 == 0)
							LM_PrintToChat(plyClient, "Loaded %d props, still going...", g_iCount[plyClient])

					} else {
						if (!LM_CheckMaxEdict()) {
							LM_PrintToChat(plyClient, "Server has no more room for new props, current loading will be terminated!")
						}
						RemoveEdict(entLoadEntity)
						bRegOwnerError = true
					}
				}
			}
		}
		if (!IsEndOfFile(g_hFile[plyClient]) && !bRegOwnerError) {
			Handle hNewPack
			CreateDataTimer(0.05, Timer_Load, hNewPack)
			WritePackCell(hNewPack, plyClient)
			WritePackString(hNewPack, szSteamID)
			WritePackString(hNewPack, szDataHeader)
		} else {
			CloseHandle(g_hFile[plyClient])
			g_bIsRunning[plyClient] = false
			LM_PrintToChat(plyClient, "Loaded %i props, failed to load %i props", g_iCount[plyClient], g_iError[plyClient])
			g_iCount[plyClient] = 0
			g_iError[plyClient] = 0
		}
	}
	return Plugin_Handled
}

public Action Timer_List(Handle hTimer, Handle hDataPack) {
	ResetPack(hDataPack)
	char szSteamID[32]
	int plyClient = ReadPackCell(hDataPack)
	ReadPackString(hDataPack, szSteamID, sizeof(szSteamID))
	
	if (!LM_IsClientValid(plyClient, plyClient))
		return Plugin_Handled
	
	if (g_hFile[plyClient] == INVALID_HANDLE) {
		g_hFile[plyClient] = OpenFile(g_szListName, "r")
		g_iTryCount[plyClient]++
		if (g_iTryCount[plyClient] < 3) {
			Handle hNewPack
			CreateDataTimer(0.2, Timer_List, hNewPack)
			WritePackCell(hNewPack, plyClient)
			WritePackString(hNewPack, szSteamID)
		} else {
			LM_PrintToChat(plyClient, "Unable to list the save! Contact admins!")
			g_hFile[plyClient] = INVALID_HANDLE
			g_iTryCount[plyClient] = 0
			return Plugin_Handled
		}
	} else {
		char szListString[255], szBuffer[3][128], szSaveName[32], szTime[16]
		PrintToChat(plyClient, "|| [SaveName] | [Date]")
		
		while (!IsEndOfFile(g_hFile[plyClient])) {
			if (ReadFileLine(g_hFile[plyClient], szListString, sizeof(szListString))) {
				if (StrContains(szListString, szSteamID) != -1) {
					ExplodeString(szListString, " ", szBuffer, 3, 128)
					Format(szSaveName, sizeof(szSaveName), "%s", szBuffer[1])
					Format(szTime, sizeof(szTime), "%s", szBuffer[2])
					PrintToChat(plyClient, "|| %s | %s", szSaveName, szTime)
					g_iCount[plyClient]++
				}
			}
		}
		CloseHandle(g_hFile[plyClient])
		g_bIsRunning[plyClient] = false
		if (g_iCount[plyClient] == 0) {
			LM_PrintToChat(plyClient, "You don't have any save.")
		} else {
			LM_PrintToChat(plyClient, "You have %i save(s).", g_iCount[plyClient])
			g_iCount[plyClient] = 0
		}
	}
	return Plugin_Handled
}

stock Save_CheckSaveName(plyClient, char szSaveName[32]) {
	if (strlen(szSaveName) > 32) {
		LM_PrintToChat(plyClient, "The max SaveName length is 32!")
		return false
	}
	
	Regex hRegex = new Regex("^[A-Za-z0-9]+$")
	if (hRegex.Match(szSaveName))
		return true

	
	return false
}

public CheckSaveList(plyClient, char[] szMode, char[] szSaveName, char[] szSteamID) {
	g_hFile[plyClient] = OpenFile(g_szListName, "a+")
	if (g_hFile[plyClient] == INVALID_HANDLE)
		return -1
	if (StrEqual(szMode, "save")) {
		char szListString[255], szBuffer[3][255]
		while (!IsEndOfFile(g_hFile[plyClient]))	{
			if (ReadFileLine(g_hFile[plyClient], szListString, sizeof(szListString))) {
				ExplodeString(szListString, " ", szBuffer, 3, 255)
				if (StrEqual(szSteamID, szBuffer[0]) && StrEqual(szSaveName, szBuffer[1])) {
					CloseHandle(g_hFile[plyClient])
					return true
				}
			}
		}
		char szTime[64]
		FormatTime(szTime, sizeof(szTime), "%Y/%m/%d")
		WriteFileLine(g_hFile[plyClient], "%s %s %s \t\t//%N", szSteamID, szSaveName, szTime, plyClient)
		PrintToConsole(plyClient, "%s %s %s \t\t//%N", szSteamID, szSaveName, szTime, plyClient)
		FlushFile(g_hFile[plyClient])
		CloseHandle(g_hFile[plyClient])
		return false
	} else if (StrEqual(szMode, "delete")) {
		char szArrayString[64][128], szArrayBuffer[64][3][128]
		for (int i = 0; i < 64; i++) {
			ReadFileLine(g_hFile[plyClient], szArrayString[i], sizeof(szArrayString))
			ExplodeString(szArrayString[i], " ", szArrayBuffer[i], 3, sizeof(szArrayBuffer))
			if (StrEqual(szSteamID, szArrayBuffer[i][0]) && StrEqual(szSaveName, szArrayBuffer[i][1]))
				szArrayString[i] = ""
				
			if (IsEndOfFile(g_hFile[plyClient]))
				break
		}
		CloseHandle(g_hFile[plyClient])
		if (!DeleteFile(g_szListName))
			return -1
		
		SortStrings(szArrayString, sizeof(szArrayString))
		g_hFile[plyClient] = OpenFile(g_szListName, "w+")
		for (int i = 0; i < 64; i++) {
			if (StrContains(szArrayString[i], "0-") == 0)
				WriteFileLine(g_hFile[plyClient], "%s", szArrayString[i])
		}
		FlushFile(g_hFile[plyClient])
		CloseHandle(g_hFile[plyClient])
		return true
	}
	CloseHandle(g_hFile[plyClient])
	return -1
}


