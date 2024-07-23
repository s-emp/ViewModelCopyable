import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CopyableMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else { throw CopyError.modelIsNotStruct }
        let componentName = try getComponentName(of: node)
        let variables = structDecl.memberBlock.members.compactMap { member in
            return member.decl.as(VariableDeclSyntax.self)
        }
        let copyFuncDeclSyntax = createCopyFunc(with: variables)
        let copyFuncWithKeyPathDeclSyntax = createCopyFuncWithKeyPath(with: variables)
        let builderStructDeclSyntax = try createBuilder(variables, componentName: componentName)
        return [copyFuncDeclSyntax, copyFuncWithKeyPathDeclSyntax, builderStructDeclSyntax]
    }
    
    static func getComponentName(of node: AttributeSyntax) throws -> String {
        guard
            let arguments = node.arguments?.as(LabeledExprListSyntax.self),
            let argument = arguments.first,
            let memberAccess = argument.expression.as(MemberAccessExprSyntax.self),
            let declExpr = memberAccess.base?.as(DeclReferenceExprSyntax.self)
        else { throw CopyError.notFoundComponentName }
        return declExpr.baseName.text
    }
    
    static func createCopyFunc(with variables: [VariableDeclSyntax]) -> DeclSyntax {
        let identifiers = variables.compactMap { variable in
            variable.bindings.first?.as(PatternBindingSyntax.self)?.pattern.as(IdentifierPatternSyntax.self)?.identifier
        }
        var returnStr: String = ""
        identifiers.forEach { tokenSyntax in
            returnStr.append("\(tokenSyntax): builder.\(tokenSyntax),")
        }
        if !returnStr.isEmpty { returnStr.removeLast() }
        return DeclSyntax(
            try! FunctionDeclSyntax(
                "public func copy(build: (inout Builder) -> Void) -> Self",
                bodyBuilder: {
                    "var builder = Builder(model: self)"
                    "build(&builder)"
                    "return .init(\(raw: returnStr))"
                }
            )
        )
    }
    
    static func createCopyFuncWithKeyPath(with variables: [VariableDeclSyntax]) -> DeclSyntax {
        let identifiers = variables.compactMap { variable in
            variable.bindings.first?.as(
                PatternBindingSyntax.self
            )?.pattern.as(IdentifierPatternSyntax.self)?.identifier
        }
        var returnStr: String = ""
        identifiers.forEach { tokenSyntax in
            returnStr.append("\(tokenSyntax): builder.\(tokenSyntax),")
        }
        if !returnStr.isEmpty { returnStr.removeLast() }
        return DeclSyntax(
            try! FunctionDeclSyntax(
                "public func copy<T>(_ keyPath: WritableKeyPath<Builder, T>, _ value: T) -> Self",
                bodyBuilder: {
                    "var builder = Builder(model: self)"
                    "builder[keyPath: keyPath] = value"
                    "return .init(\(raw: returnStr))"
                }
            )
        )
    }
    
    static func createBuilder(_ variables: [VariableDeclSyntax], componentName: String) throws -> DeclSyntax {
        let comments = variables.map {
            let comment = $0.leadingTrivia.compactMap { triviaPiece in
                switch triviaPiece {
                case let .docLineComment(comment): return comment
                default: return nil
                }
            }.first ?? ""
            return comment
        }
        let memberBindings = variables.map { $0.bindings.first }
        var params: [(name: TokenSyntax, type: TokenSyntax, comment: String)] = []
        for (index, binding) in memberBindings.enumerated() {
            guard
                let paramName = binding?.pattern.as(IdentifierPatternSyntax.self)?.identifier,
                let paramType = binding?.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name
            else { continue }
            params.append((name: paramName, type: paramType, comment: comments[index]))
        }
        let builder = try StructDeclSyntax("public struct Builder") {
            for param in params {
                """
                \(raw: param.comment)
                public var \(param.name): \(param.type)
                """
            }
            try InitializerDeclSyntax("public init(model: \(raw: componentName).Model)") {
                for param in params {
                    """
                    \(param.name) = model.\(param.name)
                    """
                }
            }
        }
        return DeclSyntax(builder)
    }
}

@main
struct ModelCopyablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CopyableMacro.self,
    ]
}
