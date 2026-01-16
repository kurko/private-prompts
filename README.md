# Private Prompts

Private Claude commands, skills, and agents that merge with public dotfiles.

## Setup

```bash
git clone git@github.com:kurko/private-prompts.git ~/.private-prompts
cd ~/.private-prompts
./install.sh
update_dotfiles
```

## Structure

```
~/.private-prompts/
  commands/   # Private Claude commands
  skills/     # Private Claude skills
  agents/     # Private Claude agents
```

## How it works

The `update_dotfiles` function in `~/.dotfiles/bashrc_source` symlinks both public
(from `~/.dotfiles/ai/`) and private (from `~/.private-prompts/`) prompts into
`~/.claude/commands/`, `~/.claude/skills/`, and `~/.claude/agents/`.

Private prompts take precedence if there are naming conflicts.
