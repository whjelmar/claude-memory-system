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
export declare const searchMemoryTool: {
    name: string;
    description: string;
    inputSchema: {
        type: "object";
        properties: {
            query: {
                type: string;
                description: string;
            };
            scope: {
                type: string;
                enum: string[];
                description: string;
            };
        };
        required: string[];
    };
};
/**
 * Execute the search memory tool
 */
export declare function executeSearchMemory(params: SearchMemoryParams): Promise<SearchMemoryResult>;
/**
 * Format the search results for display
 */
export declare function formatSearchMemoryResult(result: SearchMemoryResult): string;
//# sourceMappingURL=search-memory.d.ts.map