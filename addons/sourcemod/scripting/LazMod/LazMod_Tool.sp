

#include <sourcemod>
#include <sdktools>

#include <vphysics>

#include <lazmod>


#define MSGTAG_TOOL "\x04Tool\x01:"
#define MSGTAG_TOOL_ADMIN "\x04Admin Tool\x01:"




bool g_bIsPressingAttack[MAXPLAYERS] = { false,...}

char g_szPlayerCmdList[][] = {
	"",
	"sm_freeze",
	"sm_unfreeze",
	"sm_nobreak",
	"sm_unnobreak",
	"sm_del",
	"sm_weld"
}
char g_szPlayerCmdText[][] = {
	"*None",
	"Freeze",
	"UnFreeze",
	"NoBreak",
	"UnNoBreak",
	"Delete",
	"Weld"
}
int g_iPlayerCmdSize = sizeof(g_szPlayerCmdList)

char g_szAdminCmdList[][] = {
	"",
	"sm_deathray",
	"sm_shoot",
	"sm_hurt 5000 300 16384 stunstick r",
	"sm_droct",
	"sm_hax @aim",
	"sm_ionattack",
	"sm_dels",
	"sm_dels2",
	"sm_delr"
}
char g_szAdminCmdText[][] = {
	"None",
	"DeathRay",
	"Shoot",
	"Hurt",
	"Dr.Oct",
	"HAAAAAX",
	"Ion Cannon Attack",
	"DelStrider",
	"DelStrider2",
	"DelRange"
}
int g_iAdminCmdSize = sizeof(g_szAdminCmdList)

int g_iPlayerCurrent[MAXPLAYERS] = { 0,...}
int g_iAdminCurrent[MAXPLAYERS] = { 0,...}

public Plugin myinfo = {
	name = "LazMod - Tool",
	author = "LaZycAt, hjkwe654",
	description = "Run command with weapon.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	HookEvent("player_spawn", Event_OnPlayerSpawn)
	
}

public OnClientDisconnect(plyClient) {
	g_iAdminCurrent[plyClient] = 0
	g_iPlayerCurrent[plyClient] = 0
}

public Action Event_OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
	int plyClient = GetClientOfUserId(GetEventInt(event, "userid"))
	GivePlayerItem(plyClient, "weapon_crowbar")
	GivePlayerItem(plyClient, "weapon_stunstick")

	return Plugin_Handled
}

public Action OnPlayerRunCmd(plyClient, &buttons, &impulse, float vel[3], float angles[3], &weapon) {
	
	char szWeapon[64]
	int iWeapon = LM_GetEntActiveWeapon(plyClient)
	
	if (buttons & (IN_ATTACK | IN_ATTACK2) && iWeapon != -1 && IsValidEdict(iWeapon) && GetEdictClassname(iWeapon, szWeapon, sizeof(szWeapon)) && StrEqual(szWeapon, "weapon_crowbar")) {
		int iCurrent
		if (LM_IsClientAdmin(plyClient))
		iCurrent = g_iPlayerCurrent[plyClient]
			
		if (iCurrent != 0) {
			if (buttons & IN_ATTACK && !g_bIsPressingAttack[plyClient]) {
				RunCommand(plyClient)
				g_bIsPressingAttack[plyClient] = true
			}
		}
		if (buttons & IN_ATTACK2 && !g_bIsPressingAttack[plyClient]) {
			ChangeCommand(plyClient)
			g_bIsPressingAttack[plyClient] = true
		}
	}
	
	if (LM_IsClientAdmin(plyClient) && buttons & (IN_ATTACK | IN_ATTACK2) && iWeapon != -1 && IsValidEdict(iWeapon) && GetEdictClassname(iWeapon, szWeapon, sizeof(szWeapon)) && StrEqual(szWeapon, "weapon_stunstick")) {
		if (g_iAdminCurrent[plyClient] != 0) {
			if (buttons & IN_ATTACK && !g_bIsPressingAttack[plyClient]) {
				RunAdminCommand(plyClient)
				g_bIsPressingAttack[plyClient] = true
			}
		}
		if (buttons & IN_ATTACK2 && !g_bIsPressingAttack[plyClient]) {
			ChangeAdminCommand(plyClient)
			g_bIsPressingAttack[plyClient] = true
		}
	}
	
	if(!(buttons & IN_ATTACK) && !(buttons & IN_ATTACK2))
		g_bIsPressingAttack[plyClient] = false
	
	if (g_bIsPressingAttack[plyClient]) {
		buttons &= ~IN_ATTACK
		buttons &= ~IN_ATTACK2
	}
	return Plugin_Handled
}

void RunCommand(plyClient) {
	int iCurrentMode = g_iPlayerCurrent[plyClient]
	FakeClientCommand(plyClient, g_szPlayerCmdList[iCurrentMode])
}

void ChangeCommand(plyClient) {
	int iCurrent
	char szCurrent[8]

	if (g_iPlayerCurrent[plyClient] < g_iPlayerCmdSize - 1)
		g_iPlayerCurrent[plyClient]++
	else
		g_iPlayerCurrent[plyClient] = 0
		
	iCurrent = g_iPlayerCurrent[plyClient]
	if (iCurrent+1 >= 10)
		Format(szCurrent, sizeof(szCurrent), "%i.", iCurrent+1)
	else
		Format(szCurrent, sizeof(szCurrent), "0%i.", iCurrent+1)
	
	LM_PrintToChat(plyClient, "%s %s", szCurrent, g_szPlayerCmdText[iCurrent])
	
}

void RunAdminCommand(plyClient) {
	int iCurrentMode = g_iAdminCurrent[plyClient]
	FakeClientCommand(plyClient, g_szAdminCmdList[iCurrentMode])
}

void ChangeAdminCommand(plyClient) {
	if (g_iAdminCurrent[plyClient] < g_iAdminCmdSize - 1)
		g_iAdminCurrent[plyClient]++
	else
		g_iAdminCurrent[plyClient] = 0
		
	int iCurrent = g_iAdminCurrent[plyClient]
	char szCurrent[8]
	if (iCurrent+1 >= 10)
		Format(szCurrent, sizeof(szCurrent), "%i.", iCurrent+1)
	else
		Format(szCurrent, sizeof(szCurrent), "0%i.", iCurrent+1)
	
	LM_PrintToChat(plyClient, "%s %s %s", MSGTAG_TOOL_ADMIN, szCurrent, g_szAdminCmdText[iCurrent])
}


