

#define LAZMODTAG_COLOR "\x01[\x04LM\x01]"
#define LAZMODTAG "[LazMod]"

#define INFOTAG  "[Info]"
#define WARNTAG  "[Warn]"
#define ERRORTAG "[Erro]"


/**
 * Prints a message to client's chat with the LazMod tag.
 *
 * @param plyClient			Client index.
 * @param format			Formatting rules.
 * @param ...				Variable number of format parameters.
 * @return					Number of bytes written.
 */
stock int LM_PrintToChat(const int plyClient, const char[] format, any ...) {
	char szMsg[256]
	int written = VFormat(szMsg, sizeof(szMsg), format, 3)
	PrintToChat(plyClient, "%s %s", LAZMODTAG_COLOR, szMsg)
	return written
}

/**
 * Prints a message to client's console with the LazMod tag.
 *
 * @param plyClient			Client index.
 * @param format			Formatting rules.
 * @param ...				Variable number of format parameters.
 * @return					Number of bytes written.
 */
stock int LM_PrintToConsole(const int plyClient, const char[] format, any ...) {
	char szMsg[256]
	int written = VFormat(szMsg, sizeof(szMsg), format, 3)
	PrintToConsole(plyClient, "%s %s", LAZMODTAG, szMsg)
	return written
}

/**
 * Prints a message to client's console with the LazMod and error tag.
 *
 * @param plyClient			Client index.
 * @param format			Formatting rules.
 * @param ...				Variable number of format parameters.
 * @return					Number of bytes written.
 */
stock int LM_PrintToConsoleError(const int plyClient, const char[] format, any ...) {
	char szMsg[256]
	int written = VFormat(szMsg, sizeof(szMsg), format, 3)
	PrintToConsole(plyClient, "%s%s %s", LAZMODTAG, ERRORTAG, szMsg)
	return written
}

/**
 * Prints a message to all client's console with the LazMod tag.
 *
 * @param format			Formatting rules.
 * @param ...				Variable number of format parameters.
 * @return					Number of bytes written.
 */
stock int LM_PrintToConsoleAll(const char[] format, any ...) {
	char szMsg[256]
	int written = VFormat(szMsg, sizeof(szMsg), format, 2)
	PrintToConsoleAll("%s %s", LAZMODTAG, szMsg)
	return written
}

/**
 * Prints a message to all client's console with the LazMod and error tag.
 *
 * @param format			Formatting rules.
 * @param ...				Variable number of format parameters.
 * @return					Number of bytes written.
 */
stock int LM_PrintToConsoleAllError(const char[] format, any ...) {
	char szMsg[256]
	int written = VFormat(szMsg, sizeof(szMsg), format, 2)
	PrintToConsoleAll("%s%s %s", LAZMODTAG, ERRORTAG, szMsg)
	return written
}

/**
 * Prints a message to all clients with the LazMod tag.
 *
 * @param format			Formatting rules.
 * @param ...				Variable number of format parameters.
 * @return					Number of bytes written.
 */
stock int LM_PrintToAll(const char[] format, any ...) {
	char szMsg[256]
	int written = VFormat(szMsg, sizeof(szMsg), format, 2)
	PrintToChatAll("%s %s", LAZMODTAG_COLOR, szMsg)
	return written
}

/**
 * Prints a message to server with the LazMod tag.
 *
 * @param format			Formatting rules.
 * @param ...				Variable number of format parameters.
 * @return					Number of bytes written.
 */
stock int LM_PrintToServer(const char[] format, any ...) {
	char szMsg[256]
	int written = VFormat(szMsg, sizeof(szMsg), format, 2)
	PrintToServer("%s %s", LAZMODTAG, szMsg)
	return written
}

/**
 * Prints a message to server with the LazMod and error tag.
 *
 * @param format			Formatting rules.
 * @param ...				Variable number of format parameters.
 * @return					Number of bytes written.
 */
stock int LM_PrintToServerError(const char[] format, any ...) {
	char szMsg[192]
	int written = VFormat(szMsg, sizeof(szMsg), format, 2)
	PrintToServer("%s%s %s", LAZMODTAG, ERRORTAG, szMsg)
	return written
}


/**
 * Logging commands and args.
 * 
 * @param plyClient			Client index.
 * @param command			Command to log.
 * @param args				Args to log.
 * @return					Number of bytes written.
 */
stock int LM_LogCmd(const int plyClient, const char[] szCmd, const char[] szArgs) {
	
	static char szLogPath[64]
	char szTime[16], szName[33], szAuthid[MAX_AUTHID_LENGTH]
	
	FormatTime(szTime, sizeof(szTime), "%Y-%m-%d")
	GetClientName(plyClient, szName, sizeof(szName))
	GetClientAuthId(plyClient, AuthId_Steam2, szAuthid, sizeof(szAuthid))
	
	BuildPath(Path_SM, szLogPath, 64, "logs/LazMod-%s.log", szTime)
	
	char szBuffer[256]
	int iWritten = 0
	if (StrEqual(szArgs, "")) {
		Format(szBuffer, sizeof(szBuffer), "\"%s\" (%s) Cmd: %s", szName, szAuthid, szCmd)
		LogToFile(szLogPath, szBuffer)
		LogToGame(szBuffer)
		iWritten = strlen(szBuffer)
	} else {
		Format(szBuffer, sizeof(szBuffer), "\"%s\" (%s) Cmd: %s, Args:%s", szName, szAuthid, szCmd, szArgs)
		LogToFile(szLogPath, szBuffer)
		LogToGame(szBuffer)
		iWritten = strlen(szBuffer)
	}
	return iWritten
}






