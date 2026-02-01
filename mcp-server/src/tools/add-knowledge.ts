import * as path from "path";
import {
  getMemoryPath,
  ensureDir,
  writeFileSafe,
  readFileSafe,
  getDateString,
  listFiles,
} from "../utils/file-helpers.js";

export interface AddKnowledgeParams {
  topic: string;
  content: string;
}

export interface AddKnowledgeResult {
  knowledgeFile: string;
  created: boolean;
  updated: boolean;
  indexUpdated: boolean;
}

/**
 * Tool definition for memory_add_knowledge
 */
export const addKnowledgeTool = {
  name: "memory_add_knowledge",
  description:
    "Adds or updates knowledge in the memory system. Creates a knowledge file for the given topic, or appends to an existing one. Updates the knowledge index if it exists.",
  inputSchema: {
    type: "object" as const,
    properties: {
      topic: {
        type: "string",
        description:
          "The topic name for the knowledge (will be used as filename)",
      },
      content: {
        type: "string",
        description: "The knowledge content to add (markdown format supported)",
      },
    },
    required: ["topic", "content"],
  },
};

/**
 * Convert a topic to a filename-friendly slug
 */
function topicToFilename(topic: string): string {
  return (
    topic
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "") + ".md"
  );
}

/**
 * Generate new knowledge file content
 */
function generateNewKnowledgeContent(
  topic: string,
  content: string,
  dateString: string
): string {
  return [
    `# ${topic}`,
    "",
    `**Created:** ${dateString}`,
    `**Last Updated:** ${dateString}`,
    "",
    "---",
    "",
    content,
    "",
  ].join("\n");
}

/**
 * Append to existing knowledge file content
 */
function appendToKnowledgeContent(
  existingContent: string,
  newContent: string,
  dateString: string
): string {
  // Update the "Last Updated" line if it exists
  let updated = existingContent.replace(
    /\*\*Last Updated:\*\* .+/,
    `**Last Updated:** ${dateString}`
  );

  // Append the new content
  updated += `\n---\n\n## Update (${dateString})\n\n${newContent}\n`;

  return updated;
}

/**
 * Update the knowledge index file
 */
async function updateKnowledgeIndex(
  knowledgePath: string,
  topic: string,
  filename: string,
  isNew: boolean
): Promise<boolean> {
  const indexPath = path.join(knowledgePath, "index.md");
  let indexContent = await readFileSafe(indexPath);

  if (indexContent === null) {
    // Create new index
    indexContent = [
      "# Knowledge Index",
      "",
      "This index lists all knowledge files in the memory system.",
      "",
      "## Topics",
      "",
      `- [${topic}](./${filename})`,
      "",
    ].join("\n");
    await writeFileSafe(indexPath, indexContent);
    return true;
  }

  // Check if topic already in index
  if (indexContent.includes(`[${topic}]`)) {
    return false; // Already indexed
  }

  // Add to index (before the last empty line)
  const lines = indexContent.split("\n");
  const lastNonEmpty = lines.length - 1;
  lines.splice(lastNonEmpty, 0, `- [${topic}](./${filename})`);
  await writeFileSafe(indexPath, lines.join("\n"));
  return true;
}

/**
 * Execute the add knowledge tool
 */
export async function executeAddKnowledge(
  params: AddKnowledgeParams
): Promise<AddKnowledgeResult> {
  const memoryPath = getMemoryPath();
  const knowledgePath = path.join(memoryPath, "knowledge");
  const dateString = getDateString();

  // Ensure directory exists
  await ensureDir(knowledgePath);

  // Generate filename and path
  const filename = topicToFilename(params.topic);
  const filePath = path.join(knowledgePath, filename);

  // Check if file exists
  const existingContent = await readFileSafe(filePath);
  const isNew = existingContent === null;

  let finalContent: string;
  if (isNew) {
    // Create new file
    finalContent = generateNewKnowledgeContent(
      params.topic,
      params.content,
      dateString
    );
  } else {
    // Append to existing file
    finalContent = appendToKnowledgeContent(
      existingContent,
      params.content,
      dateString
    );
  }

  await writeFileSafe(filePath, finalContent);

  // Update index
  const indexUpdated = await updateKnowledgeIndex(
    knowledgePath,
    params.topic,
    filename,
    isNew
  );

  return {
    knowledgeFile: filePath,
    created: isNew,
    updated: !isNew,
    indexUpdated,
  };
}

/**
 * Format the result for display
 */
export function formatAddKnowledgeResult(result: AddKnowledgeResult): string {
  const action = result.created ? "Created" : "Updated";
  return [
    `# Knowledge ${action} Successfully`,
    "",
    `**File:** ${result.knowledgeFile}`,
    `**Action:** ${action}`,
    `**Index Updated:** ${result.indexUpdated ? "Yes" : "No (already indexed)"}`,
    "",
    `The knowledge has been ${action.toLowerCase()} in the memory system.`,
  ].join("\n");
}
