"""为既有 Runner 添加独立 Widget target；保留原工程和签名配置。"""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "app/ios/Runner.xcodeproj/project.pbxproj"


def identifier(name: str) -> str:
    return hashlib.sha1(f"shiyu.widgets.{name}".encode()).hexdigest()[:24].upper()


def main() -> None:
    text = PROJECT.read_text(encoding="utf-8")
    if identifier("target") in text:
        print("Widget target already configured.")
        return
    objects = []

    def add(name: str, body: str) -> str:
        key = identifier(name)
        objects.append(f"\t\t{key} = {{ {body} }};\n")
        return key

    def modify(key: str, transform) -> None:
        nonlocal text
        pattern = rf"(\t\t{key}[^\n]*= \{{)(.*?)(\n\t\t\}};)"
        match = re.search(pattern, text, re.S)
        if not match:
            raise ValueError(f"Missing Xcode object {key}")
        text = text[:match.start()] + match[1] + transform(match[2]) + match[3] + text[match.end():]

    def append_list(body: str, field: str, value: str) -> str:
        pattern = rf"({field} = \()(.*?)(\n\s*\);)"
        result, count = re.subn(pattern, lambda m: m[1] + m[2] + f"\n\t\t\t\t{value}," + m[3], body, count=1, flags=re.S)
        if count != 1:
            raise ValueError(f"Missing list {field}")
        return result

    source_refs = []

    def source(name: str, path: str, phase: str | None = None) -> str:
        reference = add(f"ref.{name}", f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{path}"; sourceTree = SOURCE_ROOT;')
        source_refs.append(reference)
        build = add(f"build.{name}", f"isa = PBXBuildFile; fileRef = {reference};")
        if phase:
            modify(phase, lambda body: append_list(body, "files", build))
        return build

    runner_sources = "97C146EA1CF9000F007C117D"
    source("bridge", "Runner/WidgetSettingsBridge.swift", runner_sources)
    shared_build = source("shared", "Shared/SharedWidgetStore.swift", runner_sources)
    shared_ref = identifier("ref.shared")
    widget_shared_build = add("build.widget.shared", f"isa = PBXBuildFile; fileRef = {shared_ref};")
    widget_build = source("widget", "ShiyuWidgets/RetirementWidget.swift")
    generated_build = source("generated", "../../native/ios/Generated/ShiyuCore.swift")
    group = add("group", 'isa = PBXGroup; name = "Shiyu Widgets"; sourceTree = "<group>"; children = (' + ",".join(source_refs) + ");")
    modify("97C146E51CF9000F007C117D", lambda body: append_list(body, "children", group))

    product = add("product", 'isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = ShiyuWidgets.appex; sourceTree = BUILT_PRODUCTS_DIR;')
    modify("97C146EF1CF9000F007C117D", lambda body: append_list(body, "children", product))
    sources = add("sources", f"isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({widget_build},{widget_shared_build},{generated_build},); runOnlyForDeploymentPostprocessing = 0;")
    frameworks = add("frameworks", "isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;")
    resources = add("resources", "isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;")
    script = json.dumps('bash "$SRCROOT/../../scripts/build_widget_core.sh"')
    build_rust = add("rust", f'isa = PBXShellScriptBuildPhase; alwaysOutOfDate = 1; buildActionMask = 2147483647; files = (); inputPaths = (); outputPaths = ("$(BUILT_PRODUCTS_DIR)/ShiyuWidgetCore/libshiyu_ffi.a",); name = "Build Widget Rust core"; shellPath = /bin/bash; shellScript = {script}; runOnlyForDeploymentPostprocessing = 0;')

    configurations = []
    for mode in ["Debug", "Release", "Profile"]:
        configurations.append(add(f"config.{mode}", f'''isa = XCBuildConfiguration; name = {mode}; buildSettings = {{
            APPLICATION_EXTENSION_API_ONLY = YES;
            CODE_SIGN_ENTITLEMENTS = ShiyuWidgets/ShiyuWidgets.entitlements;
            CODE_SIGN_STYLE = Automatic;
            CURRENT_PROJECT_VERSION = 1;
            GENERATE_INFOPLIST_FILE = YES;
            INFOPLIST_FILE = ShiyuWidgets/Info.plist;
            IPHONEOS_DEPLOYMENT_TARGET = 15.0;
            MARKETING_VERSION = 0.1.0;
            PRODUCT_BUNDLE_IDENTIFIER = com.growthrecord.shiyu.widgets;
            PRODUCT_NAME = "$(TARGET_NAME)";
            SDKROOT = iphoneos;
            SKIP_INSTALL = YES;
            SWIFT_VERSION = 5.0;
            TARGETED_DEVICE_FAMILY = "1,2";
            ENABLE_USER_SCRIPT_SANDBOXING = NO;
            LIBRARY_SEARCH_PATHS = ("$(inherited)","$(BUILT_PRODUCTS_DIR)/ShiyuWidgetCore",);
            OTHER_LDFLAGS = ("$(inherited)","-lshiyu_ffi",);
            SWIFT_INCLUDE_PATHS = "$(SRCROOT)/../../native/ios/Generated";
            OTHER_SWIFT_FLAGS = ("$(inherited)","-Xcc","-fmodule-map-file=$(SRCROOT)/../../native/ios/Generated/ShiyuCoreFFI.modulemap",);
            LD_RUNPATH_SEARCH_PATHS = ("$(inherited)","@executable_path/Frameworks","@executable_path/../../Frameworks",);
        }};'''))
    config_list = add("configs", "isa = XCConfigurationList; buildConfigurations = (" + ",".join(configurations) + "); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;")
    target = add("target", f'isa = PBXNativeTarget; buildConfigurationList = {config_list}; buildPhases = ({build_rust},{sources},{frameworks},{resources},); buildRules = (); dependencies = (); name = ShiyuWidgets; productName = ShiyuWidgets; productReference = {product}; productType = "com.apple.product-type.app-extension";')
    modify("97C146E61CF9000F007C117D", lambda body: append_list(body, "targets", target))

    proxy = add("proxy", f"isa = PBXContainerItemProxy; containerPortal = 97C146E61CF9000F007C117D; proxyType = 1; remoteGlobalIDString = {target}; remoteInfo = ShiyuWidgets;")
    dependency = add("dependency", f"isa = PBXTargetDependency; target = {target}; targetProxy = {proxy};")
    embed_build = add("embed.build", f"isa = PBXBuildFile; fileRef = {product}; settings = {{ ATTRIBUTES = (RemoveHeadersOnCopy,); }};")
    embed = add("embed", f'isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = ({embed_build},); name = "Embed App Extensions"; runOnlyForDeploymentPostprocessing = 0;')
    # 扩展先于 Flutter 的打包脚本嵌入，避免 Xcode 推导出循环依赖。
    modify("97C146ED1CF9000F007C117D", lambda body: append_list(body, "dependencies", dependency).replace("buildPhases = (", f"buildPhases = (\n\t\t\t\t{embed},", 1))
    for key in ["97C147061CF9000F007C117D", "97C147071CF9000F007C117D", "249021D4217E4FDB00AE95B9"]:
        modify(key, lambda body: body.replace("buildSettings = {", "buildSettings = {\n\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;", 1))
    marker = "\n\t};\n\trootObject"
    if marker not in text:
        raise ValueError("Missing root project terminator")
    text = text.replace(marker, "\n" + "".join(objects) + marker, 1)
    PROJECT.write_text(text, encoding="utf-8", newline="\n")
    print("Configured embedded ShiyuWidgets target and App Group entitlements.")


if __name__ == "__main__":
    main()
