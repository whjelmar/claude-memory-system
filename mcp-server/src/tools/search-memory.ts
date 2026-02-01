import * as path from "path";
import { getMemoryPath, searchInFiles } from "../utils/file-helpers.js";

export type SearchScope = "sessions" | "decisions" | "knowledge" | "all";

export interface SearchMemoryParams {
  query: string;
  scope: SearchScope;
}

export interface SearchMatch {
  file: string;
  path: string;
  matches: string[];
}

export interface SearchMemoryResult {
  query: string;
  scope: SearchScope;
  totalMatches: number;
  results: {
    sessions: SearchMatch[];
    decisions: SearchMatch[];
    knowledge: SearchMatch[];
  };
}

/**
 * Tool definition for memory_search
 */
export const searchMemoryTool = {
  name: "memory_search",
  description:
    "Searches across memory files for the given query. Can search in sessions, decisions, knowledge, or all areas. Returns matching excerpts with file paths.",
  inputSchema: {
    type: "object" as const,
    properties: {
      query: {
        type: "string",
        description: "The search query (case-insensitive)",
      },
      scope: {
        type: "string",
        enum: ["sessions", "decisions", "knowledge", "all"],
        description:
          "Where to search: 'sessions' (session logs), 'decisions' (decision records), 'knowledge' (knowledge files), or 'all' (everywhere)",
      },
    },
    required: ["query", "scope"],
  },
};

/**
 * Execute the search memory tool
 */
export async function executeSearchMemory(
  params: SearchMemoryParams
): Promise<SearchMemoryResult> {
  const memoryPath = getMemoryPath();

  const results: SearchMemoryResult = {
    query: params.query,
    scope: params.scope,
    totalMatches: 0,
    results: {
      sessions: [],
      decisions: [],
      knowledge: [],
    },
  };

  const searchAreas: Array<{
    key: "sessions" | "decisions" | "knowledge";
    path: string;
  }> = [];

  if (params.scope === "sessions" || params.scope === "all") {
    searchAreas.push({
      key: "sessions",
      path: path.join(memoryPath, "sessions"),
    });
  }

  if (params.scope === "decisions" || params.scope === "all") {
    searchAreas.push({
      key: "decisions",
      path: path.join(memoryPath, "decisions"),
    });
  }

  if (params.scope === "knowledge" || params.scope === "all") {
    searchAreas.push({
      key: "knowledge",
      path: path.join(memoryPath, "knowledge"),
    });
  }

  // Also search root memory files if searching all
  if (params.scope === "all") {
    const rootResults = await searchInFiles(memoryPath, params.query, ".md");
    // Add root files to knowledge results for simplicity
    results.results.knowledge.push(...rootResults);
    results.totalMatches += rootResults.reduce(
      (sum, r) => sum + r.matches.length,
      0
    );
  }

  // Search each area
  for (const area of searchAreas) {
    const areaResults = await searchInFiles(area.path, params.query, ".md");
    results.results[area.key].push(...areaResults);
    results.totalMatches += areaResults.reduce(
      (sum, r) => sum + r.matches.length,
      0
    );
  }

  return results;
}

/**
 * Format the search results for display
 */
export function formatSearchMemoryResult(result: SearchMemoryResult): string {
  const lines: string[] = [];

  lines.push("# Memory Search Results");
  lines.push("");
  lines.push(`**Query:** "${result.query}"`);
  lines.push(`**Scope:** ${result.scope}`);
  lines.push(`**Total Matches:** ${result.totalMatches}`);
  lines.push("");

  if (result.totalMatches === 0) {
    lines.push("No matches found.");
    return lines.join("\n");
  }

  // Format sessions results
  if (result.results.sessions.length > 0) {
    lines.push("## Sessions");
    lines.push("");
    for (const match of result.results.sessions) {
      lines.push(`### ${match.file}`);
      lines.push(`*Path: ${match.path}*`);
      lines.push("");
      for (const excerpt of match.matches.slice(0, 3)) {
        // Limit excerpts per file
        lines.push("```");
        lines.push(excerpt);
        lines.push("```");
        lines.push("");
      }
      if (match.matches.length > 3) {
        lines.push(`*...and ${match.matches.length - 3} more matches*`);
        lines.push("");
      }
    }
  }

  // Format decisions results
  if (result.results.decisions.length > 0) {
    lines.push("## Decisions");
    lines.push("");
    for (const match of result.results.decisions) {
      lines.push(`### ${match.file}`);
      lines.push(`*Path: ${match.path}*`);
      lines.push("");
      for (const excerpt of match.matches.slice(0, 3)) {
        lines.push("```");
        lines.push(excerpt);
        lines.push("```");
        lines.push("");
      }
      if (match.matches.length > 3) {
        lines.push(`*...and ${match.matches.length - 3} more matches*`);
        lines.push("");
      }
    }
  }

  // Format knowledge results
  if (result.results.knowledge.length > 0) {
    lines.push("## Knowledge");
    lines.push("");
    for (const match of result.results.knowledge) {
      lines.push(`### ${match.file}`);
      lines.push(`*Path: ${match.path}*`);
      lines.push("");
      for (const excerpt of match.matches.slice(0, 3)) {
        lines.push("```");
        lines.push(excerpt);
        lines.push("```");
        lines.push("");
      }
      if (match.matches.length > 3) {
        lines.push(`*...and ${match.matches.length - 3} more matches*`);
        lines.push("");
      }
    }
  }

  return lines.join("\n");
}
