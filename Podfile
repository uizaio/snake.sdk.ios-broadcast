# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'UZBroadcast' do
  platform :ios, '10.0'
  use_frameworks!

  pod 'HaishinKit'

end

target 'UZBroadcastExample' do
	platform :ios, '10.0'
	use_frameworks!
	
#	pod 'UZBroadcast', :path => './'
	pod 'SwiftIcons'
	pod 'HaishinKit'
end

target 'UZBroadcastExtension' do
	platform :ios, '10.0'
	use_frameworks!
	pod 'HaishinKit'
#	pod 'UZBroadcast', :path => './'
	
end

target 'UZBroadcastExtensionSetupUI' do
	platform :ios, '10.0'
	use_frameworks!
	pod 'HaishinKit'
#	pod 'UZBroadcast', :path => './'
	
end

post_install do |installer|
	
	installer.pods_project.targets.each do |target|
		if target.name == 'SwiftIcons'
			target.build_configurations.each do |config|
				config.build_settings['SWIFT_VERSION'] = '4.0'
			end
		end
	end
	
end
