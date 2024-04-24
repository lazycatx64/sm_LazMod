

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>

static int COLOR_WHITE[4]	= {255,255,255,255}
static int COLOR_RED[4]	= {255,50,50,255}
// static int COLOR_GREEN[4]	= {50,255,50,255}
static int COLOR_BLUE[4]	= {50,50,255,255}

// Global definions
int g_mdlLaserBeam
int g_mdlHalo
int g_mdlBeam

public Plugin myinfo = {
	name = "LazMod - Beam",
	author = "LaZycAt, hjkwe654",
	description = "Beamy stuff.",
	version = LAZMOD_VER,
	url = ""
}

public OnPluginStart() {
	RegAdminCmd("sm_deathray", Command_Deathray, 0, "boom boom.")
	RegAdminCmd("sm_droct", Command_DrOct, 0, "Can also add range parameter but you shouldn't.")
}

public OnMapStart() {
	g_mdlLaserBeam = PrecacheModel("materials/sprites/laserbeam.vmt")
	g_mdlHalo = PrecacheModel("materials/sprites/halo01.vmt")
	g_mdlBeam = PrecacheModel("materials/sprites/laser.vmt")
	PrecacheSound("dr_oct.wav", true)
	PrecacheSound("npc/strider/charging.wav", true)
	PrecacheSound("npc/strider/fire.wav", true)
}



public Action Command_Deathray(Client, args) {
	float fClientPos[3], fAimPos[3]
	int iColor[4]
	
	LM_ClientAimPos(Client, fAimPos)
	
	int entProp = GetClientAimTarget(Client)
	if (entProp != -1) {
		static EntFlag; EntFlag = GetEntityFlags(entProp)
		if (EntFlag & (FL_CLIENT | FL_FAKECLIENT))
			GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", fAimPos)
	}
	
	GetClientAbsOrigin(Client, fClientPos)
	int entExplosion = CreateEntityByName("env_explosion")
	fClientPos[2] = (fClientPos[2] + 50)
	
	TeleportEntity(entExplosion, fAimPos, NULL_VECTOR, NULL_VECTOR)
	DispatchKeyValue(entExplosion, "iMagnitude", "200")
	DispatchKeyValue(entExplosion, "iRadiusOverride", "200")
	DispatchSpawn(entExplosion)
	
	iColor[0] = GetRandomInt(50, 255)
	iColor[1] = GetRandomInt(50, 255)
	iColor[2] = GetRandomInt(50, 255)
	iColor[3] = GetRandomInt(250, 255)
	
	TE_SetupBeamPoints(fAimPos, fClientPos, g_mdlLaserBeam, g_mdlHalo, 0, 66, 0.1, 3.0, 3.0, 0, 0.0, iColor, 20)
	TE_SendToAll()
	
	AcceptEntityInput(entExplosion, "explode", Client, Client)
	AcceptEntityInput(entExplosion, "kill", -1)
	return Plugin_Handled
}

public Action Command_DrOct(Client, args) {
	char szRange[8]
	GetCmdArg(1, szRange, sizeof(szRange))
	
	if (StringToInt(szRange) < 1)
		szRange = "300"
	
	float vDrOctOrigin[3]
	LM_ClientAimPos(Client, vDrOctOrigin)
	DrOctCharge(Client, vDrOctOrigin, szRange)
	return Plugin_Handled
}

// Timers
public DrOctCharge(Client, float vDrOctOrigin[3], char[] szRange) {
	float vOriginPlayer[3], vOriginPlayerBeam[3]
	
	GetClientAbsOrigin(Client, vOriginPlayer)
	GetClientAbsOrigin(Client, vOriginPlayerBeam)
	vOriginPlayerBeam[2] += 50
	EmitAmbientSound("dr_oct.wav", vDrOctOrigin, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3)
	EmitAmbientSound("dr_oct.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3)
	EmitAmbientSound("npc/strider/charging.wav", vDrOctOrigin, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3)
	EmitAmbientSound("npc/strider/charging.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3)
	
	int entPush = CreateEntityByName("point_push")
	TeleportEntity(entPush, vDrOctOrigin, NULL_VECTOR, NULL_VECTOR)
	DispatchKeyValue(entPush, "magnitude", "-1000")
	DispatchKeyValue(entPush, "radius", szRange)
	DispatchKeyValue(entPush, "inner_radius", szRange)
	DispatchKeyValue(entPush, "spawnflags", "28")
	DispatchSpawn(entPush)
	AcceptEntityInput(entPush, "enable", -1)
	
	int entCore = CreateEntityByName("env_citadel_energy_core")
	TeleportEntity(entCore, vDrOctOrigin, NULL_VECTOR, NULL_VECTOR)
	DispatchKeyValue(entCore, "scale", "5")
	DispatchKeyValue(entCore, "spawnflags", "1")
	DispatchSpawn(entCore)
	AcceptEntityInput(entCore, "startdischarge", -1)
	
	TE_SetupBeamPoints(vDrOctOrigin, vOriginPlayerBeam, g_mdlBeam, g_mdlHalo, 0, 66, 1.3, 15.0, 15.0, 0, 0.0, COLOR_BLUE, 20)
	TE_SendToAll()
	TE_SetupBeamPoints(vDrOctOrigin, vOriginPlayerBeam, g_mdlBeam, g_mdlHalo, 0, 66, 1.3, 20.0, 20.0, 0, 0.0, COLOR_WHITE, 20)
	TE_SendToAll()
	
	Handle hDataPack
	CreateDataTimer(1.2, Timer_DrOctFire, hDataPack)
	WritePackCell(hDataPack, Client)
	WritePackCell(hDataPack, entPush)
	WritePackCell(hDataPack, entCore)
	WritePackFloat(hDataPack, vDrOctOrigin[0])
	WritePackFloat(hDataPack, vDrOctOrigin[1])
	WritePackFloat(hDataPack, vDrOctOrigin[2])
	WritePackFloat(hDataPack, vOriginPlayerBeam[0])
	WritePackFloat(hDataPack, vOriginPlayerBeam[1])
	WritePackFloat(hDataPack, vOriginPlayerBeam[2])
	return 0
}

public Action Timer_DrOctFire(Handle Timer, Handle hDataPack) {
	
	ResetPack(hDataPack)
	int Client = ReadPackCell(hDataPack)
	int entPush = ReadPackCell(hDataPack)
	int entCore = ReadPackCell(hDataPack)
	float vDrOctOrigin[3]
	vDrOctOrigin[0] = ReadPackFloat(hDataPack)
	vDrOctOrigin[1] = ReadPackFloat(hDataPack)
	vDrOctOrigin[2] = ReadPackFloat(hDataPack)
	float vOriginPlayerBeam[3]
	vOriginPlayerBeam[0] = ReadPackFloat(hDataPack)
	vOriginPlayerBeam[1] = ReadPackFloat(hDataPack)
	vOriginPlayerBeam[2] = ReadPackFloat(hDataPack)
	
	EmitAmbientSound("npc/strider/fire.wav", vDrOctOrigin, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	EmitAmbientSound("npc/strider/fire.wav", vOriginPlayerBeam, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5)
	
	TE_SetupBeamPoints(vDrOctOrigin, vOriginPlayerBeam, g_mdlBeam, g_mdlHalo, 0, 66, 0.2, 15.0, 15.0, 0, 0.0, COLOR_RED, 20)
	TE_SendToAll()
	TE_SetupBeamPoints(vDrOctOrigin, vOriginPlayerBeam, g_mdlBeam, g_mdlHalo, 0, 66, 0.2, 20.0, 20.0, 0, 0.0, COLOR_WHITE, 20)
	TE_SendToAll()
	DispatchKeyValue(entPush, "magnitude", "1000")
	
	Handle hNewPack
	CreateDataTimer(0.01, Timer_DrOctRemove, hNewPack)
	WritePackCell(hNewPack, entPush)
	WritePackCell(hNewPack, entCore)
	return Plugin_Handled
}

public Action Timer_DrOctRemove(Handle Timer, Handle hDataPack) {
	ResetPack(hDataPack)
	int entPush = ReadPackCell(hDataPack)
	int entCore = ReadPackCell(hDataPack)
	if (IsValidEntity(entPush))
		AcceptEntityInput(entPush, "kill", -1)
	if (IsValidEntity(entCore))
		AcceptEntityInput(entCore, "kill", -1)
	return Plugin_Handled
}
