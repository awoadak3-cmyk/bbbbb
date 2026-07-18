import SwiftUI
@preconcurrency import WebKit

/// Shows the source site's official embed page directly (same principle as the Android version):
/// the actual playback UI/controls come from the source, we just sniff the m3u8 manifest quietly
/// in the background to power the download feature.
struct PlayerView: View {
    let url: String
    var episodeLabel: String?
    var hasNextEpisode: Bool = false
    var onNextEpisode: () -> Void = {}
    var onClose: () -> Void

    @State private var manifestURL: String?
    @State private var showDownloadSheet = false
    @State private var downloadInProgress = false
    @State private var downloadProgress: Double = 0
    @State private var downloadMessage: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            EmbedWebView(urlString: url) { manifest in
                if manifestURL == nil {
                    manifestURL = manifest
                    showDownloadSheet = true
                }
            }
            .ignoresSafeArea()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.45), in: Circle())
            }
            .padding(14)
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $showDownloadSheet) {
            downloadSheet
                .presentationDetents([.height(260)])
                .presentationBackground(AuroraColor.surfaceElevated)
        }
    }

    private var downloadSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("تنزيل هذا الفيديو").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)

            if downloadInProgress {
                Text("جاري التحميل… \(Int(downloadProgress * 100))%").foregroundStyle(.white.opacity(0.8))
                ProgressView(value: downloadProgress).tint(AuroraColor.brandRed)
            } else {
                Text(downloadMessage ?? "تم العثور على مصدر فيديو، هل ترغب بحفظه؟")
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.system(size: 14))

                HStack(spacing: 12) {
                    Button {
                        guard let manifestURL else { return }
                        downloadInProgress = true
                        Task {
                            let result = await HLSDownloader.shared.download(m3u8URL: manifestURL, referer: url) { p in
                                downloadProgress = p
                            }
                            downloadInProgress = false
                            switch result {
                            case .success(let path):
                                downloadMessage = "تم الحفظ: \(path)"
                            case .failure(let message):
                                downloadMessage = "فشل التنزيل: \(message)"
                            }
                        }
                    } label: {
                        Text("تنزيل").fontWeight(.bold).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(AuroraColor.brandRed, in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button { showDownloadSheet = false } label: {
                        Text("تخطي").foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(20)
    }
}

/// UIViewRepresentable wrapper around WKWebView that loads the embed page directly and
/// silently sniffs .m3u8 requests.
///
/// Important: unlike Android's WebViewClient.shouldInterceptRequest, WKWebView has NO native
/// hook for observing arbitrary sub-resource requests (XHR/fetch) — only full page navigations.
/// Since the manifest is virtually always fetched via the page's own JS (fetch/XHR), not a
/// full navigation, we inject a small script at document-start that monkey-patches
/// `window.fetch` and `XMLHttpRequest` to report any ".m3u8" URL back to native code via a
/// WKScriptMessageHandler. This mirrors the Android sniffing behavior faithfully.
struct EmbedWebView: UIViewRepresentable {
    let urlString: String
    let onManifestSniffed: (String) -> Void

    private static let sniffHandlerName = "auroraSniffer"

    private static let sniffScript = """
    (function() {
      if (window.__auroraPatched) return;
      window.__auroraPatched = true;

      const report = function(url) {
        try {
          if (typeof url === 'string' && url.indexOf('.m3u8') !== -1) {
            window.webkit.messageHandlers.\(sniffHandlerName).postMessage(url);
          }
        } catch (e) {}
      };

      const originalFetch = window.fetch;
      window.fetch = function(input, init) {
        try {
          const url = (typeof input === 'string') ? input : (input && input.url);
          report(url);
        } catch (e) {}
        return originalFetch.apply(this, arguments);
      };

      const originalOpen = XMLHttpRequest.prototype.open;
      XMLHttpRequest.prototype.open = function(method, url) {
        report(url);
        return originalOpen.apply(this, arguments);
      };
    })();
    """

    func makeCoordinator() -> Coordinator { Coordinator(onManifestSniffed: onManifestSniffed) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let userScript = WKUserScript(source: Self.sniffScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)
        config.userContentController.add(context.coordinator, name: Self.sniffHandlerName)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false

        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let onManifestSniffed: (String) -> Void
        private var sniffed = false

        init(onManifestSniffed: @escaping (String) -> Void) {
            self.onManifestSniffed = onManifestSniffed
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard !sniffed, let url = message.body as? String else { return }
            sniffed = true
            DispatchQueue.main.async { [onManifestSniffed] in onManifestSniffed(url) }
        }

        // Full-navigation fallback, in case the source ever links directly to the manifest.
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let urlStr = navigationAction.request.url?.absoluteString ?? ""
            if !sniffed, urlStr.contains(".m3u8") {
                sniffed = true
                let manifest = urlStr
                DispatchQueue.main.async { [onManifestSniffed] in onManifestSniffed(manifest) }
            }
            decisionHandler(.allow)
        }
    }
}
