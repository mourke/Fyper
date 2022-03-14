import Resolver

extension CoffeeMaker {
    
    convenience init() {
        let pump = Resolver.resolve(Pump.self)
		let heater = Resolver.resolve(Heater.self)
        self.init(pump: pump, heater: heater)
    }
}