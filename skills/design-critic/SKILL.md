---
name: design-critic
description: Get an outside critique of a visual design from screenshots and iterate on it. Use after building or restyling a page or component, and when the user says "critique this design", "how does it look", "design feedback", "it looks off". Not for code review.
---

# Design critic

The agent that built a design defends its own decisions and judges the code it wrote, not what a user sees. A critic in a fresh context that sees only screenshots judges the result. Using the same critic prompt every round keeps scores comparable between rounds.

## Loop

1. **Screenshot.** Capture the design at the widths it will be used at, usually 1440px and 390px, full page. Use whatever browser or screenshot tool is available. Save the files in a new temporary folder (for example from `mktemp -d`) with neutral names such as `1440.png` and `390.png`, since a path with the project name in it tells the critic what the design is for.

2. **Start the critic.** Start a fresh subagent on the strongest model available, since the critic needs better judgment than the builder. Its prompt is the full text of [CRITIC.md](CRITIC.md) followed by the screenshot paths. Give it nothing else:
   - No code, file names or brief. The critic works out the intended aesthetic from the pixels, as a user would.
   - No earlier critiques. They anchor the next one.
   - No target score. A known target pulls the score toward it.

   Reference images (a moodboard) may go with the screenshots, labelled as references, not as targets to copy.

   If the tool can't start subagents, tell the user. Critiquing your own work in the same context defeats the method.

3. **Stop or apply.** Stop if the score is 9 or more, or this was the third critique; its gaps become the gaps left open. Otherwise fix the gaps and make the removals, most important first. If a gap conflicts with something the user asked for, keep the user's requirement and note the conflict.

4. **Repeat.** New screenshots, a new subagent, the same CRITIC.md, unchanged.

5. **Report.** The last critique's score, rounds run, and the gaps left open with the reason for each. Stopping before applying the last critique's fixes means the reported score describes the design as delivered.

## Comparing designs

To choose between several designs, send all their screenshots in one critic call. CRITIC.md asks for a ranking first, and a ranking across designs is more reliable than one design's score on its own.

## Limits

Screenshots don't show motion, hover, focus or interaction. Check those separately.
