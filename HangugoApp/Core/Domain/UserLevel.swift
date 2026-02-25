enum UserLevel: String, CaseIterable, Identifiable {
    case beginner
    case intermediate
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        }
    }
}
