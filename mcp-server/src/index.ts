#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ErrorCode,
  McpError,
} from "@modelcontextprotocol/sdk/types.js";

import {
  readContextTool,
  executeReadContext,
  formatContextResult,
} from "./tools/read-context.js";
import {
  saveSessionTool,
  executeSaveSession,
  formatSaveSessionResult,
  SaveSessionParams,
} from "./tools/save-session.js";
import {
  logDecisionTool,
  executeLogDecision,
  formatLogDecisionResult,
  LogDecisionParams,
} from "./tools/log-decision.js";
import {
  addKnowledgeTool,
  executeAddKnowledge,
  formatAddKnowledgeResult,
  AddKnowledgeParams,
} from "./tools/add-knowledge.js";
import {
  searchMemoryTool,
  executeSearchMemory,
  formatSearchMemoryResult,
  SearchMemoryParams,
} from "./tools/search-memory.js";

/**
 * Claude Memory MCP Server
 *
 * Provides memory tools for persistent context across Claude sessions.
 *
 * Usage:
 *   node dist/index.js [project-root]
 *
 * Or set MEMORY_PROJECT_ROOT environment variable.
 */

// Create the MCP server
const server = new Server(
  {
    name: "claude-memory-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      readContextTool,
      saveSessionTool,
      logDecisionTool,
      addKnowledgeTool,
      searchMemoryTool,
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "memory_read_context": {
        const result = await executeReadContext();
        return {
          content: [
            {
              type: "text",
              text: formatContextResult(result),
            },
          ],
        };
      }

      case "memory_save_session": {
        const params = args as unknown as SaveSessionParams;

        // Validate required parameters
        if (!params.summary || typeof params.summary !== "string") {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'summary' parameter"
          );
        }
        if (!Array.isArray(params.work_completed)) {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'work_completed' parameter (must be an array)"
          );
        }
        if (!Array.isArray(params.decisions)) {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'decisions' parameter (must be an array)"
          );
        }
        if (!Array.isArray(params.discoveries)) {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'discoveries' parameter (must be an array)"
          );
        }
        if (!Array.isArray(params.next_steps)) {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'next_steps' parameter (must be an array)"
          );
        }

        const result = await executeSaveSession(params);
        return {
          content: [
            {
              type: "text",
              text: formatSaveSessionResult(result),
            },
          ],
        };
      }

      case "memory_log_decision": {
        const params = args as unknown as LogDecisionParams;

        // Validate required parameters
        if (!params.title || typeof params.title !== "string") {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'title' parameter"
          );
        }
        if (!params.context || typeof params.context !== "string") {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'context' parameter"
          );
        }
        if (!Array.isArray(params.options)) {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'options' parameter (must be an array)"
          );
        }
        if (!params.decision || typeof params.decision !== "string") {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'decision' parameter"
          );
        }
        if (!params.consequences || typeof params.consequences !== "string") {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'consequences' parameter"
          );
        }

        const result = await executeLogDecision(params);
        return {
          content: [
            {
              type: "text",
              text: formatLogDecisionResult(result),
            },
          ],
        };
      }

      case "memory_add_knowledge": {
        const params = args as unknown as AddKnowledgeParams;

        // Validate required parameters
        if (!params.topic || typeof params.topic !== "string") {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'topic' parameter"
          );
        }
        if (!params.content || typeof params.content !== "string") {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'content' parameter"
          );
        }

        const result = await executeAddKnowledge(params);
        return {
          content: [
            {
              type: "text",
              text: formatAddKnowledgeResult(result),
            },
          ],
        };
      }

      case "memory_search": {
        const params = args as unknown as SearchMemoryParams;

        // Validate required parameters
        if (!params.query || typeof params.query !== "string") {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'query' parameter"
          );
        }
        if (
          !params.scope ||
          !["sessions", "decisions", "knowledge", "all"].includes(params.scope)
        ) {
          throw new McpError(
            ErrorCode.InvalidParams,
            "Missing or invalid 'scope' parameter (must be 'sessions', 'decisions', 'knowledge', or 'all')"
          );
        }

        const result = await executeSearchMemory(params);
        return {
          content: [
            {
              type: "text",
              text: formatSearchMemoryResult(result),
            },
          ],
        };
      }

      default:
        throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
    }
  } catch (error) {
    if (error instanceof McpError) {
      throw error;
    }

    // Handle unexpected errors
    const message = error instanceof Error ? error.message : String(error);
    throw new McpError(
      ErrorCode.InternalError,
      `Tool execution failed: ${message}`
    );
  }
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);

  // Log startup info to stderr (stdout is reserved for MCP protocol)
  console.error("Claude Memory MCP Server started");
  console.error(`Project root: ${process.env.MEMORY_PROJECT_ROOT || process.argv[2] || process.cwd()}`);
}

main().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});
