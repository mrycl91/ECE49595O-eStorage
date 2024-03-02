import SwiftUI

struct AddItemView: View {
    @State private var itemName = ""
    @State private var expirationDateInput = ""
    @State private var showingDatePicker = false
    @State private var navigateToBarCodeCameraView = false
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage?

    var onAdd: (Item) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter Item Name", text: $itemName)
                    .padding()

                TextField("Enter Expiration Date in yyyy-mm-dd or mm-dd", text: $expirationDateInput)
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
                    let newItem = createItem()
                    onAdd(newItem)

                    // Save the new item to UserDefaults
                    saveItemToUserDefaults(newItem)

                    // Dismiss the view
                    presentationMode.wrappedValue.dismiss()
                })
                .padding()

                NavigationLink(destination: BarCodeCameraView(), isActive: $navigateToBarCodeCameraView) {
                    EmptyView()
                }
                // Button for Barcode Lookup (Not implemented)
                Button("Add Item by Barcode", action: {
                    // Implement barcode lookup functionality here
                    self.navigateToBarCodeCameraView = true
                })
                .padding()

                // Button for Text Recognition (Not implemented)
                NavigationLink(destination: CameraView(isShown: $isShowingCamera, capturedImage: $capturedImage), isActive: $isShowingCamera) {
                    EmptyView()
                }
                
                Button("Add Item by Text Recognition", action: {
                    isShowingCamera = true
                })
                .padding()
            }
            .navigationTitle("Add Item🌭")
        }
    }

    private func createItem() -> Item {
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: Date())

        if expirationDateInput.isEmpty {
            components.month = Calendar.current.component(.month, from: Date())
            components.day = Calendar.current.component(.day, from: Date())
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd"
            if let date = dateFormatter.date(from: expirationDateInput) {
                components.month = Calendar.current.component(.month, from: date)
                components.day = Calendar.current.component(.day, from: date)
            } else {
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dateFormatter.date(from: expirationDateInput) {
                    components.year = Calendar.current.component(.year, from: date)
                    components.month = Calendar.current.component(.month, from: date)
                    components.day = Calendar.current.component(.day, from: date)
                }
            }
        }

        return Item(name: itemName, expirationDate: Calendar.current.date(from: components))
    }

    private func saveItemToUserDefaults(_ item: Item) {
        if var existingItems = UserDefaults.standard.array(forKey: "StoredItemsKey") as? [Data] {
            // Convert the item to Data
            if let itemData = try? JSONEncoder().encode(item) {
                existingItems.append(itemData)
                UserDefaults.standard.set(existingItems, forKey: "StoredItemsKey")
            }
        } else {
            // If no existing items, create a new array with the current item
            let items: [Data] = [try? JSONEncoder().encode(item)].compactMap { $0 }
            UserDefaults.standard.set(items, forKey: "StoredItemsKey")
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
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()
