//
//  StartingViewController.m
//  Scroll Data
//
//  Created by Arman Aydemir on 1/3/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

#import "StartingViewController.h"

@interface StartingViewController ()

@end

@implementation StartingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startReading:(id)sender {
    [self performSegueWithIdentifier:@"startReading" sender:sender];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
