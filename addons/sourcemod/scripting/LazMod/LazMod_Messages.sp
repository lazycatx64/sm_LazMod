#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <vphysics>

new bool:g_bClientLang[MAXPLAYERS];
new Handle:g_hCookieClientLang;

public Plugin:myinfo = {
	name = "BuildMod - Messages",
	author = "LaZycAt, hjkwe654",
	description = "Show props infomation.",
	version = LAZMOD_VER,
	url = ""
};

public OnPluginStart() {
	LoadTranslations("common.phrases");
	CreateTimer(0.1, Display_Msgs, 0, TIMER_REPEAT);
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

public Action:Display_Msgs(Handle:timer) {	
	for (new Client = 1; Client <= MaxClients; Client++) {		
		if (LM_IsClientValid(Client, Client, true) && !IsFakeClient(Client)) {
			new iAimTarget = LM_ClientAimEntity(Client, false, true);
			if (iAimTarget != -1 && IsValidEdict(iAimTarget))
				EntityInfo(Client, iAimTarget);
		}
	}
	return;
}

public EntityInfo(Client, iTarget) {
	if (IsFunc(iTarget))
		return;
	
	SetHudTextParams(0.015, 0.08, 0.1, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
	if (IsPlayer(iTarget)) {
		new iHealth = GetClientHealth(iTarget);
		if (iHealth <= 1)
			iHealth = 0;
		if (LM_IsAdmin(Client)) {
			new String:szSteamId[32], String:szIP[16];
			GetClientAuthString(iTarget, szSteamId, sizeof(szSteamId));
			GetClientIP(iTarget, szIP, sizeof(szIP));
			if (g_bClientLang[Client])
				ShowHudText(Client, -1, "玩家: %N\n血量: %i\n玩家編號: %i\nSteamID:%s\nIP: %s", iTarget, iHealth, GetClientUserId(iTarget), szSteamId, szIP);
			else
				ShowHudText(Client, -1, "Player: %N\nHealth: %i\nUserID: %i\nSteamID:%s\nIP: %s", iTarget, iHealth, GetClientUserId(iTarget), szSteamId, szIP);
		} else {
			if (g_bClientLang[Client])
				ShowHudText(Client, -1, "玩家: %N\n血量: %i", iTarget, iHealth);
			else
				ShowHudText(Client, -1, "Player: %N\nHealth: %i", iTarget, iHealth);
		}
		return;
	}
	new String:szClass[32];
	GetEdictClassname(iTarget, szClass, sizeof(szClass));
	if (IsNpc(iTarget)) {
		new iHealth = GetEntProp(iTarget, Prop_Data, "m_iHealth");
		if (iHealth <= 1)
			iHealth = 0;
		if (g_bClientLang[Client])
			ShowHudText(Client, -1, "類型: %s\n血量: %i", szClass, iHealth);
		else
			ShowHudText(Client, -1, "Classname: %s\nHealth: %i", szClass, iHealth);
		return;
	}
	
	new String:szModel[128], String:szOwner[32];
	new iOwner = LM_GetEntityOwner(iTarget);
	GetEntPropString(iTarget, Prop_Data, "m_ModelName", szModel, sizeof(szModel));
	if (iOwner != -1)
		GetClientName(iOwner, szOwner, sizeof(szOwner));
	else if (iOwner > MAXPLAYERS){
		if (g_bClientLang[Client])
			szOwner = "*離線";
		else
			szOwner = "*Disconnectd";
	} else {
		if (g_bClientLang[Client])
			szOwner = "*無";
		else
			szOwner = "*None";
	}
	
	if (Phys_IsPhysicsObject(iTarget)) {
		if (g_bClientLang[Client])
			ShowHudText(Client, -1, "類型: %s\n編號: %i\n模組: %s\n擁有者: %s\n重量:%f", szClass, iTarget, szModel, szOwner, Phys_GetMass(iTarget));
		else
			ShowHudText(Client, -1, "Classname: %s\nIndex: %i\nModel: %s\nOwner: %s\nMass:%f", szClass, iTarget, szModel, szOwner, Phys_GetMass(iTarget));
	} else {
		if (g_bClientLang[Client])
			ShowHudText(Client, -1, "類型: %s\n編號: %i\n模組: %s\n擁有者: %s", szClass, iTarget, szModel, szOwner);
		else
			ShowHudText(Client, -1, "Classname: %s\nIndex: %i\nModel: %s\nOwner: %s", szClass, iTarget, szModel, szOwner);
	}
	return;
}

bool:IsFunc(iEntity){
	new String:szClass[32];
	GetEdictClassname(iEntity, szClass, sizeof(szClass));
	if (StrContains(szClass, "func_", false) == 0 && !StrEqual(szClass, "func_physbox"))
		return true;
	return false;
}

bool:IsNpc(iEntity){
	new String:szClass[32];
	GetEdictClassname(iEntity, szClass, sizeof(szClass));
	if (StrContains(szClass, "npc_", false) == 0)
		return true;
	return false;
}

bool:IsPlayer(iEntity){
	if ((GetEntityFlags(iEntity) & (FL_CLIENT | FL_FAKECLIENT)))
		return true;
	return false;
}


