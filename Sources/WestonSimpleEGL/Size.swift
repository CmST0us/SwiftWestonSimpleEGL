class Size {
    var width: Int
    var height: Int

    init(_ width: Int, _ height: Int) {
        self.width = width
        self.height = height
    }

    static var zero: Size {
        return Size(0, 0)
    }
}