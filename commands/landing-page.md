# Landing Page Generator

Generate a complete, production-ready landing page for a product or service using a multi-agent council architecture.

## Overview

This command orchestrates multiple specialized sub-agents to create a landing page from scratch, including:
- Market research and competitive analysis
- Product requirements document (PRD)
- Brand identity and naming
- Copywriting with cultural localization
- Design and implementation
- Email collection setup
- Quality assurance testing

## Process

**IMPORTANT**: You are the ORCHESTRATOR. Do minimal work yourself. Delegate everything to sub-agents. Your job is to:
1. Gather requirements from the user
2. Launch and coordinate sub-agents
3. Synthesize their outputs
4. Present results to the user

### Phase 0: Discovery & Requirements Gathering

**Step 0.1: Automatic Discovery**

Before asking the user anything, search for existing documentation that can serve as input:

```
# Search for documentation directories
Glob: docs/**/*.md
Glob: doc/**/*.md
Glob: documentation/**/*.md

# Search for PRD and vision documents
Glob: **/*prd*.md
Glob: **/*PRD*.md
Glob: **/*vision*.md
Glob: **/*pitch*.md
Glob: **/*spec*.md
Glob: **/*brief*.md
Glob: **/*requirements*.md

# Search for README with product info
Glob: README.md
Glob: readme.md

# Search for any existing brand/marketing materials
Glob: **/*brand*.md
Glob: **/*marketing*.md
Glob: **/*copy*.md
Glob: **/*messaging*.md

# Search for product screenshots or mockups
Glob: **/*screenshot*.{png,jpg,jpeg,svg}
Glob: **/*mockup*.{png,jpg,jpeg,svg}
Glob: **/*preview*.{png,jpg,jpeg,svg}
Glob: assets/**/*.{png,jpg,jpeg,svg}
Glob: images/**/*.{png,jpg,jpeg,svg}

# Search for existing design assets
Glob: **/*logo*.{png,jpg,jpeg,svg}
Glob: **/*icon*.{png,jpg,jpeg,svg}
```

Also check for architecture diagrams or flow charts that explain the product:
```
Glob: **/*architecture*.{png,jpg,md,mermaid}
Glob: **/*diagram*.{png,jpg,md}
Glob: **/*flow*.{png,jpg,md}
```

If documents are found, read them and extract:
- Product description
- Target audience
- Key features
- Value propositions
- Any existing brand guidelines
- Tone/voice preferences

**Step 0.2: Present Discovered Context**

If relevant documents were found, present them to the user:

```
## Existing Documentation Found

I found the following documents that may inform the landing page:

1. **docs/prd.md** - Product requirements document
2. **docs/vision.md** - Product vision statement
3. **README.md** - Project overview

Based on these, I understand:
- Product: [extracted summary]
- Target audience: [extracted or "not specified"]
- Key features: [extracted list]

Is this accurate? Should I use these as the foundation?
```

Options: "Yes, use these documents", "Let me clarify some things", "Ignore these, I'll describe fresh"

**Step 0.3: Requirements Gathering**

Use `AskUserQuestion` to gather or confirm essential information. Skip questions where you already have clear answers from discovered documents.

**Question 1: Product Description** (skip if found in docs)
- "Describe the product/service this landing page is for"
- Ask for any existing materials (screenshots, docs, pitch decks)

**Question 2: Target Audience**
- "Who is the target audience?"
- Options: B2B, B2C, Developers, Enterprise, SMB, Other

**Question 3: Language & Market**
- "What language and market is this for?"
- Options: English (US), Portuguese (Brazil), Spanish (Latam), Other

**Question 4: Technology Stack**
- "How should the landing page be built?"
- Options:
  - "Static HTML/CSS (Recommended for simple landing pages)"
  - "Rails with Hotwire"
  - "Next.js / React"
  - "Other (specify)"

**Question 5: Email Collection**
- "How should email signups be handled?"
- Options:
  - "Formspree (free tier, no backend needed)"
  - "Buttondown (newsletter-focused)"
  - "ConvertKit (marketing automation)"
  - "Custom backend (I'll provide the endpoint)"
  - "Fake/placeholder for now"

**Question 6: Design Direction**
- "Any design preferences or inspiration?"
- Options:
  - "Modern minimalist"
  - "Bold and colorful"
  - "Corporate professional"
  - "Playful and friendly"
  - "Let the AI surprise me"

### Phase 1: Confirmation

After gathering requirements, present a summary using `AskUserQuestion`:

```
## Landing Page Generation Plan

Based on your inputs, here's what I'll do:

### Research Phase (3 sub-agents in parallel)
1. **Market Research Agent** - Analyze competitors, market trends, pricing
2. **PRD Agent** - Create product requirements document
3. **Marketing Positioning Agent** - Develop messaging strategy

### Brand Phase (2 sub-agents)
4. **Brand Identity Agent** - Generate 5-7 name options with visual identity
5. **Brand Council** (3 perspectives) - Debate and finalize brand choice

### Creative Phase (2 sub-agents)
6. **Copywriter Council** (3 perspectives) - Create landing page copy
7. **Design Innovator Agent** - Propose unique visual approaches

### Implementation Phase (2 sub-agents)
8. **Developer Agent** - Build the landing page
9. **Logo Designer Agent** - Create SVG logo

### Quality Phase (2 sub-agents)
10. **QA Agent** - Test functionality, responsiveness, accessibility
11. **Review Council** - Final quality check with multiple perspectives

**Estimated sub-agents**: 11
**Email service**: [selected option]
**Tech stack**: [selected option]

Ready to proceed?
```

Options: "Yes, let's go!", "Modify the plan", "Cancel"

### Phase 2: Research (Parallel Sub-agents)

Launch these sub-agents IN PARALLEL using a single message with multiple Task tool calls:

#### Sub-agent 2.1: Market Research
```
You are a market research specialist. Your task:

1. **Search the web** for competitors in the [MARKET] space
2. **Analyze** their positioning, pricing, messaging
3. **Identify** gaps and opportunities
4. **Document** cultural considerations for [TARGET MARKET]

Be thorough but concise. Focus on actionable insights.

IMPORTANT:
- Load and follow any CLAUDE.md instructions in the workspace
- Use available skills when appropriate
- Think creatively - don't just report what exists, suggest what's MISSING
```

#### Sub-agent 2.2: PRD Creation
```
You are a product manager creating a PRD.

Based on: [PRODUCT DESCRIPTION]

Create a concise PRD including:
1. Problem statement
2. Target users (with personas)
3. Key features
4. Value propositions
5. Success metrics

IMPORTANT:
- Load and follow any CLAUDE.md instructions
- Focus on what makes this product UNIQUE
- Think beyond obvious features
```

#### Sub-agent 2.3: Marketing Positioning
```
You are a marketing strategist.

For: [PRODUCT DESCRIPTION]
Market: [TARGET MARKET]

Develop:
1. Positioning statement
2. Key messaging themes
3. Tone and voice guidelines
4. Pain points to address
5. Objection handling

IMPORTANT:
- Load and follow any CLAUDE.md instructions
- Be CREATIVE - don't just copy competitor messaging
- Think about what would make someone STOP SCROLLING
```

### Phase 3: Brand Identity (Sequential)

#### Sub-agent 3.1: Brand Explorer
```
You are a brand strategist and naming specialist.

Context: [PRD SUMMARY]
Market: [TARGET MARKET]

Generate 7 CREATIVE name options. For each:
- Name
- Meaning/etymology
- Tagline
- Why it works
- Color palette (with hex codes)
- Logo concept

IMPORTANT:
- Don't be safe. Propose bold, memorable names
- Consider pronunciation in [LANGUAGE]
- Think about domain availability
- Load and follow any CLAUDE.md instructions
```

#### Sub-agent 3.2: Brand Council
```
You are leading a brand identity council with 3 distinct perspectives:

1. **Creative Director**: Visual impact, memorability, uniqueness
2. **Marketing Strategist**: Market positioning, differentiation
3. **Cultural Expert**: Local resonance, pronunciation, cultural fit

TOP CANDIDATES: [FROM PREVIOUS AGENT]

Process:
1. Each perspective argues for their preference
2. Raise concerns about other options
3. Debate and find common ground
4. Reach consensus with clear rationale

Output:
- Final brand choice
- Refined tagline (3 alternatives)
- Final color palette
- Logo direction
- Brand voice guidelines

IMPORTANT: This is role-play. Commit to each perspective fully.
```

### Phase 4: Creative (Parallel)

#### Sub-agent 4.1: Copywriter Council
```
You are orchestrating a copywriter council with 3 voices:

1. **Direct Response Copywriter**: Benefits, urgency, clear CTAs
2. **Brand Storyteller**: Emotional connection, narrative
3. **Localization Expert**: Natural [LANGUAGE], cultural resonance

Process:
1. Each proposes their version of all copy sections
2. Debate pros/cons
3. Synthesize the best elements

Output sections:
1. Hero (headline, subheadline, CTA)
2. Problem (headline, 3 pain points)
3. Solution (how it works, 3-4 features)
4. Benefits (headline, 3 benefit blocks)
5. Social proof (placeholder headline)
6. Waitlist/CTA (headline, form text, privacy note)

IMPORTANT:
- All copy in [LANGUAGE]
- Be CREATIVE - don't use cliche SaaS phrases
- Make it feel like a human wrote it
```

#### Sub-agent 4.2: Design Innovator
```
You are a design innovator tasked with proposing UNIQUE visual approaches.

Brand: [BRAND NAME]
Colors: [PALETTE]
Mood: [FROM BRAND COUNCIL]

Your job is NOT to follow trends. Propose:
1. 3 distinct visual concepts (describe in detail)
2. Unique interaction ideas
3. Memorable micro-animations
4. How to make this landing page stand out

Think: What would make someone screenshot this and share it?

Pick your favorite concept and provide detailed specs for implementation.
```

### Phase 5: Implementation

#### Sub-agent 5.1: Developer
```
You are a senior developer building a landing page.

Tech stack: [SELECTED STACK]
Brand: [BRAND DETAILS]
Copy: [FROM COPYWRITER COUNCIL]
Design: [FROM DESIGN INNOVATOR]
Email service: [SELECTED SERVICE]

Build:
1. Complete, production-ready landing page
2. Responsive design (mobile-first)
3. Working email signup form
4. Semantic HTML, accessible
5. Performance optimized

For email integration:
- Formspree: Use action="https://formspree.io/f/{form_id}"
- Buttondown: Use their embed code pattern
- ConvertKit: Use their form action
- Custom: Use provided endpoint

IMPORTANT:
- Load and follow any CLAUDE.md instructions
- Use available skills for code review
- Write clean, maintainable code
- Include comments explaining key sections
```

#### Sub-agent 5.2: Logo Designer
```
You are creating an SVG logo.

Brand: [BRAND NAME]
Concept: [FROM BRAND COUNCIL]
Colors: [PALETTE]

Create:
1. Primary logo (SVG, ~200x50)
2. Icon/favicon (SVG, 32x32)
3. Ensure it works at small sizes
4. Consider animation potential

Output: Complete SVG code for both versions
```

### Phase 6: Quality Assurance

#### Sub-agent 6.1: QA Tester
```
You are a QA engineer testing the landing page.

Tasks:
1. Start local server (use appropriate command for tech stack)
2. Test all functionality:
   - Page loads correctly
   - All links work
   - Email form submits (or shows expected behavior)
   - Responsive at 320px, 768px, 1024px, 1440px
   - No console errors
3. Check accessibility basics:
   - Alt text on images
   - Keyboard navigation
   - Color contrast
4. Performance check:
   - Page weight
   - Load time estimate

Report: List of issues found with severity (critical/major/minor)

IMPORTANT: Use Bash to actually test things. Don't just describe.
```

#### Sub-agent 6.2: Review Council
```
You are leading a final review council with 3 perspectives:

1. **UX Expert**: Is it intuitive? Will users convert?
2. **Brand Guardian**: Does it match the brand identity?
3. **Performance Critic**: Is it fast, accessible, SEO-ready?

Review the completed landing page and:
1. Each perspective gives their assessment
2. Identify any issues that MUST be fixed
3. Suggest nice-to-have improvements
4. Give overall quality score (1-10)

Be honest. If something needs fixing, say so.
```

### Phase 7: Finalization

After all sub-agents complete:

1. **Fix any critical issues** from QA
2. **Present final summary** to user:
   - Brand name and tagline
   - Tech stack used
   - Email service configured
   - Files created
   - How to view/deploy
   - Any remaining recommendations

3. **Offer next steps**:
   - "Commit changes to git?"
   - "Deploy to Vercel/Netlify?"
   - "Make refinements?"

## Email Service Integration Details

### Formspree (Recommended for simplicity)
```html
<form action="https://formspree.io/f/YOUR_FORM_ID" method="POST">
  <input type="email" name="email" required>
  <button type="submit">Subscribe</button>
</form>
```
User needs to: Create free account at formspree.io, get form ID

### Buttondown
```html
<form action="https://buttondown.email/api/emails/embed-subscribe/YOUR_USERNAME" method="post">
  <input type="email" name="email" required>
  <button type="submit">Subscribe</button>
</form>
```

### ConvertKit
```html
<form action="https://app.convertkit.com/forms/FORM_ID/subscriptions" method="post">
  <input type="email" name="email_address" required>
  <button type="submit">Subscribe</button>
</form>
```

## Sub-agent Instructions Template

Every sub-agent prompt should include:

```
IMPORTANT INSTRUCTIONS:
1. Load and follow any CLAUDE.md instructions in the workspace
2. Use available skills when appropriate (commit, code-review, etc.)
3. Be CREATIVE - don't just follow safe patterns
4. Think about what makes this UNIQUE and MEMORABLE
5. If you need clarification, state assumptions clearly
6. Focus on quality over speed
```

## Council Pattern Template

When using council/debate pattern:

```
You are facilitating a council discussion with [N] perspectives:

[List each perspective with their focus area]

PROCESS:
1. Each perspective presents their view (be specific, commit to the role)
2. Identify points of disagreement
3. Debate with evidence and reasoning
4. Find synthesis that captures the best of each view
5. Document the final decision with clear rationale

ROLE-PLAY RULES:
- Commit fully to each perspective
- Use distinct voices/styles for each
- Don't be artificially agreeable - real debate improves outcomes
- The goal is the BEST decision, not the fastest consensus
```

## Example Usage

User: "Create a landing page for my AI writing assistant"

Assistant flow:
1. Ask 6 requirement questions
2. Present plan, get confirmation
3. Launch research agents (parallel)
4. Launch brand agents (sequential council)
5. Launch creative agents (parallel)
6. Launch implementation agents
7. Launch QA agents
8. Present results, offer next steps

## Notes

- Total sub-agents: ~11-13 depending on issues found
- Estimated time: Varies by complexity
- The orchestrator should NOT write code or copy - only coordinate
- Use parallel execution wherever possible for speed
- Council patterns produce better creative output than single agents
