/**
 * DODHooks - SourcePawn Include File
 *
 * Provides natives and forwards for the DODHooks extension.
 * Compatible with SourceMod 1.12 / 1.13
 */

#if defined _dodhooks_included
 #endinput
#endif
#define _dodhooks_included

/**
 * Auto-loads the DODHooks extension whenever a plugin includes this file.
 * SourceMod will load "dodhooks.ext" (resolved to dodhooks.ext.2.dods) when
 * the plugin starts, so no manual "sm exts load" or ".autoload" file is
 * required. Set autoload = 0 if you prefer to control loading yourself.
 */
public Extension __ext_dodhooks =
{
    name = "DODHooks",
    file = "dodhooks.ext.2.dods",
    autoload = 1,
    required = 0,
};

/**
 * Player class constants
 */
enum DODPlayerClass
{
    DODClass_Random      = -2,
    DODClass_None        = 0,
    DODClass_Rifleman    = 1,
    DODClass_Assault     = 2,
    DODClass_Support     = 3,
    DODClass_Sniper      = 4,
    DODClass_Machinegunner = 5,
    DODClass_Rocket      = 6,
};

/**
 * Team constants
 */
#define DODTeam_Unassigned  0
#define DODTeam_Spectator   1
#define DODTeam_Allies      2
#define DODTeam_Axis        3

/**
 * ============================================================
 * NATIVES
 * ============================================================
 */

/**
 * Gets a player's current class.
 *
 * @param client    Client index.
 * @return          Current DODPlayerClass value.
 * @error           Invalid client index.
 */
native int DOD_GetPlayerClass(int client);

/**
 * Sets a player's current class.
 *
 * @param client    Client index.
 * @param class     DODPlayerClass value to set.
 * @return          true on success, false on failure.
 * @error           Invalid client or class value.
 */
native bool DOD_SetPlayerClass(int client, DODPlayerClass playerclass);

/**
 * Gets a player's desired class (the class they will spawn as).
 *
 * @param client    Client index.
 * @return          Desired DODPlayerClass value.
 * @error           Invalid client index.
 */
native int DOD_GetDesiredPlayerClass(int client);

/**
 * Sets a player's desired class.
 *
 * @param client    Client index.
 * @param class     DODPlayerClass value to set.
 * @return          true on success, false on failure.
 * @error           Invalid client or class value.
 */
native bool DOD_SetDesiredPlayerClass(int client, DODPlayerClass playerclass);

/**
 * Forces a player's helmet to pop off.
 *
 * @param client        Client index.
 * @param velocity     Vector array (3 floats) for helmet velocity.
 * @param origin       Vector array (3 floats) for helmet origin.
 * @return              true on success.
 * @error               Invalid client index.
 */
native bool DOD_PopHelmet(int client, const float velocity[3], const float origin[3]);

/**
 * Sets the number of control points on the map.
 *
 * @param numCP     Number of control points.
 * @return          true on success.
 */
native bool DOD_SetNumControlPoints(int numCP);

/**
 * Precaches a control point icon material and returns its index.
 *
 * @param material  Material name to precache.
 * @return          Material index, or 0 on failure.
 */
native int DOD_PrecacheCPIcon(const char[] material);

/**
 * Sets the icons for a control point.
 *
 * @param cpIndex       Control point index.
 * @param alliesIcon    Allies icon material index (0 = no change).
 * @param axisIcon      Axis icon material index (0 = no change).
 * @param neutralIcon   Neutral icon material index (0 = no change).
 * @param timerCapIcon  Timer capture icon material index (0 = no change).
 * @param bombedIcon    Bombed icon material index (0 = no change).
 * @return              true on success.
 */
native bool DOD_SetCPIcons(int cpIndex, int alliesIcon, int axisIcon, int neutralIcon, int timerCapIcon, int bombedIcon);

/**
 * Sets whether a control point is visible.
 *
 * @param cpIndex   Control point index.
 * @param visible   true to show, false to hide.
 * @return          true on success.
 */
native bool DOD_SetCPVisible(int cpIndex, bool visible);

/**
 * Pauses a round timer.
 *
 * @param timerEnt  Entity index of the dod_round_timer.
 * @return          true on success.
 * @error           Invalid timer entity.
 */
native bool DOD_PauseTimer(int timerEnt);

/**
 * Resumes a round timer.
 *
 * @param timerEnt  Entity index of the dod_round_timer.
 * @return          true on success.
 * @error           Invalid timer entity.
 */
native bool DOD_ResumeTimer(int timerEnt);

/**
 * Sets the time remaining on a round timer.
 *
 * @param timerEnt  Entity index of the dod_round_timer.
 * @param seconds   Time remaining in seconds.
 * @return          true on success.
 * @error           Invalid timer entity.
 */
native bool DOD_SetTimeRemaining(int timerEnt, float seconds);

/**
 * Gets the time remaining on a round timer.
 *
 * @param timerEnt  Entity index of the dod_round_timer.
 * @return          Time remaining in seconds (0.0 if paused and expired).
 * @error           Invalid timer entity.
 */
native float DOD_GetTimeRemaining(int timerEnt);

/**
 * Forces a player to respawn.
 *
 * @param client        Client index.
 * @param useClass      If true, uses the player's desired class.
 * @return              true on success.
 * @error               Invalid client index.
 */
native bool DOD_RespawnPlayer(int client, bool useClass = true);

/**
 * Adds wave time for a team.
 *
 * @param team      DODTeam_Allies or DODTeam_Axis.
 * @param delay     Additional time in seconds.
 * @return          true on success.
 * @error           Invalid team.
 */
native bool DOD_AddWaveTime(int team, float delay);

/**
 * Sets the winning team for the current round.
 *
 * @param team      DODTeam_Allies or DODTeam_Axis.
 * @return          true on success.
 * @error           Invalid team.
 */
native bool DOD_SetWinningTeam(int team);

/**
 * Sets the round state.
 *
 * @param state     Round state value.
 * @return          true on success.
 */
native bool DOD_SetRoundState(int state);

/**
 * Sets a player's state.
 *
 * @param client    Client index.
 * @param state     Player state value.
 * @return          true on success.
 * @error           Invalid client index.
 */
native bool DOD_SetPlayerState(int client, int state);

/**
 * Sets a bomb target's state.
 *
 * @param entity    Entity index of the dod_bomb_target.
 * @param state     Bomb target state value.
 * @return          true on success.
 * @error           Invalid entity index.
 */
native bool DOD_SetBombTargetState(int entity, int state);

/**
 * ============================================================
 * FORWARDS (Hooks)
 * ============================================================
 */

/**
 * Called when a player uses a voice command.
 *
 * @param client        Client index.
 * @param voiceCommand  Voice command id (can be modified).
 * @return              Plugin_Handled to block, Plugin_Continue to allow.
 */
forward Action OnVoiceCommand(int client, int &voiceCommand);

/**
 * Called when a player joins a class.
 *
 * @param client        Client index.
 * @param playerClass   Class being joined (can be modified).
 * @return              Plugin_Handled to block, Plugin_Continue to allow.
 */
forward Action OnJoinClass(int client, int &playerClass);

/**
 * Called when a helmet is popped off a player.
 *
 * @param client        Client index.
 * @param velocity      Helmet velocity vector (can be modified).
 * @param origin        Helmet origin vector (can be modified).
 * @return              Plugin_Handled to block, Plugin_Continue to allow.
 */
forward Action OnPopHelmet(int client, float velocity[3], float origin[3]);

/**
 * Called when a player is about to respawn.
 *
 * @param client        Client index.
 * @return              Plugin_Handled to block, Plugin_Continue to allow.
 */
forward Action OnPlayerRespawn(int client);

/**
 * Called when wave time is added for a team.
 *
 * @param team          Team index.
 * @param delay         Time being added (can be modified).
 * @return              Plugin_Handled to block, Plugin_Continue to allow.
 */
forward Action OnAddWaveTime(int team, float &delay);

/**
 * Called when the winning team is set.
 *
 * @param team          Winning team.
 * @return              Plugin_Handled to block, Plugin_Continue to allow.
 */
forward Action OnSetWinningTeam(int team);

/**
 * Called when the round state changes.
 *
 * @param roundState    New round state (can be modified).
 * @return              Plugin_Handled to block, Plugin_Continue to allow.
 */
forward Action OnEnterRoundState(int &roundState);

/**
 * Called when a player's state changes.
 *
 * @param client        Client index.
 * @param playerState   New player state (can be modified).
 * @return              Plugin_Handled to block, Plugin_Continue to allow.
 */
forward Action OnEnterPlayerState(int client, int &playerState);

/**
 * Called when a bomb target's state changes.
 *
 * @param entity        Bomb target entity index.
 * @param bombState     New bomb target state (can be modified).
 * @return              Plugin_Handled to block, Plugin_Continue to allow.
 */
forward Action OnEnterBombTargetState(int entity, int &bombState);
