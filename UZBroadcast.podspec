Pod::Spec.new do |s|
    s.name = 'UZBroadcast'
    s.version = '2.2.2'
    s.summary = 'UZBroadcast'
    s.homepage = 'https://uiza.io/'
    s.documentation_url = 'https://uizaio.github.io/uiza-ios-broadcast-sdk/'
    s.author = { 'Uiza' => 'namnh@uiza.io' }
    s.license = { :type => "BSD", :file => "LICENSE" }
    s.source = { :git => "https://github.com/uizaio/snake.sdk.ios-broadcast.git", :tag => "v" + s.version.to_s }
    s.source_files = 'UZBroadcast/*.*', 'UZBroadcast/*.{h,m}'
    s.public_header_files = 'UZBroadcast/*.h'
    s.ios.deployment_target = '10.0'
    s.requires_arc  = true
    s.swift_version = '5.3'
    
    s.ios.dependency "HaishinKit", "~> 1.1.6"
    s.ios.dependency "GPUImage"
    s.static_framework = true
end
