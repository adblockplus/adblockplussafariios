#import "ActionRequestHandler.h"

@interface ActionRequestHandler ()

@end

@implementation ActionRequestHandler

- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context {
    NSItemProvider *attachment = [[NSItemProvider alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"easylist" withExtension:@"json"]];
    
    NSExtensionItem *item = [[NSExtensionItem alloc] init];
    item.attachments = @[attachment];
    
    [context completeRequestReturningItems:@[item] completionHandler:nil];
}

@end
