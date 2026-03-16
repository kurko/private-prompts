# Squeaks Prototype Scaffolder

Scaffold a new lo-fi prototype project using the Squeaks starter kit (Vite + React 19 + Shadcn UI with a monochrome wireframe aesthetic).

## Process

### Step 1: Detect Context

Check if the current directory is already a Squeaks project:

```
# Look for Squeaks signature in CLAUDE.md or package.json
Grep: pattern="[Ss]queaks" in CLAUDE.md
Grep: pattern="squeaks" in package.json
```

If EITHER grep finds a match, this is already a Squeaks project — skip to Step 4.

### Step 2: Scaffold New Project

Ask the user two questions:

**Question 1: Project name**
- "What should the prototype be called? (this becomes the directory name)"
- Suggest a default based on any context the user has already provided

**Question 2: Location**
- "Where should I create it?"
- Options: "Current directory", "Home directory (~)", "Specify a path"
- Default to current directory

Then clone and reinitialize. If any command fails, report the error and stop — do NOT proceed with later steps.

**IMPORTANT:** The shell working directory resets between Bash tool calls. Use absolute paths (e.g., `<location>/<project-name>`) for all commands after cloning.

```bash
# Clone the starter kit (use absolute path for the target)
gh repo clone growthxai/squeaks <location>/<project-name>
```

```bash
# Remove upstream git history and reinitialize (use absolute path)
rm -rf <location>/<project-name>/.git
git -C <location>/<project-name> init
git -C <location>/<project-name> add -A
git -C <location>/<project-name> commit -m "Initial scaffold from growthxai/squeaks"
```

### Step 3: Install Dependencies

Check if `<location>/<project-name>/node_modules/` exists. If not:

```bash
npm --prefix <location>/<project-name> install
```

### Step 4: Start Dev Server

```bash
npm --prefix <location>/<project-name> run dev
```

Run this in the background so the user can keep working.

Read the project's CLAUDE.md and summarize its key conventions for the user. Then tell them the prototype is ready and the dev server is running.
