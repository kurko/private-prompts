# Private Prompts

Private Claude Code commands, skills, and agents that supplement public dotfiles.

This repository stores Claude Code prompts that you don't want in your public dotfiles - proprietary workflows, client-specific commands, or personal productivity hacks.

## Quick Install

```bash
git clone git@github.com:kurko/private-prompts.git ~/.private-prompts
~/.private-prompts/install.sh
```

## Copy-Paste Prompt for Claude Code

Run this on a new machine where Claude Code is already installed:

```
Clone my private prompts repository and install it:

1. Clone git@github.com:kurko/private-prompts.git to ~/.private-prompts
2. Run the install.sh script
3. Verify the symlinks were created in ~/.claude/commands, ~/.claude/skills, and ~/.claude/agents

This installs my private Claude Code commands and skills that supplement my public dotfiles.
```

## How It Works

### Directory Structure

```
~/.private-prompts/
  commands/     # Slash commands (e.g., /landing-page)
  skills/       # Auto-triggered skills
  agents/       # Custom agents
  install.sh    # Creates symlinks to ~/.claude/
```

### Installation Flow

1. `install.sh` creates symlinks from `~/.private-prompts/{commands,skills,agents}/*` to `~/.claude/{commands,skills,agents}/`
2. Claude Code reads prompts from `~/.claude/` directories
3. Private prompts override public ones if there are naming conflicts

### Integration with Dotfiles

If you also use public dotfiles with Claude prompts (e.g., `~/.dotfiles/ai/`), run `update_dotfiles` after installing to merge both:

```bash
~/.private-prompts/install.sh   # Install private prompts
update_dotfiles                  # Merge public dotfiles (if you have them)
```

The symlink order ensures private prompts take precedence over public ones with the same name.

## Adding New Prompts

### Commands (User-Invoked)

Create a markdown file in `commands/`:

```bash
# Example: commands/my-workflow.md
```

Invoke with `/my-workflow` in Claude Code.

### Skills (Auto-Triggered)

Create a directory in `skills/` with instruction and activation files:

```bash
skills/my-skill/
  instruction.md    # What the skill does
  activation.txt    # When to trigger (keywords/patterns)
```

### Agents

Create a markdown file in `agents/` for custom agent definitions.

## Current Contents

**Commands:**
- `landing-page` - Multi-agent landing page generator with research, branding, and implementation phases

**Skills:** (none yet)

**Agents:** (none yet)

## Maintenance

After adding new prompts, re-run the install script to create symlinks:

```bash
~/.private-prompts/install.sh
```

Or commit and push, then clone fresh on other machines.
