

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>




Handle g_hCookieSDoorTarget
Handle g_hCookieSDoorModel

public Plugin myinfo = {
	name = "LazMod - Door",
	author = "LaZycAt, hjkwe654",
	description = "Create Doors.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {	
	RegAdminCmd("sm_door", Command_SpawnDoor, 0, "Doors creator.")
	g_hCookieSDoorTarget = RegClientCookie("cookie_SDoorTarget", "For SDoor.", CookieAccess_Private)
	g_hCookieSDoorModel = RegClientCookie("cookie_SDoorModel", "For SDoor.", CookieAccess_Private)
}

public Action Command_SpawnDoor(Client, args) {
	if(!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled
	
	char szDoorTarget[16], szType[4], szFormatStr[64], szNameStr[8]
	float fAimPos[3]
	LM_ClientAimPos(Client, fAimPos)
	GetCmdArg(1, szType, sizeof(szType))
	static entEntity
	char szModel[128]
	
	if (StrEqual(szType[0], "1") || StrEqual(szType[0], "2") || StrEqual(szType[0], "3") || StrEqual(szType[0], "4") || StrEqual(szType[0], "5") || StrEqual(szType[0], "6") || StrEqual(szType[0], "7")) {
		int entDoor = CreateEntityByName("prop_dynamic")
		
		switch(szType[0]) {
			case '1': szModel = "models/props_combine/combine_door01.mdl"
			case '2': szModel = "models/combine_gate_citizen.mdl"
			case '3': szModel = "models/combine_gate_Vehicle.mdl"
			case '4': szModel = "models/props_doors/doorKLab01.mdl"
			case '5': szModel = "models/props_lab/blastdoor001c.mdl"
			case '6': szModel = "models/props_lab/elevatordoor.mdl"
			case '7': szModel = "models/props_lab/RavenDoor.mdl"
		}
		
		DispatchKeyValue(entDoor, "model", szModel)
		SetEntProp(entDoor, Prop_Send, "m_nSolidType", 6)
		LM_SetEntityOwner(entDoor, Client)
		
		TeleportEntity(entDoor, fAimPos, NULL_VECTOR, NULL_VECTOR)
		DispatchSpawn(entDoor)
	} else if (StrEqual(szType[0], "a") || StrEqual(szType[0], "b") || StrEqual(szType[0], "c")) {
	
		entEntity = LM_GetClientAimEntity(Client)
		if (entEntity == -1)
			return Plugin_Handled
		
		switch(szType[0]) {
			case 'a': {
				new iName = GetRandomInt(1000, 5000)
				
				IntToString(iName, szNameStr, sizeof(szNameStr))
				Format(szFormatStr, sizeof(szFormatStr), "door%s", szNameStr)
				DispatchKeyValue(entEntity, "targetname", szFormatStr)
				
				GetEntPropString(entEntity, Prop_Data, "m_ModelName", szModel, sizeof(szModel))
				SetClientCookie(Client, g_hCookieSDoorTarget, szFormatStr)
				SetClientCookie(Client, g_hCookieSDoorModel, szModel)
			}
			case 'b': {
				GetClientCookie(Client, g_hCookieSDoorTarget, szDoorTarget, sizeof(szDoorTarget))
				GetClientCookie(Client, g_hCookieSDoorModel, szModel, sizeof(szModel))
				
				if (StrEqual(szModel, "models/props_lab/blastdoor001c.mdl")) {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,dog_open,0", szDoorTarget)
					DispatchKeyValue(entEntity, "OnHealthChanged", szFormatStr)
					Format(szFormatStr, sizeof(szFormatStr), "%s,DisableCollision,,1", szDoorTarget)
					DispatchKeyValue(entEntity, "OnHealthChanged", szFormatStr)
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,close,5", szDoorTarget)
					DispatchKeyValue(entEntity, "OnHealthChanged", szFormatStr)
					Format(szFormatStr, sizeof(szFormatStr), "%s,EnableCollision,,5.1", szDoorTarget)
					DispatchKeyValue(entEntity, "OnHealthChanged", szFormatStr)
				} else if (StrEqual(szModel, "models/props_lab/RavenDoor.mdl")) {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,RavenDoor_Open,0", szDoorTarget)
					DispatchKeyValue(entEntity, "OnHealthChanged", szFormatStr)
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,RavenDoor_Drop,7", szDoorTarget)
					DispatchKeyValue(entEntity, "OnHealthChanged", szFormatStr)
				} else {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,open,0", szDoorTarget)
					DispatchKeyValue(entEntity, "OnHealthChanged", szFormatStr)
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,close,4", szDoorTarget)
					DispatchKeyValue(entEntity, "OnHealthChanged", szFormatStr)
				}
			}
			case 'c': {
				GetClientCookie(Client, g_hCookieSDoorTarget, szDoorTarget, sizeof(szDoorTarget))
				GetClientCookie(Client, g_hCookieSDoorModel, szModel, sizeof(szModel))
				DispatchKeyValue(entEntity, "spawnflags", "258")
				
				if (StrEqual(szModel, "models/props_lab/blastdoor001c.mdl")) {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,dog_open,0", szDoorTarget)
					DispatchKeyValue(entEntity, "OnPlayerUse", szFormatStr)
					Format(szFormatStr, sizeof(szFormatStr), "%s,DisableCollision,,1", szDoorTarget)
					DispatchKeyValue(entEntity, "OnPlayerUse", szFormatStr)
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,close,5", szDoorTarget)
					DispatchKeyValue(entEntity, "OnPlayerUse", szFormatStr)
					Format(szFormatStr, sizeof(szFormatStr), "%s,EnableCollision,,5.1", szDoorTarget)
					DispatchKeyValue(entEntity, "OnPlayerUse", szFormatStr)
				} else if (StrEqual(szModel, "models/props_lab/RavenDoor.mdl")) {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,RavenDoor_Open,0", szDoorTarget)
					DispatchKeyValue(entEntity, "OnPlayerUse", szFormatStr)
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,RavenDoor_Drop,7", szDoorTarget)
					DispatchKeyValue(entEntity, "OnPlayerUse", szFormatStr)
				} else {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,open,0", szDoorTarget)
					DispatchKeyValue(entEntity, "OnPlayerUse", szFormatStr)
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,close,4", szDoorTarget)
					DispatchKeyValue(entEntity, "OnPlayerUse", szFormatStr)
				}
			}
		}
	} else {
		LM_PrintToChat(Client, "Usage: !door <type/option>")
		LM_PrintToChat(Client, "!door 1~7 = Spawn door")
		LM_PrintToChat(Client, "!door a = Select door")
		LM_PrintToChat(Client, "!door b = Select button (Shoot to open)")
		LM_PrintToChat(Client, "!door c = Select button (Press to open)")
	}
	return Plugin_Handled
}
