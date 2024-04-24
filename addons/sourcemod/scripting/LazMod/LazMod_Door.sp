#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>

new bool:g_bClientLang[MAXPLAYERS];
new Handle:g_hCookieClientLang;

new Handle:g_hCookieSDoorTarget;
new Handle:g_hCookieSDoorModel;

public Plugin:myinfo = {
	name = "BuildMod - Door",
	author = "LaZycAt, hjkwe654",
	description = "Create Doors.",
	version = LAZMOD_VER,
	url = ""
};

public OnPluginStart() {	
	RegAdminCmd("sm_sdoor", Command_SpawnDoor, ADMFLAG_CUSTOM1, "Doors creator.");
	g_hCookieSDoorTarget = RegClientCookie("cookie_SDoorTarget", "For SDoor.", CookieAccess_Private);
	g_hCookieSDoorModel = RegClientCookie("cookie_SDoorModel", "For SDoor.", CookieAccess_Private);
	g_hCookieClientLang = RegClientCookie("cookie_BuildModClientLang", "BuildMod Client Language.", CookieAccess_Private);
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

public Action:Command_SpawnDoor(Client, args) {
	if(!LM_AllowToUse(Client) || LM_IsBlacklisted(Client))
		return Plugin_Handled;
	
	decl String:szDoorTarget[16], String:szType[4], String:szFormatStr[64], String:szNameStr[8];
	decl Float:iAim[3];
	LM_ClientAimPos(Client, iAim);
	GetCmdArg(1, szType, sizeof(szType));
	static iEntity;
	new String:szModel[128];
	
	if (StrEqual(szType[0], "1") || StrEqual(szType[0], "2") || StrEqual(szType[0], "3") || StrEqual(szType[0], "4") || StrEqual(szType[0], "5") || StrEqual(szType[0], "6") || StrEqual(szType[0], "7")) {
		new Obj_Door = CreateEntityByName("prop_dynamic");
		
		switch(szType[0]) {
			case '1': szModel = "models/props_combine/combine_door01.mdl";
			case '2': szModel = "models/combine_gate_citizen.mdl";
			case '3': szModel = "models/combine_gate_Vehicle.mdl";
			case '4': szModel = "models/props_doors/doorKLab01.mdl";
			case '5': szModel = "models/props_lab/blastdoor001c.mdl";
			case '6': szModel = "models/props_lab/elevatordoor.mdl";
			case '7': szModel = "models/props_lab/RavenDoor.mdl";
		}
		
		DispatchKeyValue(Obj_Door, "model", szModel);
		SetEntProp(Obj_Door, Prop_Send, "m_nSolidType", 6);
		LM_SetEntityOwner(Obj_Door, Client);
		
		TeleportEntity(Obj_Door, iAim, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(Obj_Door);
	} else if (StrEqual(szType[0], "a") || StrEqual(szType[0], "b") || StrEqual(szType[0], "c")) {
	
		iEntity = LM_ClientAimEntity(Client);
		if (iEntity == -1)
			return Plugin_Handled;
		
		switch(szType[0]) {
			case 'a': {
				new iName = GetRandomInt(1000, 5000);
				
				IntToString(iName, szNameStr, sizeof(szNameStr));
				Format(szFormatStr, sizeof(szFormatStr), "door%s", szNameStr);
				DispatchKeyValue(iEntity, "targetname", szFormatStr);
				
				GetEntPropString(iEntity, Prop_Data, "m_ModelName", szModel, sizeof(szModel));
				SetClientCookie(Client, g_hCookieSDoorTarget, szFormatStr);
				SetClientCookie(Client, g_hCookieSDoorModel, szModel);
			}
			case 'b': {
				GetClientCookie(Client, g_hCookieSDoorTarget, szDoorTarget, sizeof(szDoorTarget));
				GetClientCookie(Client, g_hCookieSDoorModel, szModel, sizeof(szModel));
				
				if (StrEqual(szModel, "models/props_lab/blastdoor001c.mdl")) {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,dog_open,0", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,DisableCollision,,1", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,close,5", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,EnableCollision,,5.1", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
				} else if (StrEqual(szModel, "models/props_lab/RavenDoor.mdl")) {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,RavenDoor_Open,0", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,RavenDoor_Drop,7", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
				} else {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,open,0", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,close,4", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
				}
			}
			case 'c': {
				GetClientCookie(Client, g_hCookieSDoorTarget, szDoorTarget, sizeof(szDoorTarget));
				GetClientCookie(Client, g_hCookieSDoorModel, szModel, sizeof(szModel));
				DispatchKeyValue(iEntity, "spawnflags", "258");
				
				if (StrEqual(szModel, "models/props_lab/blastdoor001c.mdl")) {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,dog_open,0", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,DisableCollision,,1", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,close,5", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,EnableCollision,,5.1", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
				} else if (StrEqual(szModel, "models/props_lab/RavenDoor.mdl")) {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,RavenDoor_Open,0", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,RavenDoor_Drop,7", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
				} else {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,open,0", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,close,4", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
				}
			}
		}
	} else {
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "用法: !sdoor <選擇>");
			LM_PrintToChat(Client, "!sdoor 1~7 = 叫出門 door");
			LM_PrintToChat(Client, "!sdoor a = 選擇一個門");
			LM_PrintToChat(Client, "!sdoor b = 選擇按鈕 (射擊按鈕開門)");
			LM_PrintToChat(Client, "!sdoor c = 選擇按鈕 (按E使用開門)");
		} else {
			LM_PrintToChat(Client, "Usage: !sdoor <choose>");
			LM_PrintToChat(Client, "!sdoor 1~7 = Spawn door");
			LM_PrintToChat(Client, "!sdoor a = Select door");
			LM_PrintToChat(Client, "!sdoor b = Select button (Shoot to open)");
			LM_PrintToChat(Client, "!sdoor c = Select button (Press to open)");
		}
	}
	return Plugin_Handled;
}
