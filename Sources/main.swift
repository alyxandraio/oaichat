//
//  main.swift
//  oaichat
//
//  Created by Alyxandra Ferrari on 1/1/2025.
//

// To anyone who may have the misfortune of reading this:
// I know this isn't the most well-written program of
// all-time. I'm planning on cleaning it up once I finish implementation
// of the full feature set I wish to include with the 1.0 release.
// All that to say, you don't have to point out to me that
// this sucks. I'm very aware and it's on my radar. Besides
// that, thank you for showing interest in my project!

import Foundation
import ArgumentParser

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class oaichat: ParsableCommand {
    
    @Option(help: "The OpenAI model with which to converse.") var model: String?
    @Option(help: "The OpenAI API endpoint with which to communicate; appended to assumed static prefix of '\(ProcessInfo.processInfo.environment["TERM_PROGRAM"] == nil ? "" : oaichat.cyan)https://api.openai.com/v1/\(ProcessInfo.processInfo.environment["TERM_PROGRAM"] == nil ? "" : oaichat.reset)'.") var endpoint: String? // my deepest apologies to any poor soul with the misfortune of having to read this abomination, i'll have a parking space in hell right next to satan's for this one
    
    // ANSI escape sequence constants
    static let violet = "\u{001B}[38;5;183m"
    static let green = "\u{001B}[32m"
    static let cyan = "\u{001B}[36m"
    static let red = "\u{001B}[31m"
    static let reset = "\u{001B}[0m"
    static let up = "\u{001B}[1A"
    static let down = "\u{001B}[1B"
    
    static let standardPrompt = "\(oaichat.cyan)(user)> \(oaichat.reset)"
    static let standardPromptStripped = "(user)> "
    
    static let systemPrompt = "(system)> "
    
    static let keyComponent = ".config/"
    static let keyComponent2 = "oaichat/"
    static let keyComponent3 = "openai_api_key.txt"
    static let keyComponent4 = "conversations/"
    static let keyComponent5 = "oaichat_config.json"
    
    var messages: [GPTMessage] = []
    var apiKey: String?
    var defaultModel = "gpt-4o-mini"
    var strippedTerm = ProcessInfo.processInfo.environment["TERM_PROGRAM"] == nil
    
    var modelPrompt: String? {
        guard let model = model else { return nil }
        return "\(oaichat.cyan)(\(model))> \(oaichat.reset)"
    }
    
    var modelPromptStripped: String? {
        guard let model = model else { return nil }
        return "(\(model))> "
    }
    
    func run() throws {
        let configURL = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(oaichat.keyComponent)
            .appendingPathComponent(oaichat.keyComponent2)
            .appendingPathComponent(oaichat.keyComponent5)
        let configPath = configURL.path()
        
        do {
            let configData = try Data(contentsOf: configURL)
            let decoder = JSONDecoder()
            let config = try decoder.decode(OaichatConfiguration.self, from: configData)
            apiKey = config.api_key
            if let default_model = config.default_model {
                defaultModel = default_model
            }
        } catch {
            if strippedTerm {
                cprint("<!> Missing or invalid oaichat configuration JSON data found at '\(configPath)'. <!>\n")
            } else {
                cprint("\(oaichat.red)<!>\(oaichat.reset) Missing or invalid \(oaichat.cyan)oaichat\(oaichat.reset) configuration JSON data found at '\(oaichat.cyan)\(configPath)\(oaichat.reset)'. \(oaichat.red)<!>\(oaichat.reset)\n")
            }
            cprint("\n")
            cprint(error.localizedDescription)
            cprint("\n")
            return
        }
        
        guard let apiKey = apiKey else { return }
        
        cprint("\n")
        cprint("\(oaichat.violet)oaichat\(oaichat.reset)")
        cprint("\n\n")
        
        cprint("Compilation build configuration: ")
        if strippedTerm {
            #if DEBUG
            cprifdh.$h.ft("DEBUG")
            #else
            cprint("RELEASE")
            #endif
        } else {
            #if DEBUG
            cprint("\(oaichat.cyan)DEBUG\(oaichat.reset)")
            #else
            cprint("\(oaichat.cyan)RELEASE\(oaichat.reset)")
            #endif
        }
        cprint("\n")
        
        if strippedTerm {
            cprint("OpenAI API Key: \(apiKey.prefix(3))...\(apiKey.suffix(4))")
            cprint("\n")
            cprint("Within Xcode terminal emulator: \(strippedTerm ? "yes" : "no")")
            cprint("\n\n")
        } else {
            cprint("OpenAI API Key: \(oaichat.cyan)\(apiKey.prefix(3))...\(apiKey.suffix(4))\(oaichat.reset)")
            cprint("\n")
            cprint("Within Xcode terminal emulator: \(oaichat.cyan)\(strippedTerm ? "yes" : "no")\(oaichat.reset)")
            cprint("\n\n")
        }
        
        model: if model == nil {
            if strippedTerm {
                cprint("OpenAI Model (default to 'o4-mini'): ")
                guard let input = readLine() else {
                    model = "o4-mini"
                    cprint("\nCould not read stdin, defaulting to '\(model!)'.")
                    break model
                }
                model = input.isEmpty ? "o4-mini" : input
            } else {
                cprint("OpenAI Model (default to '\(oaichat.cyan)o4-mini\(oaichat.reset)'): ")
                guard let input = readLine() else {
                    model = "o4-mini"
                    cprint("\nCould not read stdin, defaulting to '\(oaichat.cyan)\(model!)\(oaichat.reset)'.")
                    break model
                }
                model = input.isEmpty ? "o4-mini" : input
            }
        }
        
        endpoint: if endpoint == nil {
            if strippedTerm {
                cprint("OpenAI API Endpoint (default to 'api.openai.com/...'): ")
                guard let input = readLine() else {
                    endpoint = "https://api.openai.com/v1/chat/completions"
                    cprint("\nCould not read stdin, defaulting to 'chat/completions'.")
                    break endpoint
                }
                endpoint = input.isEmpty ? "https://api.openai.com/v1/chat/completions" : input
            } else {
                cprint("OpenAI API Endpoint (default to '\(oaichat.cyan)chat/completions\(oaichat.reset)'): ")
                guard let input = readLine() else {
                    endpoint = "https://api.openai.com/v1/chat/completions"
                    cprint("\nCould not read stdin, defaulting to '\(oaichat.cyan)chat/completions\(oaichat.reset)'.")
                    break endpoint
                }
                endpoint = input.isEmpty ? "https://api.openai.com/v1/chat/completions" : input
            }
        }
        
        guard var model = model else { return }
        guard var endpoint = endpoint else { return }
        
        for _ in 1...200 { cprint("\n") } // clear terminal
        
        while true {
            cprint(strippedTerm ? oaichat.standardPromptStripped : oaichat.standardPrompt)
            guard let stdinput = readLine() else { break }
            var input = stdinput
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "[", with: "\\[")
                .replacingOccurrences(of: "]", with: "\\]")
                .replacingOccurrences(of: "{", with: "\\{")
                .replacingOccurrences(of: "}", with: "\\}")
            
            colon: if input.starts(with: ":") {
                if !strippedTerm {
                    cprint("\(oaichat.up)\r\(oaichat.violet)\(oaichat.standardPrompt)\(oaichat.violet)\(input)\(oaichat.reset)\(oaichat.down)\r")
                }
                let inputDeriv = input.dropFirst()
                
                let elements = inputDeriv.split(separator: " ")
                guard let first = elements.first else { break }
                switch first { // TODO: `strippedTerm` conditional breaks for `cprint` calls containing an ANSI sequence
                    case "q":
                        if strippedTerm {
                            cprint("(system)> \(oaichat.reset)Issued SIGTERM.\n\n")
                        } else {
                            cprint("\(oaichat.green)(system)> \(oaichat.reset)Issued SIGTERM.\n\n")
                        }
                        return
                    case "quit":
                        if strippedTerm {
                            cprint("(system)> \(oaichat.reset)Issued SIGTERM.\n\n")
                        } else {
                            cprint("\(oaichat.green)(system)> \(oaichat.reset)Issued SIGTERM.\n\n")
                        }
                        return
                    case "model":
                        guard elements.count > 1 else {
                            cprint("\(oaichat.red)(system)> \(oaichat.reset)Usage: \(oaichat.cyan):model <model>\(oaichat.reset).\n\n")
                            break
                        }
                        model = String(elements[1])
                        #if DEBUG
                        cprint("\n\nDEBUG MODEL UPDATE:\n\(model)\n\n")
                        #endif
                        cprint("\(oaichat.green)(system)> \(oaichat.reset)Model updated.\n\n")
                    case "endpoint":
                        guard elements.count > 1 else {
                            cprint("\(oaichat.red)(system)> \(oaichat.reset)Usage: \(oaichat.cyan):endpoint <endpoint>\(oaichat.reset).\n\n")
                            break
                        }
                        endpoint = String(elements[1])
                        cprint("\(oaichat.green)(system)> \(oaichat.reset)Endpoint updated.\n\n")
                    case "h":
                        cprint("\(oaichat.green)(system)> \(oaichat.reset) commands – :h, :help, :q, :quit, :model, :endpoint, :save, :apikey, :file, :default\n\n")
                    case "help":
                        cprint("\(oaichat.green)(system)> \(oaichat.reset) commands – :h, :help, :q, :quit, :model, :endpoint, :save, :apikey, :file\n\n")
                    case "save":
                        guard elements.count > 1 else {
                            cprint("\(oaichat.red)(system)> \(oaichat.reset)Usage: \(oaichat.cyan):save <path>\(oaichat.reset).\n\n")
                            break
                        }
                        let path = String(elements[1])
                        var messagesJson = ""
                        for message in messages {
                            messagesJson += """
                            {
                                "role": "\(message.participant.decoded)",
                                "content": "\(message.content)"
                            },\n
                            """
                        }
                        
                        let json = """
                        {
                            "model": "\(model)",
                            "messages": [
                                \(messagesJson)
                                {
                                    "role": "user",
                                    "content": "\(inputDeriv)"
                                }
                            ]
                        }
                        """
                        do {
                            if #available(macOS 13.0, *) {
                                try json.write(to: URL(filePath: path), atomically: true, encoding: .utf8)
                            } else {
                                cprint("\(oaichat.red)(system)> \(oaichat.reset)Available on macOS 13+ only.\n\n")
                                break
                            }
                            cprint("\(oaichat.green)(system)> \(oaichat.reset)Saved conversation successfully.\n\n")
                        } catch {
                            cprint("\(oaichat.red)(system)> \(oaichat.reset)Error saving conversation.\n\n")
                        }
                    case "apikey":
                        guard elements.count > 1 else {
                            cprint("\(oaichat.red)(system)> \(oaichat.reset)Usage: \(oaichat.cyan):apikey <key>\(oaichat.reset).\n\n")
                            break
                        }
                        cprint("\(oaichat.up)\r")
                        _ = clsprint()
                        cprint("\r")
                        let key = elements[1]
                        self.apiKey = String(key)
                        let manager = FileManager.default
                        let configDirectoryPath = configURL.deletingLastPathComponent().path()
                        if !manager.fileExists(atPath: configDirectoryPath) {
                            do {
                                try manager.createDirectory(atPath: configDirectoryPath, withIntermediateDirectories: true)
                            } catch {
                                cprint("\(oaichat.red)(system)> \(oaichat.reset)Error creating config directory.\n")
                                _ = clsprint()
                                cprint("\r\n")
                                break
                            }
                        }
                        do {
                            let config = OaichatConfiguration(api_key: String(self.apiKey!), default_model: self.defaultModel)
                            let jsonData = try JSONEncoder().encode(config)
                            try jsonData.write(to: configURL)
                            
                            cprint("\(oaichat.green)(system)> \(oaichat.reset)Successfully changed API key.\n")
                            _ = clsprint()
                            cprint("\r\n")
                        } catch {
                            cprint("\(oaichat.red)(system)> \(oaichat.reset)Error saving API key.\n\n")
                            _ = clsprint()
                            cprint("\r\n")
                        }
                    case "file":
                        guard elements.count > 1 else {
                            cprint("\(oaichat.red)(system)> \(oaichat.reset)Usage: \(oaichat.cyan):file <path>\(oaichat.reset).\n\n")
                            break
                        }
                        let path = String(elements[1])
                        let file = URL(fileURLWithPath: path)
                        do {
                            let contents = try String(contentsOf: file, encoding: .utf8)
                            input = contents
                                .replacingOccurrences(of: "\"", with: "\\\"")
                                .replacingOccurrences(of: "\n", with: "\\n")
                                .replacingOccurrences(of: "[", with: "\\[")
                                .replacingOccurrences(of: "]", with: "\\]")
                                .replacingOccurrences(of: "{", with: "\\{")
                                .replacingOccurrences(of: "}", with: "\\}")
                            break colon
                        } catch {
                            cprint("\(oaichat.red)(system)> \(oaichat.reset)Error reading prompt from disk.\n\n")
                        }
                    case "default":
                        guard elements.count > 1 else {
                            cprint("\(oaichat.red)(system)> \(oaichat.reset)Usage: \(oaichat.cyan):default <model>\(oaichat.reset).\n\n")
                            break
                        }
                        cprint("\(oaichat.up)\r")
                        _ = clsprint()
                        cprint("\r")
                        let key = elements[1]
                        self.apiKey = String(key)
                        let manager = FileManager.default
                        let configDirectoryPath = configURL.deletingLastPathComponent().path()
                        if !manager.fileExists(atPath: configDirectoryPath) {
                            do {
                                try manager.createDirectory(atPath: configDirectoryPath, withIntermediateDirectories: true)
                            } catch {
                                cprint("\(oaichat.red)(system)> \(oaichat.reset)Error creating config directory.\n")
                                _ = clsprint()
                                cprint("\r\n")
                                break
                            }
                        }
                        do {
                            let config = OaichatConfiguration(api_key: String(self.apiKey!), default_model: self.defaultModel)
                            let jsonData = try JSONEncoder().encode(config)
                            try jsonData.write(to: configURL)
                            
                            cprint("\(oaichat.green)(system)> \(oaichat.reset)Successfully changed API key.\n")
                            _ = clsprint()
                            cprint("\r\n")
                        } catch {
                            cprint("\(oaichat.red)(system)> \(oaichat.reset)Error saving API key.\n\n")
                            _ = clsprint()
                            cprint("\r\n")
                        }
                    default:
                        cprint("\(oaichat.red)(system)> \(oaichat.reset)Unknown sequence. Try \(oaichat.cyan):help\(oaichat.reset).\n\n")
                }
                
                continue
            }
            
            for _ in 0...0 { cprint("\n") } // iterate once; intentionally verbose in the interest of maximising readability over function
            let url = URL(string: endpoint)!
            var request = URLRequest(url: url)
            request.timeoutInterval = 300
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            var queryMessages: [[String: Any]] = [["role": "user", "content": input]]
            for message in messages { queryMessages.insert(contentsOf: [["role": message.participant.decoded, "content": message.content]], at: 0) }
            let query: [String: Any] = ["model": model, "messages": queryMessages]
            let jsonData = try JSONSerialization.data(withJSONObject: query)
            request.httpBody = jsonData
            
            var waiting = true
            var response: Data?
            var error: (any Error)?
            let task = URLSession.shared.dataTask(with: request) { data, httpResponse, httpError in
                if let httpError = httpError {
                    print("\n\nerror: \(httpError)")
                    error = httpError
                    waiting = false
                    return
                }
                
                if let httpResponse = httpResponse as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    print("\n\nhttp error: \(httpResponse.statusCode)")
                    if let data = data { print("\nJSON RESPONSE:\n\(String(data: data, encoding: .utf8)!)\n\n") }
                    waiting = false
                    return
                }
                
                if let data = data { response = data }
                waiting = false
            }
            task.resume()
            
            cprint("\(oaichat.cyan)(\(model))> \(oaichat.reset)thinking")
            var state: Int = 0
            while waiting {
                fflush(stdout)
                usleep(160_000) // 100,000 µs == 1/10 s == 0.1 s
                
                state += 1
                if state > 5 { state = 0 } // clamping and uint2 overflow enforcement
                
                //var ellipsis = ""
                //for _ in 0..<state { ellipsis += "." } // range of `state` is 0...3; count of periods in ellipsis evaluated by interpretation of `state` as a count
                //for _ in state..<3 { ellipsis += " " }
                
                let ellipsis = [
                    0: "   ",
                    1: ".  ",
                    2: ".. ",
                    3: "...",
                    4: " ..",
                    5: "  .",
                ]
                
                let index = ellipsis[state]
                guard let index = index else { return }
                cprint("\r\(oaichat.cyan)(\(model))> \(oaichat.reset)thinking\(index)")
            }
            
            if let _ = error { break }
            guard let response = response else { break }
            
            #if DEBUG
            cprint("\n\nDEBUG JSON RESPONSE:\n\(String(data: response, encoding: .utf8)!)\n\n")
            
            var schema: GPTResponse?
            do {
                schema = try JSONDecoder().decode(GPTResponse.self, from: response)
            } catch {
                cprint("\n\nerror: \(error)\n\n")
                return
            }
            #else
            let schema = try? JSONDecoder().decode(GPTResponse.self, from: response)
            #endif
            
            guard let schema = schema else { break }
            guard schema.choices.count > 0 else { break }
            guard schema.choices.first!.message.role == "assistant" else { break } // assertion for sanity
            
            cprint("\r\(oaichat.cyan)(\(model))> \(oaichat.reset)")
            for character in schema.choices.first!.message.content {
                cprint(String(character))
                fflush(stdout)
                usleep(1750)
            }
            
            for _ in 0...1 { cprint("\n") } // iterate twice
            
            let user = GPTMessage(participant: .user, content: input)
            let assistant = GPTMessage(
                participant: .assistant,
                content: schema.choices.first!.message.content
                    .replacingOccurrences(of: "\"", with: "\\\"")
                    .replacingOccurrences(of: "\n", with: "\\n")
                    .replacingOccurrences(of: "[", with: "\\[")
                    .replacingOccurrences(of: "]", with: "\\]")
                    .replacingOccurrences(of: "{", with: "\\{")
                    .replacingOccurrences(of: "}", with: "\\}")
                
            )
            messages += [user, assistant]
        }
        
        cprint("\n\nsomething shat itself! frowny face :(\n")
    }
    
    func cprint(_ str: String) { print(str, terminator: "") }
    
    func clsprint() -> Bool {
        if let columns = getenv("COLUMNS"), let width = Int(String(cString: columns)) {
            cprint(String(repeating: " ", count: width))
            return true
        }
        print("NOOOOOO WHAT")
        print(getenv("COLUMNS") as Any)
        return false
    }
}

enum GPTParticipant: Codable {
    case assistant
    case user
    case developer
}

extension GPTParticipant {
    var decoded: String {
        switch self {
            case .assistant:
                "assistant"
            case .user:
                "user"
            case .developer:
                "developer"
        }
    }
}

struct GPTMessage: Codable {
    let participant: GPTParticipant
    let content: String
}

struct GPTResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [GPTResponse2]
    let system_fingerprint: String?
}

struct GPTResponse2: Codable {
    let index: Int
    let message: GPTResponse3
    let logprobs: String?
    let finish_reason: String
}

struct GPTResponse3: Codable {
    let role: String
    let content: String
    let refusal: String?
}

struct GPTResponse4: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
    let prompt_tokens_details: GPTResponse5
    let completion_tokens_details: GPTResponse6
}

struct GPTResponse5: Codable {
    let cached_tokens: Int
    let audio_tokens: Int
}

struct GPTResponse6: Codable {
    let reasoning_tokens: Int
    let audio_tokens: Int
    let accepted_prediction_tokens: Int
    let rejected_prediction_tokens: Int
}

struct OaichatConfiguration: Codable {
    let api_key: String
    let default_model: String?
}

oaichat.main()
