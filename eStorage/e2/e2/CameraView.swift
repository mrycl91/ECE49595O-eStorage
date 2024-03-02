import SwiftUI
import AVFoundation
import Vision



struct CameraPreview: UIViewControllerRepresentable {
    @Binding var isShown: Bool
    @Binding var capturedImage: UIImage?

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        @Binding var isShown: Bool
        @Binding var capturedImage: UIImage?

        init(isShown: Binding<Bool>, capturedImage: Binding<UIImage?>) {
            _isShown = isShown
            _capturedImage = capturedImage
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let imageData = photo.fileDataRepresentation(), let uiImage = UIImage(data: imageData) {
                capturedImage = uiImage
                isShown = true
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(isShown: $isShown, capturedImage: $capturedImage)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video) else { return viewController }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(input)
        } catch {
            return viewController
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)

        let output = AVCapturePhotoOutput()
        captureSession.addOutput(output)
        captureSession.startRunning()

        let previewView = UIView(frame: viewController.view.frame)
        previewView.layer.addSublayer(previewLayer)
        viewController.view.addSubview(previewView)

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No update needed
    }
}

struct CameraView: View {
    @Binding var isShown: Bool
    @Binding var capturedImage: UIImage?
    @State private var showingRetakeConfirmation = false
    @State private var recognizedText: String?

    var body: some View {
        VStack {
            if let capturedImage = capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .padding()

                HStack {
                    Button("Retake") {
                        showingRetakeConfirmation = true
                    }
                    .padding()

                    Spacer()

                    Button("Use Photo") {
                        isShown = false
                        recognizeText(from: capturedImage)
                    }
                    .padding()
                }
                .padding()
                .background(Color.gray.opacity(0.8))
            } else {
                CameraPreview(isShown: $isShown, capturedImage: $capturedImage)
            }
        }
        .actionSheet(isPresented: $showingRetakeConfirmation) {
            ActionSheet(
                title: Text("Do you want to retake the photo?"),
                buttons: [
                    .default(Text("Retake"), action: {
                        capturedImage = nil
                        showingRetakeConfirmation = false
                    }),
                    .cancel(Text("Cancel"), action: {
                        showingRetakeConfirmation = false
                    })
                ]
            )
        }
    }

    private func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Error recognizing text: \(error)")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")

            self.recognizedText = recognizedText
        }

        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing text recognition: \(error)")
        }
    }
}

struct TextRecognitionResultView: View {
    var image: UIImage?
    var recognizedText: String

    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }

            Text(recognizedText)
                .padding()

            Spacer()
        }
        .navigationTitle("Text Recognition Result")
    }
}
