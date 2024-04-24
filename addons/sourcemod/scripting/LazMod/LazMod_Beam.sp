#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <lazmod>
#include <lazmod_stocks>
#include <vphysics>

#define MSGTAG "\x01[\x04LM\x01]"

// Global definions
new g_LBeam;
new g_Halo;
new g_Beam;

new ColorWhite[4] = { 255,255,255,255};
new ColorRed[4] = { 255,50,50,255};
new ColorBlue[4] = { 50,50,255,255};

public Plugin:myinfo = {
	name = "LazMod - Beam",
	author = "LaZycAt, hjkwe654",
	description = "Beam stuff.",
	version = LAZMOD_VER,
	url = ""
};

public OnPluginStart() {
	RegAdminCmd("sm_deathray", Command_Deathray, 0, "To blow you up.");
	RegAdminCmd("sm_droct", Command_DrOct, 0, "To hurt you.");
}

public OnMapStart() {
	g_LBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_Halo = PrecacheModel("materials/sprites/halo01.vmt");
	g_Beam = PrecacheModel("materials/sprites/laser.vmt");
	PrecacheSound("dr_oct.wav", true);
	PrecacheSound("npc/strider/charging.wav", true);
	PrecacheSound("npc/strider/fire.wav", true);
}



public Action:Command_Deathray(Client, args) {
	new Float:fClientPos[3], Float:fAimPos[3];
	new iColor[4];
	
	LM_ClientAimPos(Client, fAimPos);
	
	new iEntity = GetClientAimTarget(Client);
	if (iEntity != -1) {
		static EntFlag; EntFlag = GetEntityFlags(iEntity);
		if (EntFlag & (FL_CLIENT | FL_FAKECLIENT))
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fAimPos);
	}
	
	GetClientAbsOrigin(Client, fClientPos);
	new Obj_Explosion = CreateEntityByName("env_explosion");
	fClientPos[2] = (fClientPos[2] + 50);
	
	TeleportEntity(Obj_Explosion, fAimPos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Obj_Explosion, "iMagnitude", "200");
	DispatchKeyValue(Obj_Explosion, "iRadiusOverride", "200");
	DispatchSpawn(Obj_Explosion);
	
	iColor[0] = GetRandomInt(50, 255);
	iColor[1] = GetRandomInt(50, 255);
	iColor[2] = GetRandomInt(50, 255);
	iColor[3] = GetRandomInt(250, 255);
	
	TE_SetupBeamPoints(fAimPos, fClientPos, g_LBeam, g_Halo, 0, 66, 0.1, 3.0, 3.0, 0, 0.0, iColor, 20);
	TE_SendToAll();
	
	AcceptEntityInput(Obj_Explosion, "explode", Client, Client);
	AcceptEntityInput(Obj_Explosion, "kill", -1);
	return Plugin_Handled;
}

public Action:Command_DrOct(Client, args) {
	new String:szRange[8];
	GetCmdArg(1, szRange, sizeof(szRange));
	
	if (StringToInt(szRange) < 1)
		szRange = "300";
	
	new Float:vDrOctOrigin[3];
	LM_ClientAimPos(Client, vDrOctOrigin);
	DrOctCharge(Client, vDrOctOrigin, szRange);
	return Plugin_Handled;
}

// Timers
public DrOctCharge(Client, Float:vDrOctOrigin[3], String:szRange[]) {
	new Float:vOriginPlayer[3], Float:vOriginPlayerBeam[3];
	
	GetClientAbsOrigin(Client, vOriginPlayer);
	GetClientAbsOrigin(Client, vOriginPlayerBeam);
	vOriginPlayerBeam[2] += 50;
	EmitAmbientSound("dr_oct.wav", vDrOctOrigin, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);
	EmitAmbientSound("dr_oct.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);
	EmitAmbientSound("npc/strider/charging.wav", vDrOctOrigin, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);
	EmitAmbientSound("npc/strider/charging.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);
	
	new Obj_Push = CreateEntityByName("point_push");
	TeleportEntity(Obj_Push, vDrOctOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Obj_Push, "magnitude", "-1000");
	DispatchKeyValue(Obj_Push, "radius", szRange);
	DispatchKeyValue(Obj_Push, "inner_radius", szRange);
	DispatchKeyValue(Obj_Push, "spawnflags", "28");
	DispatchSpawn(Obj_Push);
	AcceptEntityInput(Obj_Push, "enable", -1);
	
	new Obj_Core = CreateEntityByName("env_citadel_energy_core");
	TeleportEntity(Obj_Core, vDrOctOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Obj_Core, "scale", "5");
	DispatchKeyValue(Obj_Core, "spawnflags", "1");
	DispatchSpawn(Obj_Core);
	AcceptEntityInput(Obj_Core, "startdischarge", -1);
	
	TE_SetupBeamPoints(vDrOctOrigin, vOriginPlayerBeam, g_Beam, g_Halo, 0, 66, 1.3, 15.0, 15.0, 0, 0.0, ColorBlue, 20);
	TE_SendToAll();
	TE_SetupBeamPoints(vDrOctOrigin, vOriginPlayerBeam, g_Beam, g_Halo, 0, 66, 1.3, 20.0, 20.0, 0, 0.0, ColorWhite, 20);
	TE_SendToAll();
	
	new Handle:hDataPack;
	CreateDataTimer(1.2, Timer_DrOctFire, hDataPack);
	WritePackCell(hDataPack, Client);
	WritePackCell(hDataPack, Obj_Push);
	WritePackCell(hDataPack, Obj_Core);
	WritePackFloat(hDataPack, vDrOctOrigin[0]);
	WritePackFloat(hDataPack, vDrOctOrigin[1]);
	WritePackFloat(hDataPack, vDrOctOrigin[2]);
	WritePackFloat(hDataPack, vOriginPlayerBeam[0]);
	WritePackFloat(hDataPack, vOriginPlayerBeam[1]);
	WritePackFloat(hDataPack, vOriginPlayerBeam[2]);
	return;
}

public Action:Timer_DrOctFire(Handle:Timer, Handle:hDataPack) {
	
	ResetPack(hDataPack);
	new Client = ReadPackCell(hDataPack);
	new Obj_Push = ReadPackCell(hDataPack);
	new Obj_Core = ReadPackCell(hDataPack);
	new Float:vDrOctOrigin[3];
	vDrOctOrigin[0] = ReadPackFloat(hDataPack);
	vDrOctOrigin[1] = ReadPackFloat(hDataPack);
	vDrOctOrigin[2] = ReadPackFloat(hDataPack);
	new Float:vOriginPlayerBeam[3];
	vOriginPlayerBeam[0] = ReadPackFloat(hDataPack);
	vOriginPlayerBeam[1] = ReadPackFloat(hDataPack);
	vOriginPlayerBeam[2] = ReadPackFloat(hDataPack);
	
	EmitAmbientSound("npc/strider/fire.wav", vDrOctOrigin, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	EmitAmbientSound("npc/strider/fire.wav", vOriginPlayerBeam, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	TE_SetupBeamPoints(vDrOctOrigin, vOriginPlayerBeam, g_Beam, g_Halo, 0, 66, 0.2, 15.0, 15.0, 0, 0.0, ColorRed, 20);
	TE_SendToAll();
	TE_SetupBeamPoints(vDrOctOrigin, vOriginPlayerBeam, g_Beam, g_Halo, 0, 66, 0.2, 20.0, 20.0, 0, 0.0, ColorWhite, 20);
	TE_SendToAll();
	DispatchKeyValue(Obj_Push, "magnitude", "1000");
	
	new Handle:hNewPack;
	CreateDataTimer(0.01, Timer_DrOctRemove, hNewPack);
	WritePackCell(hNewPack, Obj_Push);
	WritePackCell(hNewPack, Obj_Core);
}

public Action:Timer_DrOctRemove(Handle:Timer, Handle:hDataPack) {
	ResetPack(hDataPack);
	new Obj_Push = ReadPackCell(hDataPack);
	new Obj_Core = ReadPackCell(hDataPack);
	if (IsValidEntity(Obj_Push))
		AcceptEntityInput(Obj_Push, "kill", -1);
	if (IsValidEntity(Obj_Core))
		AcceptEntityInput(Obj_Core, "kill", -1);
}
