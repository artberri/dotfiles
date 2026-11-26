# typescript7-lsp

Runs TypeScript 7's own language server, `tsc --lsp --stdio` (the global `tsc` on PATH), for Claude Code's LSP tool.

The official `typescript-lsp@claude-plugins-official` runs `typescript-language-server`, which needs `tsserver.js`.
TypeScript 7 doesn't ship it, so the official plugin fails to start ("provides no tsserver.js" / "Could not find a valid
TypeScript installation"). `claude/settings.json` turns the official plugin off: while both are on, Claude Code sends
TypeScript files to the official one and the LSP tool fails.

`claude/links` links this folder into the `skills` folder of both config folders. Claude Code loads a plugin it finds
there as `typescript7-lsp@skills-dir`, enabled, with no install step.

Navigation, references, hover, symbols and call hierarchy work. Diagnostics don't yet: TypeScript 7's server only
answers pull diagnostics and Claude Code only takes pushed ones. Without a global TypeScript 7 `tsc`, the server fails
to start, as the official one did without `typescript-language-server`.

Remove it once https://github.com/anthropics/claude-plugins-official/issues/4492 is fixed: delete this folder, its two
lines in `claude/links` and the `~/.claude/skills/typescript7-lsp` and `~/.claude-personal/skills/typescript7-lsp`
links, then set `typescript-lsp@claude-plugins-official` back to `true` in `claude/settings.json` and run
`./install claude`. Diagnostics come back with no change here once https://github.com/microsoft/TypeScript/pull/63921
ships in a TypeScript release, or Claude Code supports pull diagnostics
(https://github.com/anthropics/claude-code/issues/40282).
