Pod::Spec.new do |spec|
  spec.name                   = 'UIImageLoader'
  spec.version                = '1.1.1'
  spec.license                = { :type => 'MIT',  :file => 'LICENSE' }
  spec.homepage               = 'https://github.com/gngrwzrd/UIImageLoader'
  spec.authors                = { 'Aaron Smith' => 'gngrwzrd@gmail.com' }
  spec.summary                = 'UIImage & NSImage Cache with Callbacks'
  spec.source                 = { :git => 'https://github.com/gngrwzrd/UIImageLoader.git', :tag => '1.1.1' }
  spec.source_files           = 'UIImageLoader.{h,m}'
  spec.ios.deployment_target  = '8.0'
  spec.osx.deployment_target  = '10.8'
  spec.tvos.deployment_target = '10.0'
end