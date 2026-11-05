#ifndef RUNNER_DESKTOP_GEOMETRY_H_
#define RUNNER_DESKTOP_GEOMETRY_H_

#include <flutter/binary_messenger.h>
#include <windows.h>

void RegisterDesktopGeometry(flutter::BinaryMessenger* messenger, HWND window);

#endif
