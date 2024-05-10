
/**
 * This is the playground I test random messy stuff, do not put it in your server
 */

#include <sourcemod>
#include <sdktools>

#include <vphysics>
#include <smlib>

#include <lazmod>

bool g_bClientConnTest = true


public Plugin myinfo = {
	name = "LazMod Test",
	author = "LaZycAt",
	description = "This is the playground I test random messy stuff, do not put it in your server",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {


	PrintToServer( "LazMod Test loaded!" )
}

public bool OnClientConnect(int plyClient, char[] szRejectMsg, int iMaxLen) {
	if (g_bClientConnTest) {
		String_Trim(szRejectMsg, szRejectMsg, iMaxLen)
		PrintToServer("[LazMod][Test] %L - OnClientConnect(%d, %s, %d)", plyClient, plyClient, szRejectMsg, iMaxLen)
	}

	return true
}

public void OnClientConnected(int plyClient) {
	if (g_bClientConnTest)
		PrintToServer("[LazMod][Test] %L - OnClientConnected(%d)", plyClient, plyClient)
}

public void OnClientPutInServer(int plyClient) {
	if (g_bClientConnTest)
		PrintToServer("[LazMod][Test] %L - OnClientPutInServer(%d)", plyClient, plyClient)
}

public void OnClientAuthorized(int plyClient, const char[] szAuth) {
	if (g_bClientConnTest)
		PrintToServer("[LazMod][Test] %L - OnClientAuthorized(%d, %s)", plyClient, plyClient, szAuth)
}



public Action OnClientPreAdminCheck(int plyClient) {
	if (g_bClientConnTest)
		PrintToServer("[LazMod][Test] %L - OnClientPreAdminCheck(%d)", plyClient, plyClient)
	return Plugin_Continue
	// return Plugin_Handled
}

public void OnClientPostAdminFilter(int plyClient) {
	if (g_bClientConnTest)
		PrintToServer("[LazMod][Test] %L - OnClientPostAdminFilter(%d)", plyClient, plyClient)
}

public void OnClientPostAdminCheck(int plyClient) {
	if (g_bClientConnTest)
		PrintToServer("[LazMod][Test] %L - OnClientPostAdminCheck(%d)", plyClient, plyClient)
}



public void OnClientDisconnect(int plyClient) {
	if (g_bClientConnTest)
		PrintToServer("[LazMod][Test] %L - OnClientDisconnect(%d)", plyClient, plyClient)
}

public void OnClientDisconnect_Post(int plyClient) {
	if (g_bClientConnTest)
		PrintToServer("[LazMod][Test] -<><STEAM_ID_PENDING><> - OnClientDisconnect_Post(%d)", plyClient, plyClient)
}



