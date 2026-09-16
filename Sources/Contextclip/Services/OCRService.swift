import Foundation
import Vision

enum OCRError: LocalizedError {
    case recognitionFailed(Error)

    var errorDescription: String? {
        switch self {
        case .recognitionFailed(let error):
            return "Text recognition failed: \(error.localizedDescription)"
        }
    }
}

enum OCRService {
    /// Recognises text in an image file and returns it as newline separated lines in reading order.
    /// Returns an empty string when nothing was found.
    static func recognizeText(in imageURL: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.automaticallyDetectsLanguage = true

                let handler = VNImageRequestHandler(url: imageURL, options: [:])
                do {
                    try handler.perform([request])
                    let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                    continuation.resume(returning: lines.joined(separator: "\n"))
                } catch {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                }
            }
        }
    }
}
