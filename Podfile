source 'https://github.com/CocoaPods/Specs.git'

# Prefer static frameworks for faster builds
use_frameworks! :linkage => :static

inhibit_all_warnings!

target 'iOSExample' do
  platform :ios, '12.0'

  # Use the local StructureKit podspec in this repo
  pod 'StructureKit', :path => './'
end

target 'AppleTv' do
  platform :tvos, '12.0'

  pod 'StructureKit', :path => './'
end

target 'macOS' do
  platform :osx, '11.0'

  pod 'StructureKit', :path => './'
end


