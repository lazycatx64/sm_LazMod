

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

public OnClientDisconnect(Client) {
	g_iAdminCurrent[Client] = 0
	g_iPlayerCurrent[Client] = 0
}

public Action Event_OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
	new Client = GetClientOfUserId(GetEventInt(event, "userid"))
	GivePlayerItem(Client, "weapon_crowbar")
	GivePlayerItem(Client, "weapon_stunstick")

	return Plugin_Handled
}

public Action OnPlayerRunCmd(Client, &buttons, &impulse, float vel[3], float angles[3], &weapon) {
	
	char szWeapon[64]
	int iWeapon = GetEntPropEnt(Client, Prop_Send, "m_hActiveWeapon")
	
	if (buttons & (IN_ATTACK | IN_ATTACK2) && iWeapon != -1 && IsValidEdict(iWeapon) && GetEdictClassname(iWeapon, szWeapon, sizeof(szWeapon)) && StrEqual(szWeapon, "weapon_crowbar")) {
		int iCurrent
		if (LM_IsAdmin(Client))
		iCurrent = g_iPlayerCurrent[Client]
			
		if (iCurrent != 0) {
			if (buttons & IN_ATTACK && !g_bIsPressingAttack[Client]) {
				RunCommand(Client)
				g_bIsPressingAttack[Client] = true
			}
		}
		if (buttons & IN_ATTACK2 && !g_bIsPressingAttack[Client]) {
			ChangeCommand(Client)
			g_bIsPressingAttack[Client] = true
		}
	}
	
	if (LM_IsAdmin(Client) && buttons & (IN_ATTACK | IN_ATTACK2) && iWeapon != -1 && IsValidEdict(iWeapon) && GetEdictClassname(iWeapon, szWeapon, sizeof(szWeapon)) && StrEqual(szWeapon, "weapon_stunstick")) {
		if (g_iAdminCurrent[Client] != 0) {
			if (buttons & IN_ATTACK && !g_bIsPressingAttack[Client]) {
				RunAdminCommand(Client)
				g_bIsPressingAttack[Client] = true
			}
		}
		if (buttons & IN_ATTACK2 && !g_bIsPressingAttack[Client]) {
			ChangeAdminCommand(Client)
			g_bIsPressingAttack[Client] = true
		}
	}
	
	if(!(buttons & IN_ATTACK) && !(buttons & IN_ATTACK2))
		g_bIsPressingAttack[Client] = false
	
	if (g_bIsPressingAttack[Client]) {
		buttons &= ~IN_ATTACK
		buttons &= ~IN_ATTACK2
	}
	return Plugin_Handled
}

public RunCommand(Client) {
	new iCurrent = g_iPlayerCurrent[Client]
	FakeClientCommand(Client, g_szPlayerCmdList[iCurrent])
}

public ChangeCommand(Client) {
	int iCurrent
	char szCurrent[8]

	if (g_iPlayerCurrent[Client] < g_iPlayerCmdSize - 1)
		g_iPlayerCurrent[Client]++
	else
		g_iPlayerCurrent[Client] = 0
		
	iCurrent = g_iPlayerCurrent[Client]
	if (iCurrent+1 >= 10)
		Format(szCurrent, sizeof(szCurrent), "%i.", iCurrent+1)
	else
		Format(szCurrent, sizeof(szCurrent), "0%i.", iCurrent+1)
	
	LM_PrintToChat(Client, "%s %s", szCurrent, g_szPlayerCmdText[iCurrent])
	
}

public RunAdminCommand(Client) {
	new iCurrent = g_iAdminCurrent[Client]
	FakeClientCommand(Client, g_szAdminCmdList[iCurrent])
}

public ChangeAdminCommand(Client) {
	if (g_iAdminCurrent[Client] < g_iAdminCmdSize - 1)
		g_iAdminCurrent[Client]++
	else
		g_iAdminCurrent[Client] = 0
		
	int iCurrent = g_iAdminCurrent[Client]
	char szCurrent[8]
	if (iCurrent+1 >= 10)
		Format(szCurrent, sizeof(szCurrent), "%i.", iCurrent+1)
	else
		Format(szCurrent, sizeof(szCurrent), "0%i.", iCurrent+1)
	
	LM_PrintToChat(Client, "%s %s %s", MSGTAG_TOOL_ADMIN, szCurrent, g_szAdminCmdText[iCurrent])
}


