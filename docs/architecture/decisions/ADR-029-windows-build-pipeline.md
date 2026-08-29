# ADR-029：Windows Build Pipeline

- 问题：如何建立可重复 Windows 导出。
- 候选方案：手动导出；脚本化导出 + 校验 + Manifest。
- 最终方案：tools/build_windows.ps1 + Export Preset + build_manifest.json + Release zip。
- 选择原因：可重复、失败可检测、不覆盖成功构建。
- 优缺点：优点是稳定；缺点是需要 export templates。
- 未来影响：CI/发布流程基于此。
