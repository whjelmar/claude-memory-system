import * as path from "path";
import { getMemoryPath, readFileSafe } from "../utils/file-helpers.js";

export interface ContextResult {
  currentContext: string | null;
  activePlan: string | null;
  hasContext: boolean;
  hasPlan: boolean;
  contextPath: string;
  planPath: string;
}

/**
 * Tool definition for memory_read_context
 */
export const readContextTool = {
  name: "memory_read_context",
  description:
    "Reads the current context and active plan from the memory system. Returns the contents of current_context.md and active_plan.md files, providing context about ongoing work and plans.",
  inputSchema: {
    type: "object" as const,
    properties: {},
    required: [],
  },
};

/**
 * Execute the read context tool
 */
export async function executeReadContext(): Promise<ContextResult> {
  const memoryPath = getMemoryPath();
  const contextPath = path.join(memoryPath, "current_context.md");
  const planPath = path.join(memoryPath, "active_plan.md");

  const currentContext = await readFileSafe(contextPath);
  const activePlan = await readFileSafe(planPath);

  return {
    currentContext,
    activePlan,
    hasContext: currentContext !== null,
    hasPlan: activePlan !== null,
    contextPath,
    planPath,
  };
}

/**
 * Format the result for display
 */
export function formatContextResult(result: ContextResult): string {
  const parts: string[] = [];

  parts.push("# Memory Context\n");

  if (result.hasContext) {
    parts.push("## Current Context");
    parts.push(`Source: ${result.contextPath}\n`);
    parts.push(result.currentContext || "");
    parts.push("");
  } else {
    parts.push("## Current Context");
    parts.push("No current context found. The memory system may not be initialized.\n");
  }

  if (result.hasPlan) {
    parts.push("## Active Plan");
    parts.push(`Source: ${result.planPath}\n`);
    parts.push(result.activePlan || "");
  } else {
    parts.push("## Active Plan");
    parts.push("No active plan found.\n");
  }

  return parts.join("\n");
}
