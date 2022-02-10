extension CoffeeMaker {
    
    convenience init() {
        self.init(pump: Pump(), heater: Heater())
    }
}