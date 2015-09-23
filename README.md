OpenTok iOS Annotations Plugin
===========================

This plugin adds annotation and screen capture capabilities to OpenTok for iOS.

Notes
-----

* See [OpenTok iOS SDK developer and client requirements](https://tokbox.com/developer/sdks/ios/#system-requirements) for a list of system requirements and supported devices.

* See the [OpenTok iOS SDK Reference](https://tokbox.com/developer/sdks/ios/reference/index.html)
for details on the API.

Installing
----------

### CocoaPods

1. Add `pod 'OpenTokAnnotations'` to your podfile.
2. Run `pod install` from your Terminal or using an Xcode plugin.

### Manually add the framework

1. Download the OpenTok Annotation [framework files]() and unzip it.
2. Click your project name in the Project Navigator sidebar.
3. Choose the Build Phases tab.
4. Expand the Link Binary With Libraries section.
5. Click the '+' sign to add a framework.
6. Select 'Add Other...' from the popup and navigate to folder you unzipped in step 1.

Using the plugin
----------------

For a quick start, download the [OpenTok iOS samples](https://github.com/opentok/opentok-ios-sdk-samples). If you already have your own project to work with,
the steps below should help you incorporate the annotations plugin.

(Coming soon)

Customizing the toolbar
----------------

(Coming soon)

#### Adding/removing menu items

#### Add menu items using Interface Builder

#### Defaults

#### Handling custom items

#### Custom colors

For best results
----------------

In order to ensure that all annotations are visible across devices, it is recommended to use predefined
aspect ratios for your video frames.

[code sample]