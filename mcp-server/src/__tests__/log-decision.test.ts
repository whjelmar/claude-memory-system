import * as fs from "fs/promises";
import * as path from "path";
import * as os from "os";
import {
  executeLogDecision,
  formatLogDecisionResult,
  LogDecisionParams,
  LogDecisionResult,
} from "../tools/log-decision.js";

describe("log-decision tool", () => {
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
    const decisionsDir = path.join(memoryDir, "decisions");
    await fs.mkdir(memoryDir, { recursive: true });
    await fs.mkdir(decisionsDir, { recursive: true });

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

  describe("executeLogDecision", () => {
    const validParams: LogDecisionParams = {
      title: "Choose Authentication Method",
      context:
        "We need to implement user authentication for our API. The system needs to support both web and mobile clients.",
      options: [
        {
          name: "JWT Tokens",
          pros: [
            "Stateless authentication",
            "Works well with microservices",
            "Standard implementation",
          ],
          cons: [
            "Cannot be invalidated easily",
            "Token size can be large",
          ],
        },
        {
          name: "Session-based Auth",
          pros: [
            "Easy to invalidate sessions",
            "Smaller cookies",
          ],
          cons: [
            "Requires server-side state",
            "Harder to scale horizontally",
          ],
        },
      ],
      decision:
        "We chose JWT Tokens for authentication because our architecture requires stateless authentication across multiple services.",
      consequences:
        "We will need to implement token refresh logic and consider token blacklisting for logout functionality.",
    };

    it("should create decision file with correct content", async () => {
      const result = await executeLogDecision(validParams);

      const decisionContent = await fs.readFile(result.decisionFile, "utf-8");

      expect(decisionContent).toContain(
        "# Decision 001: Choose Authentication Method"
      );
      expect(decisionContent).toContain("**Date:**");
      expect(decisionContent).toContain("**Status:** Decided");
      expect(decisionContent).toContain("## Context");
      expect(decisionContent).toContain("implement user authentication");
      expect(decisionContent).toContain("## Options Considered");
      expect(decisionContent).toContain("### Option 1: JWT Tokens");
      expect(decisionContent).toContain("**Pros:**");
      expect(decisionContent).toContain("- Stateless authentication");
      expect(decisionContent).toContain("**Cons:**");
      expect(decisionContent).toContain("- Cannot be invalidated easily");
      expect(decisionContent).toContain("### Option 2: Session-based Auth");
      expect(decisionContent).toContain("## Decision");
      expect(decisionContent).toContain("We chose JWT Tokens");
      expect(decisionContent).toContain("## Consequences");
      expect(decisionContent).toContain("implement token refresh logic");
    });

    it("should auto-number decisions starting from 1", async () => {
      const result = await executeLogDecision(validParams);

      expect(result.decisionNumber).toBe(1);
      expect(result.decisionFile).toContain("decision-001-");
    });

    it("should auto-increment decision numbers", async () => {
      // Create first decision
      await executeLogDecision(validParams);

      // Create second decision
      const params2: LogDecisionParams = {
        ...validParams,
        title: "Choose Database",
      };
      const result2 = await executeLogDecision(params2);

      expect(result2.decisionNumber).toBe(2);
      expect(result2.decisionFile).toContain("decision-002-");
    });

    it("should create slug from title in filename", async () => {
      const result = await executeLogDecision(validParams);

      const fileName = path.basename(result.decisionFile);
      expect(fileName).toMatch(/^decision-001-choose-authentication-method\.md$/);
    });

    it("should handle special characters in title for slug", async () => {
      const params: LogDecisionParams = {
        ...validParams,
        title: "API Design: REST vs GraphQL!!!",
      };

      const result = await executeLogDecision(params);

      const fileName = path.basename(result.decisionFile);
      expect(fileName).toMatch(/^decision-001-api-design-rest-vs-graphql\.md$/);
    });

    it("should truncate long titles in slug to 50 characters", async () => {
      const params: LogDecisionParams = {
        ...validParams,
        title:
          "This is a very long decision title that should be truncated in the filename but preserved in the content",
      };

      const result = await executeLogDecision(params);

      const fileName = path.basename(result.decisionFile);
      // Slug portion should be max 50 chars
      const slugPart = fileName.replace("decision-001-", "").replace(".md", "");
      expect(slugPart.length).toBeLessThanOrEqual(50);
    });

    it("should handle multiple options with varying pros/cons", async () => {
      const params: LogDecisionParams = {
        ...validParams,
        options: [
          { name: "Option A", pros: ["Pro 1"], cons: [] },
          { name: "Option B", pros: [], cons: ["Con 1", "Con 2", "Con 3"] },
          {
            name: "Option C",
            pros: ["Pro 1", "Pro 2"],
            cons: ["Con 1", "Con 2"],
          },
        ],
      };

      const result = await executeLogDecision(params);
      const content = await fs.readFile(result.decisionFile, "utf-8");

      expect(content).toContain("### Option 1: Option A");
      expect(content).toContain("### Option 2: Option B");
      expect(content).toContain("### Option 3: Option C");
    });

    it("should create decisions directory if it does not exist", async () => {
      // Remove decisions directory
      await fs.rm(path.join(testDir, ".claude", "memory", "decisions"), {
        recursive: true,
      });

      const result = await executeLogDecision(validParams);

      const exists = await fs
        .access(result.decisionFile)
        .then(() => true)
        .catch(() => false);
      expect(exists).toBe(true);
    });

    it("should return correct result structure", async () => {
      const result = await executeLogDecision(validParams);

      expect(result.decisionFile).toBeTruthy();
      expect(result.decisionNumber).toBe(1);
      expect(result.title).toBe("Choose Authentication Method");
    });

    it("should continue numbering after existing decisions", async () => {
      // Create pre-existing decision files
      const decisionsDir = path.join(testDir, ".claude", "memory", "decisions");
      await fs.writeFile(
        path.join(decisionsDir, "decision-005-old-decision.md"),
        "# Old Decision"
      );
      await fs.writeFile(
        path.join(decisionsDir, "decision-010-another-old.md"),
        "# Another Old"
      );

      const result = await executeLogDecision(validParams);

      expect(result.decisionNumber).toBe(11);
    });

    it("should preserve unicode characters in content", async () => {
      const params: LogDecisionParams = {
        title: "Internationalization Strategy",
        context: "Need to support multiple languages: English, Espanol, Francais",
        options: [
          {
            name: "i18n Library",
            pros: ["Supports special characters"],
            cons: ["Additional dependency"],
          },
        ],
        decision: "Use established i18n library",
        consequences: "Characters like accented characters should work",
      };

      const result = await executeLogDecision(params);
      const content = await fs.readFile(result.decisionFile, "utf-8");

      expect(content).toContain("Espanol");
      expect(content).toContain("Francais");
    });
  });

  describe("formatLogDecisionResult", () => {
    it("should format successful result", () => {
      const result: LogDecisionResult = {
        decisionFile: "/path/to/decisions/decision-001-test-decision.md",
        decisionNumber: 1,
        title: "Test Decision",
      };

      const formatted = formatLogDecisionResult(result);

      expect(formatted).toContain("# Decision Logged Successfully");
      expect(formatted).toContain("**Decision Number:** 1");
      expect(formatted).toContain("**Title:** Test Decision");
      expect(formatted).toContain(
        "**File:** /path/to/decisions/decision-001-test-decision.md"
      );
      expect(formatted).toContain("decision has been recorded");
    });

    it("should display multi-digit decision numbers correctly", () => {
      const result: LogDecisionResult = {
        decisionFile: "/path/to/decision-123-test.md",
        decisionNumber: 123,
        title: "Test",
      };

      const formatted = formatLogDecisionResult(result);

      expect(formatted).toContain("**Decision Number:** 123");
    });
  });
});
