#import <UIKit/UIKit.h>
#import <CoreFoundation/CFBase.h>
#define kCFCoreFoundationVersionNumber_iOS_9_0 1240.1
@interface IMHandle
@property(readonly, nonatomic) NSString *name;
@end
@interface IMChat
@property(readonly) unsigned int messageCount;
- (unsigned int)messageCount;
- (void)messageIterate;
- (NSString *)bigMessageCount;
- (id)loadMessagesBeforeDate:(id)arg1 limit:(unsigned int)arg2;
- (void)setNumberOfMessagesToKeepLoaded:(unsigned int)arg1;
- (unsigned int)numberOfMessagesToKeepLoaded;
- (BOOL)hasMoreMessagesToLoad;
- (NSString *)guid;
@property(retain) IMHandle * recipient;
@end
@interface IMMessageItem
- (bool)isDelivered;
- (bool)isSent;
- (bool)isRead;
- (bool)isEmpty;
- (bool)isFinished;
- (bool)isFromMe;
- (id)_service;
@end
@interface CKConversation
@property(retain) IMChat * chat;
@property(retain,readonly) NSString * name;
@end
@interface IMService
- (BOOL)__ck_isSMS;
@end

@interface CKConversationListCell
- (void)updateContentsForConversation:(CKConversation*)conversation;
- (UITableView *)_tableView;
@end

@interface CKConversationList
- (NSArray *)conversations;
@end

@interface CKConversationListController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
- (CKConversationList *)conversationList;
@end
#define settingsPath @"/var/mobile/Library/Preferences/com.teggers.messagecount.plist"

NSMutableDictionary *messageCountDictionary;
%hook CKConversationListCell

- (void)updateContentsForConversation:(CKConversation*)conversation{
	%orig;
	if(messageCountDictionary == NULL){
		NSFileManager* fm = [NSFileManager defaultManager];
		if([fm fileExistsAtPath:settingsPath]){
			messageCountDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
		} else {
			messageCountDictionary = [[NSMutableDictionary alloc]
			initWithDictionary:@{
			}];
			[messageCountDictionary writeToFile:settingsPath atomically:YES];
		}
	}
	UILabel* nameLabel;
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0) {
		nameLabel = MSHookIvar<id>(self, "_fromLabel");
	} else {
		UITableViewCell* contentView = MSHookIvar<id>(self, "_contentView");
		nameLabel = contentView.subviews[1];
	}
	NSString *origName = conversation.name;
	NSString *mCountString = [conversation.chat bigMessageCount];
	NSString *newNameText = [origName stringByAppendingString:@" ("];
	newNameText = [newNameText stringByAppendingString:mCountString];
	newNameText = [newNameText stringByAppendingString:@")"];
	[nameLabel setText:newNameText];
}
%end

%hook IMChat
- (BOOL)_handleIncomingItem:(IMMessageItem*)arg1{
	if([[arg1 _service] __ck_isSMS]&& ![arg1 isDelivered] && ![arg1 isSent] && ![arg1 isRead] && [arg1 isFromMe] && [arg1 isFinished]){
		[self messageIterate];
	}
	if([arg1 isDelivered] && [arg1 isSent] && ![arg1 isRead] && [arg1 isFromMe]){
		[self messageIterate];
	}
	if([arg1 isDelivered] && ![arg1 isEmpty] && [arg1 isFinished] && ![arg1 isSent] && ![arg1 isRead] && ![arg1 isFromMe]){
		[self messageIterate];
	}
	return %orig;
}

%new
- (void)messageIterate{
	NSString *nmS = messageCountDictionary[[self guid]];
	long long nm = [nmS longLongValue] + 1;
	nmS = [NSString stringWithFormat:@"%lli", nm];
	messageCountDictionary[[self guid]] = nmS;
	[messageCountDictionary writeToFile:settingsPath atomically:YES];
}
%new
- (NSString *)bigMessageCount{
	NSString *nmS = messageCountDictionary[[self guid]];
	if(messageCountDictionary[[self guid]] == NULL){
		[self loadMessagesBeforeDate:0 limit:1000000];
		[NSTimer scheduledTimerWithTimeInterval:5.0
		target:self
		selector:@selector(mc:)
		userInfo:[NSNumber numberWithInt:1]
		repeats:NO];
		nmS = @"1";
	}
	return nmS;
}

%new
- (void)mc:(NSTimer*)n {
	NSString *nmS = [NSString stringWithFormat:@"%d", [self messageCount]];
	NSNumber *nL = n.userInfo;
	if([self messageCount] > 1 || [nL intValue] > 50 ){
		messageCountDictionary[[self guid]] = nmS;
		[messageCountDictionary writeToFile:settingsPath atomically:YES];
	} else {
		[NSTimer scheduledTimerWithTimeInterval:5.0
		target:self
		selector:@selector(mc:)
		userInfo:[NSNumber numberWithInt:[nL intValue]+1]
		repeats:NO];
	}
}
%end
