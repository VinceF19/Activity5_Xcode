// CurriculumViewController.swift
import UIKit

// --- Custom Table View Cell Class ---
// Define the cell class with outlets for the labels it contains.
// Make sure the prototype cell in Storyboard has its Custom Class set to "CurriculumTableViewCell"
// and the Reuse Identifier set to "CurriculumCell". Connect the outlets below to the labels in that cell.
class CurriculumTableViewCell: UITableViewCell {
    @IBOutlet weak var Code: UILabel!
    @IBOutlet weak var Subject: UILabel!
    @IBOutlet weak var Schedule: UILabel!
    
    
    @IBOutlet weak var PrelimGrade: UILabel!
    @IBOutlet weak var MidtermGrade: UILabel!
    @IBOutlet weak var PreFinalGrade: UILabel!
    @IBOutlet weak var FinalGrade: UILabel!
}

// --- View Controller ---
class CurriculumViewController: UITableViewController {

    // --- Properties to receive data ---
    var profileData: Profile?
    var userData: User?
    var token: String? // To receive the session token from LoginVC
    // sessid and sessionName are not strictly needed if relying on automatic cookie handling
    // but keeping them doesn't hurt if they are passed.
    var sessid: String?
    var sessionName: String?

    // --- Data Source for Table View ---
    var curriculumItems: [ClassDetail] = [] // Updated to use ClassDetail

    // --- Outlets for Header View ---
    @IBOutlet weak var studentNameLabel: UILabel!
    @IBOutlet weak var studentIdLabel: UILabel!

    // --- View Lifecycle ---
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[CurriculumVC] viewDidLoad - Started.")
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 80

        displayUserData()
        fetchRegistrationData() // Renamed function for clarity

        print("[CurriculumVC] viewDidLoad - Finished.")
    }

    func displayUserData() {
        print("[CurriculumVC] Attempting to display user data in header...")
        if let profile = profileData {
            let firstName = profile.firstName ?? ""
            let lastName = profile.lastName ?? ""
            let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
            studentNameLabel?.text = fullName.isEmpty ? "Name: N/A" : "Name: \(fullName)"
            studentIdLabel?.text = "ID: \(profile.code ?? profile.bcode ?? "N/A")"
        } else {
            studentNameLabel?.text = "Name: N/A"
            studentIdLabel?.text = "ID: N/A"
            print("[CurriculumVC] Profile data was nil, setting header labels to N/A.")
        }
        print("[CurriculumVC] Finished updating header UI elements.")
    }

    // --- API Fetching Logic ---
    func fetchRegistrationData() { // Renamed from fetchCurriculumData
        print("[CurriculumVC] Attempting to fetch REGISTRATION data...")

        guard let token = self.token, !token.isEmpty else {
            print("[CurriculumVC] Error: Missing session token. Cannot fetch data.")
            showAlert(title: "Error", message: "Session token is missing. Please log in again.")
            return
        }

        // --- MODIFICATION: Use the /registrations endpoint ---
        let registrationsURLString = "https://sis2.addu.edu.ph/dev/registrations"
        guard let registrationsURL = URL(string: registrationsURLString) else {
            print("[CurriculumVC] Error: Invalid registrations URL string.")
            showAlert(title: "Error", message: "Internal configuration error (API URL).")
            return
        }

        var request = URLRequest(url: registrationsURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(token, forHTTPHeaderField: "X-CSRF-Token")
        // Relying on URLSession.shared for automatic cookie handling, as per your successful example.

        print("[CurriculumVC] Fetching from URL: \(registrationsURLString)")
        print("[CurriculumVC] Using Token for X-CSRF-Token: \(token)")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[CurriculumVC] Network request error: ", error)
                    self?.showAlert(title: "Network Error", message: "Failed to fetch registrations. Please check your connection. \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[CurriculumVC] Invalid response received (not HTTP).")
                    self?.showAlert(title: "Error", message: "Received an invalid response from the server.")
                    return
                }

                print("[CurriculumVC] Received HTTP Status Code for /registrations: ", httpResponse.statusCode)

                guard (200...299).contains(httpResponse.statusCode) else {
                    print("[CurriculumVC] API request to /registrations failed with status code: \(httpResponse.statusCode)")
                    var errorMessage = "Failed to fetch registrations (Code: \(httpResponse.statusCode))."
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("[CurriculumVC] Error response body: \(responseString)")
                    }
                    self?.showAlert(title: "API Error", message: errorMessage)
                    return
                }

                guard let data = data else {
                    print("[CurriculumVC] No data received in /registrations response.")
                    self?.showAlert(title: "Error", message: "No data received from the server for registrations.")
                    return
                }

                // --- MODIFICATION: Just print the raw JSON for now ---
                if let rawResponseString = String(data: data, encoding: .utf8) {
                    print("[CurriculumVC] ----- RAW /registrations Response Data Start -----")
                    print(rawResponseString)
                    print("[CurriculumVC] ----- RAW /registrations Response Data End -----")
                    // TODO: Once you see this output, determine the JSON structure
                    // and create appropriate Codable structs. Then, uncomment and adapt the decoding block below.
                    // No longer needed: self?.showAlert(title: "Data Received (Raw)", message: "Registration data received. Check console for raw JSON. Next step is to parse it.")
                } else {
                     print("[CurriculumVC] Warning: Could not convert raw registration data to string for logging.")
                 }


                // --- Decode the JSON response ---
                do {
                    let decoder = JSONDecoder()
                    // Attempt to decode the data as an array of RegistrationRecord
                    let registrationRecords = try decoder.decode([RegistrationRecord].self, from: data)

                    print("[CurriculumVC] Successfully decoded \(registrationRecords.count) registration records.")

                    // Flatten the classes from all registration records into a single list
                    var allClasses: [ClassDetail] = []
                    for record in registrationRecords {
                        if let classesInRecord = record.classes {
                            allClasses.append(contentsOf: classesInRecord)
                        }
                    }
                    
                    self?.curriculumItems = allClasses // Assign decoded and flattened items
                    self?.tableView.reloadData() // Refresh the table view on the main thread
                    print("[CurriculumVC] Populated curriculumItems with \(allClasses.count) classes.")

                } catch {
                    print("[CurriculumVC] FAILED TO DECODE /registrations JSON: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("[CurriculumVC] Decoding Error Details: \(decodingError)")
                        // Provide more specific error details if possible
                        switch decodingError {
                        case .typeMismatch(let type, let context):
                            print("Type mismatch for type \(type) in \(context.codingPath): \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("Value not found for type \(type) in \(context.codingPath): \(context.debugDescription)")
                        case .keyNotFound(let key, let context):
                            print("Key not found: \(key) in \(context.codingPath): \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("Data corrupted in \(context.codingPath): \(context.debugDescription)")
                        @unknown default:
                            print("Unknown decoding error.")
                        }
                    }
                    // Show an alert to the user about the parsing failure
                    self?.showAlert(title: "Data Error", message: "Could not process registration data. The format might have changed. \(error.localizedDescription)")
                }
            }
        }
        task.resume()
        print("[CurriculumVC] URLSession task for /registrations resumed (request sent).")
    }

    // MARK: - Table view data source
    // These will need to be adapted once curriculumItems is populated with actual registration data

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return curriculumItems.count // This will be 0 until we parse and populate
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "CurriculumCell" // You might want to rename this if it's for registrations
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CurriculumTableViewCell else {
            print("[CurriculumVC] Error: Could not dequeue cell as CurriculumTableViewCell.")
            let basicCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            basicCell.textLabel?.text = "Error loading cell"
            return basicCell
        }

        // This part needs to be updated based on the actual structure of registration items
        if indexPath.row < curriculumItems.count { // Ensure index is within bounds
            let item = curriculumItems[indexPath.row]
            
            cell.Code?.text = item.subjectCode ?? "N/A"
            // Ensure Subject label is updated. If item.subjectName is nil, it will show "N/A".
            cell.Subject?.text = item.subjectName ?? "N/A"
            // Ensure Schedule label is updated. If item.cleanedSchedule is nil, it will show "N/A".
            cell.Schedule?.text = item.cleanedSchedule ?? "N/A"

            // Populate Grade Labels
            cell.PrelimGrade?.text = item.grades?.P ?? "-" // Using "-" as placeholder for missing grades
            cell.MidtermGrade?.text = item.grades?.M ?? "-"
            cell.PreFinalGrade?.text = item.grades?.Pre ?? "-"
            cell.FinalGrade?.text = item.grades?.F ?? "-"
            
            // For debugging, print what's being set:
            // print("[CurriculumVC Cell] Code: \(cell.Code?.text ?? "nil"), Subject: \(cell.Subject?.text ?? "nil"), Schedule: \(cell.Schedule?.text ?? "nil")")
            // print("[CurriculumVC Cell] Grades P: \(cell.PrelimGrade?.text ?? "nil"), M: \(cell.MidtermGrade?.text ?? "nil"), Pre: \(cell.PreFinalGrade?.text ?? "nil"), F: \(cell.FinalGrade?.text ?? "nil")")

        } else {
            // This case should ideally not be hit if numberOfRowsInSection is correct and curriculumItems is populated.
            print("[CurriculumVC] Warning: indexPath.row \(indexPath.row) is out of bounds for curriculumItems count \(curriculumItems.count). Setting cell to placeholder.")
            cell.Code?.text = "Loading..."
            cell.Subject?.text = " " // Use a space to ensure it clears previous content
            cell.Schedule?.text = " " // Use a space to ensure it clears previous content
            cell.PrelimGrade?.text = " "
            cell.MidtermGrade?.text = " "
            cell.PreFinalGrade?.text = " "
            cell.FinalGrade?.text = " "
        }
        return cell
    }

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}