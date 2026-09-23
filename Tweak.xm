#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *const GMPLogPath = @"/var/mobile/GoogleMapsProbe.log";
static NSMutableSet<NSString *> *gSeen;

static void GMPLog(NSString *fmt, ...) {
    va_list args; va_start(args, fmt);
    NSString *m = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSString *line = [NSString stringWithFormat:@"[GMP] %@\n", m];
    NSData *d = [line dataUsingEncoding:NSUTF8StringEncoding];
    @synchronized (GMPLogPath) {
        NSFileHandle *h = [NSFileHandle fileHandleForWritingAtPath:GMPLogPath];
        if (!h) { [d writeToFile:GMPLogPath atomically:YES]; return; }
        @try { [h seekToEndOfFile]; [h writeData:d]; } @catch (...) {}
        [h closeFile];
    }
}

static BOOL GMPInteresting(NSString *s) {
    if (!s.length || s.length > 900) return NO;
    NSString *l=s.lowercaseString;
    NSArray *keys=@[@"cá rô",@"ca ro",@"rating",@"review",@"star",@"placeid",@"place_id",
                    @"latitude",@"longitude",@"formattedaddress",@"userRating"];
    for (NSString *k in keys) if ([l containsString:k.lowercaseString]) return YES;
    return NO;
}

static void GMPRecord(NSString *source, id obj) {
    if (!obj) return;
    NSString *s=nil;
    @try { s=[obj description]; } @catch (...) { return; }
    if (!GMPInteresting(s)) return;
    NSString *key=[NSString stringWithFormat:@"%@|%@",source,s];
    if ([gSeen containsObject:key]) return;
    [gSeen addObject:key];
    GMPLog(@"%@ class=%@ value=%@",source,NSStringFromClass([obj class]),s);
}

static void GMPWalk(id obj, NSUInteger depth) {
    if (!obj || depth>3) return;
    GMPRecord(@"RUNTIME",obj);
    if ([obj isKindOfClass:NSDictionary.class]) {
        NSDictionary *d=obj;
        for (id k in d) { GMPRecord(@"KEY",k); GMPWalk(d[k],depth+1); }
    } else if ([obj isKindOfClass:NSArray.class]) {
        NSUInteger n=MIN((NSUInteger)20,[(NSArray *)obj count]);
        for (NSUInteger i=0;i<n;i++) GMPWalk(((NSArray *)obj)[i],depth+1);
    }
}

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *url=request.URL.absoluteString ?: @"";
    if ([url.lowercaseString containsString:@"google"]) GMPLog(@"HTTP %@ %@",request.HTTPMethod ?: @"GET",url);
    void (^wrapped)(NSData *,NSURLResponse *,NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data.length && data.length < 1024*1024) {
            NSString *text=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (GMPInteresting(text)) GMPLog(@"HTTP-RESPONSE url=%@ bytes=%lu text=%@",url,(unsigned long)data.length,text);
        }
        if (completionHandler) completionHandler(data,response,error);
    };
    return %orig(request,wrapped);
}
%end

%hook NSJSONSerialization
+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)error {
    id obj=%orig;
    GMPWalk(obj,0);
    return obj;
}
%end

%ctor {
    @autoreleasepool {
        gSeen=[NSMutableSet set];
        [[NSFileManager defaultManager] removeItemAtPath:GMPLogPath error:nil];
        GMPLog(@"START bundle=%@ version=%@",NSBundle.mainBundle.bundleIdentifier,
               [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
    }
}
