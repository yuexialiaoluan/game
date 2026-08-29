# Windows 构建说明

1. 安装 Godot 4.7.2 Export Templates：
   - Godot 编辑器菜单：Editor → Manage Export Templates → Download and Install（选择 4.7.2.stable）。
   - 或从 Godot 官方下载 `Godot_v4.7.2-stable_export_templates.tpz`，在编辑器导入。
2. 运行：`powershell -File tools/build_windows.ps1`
3. 输出：`builds/windows/TheBrave.exe` + `build_manifest.json`
