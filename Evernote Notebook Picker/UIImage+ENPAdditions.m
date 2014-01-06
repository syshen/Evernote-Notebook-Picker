//
//  UIImage+ENPAdditions.m
//  Notebook Picker Sample
//
//  Created by syshen on 1/6/14.
//  Copyright (c) 2014 syshen. All rights reserved.
//

#import "UIImage+ENPAdditions.h"

@implementation UIImage (ENPAdditions)
+ (BOOL) retina {
  if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]
      && [[UIScreen mainScreen] scale] == 2.0) {
    return YES;
  }
  return NO;

}

+ (UIImage*)imageNamed:(NSString *)name bundle:(NSBundle*)bundle {
  
  NSMutableString *imageName = [NSMutableString stringWithString:name];
  if ([[self class] retina]) {
    [imageName appendString:@"@2x"];
    NSString *imagePath = [bundle pathForResource:imageName ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if (image)
      return image;
  }
  
  NSString *imagePath = [bundle pathForResource:name ofType:@"png"];
  return [UIImage imageWithContentsOfFile:imagePath];
  
}

@end
