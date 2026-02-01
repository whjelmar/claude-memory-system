export interface DecisionOption {
    name: string;
    pros: string[];
    cons: string[];
}
export interface LogDecisionParams {
    title: string;
    context: string;
    options: DecisionOption[];
    decision: string;
    consequences: string;
}
export interface LogDecisionResult {
    decisionFile: string;
    decisionNumber: number;
    title: string;
}
/**
 * Tool definition for memory_log_decision
 */
export declare const logDecisionTool: {
    name: string;
    description: string;
    inputSchema: {
        type: "object";
        properties: {
            title: {
                type: string;
                description: string;
            };
            context: {
                type: string;
                description: string;
            };
            options: {
                type: string;
                items: {
                    type: string;
                    properties: {
                        name: {
                            type: string;
                            description: string;
                        };
                        pros: {
                            type: string;
                            items: {
                                type: string;
                            };
                            description: string;
                        };
                        cons: {
                            type: string;
                            items: {
                                type: string;
                            };
                            description: string;
                        };
                    };
                    required: string[];
                };
                description: string;
            };
            decision: {
                type: string;
                description: string;
            };
            consequences: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
/**
 * Execute the log decision tool
 */
export declare function executeLogDecision(params: LogDecisionParams): Promise<LogDecisionResult>;
/**
 * Format the result for display
 */
export declare function formatLogDecisionResult(result: LogDecisionResult): string;
//# sourceMappingURL=log-decision.d.ts.map