#include "ONPRootListController.h"
#import <Preferences/PSSpecifier.h>
#import "NSTask.h"

@implementation ONPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

- (void)openUrl:(PSSpecifier *)specifier {
    NSString *url = [specifier.properties objectForKey:@"url"];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: url]];
}

- (void)respring:(PSSpecifier *)specifier {
    NSTask *t = [[[NSTask alloc] init] autorelease];
    [t setLaunchPath:@"/usr/bin/killall"];
    [t setArguments:[NSArray arrayWithObjects:@"backboardd", nil]];
    [t launch];
}

- (void)reset:(PSSpecifier *)specifier {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    [manager removeItemAtPath:@"/var/mobile/Library/Preferences/ca.menushka.onenotify.preferences.plist" error:&error];
    [self respring:nil];
}

@end
