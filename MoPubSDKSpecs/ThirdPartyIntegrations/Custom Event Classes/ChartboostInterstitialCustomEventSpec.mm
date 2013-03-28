#import "ChartboostInterstitialCustomEvent.h"
#import "FakeChartboost.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface MPInstanceProvider (ChartboostInterstitials_Spec)

- (Chartboost *)buildChartboost;

@end

SPEC_BEGIN(ChartboostInterstitialCustomEventSpec)

describe(@"ChartboostInterstitialCustomEvent", ^{
    __block ChartboostInterstitialCustomEvent *customEvent;
    __block id<MPInterstitialCustomEventDelegate, CedarDouble>delegate;
    __block FakeChartboost *chartboost;

    describe(@"Chartboost instance provider", ^{
        it(@"should return the shared chartboost", ^{
            MPInstanceProvider *provider = [[[MPInstanceProvider alloc] init] autorelease];
            [provider buildChartboost] should be_same_instance_as([Chartboost sharedChartboost]);
        });
    });

    describe(@"requesting with custom event info", ^{
        context(@"when the app ID or app signature is invalid", ^{
            beforeEach(^{
                chartboost = [[[FakeChartboost alloc] init] autorelease];
                fakeProvider.fakeChartboost = chartboost;

                customEvent = [[ChartboostInterstitialCustomEvent alloc] init];
                delegate = nice_fake_for(@protocol(MPInterstitialCustomEventDelegate));
                customEvent.delegate = delegate;
                [customEvent requestInterstitialWithCustomEventInfo:nil];
            });

            it(@"should immediately tell the delegate that it failed to load an ad", ^{
                delegate should have_received(@selector(interstitialCustomEvent:didFailToLoadAdWithError:)).with(customEvent).and_with(nil);
            });

            it(@"should not set itself as the chartboost's delegate, or tell it to do anything", ^{
                chartboost.delegate should_not equal(customEvent);
                chartboost.didStartSession should equal(NO);
                chartboost.requestedLocations should be_empty;
            });
        });
    });
});

SPEC_END
