import * as fs from "fs/promises";
import * as path from "path";
import * as os from "os";
import {
  getProjectRoot,
  getMemoryPath,
  ensureDir,
  readFileSafe,
  writeFileSafe,
  listFiles,
  getTimestamp,
  getDateString,
  searchInFiles,
  getNextNumber,
} from "../utils/file-helpers.js";

describe("file-helpers", () => {
  let testDir: string;

  beforeEach(async () => {
    // Create a unique temp directory for each test
    testDir = path.join(os.tmpdir(), `claude-memory-test-${Date.now()}-${Math.random().toString(36).slice(2)}`);
    await fs.mkdir(testDir, { recursive: true });
  });

  afterEach(async () => {
    // Clean up test directory
    try {
      await fs.rm(testDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  });

  describe("getProjectRoot", () => {
    const originalEnv = process.env.MEMORY_PROJECT_ROOT;
    const originalArgv = process.argv;

    afterEach(() => {
      process.env.MEMORY_PROJECT_ROOT = originalEnv;
      process.argv = originalArgv;
    });

    it("should return MEMORY_PROJECT_ROOT env var when set", () => {
      process.env.MEMORY_PROJECT_ROOT = "/custom/path";
      expect(getProjectRoot()).toBe(path.resolve("/custom/path"));
    });

    it("should return command line argument when env var not set", () => {
      delete process.env.MEMORY_PROJECT_ROOT;
      process.argv = ["node", "script.js", "/arg/path"];
      expect(getProjectRoot()).toBe(path.resolve("/arg/path"));
    });

    it("should return cwd when neither env var nor arg is set", () => {
      delete process.env.MEMORY_PROJECT_ROOT;
      process.argv = ["node", "script.js"];
      expect(getProjectRoot()).toBe(path.resolve(process.cwd()));
    });
  });

  describe("getMemoryPath", () => {
    const originalEnv = process.env.MEMORY_PROJECT_ROOT;

    afterEach(() => {
      process.env.MEMORY_PROJECT_ROOT = originalEnv;
    });

    it("should return .claude/memory under project root", () => {
      process.env.MEMORY_PROJECT_ROOT = testDir;
      const memoryPath = getMemoryPath();
      expect(memoryPath).toBe(path.join(testDir, ".claude", "memory"));
    });
  });

  describe("ensureDir", () => {
    it("should create directory if it does not exist", async () => {
      const newDir = path.join(testDir, "new-dir", "nested");
      await ensureDir(newDir);

      const stats = await fs.stat(newDir);
      expect(stats.isDirectory()).toBe(true);
    });

    it("should not throw if directory already exists", async () => {
      await fs.mkdir(path.join(testDir, "existing"));

      await expect(ensureDir(path.join(testDir, "existing"))).resolves.not.toThrow();
    });

    it("should create nested directories", async () => {
      const nestedDir = path.join(testDir, "a", "b", "c", "d");
      await ensureDir(nestedDir);

      const stats = await fs.stat(nestedDir);
      expect(stats.isDirectory()).toBe(true);
    });
  });

  describe("readFileSafe", () => {
    it("should read file contents when file exists", async () => {
      const filePath = path.join(testDir, "test.txt");
      await fs.writeFile(filePath, "Hello, World!");

      const content = await readFileSafe(filePath);
      expect(content).toBe("Hello, World!");
    });

    it("should return null when file does not exist", async () => {
      const filePath = path.join(testDir, "nonexistent.txt");

      const content = await readFileSafe(filePath);
      expect(content).toBeNull();
    });

    it("should handle UTF-8 content", async () => {
      const filePath = path.join(testDir, "unicode.txt");
      const unicodeContent = "Hello, World! Special chars: e a n";
      await fs.writeFile(filePath, unicodeContent, "utf-8");

      const content = await readFileSafe(filePath);
      expect(content).toBe(unicodeContent);
    });
  });

  describe("writeFileSafe", () => {
    it("should write content to file", async () => {
      const filePath = path.join(testDir, "output.txt");
      await writeFileSafe(filePath, "Test content");

      const content = await fs.readFile(filePath, "utf-8");
      expect(content).toBe("Test content");
    });

    it("should create parent directories if they do not exist", async () => {
      const filePath = path.join(testDir, "new", "nested", "file.txt");
      await writeFileSafe(filePath, "Nested content");

      const content = await fs.readFile(filePath, "utf-8");
      expect(content).toBe("Nested content");
    });

    it("should overwrite existing file", async () => {
      const filePath = path.join(testDir, "existing.txt");
      await fs.writeFile(filePath, "Old content");

      await writeFileSafe(filePath, "New content");

      const content = await fs.readFile(filePath, "utf-8");
      expect(content).toBe("New content");
    });
  });

  describe("listFiles", () => {
    beforeEach(async () => {
      // Create test files
      await fs.writeFile(path.join(testDir, "file1.md"), "content1");
      await fs.writeFile(path.join(testDir, "file2.md"), "content2");
      await fs.writeFile(path.join(testDir, "file3.txt"), "content3");
      await fs.mkdir(path.join(testDir, "subdir"));
    });

    it("should list all files in directory", async () => {
      const files = await listFiles(testDir);
      expect(files).toContain("file1.md");
      expect(files).toContain("file2.md");
      expect(files).toContain("file3.txt");
      expect(files).not.toContain("subdir");
    });

    it("should filter files by extension", async () => {
      const files = await listFiles(testDir, ".md");
      expect(files).toContain("file1.md");
      expect(files).toContain("file2.md");
      expect(files).not.toContain("file3.txt");
    });

    it("should return empty array for non-existent directory", async () => {
      const files = await listFiles(path.join(testDir, "nonexistent"));
      expect(files).toEqual([]);
    });

    it("should return empty array for empty directory", async () => {
      const emptyDir = path.join(testDir, "empty");
      await fs.mkdir(emptyDir);

      const files = await listFiles(emptyDir);
      expect(files).toEqual([]);
    });
  });

  describe("getTimestamp", () => {
    it("should return ISO-like timestamp without colons or dots", () => {
      const timestamp = getTimestamp();
      expect(timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}$/);
    });

    it("should be based on current date", () => {
      const timestamp = getTimestamp();
      const now = new Date();
      const yearPart = timestamp.slice(0, 4);
      expect(parseInt(yearPart)).toBe(now.getFullYear());
    });
  });

  describe("getDateString", () => {
    it("should return date in YYYY-MM-DD format", () => {
      const dateString = getDateString();
      expect(dateString).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    });

    it("should reflect current date", () => {
      const dateString = getDateString();
      const now = new Date();
      const expected = now.toISOString().slice(0, 10);
      expect(dateString).toBe(expected);
    });
  });

  describe("searchInFiles", () => {
    beforeEach(async () => {
      await fs.writeFile(
        path.join(testDir, "doc1.md"),
        "# Title\nThis contains searchTerm and more content.\nAnother line."
      );
      await fs.writeFile(
        path.join(testDir, "doc2.md"),
        "# Another Doc\nNo matches here.\nJust plain text."
      );
      await fs.writeFile(
        path.join(testDir, "doc3.md"),
        "# Third Doc\nMultiple searchTerm occurrences.\nsearchTerm again."
      );
      await fs.writeFile(path.join(testDir, "doc4.txt"), "searchTerm in txt");
    });

    it("should find files containing the search term", async () => {
      const results = await searchInFiles(testDir, "searchTerm", ".md");
      expect(results.length).toBe(2);
      expect(results.map((r) => r.file)).toContain("doc1.md");
      expect(results.map((r) => r.file)).toContain("doc3.md");
    });

    it("should return matching excerpts with context", async () => {
      const results = await searchInFiles(testDir, "searchTerm", ".md");
      const doc1Result = results.find((r) => r.file === "doc1.md");
      expect(doc1Result).toBeDefined();
      expect(doc1Result!.matches.length).toBeGreaterThan(0);
      expect(doc1Result!.matches[0]).toContain("searchTerm");
    });

    it("should be case-insensitive", async () => {
      const results = await searchInFiles(testDir, "SEARCHTERM", ".md");
      expect(results.length).toBe(2);
    });

    it("should return empty array for non-existent directory", async () => {
      const results = await searchInFiles(
        path.join(testDir, "nonexistent"),
        "searchTerm"
      );
      expect(results).toEqual([]);
    });

    it("should filter by extension", async () => {
      const mdResults = await searchInFiles(testDir, "searchTerm", ".md");
      const txtResults = await searchInFiles(testDir, "searchTerm", ".txt");

      expect(mdResults.map((r) => r.file)).not.toContain("doc4.txt");
      expect(txtResults.map((r) => r.file)).toContain("doc4.txt");
    });

    it("should return empty array when no matches found", async () => {
      const results = await searchInFiles(testDir, "nonexistentterm", ".md");
      expect(results).toEqual([]);
    });
  });

  describe("getNextNumber", () => {
    it("should return 1 for empty directory", async () => {
      const num = await getNextNumber(testDir, "decision-");
      expect(num).toBe(1);
    });

    it("should return next number based on existing files", async () => {
      await fs.writeFile(path.join(testDir, "decision-001-first.md"), "");
      await fs.writeFile(path.join(testDir, "decision-002-second.md"), "");

      const num = await getNextNumber(testDir, "decision-");
      expect(num).toBe(3);
    });

    it("should handle gaps in numbering", async () => {
      await fs.writeFile(path.join(testDir, "decision-001-first.md"), "");
      await fs.writeFile(path.join(testDir, "decision-005-fifth.md"), "");

      const num = await getNextNumber(testDir, "decision-");
      expect(num).toBe(6);
    });

    it("should ignore files with different prefix", async () => {
      await fs.writeFile(path.join(testDir, "decision-001-first.md"), "");
      await fs.writeFile(path.join(testDir, "session-099-latest.md"), "");

      const num = await getNextNumber(testDir, "decision-");
      expect(num).toBe(2);
    });

    it("should return 1 for non-existent directory", async () => {
      const num = await getNextNumber(
        path.join(testDir, "nonexistent"),
        "decision-"
      );
      expect(num).toBe(1);
    });
  });
});
