#import "SpectacleScreenDetection.h"
#import "SpectacleUtilities.h"

@implementation SpectacleScreenDetection

+ (NSScreen *)screenWithAction: (SpectacleWindowAction)action andRect: (CGRect)rect screens: (NSArray *)screens mainScreen: (NSScreen *)mainScreen {
    NSArray *screensInConsistentOrder = [SpectacleScreenDetection screensInConsistentOrder: screens];
    NSScreen *result = [self screenContainingRect: rect screens: screensInConsistentOrder mainScreen: mainScreen];
    
    if (MovingToNextOrPreviousDisplay(action)) {
        result = [self nextOrPreviousScreenToFrameOfScreen: NSRectToCGRect([result frame]) inDirectionOfAction: action screens: screensInConsistentOrder];
    }
    
    return result;
}

#pragma mark -

+ (NSScreen *)screenContainingRect: (CGRect)rect screens: (NSArray *)screens mainScreen: (NSScreen *)mainScreen {
    CGFloat largestPercentageOfRectWithinFrameOfScreen = 0.0f;
    NSScreen *result = mainScreen;
    
    for (NSScreen *currentScreen in screens) {
        CGRect currentFrameOfScreen = NSRectToCGRect(currentScreen.frame);
        CGRect flippedRect = rect;
        CGFloat percentageOfRectWithinCurrentFrameOfScreen = 0.0f;

        flippedRect.origin.y = FlipVerticalOriginOfRectInRect(flippedRect, currentFrameOfScreen);
        
        if (CGRectContainsRect(currentFrameOfScreen, flippedRect)) {
            result = currentScreen;
            
            break;
        }
        
        percentageOfRectWithinCurrentFrameOfScreen = [self percentageOfRect: flippedRect withinFrameOfScreen: currentFrameOfScreen];
        
        if (percentageOfRectWithinCurrentFrameOfScreen > largestPercentageOfRectWithinFrameOfScreen) {
            largestPercentageOfRectWithinFrameOfScreen = percentageOfRectWithinCurrentFrameOfScreen;
            
            result = currentScreen;
        }
    }
    
    return result;
}

#pragma mark -

+ (CGFloat)percentageOfRect: (CGRect)rect withinFrameOfScreen: (CGRect)frameOfScreen {
    CGRect intersectionOfRectAndFrameOfScreen = CGRectIntersection(rect, frameOfScreen);
    CGFloat result = 0.0f;
    
    if (!CGRectIsNull(intersectionOfRectAndFrameOfScreen)) {
        result = AreaOfRect(intersectionOfRectAndFrameOfScreen) / AreaOfRect(rect);
    }
    
    return result;
}

#pragma mark -

+ (NSScreen *)nextOrPreviousScreenToFrameOfScreen: (CGRect)frameOfScreen inDirectionOfAction: (SpectacleWindowAction)action screens: (NSArray *)screens {
    NSScreen *result = nil;

    if (screens.count <= 1) {
        return result;
    }

    NSLog(@"Discovered %lu screen(s).", (unsigned long)screens.count);

    NSLog(@"Current screen: %@", RectToString(frameOfScreen));

    for (NSInteger i = 0; i < screens.count; i++) {
        NSScreen *currentScreen = screens[i];

        NSLog(@"    Screen %ld: %@", (long)i, RectToString(NSRectToCGRect(currentScreen.frame)));
    }

    if (action == SpectacleWindowActionNextDisplay) {
        NSLog(@"Selecting the screen of the NEXT display.");
    } else if (action == SpectacleWindowActionPreviousDisplay) {
        NSLog(@"Selecting the screen of the PREVIOUS display.");
    }

    for (NSInteger i = 0; i < screens.count; i++) {
        NSScreen *currentScreen = screens[i];
        CGRect currentFrameOfScreen = NSRectToCGRect(currentScreen.frame);
        NSInteger nextOrPreviousIndex = i;

        if (!CGRectEqualToRect(currentFrameOfScreen, frameOfScreen)) {
            continue;
        }

        NSLog(@"Index of the current screen: %ld", (long)i);

        if (action == SpectacleWindowActionNextDisplay) {
            nextOrPreviousIndex++;
        } else if (action == SpectacleWindowActionPreviousDisplay) {
            nextOrPreviousIndex--;
        }

        if (nextOrPreviousIndex < 0) {
            nextOrPreviousIndex = screens.count - 1;
        } else if (nextOrPreviousIndex >= screens.count) {
            nextOrPreviousIndex = 0;
        }

        result = screens[nextOrPreviousIndex];

        break;
    }

    NSLog(@"Selected screen: %@", RectToString(NSRectToCGRect(result.frame)));

    return result;
}

# pragma mark -

+ (NSArray *)screensInConsistentOrder: (NSArray *)screens {
    NSArray *result = [[screens sortedArrayWithOptions: NSSortStable usingComparator: ^(NSScreen *screenOne, NSScreen *screenTwo) {
        if (CGPointEqualToPoint(screenOne.frame.origin, CGPointMake(0, 0))) {
            return NSOrderedAscending;
        } else if (CGPointEqualToPoint(screenTwo.frame.origin, CGPointMake(0, 0))) {
            return NSOrderedDescending;
        }

        return (NSComparisonResult)(screenTwo.frame.origin.y - screenOne.frame.origin.y);
    }] sortedArrayWithOptions: NSSortStable usingComparator: ^(NSScreen *screenOne, NSScreen *screenTwo) {
        if (CGPointEqualToPoint(screenOne.frame.origin, CGPointMake(0, 0))) {
            return NSOrderedAscending;
        } else if (CGPointEqualToPoint(screenTwo.frame.origin, CGPointMake(0, 0))) {
            return NSOrderedDescending;
        }

        return (NSComparisonResult)(screenTwo.frame.origin.x - screenOne.frame.origin.x);
    }];

    return result;
}

@end
