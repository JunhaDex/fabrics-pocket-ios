//
//  WebShell.swift
//  fabrics-pocket-ios
//

import SwiftUI
import WebKit

@Observable
final class WebShell: NSObject, WKNavigationDelegate, WKUIDelegate {
    let webView = WKWebView()
    // 마지막 메인 프레임 로딩이 실패한 URL. nil이 아니면 오류 화면을 덮는다.
    private(set) var failedURL: URL?
    // 첫 메인 프레임 로딩이 실패 없이 끝났는지. true가 되면 로딩 화면을 걷고 다시 띄우지 않는다.
    private(set) var launched = false
    @ObservationIgnored private var loadFailed = false
    // 웹뷰 안에서 표시할 호스트. 포트는 보지 않는다.
    private let allowedHosts: Set<String>

    override init() {
        let hosts = Bundle.main.object(forInfoDictionaryKey: "PocketAllowedHosts") as? String ?? ""
        allowedHosts = Set(hosts.split(separator: " ").map(String.init))
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        // 문서 교체 사이에 기본 흰 배경이 비치지 않도록 시작 화면과 같은 색을 깐다.
        webView.isOpaque = false
        webView.backgroundColor = UIColor(resource: .background)
        webView.scrollView.backgroundColor = UIColor(resource: .background)
        // 웹이 env()로 safe area를 처리하므로 스크롤 뷰가 inset을 중복 적용하지 않게 한다.
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        #if DEBUG
        webView.isInspectable = true
        #endif
        if let value = Bundle.main.object(forInfoDictionaryKey: "PocketStartURL") as? String,
           let url = URL(string: value) {
            load(url)
        }
    }

    func load(_ url: URL) {
        webView.load(URLRequest(url: url))
    }

    // 메인 프레임이 허용 호스트 밖으로 가면 시스템에 넘긴다. 내부 이동은 그대로 통과시켜야
    // cross-document View Transitions가 유지된다.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        if let frame = navigationAction.targetFrame, !frame.isMainFrame {
            return decisionHandler(.allow)
        }
        guard let url = navigationAction.request.url,
              !isAllowed(url), !["about", "data", "blob"].contains(url.scheme) else {
            return decisionHandler(.allow)
        }
        UIApplication.shared.open(url)
        decisionHandler(.cancel)
    }

    // target=_blank와 window.open. 새 창은 만들지 않고, 허용 호스트면 현재 웹뷰에서 연다.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            if isAllowed(url) {
                webView.load(navigationAction.request)
            } else {
                UIApplication.shared.open(url)
            }
        }
        return nil
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadFailed = false
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        fail(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        fail(error)
    }

    // 재시도가 성공할 때까지 오류 화면을 유지한다.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !loadFailed {
            failedURL = nil
            launched = true
        }
    }

    private func isAllowed(_ url: URL) -> Bool {
        ["http", "https"].contains(url.scheme) && allowedHosts.contains(url.host() ?? "")
    }

    private func fail(_ error: Error) {
        let error = error as NSError
        if error.code == NSURLErrorCancelled { return }
        loadFailed = true
        failedURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL ?? webView.url
    }
}

struct WebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView { webView }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
