//
//  VelonLegalWebViewController.swift
//  velon
//

import UIKit
import WebKit

final class VelonLegalWebViewController: UIViewController, WKNavigationDelegate {
    private let pageTitle: String
    private let pageURL: URL
    private let webView = WKWebView(frame: .zero)
    private let spinner = UIActivityIndicatorView(style: .large)
    private let errorPanel = VelonUIFactory.glassPanel()
    private let errorLabel = VelonUIFactory.bodyLabel("")
    private let retryButton = VelonUIFactory.primaryButton(title: "Try Again")

    init(title: String, url: URL) {
        self.pageTitle = title
        self.pageURL = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = pageTitle
        view.backgroundColor = VelonTheme.creamSurface
        _ = velonInstallAmbient(.profile)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.backgroundColor = .clear
        webView.isOpaque = false
        view.addSubview(webView)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = VelonTheme.primaryDeep
        view.addSubview(spinner)

        errorPanel.translatesAutoresizingMaskIntoConstraints = false
        errorPanel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textAlignment = .center
        errorLabel.text = "We could not load this page. Check your connection and try again."
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.addTarget(self, action: #selector(reloadPage), for: .touchUpInside)
        errorPanel.addSubview(errorLabel)
        errorPanel.addSubview(retryButton)
        view.addSubview(errorPanel)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorPanel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            errorLabel.topAnchor.constraint(equalTo: errorPanel.topAnchor, constant: 20),
            errorLabel.leadingAnchor.constraint(equalTo: errorPanel.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: errorPanel.trailingAnchor, constant: -16),
            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 14),
            retryButton.leadingAnchor.constraint(equalTo: errorPanel.leadingAnchor, constant: 16),
            retryButton.trailingAnchor.constraint(equalTo: errorPanel.trailingAnchor, constant: -16),
            retryButton.bottomAnchor.constraint(equalTo: errorPanel.bottomAnchor, constant: -20)
        ])

        reloadPage()
    }

    @objc private func reloadPage() {
        errorPanel.isHidden = true
        webView.isHidden = false
        spinner.startAnimating()
        webView.load(URLRequest(url: pageURL))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
        errorPanel.isHidden = true
        webView.isHidden = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showLoadError()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showLoadError()
    }

    private func showLoadError() {
        spinner.stopAnimating()
        webView.isHidden = true
        errorPanel.isHidden = false
    }
}
