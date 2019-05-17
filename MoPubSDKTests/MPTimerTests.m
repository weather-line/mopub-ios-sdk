//
//  MPTimerTests.m
//
//  Copyright 2018-2019 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import <XCTest/XCTest.h>
#import "MPTimer+Testing.h"
#import "MPTimer.h"

static const NSTimeInterval kTimerRepeatIntervalInSeconds = 0.05;

// `NSTimer` is not totally accurate and it might be slower on build machines, thus we need some
// extra tolerance while waiting for the expections to be fulfilled.
static const NSTimeInterval kWaitTimeTolerance = 2;

/**
 * This test make use of `MPTimer.associatedTitle` to identifier the timers in each test.
 */
@interface MPTimerTests : XCTestCase

/**
 * Key: (NSString *) name of the test
 * Value: (NSNumber *) the number of times the timer is fired in the corresponding test
 */
@property NSMutableDictionary * testNameVsFiringCount;

/**
 * Key: (NSString *) name of the test
 * Value: (XCTestExpectation *) the expectation to be fulfill after the timer is fired in the corresponding test
 */
@property NSMutableDictionary * testNameVsExpectation;

@end

@implementation MPTimerTests

// Create the dictionaries as needed
- (void)setUp {
    if (self.testNameVsFiringCount == nil) {
        self.testNameVsFiringCount = [NSMutableDictionary dictionary];
    }
    if (self.testNameVsExpectation == nil) {
        self.testNameVsExpectation = [NSMutableDictionary dictionary];
    }
}

// A helper for reducing code duplication.
- (MPTimer *)generateTestTimerWithTitle:(NSString *)title {
    MPTimer * timer = [MPTimer timerWithTimeInterval:kTimerRepeatIntervalInSeconds
                                              target:self
                                            selector:@selector(timerHandler:)
                                             repeats:YES];
    timer.associatedTitle = title;
    return timer;
}

// This is the method called by all the test timers.
- (void)timerHandler:(MPTimer *)timer {
    // increment the firing count
    NSNumber * timerCount = self.testNameVsFiringCount[timer.associatedTitle];
    self.testNameVsFiringCount[timer.associatedTitle] = [NSNumber numberWithInt:timerCount.intValue + 1];

    // fulfill corresponding expection, if any
    [((XCTestExpectation *)self.testNameVsExpectation[timer.associatedTitle]) fulfill];
    self.testNameVsExpectation[timer.associatedTitle] = nil;
}

// Test invalidating the timer before firing.
- (void)testInvalidateAfterInstantiation {
    NSString * testName = NSStringFromSelector(_cmd);
    MPTimer * timer = [self generateTestTimerWithTitle:testName];

    XCTAssertFalse(timer.isCountdownActive);
    XCTAssertFalse(timer.isScheduled);
    XCTAssertTrue(timer.isValid);
    [timer invalidate];
    XCTAssertFalse(timer.isCountdownActive);
    XCTAssertFalse(timer.isScheduled);
    XCTAssertFalse(timer.isValid);
}

// Test invalidating the timer after firing.
- (void)testInvalidateAfterStart {
    NSString * testName = NSStringFromSelector(_cmd);
    MPTimer * timer = [self generateTestTimerWithTitle:testName];
    XCTestExpectation * expectation = [self expectationWithDescription:@"Wait for timer to fire"];
    self.testNameVsExpectation[testName] = expectation;

    XCTAssertFalse(timer.isCountdownActive);
    XCTAssertFalse(timer.isScheduled);
    XCTAssertTrue(timer.isValid);
    [timer scheduleNow];
    XCTAssertTrue(timer.isCountdownActive);
    XCTAssertTrue(timer.isScheduled);
    XCTAssertTrue(timer.isValid);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimerRepeatIntervalInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue(timer.isCountdownActive);
        XCTAssertTrue(timer.isScheduled);
        XCTAssertTrue(timer.isValid);
        [timer invalidate];
        XCTAssertFalse(timer.isCountdownActive);
        XCTAssertFalse(timer.isScheduled);
        XCTAssertFalse(timer.isValid);
    });
    [self waitForExpectationsWithTimeout:kTimerRepeatIntervalInSeconds * kWaitTimeTolerance handler:^(NSError * _Nullable error) {
        XCTAssertEqual([(NSNumber *)self.testNameVsFiringCount[timer.associatedTitle] intValue], 1);
        XCTAssertNil(error);
    }];
}

// Test invalidating the timer after firing and then pause.
- (void)testInvalidateAfterStartedAndPause {
    NSString * testName = NSStringFromSelector(_cmd);
    MPTimer * timer = [self generateTestTimerWithTitle:testName];
    XCTestExpectation * expectation = [self expectationWithDescription:@"Wait for timer to fire"];
    self.testNameVsExpectation[testName] = expectation;

    XCTAssertFalse(timer.isCountdownActive);
    XCTAssertFalse(timer.isScheduled);
    XCTAssertTrue(timer.isValid);
    [timer scheduleNow];
    XCTAssertTrue(timer.isCountdownActive);
    XCTAssertTrue(timer.isScheduled);
    XCTAssertTrue(timer.isValid);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimerRepeatIntervalInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue(timer.isCountdownActive);
        XCTAssertTrue(timer.isScheduled);
        XCTAssertTrue(timer.isValid);
        [timer pause];
        XCTAssertFalse(timer.isCountdownActive);
        XCTAssertTrue(timer.isScheduled);
        XCTAssertTrue(timer.isValid);
        [timer invalidate];
        XCTAssertFalse(timer.isCountdownActive);
        XCTAssertFalse(timer.isScheduled);
        XCTAssertFalse(timer.isValid);
    });
    [self waitForExpectationsWithTimeout:kTimerRepeatIntervalInSeconds * kWaitTimeTolerance handler:^(NSError * _Nullable error) {
        XCTAssertEqual([(NSNumber *)self.testNameVsFiringCount[timer.associatedTitle] intValue], 1);
        XCTAssertNil(error);
    }];
}

// Test pausing and resuming the timer at different timings (before & after firing & invalidating).
- (void)testPauseAndResume {
    NSString * testName = NSStringFromSelector(_cmd);
    MPTimer * timer = [self generateTestTimerWithTitle:testName];
    XCTestExpectation * expectation = [self expectationWithDescription:@"Wait for timer to fire"];
    self.testNameVsExpectation[testName] = expectation;

    XCTAssertFalse(timer.isCountdownActive);
    XCTAssertFalse(timer.isScheduled);
    XCTAssertTrue(timer.isValid);
    [timer pause];
    XCTAssertFalse(timer.isCountdownActive);
    XCTAssertFalse(timer.isScheduled);
    XCTAssertTrue(timer.isValid);
    [timer scheduleNow];
    XCTAssertTrue(timer.isCountdownActive);
    XCTAssertTrue(timer.isScheduled);
    XCTAssertTrue(timer.isValid);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimerRepeatIntervalInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue(timer.isCountdownActive);
        XCTAssertTrue(timer.isScheduled);
        XCTAssertTrue(timer.isValid);
        [timer pause];
        XCTAssertFalse(timer.isCountdownActive);
        XCTAssertTrue(timer.isScheduled);
        XCTAssertTrue(timer.isValid);
        [timer resume];
        XCTAssertTrue(timer.isCountdownActive);
        XCTAssertTrue(timer.isScheduled);
        XCTAssertTrue(timer.isValid);
        [timer invalidate];
        XCTAssertFalse(timer.isCountdownActive);
        XCTAssertFalse(timer.isScheduled);
        XCTAssertFalse(timer.isValid);
        [timer pause];
        XCTAssertFalse(timer.isCountdownActive);
        XCTAssertFalse(timer.isScheduled);
        XCTAssertFalse(timer.isValid);
        [timer resume];
        XCTAssertFalse(timer.isCountdownActive);
        XCTAssertFalse(timer.isScheduled);
        XCTAssertFalse(timer.isValid);
    });
    [self waitForExpectationsWithTimeout:kTimerRepeatIntervalInSeconds * kWaitTimeTolerance handler:^(NSError * _Nullable error) {
        XCTAssertEqual([(NSNumber *)self.testNameVsFiringCount[timer.associatedTitle] intValue], 1);
        XCTAssertNil(error);
    }];
}

// Test whether the timer repeats firing as expected.
- (void)testRepeatingTimer {
    NSString * testName = NSStringFromSelector(_cmd);
    MPTimer * timer = [self generateTestTimerWithTitle:testName];
    XCTestExpectation * expectation = [self expectationWithDescription:@"Wait for timer to fire"];
    int firingCount = 10;

    XCTAssertFalse(timer.isCountdownActive);
    XCTAssertFalse(timer.isScheduled);
    XCTAssertTrue(timer.isValid);
    [timer scheduleNow];
    XCTAssertTrue(timer.isCountdownActive);
    XCTAssertTrue(timer.isScheduled);
    XCTAssertTrue(timer.isValid);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimerRepeatIntervalInSeconds * firingCount * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:kTimerRepeatIntervalInSeconds * firingCount * kWaitTimeTolerance handler:^(NSError * _Nullable error) {
        XCTAssertEqual([(NSNumber *)self.testNameVsFiringCount[timer.associatedTitle] intValue], firingCount);
        XCTAssertNil(error);
    }];

    XCTAssertTrue(timer.isCountdownActive);
    XCTAssertTrue(timer.isScheduled);
    XCTAssertTrue(timer.isValid);
    [timer invalidate];
    XCTAssertFalse(timer.isCountdownActive);
    XCTAssertFalse(timer.isScheduled);
    XCTAssertFalse(timer.isValid);
}

// Test whether redundant `scheduleNow` calls are safe.
- (void)testRedundantSchedules {
    NSString * testName = NSStringFromSelector(_cmd);
    MPTimer * timer = [self generateTestTimerWithTitle:testName];
    XCTestExpectation * expectation = [self expectationWithDescription:@"Wait for timer to fire"];
    self.testNameVsExpectation[testName] = expectation;

    XCTAssertFalse(timer.isCountdownActive);
    XCTAssertFalse(timer.isScheduled);
    XCTAssertTrue(timer.isValid);
    [timer scheduleNow];
    XCTAssertTrue(timer.isCountdownActive);
    XCTAssertTrue(timer.isScheduled);
    XCTAssertTrue(timer.isValid);
    [timer scheduleNow];
    XCTAssertTrue(timer.isCountdownActive);
    XCTAssertTrue(timer.isScheduled);
    XCTAssertTrue(timer.isValid);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimerRepeatIntervalInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue(timer.isCountdownActive);
        XCTAssertTrue(timer.isScheduled);
        XCTAssertTrue(timer.isValid);
        [timer invalidate];
        XCTAssertFalse(timer.isCountdownActive);
        XCTAssertFalse(timer.isScheduled);
        XCTAssertFalse(timer.isValid);
        [timer scheduleNow];
        XCTAssertFalse(timer.isCountdownActive);
        XCTAssertFalse(timer.isScheduled);
        XCTAssertFalse(timer.isValid);
    });
    [self waitForExpectationsWithTimeout:kTimerRepeatIntervalInSeconds * kWaitTimeTolerance handler:^(NSError * _Nullable error) {
        XCTAssertEqual([(NSNumber *)self.testNameVsFiringCount[timer.associatedTitle] intValue], 1);
        XCTAssertNil(error);
    }];
}

@end
