# cut-the-clutter

A Claude Code plugin that makes Claude write plainly. It ships a writing skill — cut clutter, use active verbs, drop qualifiers, run a revision pass — and a `UserPromptSubmit` hook that prints the skill on every message you send. Claude never has to decide whether the rules apply, because they are already in front of it.

## Install

```
/plugin marketplace add ahmedaabouzied/cut-the-clutter
/plugin install cut-the-clutter@cut-the-clutter
```

## Turn it off

Run `/plugin` and disable or uninstall `cut-the-clutter`. The hook stops with it.

## What it costs

The hook feeds the whole skill into the conversation on every message: 5,473 bytes, 896 words, or roughly 1,400 tokens per turn. In a long session that adds up, so keep it on for writing work and turn it off for the rest.

Inspired by William Zinsser's *On Writing Well*.
