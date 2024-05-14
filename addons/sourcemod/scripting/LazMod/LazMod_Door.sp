

#include <sourcemod>
#include <sdktools>

#include <vphysics>
#include <smlib>

#include <lazmod>


char g_szDDoorTarget[MAXPLAYERS][64]
char g_szDDoorModel[MAXPLAYERS][128]

public Plugin myinfo = {
	name = "LazMod - Door",
	author = "LaZycAt, hjkwe654",
	description = "Create Doors.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {	
	RegAdminCmd("sm_ddoor", Command_SpawnDynamicDoor, 0, "Create dynamic doors.")
	RegAdminCmd("sm_pdoor", Command_SpawnPropDoor, 0, "Create prop doors.")

	PrintToServer( "LazMod Door loaded!" )
}

/**
 * TODO: Use sourcemod to hook button outputs instead of built-in
 */
public Action Command_SpawnDynamicDoor(plyClient, args) {
	if(!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient))
		return Plugin_Handled
	
	char szType[4], szOutput[64]
	GetCmdArg(1, szType, sizeof(szType))
	static entEntity
	char szModel[128]
	
	if (StrEqual(szType[0], "1") || StrEqual(szType[0], "2") || StrEqual(szType[0], "3") || StrEqual(szType[0], "4") || StrEqual(szType[0], "5") || StrEqual(szType[0], "6") || StrEqual(szType[0], "7")) {
		
		float vAimPos[3]
		LM_ClientAimPos(plyClient, vAimPos)
		
		switch(szType[0]) {
			case '1': {
				szModel = "models/props_combine/combine_door01.mdl"
				vAimPos[2] += 95
			}
			case '2': szModel = "models/combine_gate_citizen.mdl"
			case '3': szModel = "models/combine_gate_Vehicle.mdl"
			case '4': szModel = "models/props_doors/doorKLab01.mdl"
			case '5': szModel = "models/props_lab/blastdoor001c.mdl"
			case '6': szModel = "models/props_lab/elevatordoor.mdl"
			case '7': szModel = "models/props_lab/RavenDoor.mdl"
		}
		
		int entDoor = LM_CreateEntity(plyClient, "prop_dynamic", szModel, vAimPos)
		if (entDoor == -1)
			return Plugin_Handled

		DispatchSpawn(entDoor)

	} else if (StrEqual(szType[0], "a") || StrEqual(szType[0], "b") || StrEqual(szType[0], "c")) {
	
		entEntity = LM_GetClientAimEntity(plyClient)
		if (entEntity == -1)
			return Plugin_Handled
		
		if (StrEqual(szType[0], "a")) {
			Format(g_szDDoorTarget[plyClient], sizeof(g_szDDoorTarget[]), "door%d", GetRandomInt(1000, 5000))
			DispatchKeyValue(entEntity, "targetname", g_szDDoorTarget[plyClient])
			LM_GetEntModel(entEntity, g_szDDoorModel[plyClient], sizeof(g_szDDoorModel[]))

			LM_PrintToChat(plyClient, "Door selected, now use !ddoor b or c on button prop", entEntity)
		} else if (StrEqual(szType[0], "b") || StrEqual(szType[0], "c")) {

			if (StrEqual(g_szDDoorTarget[plyClient], "") || StrEqual(g_szDDoorModel[plyClient], "")) {
				LM_PrintToChat(plyClient, "You have not select a door yet!")
				return Plugin_Handled
			}
			szModel = g_szDDoorModel[plyClient]
			
			char szEvent[16] = "OnHealthChanged"

			if (StrEqual(szType[0], "c")) {
				char szButtonClass[128]
				GetEdictClassname(entEntity, szButtonClass, sizeof(szButtonClass))
				if (!String_StartsWith(szButtonClass, "prop_physics")) {
					LM_PrintToChat(plyClient, "You can only use this type of button on prop_physics entities!")
					return Plugin_Handled
				}
				DispatchKeyValue(entEntity, "spawnflags", "258")
				szEvent = "OnPlayerUse"
			}

			if (StrEqual(szModel, "models/props_lab/blastdoor001c.mdl")) {
				Format(szOutput, sizeof(szOutput), "%s,setanimation,dog_open,0", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
				Format(szOutput, sizeof(szOutput), "%s,DisableCollision,,1", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
				Format(szOutput, sizeof(szOutput), "%s,setanimation,close,5", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
				Format(szOutput, sizeof(szOutput), "%s,EnableCollision,,5.1", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
			} else if (StrEqual(szModel, "models/props_lab/RavenDoor.mdl")) {
				Format(szOutput, sizeof(szOutput), "%s,setanimation,RavenDoor_Open,0", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
				Format(szOutput, sizeof(szOutput), "%s,setanimation,RavenDoor_Drop,7", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
			} else {
				Format(szOutput, sizeof(szOutput), "%s,setanimation,open,0", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
				Format(szOutput, sizeof(szOutput), "%s,setanimation,close,4", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
			}
			
			LM_PrintToChat(plyClient, "Button selected, try %s your button", (StrEqual(szType[0], "b")?"shoot":"press E on"))
		}


	} else {
		LM_PrintToChat(plyClient, "Usage: !ddoor <door type/option>")
		LM_PrintToChat(plyClient, "!ddoor 1~7 = Spawn a dynamic door")
		LM_PrintToChat(plyClient, "!ddoor a = Select door")
		LM_PrintToChat(plyClient, "!ddoor b = Set button (Shoot to open)")
		LM_PrintToChat(plyClient, "!ddoor c = Set button (Press to open)(Physics only)")
	}


	char szArgString[256]
	GetCmdArgString(szArgString, sizeof(szArgString))
	LM_LogCmd(plyClient, "sm_ddoor", szArgString)
	return Plugin_Handled
}

public Action Command_SpawnPropDoor(plyClient, args) {
	if(!LM_AllowToLazMod(plyClient) || LM_IsBlacklisted(plyClient))
		return Plugin_Handled
	
	char szType[4], szOutput[64]
	GetCmdArg(1, szType, sizeof(szType))
	static entEntity
	char szModel[128]
	
	if (StrEqual(szType[0], "1") || StrEqual(szType[0], "2") || StrEqual(szType[0], "3") || StrEqual(szType[0], "4") || StrEqual(szType[0], "5") || StrEqual(szType[0], "6") || StrEqual(szType[0], "7")) {
		
		float vAimPos[3]
		LM_ClientAimPos(plyClient, vAimPos)
		
		switch(szType[0]) {
			case '1': {
				szModel = "models/props_combine/combine_door01.mdl"
				vAimPos[2] += 95
			}
			case '2': szModel = "models/combine_gate_citizen.mdl"
			case '3': szModel = "models/combine_gate_Vehicle.mdl"
			case '4': szModel = "models/props_doors/doorKLab01.mdl"
			case '5': szModel = "models/props_lab/blastdoor001c.mdl"
			case '6': szModel = "models/props_lab/elevatordoor.mdl"
			case '7': szModel = "models/props_lab/RavenDoor.mdl"
		}
		
		int entDoor = LM_CreateEntity(plyClient, "prop_dynamic", szModel, vAimPos)
		if (entDoor == -1)
			return Plugin_Handled

		DispatchSpawn(entDoor)

	} else if (StrEqual(szType[0], "a") || StrEqual(szType[0], "b") || StrEqual(szType[0], "c")) {
	
		entEntity = LM_GetClientAimEntity(plyClient)
		if (entEntity == -1)
			return Plugin_Handled
		
		if (StrEqual(szType[0], "a")) {
			Format(g_szDDoorTarget[plyClient], sizeof(g_szDDoorTarget[]), "door%d", GetRandomInt(1000, 5000))
			DispatchKeyValue(entEntity, "targetname", g_szDDoorTarget[plyClient])
			LM_GetEntModel(entEntity, g_szDDoorModel[plyClient], sizeof(g_szDDoorModel[]))

			LM_PrintToChat(plyClient, "Door selected, now use !ddoor b or c on button prop", entEntity)
		} else if (StrEqual(szType[0], "b") || StrEqual(szType[0], "c")) {

			if (StrEqual(g_szDDoorTarget[plyClient], "") || StrEqual(g_szDDoorModel[plyClient], "")) {
				LM_PrintToChat(plyClient, "You have not select a door yet!")
				return Plugin_Handled
			}
			szModel = g_szDDoorModel[plyClient]
			
			char szEvent[16] = "OnHealthChanged"

			if (StrEqual(szType[0], "c")) {
				char szButtonClass[128]
				GetEdictClassname(entEntity, szButtonClass, sizeof(szButtonClass))
				if (!String_StartsWith(szButtonClass, "prop_physics")) {
					LM_PrintToChat(plyClient, "You can only use this type of button on prop_physics entities!")
					return Plugin_Handled
				}
				DispatchKeyValue(entEntity, "spawnflags", "258")
				szEvent = "OnPlayerUse"
			}

			if (StrEqual(szModel, "models/props_lab/blastdoor001c.mdl")) {
				Format(szOutput, sizeof(szOutput), "%s,setanimation,dog_open,0", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
				Format(szOutput, sizeof(szOutput), "%s,DisableCollision,,1", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
				Format(szOutput, sizeof(szOutput), "%s,setanimation,close,5", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
				Format(szOutput, sizeof(szOutput), "%s,EnableCollision,,5.1", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
			} else if (StrEqual(szModel, "models/props_lab/RavenDoor.mdl")) {
				Format(szOutput, sizeof(szOutput), "%s,setanimation,RavenDoor_Open,0", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
				Format(szOutput, sizeof(szOutput), "%s,setanimation,RavenDoor_Drop,7", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
			} else {
				Format(szOutput, sizeof(szOutput), "%s,setanimation,open,0", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
				Format(szOutput, sizeof(szOutput), "%s,setanimation,close,4", g_szDDoorTarget[plyClient])
				DispatchKeyValue(entEntity, szEvent, szOutput)
			}
			
			LM_PrintToChat(plyClient, "Button selected, try %s your button", (StrEqual(szType[0], "b")?"shoot":"press E on"))
		}


	} else {
		LM_PrintToChat(plyClient, "Usage: !ddoor <door type/option>")
		LM_PrintToChat(plyClient, "!ddoor 1~7 = Spawn a dynamic door")
		LM_PrintToChat(plyClient, "!ddoor a = Select door")
		LM_PrintToChat(plyClient, "!ddoor b = Set button (Shoot to open)")
		LM_PrintToChat(plyClient, "!ddoor c = Set button (Press to open)(Physics only)")
	}


	char szArgString[256]
	GetCmdArgString(szArgString, sizeof(szArgString))
	LM_LogCmd(plyClient, "sm_ddoor", szArgString)
	return Plugin_Handled
}
