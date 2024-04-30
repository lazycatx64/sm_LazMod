


#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>




public Plugin myinfo = {
	name = "LazMod - PropInfo",
	author = "LaZycAt, hjkwe654",
	description = "Show props infomation on hud.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	LoadTranslations("common.phrases")
	CreateTimer(0.1, Display_Msgs, 0, TIMER_REPEAT)
	
	PrintToServer( "LazMod PropInfo loaded!" )
}

public Action Display_Msgs(Handle timer) {	
	for (int plyClient = 1; plyClient <= MaxClients; plyClient++) {		
		if (LM_IsClientValid(plyClient, plyClient, true) && !IsFakeClient(plyClient)) {
			int iAimTarget = LM_GetClientAimEntity(plyClient, false, true)
			if (iAimTarget != -1 && IsValidEdict(iAimTarget))
				EntityInfo(plyClient, iAimTarget)
		}
	}
	return Plugin_Handled
}

public EntityInfo(Client, entTarget) {
	if (LM_IsFuncProp(entTarget))
		return
	
	SetHudTextParams(0.015, 0.08, 0.1, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2)
	if (LM_IsPlayer(entTarget)) {
		int iHealth = GetClientHealth(entTarget)
		if (iHealth <= 1)
			iHealth = 0

		if (LM_IsAdmin(Client)) {
			char szSteamId[32]
			GetClientAuthId(entTarget, AuthId_Steam2, szSteamId, sizeof(szSteamId))
			ShowHudText(Client, -1, "Player: %N\nHealth: %i\nUserID: %i\nSteamID:%s", entTarget, iHealth, GetClientUserId(entTarget), szSteamId)
		} else {
			ShowHudText(Client, -1, "Player: %N\nHealth: %i", entTarget, iHealth)
		}
		return
	}

	char szClass[32]
	GetEdictClassname(entTarget, szClass, sizeof(szClass))
	if (LM_IsNpc(entTarget)) {
		int iHealth = GetEntProp(entTarget, Prop_Data, "m_iHealth")
		if (iHealth <= 1)
			iHealth = 0
		ShowHudText(Client, -1, "Classname: %s\nHealth: %i", szClass, iHealth)
		return
	}
	
	char szOwner[32]
	int plyOwner = LM_GetEntityOwner(entTarget)
	if (plyOwner != -1)
		GetClientName(plyOwner, szOwner, sizeof(szOwner))
	else if (plyOwner > MAXPLAYERS){
		szOwner = "*Disconnectd"
	} else {
		szOwner = "*None"
	}

	char szModel[128] 
	GetEntPropString(entTarget, Prop_Data, "m_ModelName", szModel, sizeof(szModel))
	
	if (Phys_IsPhysicsObject(entTarget)) 
		ShowHudText(Client, -1, "Classname: %s\nIndex: %i\nModel: %s\nOwner: %s\nMass:%f", szClass, entTarget, szModel, szOwner, Phys_GetMass(entTarget))
	else 
		ShowHudText(Client, -1, "Classname: %s\nIndex: %i\nModel: %s\nOwner: %s", szClass, entTarget, szModel, szOwner)
	
	return
}



