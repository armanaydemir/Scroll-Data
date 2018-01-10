//
//  StartingViewController.m
//  Scroll Data
//
//  Created by Arman Aydemir on 1/3/18.
//  Copyright © 2018 Arman Aydemir. All rights reserved.
//

#import "StartingViewController.h"
#import "ViewController.h"

@interface StartingViewController ()

@end

@implementation StartingViewController

// nytimes articles for testing -----
// https://www.nytimes.com/2017/02/01/magazine/the-misunderstood-genius-of-russell-westbrook.html
// https://www.nytimes.com/2017/11/22/us/politics/alliance-defending-freedom-gay-rights.html
// https://www.nytimes.com/2017/11/21/technology/bitcoin-bitfinex-tether.html

- (void)viewDidLoad {
    [super viewDidLoad];
    self.articleLink.text = @"https://www.nytimes.com/2017/11/21/technology/bitcoin-bitfinex-tether.html";
    [self.startButton setTitle:@"Tap to Start Reading" forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startReading:(id)sender {
    [self performSegueWithIdentifier:@"startReading" sender:sender];
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController* vc = [segue destinationViewController];
    if([vc isKindOfClass:[ViewController class]]){
        ViewController* destination = (ViewController*)vc;
        destination.articleLink = self.articleLink.text;
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
