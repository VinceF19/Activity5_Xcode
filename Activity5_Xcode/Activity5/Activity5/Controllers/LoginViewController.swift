// LoginViewController.swift
import UIKit

class LoginViewController: UIViewController {

    // --- Outlets ---
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // --- Properties ---
    // To temporarily hold data before passing via segue
    private var loginSuccessData: LoginResponse?

    // --- Standard View Controller Methods ---
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator?.hidesWhenStopped = true
        activityIndicator?.stopAnimating()
        // Clear any potential leftover data on load
        loginSuccessData = nil
        print("[LoginVC] ViewDidLoad - Initialized.")
    }

    // --- Actions ---
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        print("[LoginVC] Login Button Tapped.")
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            print("[LoginVC] Error: Missing username or password.")
            showAlert(title: "Error", message: "Please enter both username and password.")
            return
        }

        loginButton?.isEnabled = false
        activityIndicator?.startAnimating()
        // Clear previous success data before new attempt
        loginSuccessData = nil
        print("[LoginVC] Cleared previous loginSuccessData, starting login.")

        performLogin(username: username, password: password)
    }

    // --- API Call Logic ---
    func performLogin(username: String, password: String) {
        print("[LoginVC] performLogin called for user: \(username)")

        let loginURLString = "https://sis2.addu.edu.ph/dev/user/login" // Replace if needed
        guard let loginURL = URL(string: loginURLString) else {
            print("[LoginVC] Error: Invalid login URL string.")
            DispatchQueue.main.async {
                self.loginButton?.isEnabled = true
                self.activityIndicator?.stopAnimating()
                self.showAlert(title: "Error", message: "Internal configuration error (URL).")
            }
            return
        }

        var loginRequest = URLRequest(url: loginURL)
        loginRequest.httpMethod = "POST"
        loginRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        loginRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        let body: [String: String] = [
            "username": username,
            "password": password
        ]

        do {
            loginRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            print("[LoginVC] Login request body serialized.")
        } catch {
            print("[LoginVC] Failed to serialize the request body: ", error)
            DispatchQueue.main.async {
                self.loginButton?.isEnabled = true
                self.activityIndicator?.stopAnimating()
                self.showAlert(title: "Error", message: "Internal error creating request.")
            }
            return
        }

        print("[LoginVC] Starting URLSession data task...")
        let task = URLSession.shared.dataTask(with: loginRequest) { data, response, error in
            print("[LoginVC] URLSession task completed.")
            DispatchQueue.main.async { // Ensure UI updates on main thread

                if let error = error {
                    print("[LoginVC] Network request error: ", error)
                    self.showAlert(title: "Network Error", message: "Failed to connect. Please check your internet connection. \(error.localizedDescription)")
                    self.loginButton?.isEnabled = true
                    self.activityIndicator?.stopAnimating()
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[LoginVC] Invalid response received (not HTTP).")
                    self.showAlert(title: "Error", message: "Received an invalid response from the server.")
                    self.loginButton?.isEnabled = true
                    self.activityIndicator?.stopAnimating()
                    return
                }

                print("[LoginVC] Received HTTP Status Code: ", httpResponse.statusCode)

                guard let data = data else {
                    print("[LoginVC] No data received in response.")
                    self.showAlert(title: "Error", message: "No data received from the server.")
                    self.loginButton?.isEnabled = true
                    self.activityIndicator?.stopAnimating()
                    return
                }

                // Optional: Print raw response for debugging
                if let rawResponseString = String(data: data, encoding: .utf8) {
                    print("[LoginVC] ----- RAW Response Data Start -----")
                    print(rawResponseString)
                    print("[LoginVC] ----- RAW Response Data End -----")
                }

                // --- SUCCESS / FAILURE HANDLING ---
                if (200...299).contains(httpResponse.statusCode) {
                    print("[LoginVC] Login Successful (Status Code \(httpResponse.statusCode)). Attempting to decode response...")
                    do {
                        let decoder = JSONDecoder()
                        let loginResponse = try decoder.decode(LoginResponse.self, from: data)
                        print("[LoginVC] Successfully decoded LoginResponse.")

                        // --- Optional: Detailed print of decoded data ---
                        // (Keep your existing detailed print here if helpful)
                        // ...

                        // Store the data to be passed via segue
                        self.loginSuccessData = loginResponse
                        print("[LoginVC] Stored decoded data in loginSuccessData.")

                        // --- PERFORM THE SEGUE TO THE TAB BAR CONTROLLER ---
                        // Make sure the segue identifier in your Storyboard from
                        // LoginVC to the TabBarController is "navigateToTabBar" (or update this string)
                        print("[LoginVC] Performing segue with identifier 'navigateToTabBar'...")
                        self.performSegue(withIdentifier: "navigateToTabBar", sender: self)
                        // Keep indicator running until next screen loads
                        // Keep button disabled

                    } catch {
                        print("[LoginVC] Login Success (Status Code \(httpResponse.statusCode)), BUT FAILED TO DECODE JSON: \(error)")
                        if let decodingError = error as? DecodingError {
                            print("[LoginVC] Decoding Error Details: \(decodingError)")
                        }
                        self.showAlert(title: "Login Success (Warning)", message: "Logged in, but couldn't process user data. Check console logs. \(error.localizedDescription)")
                        self.loginButton?.isEnabled = true
                        self.activityIndicator?.stopAnimating()
                    }

                } else {
                    // FAILURE CASE
                    print("[LoginVC] Login Failed. Status Code: \(httpResponse.statusCode)")
                    var errorMessage = "Login failed. Please check your credentials."
                    if let errorJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let message = errorJson["message"] as? String {
                        errorMessage = message
                        print("[LoginVC] Server error message: \(errorMessage)")
                    } else if let responseString = String(data: data, encoding: .utf8) {
                         print("[LoginVC] Raw error response string: \(responseString)")
                    }

                    self.showAlert(title: "Login Failed (\(httpResponse.statusCode))", message: errorMessage)
                    self.loginButton?.isEnabled = true
                    self.activityIndicator?.stopAnimating()
                }
            } // End DispatchQueue.main.async
        } // End URLSession.shared.dataTask

        task.resume()
        print("[LoginVC] URLSession task resumed (request sent).")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("[LoginVC] prepare(for segue:) called. Identifier: \(segue.identifier ?? "nil")")

        // 1. Check the Segue Identifier
        if segue.identifier == "navigateToTabBar" { // *** USE THE CORRECT IDENTIFIER ***
            print("[LoginVC] Segue identifier matches 'navigateToTabBar'.")

            // 2. Ensure data exists
            guard let dataToPass = self.loginSuccessData else {
                print("[LoginVC] Error: Segue 'navigateToTabBar' triggered but loginSuccessData is nil.")
                self.activityIndicator?.stopAnimating()
                self.loginButton?.isEnabled = true
                return
            }

            // 3. Get the DESTINATION Tab Bar Controller
            guard let tabBarController = segue.destination as? UITabBarController else {
                print("[LoginVC] Error: Segue destination is not UITabBarController. Actual type: \(type(of: segue.destination))")
                self.activityIndicator?.stopAnimating()
                self.loginButton?.isEnabled = true
                return
            }
            print("[LoginVC] Segue destination is UITabBarController.")

            // 4. Access the View Controllers MANAGED BY the Tab Bar Controller
            guard let viewControllers = tabBarController.viewControllers else {
                print("[LoginVC] Warning: TabBarController has no view controllers array.")
                self.loginSuccessData = nil
                self.activityIndicator?.stopAnimating()
                self.loginButton?.isEnabled = true // Enable button if we can't proceed
                return
            }

            print("[LoginVC] Found \(viewControllers.count) view controllers in TabBarController. Iterating to pass data...")

            var curriculumTabIndex: Int? = nil // To store the index of the curriculum tab

            // 5. Loop through the Tab Bar's View Controllers and pass data
            for (index, vc) in viewControllers.enumerated() { // Use enumerated to get the index
                var targetVC: UIViewController? = vc // Assume direct VC first

                // Check if the VC is embedded in a Navigation Controller
                if let navController = vc as? UINavigationController {
                    targetVC = navController.topViewController // Get the actual VC
                    print("[LoginVC] Tab \(index): Found UINavigationController, checking its topViewController: \(type(of: targetVC))")
                } else {
                     print("[LoginVC] Tab \(index): Found direct ViewController: \(type(of: targetVC))")
                }

                // --- Pass data to RegistrationViewController ---
                if let registrationVC = targetVC as? RegistrationViewController {
                    print("[LoginVC] Tab \(index): Found RegistrationViewController. Passing data...")
                    registrationVC.profileData = dataToPass.profile
                    registrationVC.userData = dataToPass.user
                }
                // --- Pass data to CurriculumViewController ---
                else if let curriculumVC = targetVC as? CurriculumViewController {
                    print("[LoginVC] Tab \(index): Found CurriculumViewController. Passing data...")
                    curriculumVC.profileData = dataToPass.profile
                    curriculumVC.userData = dataToPass.user
                    // Pass session info needed for API calls
                    curriculumVC.token = dataToPass.token
                    curriculumVC.sessid = dataToPass.sessid
                    curriculumVC.sessionName = dataToPass.sessionName
                    curriculumTabIndex = index // *** STORE THE INDEX ***
                    print("[LoginVC] Stored curriculumTabIndex: \(index)")
                }
                // --- Add 'else if' blocks for any OTHER VCs in the tab bar ---
                // else if let gradesVC = targetVC as? GradesViewController { ... }
                else {
                    print("[LoginVC] Tab \(index): ViewController is of type \(type(of: targetVC)), not passing data to it.")
                }

            } // End of loop

            print("[LoginVC] Finished iterating through view controllers.")

            // 6. *** SELECT THE CURRICULUM TAB ***
            if let tabIndex = curriculumTabIndex {
                print("[LoginVC] Setting selected tab index to: \(tabIndex)")
                tabBarController.selectedIndex = tabIndex
            } else {
                print("[LoginVC] Warning: CurriculumViewController not found in tabs. Cannot set selected index.")
                // Optionally default to index 0 or show an error
                // tabBarController.selectedIndex = 0
            }

            // 7. Clean up AFTER passing data and setting index
            self.loginSuccessData = nil
            print("[LoginVC] Cleared loginSuccessData.")
            self.activityIndicator?.stopAnimating()
            print("[LoginVC] Stopped activity indicator.")
            // Keep login button disabled

        } else {
            print("[LoginVC] Prepare for segue called for unexpected identifier: \(segue.identifier ?? "nil")")
            if loginSuccessData == nil {
                self.activityIndicator?.stopAnimating()
                self.loginButton?.isEnabled = true
            }
        }
    }


    // --- Helper Function for Alerts ---
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        // Ensure presentation on main thread
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}