
extension CopyableMacro {
    enum CopyError: Error, CustomStringConvertible {
        case notFoundComponentName
        case modelIsNotStruct
        
        var description: String {
            switch self {
            case .notFoundComponentName:
                return "Component name not found. Please provide a component name as an argument to the macro."
            case .modelIsNotStruct:
                return "Model is not a struct. Please use the macro with a struct declaration."
            }
        }
    }
}
