// Models.swift (or add within LoginViewController initially if preferred)
import Foundation

// Structure matching the overall login response
struct LoginResponse: Codable {
    let profile: Profile
    let user: User
    let sessionName: String // Map JSON keys if needed using CodingKeys
    let sessid: String
    let token: String

    // Use CodingKeys if Swift property names don't exactly match JSON keys
    enum CodingKeys: String, CodingKey {
        case profile, user, sessid, token
        case sessionName = "session_name" // Example mapping
    }
}

// Structure for the "profile" object
struct Profile: Codable {
    let bcode: String?         // Use optional if data might be missing
    let birthdateString: String? // Keep as String initially for formatting
    let code: String?
    let cityAddress: String?
    let cityContactNumber: String?
    let gender: Int?           // Keep as Int initially
    let middleName: String?
    let firstName: String?
    let lastName: String?
    let civilStatus: Int?      // Keep as Int initially
    // Add other fields if needed, mapping keys if necessary

    enum CodingKeys: String, CodingKey {
        case bcode = "BCODE"
        case birthdateString = "BIRTHDATE"
        case code = "CODE"
        case cityAddress = "CITYADDRESS"
        case cityContactNumber = "CITYCONTACTNUMBER"
        case gender = "GENDER"
        case middleName = "MIDDLENAME"
        case firstName = "FIRSTNAME"
        case lastName = "LASTNAME"
        case civilStatus = "CIVILSTATUS"
        // Map other keys...
    }
}

// Structure for the "user" object
struct User: Codable {
    let mail: String?
    let name: String?
    let uid: Int?
    // Add other fields if needed
}
