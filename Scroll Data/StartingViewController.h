//
//  StartingViewController.h
//  Scroll Data
//
//  Created by Arman Aydemir on 1/3/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StartingViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *startButton;

@property (weak, nonatomic) IBOutlet UITextField *articleLink;

@property (weak, nonatomic) IBOutlet UITableView *articles;
@end
