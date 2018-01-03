//
//  ViewController.h
//  Scroll Data
//
//  Created by Arman Aydemir on 4/18/17.
//  Copyright © 2017 Arman Aydemir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *table;

@property (strong, nonatomic) NSDate* startTime;

@property (strong, nonatomic) NSDictionary* recent;

@property (strong, nonatomic) NSMutableArray<NSString*>* text;

@end

