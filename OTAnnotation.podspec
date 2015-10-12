Pod::Spec.new do |s|
  s.name         = "OTAnnotation"
  s.version      = "1.0.0"
  s.summary      = "OpenTok annotation plugin for iOS."
  s.homepage     = "https://github.com/opentok/annotation-component-ios"
  s.author       = { "Trevor Boyer" => "trevor@tokbox.com" }
  s.platform     = :ios, '7.0'
  s.source       = { :git => "https://github.com/opentok/annotation-component-ios.git", :tag => s.version.to_s }
  s.source_files = 'OTAnnotations/**/*'
  s.requires_arc = true
end
