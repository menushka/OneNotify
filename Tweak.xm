#import <MenushkaPrefs/MenushkaPrefs.h>
#import <UIKit/UIKit.h>
#import <SpringBoard/SBLockScreenManager.h>

#define kCFCoreFoundationVersion_iOS_13 1665

BOOL prefEnabled;
BOOL prefHideTextNotificationCenter;
BOOL prefHideTextNoOlderNotifications;
BOOL prefPullToDismissEnabled;
BOOL prefPullToDismissVibrateEnabled;
BOOL prefPullToDismissAmount;
BOOL prefDisableWhenLock;
BOOL prefBlockScreenWakeEnabled;
NSMutableDictionary *prefBlockScreenWakeSelectedApps;
NSInteger prefBlockScreenWakeSelectionMode;

@interface NCNotificationCombinedListViewController : UIViewController
- (long long)collectionView:(id)arg1 numberOfItemsInSection:(long long)arg2;
- (void)forceNotificationHistoryRevealed:(bool)arg1 animated:(bool)arg2;
- (void)_clearAllNotificationRequests;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)kn_dismissAllNotifications:(UIScrollView *)scrollView;
@end

@interface NCNotificationListCollectionView : UICollectionView
@property (assign, nonatomic) NCNotificationCombinedListViewController *listDelegate;
@end

@interface NCNotificationListSectionHeaderView : UICollectionReusableView
@property (copy, nonatomic) NSString *title;
@property (nonatomic,retain) UILabel *titleLabel;
@end

@interface NCNotificationRequest
@property (nonatomic,copy,readonly) NSString * sectionIdentifier;
@end

@interface NCNotificationStructuredSectionList
- (void)clearAllNotificationRequests;
@end

@interface CSCombinedListViewController : UIViewController
- (void)forceNotificationHistoryRevealed:(bool)arg1 animated:(bool)arg2;
@end

@interface NCNotificationMasterList
@property (nonatomic,retain) NCNotificationStructuredSectionList * incomingSectionList;
@property (nonatomic,retain) NCNotificationStructuredSectionList * historySectionList;
@property (nonatomic,retain) NCNotificationStructuredSectionList * missedSectionList;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)kn_dismissAllNotifications:(UIScrollView *)scrollView;
@end

@interface NCNotificationStructuredListViewController : UIViewController
@property (nonatomic, weak) CSCombinedListViewController *delegate;
@end

@interface SBDashBoardViewController : UIViewController
@property(nonatomic, getter=isAuthenticated) BOOL authenticated;
@end

@interface CSCoverSheetViewController : UIViewController
@property(nonatomic, getter=isAuthenticated) BOOL authenticated;
@end

@interface SBLockScreenManager ()
@property (readonly, nonatomic) SBDashBoardViewController *dashBoardViewController;
@property (readonly, nonatomic) CSCoverSheetViewController *coverSheetViewController;

@end

NCNotificationListCollectionView *collectionView;
NCNotificationStructuredListViewController *combinedList;

BOOL dismiss = NO;

%group OneNotifyEnabled

%hook NCNotificationListCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
	collectionView = %orig;
	return collectionView;
}

%end

%hook NCNotificationStructuredListViewController

-(id)init {
	combinedList = %orig;
	return combinedList;
}

%end

%hook SBScreenWakeAnimationController

-(void)prepareToWakeForSource:(long long)arg1 timeAlpha:(double)arg2 statusBarAlpha:(double)arg3 delegate:(id)arg4 target:(id)arg5 completion:(/*^block*/id)arg6 {
	dispatch_async(dispatch_get_main_queue(), ^{
		[collectionView.listDelegate forceNotificationHistoryRevealed: YES animated: NO];
	});

	%orig;
}

-(void)prepareToWakeForSource:(long long)arg1 timeAlpha:(double)arg2 statusBarAlpha:(double)arg3 target:(id)arg4 completion:(/*^block*/id)arg5 {
	dispatch_async(dispatch_get_main_queue(), ^{
		HBLogDebug(@"%@", combinedList.delegate);
		[combinedList.delegate forceNotificationHistoryRevealed: YES animated: NO];
	});

	%orig;
}

%end

%end

%group HideNotificationCenter

%hook NCNotificationListSectionHeaderView

-(id)initWithFrame:(CGRect)arg1 {
	NCNotificationListSectionHeaderView *r = %orig;
	r.hidden = 1;
	return r;
}

%end

%hook NCNotificationStructuredSectionList

-(double)headerViewHeightForNotificationList:(id)arg1 {
	return 0;
}

%end

%end

%group HideNoOlderNotifications

%hook NCNotificationListSectionRevealHintView

- (void)layoutSubviews {
	return;
}

%end

%end

%group PullToDismiss

%hook NCNotificationCombinedListViewController

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	%orig;
	if (prefDisableWhenLock) {
		BOOL isAuth = NO;
		SBLockScreenManager *manager = [%c(SBLockScreenManager) sharedInstance];
		if ([manager respondsToSelector:@selector(dashBoardViewController)]) {
		    // Only iOS 10+
		    SBDashBoardViewController *dashBoardViewController = manager.dashBoardViewController;
		    isAuth = [dashBoardViewController isAuthenticated];
		} else if ([manager respondsToSelector:@selector(coverSheetViewController)]) {
		    // iOS 13
		    CSCoverSheetViewController *coverSheetViewController = manager.coverSheetViewController;
	        isAuth = [coverSheetViewController isAuthenticated];
		}
		if (!isAuth) {
			return;
		}
	}
	if (scrollView.contentOffset.y < -scrollView.contentInset.top - prefPullToDismissAmount) {
		if (dismiss) return;
		dismiss = YES;
		[self kn_dismissAllNotifications: scrollView];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	%orig;
	dismiss = NO;
}

%new
- (void)kn_dismissAllNotifications:(UIScrollView *)scrollView {
	if (prefPullToDismissVibrateEnabled) {
		UIImpactFeedbackGenerator *myGen = [[UIImpactFeedbackGenerator alloc] initWithStyle:(UIImpactFeedbackStyleHeavy)];
		[myGen impactOccurred];
		myGen = NULL;
	}

	float scrollHeight = scrollView.contentOffset.y;
	[self _clearAllNotificationRequests];
	scrollView.contentOffset = CGPointMake(0, scrollHeight);
}

%end

%hook NCNotificationMasterList

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	%orig;
	if (prefDisableWhenLock) {
		BOOL isAuth = NO;
		SBLockScreenManager *manager = [%c(SBLockScreenManager) sharedInstance];
		if ([manager respondsToSelector:@selector(dashBoardViewController)]) {
		    // Only iOS 10+
		    SBDashBoardViewController *dashBoardViewController = manager.dashBoardViewController;
		    isAuth = [dashBoardViewController isAuthenticated];
		} else if ([manager respondsToSelector:@selector(coverSheetViewController)]) {
		    // iOS 13
		    CSCoverSheetViewController *coverSheetViewController = manager.coverSheetViewController;
	        isAuth = [coverSheetViewController isAuthenticated];
		}
		if (!isAuth) {
			return;
		}
	}
	if (scrollView.contentOffset.y < -scrollView.contentInset.top - prefPullToDismissAmount) {
		if (dismiss) return;
		dismiss = YES;
		[self kn_dismissAllNotifications: scrollView];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	%orig;
	dismiss = NO;
}

%new
- (void)kn_dismissAllNotifications:(UIScrollView *)scrollView {
	if (prefPullToDismissVibrateEnabled) {
		UIImpactFeedbackGenerator *myGen = [[UIImpactFeedbackGenerator alloc] initWithStyle:(UIImpactFeedbackStyleHeavy)];
		[myGen impactOccurred];
		myGen = NULL;
	}

	float scrollHeight = scrollView.contentOffset.y;
	[self.incomingSectionList clearAllNotificationRequests];
	[self.historySectionList clearAllNotificationRequests];
	[self.missedSectionList clearAllNotificationRequests];
	scrollView.contentOffset = CGPointMake(0, scrollHeight);
}

%end

%end

%group BlockScreenWake

%hook SBNCScreenController
-(BOOL)canTurnOnScreenForNotificationRequest:(NCNotificationRequest *)arg1 {
	if (prefBlockScreenWakeEnabled) {
		if (prefBlockScreenWakeSelectionMode == 0) {
			if ([prefBlockScreenWakeSelectedApps objectForKey:arg1.sectionIdentifier] != nil && [[prefBlockScreenWakeSelectedApps objectForKey:arg1.sectionIdentifier] boolValue] == YES) return NO;
		} else {
			if ([prefBlockScreenWakeSelectedApps objectForKey:arg1.sectionIdentifier] == nil || [[prefBlockScreenWakeSelectedApps objectForKey:arg1.sectionIdentifier] boolValue] == NO) return NO;
		}
	}
	return %orig;
}
%end

%end

void loadPrefs() {
	MenushkaPrefs *prefs = [MenushkaPrefs getPrefs:@"ca.menushka.onenotify.preferences"];

	prefEnabled = [prefs boolForKey:@"enabled" default:YES];
	prefHideTextNotificationCenter = [prefs boolForKey:@"hideTextNotificationCenter" default:YES];
	prefHideTextNoOlderNotifications = [prefs boolForKey:@"hideTextNoOlderNotifications" default:YES];
	prefPullToDismissEnabled = [prefs boolForKey:@"pullToDismissEnabled" default:YES];
	prefPullToDismissVibrateEnabled = [prefs boolForKey:@"pullToDismissVibrateEnabled" default:YES];
	prefPullToDismissAmount = [prefs floatForKey:@"pullToDismissAmount" default:100];
	prefBlockScreenWakeEnabled = [prefs boolForKey:@"blockScreenWakeEnabled" default:YES];
	prefDisableWhenLock = [prefs boolForKey:@"disableWhenLock" default:YES];
	prefBlockScreenWakeSelectedApps = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/ca.menushka.onenotify.preferences.app.plist"];
	prefBlockScreenWakeSelectionMode = [prefs intForKey:@"blockScreenWakeSelectionMode" default:0];
}

%ctor {
	loadPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("ca.menushka.onenotify.preferences/ReloadPrefs"), NULL, kNilOptions);
	if (prefEnabled) {
		%init(OneNotifyEnabled);

		if (prefHideTextNotificationCenter) %init(HideNotificationCenter);
		if (prefHideTextNoOlderNotifications) %init(HideNoOlderNotifications);
		if (prefPullToDismissEnabled) %init(PullToDismiss);
		if (prefBlockScreenWakeEnabled) %init(BlockScreenWake);
	}
}
