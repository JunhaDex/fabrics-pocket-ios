//
//  Bridge.swift
//  fabrics-pocket-ios
//

import WebKit

// 결과 코드는 브릿지 계약 문서의 레지스트리 표가 원본이다. 이름을 그대로 옮긴다.
enum CancelCode: String { case USER_CANCELED, PERMISSION_DENIED, PERMISSION_BLOCKED }

enum ErrorCode: String { case UNSUPPORTED, INVALID_PARAMS, BUSY, UNAVAILABLE, INTERNAL }

enum BridgeResult {
    case ok([String: Any] = [:])
    case canceled(CancelCode)
    case error(ErrorCode)
}

/// 메서드 하나의 구현. 사용자 조작을 기다리는 메서드가 있으므로 결과는 콜백으로 한 번 돌려준다.
typealias BridgeHandler = @MainActor (_ params: [String: Any], _ reply: @escaping (BridgeResult) -> Void) -> Void

/// 웹뷰와 네이티브 사이의 브릿지. 와이어 형식과 규칙은 브릿지 계약 문서를 따른다.
///
/// capability 목록은 `handlers`의 키에서 만든다. 구현되지 않은 메서드는 목록에 들어갈 수 없다.
/// `WKUserContentController`가 이 객체를 강하게 참조하므로 웹뷰는 weak로 둔다.
final class Bridge: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?
    private let handlers: [String: BridgeHandler]
    private let allowedHosts: Set<String>
    private let script: WKUserScript

    init(handlers: [String: BridgeHandler], allowedHosts: Set<String>, runtimeVersion: String) {
        self.handlers = handlers
        self.allowedHosts = allowedHosts
        let config: [String: Any] = [
            "capabilities": handlers.keys.sorted(),
            "runtimeVersion": runtimeVersion,
            "hosts": Array(allowedHosts),
        ]
        let json = String(decoding: try! JSONSerialization.data(withJSONObject: config), as: UTF8.self)
        let url = Bundle.main.url(forResource: "bridge", withExtension: "js")!
        let source = try! String(contentsOf: url, encoding: .utf8)
            .replacingOccurrences(of: "/*BRIDGE_CONFIG*/", with: json)
        script = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        super.init()
    }

    /// 웹뷰를 생성하기 전에 configuration에 스크립트와 메시지 핸들러를 넣는다.
    func install(in configuration: WKWebViewConfiguration) {
        configuration.userContentController.addUserScript(script)
        configuration.userContentController.add(self, name: "nativeBridgeChannel")
    }

    func emit(_ event: String, data: [String: Any] = [:]) {
        send(["event": event, "data": data])
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame,
              allowedHosts.contains(message.frameInfo.securityOrigin.host),
              let raw = message.body as? String,
              let body = (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any],
              body["ready"] == nil,
              let id = body["id"] as? String else { return }
        let reply: (BridgeResult) -> Void = { [weak self] result in self?.send(Self.encode(id, result)) }
        guard let method = body["method"] as? String, let handler = handlers[method] else {
            return reply(.error(.UNSUPPORTED))
        }
        guard let params = body["params"].map({ $0 as? [String: Any] }) ?? [:] else {
            return reply(.error(.INVALID_PARAMS))
        }
        handler(params, reply)
    }

    private func send(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message) else { return }
        webView?.callAsyncJavaScript(
            "window.__nativeBridgeReceive(m)",
            arguments: ["m": String(decoding: data, as: UTF8.self)],
            in: nil,
            in: .page,
            completionHandler: nil
        )
    }

    private static func encode(_ id: String, _ result: BridgeResult) -> [String: Any] {
        switch result {
        case .ok(let data): ["id": id, "status": "ok", "data": data]
        case .canceled(let code): ["id": id, "status": "canceled", "code": code.rawValue]
        case .error(let code): ["id": id, "status": "error", "code": code.rawValue]
        }
    }
}
