import Foundation

struct GeminiService {
    struct APIError: LocalizedError, Decodable {
        let code: Int?
        let message: String
        var errorDescription: String? { message }
    }

    func rewriteToJapanese(input: String, apiKey: String, model: String, temperature: Double) async throws -> String {
        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!

        let systemPrompt = """
        あなたは熟練の日本語コミュニケーションアシスタントです。以下の指示に厳密に従って、入力内容を「職場の Slack にそのまま投稿できる自然な日本語」に整えてください。

        ルール：
        - 口調：丁寧すぎず、くだけすぎず。親しみやすく、プロフェッショナル。
        - 文体：簡潔・自然・読みやすい。過剰な敬語や硬さを避ける。
        - 意図：元の意味・重要情報・ニュアンスを正確に保持。
        - 混在入力：英語・中国語・和訳済みの混在を許容し、必要に応じ自然な日本語に統一。
        - Slack：箇条書き・コード・URL などは壊さず保持。顔文字や絵文字は控えめに。
        - 過度な言い換えは禁止。襟を正すほどではないが失礼にならない距離感。
        - すでに日本語の場合は、自然さ・簡潔さ・仕事場向けの調整のみ行い大きく変えない。

        返答は日本語のみ。前置き・説明・「以下です」等は不要。必要に応じて適切に段落・箇条書きを使ってよい。
        """

        let userText = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return "" }

        let req = GenerateContentRequest(
            systemInstruction: Content(role: "system", parts: [Part(text: systemPrompt)]),
            contents: [Content(role: "user", parts: [Part(text: userText)])],
            generationConfig: GenerationConfig(temperature: temperature, topK: 50, topP: 0.95)
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(req)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200..<300).contains(http.statusCode) == false {
            if let apiErr = try? JSONDecoder().decode(GoogleErrorEnvelope.self, from: data) {
                throw apiErr.error
            }
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(GenerateContentResponse.self, from: data)
        if let text = decoded.candidates?.first?.content.parts?.compactMap({ $0.text }).joined(), !text.isEmpty {
            return text
        }
        if let finish = decoded.candidates?.first?.finishReason, finish == "SAFETY" {
            throw NSError(domain: "Gemini", code: -2, userInfo: [NSLocalizedDescriptionKey: "请求被安全策略拦截"])
        }
        throw NSError(domain: "Gemini", code: -1, userInfo: [NSLocalizedDescriptionKey: "未返回有效文本"])
    }
}

// MARK: - Models

struct GenerateContentRequest: Codable {
    let systemInstruction: Content
    let contents: [Content]
    let generationConfig: GenerationConfig
}

struct Content: Codable {
    let role: String?
    let parts: [Part]?
}

struct Part: Codable {
    let text: String?
}

struct GenerationConfig: Codable {
    let temperature: Double?
    let topK: Int?
    let topP: Double?
}

struct GenerateContentResponse: Codable {
    let candidates: [Candidate]?
}

struct Candidate: Codable {
    let content: Content
    let finishReason: String?
}

struct GoogleErrorEnvelope: Decodable {
    let error: GeminiService.APIError
}

