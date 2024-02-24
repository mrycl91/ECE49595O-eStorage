import SwiftUI
import Vision
import CoreML

struct ContentView: View {
    @State private var imageCapture : UIImage?
    @State private var showSheet = false
    @State private var classificationResult = ""
    @State private var classifyText = false
    @State private var classifyObject = false
    
    private var model: Resnet50?
    
    // initialize model
    init() {
        do {
            model = try Resnet50(configuration: MLModelConfiguration())
        } catch {
            print("Unable to initialize model\(error)")
        }
    }
    
    var body: some View {
        HStack {
            if imageCapture != nil{
                Text("Classification Result: \(classificationResult)")
                    .padding()
            }
        }
        
        VStack {
            if let image = imageCapture{
                Image(uiImage: image)
                    .resizable()
                    .padding(.all, 4)
                    .frame(width: 300, height: 400)
                    .background(Color.black.opacity(0.2))
                    .aspectRatio(contentMode: .fill)
                    .padding(8)
                
            } else{
//                Button("Text"){
//                    showSheet = true
//                    classifyText = true
//                    classifyObject = false
//                }
//                .padding(.horizontal, 20)
//                .padding(.vertical, 10)
//                .border(.gray)
                
                Button("Object"){
                    showSheet = true
                    classifyText = false
                    classifyObject = true
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .border(.gray)
            }
        }
        .padding(.horizontal, 20)
        .sheet(isPresented: $showSheet, onDismiss: {
            if let image = imageCapture{
                if classifyText{
                    performTextRecognition(image: image)
                } else{
                    processImage(image: image)
                }
            }
        }) {
            // Pick an image from the photo library:
            //            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$imageCapture)
            // If you wish to take a photo from camera instead:
            ImagePicker(sourceType: .camera, selectedImage: self.$imageCapture)
        }
        
        HStack{
            if imageCapture != nil{
                Button("Confirm"){
                    print("Click Confirm")
                    if classifyObject{
                        showSheet = true
                        classifyText = true
                        classifyObject = false
                        
                    } else{
                        imageCapture = nil // just tmp for go back
                    }
                }
                Button("Retake"){
                    showSheet = true
                }
            }
        }
        .sheet(isPresented: $showSheet, onDismiss: {
            if let image = imageCapture{
                if classifyText{
                    performTextRecognition(image: image)
                } else{
                    processImage(image: image)
                }
            }
        }) {
            // Pick an image from the photo library:
            //            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$imageCapture)
            // If you wish to take a photo from camera instead:
            ImagePicker(sourceType: .camera, selectedImage: self.$imageCapture)
        }
    }
    
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
                self.classificationResult = recognizedStrings.joined(separator: ", ")
            }
            try imageRequestHandler.perform([request])
        } catch {
            print("Error: \(error)")
        }
    }
    
    func processImage(image: UIImage?) {
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
        classificationResult = cleanedLabel
        
        // 清理類別標籤，通過移除逗號之後的額外資訊（如果存在）
        func cleanClassLabel(_ classLabel: String) -> String {
            if let commaIndex = classLabel.firstIndex(of: ",") {
                return String(classLabel[..<commaIndex])
            }
            return classLabel
        }
    }
}


#Preview {
    ContentView()
}

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
