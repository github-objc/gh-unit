//
//  GHUnitIOSTestViewController.m
//  GHUnitIOS
//
//  Created by Gabriel Handford on 2/20/09.
//  Copyright 2009. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "GHUnitIOSTestViewController.h"
#import "GHViewTestCase.h"

@implementation GHUnitIOSTestViewController

- (id)init {
  if ((self = [super init])) {
    UIBarButtonItem *runButton = [[UIBarButtonItem alloc] initWithTitle:@"Re-run" style:UIBarButtonItemStyleDone
                                                 target:self action:@selector(_runTest)];
    self.navigationItem.rightBarButtonItem = runButton;
    [runButton release];
  }
  return self;
}

- (void)dealloc {
  [testNode_ release];
  [super dealloc];
}

- (void)loadView {
  testView_ = [[GHUnitIOSTestView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
  testView_.controlDelegate = self;
  self.view = testView_;
  [testView_ release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

- (void)_runTest {
  id<GHTest> test = [testNode_.test copyWithZone:NULL];
  NSLog(@"Re-running: %@", test);
  [testView_ setText:@"Running..."];
  [test run:GHTestOptionForceSetUpTearDownClass];  
  [self setTest:test];
  [test release];
}

- (NSString *)updateTestView {
  NSMutableString *text = [NSMutableString stringWithCapacity:200];
  [text appendFormat:@"%@ %@\n", [testNode_ identifier], [testNode_ statusString]];
  NSString *log = [testNode_ log];
  if (log) [text appendFormat:@"\nLog:\n%@\n", log];
  NSString *stackTrace = [testNode_ stackTrace];
  if (stackTrace) [text appendFormat:@"\n%@\n", stackTrace];
  if ([testNode_.test.exception.name isEqualToString:@"GHViewChangeException"]) {
    NSDictionary *exceptionUserInfo = testNode_.test.exception.userInfo;
    UIImage *originalImage = [exceptionUserInfo objectForKey:@"OriginalImage"];
    UIImage *newImage = [exceptionUserInfo objectForKey:@"NewImage"];
    [testView_ setOriginalImage:originalImage newImage:newImage text:text];
  } else if ([testNode_.test.exception.name isEqualToString:@"GHViewUnavailableException"]) {
    NSDictionary *exceptionUserInfo = testNode_.test.exception.userInfo;
    //UIImage *originalImage = [exceptionUserInfo objectForKey:@"OriginalImage"];
    UIImage *newImage = [exceptionUserInfo objectForKey:@"NewImage"];
    [testView_ setOriginalImage:nil newImage:newImage text:text];
  } else {
    [testView_ setText:text];
  }
  return text;
}

- (void)setTest:(id<GHTest>)test {
  [self view];
  self.title = [test name];

  [testNode_ release];
  testNode_ = [[GHTestNode nodeWithTest:test children:nil source:nil] retain];
  NSString *text = [self updateTestView];
  NSLog(@"%@", text);
}

#pragma mark Delegates (GHUnitIOSTestView)

- (void)testViewDidSelectOriginalImage:(GHUnitIOSTestView *)testView {
  UIViewController *viewController = [[UIViewController alloc] init];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  UIImage *originalImage = [testNode_.test.exception.userInfo objectForKey:@"OriginalImage"];
  [scrollView addSubview:[[[UIImageView alloc] initWithImage:originalImage] autorelease]];
  scrollView.contentSize = originalImage.size;
  viewController.view = scrollView;
  [self.navigationController pushViewController:viewController animated:YES];
}

- (void)testViewDidSelectNewImage:(GHUnitIOSTestView *)testView {
  UIViewController *viewController = [[UIViewController alloc] init];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  UIImage *newImage = [testNode_.test.exception.userInfo objectForKey:@"NewImage"];
  [scrollView addSubview:[[[UIImageView alloc] initWithImage:newImage] autorelease]];
  scrollView.contentSize = newImage.size;
  viewController.view = scrollView;
  [self.navigationController pushViewController:viewController animated:YES];
}

- (void)testViewDidApproveChange:(GHUnitIOSTestView *)testView {
  // TODO(johnb): Change some UI to reflect that the change has been accepted
  // Save new image as the approved version
  NSString *imageFilename = [testNode_.test.exception.userInfo objectForKey:@"ImageFilename"];
  UIImage *newImage = [testNode_.test.exception.userInfo objectForKey:@"NewImage"];
  [GHViewTestCase saveToDocumentsWithImage:newImage filename:imageFilename];
  [self _runTest];
}

@end
