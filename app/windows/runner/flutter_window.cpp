#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "desktop_multi_window/desktop_multi_window_plugin.h"
#include "resource.h"
#include "window_manager/window_manager_plugin.h"
#include "screen_retriever_windows/screen_retriever_windows_plugin_c_api.h"

namespace {

// 子窗口复用可执行文件中的应用图标，异步设置以避免创建时重入。
void ApplyAppIcon(HWND window, WPARAM type, int width, int height) {
  const HICON icon = static_cast<HICON>(
      LoadImageW(GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON),
                 IMAGE_ICON, width, height, LR_SHARED));
  if (icon != nullptr) {
    PostMessageW(window, WM_SETICON, type, reinterpret_cast<LPARAM>(icon));
  }
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
  // 子窗只注册窗口控制，托盘、快捷键与业务仍由主引擎负责。
  DesktopMultiWindowSetWindowCreatedCallback([](void* controller) {
    auto* view = static_cast<flutter::FlutterViewController*>(controller);
    WindowManagerPluginRegisterWithRegistrar(
        view->engine()->GetRegistrarForPlugin("WindowManagerPlugin"));
    ScreenRetrieverWindowsPluginCApiRegisterWithRegistrar(
        view->engine()->GetRegistrarForPlugin("ScreenRetrieverWindowsPluginCApi"));
    const HWND window = GetAncestor(view->view()->GetNativeWindow(), GA_ROOT);
    if (window != nullptr) {
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
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
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
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
