#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <vphysics>

#define MSGTAG "\x04Tool\x01:"
#define MSGTAG_L2 "\x04L2 Tool\x01:"
#define MSGTAG_ADMIN "\x04Admin Tool\x01:"

new bool:g_bClientLang[MAXPLAYERS];
new Handle:g_hCookieClientLang;

new bool:g_bIsPressingAttack[MAXPLAYERS] = { false,...};

new String:g_szPlayerCmdList[][] = {
	"",
	"sm_f",
	"sm_uf",
	"sm_d",
	"sm_dr",
	"sm_w"
};
new String:g_szPlayerCmdTextChz[][] = {
	"*無",
	"固定",
	"解除固定",
	"刪除",
	"放到地面",
	"焊接"
};
new String:g_szPlayerCmdTextEng[][] = {
	"*None",
	"Freeze",
	"UnFreeze",
	"Delete",
	"Drop to ground",
	"Weld"
};
new g_iPlayerCmdSize = sizeof(g_szPlayerCmdList);

new String:g_szL2PlayerCmdList[][] = {
	"",
	"sm_f",
	"sm_uf",
	"sm_ff",
	"sm_uff",
	"sm_nb",
	"sm_unb",
	"sm_d",
	"sm_dr",
	"sm_w"
};
new String:g_szL2PlayerCmdTextChz[][] = {
	"*無",
	"固定",
	"解除固定",
	"強力固定",
	"解除強力固定",
	"物件不損壞",
	"解除物件不損壞",
	"刪除",
	"放到地面",
	"焊接"
};
new String:g_szL2PlayerCmdTextEng[][] = {
	"*None",
	"Freeze",
	"UnFreeze",
	"Force Freeze",
	"UnForce Freeze",
	"NoBreak",
	"UnNoBreak",
	"Delete",
	"Drop to ground",
	"Weld"
};
new g_iL2PlayerCmdSize = sizeof(g_szL2PlayerCmdList);

new String:g_szAdminCmdList[][] = {
	"",
	"sm_expray",
	"sm_shoot",
	"sm_hurt 5000 300 16384 stunstick r",
	"sm_droct",
	"sm_hax @aim",
	"sm_ionattack",
	"sm_dels",
	"sm_dels2",
	"sm_delr"
};
new String:g_szAdminCmdText[][] = {
	"None",
	"Explosion Ray",
	"Shoot",
	"Hurt",
	"Dr.Oct",
	"HAAAAAX",
	"Ion Cannon Attack",
	"DelStrider",
	"DelStrider2",
	"DelRange"
};
new g_iAdminCmdSize = sizeof(g_szAdminCmdList);

new g_iPlayerCurrent[MAXPLAYERS] = { 0,...};
new g_iL2PlayerCurrent[MAXPLAYERS] = { 0,...};
new g_iAdminCurrent[MAXPLAYERS] = { 0,...};

public Plugin:myinfo = {
	name = "BuildMod - Tool",
	author = "LaZycAt, hjkwe654",
	description = "Run command with weapon.",
	version = LAZMOD_VER,
	url = ""
};

public OnPluginStart() {
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	
	g_hCookieClientLang = RegClientCookie("cookie_BuildModClientLang", "BuildMod Client Language.", CookieAccess_Private);
}

public OnClientDisconnect(Client) {
	g_iAdminCurrent[Client] = 0;
	g_iPlayerCurrent[Client] = 0;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	GivePlayerItem(Client, "weapon_crowbar");
	GivePlayerItem(Client, "weapon_stunstick");
}

public Action:OnPlayerRunCmd(Client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
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
	
	new String:szWeapon[64];
	new iWeapon = GetEntPropEnt(Client, Prop_Send, "m_hActiveWeapon");
	
	if (buttons & (IN_ATTACK | IN_ATTACK2) && iWeapon != -1 && IsValidEdict(iWeapon) && GetEdictClassname(iWeapon, szWeapon, sizeof(szWeapon)) && StrEqual(szWeapon, "weapon_crowbar")) {
		new iCurrent;
		if (LM_IsAdmin(Client, true))
			iCurrent = g_iL2PlayerCurrent[Client];
		else
			iCurrent = g_iPlayerCurrent[Client];
			
		if (iCurrent != 0) {
			if (buttons & IN_ATTACK && !g_bIsPressingAttack[Client]) {
				RunCommand(Client);
				g_bIsPressingAttack[Client] = true;
			}
		}
		if (buttons & IN_ATTACK2 && !g_bIsPressingAttack[Client]) {
			ChangeCommand(Client);
			g_bIsPressingAttack[Client] = true;
		}
	}
	
	if (LM_IsAdmin(Client) && buttons & (IN_ATTACK | IN_ATTACK2) && iWeapon != -1 && IsValidEdict(iWeapon) && GetEdictClassname(iWeapon, szWeapon, sizeof(szWeapon)) && StrEqual(szWeapon, "weapon_stunstick")) {
		if (g_iAdminCurrent[Client] != 0) {
			if (buttons & IN_ATTACK && !g_bIsPressingAttack[Client]) {
				RunAdminCommand(Client);
				g_bIsPressingAttack[Client] = true;
			}
		}
		if (buttons & IN_ATTACK2 && !g_bIsPressingAttack[Client]) {
			ChangeAdminCommand(Client);
			g_bIsPressingAttack[Client] = true;
		}
	}
	
	if(!(buttons & IN_ATTACK) && !(buttons & IN_ATTACK2))
		g_bIsPressingAttack[Client] = false;
	
	if (g_bIsPressingAttack[Client]) {
		buttons &= ~IN_ATTACK;
		buttons &= ~IN_ATTACK2;
	}
}

public RunCommand(Client) {
	if (LM_IsAdmin(Client, true)) {
		new iCurrent = g_iL2PlayerCurrent[Client];
		FakeClientCommand(Client, g_szL2PlayerCmdList[iCurrent]);
	} else {
		new iCurrent = g_iPlayerCurrent[Client];
		FakeClientCommand(Client, g_szPlayerCmdList[iCurrent]);
	}
}

public ChangeCommand(Client) {
	new iCurrent, String:szCurrent[8];
	if (LM_IsAdmin(Client, true)) {
		if (g_iL2PlayerCurrent[Client] < g_iL2PlayerCmdSize - 1)
			g_iL2PlayerCurrent[Client]++;
		else
			g_iL2PlayerCurrent[Client] = 0;
			
		iCurrent = g_iL2PlayerCurrent[Client];
		if (iCurrent+1 >= 10)
			Format(szCurrent, sizeof(szCurrent), "%i.", iCurrent+1);
		else
			Format(szCurrent, sizeof(szCurrent), "0%i.", iCurrent+1);
		
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "%s %s %s", MSGTAG_L2, szCurrent, g_szL2PlayerCmdTextChz[iCurrent]);
		else
			LM_PrintToChat(Client, "%s %s %s", MSGTAG_L2, szCurrent, g_szL2PlayerCmdTextEng[iCurrent]);
	} else {
		if (g_iPlayerCurrent[Client] < g_iPlayerCmdSize - 1)
			g_iPlayerCurrent[Client]++;
		else
			g_iPlayerCurrent[Client] = 0;
			
		iCurrent = g_iPlayerCurrent[Client];
		if (iCurrent+1 >= 10)
			Format(szCurrent, sizeof(szCurrent), "%i.", iCurrent+1);
		else
			Format(szCurrent, sizeof(szCurrent), "0%i.", iCurrent+1);
		
		if (g_bClientLang[Client])
			LM_PrintToChat(Client, "%s %s %s", MSGTAG, szCurrent, g_szPlayerCmdTextChz[iCurrent]);
		else
			LM_PrintToChat(Client, "%s %s %s", MSGTAG, szCurrent, g_szPlayerCmdTextEng[iCurrent]);
	}
}

public RunAdminCommand(Client) {
	new iCurrent = g_iAdminCurrent[Client];
	FakeClientCommand(Client, g_szAdminCmdList[iCurrent]);
}

public ChangeAdminCommand(Client) {
	if (g_iAdminCurrent[Client] < g_iAdminCmdSize - 1)
		g_iAdminCurrent[Client]++;
	else
		g_iAdminCurrent[Client] = 0;
		
	new iCurrent = g_iAdminCurrent[Client], String:szCurrent[8];
	if (iCurrent+1 >= 10)
		Format(szCurrent, sizeof(szCurrent), "%i.", iCurrent+1);
	else
		Format(szCurrent, sizeof(szCurrent), "0%i.", iCurrent+1);
	
	LM_PrintToChat(Client, "%s %s %s",MSGTAG_ADMIN, szCurrent, g_szAdminCmdText[iCurrent]);
}


