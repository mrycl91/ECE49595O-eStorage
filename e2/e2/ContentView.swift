// ContentView.swift

import SwiftUI
import Combine


struct ContentView: View {
    @Binding var items: [Item]
    @State private var selectedItem: Item?
    @State private var showingDeleteAlert = false
    @State private var showingALLDeleteAlert = false
    @State private var navigationTag: Int?
    @State private var detailPage = false
    @State private var emptyItem = Item(name: "", expirationDate: nil)

    // Key for UserDefaults
    private let itemsKey = "StoredItemsKey"

    var body: some View {
        VStack{
            GeometryReader { proxy in
                VStack{
                    HStack{
                        Text("Grocery Lists")
                            .font(.system(size:26, weight: .bold))
                            .position(x: 110, y: 60)
                            .foregroundColor(Color(hex: 0x535657))
                        ZStack(alignment: .topTrailing){
                            Path { path in
                                path.move(to: CGPoint(x:proxy.size.width/2, y:0))
                                path.addArc(
                                    center: CGPoint(x:proxy.size.width/2, y:0),
                                    radius: 110,
                                    startAngle: Angle(degrees: 90),
                                    endAngle: Angle(degrees: 180),
                                    clockwise: false
                                )
                                path.closeSubpath()
                            }
                                .fill(Color(hex: 0x535657))
                            
                            Button(action: {
                                showingALLDeleteAlert = true
                            }, label: {
                                Text("Delete\n       All")
                                    .foregroundColor(Color(hex: 0xf4faff))
                                    .padding(23)
                                    .alignmentGuide(.top){ dimension in
                                        dimension[.top]
                                    }
                            })
                                .alert(isPresented: $showingALLDeleteAlert) {
                                    Alert(
                                        title: Text("Delete Expired Item"), message: Text("Confirm deletion of all expired items?"),
                                        primaryButton: .destructive(Text("Delete")) {
                                            deleteAllExpiredItems()
                                            showingALLDeleteAlert = false
                                        },
                                        secondaryButton: .cancel(){
                                            showingALLDeleteAlert = false
                                        }
                                    )
                                }
                        }
                    }
                    .frame(height: proxy.size.height/6)
                    
                    List {
                        ForEach(items.indices, id: \.self) { index in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(" \(items[index].name)")
                                        .foregroundColor(isItemExpired(items[index].expirationDate) ? .red : Color(hex: 0x535657))
                                    if let expirationDate = items[index].expirationDate {
                                        Text("  Best by \(formattedDate(expirationDate))")
                                            .foregroundColor(isItemExpired(expirationDate) ? .red : Color(hex: 0x535657))
                                    }
                                }
                                Spacer()
                            }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedItem = items[index]
//                                    detailPage = true
                                }
                                .sheet(item: $selectedItem){ selectedItem in
                                    if selectedItem != emptyItem{
                                        ItemDetailView(item: selectedItem)
                                    }
                                }
//                                .fullScreenCover(isPresented: $detailPage){
//                                    if let selectedItem = selectedItem{
//                                        ItemDetailView(item: selectedItem)
//                                    }
//                                }
                        }
                            .onDelete(perform: deleteItems)
                            .listRowBackground(Color(hex: 0xdee7e7))
                    }
                        .listStyle(.plain)
                        .alert(isPresented: $showingDeleteAlert) {
                            Alert(
                                title: Text("Delete Item"), message: Text("Are you sure you want to delete \(selectedItem?.name ?? "this item")?"),
                                primaryButton: .destructive(Text("Delete")) {
                                    deleteSelectedItem()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .alignmentGuide(.bottom){ dimension in
                    dimension[.bottom]
                }
            }
        }
        .background(Color(hex: 0xdee7e7))
    }

    private func deleteItems(at offsets: IndexSet) {
        selectedItem = items[offsets.first ?? 0]
        showingDeleteAlert = true
    }

    private func deleteSelectedItem() {
        print("delete selected item")
        if let selectedItem = selectedItem,
           let index = items.firstIndex(where: { $0.id == selectedItem.id }) {
            items.remove(at: index)
        }
        selectedItem = emptyItem //nil
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func isItemExpired(_ expirationDate: Date?) -> Bool {
        guard let expirationDate = expirationDate else {
            return false
        }
        let currentDate = Date()

        return currentDate > expirationDate
    }

    private func deleteAllExpiredItems() {
        let currentDate = Date()
        let expiredItemsIndices = items.indices.filter { index in
            guard let expirationDate = items[index].expirationDate else {
                return false
            }
            return currentDate > expirationDate
        }
        // Display an alert if there are no expired items to delete
        guard !expiredItemsIndices.isEmpty else {
            showingDeleteAlert = true
            selectedItem = emptyItem // nil
            return
        }
        // Delete expired items
        for index in expiredItemsIndices.reversed() {
            items.remove(at: index)
        }
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        let items: [Item] = []
//        ContentView(items: .constant(items))
//    }
//}
