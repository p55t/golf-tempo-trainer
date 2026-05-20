import Foundation

enum ElevenLabsService {
    // Adam — clear neutral male voice, works well for short cues
    private static let voiceID = "pNInz6obpgDQGcFmaJgB"
    private static let model   = "eleven_turbo_v2_5"

    static func generateSpeech(text: String, apiKey: String) async throws -> Data {
        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)") else {
            throw ServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.httpBody = try JSONEncoder().encode(SpeechRequest(
            text: text,
            modelId: model,
            voiceSettings: .init(stability: 0.8, similarityBoost: 0.5)
        ))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown error"
            throw ServiceError.apiError(msg)
        }
        return data
    }

    // MARK: Models

    private struct SpeechRequest: Encodable {
        let text: String
        let modelId: String
        let voiceSettings: VoiceSettings

        enum CodingKeys: String, CodingKey {
            case text, voiceSettings
            case modelId = "model_id"
        }
    }

    private struct VoiceSettings: Encodable {
        let stability: Double
        let similarityBoost: Double

        enum CodingKeys: String, CodingKey {
            case stability
            case similarityBoost = "similarity_boost"
        }
    }

    enum ServiceError: LocalizedError {
        case invalidURL
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL:         return "Invalid ElevenLabs URL."
            case .apiError(let msg):  return "ElevenLabs API error: \(msg)"
            }
        }
    }
}
