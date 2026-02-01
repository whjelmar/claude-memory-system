import * as fs from "fs/promises";
import * as path from "path";
import * as os from "os";
import {
  executeSearchMemory,
  formatSearchMemoryResult,
  SearchMemoryParams,
  SearchMemoryResult,
} from "../tools/search-memory.js";

describe("search-memory tool", () => {
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
    const decisionsDir = path.join(memoryDir, "decisions");
    const knowledgeDir = path.join(memoryDir, "knowledge");

    await fs.mkdir(sessionsDir, { recursive: true });
    await fs.mkdir(decisionsDir, { recursive: true });
    await fs.mkdir(knowledgeDir, { recursive: true });

    // Create test content in sessions
    await fs.writeFile(
      path.join(sessionsDir, "session-2024-01-01.md"),
      "# Session 2024-01-01\nWorked on authentication feature.\nImplemented JWT tokens."
    );
    await fs.writeFile(
      path.join(sessionsDir, "session-2024-01-02.md"),
      "# Session 2024-01-02\nFixed database connection issues.\nOptimized queries."
    );

    // Create test content in decisions
    await fs.writeFile(
      path.join(decisionsDir, "decision-001-auth.md"),
      "# Decision 001: Authentication\nChose JWT tokens for API authentication.\nTokens expire in 24 hours."
    );
    await fs.writeFile(
      path.join(decisionsDir, "decision-002-database.md"),
      "# Decision 002: Database\nSelected PostgreSQL for main database.\nWill use Redis for caching."
    );

    // Create test content in knowledge
    await fs.writeFile(
      path.join(knowledgeDir, "api-auth.md"),
      "# API Authentication\nAll endpoints require JWT tokens.\nUse Bearer scheme in Authorization header."
    );
    await fs.writeFile(
      path.join(knowledgeDir, "database.md"),
      "# Database\nPostgreSQL running on port 5432.\nRedis for session cache."
    );

    // Create root memory files
    await fs.writeFile(
      path.join(memoryDir, "current_context.md"),
      "# Current Context\nCurrently working on authentication module.\nJWT implementation in progress."
    );

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

  describe("executeSearchMemory", () => {
    describe("scope: sessions", () => {
      it("should search only in sessions directory", async () => {
        const params: SearchMemoryParams = {
          query: "authentication",
          scope: "sessions",
        };

        const result = await executeSearchMemory(params);

        expect(result.results.sessions.length).toBeGreaterThan(0);
        expect(result.results.decisions.length).toBe(0);
        expect(result.results.knowledge.length).toBe(0);
      });

      it("should find matching session files", async () => {
        const params: SearchMemoryParams = {
          query: "JWT",
          scope: "sessions",
        };

        const result = await executeSearchMemory(params);

        expect(result.results.sessions.length).toBe(1);
        expect(result.results.sessions[0].file).toBe("session-2024-01-01.md");
        expect(result.results.sessions[0].matches.length).toBeGreaterThan(0);
      });
    });

    describe("scope: decisions", () => {
      it("should search only in decisions directory", async () => {
        const params: SearchMemoryParams = {
          query: "PostgreSQL",
          scope: "decisions",
        };

        const result = await executeSearchMemory(params);

        expect(result.results.sessions.length).toBe(0);
        expect(result.results.decisions.length).toBe(1);
        expect(result.results.knowledge.length).toBe(0);
      });

      it("should find matching decision files", async () => {
        const params: SearchMemoryParams = {
          query: "authentication",
          scope: "decisions",
        };

        const result = await executeSearchMemory(params);

        expect(result.results.decisions.length).toBe(1);
        expect(result.results.decisions[0].file).toBe("decision-001-auth.md");
      });
    });

    describe("scope: knowledge", () => {
      it("should search only in knowledge directory", async () => {
        const params: SearchMemoryParams = {
          query: "Bearer",
          scope: "knowledge",
        };

        const result = await executeSearchMemory(params);

        expect(result.results.sessions.length).toBe(0);
        expect(result.results.decisions.length).toBe(0);
        expect(result.results.knowledge.length).toBe(1);
      });

      it("should find matching knowledge files", async () => {
        const params: SearchMemoryParams = {
          query: "Redis",
          scope: "knowledge",
        };

        const result = await executeSearchMemory(params);

        expect(result.results.knowledge.length).toBe(1);
        expect(result.results.knowledge[0].file).toBe("database.md");
      });
    });

    describe("scope: all", () => {
      it("should search across all directories", async () => {
        const params: SearchMemoryParams = {
          query: "authentication",
          scope: "all",
        };

        const result = await executeSearchMemory(params);

        // Should find in sessions, decisions, and knowledge
        expect(result.results.sessions.length).toBeGreaterThan(0);
        expect(result.results.decisions.length).toBeGreaterThan(0);
        expect(result.results.knowledge.length).toBeGreaterThan(0);
      });

      it("should include root memory files in results", async () => {
        const params: SearchMemoryParams = {
          query: "Current Context",
          scope: "all",
        };

        const result = await executeSearchMemory(params);

        // Root files go into knowledge results
        const rootFileFound = result.results.knowledge.some(
          (r) => r.file === "current_context.md"
        );
        expect(rootFileFound).toBe(true);
      });

      it("should return total match count across all areas", async () => {
        const params: SearchMemoryParams = {
          query: "JWT",
          scope: "all",
        };

        const result = await executeSearchMemory(params);

        expect(result.totalMatches).toBeGreaterThan(0);
      });
    });

    describe("search behavior", () => {
      it("should be case-insensitive", async () => {
        const params: SearchMemoryParams = {
          query: "jwt",
          scope: "all",
        };

        const result = await executeSearchMemory(params);

        expect(result.totalMatches).toBeGreaterThan(0);
      });

      it("should return context around matches", async () => {
        const params: SearchMemoryParams = {
          query: "JWT",
          scope: "sessions",
        };

        const result = await executeSearchMemory(params);

        expect(result.results.sessions.length).toBe(1);
        const matches = result.results.sessions[0].matches;
        expect(matches.length).toBeGreaterThan(0);
        // Match should include line number
        expect(matches[0]).toMatch(/Line \d+:/);
      });

      it("should return empty results for non-matching query", async () => {
        const params: SearchMemoryParams = {
          query: "nonexistentterm12345",
          scope: "all",
        };

        const result = await executeSearchMemory(params);

        expect(result.totalMatches).toBe(0);
        expect(result.results.sessions.length).toBe(0);
        expect(result.results.decisions.length).toBe(0);
        expect(result.results.knowledge.length).toBe(0);
      });

      it("should handle partial word matches", async () => {
        const params: SearchMemoryParams = {
          query: "auth",
          scope: "all",
        };

        const result = await executeSearchMemory(params);

        // Should match "authentication", "auth", etc.
        expect(result.totalMatches).toBeGreaterThan(0);
      });

      it("should include file path in results", async () => {
        const params: SearchMemoryParams = {
          query: "JWT",
          scope: "sessions",
        };

        const result = await executeSearchMemory(params);

        expect(result.results.sessions[0].path).toBeTruthy();
        expect(result.results.sessions[0].path).toContain("session-2024-01-01.md");
      });
    });

    describe("result metadata", () => {
      it("should include query in result", async () => {
        const params: SearchMemoryParams = {
          query: "test query",
          scope: "all",
        };

        const result = await executeSearchMemory(params);

        expect(result.query).toBe("test query");
      });

      it("should include scope in result", async () => {
        const params: SearchMemoryParams = {
          query: "test",
          scope: "decisions",
        };

        const result = await executeSearchMemory(params);

        expect(result.scope).toBe("decisions");
      });
    });

    describe("empty directory handling", () => {
      it("should handle empty sessions directory", async () => {
        // Remove all session files
        const sessionsDir = path.join(testDir, ".claude", "memory", "sessions");
        const files = await fs.readdir(sessionsDir);
        for (const file of files) {
          await fs.unlink(path.join(sessionsDir, file));
        }

        const params: SearchMemoryParams = {
          query: "test",
          scope: "sessions",
        };

        const result = await executeSearchMemory(params);

        expect(result.results.sessions.length).toBe(0);
      });

      it("should handle non-existent directory", async () => {
        // Remove knowledge directory entirely
        await fs.rm(path.join(testDir, ".claude", "memory", "knowledge"), {
          recursive: true,
        });

        const params: SearchMemoryParams = {
          query: "test",
          scope: "knowledge",
        };

        const result = await executeSearchMemory(params);

        expect(result.results.knowledge.length).toBe(0);
      });
    });
  });

  describe("formatSearchMemoryResult", () => {
    it("should format results with matches", () => {
      const result: SearchMemoryResult = {
        query: "JWT",
        scope: "all",
        totalMatches: 3,
        results: {
          sessions: [
            {
              file: "session-2024-01-01.md",
              path: "/path/to/sessions/session-2024-01-01.md",
              matches: ["Line 2: Implemented JWT tokens."],
            },
          ],
          decisions: [
            {
              file: "decision-001-auth.md",
              path: "/path/to/decisions/decision-001-auth.md",
              matches: ["Line 2: Chose JWT tokens for authentication."],
            },
          ],
          knowledge: [
            {
              file: "api-auth.md",
              path: "/path/to/knowledge/api-auth.md",
              matches: ["Line 2: All endpoints require JWT tokens."],
            },
          ],
        },
      };

      const formatted = formatSearchMemoryResult(result);

      expect(formatted).toContain("# Memory Search Results");
      expect(formatted).toContain('**Query:** "JWT"');
      expect(formatted).toContain("**Scope:** all");
      expect(formatted).toContain("**Total Matches:** 3");
      expect(formatted).toContain("## Sessions");
      expect(formatted).toContain("### session-2024-01-01.md");
      expect(formatted).toContain("## Decisions");
      expect(formatted).toContain("### decision-001-auth.md");
      expect(formatted).toContain("## Knowledge");
      expect(formatted).toContain("### api-auth.md");
    });

    it("should format results with no matches", () => {
      const result: SearchMemoryResult = {
        query: "nonexistent",
        scope: "all",
        totalMatches: 0,
        results: {
          sessions: [],
          decisions: [],
          knowledge: [],
        },
      };

      const formatted = formatSearchMemoryResult(result);

      expect(formatted).toContain("# Memory Search Results");
      expect(formatted).toContain("**Total Matches:** 0");
      expect(formatted).toContain("No matches found.");
    });

    it("should limit excerpts per file to 3", () => {
      const result: SearchMemoryResult = {
        query: "test",
        scope: "sessions",
        totalMatches: 5,
        results: {
          sessions: [
            {
              file: "session.md",
              path: "/path/session.md",
              matches: [
                "Line 1: test 1",
                "Line 2: test 2",
                "Line 3: test 3",
                "Line 4: test 4",
                "Line 5: test 5",
              ],
            },
          ],
          decisions: [],
          knowledge: [],
        },
      };

      const formatted = formatSearchMemoryResult(result);

      expect(formatted).toContain("...and 2 more matches");
    });

    it("should include file paths in formatted output", () => {
      const result: SearchMemoryResult = {
        query: "test",
        scope: "decisions",
        totalMatches: 1,
        results: {
          sessions: [],
          decisions: [
            {
              file: "decision-001.md",
              path: "/full/path/to/decision-001.md",
              matches: ["Line 1: test content"],
            },
          ],
          knowledge: [],
        },
      };

      const formatted = formatSearchMemoryResult(result);

      expect(formatted).toContain("*Path: /full/path/to/decision-001.md*");
    });

    it("should only show sections that have matches", () => {
      const result: SearchMemoryResult = {
        query: "test",
        scope: "all",
        totalMatches: 1,
        results: {
          sessions: [],
          decisions: [
            {
              file: "decision.md",
              path: "/path/decision.md",
              matches: ["Line 1: test"],
            },
          ],
          knowledge: [],
        },
      };

      const formatted = formatSearchMemoryResult(result);

      expect(formatted).toContain("## Decisions");
      expect(formatted).not.toContain("## Sessions");
      expect(formatted).not.toContain("## Knowledge");
    });
  });
});
