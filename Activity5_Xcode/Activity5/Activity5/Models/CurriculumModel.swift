//
//  CurriculumModel.swift
//  Activity5
//
//  Created by Abdurrahman Guiomala Canacan on 5/5/25.
//

import Foundation

// Represents a single class/subject detail from the /registrations endpoint
// Represents the grades for a class
struct Grades: Codable {
    let P: String?      // Prelim
    let M: String?      // Midterm
    let Pre: String?    // Pre-Final
    let F: String?      // Final

    // CodingKeys are needed because 'Pre' in JSON might conflict with Swift keywords if not handled.
    // However, 'Pre' as a property name is fine. If JSON keys were different, like 'pre_final', we'd map them.
    // For this specific JSON, default Codable synthesis should work for P, M, Pre, F.
}

struct ClassDetail: Codable {
    let desc: String?       // e.g., "CS 312C - FREE ELECTIVE III"
    let sched: String?      // e.g., "* 9:15A-11:45A F612 TTh * "
    let grades: Grades?     // Added grades property

    // Computed property to extract subject code from 'desc'
    var subjectCode: String? {
        guard let description = desc else { return nil }
        // Extracts the part before " - "
        return description.components(separatedBy: " - ").first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Computed property to extract full subject name from 'desc'
    var subjectName: String? {
        guard let description = desc else { return nil }
        let parts = description.components(separatedBy: " - ")
        // Only return a subject name if there are at least two parts (code and name)
        if parts.count > 1 {
            return parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil // Return nil if 'desc' doesn't contain ' - ' separator, so "N/A" will be shown
    }

    // Computed property to clean up the schedule string
    var cleanedSchedule: String? {
        guard var scheduleText = sched else { return nil }
        // Remove leading/trailing asterisks if they exist, then trim whitespace
        var tempSched = scheduleText.trimmingCharacters(in: .whitespacesAndNewlines)
        if tempSched.hasPrefix("*") {
            tempSched.removeFirst()
        }
        if tempSched.hasSuffix("*") {
            tempSched.removeLast()
        }
        return tempSched.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Represents a registration record which contains a list of classes
struct RegistrationRecord: Codable {
    let registration: String?
    let course: String?
    let classes: [ClassDetail]?
}

// Original CurriculumItem, kept for reference or if used elsewhere, but not for /registrations
struct CurriculumItem: Codable {
    let code: String?
    let fullSubjectName: String?
    let schedule: String?
}