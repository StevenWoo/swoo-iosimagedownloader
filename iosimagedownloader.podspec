
Pod::Spec.new do |s|



  s.name         = "iosimagedownloader"
  s.version      = "0.0.8"
  s.summary      = "Download images for display in app, cache most recent 100 in app local storage"

  s.description  = <<-DESC
								   Download files in background using NSOperationQueue.  Store list of recent files in CoreData. 
                   Protocol for notification when files are downloaded.  Cached images used if possible.
                   DESC

  s.homepage     = "https://github.com/StevenWoo/swoo-iosimagedownloader"


  s.license      = 'MIT'




  s.author             = { "Steven Woo" => "swoo@tackable.com" }

  s.social_media_url = "http://twitter.com/StevenWoo"


  s.platform     = :ios, '5.0'




  s.source       = { :git => "https://github.com/StevenWoo/swoo-iosimagedownloader.git", :tag => "0.0.8" }




  s.source_files  = 'ImageCacheManager/**/*.{h,m}'
  s.exclude_files = 'Classes/Exclude'





  s.resource = "ImageCacheManager/xcdatamodeld/*"
  s.resource = "ImageCacheManager/ImageCache.momd/*"
  


  s.requires_arc = true


end
