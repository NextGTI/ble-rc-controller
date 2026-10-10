import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    // Roomy default so the two-column layout shows; never smaller than a phone-ish width.
    self.setContentSize(NSSize(width: 1040, height: 720))
    self.contentMinSize = NSSize(width: 420, height: 560)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
