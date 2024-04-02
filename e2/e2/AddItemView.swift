import SwiftUI
import Vision
import CoreML
import Foundation

struct AddItemView: View {
    var onAdd: (Item) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var itemName = ""
    @State private var expirationDateInput = ""
    @State private var showingDatePicker = false
    @State private var navigateToBarCodeCameraView = false
    @State private var isShowingCameraView = false
    @State private var confirmAdd = false
    @State private var resfromtext=""
    
    // obj recog: below===================================================
    @State private var imageCapture : UIImage?
    @State private var showSheet = false
    @State private var classificationResult = ""
    @State private var classifyText = false
    @State private var classifyObject = false
    @State private var classifyDate = false
    @State private var scannedProductName = ""
    private var model: Resnet50? = try? Resnet50(configuration: MLModelConfiguration())

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
                            gptVision(image: image)
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
                            }
//                            } else{
//                                processImage(image: image)
//                            }
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
                }

                Button("Confirm", action: {
                    let newItem = createItem()
                    onAdd(newItem)

                    // Save the new item to UserDefaults
                    saveItemToUserDefaults(newItem)

                    // Dismiss the view
                    presentationMode.wrappedValue.dismiss()
                    
                    confirmAdd = true
                })
                .padding(30)
                .alert("Item Added Successfully", isPresented: $confirmAdd){
                    Button("OK"){
                        itemName = ""
                        expirationDateInput = ""
                        showingDatePicker = false
                        navigateToBarCodeCameraView = false
                        isShowingCameraView = false
                        confirmAdd = false
                        showSheet = false
                        classificationResult = ""
                        classifyText = false
                        classifyObject = false
                        classifyDate = false
                        scannedProductName = ""
                    }
                }
                
                NavigationLink(destination: BarCodeCameraView(scannedProductName: $itemName), isActive: $navigateToBarCodeCameraView) {
                    EmptyView()
                }
            }
            .navigationTitle("Add Item 🌭")
//            .background(Color(hex: 0xdee7e7))
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
    
    
    private func gptVision(image: UIImage?) {
        print("GPT 4 Vision")
        
        guard let imageCapture = imageCapture else {
            print("The photo is nil")
            return
        }
        
        guard let pngImage = imageCapture.pngData() else {
            print("Cannot convert to png")
            return
        }
        
        let base64_image = pngImage.base64EncodedString()
      
        let prompt = "What is the item name in the picture, it should related to food or groceries. "

        let requestData: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64_image)",
                                "detail": "low"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 20
        ]
   
        let apiKey = "apiKey"
        let apiUrl = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            print("Error serializing request data: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error calling GPT API: \(error)")
                return
            }

            guard let data = data else {
                print("No data received from GPT-4 Vision API")
                return
            }
            if let responseString = String(data: data, encoding: .utf8) {
                  if let responseData = responseString.data(using: .utf8) {
                      do {
                          let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]
                          if let choices = json?["choices"] as? [[String: Any]], let firstChoice = choices.first, let message = firstChoice["message"] as? [String: Any], let content = message["content"] as? String {
                              classificationResult = content
                          }
                      } catch {
                          print("Error decoding response from GPT-3.5 API: \(error)")
                      }
                  }
              } else {
                  print("Unable to decode response from GPT-3.5 API")
              }
          }.resume()
      }
    
    private func generateResponse(prompt: String, text: String) {
        let p = "\(prompt) here is the text string(\(text))"
        
        let requestData: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "user",
                    "content": p
                ]
            ],
            "max_tokens": 300
        ]

        let apiKey = "KEY"
        let apiUrl = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            print("Error serializing request data: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error calling GPT API: \(error)")
                return
            }

            guard let data = data else {
                print("No data received from GPT-3.5 API")
                return
            }
         
            if let responseString = String(data: data, encoding: .utf8) {
                  if let responseData = responseString.data(using: .utf8) {
                      do {
                          
                          let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]
                          if let choices = json?["choices"] as? [[String: Any]], let firstChoice = choices.first, let message = firstChoice["message"] as? [String: Any], let content = message["content"] as? String {
                              DispatchQueue.main.async {
                                                          self.resfromtext = content
                                                          
                                                          if self.classifyDate {
                                                              // Update expirationDateInput if classifying expiration date
                                                              self.expirationDateInput = self.resfromtext
                                                          } else {
                                                              // Update itemName if classifying item name
                                                              self.itemName = self.resfromtext
                                                          }
                                                      }
        
                          }
                          
                      } catch {
                          print("Error decoding response from GPT-3.5 API: \(error)")
                      }
                  }
              } else {
                  print("Unable to decode response from GPT-3.5 API")
              }
          }.resume()
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
                if self.classifyDate {
                                // If classifying expiration date, pass recognized text to GPT API with appropriate prompt
                                let prompt = "What is the expiration date of the item inside the following text? Just give me the answer like these(yyyy-mm-dd or mm-dd)"
                                self.generateResponse(prompt: prompt, text: recognizedStrings.joined(separator: ", "))
                                
                            } else {
                             
                                let prompt = "What is the food item name inside the following text?just return the name of it, for example: Milk"
                                self.generateResponse(prompt: prompt, text: recognizedStrings.joined(separator: ", "))
                                
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
