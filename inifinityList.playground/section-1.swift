// Playground - noun: a place where people can play

import Foundation

enum List<T> {
    case Cons(T, () -> List<T>)
    case Nil
}

func cons<T>(value: T, list: List<T>) -> List<T> {
    return List.Cons(value) { list }
}

func one<T>(value: T) -> List<T> {
    return cons(value, .Nil)
}
func none<T>() -> List<T> {
    return .Nil
}
func lazyCons<T>(value: T, f: () -> List<T>) -> List<T> {
    return List.Cons(value, f)
}

extension List {
    var car: T? {
        switch self {
        case let .Cons(car, _):
            return car
        case .Nil:
            return nil
        }
    }
    var cdr: List<T> {
        switch self {
        case let .Cons(_, cdr):
            return cdr()
        case .Nil:
            return .Nil
        }
    }
}

struct ListGenerator<T> : GeneratorType {
    typealias Element = T
    
    init(_ list: List<T>) {
        _list = list
    }
    
    mutating func next() -> Element? {
        let car = _list.car
        _list = _list.cdr
        return car
    }
    var _list: List<T>
}

extension List : SequenceType {
    func generate() -> ListGenerator<T> {
        return ListGenerator(self)
    }
}
extension List {
    var toArray: [T] {
        var r = [T]()
        for n in self {
            r += [n]
        }
        return r
    }
}
extension Array {
    var toList: List<T> {
        var list = List<T>.Nil
        for value in self.reverse() {
            list = cons(value, list)
        }
        return list
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
    
    func drop(n: Int) -> List<T> {
        if n > 0 {
            if let v = self.car {
                return self.cdr.drop(n - 1)
            }
        }
        return self
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
    
    var reverse: List<T> {
        if let car = self.car {
            return self.cdr.reverse + one(car)
        }
        return none()
    }
    var length: Int {
        if let _ = self.car {
            return 1 + self.cdr.length
        }
        return 0
    }
}

func +<T>(a: List<T>, b: List<T>) -> List<T> {
    if let v = a.car {
        return lazyCons(v) { a.cdr + b }
    }
    return b
}

func zip<T, U>(a: List<T>, b: List<U>) -> List<(T, U)> {
    if let va = a.car, vb = b.car {
        return lazyCons((va, vb)) { zip(a.cdr, b.cdr) }
    }
    return .Nil
}
func flatten<T>(list: List<List<T>>) -> List<T> {
    if let out_car: List<T> = list.car {
        if let in_car: T = out_car.car {
            return lazyCons(in_car) { flatten(cons(out_car.cdr, list.cdr)) }
        } else {
            return flatten(list.cdr)
        }
    }
    return .Nil
}
extension List {
    func flatMap<U>(f: T -> List<U>) -> List<U> {
        return flatten(self.map(f))
    }
}

func iterate<T>(v: T, f: T -> T) -> List<T> {
    return lazyCons(v) { iterate(f(v), f) }
}

func pair<T, U>(lhs: List<T>, rhs: List<U>) -> List<(T, U)> {
    return lhs.flatMap { lhsValue in
        return rhs.map { rhsValue in
            (lhsValue, rhsValue)
        }
    }
}

func repeat<T>(value: T) -> List<T> {
    return lazyCons(value) { repeat(value) }
}

extension List {
    var cycle: List<T> {
        return self.flatMap { _ in
            self
        }
    }
    func cycle(n: Int) -> List<T> {
        return repeat(1).take(n).flatMap { _ in
            return self
        }
    }
}


println("-- natural number --")

let natural = iterate(1){ $0 + 1 }
for n in natural.take(15) {
    println(n)
}

println("-- reverse natural number --")
for n in natural.take(15).reverse {
    println(n)
}

println("-- odd number --")

let odd = iterate(1){ $0 + 2 }
for n in odd.take(15) {
    println(n)
}

println("-- cycle --")
for n in iterate(0, { $0 + 1 }).take(3).cycle(4) {
    println(n)
}

println("-- combine --")
for n in (iterate(0){ $0 + 1 }.take(3) + iterate(3){ $0 - 1 }.take(3)).cycle.take(20) {
    println(n)
}

println("-- zip --")
let index = iterate(0){ $0 + 1 }
for (i, n) in zip(index, iterate(0, { $0 + 5 })).take(10) {
    println("\(i) : \(n)")
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

println("-- moonside --")
func moonside(text: String, count: Int) -> String {
    return String(Array(text).toList.flatMap { c in one(c).cycle(count) })
}
println(moonside("ムーンサイドへようこそ", 3))

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

println("-- 9 x 9 --")
let ninenine = pair(natural.take(9), natural.take(9)).map { (a, b) in
    return "\(a) x \(b) = \(a * b)"
}
for line in ninenine {
    println(line)
}
println("count = \(ninenine.length)")

