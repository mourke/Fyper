public enum ComponentScope {
	case `public`
	case `internal`
}

/// 
/// Marks the data structure as reusable. A reusable type is one that is re-created every time it is a dependency of another type.
///
/// - Parameter exposeAs:	The protocol that this type will be abstracted to in the container. The type must conform to this protocol.
/// - Parameter scope:		The access scope that the builder function will have in the container.
///
@attached(member)
public macro Reusable(exposeAs: Any? = nil, scope: ComponentScope = .internal) = #externalMacro(module: "MacrosImplementation", type: "ComponentMacro")

///
/// Marks the data structure as a reusable singleton. A singleton type is one that is created once when its container is instantiated, and may be
/// shared between multiple instances. These instances should be thread safe.
///
/// - Parameter exposeAs:	The protocol that this type will be abstracted to in the container. The type must conform to this protocol.
/// - Warning: It is a programmer error to attach this declaration to a value type, as they are pass-by-copy by design. This macro is designed
/// to decorate **heap-allocated types** (classes, actors and non-copyable structs).
///
@attached(member)
public macro Singleton(exposeAs: Any? = nil) = #externalMacro(module: "MacrosImplementation", type: "ComponentMacro")
