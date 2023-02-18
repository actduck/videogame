import UIKit
import Flutter
import flutter_downloader

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private let CHANNEL_METHOD = "com.actduck.videogame/playgame_method"
    private let CHANNEL_EVENT = "com.actduck.videogame/playgame_event"
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    FlutterMethodChannel(name: CHANNEL_METHOD, binaryMessenger: controller.binaryMessenger).setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        // Note: this method is invoked on the UI thread.
        // Handle battery messages.
        if (call.method == "playGame") {
            if let arguments = call.arguments as? Dictionary<String, Any>,
               let gameType = arguments["gameType"] as? Dictionary<String, Any>{
                
                openGame(gameType: gameType["name"], file: arguments["romLocalPath"])
            } else {
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
        
    })
    
    FlutterEventChannel(name: CHANNEL_EVENT, binaryMessenger: controller.binaryMessenger).setStreamHandler(SwiftStreamHandler())
    
    
    
    GeneratedPluginRegistrant.register(with: self)
    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private func registerPlugins(registry: FlutterPluginRegistry) {
    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
       FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
    }
}

var eventSink: FlutterEventSink? = nil

class SwiftStreamHandler: NSObject, FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}


private func openGame(
    gameType: Any?,
    file: Any?
  ) {
    
    //push新页面
//    self.navigationController?.pushViewController(myViewController, animated: true)

//    val intent = Intent(Intent.ACTION_VIEW)
//
//    when (gameType) {
//      "NES" -> {
//        intent.setDataAndType(Uri.parse(file.absolutePath), "application/nes")
//        intent.setClass(this, NESActivity::class.java)
//      }
//      "GBA" -> {
//        intent.setDataAndType(Uri.parse(file.absolutePath), "application/gba")
//        intent.setClass(this, GBAActivity::class.java)
//      }
//      "SNES" -> {
//        intent.setDataAndType(Uri.parse(file.absolutePath), "application/snes")
//        intent.setClass(this, SNESActivity::class.java)
//      }
//      "MD" -> {
//        intent.setDataAndType(Uri.parse(file.absolutePath), "application/md")
//        intent.setClass(this, MDActivity::class.java)
//      }
//      "NEO" -> {
//        intent.setDataAndType(Uri.parse(file.absolutePath), "application/neo")
//        intent.setClass(this, NEOActivity::class.java)
//      }
//    }
//
//    if (!file.exists()) {
//      Toast.makeText(this, "game not exists", Toast.LENGTH_LONG)
//          .show()
//      return
//    }
//
//    startActivityForResult(intent, RQ_PLAY)
  }
