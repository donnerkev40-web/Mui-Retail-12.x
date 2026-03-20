# MUI Architecture Roadmap

This roadmap keeps the long-term structure work visible inside the project.
The goal is to keep MUI easy to adapt, easy to maintain, and safer to update
against both Blizzard UI changes and external addon updates.

## Principles

- Keep runtime logic in `MUI_Core`.
- Keep installer and preset imports in `MUI_Setup`.
- Keep config menus in `MUI_Config`.
- Isolate all external addon integrations behind adapters.
- Separate migrations from active runtime logic.
- Keep one main responsibility per module or file group.

## Package 1: Universal System

Goal:
- Finish the split between chat window logic and universal window logic.

Target structure:
- `Modules/Chat/UniversalWindow.lua`
- `Modules/Chat/Universal/Providers.lua`
- `Modules/Chat/Universal/Common.lua`
- `Modules/Chat/Universal/WindowTypes.lua`
- `Modules/Chat/Universal/Adapters/*`

Desired end state:
- `ChatFrame.lua` does not know hard-coded provider details.
- Provider metadata, selection, active state, and watched addons are resolved
  through the provider registry.
- External content can be added by implementing a single adapter.

## Package 2: Chat Core Split

Goal:
- Reduce the size and responsibility of `Chat.lua` and `ChatFrame.lua`.

Target structure:
- `Modules/Chat/Chat.lua` for module bootstrap and shared orchestration only
- `Modules/Chat/WindowSlots.lua`
- `Modules/Chat/PrimaryChatBridge.lua`
- `Modules/Chat/SideIcons.lua`
- `Modules/Chat/BottomButtons.lua`
- `Modules/Chat/CellBridge.lua`
- `Modules/Chat/Migrations.lua`

Desired end state:
- Chat shell, side icons, bottom buttons, and layout migrations are isolated.

## Package 3: Hard DPS and Healer Separation

Goal:
- Make DPS and Healer true full MUI profiles instead of mixing one MUI
  profile with hidden internal layout state.

Target structure:
- `Engine/LayoutProfiles.lua`
- explicit layout-to-profile mapping such as `DPS -> MayronUI-DPS`
- external addon profile assignments remain in `db.global.layouts`

Desired end state:
- DPS and Healer no longer share the same internal MUI state.
- A layout switch means switching to a full MUI profile first, then switching
  assigned external addon profiles.
- Installer and config no longer depend on hidden `profile.layoutStates`
  snapshots.

Notes:
- This is a core architecture package and should happen before large new role
  features are added.

## Package 4: ActionBars Split

Goal:
- Separate Bartender compatibility from Blizzard suppression logic.

Target structure:
- `Modules/ActionBars/BartenderCompatibility.lua`
- `Modules/ActionBars/BlizzardSuppressor.lua`
- `Modules/ActionBars/MicroMenuReplacement.lua`

Desired end state:
- Ornament, micro menu, and compatibility issues are easier to diagnose.

## Package 5: Inventory Split

Goal:
- Break the inventory module into smaller controllers.

Target structure:
- `Modules/Inventory/AnchorController.lua`
- `Modules/Inventory/LayoutEngine.lua`
- `Modules/Inventory/Filters.lua`
- `Modules/Inventory/InternalTabs.lua`
- `Modules/Inventory/BagHooks.lua`
- `Modules/Inventory/SlotRenderer.lua`

Desired end state:
- Anchoring, lock behavior, tab buttons, filters, and slot layout can evolve
  independently.

## Package 6: Tooltip Hardening

Goal:
- Reduce tooltip taint risk and separate independent tooltip concerns.

Target structure:
- `Modules/ToolTips/Style.lua`
- `Modules/ToolTips/Anchors.lua`
- `Modules/ToolTips/StatusBars.lua`
- `Modules/ToolTips/Auras.lua`
- `Modules/ToolTips/InspectCache.lua`

Desired end state:
- Tooltip issues can be fixed without touching the entire tooltip module.

## Package 7: Setup and Config Cleanup

Goal:
- Keep installer, config, and runtime responsibilities cleanly separated.

Target structure:
- `MUI_Setup/LayoutDefaults.lua`
- `MUI_Setup/ProfilePipeline.lua`
- `MUI_Setup/Validation.lua`
- `MUI_Config/Modules/*` kept UI-only

Desired end state:
- The installer only applies defaults and imports.
- Runtime behavior stays in `MUI_Core`.
- Config pages do not carry feature logic.

## Current Priority Order

1. Universal system
2. Chat core split
3. Hard DPS and Healer separation
4. ActionBars split
5. Inventory split
6. Tooltip hardening
7. Setup and config cleanup

## Delivery Rules

- Each package should land in small safe steps.
- Each step should reduce coupling, not just move code around.
- Any external addon support must remain source-independent whenever possible.

## Current Progress

- Engine architecture spine:
  - `Engine/FeatureRegistry.lua`
  - `Engine/FeatureState.lua`
  - `Engine/ModuleRegistry.lua`
  - `Engine/ModuleLifecycle.lua`
  - `Engine/LayoutManager.lua`
- Feature gating:
  - module initialization now respects feature-path toggles
  - universal provider availability now respects provider feature flags
  - action bar compatibility and Blizzard suppression can be disabled separately
- Package 1 foundation:
  - `Universal/Providers.lua` is now the stronger central source for provider
    metadata and active-state helpers.
  - `Chat/Universal/Module.lua`
  - `Chat/Universal/ProviderRegistry.lua`
  - `Chat/Universal/VisibilityController.lua`
  - `Chat/Universal/HostController.lua`
- Package 2 foundation:
  - `Chat/Module.lua`
  - `Chat/WindowRegistry.lua`
  - `Chat/WindowShell.lua`
  - `Chat/WindowLayout.lua`
  - `Chat/Migrations.lua`
  - `Chat/SideIcons.lua`
- Package 3 foundation:
  - `Engine/LayoutProfiles.lua`
  - `Engine/LayoutManager.lua`
- Package 4 foundation:
  - `ActionBars/Module.lua`
  - `ActionBars/FeatureFlags.lua`
  - `ActionBars/BlizzardSuppressor.lua`
  - `ActionBars/BartenderCompatibility.lua`
- Package 5 foundation:
  - `Inventory/AnchorController.lua`
- Package 6 foundation:
  - `Tooltips/Style.lua`
  - `Tooltips/Anchors.lua`
- Package 7 foundation:
  - `MUI_Setup/LayoutDefaults.lua`
  - `MUI_Setup/InstallerPipeline.lua`
  - `MUI_Setup/ProfileTemplates.lua`
  - `MUI_Setup/Validation.lua`

## Current Delivery Model

The structure work is landing in a compatibility-first way:

- new subsystem files are added as facades and metadata entry points first
- feature flags are wired before deep code moves
- existing large runtime files continue to work while responsibility is peeled
  away from them in smaller follow-up steps
