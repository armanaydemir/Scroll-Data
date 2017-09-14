//
//  ViewController.m
//  Scroll Data
//
//  Created by Arman Aydemir on 4/18/17.
//  Copyright © 2017 Arman Aydemir. All rights reserved.
//

#import "ViewController.h"
#import "TextCell.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.text = [[NSMutableArray alloc] init];
    self.startTime = [[NSDate alloc] init];

    NSString* path = [[NSBundle mainBundle] pathForResource:@"yeezus"
                                                     ofType:@"txt"];
    NSString* content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    NSInteger i = 1;
    NSInteger l = [content length] - 1;
    
    while(i != NSNotFound){
        NSRange k = NSMakeRange(i, l);
        
        while(NSMaxRange(k) >= [content length]){
            l --;
            k = NSMakeRange(i, l);
        }
        NSRange v = [content rangeOfString:@"<p>" options:(NSCaseInsensitiveSearch) range:k];
        
        NSRange w = [content rangeOfString:@"</p>" options:(NSCaseInsensitiveSearch) range:k];
        if(w.location == NSNotFound){
            i = NSNotFound;
        }else{
            i = w.location + w.length;
            
            k = NSMakeRange(v.location + v.length, i - (v.location + v.length));
            
            NSString *s = [content substringWithRange:k];
            
            NSInteger bot = 0;
            NSInteger len = [s length];
            
            while(bot != NSNotFound){
                k = NSMakeRange(bot, len);
                while(NSMaxRange(k) > [s length]){
                    len --;
                    k = NSMakeRange(bot, len);
                }

                v = [s rangeOfString:@"<" options:(NSCaseInsensitiveSearch) range:k];
                w = [s rangeOfString:@">" options:(NSCaseInsensitiveSearch) range:k];
                if(w.location == NSNotFound){
                    bot = NSNotFound;
                }else{
                    bot = v.location;
                    NSString* part1 = [s substringToIndex:v.location];
                    NSString* part2 = [s substringFromIndex:w.location+1];
                    s = [part1 stringByAppendingString:part2];
                }
            }
            s = [s stringByReplacingOccurrencesOfString:@"&apos;" withString:@"\'"];
            [self.text addObject:[s stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""]];
            l = [content length] - i;
        }
    }
    
    
    self.table.dataSource = self;
    [self.table registerNib:[UINib nibWithNibName:@"TextCell" bundle:nil] forCellReuseIdentifier:@"default"];
    [self.table setDelegate:self];
    [self.table setCellLayoutMarginsFollowReadableWidth:YES];
    
    self.table.estimatedRowHeight = 68.0;
    self.table.rowHeight = UITableViewAutomaticDimension;
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
    paragraphStyle.firstLineHeadIndent = 20;
    UIFont *font = [UIFont fontWithName:@"Palatino-Roman" size:11.5];
    NSDictionary *attributtes = @{NSParagraphStyleAttributeName : paragraphStyle,NSFontAttributeName: font};
    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:aString
                                                             attributes:attributtes];
    
    [cell.textLabel sizeToFit];
    [cell setSelected:NO];
    
    return cell;
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) { [self scrollingFinish]; }
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollingFinish];
}

- (void)scrollingFinish {
    NSLog(@"---------");
    CGFloat scrollVal = self.table.contentOffset.y;
    CGFloat bottomScroll = scrollVal + self.view.frame.size.height;
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
    //NSLog(@"first line is line %f of %ld", lineNum1,(long)i1);
    
    //----------------------------------
    frameTotal = 0.0;
    NSInteger i2 = 0;
    lastFrame = 0.0;
    while(bottomScroll > frameTotal){
        CGRect frame = [self.table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:i2 inSection:0]];
        frameTotal += frame.size.height;
        lastFrame = frame.size.height;
        i2++;
    }
    CGFloat lineNum2 = floor((bottomScroll - (frameTotal - lastFrame) - 25.0)/25.0) + 1;
    NSString *line2 = [NSString stringWithFormat: @"%.2f", lineNum2];
    //NSLog(@"last line is line %f of %ld", lineNum2,(long)i2);
    
    //--------------------------------
    NSArray *keys = @[@"top_line", @"top_section",@"bottom_line",@"bottom_section"];
    NSArray *entries = @[line1, [@(i1) stringValue], line2, [@(i2) stringValue]];
    NSMutableString *csv = [[NSMutableString alloc] initWithCapacity:0];
    for (int i = 0; i < entries.count; i++) {
        [csv appendFormat:@"%@;%@\n", keys[i], entries[i]];
    }
     NSLog(@"%@",csv);
}

@end
