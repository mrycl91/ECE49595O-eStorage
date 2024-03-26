import SwiftUI
import AVFoundation
import Combine

class MetadataManager: NSObject, AVCaptureMetadataOutputObjectsDelegate, ObservableObject {
    static let current = MetadataManager()
    let session = AVCaptureSession()
    @Published var productName: String = "Scanning…"
    
    func updateProductName(newValue: String) {
        self.productName = newValue
    }
    
    func confirmButtonPressed() {
        NotificationCenter.default.post(name: NSNotification.Name("ProductConfirmed"), object: self.productName)
    }
    func resetCameraSession() {
           session.startRunning() // Start the camera session again
       }
    
    private var backCamera: AVCaptureDeviceInput? {
        let camera = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        ).devices.first
        
        if let camera {
            return try? AVCaptureDeviceInput(device: camera)
        }
        return nil
    }
    
    private let metaOutput = AVCaptureMetadataOutput()
    override init() {
        super.init()
        if let backCamera {
            session.addInput(backCamera)
            session.addOutput(metaOutput)
            
            metaOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.upce]
            metaOutput.setMetadataObjectsDelegate(self, queue: .global())
        }
    }
    
    func getPreviewLayer() -> CALayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.name = "preview"
        layer.videoGravity = .resizeAspectFill
        return layer
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        session.stopRunning()
        print("Stop Running")
        DispatchQueue.main.async {
            metadataObjects.forEach { data in
                if let data = data as? AVMetadataMachineReadableCodeObject,
                   let value = data.stringValue {
                    print("Barcode Info: \(value)")
                    self.fetchProductByUPC(upc: value)
                }
            }
        }
    }
    
    func fetchProductByUPC(upc: String) {
        let apiKey = "231f31b11e2978aa36f44764d5cfdb9f4d09079b113409f1e5b3e273ed10aacd"
        let urlString = "https://go-upc.com/api/v1/code/\(upc)?key=\(apiKey)" // Replace with the actual API endpoint from Go-UPC
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error with fetching product: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let data = data else {
                    print("Error with the response, unexpected status code: \(String(describing: response))")
                    return
                }
                
                do {
                    let productInfo = try JSONDecoder().decode(ProductInfo.self, from: data)
                    DispatchQueue.main.async {
                        self.productName = productInfo.product.name
                    }
                    print(self.productName)
                } catch {
                    print("JSON decoding error: \(error)")
                    DispatchQueue.main.async {
                        self.productName = "Product Not Found"
                    }
                }
            }
            task.resume()
        }
    }
}

struct PreviewView: UIViewRepresentable {
    var previewLayer: CALayer
    var proxy: GeometryProxy
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        let previewLayer = uiView.layer.sublayers?.first { layer in
            layer.name == "preview"
        }
        if let previewLayer {
            previewLayer.frame = proxy.frame(in: .local)
        }
    }
    
    typealias UIViewType = UIView
}

struct BarCodeCameraView: View {
    @ObservedObject private var avManager = MetadataManager.current
    @Binding var scannedProductName: String 
    private let avman = MetadataManager.current.getPreviewLayer()
    @Environment(\.presentationMode) var presentationMode // Add this line

    init(scannedProductName: Binding<String>) {
            self._scannedProductName = scannedProductName // Initialize the binding
        }

    var body: some View {
        VStack {
            Text(avManager.productName) // Display the dynamically updated product name
                            .padding()
                            .background(Color.white.opacity(0.85))
                            .cornerRadius(8)
            
            GeometryReader { proxy in
                PreviewView(
                    previewLayer: avman,
                    proxy: proxy
                )
                .background(.blue.opacity(0.1))
                .onAppear{
                    DispatchQueue.global().async {
                        MetadataManager.current.session.startRunning()
                        print("Start Running")
                    }
                }
            }
            .frame(width: 380, height:300)
            
            // Add the Confirm button
            Button("Confirm") {
                avManager.confirmButtonPressed()
                scannedProductName = avManager.productName
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            Button("Retake") {
                avManager.resetCameraSession() // Reset the camera session

                avManager.updateProductName(newValue: "Scanning...")
                        }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .onAppear{
            avManager.updateProductName(newValue: "Scanning...")
        }
       
    }
}

struct BarCodeCameraView_Previews: PreviewProvider {
    static var previews: some View {
        BarCodeCameraView(scannedProductName: .constant(""))
    }
}

struct ProductInfo: Codable {
    let code: String
    let codeType: String
    let product: Product
    let barcodeUrl: String
}

struct Product: Codable {
    let name: String
    let description: String
    let imageUrl: String
    let brand: String
    let specs: [[String]]
    let category: String
}
