

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>




bool g_bGodMode[MAXPLAYERS]
int g_iGodModeLock[MAXPLAYERS] = {0, ...}
int g_entDfilter = -1
Handle g_hLock[MAXPLAYERS]

public Plugin myinfo = {
	name = "LazMod - NoKill",
	author = "LaZycAt, hjkwe654",
	description = "Protect clients.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {	
	RegAdminCmd("sm_nokill", Command_NoKill, 0, "Enable/Disable protector.")
	RegAdminCmd("sm_nk", Command_NoKill, 0, "Enable/Disable protector.")
	HookEvent("player_hurt", OnDamage, EventHookMode_Post)
	HookEvent("player_death", OnDeath, EventHookMode_Post)
	
	PrintToServer( "LazMod NoKill loaded!" )
}

public OnMapStart()
	CheckDfilterExist()


public Action Command_NoKill(Client, args) {
	if (!LM_AllowToLazMod(Client) || LM_IsBlacklisted(Client) || !LM_IsClientValid(Client, Client)) {
		PrintToChat(Client, "No!")
		return Plugin_Handled
	}
	
	CheckDfilterExist()
	
	char szPlayer[64], szSwitch[8]
	GetCmdArg(1, szPlayer, sizeof(szPlayer))
	GetCmdArg(2, szSwitch, sizeof(szSwitch))
	
	if (args > 0 && LM_IsAdmin(Client)) {
		char target_name[MAX_TARGET_LENGTH]
		int target_list[MAXPLAYERS], target_count
		bool tn_is_ml
		
		if ((target_count = ProcessTargetString(szPlayer, Client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(Client, target_count)
			return Plugin_Handled
		}

		for (int i = 0; i < target_count; i++) {
			new iTarget = target_list[i]
			if (args > 1) {
				if (StrEqual(szSwitch, "1")) {
					if (!g_bGodMode[iTarget]) {
						g_bGodMode[iTarget] = true
						SetVariantString("cat_dfilter_dmg")
						AcceptEntityInput(iTarget, "setdamagefilter", -1)
						LM_PrintToChat(iTarget, "On")
						LM_PrintToChat(Client, "Turned %N NoKill ON", iTarget)
					} else 
						LM_PrintToChat(Client, "%N NoKill is already ON", iTarget)
				} else if (StrEqual(szSwitch, "0")) {
					if (g_bGodMode[iTarget]) {
						g_bGodMode[iTarget] = false
						SetVariantString("0")
						AcceptEntityInput(iTarget, "setdamagefilter", -1)
						LM_PrintToChat(iTarget, "Off")
						LM_PrintToChat(Client, "Turned %N NoKill OFF", iTarget)
					} else
						LM_PrintToChat(Client, "%N NoKill is already OFF", iTarget)
				}
			} else {
				if (!g_bGodMode[iTarget]) {
					g_bGodMode[iTarget] = true
					SetVariantString("cat_dfilter_dmg")
					AcceptEntityInput(iTarget, "setdamagefilter", -1)
					LM_PrintToChat(iTarget, "On")
					LM_PrintToChat(Client, "Turned %N NoKill ON", iTarget)
				} else {
					g_bGodMode[iTarget] = false
					SetVariantString("0")
					AcceptEntityInput(iTarget, "setdamagefilter", -1)
					LM_PrintToChat(iTarget, "Off")
					LM_PrintToChat(Client, "Turned %N NoKill OFF", iTarget)
				}
			}
		}
		return Plugin_Handled
	}
	
	if (g_iGodModeLock[Client] > 0){
		LM_PrintToChat(Client, "You cannot use NoKill after killed a player!")
		LM_PrintToChat(Client, "Lock Time left: %i secend(s).", g_iGodModeLock[Client])
		return Plugin_Handled
	}
	
	if (!g_bGodMode[Client]) {
		g_bGodMode[Client] = true
		SetVariantString("cat_dfilter_dmg")
		AcceptEntityInput(Client, "setdamagefilter", -1)
		LM_PrintToChat(Client, "On")
	} else {
		g_bGodMode[Client] = false
		SetVariantString("0")
		AcceptEntityInput(Client, "setdamagefilter", -1)
		LM_PrintToChat(Client, "Off")
	}
	
	char szTemp[33], szArgs[128]
	for (int i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp))
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp)
	}
	LM_LogCmd(Client, "sm_nokill", szArgs)
	return Plugin_Handled
}

public OnDeath(Handle hEvent, const char[] szName, bool bBroadcast) {
	new iVictem = GetClientOfUserId(GetEventInt(hEvent, "userid"))
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"))
	
	if (g_bGodMode[iVictem]) {
		g_bGodMode[iVictem] = false
		
		LM_PrintToChat(iVictem, "Off")
		SetVariantString("0")
		AcceptEntityInput(iVictem, "setdamagefilter", -1)
	}
	
	if (iAttacker != iVictem && LM_IsClientValid(iAttacker, iAttacker)) {
		SetVariantString("0")
		AcceptEntityInput(iAttacker, "setdamagefilter", -1)
		if (g_bGodMode[iAttacker]) {
			LM_PrintToChat(iAttacker, "NoKill auto disabled because attacking players.")
		}
		if (g_iGodModeLock[iAttacker] == 0)
			LM_PrintToChat(iAttacker, "Locked")
			
		g_iGodModeLock[iAttacker] += 60
		if (g_hLock[iAttacker] != INVALID_HANDLE) {
			KillTimer(g_hLock[iAttacker])
			g_hLock[iAttacker] = INVALID_HANDLE
		}
		g_hLock[iAttacker] = CreateTimer(0.0, Timer_Lock, iAttacker)
	}
}

public OnDamage(Handle hEvent, const char[] szName, bool bBroadcast) {
	new iVictem = GetClientOfUserId(GetEventInt(hEvent, "userid"))
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"))
	
	if (g_bGodMode[iAttacker] && iAttacker != iVictem && LM_IsClientValid(iAttacker, iAttacker)) {
		g_bGodMode[iAttacker] = false
		SetVariantString("0")
		AcceptEntityInput(iAttacker, "setdamagefilter", -1)
		LM_PrintToChat(iAttacker, "NoKill auto disabled because attacking players.")
		LM_PrintToChat(iAttacker, "Off")
	}
}

public Action Timer_Lock(Handle Timer, any Client) {
	if (Client > 0) {
		if (LM_IsClientValid(Client, Client)) {
			if (g_iGodModeLock[Client] > 0) {
				g_iGodModeLock[Client]--
				PrintCenterText(Client, "NoKill Locked, Time Left: %i", g_iGodModeLock[Client])
				g_hLock[Client] = CreateTimer(1.0, Timer_Lock, Client)
			} else {
				LM_PrintToChat(Client, "Unlocked")
				KillTimer(g_hLock[Client])
				g_hLock[Client] = INVALID_HANDLE
			}
		} else {
			g_iGodModeLock[Client] = 0
			KillTimer(g_hLock[Client])
			g_hLock[Client] = INVALID_HANDLE
		}
	}
	return Plugin_Handled
}

public CheckDfilterExist() {
	g_entDfilter = -1
	g_entDfilter = FindEntityByClassname(0, "cat_dfilter_dmg")
	if (g_entDfilter == -1) {
		g_entDfilter = CreateEntityByName("filter_damage_type")
		DispatchKeyValue(g_entDfilter, "targetname", "cat_dfilter_dmg")
		DispatchKeyValue(g_entDfilter, "classname", "cat_dfilter_dmg")
		DispatchKeyValue(g_entDfilter, "Negated", "0")
		DispatchKeyValue(g_entDfilter, "damagetype", "16384")
		DispatchSpawn(g_entDfilter)
	}
}

public OnPluginEnd() {
	for (int i = 0; i < MAXPLAYERS; i++) {
		g_bGodMode[i] = false
		g_iGodModeLock[i] = 0
	}
}
