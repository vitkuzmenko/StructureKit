Pod::Spec.new do |s |    
    s.name = "StructureKit"
    s.version = "1.0.5"
    s.summary = "StructureKit is an simplest way to control very very hard tables or collections."
    s.homepage = "https://github.com/vitkuzmenko/StructureKit.git"
    
    s.license = {
      :type => "Apache 2.0",
      :file => "LICENSE"
    }
    s.author = {
      "Vitaliy" => "kuzmenko.v.u@gmail.com"
    }
    s.social_media_url = "http://twitter.com/vitkuzmenko"
    
    s.ios.deployment_target = '9.0'
    s.tvos.deployment_target = '11.0'
    
    s.source = {
      :git => s.homepage,
      :tag => s.version.to_s
    }
    s.source_files = "Sources/**/*.swift"
    
    s.swift_version = '5.0'
end