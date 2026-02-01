import * as path from "path";
import {
  getMemoryPath,
  ensureDir,
  writeFileSafe,
  readFileSafe,
  getTimestamp,
  getDateString,
} from "../utils/file-helpers.js";

export interface SaveSessionParams {
  summary: string;
  work_completed: string[];
  decisions: string[];
  discoveries: string[];
  next_steps: string[];
}

export interface SaveSessionResult {
  sessionFile: string;
  contextUpdated: boolean;
  timestamp: string;
}

/**
 * Tool definition for memory_save_session
 */
export const saveSessionTool = {
  name: "memory_save_session",
  description:
    "Saves the current session to memory. Creates a timestamped session file with work completed, decisions made, discoveries, and next steps. Also updates the current_context.md file.",
  inputSchema: {
    type: "object" as const,
    properties: {
      summary: {
        type: "string",
        description: "Brief summary of what was accomplished in this session",
      },
      work_completed: {
        type: "array",
        items: { type: "string" },
        description: "List of tasks or items completed during the session",
      },
      decisions: {
        type: "array",
        items: { type: "string" },
        description: "Key decisions made during the session",
      },
      discoveries: {
        type: "array",
        items: { type: "string" },
        description: "Important discoveries or learnings from the session",
      },
      next_steps: {
        type: "array",
        items: { type: "string" },
        description: "Recommended next steps or tasks to continue with",
      },
    },
    required: ["summary", "work_completed", "decisions", "discoveries", "next_steps"],
  },
};

/**
 * Generate the session file content
 */
function generateSessionContent(params: SaveSessionParams, timestamp: string): string {
  const lines: string[] = [];

  lines.push(`# Session: ${timestamp}`);
  lines.push("");
  lines.push("## Summary");
  lines.push(params.summary);
  lines.push("");

  lines.push("## Work Completed");
  if (params.work_completed.length > 0) {
    for (const item of params.work_completed) {
      lines.push(`- ${item}`);
    }
  } else {
    lines.push("- No items recorded");
  }
  lines.push("");

  lines.push("## Decisions Made");
  if (params.decisions.length > 0) {
    for (const item of params.decisions) {
      lines.push(`- ${item}`);
    }
  } else {
    lines.push("- No decisions recorded");
  }
  lines.push("");

  lines.push("## Discoveries");
  if (params.discoveries.length > 0) {
    for (const item of params.discoveries) {
      lines.push(`- ${item}`);
    }
  } else {
    lines.push("- No discoveries recorded");
  }
  lines.push("");

  lines.push("## Next Steps");
  if (params.next_steps.length > 0) {
    for (const item of params.next_steps) {
      lines.push(`- [ ] ${item}`);
    }
  } else {
    lines.push("- No next steps recorded");
  }
  lines.push("");

  return lines.join("\n");
}

/**
 * Generate updated context content
 */
function generateContextContent(params: SaveSessionParams, timestamp: string): string {
  const lines: string[] = [];

  lines.push("# Current Context");
  lines.push("");
  lines.push(`Last Updated: ${timestamp}`);
  lines.push("");

  lines.push("## Recent Session Summary");
  lines.push(params.summary);
  lines.push("");

  lines.push("## Current State");
  lines.push("### Completed Work");
  if (params.work_completed.length > 0) {
    for (const item of params.work_completed) {
      lines.push(`- [x] ${item}`);
    }
  }
  lines.push("");

  lines.push("### Active Decisions");
  if (params.decisions.length > 0) {
    for (const item of params.decisions) {
      lines.push(`- ${item}`);
    }
  }
  lines.push("");

  lines.push("### Key Discoveries");
  if (params.discoveries.length > 0) {
    for (const item of params.discoveries) {
      lines.push(`- ${item}`);
    }
  }
  lines.push("");

  lines.push("## Pending Tasks");
  if (params.next_steps.length > 0) {
    for (const item of params.next_steps) {
      lines.push(`- [ ] ${item}`);
    }
  }
  lines.push("");

  return lines.join("\n");
}

/**
 * Execute the save session tool
 */
export async function executeSaveSession(
  params: SaveSessionParams
): Promise<SaveSessionResult> {
  const memoryPath = getMemoryPath();
  const sessionsPath = path.join(memoryPath, "sessions");
  const timestamp = getTimestamp();
  const dateString = getDateString();

  // Ensure directories exist
  await ensureDir(sessionsPath);

  // Create session file
  const sessionFileName = `session-${timestamp}.md`;
  const sessionFilePath = path.join(sessionsPath, sessionFileName);
  const sessionContent = generateSessionContent(params, timestamp);
  await writeFileSafe(sessionFilePath, sessionContent);

  // Update current context
  const contextPath = path.join(memoryPath, "current_context.md");
  const contextContent = generateContextContent(params, timestamp);
  await writeFileSafe(contextPath, contextContent);

  return {
    sessionFile: sessionFilePath,
    contextUpdated: true,
    timestamp,
  };
}

/**
 * Format the result for display
 */
export function formatSaveSessionResult(result: SaveSessionResult): string {
  return [
    "# Session Saved Successfully",
    "",
    `**Timestamp:** ${result.timestamp}`,
    `**Session File:** ${result.sessionFile}`,
    `**Context Updated:** ${result.contextUpdated ? "Yes" : "No"}`,
    "",
    "The session has been recorded and the current context has been updated.",
  ].join("\n");
}
