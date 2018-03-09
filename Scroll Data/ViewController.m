//
//  ViewController.m
//  Scroll Data
//
//  Created by Arman Aydemir on 4/18/17.
//  Copyright © 2017 Arman Aydemir. All rights reserved.
//

#import "ViewController.h"
#import "TextCell.h"
#import "Scroll_Data-Swift.h"
#import <sys/utsname.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.throttle = YES;
    self.table.hidden = YES;
    [self.table setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.text = [[NSMutableArray alloc] init];
    self.spinner.hidesWhenStopped = YES;
    [self.spinner startAnimating];
    [Networking requestWithHeaders:@{} method:@"GET" fullEndpoint:@"http://159.203.207.54:22364" body:@{@"articleLink":self.articleLink} completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error == nil){
            NSError *err;
            self.text = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
            NSLog(@"%@", err);
        }else{
            self.text[0] = @"problem connecting to server";
        }
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.spinner stopAnimating];
            if(self.text != nil){
                self.throttle = NO;
                self.table.hidden = NO;
                [self.table reloadData];
            }else{
                //put code in here to show error label and retry button
            }
            
        });
    }];
   
    self.startTime = [[NSDate alloc] init];
    
    self.table.dataSource = self;
    [self.table registerNib:[UINib nibWithNibName:@"TextCell" bundle:nil] forCellReuseIdentifier:@"default"];
    [self.table setDelegate:self];
    [self.table setCellLayoutMarginsFollowReadableWidth:NO];
    
    self.table.estimatedRowHeight = 68.0;
    self.table.rowHeight = UITableViewAutomaticDimension;
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.2
                                             target:self
                                           selector:@selector(timerFireMethod:)
                                           userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.text count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TextCell *cell = [self.table dequeueReusableCellWithIdentifier:@"default" forIndexPath:indexPath];
    NSString *aString = [self.text objectAtIndex:indexPath.item];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 25;
    paragraphStyle.maximumLineHeight = 25;
    UIFont *font = [UIFont fontWithName:@"Palatino-Roman" size:11.5];
    NSDictionary *attributtes = @{NSParagraphStyleAttributeName : paragraphStyle,NSFontAttributeName: font};
    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:aString
                                                             attributes:attributtes];
    
    [cell.textLabel sizeToFit];
    [cell setSelected:NO];
    
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat scrollVal = self.table.contentOffset.y;
    CGFloat bottomScroll = scrollVal + self.table.frame.size.height;
    CGFloat frameTotal = 0.0;
    NSInteger i1 = 0;
    CGFloat lastFrame = 0.0;
    while(scrollVal > frameTotal){
        CGRect frame = [self.table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:i1 inSection:0]];
        frameTotal += frame.size.height;
        lastFrame = frame.size.height;
        i1++;
    }
    CGFloat lineNum1 = floor((scrollVal - (frameTotal - lastFrame) - 25.0)/25.0) + 1;
    NSString *line1 = [NSString stringWithFormat: @"%.2f", lineNum1];
    
    
    //----------------------------------
    frameTotal = 0.0;
    NSInteger i2 = 0;
    lastFrame = 0.0;
    while(bottomScroll > frameTotal){
        if(i2 >= self.text.count){
            i2 = MIN(self.text.count, i2);
            bottomScroll = frameTotal;
        }
        CGRect frame = [self.table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:i2 inSection:0]];
        frameTotal += frame.size.height;
        lastFrame = frame.size.height;
        i2++;
    }
    CGFloat lineNum2 = floor((bottomScroll - (frameTotal - lastFrame) - 25.0)/25.0) + 1;
    NSString *line2 = [NSString stringWithFormat: @"%.2f", lineNum2];
    
    
    //--------------------------------
    NSString *uniqueIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *temp = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding]; //device type identifier
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy HH:mm:ss.SSS"];
    
    NSDate *currentDate = [NSDate date];
    NSString *dateString = [formatter stringFromDate:currentDate];
    NSString *startTimeString = [formatter stringFromDate:self.startTime];
    if(self.throttle == NO && ![self.recent isEqual:@{@"top_line":line1, @"top_section": [@(i1) stringValue],@"bottom_line":line2,@"bottom_section":[@(i2) stringValue]}]){
        self.throttle = YES;
        NSLog(@"---------");
        NSLog(@"first line is line %f of %ld", lineNum1,(long)i1);
        NSLog(@"last line is line %f of %ld", lineNum2,(long)i2);
        self.recent = @{@"top_line":line1, @"top_section": [@(i1) stringValue],@"bottom_line":line2,@"bottom_section":[@(i2) stringValue]};
        
        NSDictionary *keys = @{@"device_type":temp, @"article":self.articleLink, @"device_id":uniqueIdentifier,@"startTime":startTimeString, @"time":dateString, @"top_line":line1, @"top_section": [@(i1) stringValue],@"bottom_line":line2,@"bottom_section":[@(i2) stringValue]};
        
        [Networking requestWithHeaders:@{} method:@"POST" fullEndpoint:@"http://159.203.207.54:22364/submit_data" body:keys completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if(error){ NSLog(@"%@",error); }
        }];
    }
}

//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//    if (!decelerate) { [self scrollingFinish]; }
//}
//
//
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    [self scrollingFinish]; this is now timerFireMethod, but is exactly the same
//}


- (void)timerFireMethod:(NSTimer *)timer {
    self.throttle = NO;
}


@end
