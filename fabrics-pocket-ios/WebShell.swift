//
//  WebShell.swift
//  fabrics-pocket-ios
//

import SwiftUI
import WebKit

@Observable
final class WebShell: NSObject, WKNavigationDelegate {
    let webView = WKWebView()
    // 마지막 메인 프레임 로딩이 실패한 URL. nil이 아니면 오류 화면을 덮는다.
    private(set) var failedURL: URL?
    @ObservationIgnored private var loadFailed = false

    override init() {
        super.init()
        webView.navigationDelegate = self
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
        if !loadFailed { failedURL = nil }
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
