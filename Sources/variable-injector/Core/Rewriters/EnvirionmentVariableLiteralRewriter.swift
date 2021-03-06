//
//  EnvironmentVariableLiteralRewriter.swift
//  VariableInjector
//
//  Created by Luciano Almeida on 02/11/18.
//

import Foundation
import SwiftSyntax

public class EnvironmentVariableLiteralRewriter: SyntaxRewriter {
    
    static let envVarPattern: String = "\"\\$\\(\\w+\\)\""
    
    public var ignoredLiteralValues: Set<String> = []
    
    private var environment: [String: String] = [:]
    
    public var logger: Logger?
    
    public init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.environment = environment
    }
    
    public convenience init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        ignoredLiteralValues: [String]) {
        self.init(environment: environment)
        self.ignoredLiteralValues = Set(ignoredLiteralValues)
    }
    
    override public func visit(_ token: TokenSyntax) -> Syntax {
        guard case .stringLiteral(let text) = token.tokenKind else { return token }
    
        //Matching ENV var pattern e.g. $(ENV_VAR)
        guard text.matches(regex: EnvironmentVariableLiteralRewriter.envVarPattern) else { return token }
        
        let envVar = extractTextEnvVariableName(text: text)
        
        guard shouldPerformSubstitution(for: envVar) else { return token }
        
        guard let envValue = environment[envVar] else {
            return token
        }
        logger?.log(message: "Injecting ENV_VAR: \(text), value: \(envValue)")
        return token.withKind(.stringLiteral("\"\(envValue)\""))
    }
    
    private func shouldPerformSubstitution(for text: String) -> Bool {
        return !ignoredLiteralValues.contains(text)
    }
    
    private func extractTextEnvVariableName(text: String) -> String {
        return String(text[text.index(text.startIndex, offsetBy: 3)..<text.index(text.endIndex, offsetBy: -2)])
    }
    
}
