#include "flutter_window.h"

#include <optional>
#include <wtsapi32.h>

#include "flutter/generated_plugin_registrant.h"
#include "desktop_session.h"
#include "desktop_geometry.h"
#include "desktop_multi_window/desktop_multi_window_plugin.h"
#include "file_selector_windows/file_selector_windows.h"
#include "resource.h"
#include "window_manager/window_manager_plugin.h"
#include "screen_retriever_windows/screen_retriever_windows_plugin_c_api.h"

namespace {
constexpr int kVisibilityShortcut = 381;
constexpr int kFirstAmountShortcut = 382;
constexpr int kSecondAmountShortcut = 383;
constexpr UINT kShortcutModifiers = MOD_CONTROL | MOD_SHIFT | MOD_NOREPEAT;

// 子窗口复用可执行文件中的应用图标，异步设置以避免创建时重入。
void ApplyAppIcon(HWND window, WPARAM type, int width, int height) {
  const HICON icon = static_cast<HICON>(
      LoadImageW(GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON),
                 IMAGE_ICON, width, height, LR_SHARED));
  if (icon != nullptr) {
    PostMessageW(window, WM_SETICON, type, reinterpret_cast<LPARAM>(icon));
  }
}

const char* RuntimeEvent(UINT message, WPARAM detail) {
  switch (message) {
    case WM_TIMECHANGE:
    case WM_SETTINGCHANGE:
      return "clockChanged";
    case WM_POWERBROADCAST:
      if (detail == PBT_APMSUSPEND) return "sleep";
      if (detail == PBT_APMRESUMEAUTOMATIC || detail == PBT_APMRESUMESUSPEND) {
        return "wake";
      }
      break;
    case WM_WTSSESSION_CHANGE:
      if (detail == WTS_SESSION_LOCK) return "lock";
      if (detail == WTS_SESSION_UNLOCK) return "unlock";
      break;
  }
  return nullptr;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  RegisterPlugins(flutter_controller_->engine());
  runtime_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "shiyu/runtime",
          &flutter::StandardMethodCodec::GetInstance());
  runtime_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleDesktopMethod(call, std::move(result));
      });
  pack_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "shiyu/timerpack",
      &flutter::StandardMethodCodec::GetInstance());
  desktop_window_ = GetHandle();
  RegisterDesktopGeometry(flutter_controller_->engine()->messenger(), desktop_window_);
  fullscreen_ = IsExternalFullscreen();
  SetTimer(desktop_window_, kShiyuFullscreenTimer, 500, nullptr);
  if (WTSRegisterSessionNotification(GetHandle(), NOTIFY_FOR_THIS_SESSION)) {
    session_window_ = GetHandle();
  }
  // 子窗只注册窗口控制，托盘、快捷键与业务仍由主引擎负责。
  DesktopMultiWindowSetWindowCreatedCallback([](void* controller) {
    auto* view = static_cast<flutter::FlutterViewController*>(controller);
    WindowManagerPluginRegisterWithRegistrar(
        view->engine()->GetRegistrarForPlugin("WindowManagerPlugin"));
    FileSelectorWindowsRegisterWithRegistrar(
        view->engine()->GetRegistrarForPlugin("FileSelectorWindows"));
    ScreenRetrieverWindowsPluginCApiRegisterWithRegistrar(
        view->engine()->GetRegistrarForPlugin("ScreenRetrieverWindowsPluginCApi"));
    const HWND window = GetAncestor(view->view()->GetNativeWindow(), GA_ROOT);
    if (window != nullptr) {
      RegisterDesktopGeometry(view->engine()->messenger(), window);
      ApplyAppIcon(window, ICON_SMALL, GetSystemMetrics(SM_CXSMICON),
                   GetSystemMetrics(SM_CYSMICON));
      ApplyAppIcon(window, ICON_BIG, GetSystemMetrics(SM_CXICON),
                   GetSystemMetrics(SM_CYICON));
    }
  });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (desktop_window_ != nullptr) {
    SetVisibilityShortcut(false);
    SetAmountShortcut("");
    KillTimer(desktop_window_, kShiyuFullscreenTimer);
    desktop_window_ = nullptr;
  }
  if (session_window_ != nullptr) {
    WTSUnRegisterSessionNotification(session_window_);
    session_window_ = nullptr;
  }
  runtime_channel_.reset();
  pack_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

bool FlutterWindow::SetVisibilityShortcut(bool enabled) {
  if (enabled == visibility_shortcut_) return true;
  if (enabled && !RegisterHotKey(desktop_window_, kVisibilityShortcut, kShortcutModifiers, 'T')) {
    return false;
  }
  if (!enabled) UnregisterHotKey(desktop_window_, kVisibilityShortcut);
  visibility_shortcut_ = enabled;
  return true;
}

bool FlutterWindow::SetAmountShortcut(const std::string& letter) {
  if (letter == amount_letter_) return true;
  int candidate = 0;
  if (!letter.empty()) {
    if (letter.size() != 1 || letter[0] < 'A' || letter[0] > 'Z' || letter[0] == 'T') {
      return false;
    }
    candidate = amount_shortcut_ == kFirstAmountShortcut ? kSecondAmountShortcut : kFirstAmountShortcut;
    if (!RegisterHotKey(desktop_window_, candidate, kShortcutModifiers, letter[0])) {
      return false;
    }
  }
  if (amount_shortcut_ != 0) UnregisterHotKey(desktop_window_, amount_shortcut_);
  amount_shortcut_ = candidate;
  amount_letter_ = letter;
  return true;
}

void FlutterWindow::HandleDesktopMethod(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  if (method == "desktopFullscreen") {
    result->Success(flutter::EncodableValue(IsExternalFullscreen()));
  } else if (method == "startupSupported") {
    result->Success(flutter::EncodableValue(true));
  } else if (method == "startupEnabled") {
    result->Success(flutter::EncodableValue(StartupEnabled()));
  } else if (method == "startupSet" || method == "visibilityShortcut") {
    const bool* enabled = std::get_if<bool>(call.arguments());
    const bool applied = enabled != nullptr &&
        (method == "startupSet" ? SetStartupEnabled(*enabled) : SetVisibilityShortcut(*enabled));
    result->Success(flutter::EncodableValue(applied));
  } else if (method == "amountShortcut") {
    const auto* letter = std::get_if<std::string>(call.arguments());
    result->Success(flutter::EncodableValue(letter != nullptr && SetAmountShortcut(*letter)));
  } else {
    result->NotImplemented();
  }
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_COPYDATA && pack_channel_ && lparam != 0) {
    const auto* data = reinterpret_cast<const COPYDATASTRUCT*>(lparam);
    if (data->dwData == kShiyuPackMessage && data->lpData != nullptr &&
        data->cbData > 0 && data->cbData <= kShiyuPackPathLimit) {
      const std::string path(static_cast<const char*>(data->lpData), data->cbData);
      if (path.find('\0') != std::string::npos) return FALSE;
      pack_channel_->InvokeMethod("install", std::make_unique<flutter::EncodableValue>(path));
      return TRUE;
    }
  }
  if (runtime_channel_) {
    if (message == kShiyuReopen) {
      runtime_channel_->InvokeMethod("reopen", nullptr);
      return 0;
    }
    if (message == WM_TIMER && wparam == kShiyuFullscreenTimer) {
      const bool detected = IsExternalFullscreen();
      if (fullscreen_ != detected) {
        fullscreen_ = detected;
        runtime_channel_->InvokeMethod("fullscreen", std::make_unique<flutter::EncodableValue>(detected));
      }
      return 0;
    }
    if (message == WM_HOTKEY && wparam == kVisibilityShortcut) {
      runtime_channel_->InvokeMethod("toggleVisibility", nullptr);
      return 0;
    }
    if (message == WM_HOTKEY && amount_shortcut_ != 0 && wparam == static_cast<WPARAM>(amount_shortcut_)) {
      runtime_channel_->InvokeMethod("toggleAmount", nullptr);
      return 0;
    }
    const char* event = RuntimeEvent(message, wparam);
    if (event != nullptr) runtime_channel_->InvokeMethod(event, nullptr);
  }
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      if (flutter_controller_) flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
