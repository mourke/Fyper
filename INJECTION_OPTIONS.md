There are two main options of how to pass dependencies down to the class once the calling graph has been built.

## Option 1

- The user specifies how the 'instance to be injected' is to be built.
- Properties are generated for every class in the calling graph using extensions.
- These properties are stored using Objective-C associated objects. They also are named with prefixing double underscores so they are hidden from Xcode's code completion.
- Convenience initialisers are generated with the exact same signature as the designated initialiser of the class but with the injected values added in.

### Pros:

- Never ambiguous (basically doing it manually but hiding the ugly code)

### Cons:

- Complex
- Classes are cluttered with references to unused objects anyway
- Issues when two classes in the calling graph need the same variable injected.

## Option 2

- Basically a mixture between Resolver and Needle.
- The user injects objects somewhere in the calling graph hierarchy.
- Fyper checks that it has been injected anywhere in the calling graph.
- If it has, an extension for the class that needs the injected variable is generated with a convenience initialiser that has the exact same signature as the designated initialiser of the class but without the variables that are to be injected.
- Inside the initialiser, the injected variable will be obtained from the pool and passed to the initialiser.

### Pros:

- Simplest to implement˛


### Cons:

- Only one object of type x can be injected per calling hierarchy as there will be no distinction.
- Injection still done at runtime.
