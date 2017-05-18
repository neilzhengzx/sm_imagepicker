
Pod::Spec.new do |s|
  s.name         = "RNSmImagepicker"
  s.version      = "1.0.0"
  s.summary      = "RNSmImagepicker"
  s.description  = <<-DESC
                  RNSmImagepicker
                   DESC
  s.homepage     = ""
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/author/RNSmImagepicker.git", :tag => "master" }
  s.source_files  = "RNSmImagepicker/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end

  