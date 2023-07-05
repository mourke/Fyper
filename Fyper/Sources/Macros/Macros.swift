

@attached(peer, names: overloaded)
public macro Inject(args: (Int, Int) -> Int) = #externalMacro(module: "MacrosImplementation", type: "InjectMacro")

@attached(peer, names: overloaded)
public macro Inject(args: Int) = #externalMacro(module: "MacrosImplementation", type: "InjectMacro")
