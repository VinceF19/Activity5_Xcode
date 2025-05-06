import Foundation

// --- Configuration ---
let mainEndPoint = "https://sis2.addu.edu.ph/dev/"
let loginURLString = mainEndPoint + "user/login"
let registrationsURLString = mainEndPoint + "registrations"

// --- 1. Login Request Setup ---
print("--- Preparing Login Request ---")
guard let loginURL = URL(string: loginURLString) else {
    fatalError("Invalid Login URL")
}
var loginRequest = URLRequest(url: loginURL)
loginRequest.httpMethod = "POST"
loginRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
loginRequest.setValue("application/json", forHTTPHeaderField: "Accept") // Good practice

let loginBody: [String: String] = [
    "username": "testuser",
    "password": "testuser"
]

do {
    loginRequest.httpBody = try JSONSerialization.data(withJSONObject: loginBody, options: [])
    print("Login body set.")
} catch {
    print("Failed to serialize the login body: ", error)
    fatalError("Cannot proceed without login body")
}

// --- 2. Execute Login Request, Extract Token, THEN Fetch Registrations ---
print("--- Starting Login Request ---")
let loginTask = URLSession.shared.dataTask(with: loginRequest) { loginData, loginResponse, loginError in

    print("\n--- Login Request Completed ---")

    // --- Handle Login Network Error ---
    if let loginError = loginError {
        print("Login Request Network Error: ", loginError)
        return // Stop processing if login network failed
    }

    // --- Check Login HTTP Response ---
    guard let httpLoginResponse = loginResponse as? HTTPURLResponse else {
        print("Invalid Login response received from server.")
        return
    }

    print("Login Status Code: ", httpLoginResponse.statusCode)

    // --- Check Login Success Status Code ---
    guard (200...299).contains(httpLoginResponse.statusCode) else {
        print("Login Failed (Status Code: \(httpLoginResponse.statusCode)). Cannot proceed to fetch registrations.")
        if let loginData = loginData, let errorString = String(data: loginData, encoding: .utf8) {
            print("Login Error Response Body: \(errorString)")
        }
        return // Stop if login wasn't successful
    }

    // --- Extract CSRF Token from Login Response Data ---
    guard let loginData = loginData else {
        print("Login successful, but no data received in login response. Cannot get CSRF token.")
        return
    }

    var csrfToken: String? // Variable to hold the extracted token

    do {
        // Parse the login JSON
        if let loginJson = try JSONSerialization.jsonObject(with: loginData, options: []) as? [String: Any] {
            print("Login Response JSON Parsed.")
            // Extract the token value
            if let tokenValue = loginJson["token"] as? String {
                csrfToken = tokenValue
                print("Successfully extracted CSRF Token: \(csrfToken!)")
            } else {
                print("Error: 'token' key not found or not a String in login response JSON.")
                // Pretty print the JSON to help debug
                if let jsonData = try? JSONSerialization.data(withJSONObject: loginJson, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("Login JSON Structure:\n\(jsonString)")
                }
                return // Stop if token cannot be extracted
            }
        } else {
             print("Error: Login response JSON is not a dictionary.")
             if let responseString = String(data: loginData, encoding: .utf8) {
                  print("Raw Login response data: \(responseString)")
             }
             return // Stop if JSON structure is wrong
        }
    } catch {
        print("Login successful, but failed to decode Login JSON: ", error)
        if let responseString = String(data: loginData, encoding: .utf8) {
             print("Raw Login response data: \(responseString)")
        }
        return // Stop if JSON parsing fails
    }

    // --- Ensure we have the token before proceeding ---
    guard let validCsrfToken = csrfToken else {
        print("Error: CSRF Token was not extracted. Cannot proceed to fetch registrations.")
        return
    }

    // --- 3. If Login Successful AND Token Extracted, Fetch Registrations ---
    print("\n--- Preparing Registrations Request with CSRF Token ---")

    guard let registrationsURL = URL(string: registrationsURLString) else {
        print("Error: Invalid registrations URL string.")
        return // Cannot proceed
    }

    var registrationsRequest = URLRequest(url: registrationsURL)
    registrationsRequest.httpMethod = "GET"
    registrationsRequest.setValue("application/json", forHTTPHeaderField: "Accept")

    // --- ADD THE EXTRACTED CSRF TOKEN TO THE HEADER ---
    registrationsRequest.setValue(validCsrfToken, forHTTPHeaderField: "X-CSRF-Token")
    print("X-CSRF-Token header added to registrations request.")
    // Note: URLSession should automatically handle the session cookie (like SSESS...) as well.

    print("--- Starting Registrations Request ---")
    let registrationTask = URLSession.shared.dataTask(with: registrationsRequest) { regData, regResponse, regError in

        print("\n--- Registrations Request Completed ---")

        // --- Handle Registrations Network Error ---
        if let regError = regError {
            print("Registrations Request Network Error: ", regError)
            return
        }

        // --- Check Registrations HTTP Response ---
        guard let httpRegResponse = regResponse as? HTTPURLResponse else {
            print("Invalid Registrations response received from server.")
            return
        }

        print("Registrations Status Code: ", httpRegResponse.statusCode)

        // --- Check Registrations Success Status Code ---
        guard (200...299).contains(httpRegResponse.statusCode) else {
            print("Fetching Registrations Failed (Status Code: \(httpRegResponse.statusCode)).")
            // Print error response body - it might give more clues if it still fails
            if let regData = regData, let errorString = String(data: regData, encoding: .utf8) {
                print("Registrations Error Response Body: \(errorString)") // This might still say CSRF failed if the token was wrong/expired, or something else
            }
            return
        }

        // --- Process Registrations Success Data ---
        guard let regData = regData else {
            print("No registration data received in response, although status code was success.")
            return
        }

        do {
            let regJson = try JSONSerialization.jsonObject(with: regData, options: [])
            print("--- Successfully Fetched Registrations ---")
            print("--- Registrations Response JSON ---")
            if let jsonData = try? JSONSerialization.data(withJSONObject: regJson, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            } else {
                print(regJson)
            }
        } catch {
            print("Failed to decode Registrations JSON: ", error)
            if let responseString = String(data: regData, encoding: .utf8) {
                 print("Raw Registrations response data: \(responseString)")
            }
        }
    }
    // --- Start the Registrations task ---
    registrationTask.resume()

} // End of loginTask completion handler

// --- Start the initial Login task ---
loginTask.resume()

// --- Keep playground running (if needed) ---
// import PlaygroundSupport
// PlaygroundPage.current.needsIndefiniteExecution = true
