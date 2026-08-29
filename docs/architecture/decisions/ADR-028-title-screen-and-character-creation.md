# ADR-028：Title Screen 与 Character Creation

- 问题：如何建立正式开始界面与角色创建。
- 候选方案：各菜单硬编码跳转；统一 Menu Navigation + Service。
- 最终方案：MenuNavigator + MainMenuController + CharacterCreationService + Settings/Localization。
- 选择原因：复用服务，UI 不直接改 GameState。
- 优缺点：优点是清晰可扩展；缺点是 UI 仍为占位。
- 未来影响：正式 Title/Menu/角色创建/Settings 在此基础上完善。
