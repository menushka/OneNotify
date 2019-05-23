#import <UIKit/UIKit.h>

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

NCNotificationListCollectionView *collectionView;


BOOL pullToDismissEnabled = YES;
int pullToDismissAmount = 100;
BOOL dismiss = NO;

%hook NCNotificationListCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
	collectionView = %orig;
	return collectionView;
}

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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	%orig;
	if (!pullToDismissEnabled) return;
	if (scrollView.contentOffset.y < -scrollView.contentInset.top - pullToDismissAmount) {
		if (dismiss) return;
		dismiss = YES;
		[self kn_dismissAllNotifications: scrollView];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	%orig;
	if (!pullToDismissEnabled) return;
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

%hook SBScreenWakeAnimationController

-(void)prepareToWakeForSource:(long long)arg1 timeAlpha:(double)arg2 statusBarAlpha:(double)arg3 delegate:(id)arg4 target:(id)arg5 completion:(/*^block*/id)arg6 {
	dispatch_async(dispatch_get_main_queue(), ^{
		[collectionView.listDelegate forceNotificationHistoryRevealed: YES animated: NO];
	});

	%orig;
}

%end

%ctor {
	@autoreleasepool {
		%init;

		BOOL hideTextNotificationCenter = YES;
		BOOL hideTextNoOlderNotifications = YES;

		NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/ca.menushka.onenotify.preferences.plist"];
		if (prefs) {
			id hideTextNotificationCenterValue = [prefs valueForKey: @"hideTextNotificationCenter"];
			if (hideTextNotificationCenterValue) {
				hideTextNotificationCenter = [hideTextNotificationCenterValue boolValue];
			}

			id hideTextNoOlderNotificationsValue = [prefs valueForKey: @"hideTextNoOlderNotifications"];
			if (hideTextNoOlderNotificationsValue) {
				hideTextNoOlderNotifications = [hideTextNoOlderNotificationsValue boolValue];
			}

			id pullToDismissEnabledValue = [prefs valueForKey: @"pullToDismissEnabled"];
			if (pullToDismissEnabledValue) {
				pullToDismissEnabled = [pullToDismissEnabledValue boolValue];
			}

			id pullToDismissAmountValue = [prefs valueForKey: @"pullToDismissAmount"];
			if (pullToDismissAmountValue) {
				pullToDismissAmount = [pullToDismissAmountValue intValue];
			}
		}

		if (hideTextNotificationCenter) %init(HideNotificationCenter);
		if (hideTextNoOlderNotifications) %init(HideNoOlderNotifications);
	}
}