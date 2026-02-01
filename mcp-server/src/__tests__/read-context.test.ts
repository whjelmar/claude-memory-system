import * as fs from "fs/promises";
import * as path from "path";
import * as os from "os";
import {
  executeReadContext,
  formatContextResult,
  ContextResult,
} from "../tools/read-context.js";

describe("read-context tool", () => {
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
    const plansDir = path.join(testDir, ".claude", "plans");
    await fs.mkdir(memoryDir, { recursive: true });
    await fs.mkdir(plansDir, { recursive: true });

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

  describe("executeReadContext", () => {
    it("should read current context and active plan when both exist", async () => {
      const contextPath = path.join(
        testDir,
        ".claude",
        "memory",
        "current_context.md"
      );
      const planPath = path.join(
        testDir,
        ".claude",
        "memory",
        "active_plan.md"
      );

      await fs.writeFile(contextPath, "# Current Context\nTest context content");
      await fs.writeFile(planPath, "# Active Plan\nTest plan content");

      const result = await executeReadContext();

      expect(result.hasContext).toBe(true);
      expect(result.hasPlan).toBe(true);
      expect(result.currentContext).toContain("Test context content");
      expect(result.activePlan).toContain("Test plan content");
    });

    it("should handle missing context file", async () => {
      const planPath = path.join(
        testDir,
        ".claude",
        "memory",
        "active_plan.md"
      );
      await fs.writeFile(planPath, "# Active Plan\nTest plan content");

      const result = await executeReadContext();

      expect(result.hasContext).toBe(false);
      expect(result.currentContext).toBeNull();
      expect(result.hasPlan).toBe(true);
    });

    it("should handle missing plan file", async () => {
      const contextPath = path.join(
        testDir,
        ".claude",
        "memory",
        "current_context.md"
      );
      await fs.writeFile(contextPath, "# Current Context\nTest context content");

      const result = await executeReadContext();

      expect(result.hasContext).toBe(true);
      expect(result.hasPlan).toBe(false);
      expect(result.activePlan).toBeNull();
    });

    it("should handle both files missing", async () => {
      const result = await executeReadContext();

      expect(result.hasContext).toBe(false);
      expect(result.hasPlan).toBe(false);
      expect(result.currentContext).toBeNull();
      expect(result.activePlan).toBeNull();
    });

    it("should return correct file paths", async () => {
      const result = await executeReadContext();

      expect(result.contextPath).toBe(
        path.join(testDir, ".claude", "memory", "current_context.md")
      );
      expect(result.planPath).toBe(
        path.join(testDir, ".claude", "memory", "active_plan.md")
      );
    });

    it("should handle empty files", async () => {
      const contextPath = path.join(
        testDir,
        ".claude",
        "memory",
        "current_context.md"
      );
      const planPath = path.join(
        testDir,
        ".claude",
        "memory",
        "active_plan.md"
      );

      await fs.writeFile(contextPath, "");
      await fs.writeFile(planPath, "");

      const result = await executeReadContext();

      expect(result.hasContext).toBe(true);
      expect(result.hasPlan).toBe(true);
      expect(result.currentContext).toBe("");
      expect(result.activePlan).toBe("");
    });
  });

  describe("formatContextResult", () => {
    it("should format result when both context and plan exist", () => {
      const result: ContextResult = {
        currentContext: "Test context",
        activePlan: "Test plan",
        hasContext: true,
        hasPlan: true,
        contextPath: "/path/to/context.md",
        planPath: "/path/to/plan.md",
      };

      const formatted = formatContextResult(result);

      expect(formatted).toContain("# Memory Context");
      expect(formatted).toContain("## Current Context");
      expect(formatted).toContain("Test context");
      expect(formatted).toContain("## Active Plan");
      expect(formatted).toContain("Test plan");
      expect(formatted).toContain("/path/to/context.md");
      expect(formatted).toContain("/path/to/plan.md");
    });

    it("should indicate when context is missing", () => {
      const result: ContextResult = {
        currentContext: null,
        activePlan: "Test plan",
        hasContext: false,
        hasPlan: true,
        contextPath: "/path/to/context.md",
        planPath: "/path/to/plan.md",
      };

      const formatted = formatContextResult(result);

      expect(formatted).toContain("No current context found");
      expect(formatted).toContain("memory system may not be initialized");
    });

    it("should indicate when plan is missing", () => {
      const result: ContextResult = {
        currentContext: "Test context",
        activePlan: null,
        hasContext: true,
        hasPlan: false,
        contextPath: "/path/to/context.md",
        planPath: "/path/to/plan.md",
      };

      const formatted = formatContextResult(result);

      expect(formatted).toContain("No active plan found");
    });

    it("should handle both missing", () => {
      const result: ContextResult = {
        currentContext: null,
        activePlan: null,
        hasContext: false,
        hasPlan: false,
        contextPath: "/path/to/context.md",
        planPath: "/path/to/plan.md",
      };

      const formatted = formatContextResult(result);

      expect(formatted).toContain("No current context found");
      expect(formatted).toContain("No active plan found");
    });
  });
});
