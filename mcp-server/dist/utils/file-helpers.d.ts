/**
 * Get the project root path from environment variable or command line argument
 */
export declare function getProjectRoot(): string;
/**
 * Get the memory directory path
 */
export declare function getMemoryPath(): string;
/**
 * Ensure a directory exists, creating it if necessary
 */
export declare function ensureDir(dirPath: string): Promise<void>;
/**
 * Read a file safely, returning null if it doesn't exist
 */
export declare function readFileSafe(filePath: string): Promise<string | null>;
/**
 * Write content to a file, creating parent directories if needed
 */
export declare function writeFileSafe(filePath: string, content: string): Promise<void>;
/**
 * List files in a directory matching a pattern
 */
export declare function listFiles(dirPath: string, extension?: string): Promise<string[]>;
/**
 * Generate a timestamp string for file naming
 */
export declare function getTimestamp(): string;
/**
 * Generate a date string (YYYY-MM-DD)
 */
export declare function getDateString(): string;
/**
 * Search for text in files within a directory
 */
export declare function searchInFiles(dirPath: string, query: string, extension?: string): Promise<Array<{
    file: string;
    matches: string[];
    path: string;
}>>;
/**
 * Get the next available number for auto-numbered files
 */
export declare function getNextNumber(dirPath: string, prefix: string): Promise<number>;
//# sourceMappingURL=file-helpers.d.ts.map