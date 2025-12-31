import SwiftUI
import Foundation // Import Foundation for URL


func formatPhoneNumber(phoneNumberString: String) -> String {
    // Remove non-numeric characters
    let cleaned = phoneNumberString.filter { $0.isNumber }

    if cleaned.count >= 11 && cleaned.first == "1" {
        // Format the phone number as +1 (123) 456-7890
        let limitedCleaned = cleaned.prefix(11)
        let match =
            limitedCleaned.dropFirst().prefix(3) + limitedCleaned.dropFirst(4).prefix(3)
            + limitedCleaned.dropFirst(7)
        return "+1 (\(match.prefix(3))) \(match.dropFirst(3).prefix(3))-\(match.dropFirst(6))"
    } else if cleaned.count >= 10 {
        // Format the phone number as (123) 456-7890
        let limitedCleaned = cleaned.prefix(10)
        let match = limitedCleaned.prefix(3) + limitedCleaned.dropFirst(3).prefix(3) + limitedCleaned.dropFirst(6)
        return "(\(match.prefix(3))) \(match.dropFirst(3).prefix(3))-\(match.dropFirst(6))"
    }

    // If the phone number is not 10 or 11 digits long, return the cleaned version
    return cleaned
}

func cleanPhoneNumber(phoneNumberString: String) -> String {
    let cleanedPhoneNumber = phoneNumberString.filter { $0.isNumber }
    let formattedPhoneNumber: String

    if cleanedPhoneNumber.count == 10 {
        formattedPhoneNumber = "+1" + cleanedPhoneNumber
    } else if cleanedPhoneNumber.count == 11 {
        formattedPhoneNumber = "+" + cleanedPhoneNumber
    } else {
        formattedPhoneNumber = cleanedPhoneNumber
    }
    return formattedPhoneNumber
}

func openAppleWallet() {
    if let url = URL(string: "wallet://") {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Handle the case where the Wallet app is not available or accessible
            print("Apple Wallet is not available on this device.")
        }
    }
}

func formatSpendingInput(
    _ newValue: String,
    oldValue: String,
    spendingInput: inout String,
    spending: inout Double
) {
    let cleaned = newValue
        .replacingOccurrences(of: "$", with: "")
        .replacingOccurrences(of: ",", with: "")
        .filter { "0123456789.".contains($0) }

    if cleaned.isEmpty {
        spendingInput = ""
        spending = 0
        return
    }

    if cleaned == "." {
        spendingInput = "$0."
        spending = 0
        return
    }

    let components = cleaned.split(separator: ".", omittingEmptySubsequences: false)
    guard components.count <= 2 else {
        spendingInput = oldValue
        return
    }

    var integerPart = String(components[0])
    if integerPart.hasPrefix("0") && integerPart != "0" {
        integerPart = String(Int(integerPart) ?? 0)
    }

    var formattedInput = integerPart

    if components.count == 2 {
        let decimalPart = components[1]
        formattedInput += ".\(decimalPart.prefix(2))"
    }

    if let value = Double(formattedInput), value <= 999.99 {
        spending = value

        if components.count == 2 {
            let typedDecimals = String(components[1].prefix(2))
            spendingInput = "$\(integerPart).\(typedDecimals)"
        } else {
            spendingInput = "$\(integerPart)"
        }
    } else {
        spendingInput = oldValue
    }
}