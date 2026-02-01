import * as fs from "fs/promises";
import * as path from "path";

/**
 * Get the project root path from environment variable or command line argument
 */
export function getProjectRoot(): string {
  const projectRoot =
    process.env.MEMORY_PROJECT_ROOT || process.argv[2] || process.cwd();
  return path.resolve(projectRoot);
}

/**
 * Get the memory directory path
 */
export function getMemoryPath(): string {
  return path.join(getProjectRoot(), ".claude", "memory");
}

/**
 * Ensure a directory exists, creating it if necessary
 */
export async function ensureDir(dirPath: string): Promise<void> {
  try {
    await fs.mkdir(dirPath, { recursive: true });
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "EEXIST") {
      throw error;
    }
  }
}

/**
 * Read a file safely, returning null if it doesn't exist
 */
export async function readFileSafe(filePath: string): Promise<string | null> {
  try {
    return await fs.readFile(filePath, "utf-8");
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return null;
    }
    throw error;
  }
}

/**
 * Write content to a file, creating parent directories if needed
 */
export async function writeFileSafe(
  filePath: string,
  content: string
): Promise<void> {
  await ensureDir(path.dirname(filePath));
  await fs.writeFile(filePath, content, "utf-8");
}

/**
 * List files in a directory matching a pattern
 */
export async function listFiles(
  dirPath: string,
  extension?: string
): Promise<string[]> {
  try {
    const entries = await fs.readdir(dirPath, { withFileTypes: true });
    let files = entries
      .filter((entry) => entry.isFile())
      .map((entry) => entry.name);

    if (extension) {
      files = files.filter((file) => file.endsWith(extension));
    }

    return files;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return [];
    }
    throw error;
  }
}

/**
 * Generate a timestamp string for file naming
 */
export function getTimestamp(): string {
  const now = new Date();
  return now.toISOString().replace(/[:.]/g, "-").slice(0, 19);
}

/**
 * Generate a date string (YYYY-MM-DD)
 */
export function getDateString(): string {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Search for text in files within a directory
 */
export async function searchInFiles(
  dirPath: string,
  query: string,
  extension?: string
): Promise<Array<{ file: string; matches: string[]; path: string }>> {
  const results: Array<{ file: string; matches: string[]; path: string }> = [];
  const queryLower = query.toLowerCase();

  try {
    const files = await listFiles(dirPath, extension);

    for (const file of files) {
      const filePath = path.join(dirPath, file);
      const content = await readFileSafe(filePath);

      if (content && content.toLowerCase().includes(queryLower)) {
        const lines = content.split("\n");
        const matches: string[] = [];

        for (let i = 0; i < lines.length; i++) {
          if (lines[i].toLowerCase().includes(queryLower)) {
            // Include context (line before and after)
            const start = Math.max(0, i - 1);
            const end = Math.min(lines.length, i + 2);
            const excerpt = lines.slice(start, end).join("\n");
            matches.push(`Line ${i + 1}: ${excerpt}`);
          }
        }

        results.push({ file, matches, path: filePath });
      }
    }
  } catch (error) {
    // Directory doesn't exist, return empty results
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
      throw error;
    }
  }

  return results;
}

/**
 * Get the next available number for auto-numbered files
 */
export async function getNextNumber(
  dirPath: string,
  prefix: string
): Promise<number> {
  const files = await listFiles(dirPath, ".md");
  let maxNum = 0;

  const pattern = new RegExp(`^${prefix}(\\d+)`);
  for (const file of files) {
    const match = file.match(pattern);
    if (match) {
      const num = parseInt(match[1], 10);
      if (num > maxNum) {
        maxNum = num;
      }
    }
  }

  return maxNum + 1;
}
