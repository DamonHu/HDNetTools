Pod::Spec.new do |s|
s.name = 'HDNetTools'
s.version = '2.4.0'
s.license= { :type => "MIT", :file => "LICENSE" }
s.summary = 'HD网络请求库，基于AFNetworking封装，提供了请求悬浮窗显示于隐藏、延迟显示悬浮窗、请求时屏幕点击响应、网络超时设置和重试次数设置。'
s.homepage = 'https://github.com/DamonHu/HDNetTools'
s.authors = { 'DamonHu' => 'dong765@qq.com' }
s.source = { :git => "https://github.com/DamonHu/HDNetTools.git", :tag => s.version}
s.requires_arc = true
s.ios.deployment_target = '9.0'
s.source_files = "HDNetTools/HDNetTools/*.{h,m}"
s.frameworks = 'Foundation'
s.dependency 'AFNetworking', '~>3.1.0'
s.dependency 'SVProgressHUD'
s.documentation_url = 'http://www.hudongdong.com/ios/758.html'
end