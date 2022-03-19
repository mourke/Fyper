import Shared
import Resolver

extension DetailViewModel {
    
    init(name: String, date: Date) {
        let logger = Resolver.resolve(Logger.self)
		let authenticator = Resolver.resolve(Authenticator.self)
		let factory = Resolver.resolve(Factory.self)
		let clock = Resolver.resolve(Clock.self)
        self.init(logger: logger, authenticator: authenticator, factory: factory, clock: clock, name: name, date: date)
    }
}

extension MasterViewModel {
    
    init(buttonTitle: String) {
        let tracker = Resolver.resolve(Tracker.self)
        self.init(tracker: tracker, buttonTitle: buttonTitle)
    }
}