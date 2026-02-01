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
export declare const readContextTool: {
    name: string;
    description: string;
    inputSchema: {
        type: "object";
        properties: {};
        required: never[];
    };
};
/**
 * Execute the read context tool
 */
export declare function executeReadContext(): Promise<ContextResult>;
/**
 * Format the result for display
 */
export declare function formatContextResult(result: ContextResult): string;
//# sourceMappingURL=read-context.d.ts.map