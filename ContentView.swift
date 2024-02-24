import SwiftUI
import Vision

struct ContentView: View {
    @State private var imageCapture : UIImage?
    @State private var showSheet = false
    @State private var classificationResult = ""
    @State private var classifyText = false
    @State private var classifyObject = false
    
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
                Button("Text"){
                    showSheet = true
                    classifyText = true
                    classifyObject = false
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .border(.gray)
                
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
                }
            }
        }) {
            // Pick an image from the photo library:
            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$imageCapture)
            // If you wish to take a photo from camera instead:
//            ImagePicker(sourceType: .camera, selectedImage: self.$imageCapture)
        }
        
        HStack{
            if let image = imageCapture {
                Button("Confirm"){
                    print("click confirm")
                    imageCapture = nil // just tmp for go back
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
                }
            }
        }) {
            // Pick an image from the photo library:
            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$imageCapture)
            // If you wish to take a photo from camera instead:
//            ImagePicker(sourceType: .camera, selectedImage: self.$imageCapture)
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

}


#Preview {
    ContentView()
}
