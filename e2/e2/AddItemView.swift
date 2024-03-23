import SwiftUI
import Vision
import CoreML

struct AddItemView: View {
    var onAdd: (Item) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var itemName = ""
    @State private var expirationDateInput = ""
    @State private var showingDatePicker = false
    @State private var navigateToBarCodeCameraView = false
    @State private var isShowingCameraView = false
    
    // obj recog: below===================================================
    @State private var imageCapture : UIImage?
    @State private var showSheet = false
    @State private var classificationResult = ""
    @State private var classifyText = false
    @State private var classifyObject = false
    @State private var classifyDate = false
    
//    private var model: Resnet50?
    // initialize model
    private var model: Resnet50? = try? Resnet50(configuration: MLModelConfiguration())
//    init() {
//        do {
//            model = try Resnet50(configuration: MLModelConfiguration())
//        } catch {
//            print("Unable to initialize model: \(error)")
//        }
//    }
    // obj recog: above===================================================


    var body: some View {
        NavigationView {
            VStack {
                TextField("Item Name", text: $itemName)
                    .padding()
                
                // updated below===================================================
                HStack{
                    Button("Obj Recog", action: {
                        classifyDate = false
                        classifyText = false
                        classifyObject = true
                        showSheet = true
                    })
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    
                    Button("Text Recog", action: {
                        classifyDate = false
                        classifyText = true
                        classifyObject = false
                        showSheet = true
                    })
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    
                    Button("Barcode", action: {
                        navigateToBarCodeCameraView = true
                    })
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
                .sheet(isPresented: $showSheet, onDismiss: {
                    showSheet = false
                    if let image = imageCapture{
                        if classifyText{
                            performTextRecognition(image: image)
                        } else{
                            processImage(image: image)
                        }
                    }
                }) {
                    // If you wish to take a photo from camera instead:
                    ImgPicker(sourceType: .camera, selectedImage: self.$imageCapture)
                }
                // updated: above===================================================
                

                TextField("Expiration Date (yyyy-mm-dd) or (mm-dd)", text: $expirationDateInput)
//                    .onTapGesture {
//                        showingDatePicker = true
//                    }
                    .padding()
                
                HStack{
                    Button("Text Recog", action: {
                        classifyDate = true
                        classifyText = true
                        classifyObject = false
                        showSheet = true
                    })
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .sheet(isPresented: $showSheet, onDismiss: {
                        showSheet = false
                        if let image = imageCapture{
                            if classifyText{
                                performTextRecognition(image: image)
                            } else{
                                processImage(image: image)
                            }
                        }
                    }) {
                        // If you wish to take a photo from camera instead:
                        ImgPicker(sourceType: .camera, selectedImage: self.$imageCapture)
                    }
                    DatePicker("Best by", selection: Binding(
                        get: {
                            dateFormatter.date(from: expirationDateInput) ?? Date()
                        },
                        set: {
                            expirationDateInput = dateFormatter.string(from: $0)
                        }
                    ), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()
                    
//                    DatePicker("Best by", selection: Binding(
//                        get: {
//                            dateFormatter.date(from: expirationDateInput) ?? Date()
//                        },
//                        set: {
//                            expirationDateInput = dateFormatter.string(from: $0)
//                        }
//                    ), displayedComponents: .date)
//                    .datePickerStyle(.compact)
//                    .padding()
                }

//                if showingDatePicker {
//                    DatePicker("Expiration Date", selection: Binding(
//                        get: {
//                            dateFormatter.date(from: expirationDateInput) ?? Date()
//                        },
//                        set: {
//                            expirationDateInput = dateFormatter.string(from: $0)
//                        }
//                    ), displayedComponents: .date)
//                    .datePickerStyle(.compact)
//                    .padding()
//                }

                Button("Confirm", action: {
                    let newItem = createItem()
                    onAdd(newItem)

                    // Save the new item to UserDefaults
                    saveItemToUserDefaults(newItem)

                    // Dismiss the view
                    presentationMode.wrappedValue.dismiss()
                })
                .padding(30)
                
                NavigationLink(destination: BarCodeCameraView(), isActive: $navigateToBarCodeCameraView) {
                    EmptyView()
                }

//                NavigationLink(destination: BarCodeCameraView()) {
//                    Text("Add Item by Barcode")
//                        .padding(10)
//                }
                
//                NavigationLink(destination: CameraView()) {
//                    Text("Add Item by Text Recognition")
//                        .padding(10)
//                }
//
//                NavigationLink(destination: obj_page()) {
//                    Text("Add Item by Object")
//                        .padding(10)
//                }
            }
            .navigationTitle("Add Item 🌭")
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
    
    // obj, text recog: below===================================================
    private func performTextRecognition(image: UIImage?){
        guard let cgimage = image?.cgImage else {
            fatalError("Unable to create CGImage from UIImage")
        }
        do {
            let imageRequestHandler = VNImageRequestHandler(cgImage: cgimage)
            
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }
                let recognizedStrings = observations.compactMap { observation in
                    // Return the string of the top VNRecognizedText instance.
                    return observation.topCandidates(1).first?.string
                }
                if self.classifyDate{
                    self.expirationDateInput = recognizedStrings.joined(separator: ", ")
                } else{
                    self.itemName = recognizedStrings.joined(separator: ", ")
                }
                
            }
            try imageRequestHandler.perform([request])
        } catch {
            print("Error: \(error)")
        }
    }

    private func processImage(image: UIImage?) {
        // 確認模型是否可用
        guard let model = model else { return }
        
        // 開始一個指定大小和比例的圖形上下文
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 224, height: 224), true, 2.0)
        
        // 在圖形上下文中繪製原始圖片到指定的矩形區域內
        if let image = imageCapture{
            image.draw(in: CGRect(x: 0, y: 0, width: 224, height: 224))
        }
        
        // 從目前的圖形上下文中獲取處理後的圖片
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        // 結束目前的圖形上下文
        UIGraphicsEndImageContext()
        
        // 將處理後的圖片轉換為像素緩衝區，以供模型輸入使用
        guard let pixelBuffer = newImage.toPixelBuffer(pixelFormatType: kCVPixelFormatType_32ARGB, width: 224, height: 224) else {
            return
        }
        
        // 使用模型和輸入的像素緩衝區進行預測
        guard let prediction = try? model.prediction(image: pixelBuffer) else {
            return
        }
        
        // 從預測結果中提取預測的類別標籤
        let classLabel = prediction.classLabel
        
        // 通過移除逗號之後的額外資訊，清理類別標籤
        let cleanedLabel = cleanClassLabel(classLabel)
        
        // 獲取與預測的類別標籤相對應的概率值
        let probability = prediction.classLabelProbs[classLabel] ?? 0
        
        // 將概率值格式化為百分比字串
        let formattedProbability = String(format: "%.2f%%", probability * 100)
        
        // 使用清理後的類別標籤和格式化後的概率值設定預測文字
//        classificationResult = cleanedLabel
        if self.classifyDate{
            self.expirationDateInput = cleanedLabel
        } else{
            self.itemName = cleanedLabel
        }
        
        // 清理類別標籤，通過移除逗號之後的額外資訊（如果存在）
        func cleanClassLabel(_ classLabel: String) -> String {
            if let commaIndex = classLabel.firstIndex(of: ",") {
                return String(classLabel[..<commaIndex])
            }
            return classLabel
        }
    }
    // obj recog: above===================================================
    init(onAdd: @escaping (Item) -> Void) {
            self.onAdd = onAdd
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

extension UIImage {
    // transform UIImage to CVPixelBuffer
    func toPixelBuffer(pixelFormatType: OSType, width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: NSNumber] = [
            kCVPixelBufferCGImageCompatibilityKey as String: NSNumber(booleanLiteral: true),
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: NSNumber(booleanLiteral: true)
        ]
        
        // create CVPixelBuffer
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, pixelFormatType, attrs as CFDictionary, &pixelBuffer)
        
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        // create CVPixelBuffer Base Address
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        // create CGContext
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        // adjust axis
        context?.translateBy(x: 0, y: CGFloat(height))
        context?.scaleBy(x: 1.0, y: -1.0)
        
        // draw graphics
        UIGraphicsPushContext(context!)
        draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        UIGraphicsPopContext()
        
        // adjust base address and return CVPixelBuffer
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}
