enum ReviewRating {
    case hard
    case normal
    case easy

    /// SM-2 quality (0...5)
    var quality: Int {
        switch self {
        case .hard: return 2
        case .normal: return 4
        case .easy: return 5
        }
    }
}
