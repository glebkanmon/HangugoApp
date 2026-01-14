import Foundation

enum Secrets {

    private static let plistName = "Secrets"

    private static var values: [String: Any] = {
        guard
            let url = Bundle.main.url(forResource: plistName, withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any]
        else {
            fatalError("❌ Secrets.plist not found or invalid")
        }
        return plist
    }()

    static var deepSeekApiKey: String {
        guard let key = values["DEEPSEEK_API_KEY"] as? String else {
            fatalError("❌ DEEPSEEK_API_KEY not set in Secrets.plist")
        }
        return key
    }

    static var baseApiURL: String {
        guard let url = values["BASE_API_URL"] as? String else {
            fatalError("❌ BASE_API_URL not set in Secrets.plist")
        }
        return url
    }
}
