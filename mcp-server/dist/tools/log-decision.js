import * as path from "path";
import { getMemoryPath, ensureDir, writeFileSafe, getNextNumber, getDateString, } from "../utils/file-helpers.js";
/**
 * Tool definition for memory_log_decision
 */
export const logDecisionTool = {
    name: "memory_log_decision",
    description: "Logs a significant decision to the memory system. Creates an auto-numbered decision record with context, options considered (with pros/cons), the final decision, and expected consequences.",
    inputSchema: {
        type: "object",
        properties: {
            title: {
                type: "string",
                description: "Brief title describing the decision",
            },
            context: {
                type: "string",
                description: "Background context explaining why this decision was needed",
            },
            options: {
                type: "array",
                items: {
                    type: "object",
                    properties: {
                        name: {
                            type: "string",
                            description: "Name of the option",
                        },
                        pros: {
                            type: "array",
                            items: { type: "string" },
                            description: "Advantages of this option",
                        },
                        cons: {
                            type: "array",
                            items: { type: "string" },
                            description: "Disadvantages of this option",
                        },
                    },
                    required: ["name", "pros", "cons"],
                },
                description: "List of options that were considered",
            },
            decision: {
                type: "string",
                description: "The final decision that was made",
            },
            consequences: {
                type: "string",
                description: "Expected consequences and implications of this decision",
            },
        },
        required: ["title", "context", "options", "decision", "consequences"],
    },
};
/**
 * Generate the decision file content
 */
function generateDecisionContent(params, decisionNumber, dateString) {
    const lines = [];
    lines.push(`# Decision ${decisionNumber.toString().padStart(3, "0")}: ${params.title}`);
    lines.push("");
    lines.push(`**Date:** ${dateString}`);
    lines.push(`**Status:** Decided`);
    lines.push("");
    lines.push("## Context");
    lines.push(params.context);
    lines.push("");
    lines.push("## Options Considered");
    lines.push("");
    for (let i = 0; i < params.options.length; i++) {
        const option = params.options[i];
        lines.push(`### Option ${i + 1}: ${option.name}`);
        lines.push("");
        lines.push("**Pros:**");
        for (const pro of option.pros) {
            lines.push(`- ${pro}`);
        }
        lines.push("");
        lines.push("**Cons:**");
        for (const con of option.cons) {
            lines.push(`- ${con}`);
        }
        lines.push("");
    }
    lines.push("## Decision");
    lines.push(params.decision);
    lines.push("");
    lines.push("## Consequences");
    lines.push(params.consequences);
    lines.push("");
    return lines.join("\n");
}
/**
 * Execute the log decision tool
 */
export async function executeLogDecision(params) {
    const memoryPath = getMemoryPath();
    const decisionsPath = path.join(memoryPath, "decisions");
    const dateString = getDateString();
    // Ensure directory exists
    await ensureDir(decisionsPath);
    // Get next decision number
    const decisionNumber = await getNextNumber(decisionsPath, "decision-");
    // Create decision file
    const paddedNumber = decisionNumber.toString().padStart(3, "0");
    const decisionFileName = `decision-${paddedNumber}-${slugify(params.title)}.md`;
    const decisionFilePath = path.join(decisionsPath, decisionFileName);
    const decisionContent = generateDecisionContent(params, decisionNumber, dateString);
    await writeFileSafe(decisionFilePath, decisionContent);
    return {
        decisionFile: decisionFilePath,
        decisionNumber,
        title: params.title,
    };
}
/**
 * Convert a title to a URL-friendly slug
 */
function slugify(text) {
    return text
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "")
        .slice(0, 50);
}
/**
 * Format the result for display
 */
export function formatLogDecisionResult(result) {
    return [
        "# Decision Logged Successfully",
        "",
        `**Decision Number:** ${result.decisionNumber}`,
        `**Title:** ${result.title}`,
        `**File:** ${result.decisionFile}`,
        "",
        "The decision has been recorded in the memory system.",
    ].join("\n");
}
//# sourceMappingURL=log-decision.js.map