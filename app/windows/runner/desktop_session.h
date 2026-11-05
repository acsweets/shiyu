#ifndef RUNNER_DESKTOP_SESSION_H_
#define RUNNER_DESKTOP_SESSION_H_

#include <windows.h>

constexpr UINT kShiyuReopen = WM_APP + 38;
constexpr UINT_PTR kShiyuFullscreenTimer = 539;

// Windows 会话内只保留一个主引擎，子浮窗仍由该进程创建。
class DesktopSession {
 public:
  DesktopSession();
  ~DesktopSession();

  bool IsPrimary() const { return primary_; }
  void Attach(HWND window) const;
  void NotifyExisting() const;

 private:
  HANDLE mutex_ = nullptr;
  bool primary_ = false;
};

bool IsExternalFullscreen();
bool StartupEnabled();
bool SetStartupEnabled(bool enabled);

#endif
