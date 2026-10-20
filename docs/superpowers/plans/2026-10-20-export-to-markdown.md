# Export Cheatsheet to Markdown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to export the active cheatsheet to Markdown with options to save to `~/Documents/KeyHUD/` or copy directly to clipboard.

**Architecture:** Create `MarkdownExporter` generating GitHub-flavored Markdown tables. Add an export action menu in the HUD header (`square.and.arrow.up`).

**Tech Stack:** Swift 6, AppKit, SwiftUI.

**Spec:** `docs/superpowers/specs/2026-10-20-export-to-markdown-design.md`

## Global Constraints
- Standalone `swiftc` compilation via `/Users/ablack/.config/keyhud/build.sh`.
- Stable code signing with designated requirement.
- No `@State` compiler macros.

## Review Focus
1. Markdown table formatting is valid GitHub-flavored Markdown.
2. Saving to file creates directory `~/Documents/KeyHUD/` if missing and opens/reveals the `.md` file in Finder.
3. Copying to clipboard populates `NSPasteboard.general` cleanly.
4. Export icon is clean and fits nicely in the header toolbar.

---

### Task 1: Markdown Generator Engine & Test

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Test: `/tmp/test_markdown_exporter.swift`

**Interfaces:**
- Produces: `MarkdownExporter.generateMarkdown(title:groups:) -> String`
- Produces: `MarkdownExporter.saveToFile(title:markdown:) -> URL?`
- Produces: `MarkdownExporter.copyToClipboard(markdown:)`

- [ ] **Step 1: Write standalone test script `/tmp/test_markdown_exporter.swift`**
Validate table generation with multiple categories and special key characters.

- [ ] **Step 2: Run test script**
Run: `swift /tmp/test_markdown_exporter.swift`

- [ ] **Step 3: Implement `MarkdownExporter` in `KeyHUD.swift`**
Add `struct MarkdownExporter` with table formatting, file saving, and clipboard copying.

- [ ] **Step 4: Verify build with `build.sh`**
Run: `/Users/ablack/.config/keyhud/build.sh`

- [ ] **Step 5: Commit**
```bash
git add KeyHUD.swift
git commit -m "feat: implement MarkdownExporter engine"
```

---

### Task 2: Header Export Menu & Update TODO.md

**Files:**
- Modify: `/Users/ablack/.config/keyhud/KeyHUD.swift`
- Modify: `/Users/ablack/.config/keyhud/TODO.md`

- [ ] **Step 1: Add Export Button to HUD Header**
Add `Menu` button with `square.and.arrow.up` in the top-right toolbar offering:
- `Copy Markdown to Clipboard`
- `Save to Documents (~/Documents/KeyHUD/)`

- [ ] **Step 2: Update `TODO.md`**
Mark "Export to Markdown" as completed.

- [ ] **Step 3: Build, sign, and install `/Applications/KeyHUD.app`**
Run `/Users/ablack/.config/keyhud/build.sh` and relaunch.

- [ ] **Step 4: Commit**
```bash
git add KeyHUD.swift TODO.md docs/
git commit -m "feat: complete export to markdown feature"
```
