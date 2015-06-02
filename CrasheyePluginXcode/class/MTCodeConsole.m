//
//  MTCodeConsole.m
//  CrasheyePluginXcode
//
//  Created by Gang.Wang on 5/4/15.
//  Copyright (c) 2015 Gang.Wang. All rights reserved.
//

#import "MTCodeConsole.h"

@interface MTCodeConsole ()

@property (retain, nonatomic) NSTextView* console;
@property (strong, nonatomic) NSString* windowIdentifier;

@end

@implementation MTCodeConsole


static NSMutableDictionary* sharedInstances;

- (id)initWithIdentifier:(NSString*)identifier
{
    if (self = [super init]) {
        _windowIdentifier = identifier;
    }
    
    return self;
}

- (NSTextView*)console
{
    if (!_console) {
        _console = [self findConsoleAndActivate];
    }
    return _console;
}

- (void)log:(id)obj
{
    [self appendText:[NSString stringWithFormat:@"%@\n", obj]];
}

- (void)error:(id)obj
{
    [self appendText:[NSString stringWithFormat:@"%@\n", obj]
               color:[NSColor redColor]];
}

- (void)appendText:(NSString*)text
{
    [self appendText:text color:nil];
}

- (NSWindow*)window
{
    for (NSWindow* window in [NSApp windows]) {
        if ([[window description] isEqualToString:self.windowIdentifier]) {
            return window;
        }
    }
    return nil;
}

- (void)appendText:(NSString*)text color:(NSColor*)color
{
    if (text.length == 0)
        return;
    
    if (!color)
        color = self.console.textColor;
    
    NSMutableDictionary* attributes = [@{ NSForegroundColorAttributeName : color } mutableCopy];
    NSFont* font = [NSFont fontWithName:@"Menlo Regular" size:11];
    if (font) {
        attributes[NSFontAttributeName] = font;
    }
    NSAttributedString* as = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    NSRange theEnd = NSMakeRange(self.console.string.length, 0);
    theEnd.location += as.string.length;
    if (NSMaxY(self.console.visibleRect) == NSMaxY(self.console.bounds)) {
        [self.console.textStorage appendAttributedString:as];
        [self.console scrollRangeToVisible:theEnd];
    }
    else {
        [self.console.textStorage appendAttributedString:as];
    }
}

- (void) replaceCharactersInRange:(NSRange)range withString:(NSString *)text
{
    if (text.length == 0)
        return;

    NSColor * color = self.console.textColor;
    NSMutableDictionary* attributes = [@{ NSForegroundColorAttributeName : color } mutableCopy];
    NSFont* font = [NSFont fontWithName:@"Menlo Regular" size:11];
    if (font) {
        attributes[NSFontAttributeName] = font;
    }

    NSAttributedString* as = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    
    NSRange theEnd = NSMakeRange(self.console.string.length, 0);
    theEnd.location += as.string.length;
    
    if (NSMaxY(self.console.visibleRect) == NSMaxY(self.console.bounds)) {
        [self.console.textStorage replaceCharactersInRange:range withAttributedString:as];
        [self.console scrollRangeToVisible:theEnd];
    }
    else {
        [self.console.textStorage replaceCharactersInRange:range withAttributedString:as];
    }

}

#pragma mark - Class Methods

+ (instancetype)consoleForKeyWindow
{
    return [self consoleForWindow:[NSApp keyWindow]];
}

+ (instancetype)consoleForWindow:(NSWindow*)window
{
    if (window == nil)
        return nil;
    
    NSString* key = [window description];
    
    if (!sharedInstances)
        sharedInstances = [[NSMutableDictionary alloc] init];
    
    if (!sharedInstances[key]) {
        MTCodeConsole* console = [[MTCodeConsole alloc] initWithIdentifier:key];
        [sharedInstances setObject:console forKey:key];
    }
    
    return sharedInstances[key];
}

#pragma mark - Console Detection

+ (NSView*)findConsoleViewInView:(NSView*)view
{
    Class consoleClass = NSClassFromString(@"IDEConsoleTextView");
    return [self findViewOfKind:consoleClass inView:view];
}

+ (NSView*)findViewOfKind:(Class)kind
                   inView:(NSView*)view
{
    if ([view isKindOfClass:kind]) {
        return view;
    }
    
    for (NSView* v in view.subviews) {
        NSView* result = [self findViewOfKind:kind
                                       inView:v];
        if (result) {
            return result;
        }
    }
    return nil;
}

- (NSTextView*)findConsoleAndActivate
{
    NSTextView* console = (NSTextView*)[[self class] findConsoleViewInView:self.window.contentView];
    if (console
        && [self.window isKindOfClass:NSClassFromString(@"IDEWorkspaceWindow")]
        && [self.window.windowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        id editorArea = [self.window.windowController valueForKey:@"editorArea"];
        [editorArea performSelector:@selector(activateConsole:) withObject:self];
    }
    
    [console.textStorage deleteCharactersInRange:NSMakeRange(0, console.textStorage.length)];
    
    return console;
}

@end
