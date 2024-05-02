

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>




bool g_bGodMode[MAXPLAYERS]
int g_iGodModeLock[MAXPLAYERS] = {0, ...}
int g_entDmgFilter = -1
Handle g_hLock[MAXPLAYERS]

public Plugin myinfo = {
	name = "LazMod - NoKill",
	author = "LaZycAt, hjkwe654",
	description = "Protect player from DMers, works based on filter_damage_type entity.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {	
	RegAdminCmd("sm_nokill", Command_NoKill, 0, "Enable/Disable protector.")

	HookEvent("player_hurt", OnPlyDamaged, EventHookMode_Post)
	HookEvent("player_death", OnPlyDeath, EventHookMode_Post)
	
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
	
	char szPlayer[64]
	int iSwitch
	GetCmdArg(1, szPlayer, sizeof(szPlayer))
	iSwitch = GetCmdArgInt(2)
	
	if (args > 0 && LM_IsAdmin(Client)) {
		char target_name[MAX_TARGET_LENGTH]
		int target_list[MAXPLAYERS], target_count
		bool tn_is_ml
		
		if ((target_count = ProcessTargetString(szPlayer, Client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(Client, target_count)
			return Plugin_Handled
		}

		for (int i = 0; i < target_count; i++) {
			int iTarget = target_list[i]
			if (args > 1) {
				if (iSwitch) {
					if (!g_bGodMode[iTarget]) {
						g_bGodMode[iTarget] = true
						SetVariantString("cat_dfilter_dmg")
						AcceptEntityInput(iTarget, "setdamagefilter", -1)
						LM_PrintToChat(iTarget, "On")
						LM_PrintToChat(Client, "Turned %N NoKill ON", iTarget)
					} else 
						LM_PrintToChat(Client, "%N NoKill is already ON", iTarget)
				} else {
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

OnPlyDeath(Handle hEvent, const char[] szName, bool bBroadcast) {
	int plyVictem = GetClientOfUserId(GetEventInt(hEvent, "userid"))
	int plyAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"))
	
	if (g_bGodMode[plyVictem]) {
		g_bGodMode[plyVictem] = false
		
		LM_PrintToChat(plyVictem, "Off")
		SetVariantString("0")
		AcceptEntityInput(plyVictem, "setdamagefilter", -1)
	}
	
	if (plyAttacker != plyVictem && LM_IsClientValid(plyAttacker, plyAttacker)) {
		SetVariantString("0")
		AcceptEntityInput(plyAttacker, "setdamagefilter", -1)
		if (g_bGodMode[plyAttacker]) {
			LM_PrintToChat(plyAttacker, "NoKill auto disabled because attacking players.")
		}
		if (g_iGodModeLock[plyAttacker] == 0)
			LM_PrintToChat(plyAttacker, "Locked")
			
		g_iGodModeLock[plyAttacker] += 60
		if (g_hLock[plyAttacker] != INVALID_HANDLE) {
			KillTimer(g_hLock[plyAttacker])
			g_hLock[plyAttacker] = INVALID_HANDLE
		}
		g_hLock[plyAttacker] = CreateTimer(0.0, Timer_Lock, plyAttacker)
	}
}

OnPlyDamaged(Handle hEvent, const char[] szName, bool bBroadcast) {
	int plyVictem = GetClientOfUserId(GetEventInt(hEvent, "userid"))
	int plyAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"))
	
	if (g_bGodMode[plyAttacker] && plyAttacker != plyVictem && LM_IsClientValid(plyAttacker, plyAttacker)) {
		g_bGodMode[plyAttacker] = false
		SetVariantString("0")
		AcceptEntityInput(plyAttacker, "setdamagefilter", -1)
		LM_PrintToChat(plyAttacker, "NoKill auto disabled because attacking players.")
		LM_PrintToChat(plyAttacker, "Off")
	}
}

public Action Timer_Lock(Handle Timer, any plyAttacker) {
	if (plyAttacker > 0) {
		if (LM_IsClientValid(plyAttacker, plyAttacker)) {
			if (g_iGodModeLock[plyAttacker] > 0) {
				g_iGodModeLock[plyAttacker]--
				PrintCenterText(plyAttacker, "NoKill Locked, Time Left: %i", g_iGodModeLock[plyAttacker])
				g_hLock[plyAttacker] = CreateTimer(1.0, Timer_Lock, plyAttacker)
			} else {
				LM_PrintToChat(plyAttacker, "Unlocked")
				KillTimer(g_hLock[plyAttacker])
				g_hLock[plyAttacker] = INVALID_HANDLE
			}
		} else {
			g_iGodModeLock[plyAttacker] = 0
			KillTimer(g_hLock[plyAttacker])
			g_hLock[plyAttacker] = INVALID_HANDLE
		}
	}
	return Plugin_Handled
}

CheckDfilterExist() {
	g_entDmgFilter = -1
	g_entDmgFilter = FindEntityByClassname(0, "cat_dfilter_dmg")
	if (g_entDmgFilter == -1 || !IsValidEntity(g_entDmgFilter)) {
		g_entDmgFilter = CreateEntityByName("filter_damage_type")
		DispatchKeyValue(g_entDmgFilter, "targetname", "cat_dfilter_dmg")
		DispatchKeyValue(g_entDmgFilter, "classname", "cat_dfilter_dmg")
		DispatchKeyValue(g_entDmgFilter, "Negated", "0")
		DispatchKeyValue(g_entDmgFilter, "damagetype", "16384")
		DispatchSpawn(g_entDmgFilter)
	}
}

public OnPluginEnd() {
	for (int i = 0; i < MAXPLAYERS; i++) {
		g_bGodMode[i] = false
		g_iGodModeLock[i] = 0
	}
}
