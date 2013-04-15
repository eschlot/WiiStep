/* Header file for wiilight library.
 * Derived from `wiilight` demo created by `bool` <http://bool.rawrstudios.com>
 * Repackaged for WiiStep */

#ifndef WIILIGHT_H
#define WIILIGHT_H

void WIILIGHT_Init();
void WIILIGHT_TurnOn();
int WIILIGHT_GetLevel();
int WIILIGHT_SetLevel(int level);

void WIILIGHT_Toggle();
void WIILIGHT_TurnOff();

#endif
