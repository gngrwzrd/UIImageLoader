Pod::Spec.new do |spec|
  spec.name         = 'UIImageLoader'
  spec.version      = '1.0.0'
  spec.license      = { :type => 'MIT',  :file => 'LICENSE' }
  spec.homepage     = 'https://github.com/gngrwzrd/UIImageLoader'
  spec.authors      = { 'Aaron Smith' => 'gngrwzrd@gmail.com' }
  spec.summary      = 'UIImage & NSImage Cache with Callbacks'
  spec.source       = { :git => 'https://github.com/gngrwzrd/UIImageLoader.git', :tag => '1.0.0' }
  spec.source_files = 'UIImageLoader.{h,m}'
end