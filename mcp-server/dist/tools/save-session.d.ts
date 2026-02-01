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
export declare const saveSessionTool: {
    name: string;
    description: string;
    inputSchema: {
        type: "object";
        properties: {
            summary: {
                type: string;
                description: string;
            };
            work_completed: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
            decisions: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
            discoveries: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
            next_steps: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
        };
        required: string[];
    };
};
/**
 * Execute the save session tool
 */
export declare function executeSaveSession(params: SaveSessionParams): Promise<SaveSessionResult>;
/**
 * Format the result for display
 */
export declare function formatSaveSessionResult(result: SaveSessionResult): string;
//# sourceMappingURL=save-session.d.ts.map