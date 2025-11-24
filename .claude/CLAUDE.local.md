═══════════════════════════════════════════════════════════════
🚫 CRITICAL BLOCKING REQUIREMENT - READ FIRST 🚫
═══════════════════════════════════════════════════════════════

<!-- juggler-instructions-start -->

## MANDATORY JUGGLER CHECK - YOU ARE BLOCKED UNTIL COMPLETE

**STOP.** You MUST run this command BEFORE ANY other action:

1. Run: `juggle` (shows currently juggling balls)
2. IF ready/juggling balls exist:
   - You are **BLOCKED** from other work
     - You **MUST** address existing balls FIRST
     3. ONLY after handling existing balls may you proceed with new work

     **VIOLATION CONSEQUENCES:**
     - Creating balls while others are ready = **CRITICAL ERROR**
     - Skipping this check = **INVALID SESSION**
     - You will be asked to restart if you violate this

     ═══════════════════════════════════════════════════════════════

     ## Juggler Workflow - MANDATORY STEPS

     ### 🔴 Step 1: ALWAYS Check State First

     **STOP.** Before doing ANY research, code investigation, or planning:

     ```bash
     juggle  # Shows currently juggling balls
     ```

     **YOU ARE BLOCKED from proceeding until you run this command.**

     If you see ANY ready or juggling balls, you **MUST** handle them before starting new work.

     ### 🟡 Step 2: Handle Existing Tasks

     **IF balls exist** - You **MUST** determine if current task matches existing ball.

     A ball matches the current task if **ANY** of these are true:
     1. **Intent/description overlap** - The ball describes the same or related goal
        - Example: Ball "Fix zellij integration" matches task "fix juggle command showing error"
        2. **Same component/file** - Working on the same area of code
           - Example: Ball has todos about `root.go` matches task involving `root.go`
           3. **Related tags** - Ball has tags matching the task domain
              - Example: Ball tagged "cli" matches any command-line behavior task
              4. **Same working directory** - For multi-project setups

              **When in doubt:** Ask the user "I see ball X is about Y. Should I use this or create a new ball?"

              **CHECKPOINT:** Have you confirmed match/no-match with existing balls?

              **If match found - USE EXISTING BALL:**

              ```bash
              juggle <ball-id>              # Review details and todos
              juggle <ball-id> in-air       # Mark as actively working
              ```

              **If no match - CREATE NEW BALL:**

              ```bash
              juggle start  # Interactive creation (recommended)
              # OR
              juggle plan --intent "..." --priority medium  # Non-interactive
              ```

              **IMPORTANT:** When creating a new ball, **always provide a description** for future context:
              - Descriptions help you and other agents understand the ball's purpose later
              - Include **why** this task matters, not just what it is
              - Add relevant technical context or constraints
              - Format: "What this task is about and why it matters"
              - The `start` and `plan` commands will prompt you for a description interactively

              Example:

              ```bash
              # When prompted for description, provide context:
              "Fixing critical bug that causes data loss when users upload files > 10MB.
              Needs to be fixed before next release."
              ```

              ### 🟢 Step 3: Update Status After Work

              These state updates are **MANDATORY**, not optional:

              **CHECKPOINT:** Are you marking state transitions as you work?

              ✅ **When starting work:**

              ```bash
              juggle <ball-id> in-air
              ```

              ✅ **When you need user input:**

              ```bash
              juggle <ball-id> needs-thrown
              ```

              ✅ **After completing work:**

              ```bash
              juggle <ball-id> needs-caught
              ```

              ✅ **When fully done:**

              ```bash
              juggle <ball-id> complete "Brief summary"
              ```

              **CHECKPOINT:** Did you update ball state after completing work?

              ═══════════════════════════════════════════════════════════════

              ## Examples of Compliance

              ### ❌ WRONG - NEVER DO THIS:

              ```
              User: "Fix the help text for start command"
              Assistant: *Immediately runs find_symbol and starts investigating*

              ❌ CRITICAL ERROR - Didn't check juggler first!
              ❌ This is a BLOCKING violation
              ❌ Session must restart
              ```

              ### ✅ CORRECT - ALWAYS DO THIS:

              ```
              User: "Fix the help text for start command"

              Assistant: STOP - Let me check juggler state first.
              *Runs: juggle*
              *Sees: juggler-8 - "improving CLI help text"*

              Assistant: Found existing ball (juggler-8) about CLI help.
              I MUST use this existing ball before creating new work.

              *Runs: juggle juggler-8*
              *Reviews todos*
              *Runs: juggle juggler-8 in-air*

              ✓ CORRECT - Checked state FIRST
              ✓ CORRECT - Found match and used existing ball
              ✓ CORRECT - Marked as in-air before working
              ```

              ═══════════════════════════════════════════════════════════════

              ## Detailed Reference Information

              ### 🎯 The Juggling Metaphor

              Think of tasks as balls being juggled:
              - **needs-thrown**: Ball needs your throw (user must give direction)
              - **in-air**: Ball is flying (you're actively working)
              - **needs-caught**: Ball coming down (user must verify/catch)
              - **complete**: Ball successfully caught and put away
              - **dropped**: Ball fell and is no longer being juggled

              ### 📚 Common Commands Reference
              - `juggle` - Show currently juggling balls
              - `juggle <ball-id>` - Show ball details
              - `juggle balls` - List all balls (any state)
              - `juggle <ball-id> <state>` - Update ball state
              - `juggle <ball-id> todo add "task"` - Add todo
              - `juggle <ball-id> todo done <N>` - Complete todo N
              - `juggle next` - Find ball needing attention

              ### 🔗 Beads Integration (Optional)

              Juggler can link balls to beads issues for cross-referencing and context continuity:

              **Creating balls with beads links:**

              ```bash
              juggle start "Implement search API" --beads bd-a1b2
              juggle plan "Fix auth bug" --beads bd-c3d4 --priority high
              ```

              **Linking existing balls:**

              ```bash
              juggle link juggler-5 bd-a1b2           # Link to one issue
              juggle link juggler-5 bd-a1b2 bd-e5f6   # Link to multiple
              juggle unlink juggler-5 bd-a1b2         # Unlink
              ```

              **Finding balls by beads issue:**

              ```bash
              juggle history --beads bd-a1b2          # See all balls that worked on bd-a1b2
              juggle show juggler-5                   # Display shows linked beads issues
              ```

              **When to use beads integration:**
              - Working on beads issues and want conversation history
              - Multiple sessions on same beads issue (context continuity)
              - Tracking which juggler sessions touched which beads issues

              **Best practice:**
              When user mentions a beads issue ID (bd-xxxx), include it when creating the ball:

              ```bash
              # User: "Work on bd-a1b2 - add search API"
              juggle start "Work on bd-a1b2: Add search API" --beads bd-a1b2
              ```

              ### 🔄 Multi-Agent / Multi-Session Support

              When multiple agents/users work simultaneously, activity tracking resolution:
              1. **JUGGLER_CURRENT_BALL env var** - Explicit override
              2. **Zellij session+tab matching** - Auto-detects from environment
              3. **Single juggling ball** - If only one is juggling
              4. **Most recently active** - Fallback

              Set explicit ball:

              ```bash
              export JUGGLER_CURRENT_BALL="juggler-5"
              ```

              ### 📝 Technical Notes
              - Ball IDs: `<directory-name>-<counter>` (e.g., `juggler-1`, `myapp-5`)
              - Activity tracking via hooks updates timestamps automatically
              - Balls store Zellij session/tab info when created in Zellij
              - Multiple balls can coexist per project (use explicit IDs)

              <!-- juggler-instructions-end -->
