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
            if !shell.launched {
                LaunchView()
            }
            if let url = shell.failedURL {
                LoadErrorView { shell.load(url) }
            }
        }
    }
}

// 시스템 launch screen 다음 단계. 같은 배경색 위에 로고(앱 아이콘)와 스피너를 둔다.
struct LaunchView: View {
    var body: some View {
        VStack(spacing: 24) {
            // 브랜딩 자산이 생기기 전까지 앱 아이콘을 쓰고, 없으면 생략한다.
            if let icon = UIImage(named: "AppIcon") {
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.background))
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
