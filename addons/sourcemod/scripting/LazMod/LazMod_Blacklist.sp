#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>

new bool:g_bClientLang[MAXPLAYERS];
new Handle:g_hCookieClientLang;

public Plugin:myinfo = {
	name = "BuildMod - Blacklist",
	author = "LaZycAt, hjkwe654",
	description = "Add client to blacklist that cant use BuildMod.",
	version = LAZMOD_VER,
	url = ""
};

public OnPluginStart() {	
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_bl", Command_AddBL, ADMFLAG_CONVARS, "Add client to blacklist");
	RegAdminCmd("sm_unbl", Command_RemoveBL, ADMFLAG_CONVARS, "Remove client from blacklist");
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

public Action:Command_AddBL(Client, args) {
	if (args < 1) {
		ReplyToCommand(Client, "[SM] Usage: sm_bl <#userid|name>");
		return Plugin_Handled;
	}
	
	new String:arg[33];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg, Client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(Client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++) {
		new target = target_list[i];
		
		if(LM_IsBlacklisted(target)) {
			LM_PrintToChat(Client, "%s is already blacklisted!", target_name);
			return Plugin_Handled;
		} else 
			LM_AddBlacklist(target);
	}
	
	for (new i = 0; i < MaxClients; i++) {
		if (LM_IsClientValid(i, i)) {
			if (g_bClientLang[i])
				LM_PrintToChat(i, "%N 將 %s 加入到黑名單 :(", Client, target_name);
			else
				LM_PrintToChat(i, "%N added %s to BuildMod blacklist :(", Client, target_name);
		}
	}
	return Plugin_Handled;
}

public Action:Command_RemoveBL(Client, args) {
	if (args < 1) {
		ReplyToCommand(Client, "[SM] Usage: sm_unbl <#userid|name>");
		return Plugin_Handled;
	}
	
	new String:arg[33];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg, Client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(Client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++) {
		new target = target_list[i];
		
		if(!LM_RemoveBlacklist(target)) {
			LM_PrintToChat(Client, "%s is not in blacklist!", target_name);
			return Plugin_Handled;
		}
	}
	
	if(tn_is_ml) {
		for (new i = 0; i < MaxClients; i++) {
			if (LM_IsClientValid(i, i)) {
				if (g_bClientLang[i])
					LM_PrintToChat(i, "%N 將 %s 從黑名單移除 :)", Client, target_name);
				else
					LM_PrintToChat(i, "%N removed %s from BuildMod blacklist :)", Client, target_name);
			}
		}
	} else {
		for (new i = 0; i < MaxClients; i++) {
			if (LM_IsClientValid(i, i)) {
				if (g_bClientLang[i])
					LM_PrintToChat(i, "%N 將 %s 從黑名單移除 :)", Client, target_name);
				else
					LM_PrintToChat(i, "%N removed %s from BuildMod blacklist :)", Client, target_name);
			}
		}
	}
	
	return Plugin_Handled;
}
