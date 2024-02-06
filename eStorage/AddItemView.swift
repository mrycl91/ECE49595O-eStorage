import SwiftUI

struct AddItemView: View {
    @State private var itemName = ""
    @State private var expirationDateInput = ""
    @State private var showingDatePicker = false

    var onAdd: (Item) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter Item Name", text: $itemName)
                    .padding()

                TextField("Enter Expiration Date", text: $expirationDateInput)
                    .onTapGesture {
                        showingDatePicker = true
                    }
                    .padding()

                if showingDatePicker {
                    DatePicker("Expiration Date", selection: Binding(
                        get: {
                            dateFormatter.date(from: expirationDateInput) ?? Date()
                        },
                        set: {
                            expirationDateInput = dateFormatter.string(from: $0)
                        }
                    ), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()
                }

                Button("Add Item", action: {
                    let newItem = Item(name: itemName, expirationDate: dateFormatter.date(from: expirationDateInput))
                    onAdd(newItem)
                    presentationMode.wrappedValue.dismiss() // Dismiss the AddItemView
                })
                .padding()

                // Button for Barcode Lookup (Not implemented)
                Button("Add Item by Barcode", action: {
                    // Implement barcode lookup functionality here
                })
                .padding()

                // Button for Text Recognition (Not implemented)
                Button("Add Item by Text Recognition", action: {
                    // Implement text recognition functionality here
                })
                .padding()
            }
            .navigationTitle("Add Item🌭")
        }
    }
}

struct AddItemView_Previews: PreviewProvider {
    static var previews: some View {
        AddItemView(onAdd: { _ in })
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

