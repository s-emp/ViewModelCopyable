import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ModelCopyableMacros)
import ModelCopyableMacros

let testMacros: [String: Macro.Type] = [
    "Copyable": CopyableMacro.self,
]
#endif

final class ModelCopyableTests: XCTestCase {
    func testMacro() throws {
        #if canImport(ModelCopyableMacros)
        assertMacroExpansion(
            """
            extension ProfileView {
                @Copyable(ProfileView.self)
                public struct Model: Equatable {
                    /// Display name
                    @Semantic
                    public private(set) var name: NSAttributedString
                    /// Account status
                    public let status: Status
                    public let children: [Child]
                    public let action: ((UIView, Model) -> Void)?
            
                    public init(
                        name: NSAttributedString,
                        status: Status,
                        let children: [Child],
                        action: ((UIView, Model) -> Void)? = nil
                    ) {
                        self.name = name
                        self.status = status
                        self.children = children
                        self.action = action
                    }
                }
            }
            """,
            expandedSource: """
            extension ProfileView {
                public struct Model: Equatable {
                    /// Display name
                    @Semantic
                    public private(set) var name: NSAttributedString
                    /// Account status
                    public let status: Status
                    public let children: [Child]
                    public let action: ((UIView, Model) -> Void)?
            
                    public init(
                        name: NSAttributedString,
                        status: Status,
                        let children: [Child],
                        action: ((UIView, Model) -> Void)? = nil
                    ) {
                        self.name = name
                        self.status = status
                        self.children = children
                        self.action = action
                    }
            
                    public func copy(build: (inout Builder) -> Void) -> Self {
                        var builder = Builder(model: self)
                        build(&builder)
                        return .init(name: builder.name, status: builder.status, children: builder.children, action: builder.action)
                    }
            
                    public func copy<T>(_ keyPath: WritableKeyPath<Builder, T>, _ value: T) -> Self {
                        var builder = Builder(model: self)
                        builder[keyPath: keyPath] = value
                        return .init(name: builder.name, status: builder.status, children: builder.children, action: builder.action)
                    }
            
                    public struct Builder {
                        /// Display name
                        public var name: NSAttributedString
                        /// Account status
                        public var status: Status
                        public var children: [Child]
                        public var action: ((UIView, Model) -> Void)?
                        public init(model: ProfileView.Model) {
                            name = model.name
                            status = model.status
                            children = model.children
                            action = model.action
                        }
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
