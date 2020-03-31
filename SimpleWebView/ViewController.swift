import UIKit
import WebKit

class ViewController: UIViewController {

    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        clean()
        setupWebView()
    }

    func setupWebView() {
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        if let cookieData = UserDefaults.standard.value(forKey: "cookies") as? [[HTTPCookiePropertyKey: Any]] {
            let cookies: [HTTPCookie] = cookieData.map { HTTPCookie(properties: $0)! }
            WKWebViewConfiguration.includeCookie(cookies: cookies, preferences: preferences) { [unowned self] config in
                if let configuration = config {
                    self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width , height: self.view.frame.height), configuration: configuration)
                    self.webView.navigationDelegate = self

                    self.view.addSubview(self.webView)
                    self.loadRequest()
                }
            }
        } else {
            let config = WKWebViewConfiguration()
            config.preferences = preferences
            webView = WKWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width , height: self.view.frame.height), configuration: config)
            self.view.addSubview(self.webView)
            self.webView.navigationDelegate = self
            self.loadRequest()
        }
    }

    func loadRequest() {
        var request = URLRequest(url: URL(string: "http://40.113.127.234:4503/content/saxendacare2/master/en_ca/mobile.html")!)
        request.setValue("true", forHTTPHeaderField: "saxenda-app")
        self.webView.load(request)
    }

    func clean() {
        
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        print("[WebCacheCleaner] All cookies deleted")
        
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                print("[WebCacheCleaner] Record \(record) deleted")
            }
        }
    }

}

extension ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        // get the cookie store (WKHTTPCookieStore) from the webview
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { (cookies) in
            
            print("COOKIES RECEIVED: Count = '\(cookies.count)'")
            var storedCookies: [[HTTPCookiePropertyKey: Any]] = []
            for cookie in cookies {
                print("COOKIE RECEIVED:     '\(cookie.name): \(cookie.value)'")
                
                //if login - store in defaults
//                if(cookie.name == "login-token"){

                    var cData = [HTTPCookiePropertyKey: Any]()
                    cData[HTTPCookiePropertyKey.name] = cookie.name
                    cData[HTTPCookiePropertyKey.value] = cookie.value
                    cData[HTTPCookiePropertyKey.expires] = Date(timeInterval: 3600, since: Date())
                    cData[HTTPCookiePropertyKey.path] = cookie.path
                    cData[HTTPCookiePropertyKey.comment] = cookie.comment
                    cData[HTTPCookiePropertyKey.domain] = cookie.domain
                    cData[HTTPCookiePropertyKey.secure] = cookie.isSecure

//                    print("saving login token to user defaults")
//                    UserDefaults.standard.set(cData, forKey: "login-token")
//                }
                storedCookies.append(cData)
            }
            UserDefaults.standard.set(storedCookies, forKey: "cookies")
            
            print("  ")
        }
    }
}

extension WKWebViewConfiguration {

    static func includeCookie(cookies: [HTTPCookie], preferences: WKPreferences, completion: @escaping (WKWebViewConfiguration?) -> Void) {
         let config = WKWebViewConfiguration()
         config.preferences = preferences

         let dataStore = WKWebsiteDataStore.nonPersistent()

//         DispatchQueue.main.async {
        let waitGroup = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 1)

        for cookie in cookies {
            waitGroup.enter()
//            semaphore.wait()
            dataStore.httpCookieStore.setCookie(cookie) {
                waitGroup.leave()
//                semaphore.signal()
            }
        }

        waitGroup.notify(queue: DispatchQueue.main) {
            config.websiteDataStore = dataStore
            completion(config)
        }
//        }
    }
}
