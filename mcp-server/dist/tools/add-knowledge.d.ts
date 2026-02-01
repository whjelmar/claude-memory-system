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
export declare const addKnowledgeTool: {
    name: string;
    description: string;
    inputSchema: {
        type: "object";
        properties: {
            topic: {
                type: string;
                description: string;
            };
            content: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
/**
 * Execute the add knowledge tool
 */
export declare function executeAddKnowledge(params: AddKnowledgeParams): Promise<AddKnowledgeResult>;
/**
 * Format the result for display
 */
export declare function formatAddKnowledgeResult(result: AddKnowledgeResult): string;
//# sourceMappingURL=add-knowledge.d.ts.map