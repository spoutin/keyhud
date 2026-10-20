# Design Specification: Dynamic Shrink-to-Fit Window Sizing with Configurable Ceiling

## 1. Intent & Purpose
In KeyHUD, users can configure screen percentage sliders for width (e.g. 80%) and height (e.g. 70%). Currently, the window is always statically sized to that exact percentage box, even when viewing an application or sub-tool with only a few shortcuts (e.g., an app with 1 column and 5 shortcuts), leading to large areas of empty dead space.

This feature reinterprets the configured size settings as the **maximum ceiling** for the HUD window:
- If the shortcuts content requires less space than the ceiling, the window dynamically **shrinks to fit** the content.
- If the content requires more space than the ceiling, the window expands up to the ceiling, with scrollability for the remaining content.
- A **minimum size floor** (520 × 360 pt) ensures the header, search bar, and modifiers legend bar always remain perfectly laid out and readable.
- The window smoothly centers itself on screen based on the computed fitted dimensions.

---

## 2. Geometry & Size Calculation

### 2.1 Constants & Dimensions
- Minimum Window Width (`minWidth`): `520 pt`
- Minimum Window Height (`minHeight`): `360 pt`
- Header Height (drag header, breadcrumbs, search bar): `~62 pt`
- Bottom Bar Height (legend bar, scope toggle, item count): `~48 pt`
- Padding & Insets: `~40 pt` vertical chrome
- Estimated Column Width: `~260 pt` (including horizontal spacing)
- Row Height per Shortcut Item: `~34 pt`
- Category Header Height per Group: `~28 pt`

### 2.2 Content Size Estimation
For a given list of `[ShortcutGroup]` to display:
1. **Columns**: Number of columns = `max(1, min(groups.count, 6))`
2. **Width**:
   - `contentWidth = Double(columns) * 260.0 + 40.0`
   - `fittedWidth = max(minWidth, min(maxAllowedWidth, contentWidth))`
3. **Height**:
   - For each column, height = sum of (28 pt header + items.count * 34 pt).
   - `maxColumnHeight = groups.map { 28.0 + Double($0.items.count) * 34.0 }.max() ?? 0.0`
   - `contentHeight = maxColumnHeight + 110.0` (chrome: header + bottom legend)
   - `fittedHeight = max(minHeight, min(maxAllowedHeight, contentHeight))`

### 2.3 Centering & Placement
When the window is resized to `(fittedWidth, fittedHeight)`, center it on the active screen:
```swift
let originX = visible.origin.x + (visible.width - fittedWidth) / 2.0
let originY = visible.origin.y + (visible.height - fittedHeight) / 2.0
window.setFrame(NSRect(x: originX, y: originY, width: fittedWidth, height: fittedHeight), display: true, animate: false)
```

---

## 3. Dynamic Scope Transitions
When the user switches scopes (e.g. from `Ghostty (Main)` to a sub-tool like `K9s` or a smaller app), or filters with search queries, the window can update its fitted size dynamically or adapt to the active scope's group structure.
