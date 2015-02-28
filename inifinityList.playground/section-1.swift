// Playground - noun: a place where people can play

import Foundation

enum List<T> {
    case Cons(T, () -> List<T>)
    case Nil
}


func cons<T>(value: T, list: List<T>) -> List<T> {
    return List.Cons(value, { list })
}

func lazyCons<T>(value: T, f: () -> List<T>) -> List<T> {
    return List.Cons(value, f)
}

extension List {
    var car: T? {
        switch self {
        case let .Cons(car, cdr):
            return car
        case .Nil:
            return nil
        }
    }
    var cdr: List<T> {
        switch self {
        case let .Cons(car, cdr):
            return cdr()
        case .Nil:
            return .Nil
        }
    }
}

extension List : SequenceType {
    func generate() -> GeneratorOf<T> {
        var list = self
        return GeneratorOf {
            let value = list.car
            list = list.cdr
            return value
        }
    }
    var array: [T] {
        var r = [T]()
        for n in self {
            r += [n]
        }
        return r
    }
}

extension List {
    func take(n: Int) -> List<T> {
        if n > 0 {
            if let v = self.car {
                return lazyCons(v) { self.cdr.take(n - 1) }
            }
        }
        return .Nil
    }
    
    func skip(n: Int) -> List<T> {
        if n > 0 {
            if let v = self.car {
                return self.cdr.skip(n - 1)
            }
        }
        return self
    }
    
    func _repeat(origin: List<T>) -> List<T> {
        if let v = self.car {
            return lazyCons(v) { self.cdr._repeat(origin) }
        }
        return origin._repeat(origin)
    }
    var repeat: List<T> {
        return self._repeat(self)
    }
    func _repeat(n: Int, _ origin: List<T>) -> List<T> {
        if n <= 0 {
            return .Nil
        }
        if let v = self.car {
            return lazyCons(v) { self.cdr._repeat(n, origin) }
        }
        return origin._repeat(n - 1, origin)
    }
    func repeat(n: Int) -> List<T> {
        return self._repeat(n, self)
    }

    func map<U>(f: T -> U) -> List<U> {
        if let car = self.car {
            return lazyCons(f(car)) { self.cdr.map(f) }
        }
        return .Nil
    }
    
    func filter(f: T -> Bool) -> List<T> {
        if let car = self.car {
            if f(car) {
                return lazyCons(car) { self.cdr.filter(f) }
            } else {
                return self.cdr.filter(f)
            }
        }
        return .Nil
    }
    func reduce<R>(var initial: R, combine: (R, T) -> R) -> R {
        for value in self {
            initial = combine(initial, value)
        }
        return initial
    }
}

func +<T>(a: List<T>, b: List<T>) -> List<T> {
    if let v = a.car {
        return lazyCons(v) { a.cdr + b }
    }
    return b
}

func infinity<T>(v: T, f: T -> T) -> List<T> {
    return lazyCons(v) { infinity(f(v), f) }
}

println("-- natural number --")

let natural = infinity(1){ $0 + 1 }
for n in natural.take(15) {
    println(n)
}

println("-- odd number --")

let odd = infinity(1){ $0 + 2 }
for n in odd.take(15) {
    println(n)
}

println("-- repeat --")
for n in infinity(0, { $0 + 1 }).take(3).repeat(4) {
    println(n)
}

println("-- combine --")
for n in (infinity(0){ $0 + 1 }.take(3) + infinity(3){ $0 - 1 }.take(3)).repeat.take(20) {
    println(n)
}


println("-- fibonacci number --")
func fibonacci(a: Int64, b: Int64) -> List<Int64> {
    return lazyCons(a) { fibonacci(b, a + b) }
}

for n in fibonacci(0, 1).take(15) {
    println(n)
}

println("-- xorshift --")
func xorshift(var x: UInt32, var y: UInt32, var z: UInt32, var w: UInt32) -> List<UInt32> {
    var t = x ^ (x << 11)
    x = y
    y = z
    z = w
    w = (w ^ (w >> 19)) ^ (t ^ (t >> 8))
    return lazyCons(w) { xorshift(x, y, z, w) }
}

for n in xorshift(24903412, 53346, 34, 24).take(30).map({$0 % 10}) {
    println(n)
}

println("-- map --")
for n in natural.take(10).map({ $0 * $0 }) {
    println(n)
}

println("-- filter --")
for n in natural.take(10).filter({ $0 % 2 == 0 }) {
    println(n)
}

println("-- reduce --")
println(natural.take(10).reduce(0, combine: { $0 + $1 }))

println("-- newton sqrt --")
func newton_sqrt(x: Double, a: Double) -> List<Double> {
    let f = { x in (x + a / x) * 0.5 }
    return lazyCons(x) { newton_sqrt(f(x), a) }
}

for n in newton_sqrt(2.0, 2.0).take(6) {
    println(n)
}

println("-- Napier's constant --")
func napiers_constant(n: Double) -> List<Double> {
    let f = { t in pow(1.0 + t, 1.0 / t) }
    return lazyCons(f(n)) { napiers_constant(n * 0.5) }
}

for n in napiers_constant(1.0).take(50) {
    println(n)
}

