//
//  ContentView.swift
//  fabrics-pocket-ios
//
//  Created by Junha Kim on 10/5/26.
//

import SwiftUI

struct ContentView: View {
    @State private var shell = WebShell()

    var body: some View {
        ZStack {
            WebView(webView: shell.webView)
                .ignoresSafeArea()
            if let url = shell.failedURL {
                LoadErrorView { shell.load(url) }
            }
        }
    }
}

struct LoadErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("Can't connect")
                .font(.headline)
            Text("Check your network connection and try again.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("Try again", action: onRetry)
                .buttonStyle(.borderedProminent)
                .padding(.top, 16)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    LoadErrorView {}
}
