// RegistrationViewController.swift (Complete File)
import UIKit

class RegistrationViewController: UIViewController {

    // --- Properties to receive data ---
    var profileData: Profile?
    var userData: User?

    // --- Outlets ---
    @IBOutlet weak var ID: UILabel!
    @IBOutlet weak var FullName: UILabel!
    @IBOutlet weak var BirthDate: UILabel!
    @IBOutlet weak var Sex: UILabel!
    @IBOutlet weak var City: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var Contact: UILabel!
    // --- View Lifecycle ---
      override func viewDidLoad() {
          super.viewDidLoad()
          print("RegistrationViewController loaded.")
          // Populate labels with the received data
          populateProfileData()
      }

      // --- Data Population Logic ---
      func populateProfileData() {
          print("Attempting to populate profile data...")
          guard let profile = profileData, let user = userData else {
              print("Error: Profile or User data not received.")
              // Optionally show an error message or default text
              ID.text = "N/A"
              FullName.text = "N/A"
              BirthDate.text = "N/A"
              Sex.text = "N/A"
              City.text = "N/A"
              email.text = "N/A"
              Contact.text = "N/A"
              return
          }

          print("Profile Data: \(profile)")
          print("User Data: \(user)")

          // ID: Use 'CODE' if available, otherwise 'BCODE' or "N/A"
          ID.text = profile.code ?? profile.bcode ?? "N/A"

          // Full Name: Combine parts, handling potential nil values
          let firstName = profile.firstName ?? ""
          let middleName = profile.middleName ?? ""
          let lastName = profile.lastName ?? ""
          // Add spaces only if names exist
          var fullNameParts: [String] = []
          if !firstName.isEmpty { fullNameParts.append(firstName) }
          if !middleName.isEmpty { fullNameParts.append(middleName) }
          if !lastName.isEmpty { fullNameParts.append(lastName) }
          FullName.text = fullNameParts.joined(separator: " ").isEmpty ? "N/A" : fullNameParts.joined(separator: " ")

          // Birth Date: Use the string directly from the profile data
          // Handle potential nil or empty string
          if let dateString = profile.birthdateString, !dateString.isEmpty {
              BirthDate.text = dateString
          } else {
              BirthDate.text = "N/A"
          }

          // Sex: Convert integer to string
          switch profile.gender {
              case 1: Sex.text = "Male"
              case 2: Sex.text = "Female" // Assuming 2 is Female, adjust if needed
              default: Sex.text = "N/A"
          }

          // City Address
          City.text = profile.cityAddress ?? "N/A"

          // Email
          email.text = user.mail ?? "N/A"

          // Contact Number
          Contact.text = profile.cityContactNumber ?? "N/A"

          print("Labels populated.")
      }

      /*
      // MARK: - Navigation
      // In a storyboard-based application, you will often want to do a little preparation before navigation
      override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
          // Get the new view controller using segue.destination.
          // Pass the selected object to the new view controller.
      }
      */
  }
