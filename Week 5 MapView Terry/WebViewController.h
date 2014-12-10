//
//  WebViewController.h
//  Week 5 MapView Terry
//
//  Created by Aditya Narayan on 9/25/14.
//  Copyright (c) 2014 NM. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController

@property (strong, nonatomic) NSString* url;

@property (strong, nonatomic) IBOutlet UIWebView *myWebView;

@end
