import ModelCopyable

class ComponentView { }

extension ComponentView {
    @Copyable(ComponentView.self)
    struct Model {
        /// Name
        let name: String
        /// Age
        let age: Int
    }
}
