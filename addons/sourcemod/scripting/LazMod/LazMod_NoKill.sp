#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>

#define MSGTAG "\x04NoKill\x01:"

new bool:g_bClientLang[MAXPLAYERS];
new Handle:g_hCookieClientLang;

new bool:g_bGodMode[MAXPLAYERS];
new g_iGodModeLock[MAXPLAYERS] = 0;
new g_Obj_Dfilter = -1;
new Handle:g_hLock[MAXPLAYERS];

public Plugin:myinfo = {
	name = "BuildMod - NoKill",
	author = "LaZycAt, hjkwe654",
	description = "Protect clients.",
	version = LAZMOD_VER,
	url = ""
};

public OnPluginStart() {	
	RegAdminCmd("sm_nokill", Command_NoKill, 0, "Enable/Disable protector.");
	RegAdminCmd("sm_nk", Command_NoKill, 0, "Enable/Disable protector.");
	HookEvent("player_hurt", OnDamage, EventHookMode_Post);
	HookEvent("player_death", OnDeath, EventHookMode_Post);
	g_hCookieClientLang = RegClientCookie("cookie_BuildModClientLang", "BuildMod Client Language.", CookieAccess_Private);
}

public OnMapStart()
	CheckDfilterExist();

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

public Action:Command_NoKill(Client, args) {
	if (!LM_AllowToUse(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client)) {
		PrintToChat(Client, "No!");
		return Plugin_Handled;
	}
	
	CheckDfilterExist();
	
	new String:szPlayer[64], String:szSwitch[8];
	GetCmdArg(1, szPlayer, sizeof(szPlayer));
	GetCmdArg(2, szSwitch, sizeof(szSwitch));
	
	if (args > 0 && LM_IsAdmin(Client)) {
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
		if ((target_count = ProcessTargetString(szPlayer, Client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(Client, target_count);
			return Plugin_Handled;
		}

		for (new i = 0; i < target_count; i++) {
			new iTarget = target_list[i];
			if (args > 1) {
				if (StrEqual(szSwitch, "1")) {
					if (!g_bGodMode[iTarget]) {
						g_bGodMode[iTarget] = true;
						SetVariantString("cat_dfilter_dmg");
						AcceptEntityInput(iTarget, "setdamagefilter", -1);
						LM_PrintToChat(iTarget, "%s On", MSGTAG);
						LM_PrintToChat(Client, "%s Turned %N NoKill ON", MSGTAG, iTarget);
					} else 
						LM_PrintToChat(Client, "%s %N NoKill is already ON", MSGTAG, iTarget);
				} else if (StrEqual(szSwitch, "0")) {
					if (g_bGodMode[iTarget]) {
						g_bGodMode[iTarget] = false;
						SetVariantString("0");
						AcceptEntityInput(iTarget, "setdamagefilter", -1);
						LM_PrintToChat(iTarget, "%s Off", MSGTAG);
						LM_PrintToChat(Client, "%s Turned %N NoKill OFF", MSGTAG, iTarget);
					} else
						LM_PrintToChat(Client, "%s %N NoKill is already OFF", MSGTAG, iTarget);
				}
			} else {
				if (!g_bGodMode[iTarget]) {
					g_bGodMode[iTarget] = true;
					SetVariantString("cat_dfilter_dmg");
					AcceptEntityInput(iTarget, "setdamagefilter", -1);
					LM_PrintToChat(iTarget, "%s On", MSGTAG);
					LM_PrintToChat(Client, "%s Turned %N NoKill ON", MSGTAG, iTarget);
				} else {
					g_bGodMode[iTarget] = false;
					SetVariantString("0");
					AcceptEntityInput(iTarget, "setdamagefilter", -1);
					LM_PrintToChat(iTarget, "%s Off", MSGTAG);
					LM_PrintToChat(Client, "%s Turned %N NoKill OFF", MSGTAG, iTarget);
				}
			}
		}
		return Plugin_Handled;
	}
	
	if (g_iGodModeLock[Client] > 0){
		if (g_bClientLang[Client]) {
			LM_PrintToChat(Client, "%s 你無法在殺人後馬上使用NoKill!", MSGTAG);
			LM_PrintToChat(Client, "%s 鎖定時間剩餘: %i 秒.", MSGTAG, g_iGodModeLock[Client]);
		} else {
			LM_PrintToChat(Client, "%s You cannot use NoKill after killed a player!", MSGTAG);
			LM_PrintToChat(Client, "%s Lock Time left: %i secend(s).", MSGTAG, g_iGodModeLock[Client]);
		}
		return Plugin_Handled;
	}
	
	if (!g_bGodMode[Client]) {
		g_bGodMode[Client] = true;
		SetVariantString("cat_dfilter_dmg");
		AcceptEntityInput(Client, "setdamagefilter", -1);
		LM_PrintToChat(Client, "%s On", MSGTAG);
	} else {
		g_bGodMode[Client] = false;
		SetVariantString("0");
		AcceptEntityInput(Client, "setdamagefilter", -1);
		LM_PrintToChat(Client, "%s Off", MSGTAG);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	LM_Logging(Client, "sm_nokill", szArgs);
	return Plugin_Handled;
}

public OnDeath(Handle:hEvent, const String:szName[], bool:bBroadcast) {
	new iVictem = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if (g_bGodMode[iVictem]) {
		g_bGodMode[iVictem] = false;
		
		if (g_bClientLang[iVictem])
			LM_PrintToChat(iVictem, "%s 關閉", MSGTAG);
		else
			LM_PrintToChat(iVictem, "%s Off", MSGTAG);
		SetVariantString("0");
		AcceptEntityInput(iVictem, "setdamagefilter", -1);
	}
	
	if (iAttacker != iVictem && LM_IsClientValid(iAttacker, iAttacker)) {
		SetVariantString("0");
		AcceptEntityInput(iAttacker, "setdamagefilter", -1);
		if (g_bGodMode[iAttacker]) {
			if (g_bClientLang[iAttacker])
				LM_PrintToChat(iAttacker, "%s 因攻擊玩家NoKill自動關閉.", MSGTAG);
			else
				LM_PrintToChat(iAttacker, "%s NoKill auto disabled because attacking players.", MSGTAG);
		}
		if (g_iGodModeLock[iAttacker] == 0) {
			if (g_bClientLang[iAttacker])
				LM_PrintToChat(iAttacker, "%s 鎖定", MSGTAG);
			else
				LM_PrintToChat(iAttacker, "%s Locked", MSGTAG);
		}
		g_iGodModeLock[iAttacker] += 60;
		if (g_hLock[iAttacker] != INVALID_HANDLE) {
			KillTimer(g_hLock[iAttacker]);
			g_hLock[iAttacker] = INVALID_HANDLE;
		}
		g_hLock[iAttacker] = CreateTimer(0.0, Timer_Lock, iAttacker);
	}
}

public OnDamage(Handle:hEvent, const String:szName[], bool:bBroadcast) {
	new iVictem = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if (g_bGodMode[iAttacker] && iAttacker != iVictem && LM_IsClientValid(iAttacker, iAttacker)) {
		g_bGodMode[iAttacker] = false;
		SetVariantString("0");
		AcceptEntityInput(iAttacker, "setdamagefilter", -1);
		if (g_bClientLang[iAttacker]) {
			LM_PrintToChat(iAttacker, "%s 因攻擊玩家NoKill自動關閉.", MSGTAG);
			LM_PrintToChat(iAttacker, "%s 關閉", MSGTAG);
		} else {
			LM_PrintToChat(iAttacker, "%s NoKill auto disabled because attacking players.", MSGTAG);
			LM_PrintToChat(iAttacker, "%s Off", MSGTAG);
		}
	}
}

public Action:Timer_Lock(Handle:Timer, any:Client) {
	if (Client > 0) {
		if (LM_IsClientValid(Client, Client)) {
			if (g_iGodModeLock[Client] > 0) {
				g_iGodModeLock[Client]--;
				if (g_bClientLang[Client])
					PrintCenterText(Client, "NoKill 鎖定, 時間剩餘: %i", g_iGodModeLock[Client]);
				else
					PrintCenterText(Client, "NoKill Locked, Time Left: %i", g_iGodModeLock[Client]);
				g_hLock[Client] = CreateTimer(1.0, Timer_Lock, Client);
			} else {
				if (g_bClientLang[Client])
					LM_PrintToChat(Client, "%s 解除鎖定", MSGTAG);
				else
					LM_PrintToChat(Client, "%s Unlocked", MSGTAG);
				KillTimer(g_hLock[Client]);
				g_hLock[Client] = INVALID_HANDLE;
			}
		} else {
			g_iGodModeLock[Client] = 0;
			KillTimer(g_hLock[Client]);
			g_hLock[Client] = INVALID_HANDLE;
		}
	}
	return Plugin_Handled;
}

public CheckDfilterExist() {
	g_Obj_Dfilter = -1;
	g_Obj_Dfilter = FindEntityByClassname(0, "cat_dfilter_dmg");
	if (g_Obj_Dfilter == -1) {
		g_Obj_Dfilter = CreateEntityByName("filter_damage_type");
		DispatchKeyValue(g_Obj_Dfilter, "targetname", "cat_dfilter_dmg");
		DispatchKeyValue(g_Obj_Dfilter, "classname", "cat_dfilter_dmg");
		DispatchKeyValue(g_Obj_Dfilter, "Negated", "0");
		DispatchKeyValue(g_Obj_Dfilter, "damagetype", "16384");
		DispatchSpawn(g_Obj_Dfilter);
	}
}

public OnPluginEnd() {
	for (new i = 0; i < MAXPLAYERS; i++) {
		g_bGodMode[i] = false;
		g_iGodModeLock[i] = 0;
	}
}
