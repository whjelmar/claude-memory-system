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
  related_topics: string[];
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
 * Extract key terms from content for topic matching
 */
function extractKeyTerms(content: string): string[] {
  const terms: string[] = [];

  // Extract bold text
  const boldMatches = content.match(/\*\*([^*]+)\*\*/g);
  if (boldMatches) {
    terms.push(...boldMatches.map((m) => m.replace(/\*\*/g, "").toLowerCase()));
  }

  // Extract header content
  const headerMatches = content.match(/^##+ (.+)$/gm);
  if (headerMatches) {
    terms.push(
      ...headerMatches.map((m) => m.replace(/^##+ /, "").toLowerCase())
    );
  }

  // Extract capitalized phrases (potential proper nouns/concepts)
  const capitalMatches = content.match(/\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+\b/g);
  if (capitalMatches) {
    terms.push(...capitalMatches.map((m) => m.toLowerCase()));
  }

  return [...new Set(terms)];
}

/**
 * Calculate similarity between two strings using word overlap
 */
function calculateSimilarity(str1: string, str2: string): number {
  const words1 = str1.toLowerCase().split(/\s+/);
  const words2 = str2.toLowerCase().split(/\s+/);

  const set1 = new Set(words1);
  const set2 = new Set(words2);

  let intersection = 0;
  for (const word of set1) {
    if (set2.has(word)) {
      intersection++;
    }
  }

  const union = new Set([...words1, ...words2]).size;
  return union > 0 ? intersection / union : 0;
}

/**
 * Find related topics based on content analysis
 */
async function findRelatedTopics(
  knowledgePath: string,
  currentTopic: string,
  currentContent: string
): Promise<string[]> {
  const relatedTopics: Array<{ topic: string; score: number }> = [];
  const currentTerms = extractKeyTerms(currentContent);
  const currentSlug = currentTopic
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

  // Get all knowledge files
  const files = await listFiles(knowledgePath);
  const mdFiles = files.filter(
    (f) =>
      f.endsWith(".md") &&
      f.toLowerCase() !== "index.md" &&
      f.toLowerCase() !== "index.md"
  );

  for (const file of mdFiles) {
    const filePath = path.join(knowledgePath, file);
    const fileContent = await readFileSafe(filePath);

    if (!fileContent) continue;

    // Get topic name from first line
    const firstLine = fileContent.split("\n")[0] || "";
    const fileTopic = firstLine.replace(/^#+ /, "").trim();
    const fileSlug = file.replace(/\.md$/, "").toLowerCase();

    // Skip self
    if (fileSlug === currentSlug || fileTopic.toLowerCase() === currentTopic.toLowerCase()) {
      continue;
    }

    // Calculate relevance score
    let score = 0;

    // Check if topic name appears in content
    if (currentContent.toLowerCase().includes(fileTopic.toLowerCase())) {
      score += 0.5;
    }

    // Check if current topic appears in file content
    if (fileContent.toLowerCase().includes(currentTopic.toLowerCase())) {
      score += 0.5;
    }

    // Extract terms from file and check overlap
    const fileTerms = extractKeyTerms(fileContent);
    const termOverlap = currentTerms.filter((t) =>
      fileTerms.some((ft) => ft.includes(t) || t.includes(ft))
    ).length;
    score += termOverlap * 0.1;

    // Calculate content similarity
    const contentSimilarity = calculateSimilarity(currentContent, fileContent);
    score += contentSimilarity * 0.3;

    if (score > 0.1) {
      relatedTopics.push({ topic: fileTopic, score });
    }
  }

  // Sort by score and return top 5
  relatedTopics.sort((a, b) => b.score - a.score);
  return relatedTopics.slice(0, 5).map((t) => t.topic);
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

  // Find related topics
  const related_topics = await findRelatedTopics(
    knowledgePath,
    params.topic,
    params.content
  );

  return {
    knowledgeFile: filePath,
    created: isNew,
    updated: !isNew,
    indexUpdated,
    related_topics,
  };
}

/**
 * Format the result for display
 */
export function formatAddKnowledgeResult(result: AddKnowledgeResult): string {
  const action = result.created ? "Created" : "Updated";
  const lines = [
    `# Knowledge ${action} Successfully`,
    "",
    `**File:** ${result.knowledgeFile}`,
    `**Action:** ${action}`,
    `**Index Updated:** ${result.indexUpdated ? "Yes" : "No (already indexed)"}`,
    "",
  ];

  // Add related topics section
  if (result.related_topics && result.related_topics.length > 0) {
    lines.push("## Related Topics");
    lines.push("");
    lines.push("Consider linking to these existing knowledge files:");
    lines.push("");
    for (const topic of result.related_topics) {
      const slug = topic
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "");
      lines.push(`- [${topic}](./knowledge/${slug}.md)`);
    }
    lines.push("");
  }

  lines.push(
    `The knowledge has been ${action.toLowerCase()} in the memory system.`
  );

  return lines.join("\n");
}
