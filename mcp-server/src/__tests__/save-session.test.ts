import * as fs from "fs/promises";
import * as path from "path";
import * as os from "os";
import {
  executeSaveSession,
  formatSaveSessionResult,
  SaveSessionParams,
  SaveSessionResult,
} from "../tools/save-session.js";

describe("save-session tool", () => {
  let testDir: string;
  let originalEnv: string | undefined;

  beforeEach(async () => {
    // Save original env
    originalEnv = process.env.MEMORY_PROJECT_ROOT;

    // Create a unique temp directory for each test
    testDir = path.join(
      os.tmpdir(),
      `claude-memory-test-${Date.now()}-${Math.random().toString(36).slice(2)}`
    );
    await fs.mkdir(testDir, { recursive: true });

    // Set up memory structure
    const memoryDir = path.join(testDir, ".claude", "memory");
    const sessionsDir = path.join(memoryDir, "sessions");
    await fs.mkdir(memoryDir, { recursive: true });
    await fs.mkdir(sessionsDir, { recursive: true });

    // Set the project root
    process.env.MEMORY_PROJECT_ROOT = testDir;
  });

  afterEach(async () => {
    // Restore original env
    process.env.MEMORY_PROJECT_ROOT = originalEnv;

    // Clean up test directory
    try {
      await fs.rm(testDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  });

  describe("executeSaveSession", () => {
    const validParams: SaveSessionParams = {
      summary: "Implemented authentication feature",
      work_completed: [
        "Created login form",
        "Added JWT token handling",
        "Wrote unit tests",
      ],
      decisions: [
        "Used JWT for auth instead of sessions",
        "Chose bcrypt for password hashing",
      ],
      discoveries: [
        "Found existing utility for token refresh",
        "Discovered rate limiting was already in place",
      ],
      next_steps: [
        "Add password reset flow",
        "Implement 2FA",
        "Add refresh token rotation",
      ],
    };

    it("should create session file with correct content", async () => {
      const result = await executeSaveSession(validParams);

      // Check session file was created
      const sessionContent = await fs.readFile(result.sessionFile, "utf-8");

      expect(sessionContent).toContain("# Session:");
      expect(sessionContent).toContain("## Summary");
      expect(sessionContent).toContain("Implemented authentication feature");
      expect(sessionContent).toContain("## Work Completed");
      expect(sessionContent).toContain("- Created login form");
      expect(sessionContent).toContain("- Added JWT token handling");
      expect(sessionContent).toContain("## Decisions Made");
      expect(sessionContent).toContain("- Used JWT for auth instead of sessions");
      expect(sessionContent).toContain("## Discoveries");
      expect(sessionContent).toContain("- Found existing utility for token refresh");
      expect(sessionContent).toContain("## Next Steps");
      expect(sessionContent).toContain("- [ ] Add password reset flow");
    });

    it("should create session file with timestamp in filename", async () => {
      const result = await executeSaveSession(validParams);

      const fileName = path.basename(result.sessionFile);
      expect(fileName).toMatch(/^session-\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}\.md$/);
    });

    it("should update current_context.md", async () => {
      const result = await executeSaveSession(validParams);

      expect(result.contextUpdated).toBe(true);

      const contextPath = path.join(
        testDir,
        ".claude",
        "memory",
        "current_context.md"
      );
      const contextContent = await fs.readFile(contextPath, "utf-8");

      expect(contextContent).toContain("# Current Context");
      expect(contextContent).toContain("Last Updated:");
      expect(contextContent).toContain("## Recent Session Summary");
      expect(contextContent).toContain("Implemented authentication feature");
      expect(contextContent).toContain("## Current State");
      expect(contextContent).toContain("### Completed Work");
      expect(contextContent).toContain("[x] Created login form");
      expect(contextContent).toContain("## Pending Tasks");
      expect(contextContent).toContain("[ ] Add password reset flow");
    });

    it("should handle empty arrays gracefully", async () => {
      const emptyParams: SaveSessionParams = {
        summary: "Brief session with no details",
        work_completed: [],
        decisions: [],
        discoveries: [],
        next_steps: [],
      };

      const result = await executeSaveSession(emptyParams);
      const sessionContent = await fs.readFile(result.sessionFile, "utf-8");

      expect(sessionContent).toContain("Brief session with no details");
      expect(sessionContent).toContain("- No items recorded");
      expect(sessionContent).toContain("- No decisions recorded");
      expect(sessionContent).toContain("- No discoveries recorded");
      expect(sessionContent).toContain("- No next steps recorded");
    });

    it("should create sessions directory if it does not exist", async () => {
      // Remove sessions directory
      await fs.rm(path.join(testDir, ".claude", "memory", "sessions"), {
        recursive: true,
      });

      const result = await executeSaveSession(validParams);

      expect(result.sessionFile).toBeTruthy();
      const exists = await fs
        .access(result.sessionFile)
        .then(() => true)
        .catch(() => false);
      expect(exists).toBe(true);
    });

    it("should return timestamp in result", async () => {
      const result = await executeSaveSession(validParams);

      expect(result.timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}$/);
    });

    it("should preserve special characters in content", async () => {
      const specialParams: SaveSessionParams = {
        summary: "Session with special chars: <>&\"'",
        work_completed: ["Task with `code` and *markdown*"],
        decisions: ["Decision with /path/to/file"],
        discoveries: ["Found issue #123"],
        next_steps: ["Check https://example.com"],
      };

      const result = await executeSaveSession(specialParams);
      const sessionContent = await fs.readFile(result.sessionFile, "utf-8");

      expect(sessionContent).toContain("<>&\"'");
      expect(sessionContent).toContain("`code`");
      expect(sessionContent).toContain("/path/to/file");
      expect(sessionContent).toContain("#123");
      expect(sessionContent).toContain("https://example.com");
    });

    it("should create unique session files for concurrent saves", async () => {
      // Add small delays to ensure different timestamps
      const result1 = await executeSaveSession(validParams);
      await new Promise((resolve) => setTimeout(resolve, 1100)); // Wait for timestamp to change
      const result2 = await executeSaveSession(validParams);

      expect(result1.sessionFile).not.toBe(result2.sessionFile);
    });
  });

  describe("formatSaveSessionResult", () => {
    it("should format successful save result", () => {
      const result: SaveSessionResult = {
        sessionFile: "/path/to/sessions/session-2024-01-15T10-30-00.md",
        contextUpdated: true,
        timestamp: "2024-01-15T10-30-00",
      };

      const formatted = formatSaveSessionResult(result);

      expect(formatted).toContain("# Session Saved Successfully");
      expect(formatted).toContain("**Timestamp:** 2024-01-15T10-30-00");
      expect(formatted).toContain(
        "**Session File:** /path/to/sessions/session-2024-01-15T10-30-00.md"
      );
      expect(formatted).toContain("**Context Updated:** Yes");
      expect(formatted).toContain("session has been recorded");
    });

    it("should indicate when context was not updated", () => {
      const result: SaveSessionResult = {
        sessionFile: "/path/to/session.md",
        contextUpdated: false,
        timestamp: "2024-01-15T10-30-00",
      };

      const formatted = formatSaveSessionResult(result);

      expect(formatted).toContain("**Context Updated:** No");
    });
  });
});
