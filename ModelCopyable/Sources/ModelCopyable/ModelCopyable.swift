
@attached(member, names: named(copy), named(Builder))
public macro Copyable<T>(_ component: T) = #externalMacro(module: "ModelCopyableMacros", type: "CopyableMacro")
