import * as fs from "fs/promises";
import * as path from "path";
import * as os from "os";
import {
  executeAddKnowledge,
  formatAddKnowledgeResult,
  AddKnowledgeParams,
  AddKnowledgeResult,
} from "../tools/add-knowledge.js";

describe("add-knowledge tool", () => {
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
    const knowledgeDir = path.join(memoryDir, "knowledge");
    await fs.mkdir(memoryDir, { recursive: true });
    await fs.mkdir(knowledgeDir, { recursive: true });

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

  describe("executeAddKnowledge", () => {
    const validParams: AddKnowledgeParams = {
      topic: "API Authentication",
      content:
        "Our API uses JWT tokens for authentication. Tokens expire after 24 hours and can be refreshed using the /auth/refresh endpoint.",
    };

    it("should create new knowledge file when topic does not exist", async () => {
      const result = await executeAddKnowledge(validParams);

      expect(result.created).toBe(true);
      expect(result.updated).toBe(false);

      const content = await fs.readFile(result.knowledgeFile, "utf-8");

      expect(content).toContain("# API Authentication");
      expect(content).toContain("**Created:**");
      expect(content).toContain("**Last Updated:**");
      expect(content).toContain("JWT tokens for authentication");
      expect(content).toContain("/auth/refresh endpoint");
    });

    it("should create filename from topic slug", async () => {
      const result = await executeAddKnowledge(validParams);

      const fileName = path.basename(result.knowledgeFile);
      expect(fileName).toBe("api-authentication.md");
    });

    it("should handle special characters in topic name", async () => {
      const params: AddKnowledgeParams = {
        topic: "Database: PostgreSQL & Redis!!!",
        content: "Using PostgreSQL for main storage and Redis for caching.",
      };

      const result = await executeAddKnowledge(params);

      const fileName = path.basename(result.knowledgeFile);
      expect(fileName).toBe("database-postgresql-redis.md");
    });

    it("should append to existing knowledge file", async () => {
      // Create initial knowledge
      await executeAddKnowledge(validParams);

      // Add more knowledge to same topic
      const updateParams: AddKnowledgeParams = {
        topic: "API Authentication",
        content: "Refresh tokens have a 7-day lifetime.",
      };

      const result = await executeAddKnowledge(updateParams);

      expect(result.created).toBe(false);
      expect(result.updated).toBe(true);

      const content = await fs.readFile(result.knowledgeFile, "utf-8");

      // Should contain original content
      expect(content).toContain("JWT tokens for authentication");
      // Should contain update section
      expect(content).toContain("## Update (");
      expect(content).toContain("Refresh tokens have a 7-day lifetime");
      // Should have separator
      expect(content).toContain("---");
    });

    it("should update Last Updated timestamp when appending", async () => {
      // Create initial knowledge
      const result1 = await executeAddKnowledge(validParams);
      const content1 = await fs.readFile(result1.knowledgeFile, "utf-8");

      // Wait a moment to ensure different date if system is fast
      await new Promise((resolve) => setTimeout(resolve, 100));

      // Add more knowledge
      const updateParams: AddKnowledgeParams = {
        topic: "API Authentication",
        content: "Added new info.",
      };

      const result2 = await executeAddKnowledge(updateParams);
      const content2 = await fs.readFile(result2.knowledgeFile, "utf-8");

      // Last Updated should have been modified
      const lastUpdatedMatch = content2.match(/\*\*Last Updated:\*\* .+/);
      expect(lastUpdatedMatch).toBeTruthy();
    });

    it("should create knowledge index when adding first topic", async () => {
      const result = await executeAddKnowledge(validParams);

      expect(result.indexUpdated).toBe(true);

      const indexPath = path.join(
        testDir,
        ".claude",
        "memory",
        "knowledge",
        "index.md"
      );
      const indexContent = await fs.readFile(indexPath, "utf-8");

      expect(indexContent).toContain("# Knowledge Index");
      expect(indexContent).toContain("## Topics");
      expect(indexContent).toContain("[API Authentication](./api-authentication.md)");
    });

    it("should add new topic to existing index", async () => {
      // Create first topic
      await executeAddKnowledge(validParams);

      // Create second topic
      const params2: AddKnowledgeParams = {
        topic: "Database Schema",
        content: "Our database uses normalized schema design.",
      };

      const result2 = await executeAddKnowledge(params2);

      expect(result2.indexUpdated).toBe(true);

      const indexPath = path.join(
        testDir,
        ".claude",
        "memory",
        "knowledge",
        "index.md"
      );
      const indexContent = await fs.readFile(indexPath, "utf-8");

      expect(indexContent).toContain("[API Authentication](./api-authentication.md)");
      expect(indexContent).toContain("[Database Schema](./database-schema.md)");
    });

    it("should not duplicate topic in index when updating", async () => {
      // Create initial knowledge
      await executeAddKnowledge(validParams);

      // Update same topic
      const updateParams: AddKnowledgeParams = {
        topic: "API Authentication",
        content: "Additional auth info.",
      };

      const result = await executeAddKnowledge(updateParams);

      expect(result.indexUpdated).toBe(false);

      const indexPath = path.join(
        testDir,
        ".claude",
        "memory",
        "knowledge",
        "index.md"
      );
      const indexContent = await fs.readFile(indexPath, "utf-8");

      // Should only appear once
      const matches = indexContent.match(/API Authentication/g);
      expect(matches?.length).toBe(1);
    });

    it("should create knowledge directory if it does not exist", async () => {
      // Remove knowledge directory
      await fs.rm(path.join(testDir, ".claude", "memory", "knowledge"), {
        recursive: true,
      });

      const result = await executeAddKnowledge(validParams);

      expect(result.created).toBe(true);
      const exists = await fs
        .access(result.knowledgeFile)
        .then(() => true)
        .catch(() => false);
      expect(exists).toBe(true);
    });

    it("should preserve markdown formatting in content", async () => {
      const params: AddKnowledgeParams = {
        topic: "Code Examples",
        content: `
## Authentication Flow

\`\`\`javascript
const token = await auth.login(username, password);
\`\`\`

### Important Notes

- Always use HTTPS
- Store tokens securely
- Never expose secrets
`,
      };

      const result = await executeAddKnowledge(params);
      const content = await fs.readFile(result.knowledgeFile, "utf-8");

      expect(content).toContain("```javascript");
      expect(content).toContain("auth.login");
      expect(content).toContain("### Important Notes");
      expect(content).toContain("- Always use HTTPS");
    });

    it("should handle empty content gracefully", async () => {
      const params: AddKnowledgeParams = {
        topic: "Empty Topic",
        content: "",
      };

      const result = await executeAddKnowledge(params);

      expect(result.created).toBe(true);
      const content = await fs.readFile(result.knowledgeFile, "utf-8");
      expect(content).toContain("# Empty Topic");
    });

    it("should handle topics that produce same slug", async () => {
      // Create first topic
      await executeAddKnowledge({
        topic: "API Design",
        content: "First content",
      });

      // Create topic with same slug
      const result = await executeAddKnowledge({
        topic: "API-Design",
        content: "Second content",
      });

      // Should update existing file since slug is the same
      expect(result.updated).toBe(true);
      const content = await fs.readFile(result.knowledgeFile, "utf-8");
      expect(content).toContain("First content");
      expect(content).toContain("Second content");
    });
  });

  describe("formatAddKnowledgeResult", () => {
    it("should format created knowledge result", () => {
      const result: AddKnowledgeResult = {
        knowledgeFile: "/path/to/knowledge/api-auth.md",
        created: true,
        updated: false,
        indexUpdated: true,
      };

      const formatted = formatAddKnowledgeResult(result);

      expect(formatted).toContain("# Knowledge Created Successfully");
      expect(formatted).toContain("**File:** /path/to/knowledge/api-auth.md");
      expect(formatted).toContain("**Action:** Created");
      expect(formatted).toContain("**Index Updated:** Yes");
      expect(formatted).toContain("has been created in the memory system");
    });

    it("should format updated knowledge result", () => {
      const result: AddKnowledgeResult = {
        knowledgeFile: "/path/to/knowledge/api-auth.md",
        created: false,
        updated: true,
        indexUpdated: false,
      };

      const formatted = formatAddKnowledgeResult(result);

      expect(formatted).toContain("# Knowledge Updated Successfully");
      expect(formatted).toContain("**Action:** Updated");
      expect(formatted).toContain("**Index Updated:** No (already indexed)");
      expect(formatted).toContain("has been updated in the memory system");
    });
  });
});
