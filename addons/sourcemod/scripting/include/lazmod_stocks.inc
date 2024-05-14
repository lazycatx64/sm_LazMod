
bool g_bFirstRun = false
int g_entFirstRun = -1

/**
 * Check if plugin already ran before (plugin reload?)
 * Currently just a placeholder, no further use.
 */
stock void LM_FirstRun() {
	if (!g_bFirstRun || g_entFirstRun == -1) {
		g_entFirstRun = FindEntityByClassname(0, "cat_First_Run")
		if (g_entFirstRun == -1) {
			g_entFirstRun = CreateEntityByName("info_target")
			DispatchKeyValue(g_entFirstRun, "classname", "cat_First_Run")
			DispatchSpawn(g_entFirstRun)
			g_bFirstRun = true
		} else
			g_bFirstRun = false
	}
}

/**
 * Check if plugin already ran before (plugin reload?)
 * Currently just a placeholder, no further use.
 * 
 * @return			False if able to find 'cat_First_Run' entity; True otherwise
 */
stock bool LM_IsFirstRun() {
	return FindEntityByClassname(0, "cat_First_Run") == -1
}



/**
 * Check is target client valid.
 *
 * @param plyClient			Client to check.
 * @param plyReply			Client to reply if assigned; no reply otherwise
 * @param bCheckAlive		Also check is target alive.
 * @return					True if target valid. Otherwise false.
 */
stock bool LM_IsClientValid(const int plyClient, const int plyReply = -1, const bool bCheckAlive = false) {
	
	if (plyClient < 1 || plyClient > MAXPLAYERS) {
		if (plyReply == plyClient) {
			// Client not in game
		} else if (plyReply == 0) {
			LM_PrintToServerError("Client is not valid.")
		} else if (plyReply != -1) {
			LM_PrintToChat(plyReply, "Client is not valid.")
		}

		return false
	}

	if (!IsClientInGame(plyClient) || !IsClientAuthorized(plyClient)) {
		if (plyReply == plyClient) {
			// Client not in game
		} else if (plyReply == 0) {
			LM_PrintToServerError("Client is not fully in game.")
		} else if (plyReply != -1) {
			LM_PrintToChat(plyReply, "Client is not fully in game.")
		}

		return false
	}
	
	if (bCheckAlive && !IsPlayerAlive(plyClient)) {
		if (plyReply == plyClient) {
			LM_PrintToChat(plyReply, "You cannot use the command while dead.")
		} else if (plyReply == 0) {
			LM_PrintToServer("Client is dead.")
		} else if (plyReply != -1) {
			LM_PrintToChat(plyReply, "Client is dead.")
		}
		
		return false
	}

	return true
}

/**
 * Check if client is admin.
 * 
 * @param plyClient			Client index.
 * @return					True if admin; false otherwise.
 */
stock bool LM_IsClientAdmin(const int plyClient) {

	if (!IsClientConnected(plyClient))
		ThrowError("Client id %i is not connected.", plyClient)
	
	AdminId Aid = GetUserAdmin(plyClient)
	return GetAdminFlag(Aid, Admin_Generic)
}




/**
 * Get the coordinates of the client's aiming position
 *
 * @param plyClient			Client id
 * @param vAimPos			Aim pos to return
 */
stock void LM_ClientAimPos(int plyClient, float vAimPos[3]) {
	float vOrigin[3], vAngles[3]
	
	GetClientEyePosition(plyClient, vOrigin)
	GetClientEyeAngles(plyClient, vAngles)
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer)
	
	if (TR_DidHit(trace)) {
		TR_GetEndPosition(vAimPos, trace)
	}
	CloseHandle(trace)
}
stock bool TraceEntityFilterPlayer(entity, contentsMask) {
	return entity > MaxClients
}

/**
 * Check if a coord was in range.
 *
 * @param vCheck		Origin to check
 * @param vPoint		Center of this range
 * @param fRange		Search range
 * @return True if was in range; false otherwise.
 */
stock bool LM_IsInRange(float vCheck[3], float vPoint[3], float fRange) {
	if ((vPoint[0] + fRange) > vCheck[0] > (vPoint[0] - fRange) &&
		(vPoint[1] + fRange) > vCheck[1] > (vPoint[1] - fRange) &&
		(vPoint[2] + fRange) > vCheck[2] > (vPoint[2] - fRange))
		return true
		
	return false
}

/**
 * Check if a coord is in a specific cube range
 *
 * @param vCheck			Origin to check
 * @param vPoint1			Point1
 * @param vPoint2			Point2
 * @return					True if vCheck was in cube; false otherwise
 */
stock bool LM_IsInCube(float vCheck[3], float vPoint1[3], float vPoint2[3]) {
	if ((vPoint1[0] > vCheck[0] > vPoint2[0] || vPoint2[0] > vCheck[0] > vPoint1[0]) &&
		(vPoint1[1] > vCheck[1] > vPoint2[1] || vPoint2[1] > vCheck[1] > vPoint1[1]) &&
		(vPoint1[2] > vCheck[2] > vPoint2[2] || vPoint2[2] > vCheck[2] > vPoint1[2]))
		return true

	return false
}


/**
 * Max edicts allowed for LazMod
 * HL2DM currently is 2048.
 * 5% (103) is reserved, so we have 1945 avaliable.
 * https://developer.valvesoftware.com/wiki/Entity_limit
 * 
 * @return 		Max edicts allowed for LazMod
 */
stock int LM_GetMaxEdict() {
	
	return RoundToFloor(GetMaxEntities()*0.95)
}

/**
 * Check if current edict count is about to break SourceEngine.
 * HL2DM currently is 2048.
 * 5% (103) is reserved, so we have 1945 avaliable.
 * https://developer.valvesoftware.com/wiki/Entity_limit
 * 
 * @return 		True if about to hit the reserved limit, false otherwise
 */
stock bool LM_CheckMaxEdict() {
	
	return GetEntityCount() <= LM_GetMaxEdict()
}