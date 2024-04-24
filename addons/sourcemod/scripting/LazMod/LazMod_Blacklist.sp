

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>


public Plugin myinfo = {
	name = "LazMod - Blacklist",
	author = "LaZycAt, hjkwe654",
	description = "Add client to blacklist that cant use BuildMod.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {	
	LoadTranslations("common.phrases")
	RegAdminCmd("sm_bl", Command_AddBL, ADMFLAG_CONVARS, "Add client to LazMod blacklist to prevent them from using LazMod commands.")
	RegAdminCmd("sm_unbl", Command_RemoveBL, ADMFLAG_CONVARS, "Remove client from blacklist")

	PrintToServer( "LazMod Blacklist loaded!" )
}

public Action Command_AddBL(Client, args) {
	if (args < 1) {
		ReplyToCommand(Client, "[SM] Usage: sm_bl <#userid|name>")
		return Plugin_Handled
	}
	
	char arg[33]
	GetCmdArg(1, arg, sizeof(arg))
	
	char target_name[MAX_TARGET_LENGTH]
	int target_list[MAXPLAYERS], target_count
	bool tn_is_ml
	
	if ((target_count = ProcessTargetString(arg, Client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(Client, target_count)
		return Plugin_Handled
	}

	for (int i = 0; i < target_count; i++) {
		int target = target_list[i]
		
		if(LM_IsBlacklisted(target)) {
			LM_PrintToChat(Client, "%s is already blacklisted!", target_name)
			return Plugin_Handled
		} else 
			LM_AddBlacklist(target)
	}
	
	for (int i = 0; i < MaxClients; i++) {
		if (LM_IsClientValid(i, i)) {
			LM_PrintToChat(i, "%N added %s to LazMod blacklist :(", Client, target_name)
		}
	}
	return Plugin_Handled
}

public Action Command_RemoveBL(Client, args) {
	if (args < 1) {
		ReplyToCommand(Client, "[SM] Usage: sm_unbl <#userid|name>")
		return Plugin_Handled
	}
	
	char arg[33]
	GetCmdArg(1, arg, sizeof(arg))
	
	char target_name[MAX_TARGET_LENGTH]
	int target_list[MAXPLAYERS], target_count
	bool tn_is_ml
	
	if ((target_count = ProcessTargetString(arg, Client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(Client, target_count)
		return Plugin_Handled
	}

	for (int i = 0; i < target_count; i++) {
		new target = target_list[i]
		
		if(!LM_RemoveBlacklist(target)) {
			LM_PrintToChat(Client, "%s is not in blacklist!", target_name)
			return Plugin_Handled
		}
	}
	
	if(tn_is_ml) {
		for (int i = 0; i < MaxClients; i++) {
			if (LM_IsClientValid(i, i))
				LM_PrintToChat(i, "%N removed %s from LazMod blacklist :)", Client, target_name)
		}
	} else {
		for (int i = 0; i < MaxClients; i++) {
			if (LM_IsClientValid(i, i))
				LM_PrintToChat(i, "%N removed %s from LazMod blacklist :)", Client, target_name)
		}
	}
	
	return Plugin_Handled
}
