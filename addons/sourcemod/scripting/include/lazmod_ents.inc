
#include <smlib>

/**
 * Get origin of an entity.
 * 
 * @param entProp		Entity index
 * @param vOrigin		Origin[3] to return to
 */
stock void LM_GetEntOrigin(const int entProp, float vOrigin[3]) {

	GetEntPropVector(entProp, Prop_Data, "m_vecOrigin", vOrigin)
}

/**
 * Get angles of an entity.
 * 
 * @param entProp		Entity index
 * @param vAngles		Angles[3] to return to
 */
stock void LM_GetEntAngles(const int entProp, float vAngles[3]) {

	GetEntPropVector(entProp, Prop_Data, "m_angRotation", vAngles)
}

/**
 * Get health of an entity.
 * 
 * @param entProp		Entity index
 * 
 * @return				Health of entity
 */
stock int LM_GetEntHealth(const int entProp) {

	return GetEntProp(entProp, Prop_Data, "m_iHealth")
}

/**
 * Get solid type of an entity.
 * 
 * @param entProp		Entity index
 * 
 * @return				Solid type of entity
 */
stock SolidType_t LM_GetEntSolidType(const int entProp) {

	return view_as<SolidType_t>(GetEntProp(entProp, Prop_Data, "m_nSolidType"))
}

/**
 * Set solid type of an entity.
 * 
 * @param entProp		Entity index
 * 
 * @return				Solid type of entity
 */
stock void LM_SetEntSolidType(const int entProp, const SolidType_t stSolidType) {

	SetEntProp(entProp, Prop_Data, "m_nSolidType", view_as<int>(stSolidType))
}

/**
 * Set health of an entity.
 * 
 * @param entProp		Entity index
 * @param iHealth		Health value
 */
stock void LM_SetEntHealth(const int entProp, const int iHealth) {

	SetEntProp(entProp, Prop_Data, "m_iHealth", iHealth)
}

/**
 * Get target name of an entity.
 * 
 * @param entProp		Entity index
 * @param szTName		Targetname to return to
 * @param iMaxlen		Max length of string
 */
stock LM_GetEntTargetName(const int entProp, char[] szTName, const int iMaxlen) {

	GetEntPropString(entProp, Prop_Data, "m_iName", szTName, iMaxlen);
}

/**
 * Get class name of an entity.
 * 
 * @param entProp		Entity index
 * @param szCName		Classname to return to
 * @param iMaxlen		Max length of string
 */
stock LM_GetEntClassname(const int entProp, char[] szCName, const int iMaxlen) {

	GetEntPropString(entProp, Prop_Data, "m_iClassname", szCName, iMaxlen);
}

/**
 * Get model name of an entity.
 * 
 * @param entProp		Entity index
 * @param szModel		Modelname to return to
 * @param iMaxlen		Max length of string
 */
stock LM_GetEntModel(const int entProp, char[] szModel, const int iMaxlen) {

	GetEntPropString(entProp, Prop_Data, "m_ModelName", szModel, iMaxlen)
}

/**
 * Set render mode, fx, color, alpha amount of an entity.
 * RenderMode: https://developer.valvesoftware.com/wiki/Render_Modes
 * RenderFx: https://developer.valvesoftware.com/wiki/Template:KV_Render_FX
 * 
 * @param entProp		Entity index
 * @param szModel		Modelname to return to
 * @param iMaxlen		Max length of string
 */
stock LM_SetEntRenderEffects(const int entProp, RenderMode rmMode = RENDER_NORMAL, const RenderFx rfFX = RENDERFX_NONE, const int iAlpha = 255, int iColors[3] = {255,...}, char[] szColors = "") {

	SetEntityRenderMode(entProp, rmMode)
	SetEntityRenderFx(entProp, rfFX)
	if (!StrEqual(szColors, "")) {
		char szColor[3][4]
		if (StrContains(szColors, " ")) {
			ExplodeString(szColors, " ", szColor, sizeof(szColor), sizeof(szColor[]))
		} else if (StrContains(szColors, ",")) {
			ExplodeString(szColors, ",", szColor, sizeof(szColor), sizeof(szColor[]))
		} else if (StrContains(szColors, ", ")) {
			ExplodeString(szColors, ", ", szColor, sizeof(szColor), sizeof(szColor[]))
		}
		iColors[0] = StringToInt(szColor[0])
		iColors[1] = StringToInt(szColor[1])
		iColors[2] = StringToInt(szColor[2])
	}
	SetEntityRenderColor(entProp, iColors[0], iColors[1], iColors[2], iAlpha)
}



/**
 * Get active weapon of an entity, usually a player or npc.
 * 
 * @param entProp		Entity index
 * 
 * @return				Weapon ent index
 */
stock int LM_GetEntActiveWeapon(const int entProp) {

	return GetEntPropEnt(entProp, Prop_Send, "m_hActiveWeapon")
}


/**
 * Check if a prop is a func_* prop
 *
 * @param entProp			Entity index.
 * @return					True if func, false otherwise.
 */
stock bool LM_IsEntFunc(const int entProp) {
	char szClass[32]
	LM_GetEntClassname(entProp, szClass, sizeof(szClass))
	if (StrContains(szClass, "func_", false) == 0 && !StrEqual(szClass, "func_physbox"))
		return true
	return false
}

/**
 * Check if a prop is a npc_* prop
 *
 * @param entProp			Entity index.
 * @return					True if NPC, false otherwise.
 */
stock bool LM_IsEntNpc(const int entProp) {
	return view_as<bool>(GetEntityFlags(entProp) & (FL_NPC))
}

/**
 * Check if a prop is a Player
 *
 * @param entProp			Entity index.
 * @return					True if Player, false otherwise.
 */
stock bool LM_IsEntPlayer(const int entProp) {
	return view_as<bool>(GetEntityFlags(entProp) & (FL_CLIENT | FL_FAKECLIENT))
}



