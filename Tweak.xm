#import <Cephei/HBPreferences.h>
#import <UIKit/UIKit.h>

BOOL prefEnabled;
BOOL prefHideTextNotificationCenter;
BOOL prefHideTextNoOlderNotifications;
BOOL prefPullToDismissEnabled;
BOOL prefPullToDismissAmount;
BOOL prefBlockScreenWakeEnabled;
NSMutableDictionary *prefBlockScreenWakeSelectedApps;
NSInteger prefBlockScreenWakeSelectionMode;

@interface NCNotificationCombinedListViewController : UIViewController
- (long long)collectionView:(id)arg1 numberOfItemsInSection:(long long)arg2;
- (void)forceNotificationHistoryRevealed:(bool) arg1 animated:(bool) arg2;
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

NCNotificationListCollectionView *collectionView;

int pullToDismissAmount = 100;
BOOL dismiss = NO;

%group OneNotifyEnabled

%hook NCNotificationListCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
	collectionView = %orig;
	return collectionView;
}

%end

%hook SBScreenWakeAnimationController

-(void)prepareToWakeForSource:(long long)arg1 timeAlpha:(double)arg2 statusBarAlpha:(double)arg3 delegate:(id)arg4 target:(id)arg5 completion:(/*^block*/id)arg6 {	
	dispatch_async(dispatch_get_main_queue(), ^{
		[collectionView.listDelegate forceNotificationHistoryRevealed: YES animated: NO];
	});

	%orig;
}

%end

%end

%group HideNotificationCenter

%hook NCNotificationCombinedListViewController

-(CGSize)collectionView:(id)arg1 layout:(id)arg2 referenceSizeForHeaderInSection:(long long)arg3 {
	if (arg3 == 0 || [self collectionView:self numberOfItemsInSection: 0] == 0) {
		return CGSizeMake(0, 0);
	} else {
		return CGSizeMake(0, 8);
	}
}

-(id)collectionView:(id)arg1 viewForSupplementaryElementOfKind:(id)arg2 atIndexPath:(id)arg3 {
	NCNotificationListSectionHeaderView *cell = %orig;
	[[cell subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	return cell;
}

%end

%hook NCNotificationListHeaderTitleView

- (void)layoutSubviews {
	return;
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
	if (scrollView.contentOffset.y < -scrollView.contentInset.top - pullToDismissAmount) {
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
	UIImpactFeedbackGenerator *myGen = [[UIImpactFeedbackGenerator alloc] initWithStyle:(UIImpactFeedbackStyleHeavy)];
	[myGen impactOccurred];
	myGen = NULL;

	float scrollHeight = scrollView.contentOffset.y;
	[self _clearAllNotificationRequests];
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
	HBPreferences *prefs = [[HBPreferences alloc] initWithIdentifier:@"ca.menushka.onenotify.preferences"];

	prefEnabled = [prefs boolForKey:@"enabled" default:YES];
	prefHideTextNotificationCenter = [prefs boolForKey:@"hideTextNotificationCenter" default:YES];
	prefHideTextNoOlderNotifications = [prefs boolForKey:@"hideTextNoOlderNotifications" default:YES];
	prefPullToDismissEnabled = [prefs boolForKey:@"pullToDismissEnabled" default:YES];
	prefPullToDismissAmount = [prefs floatForKey:@"pullToDismissAmount" default:100];
	prefBlockScreenWakeEnabled = [prefs boolForKey:@"blockScreenWakeEnabled" default:YES];
	prefBlockScreenWakeSelectedApps = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/ca.menushka.onenotify.preferences.app.plist"];
	prefBlockScreenWakeSelectionMode = [prefs integerForKey:@"blockScreenWakeSelectionMode" default:0];
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