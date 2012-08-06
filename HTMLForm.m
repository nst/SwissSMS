
#import "HTMLForm.h"
#import "NSDictionary+SMSSender.h"


@interface FormEncoding : NSObject {

}

+ (NSStringEncoding)encodingForCharset:(NSString *)charset;

@end

@implementation FormEncoding

+ (NSString *)charsetFromHTTPResponse:(NSHTTPURLResponse *)response
{
	NSString *contentType = [[response allHeaderFields] objectForKey:@"Content-Type"];
	NSArray *parameters = [contentType componentsSeparatedByString:@"; "];
	unsigned count = [parameters count];
	for(int i = 0; i < count; i++) {
		NSString *parameter = [parameters objectAtIndex:i];
		if ([parameter rangeOfString:@"charset"].location != NSNotFound) {
			NSArray *keyValue = [parameter componentsSeparatedByString:@"="];
			if ([keyValue count] == 2) {
				// charset may be quoted ( http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.6 ), so we trim "
				return [[[keyValue objectAtIndex:1] lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
			}
		}
	}
	
	return nil;
}

// Convert a string encoding "utf-8", "iso-8859-1" etc. to NSStringEncoding equivalent
+ (NSStringEncoding)encodingForCharset:(NSString *)charset
{
	if (charset == nil) {
		return NSWindowsCP1252StringEncoding;
	} else if ([charset caseInsensitiveCompare:@"utf-8"] == NSOrderedSame) {
		return NSUTF8StringEncoding;
	} else if ([charset caseInsensitiveCompare:@"iso-8859-1"] == NSOrderedSame) {
		return NSISOLatin1StringEncoding;
	} else {
		return NSWindowsCP1252StringEncoding;
	}
}

@end


@implementation HTMLForm

NSString * const HTMLFormErrorDomain = @"HTMLFormErrorDomain";
NSString * const HTMLFormUserErrorDomain = @"HTMLFormUserErrorDomain";

static NSString *userAgent = nil;

+ (NSString *)userAgent
{
	return userAgent;
}

+ (void)setUserAgent:(NSString *)theUserAgent
{
	[theUserAgent retain];
	[userAgent release];
	userAgent = theUserAgent;
}

+ (id)formNamed:(NSString *)formName atURL:(NSURL *)documentURL error:(NSError **)error
{
	return [[[self alloc] initWithFormNamed:formName atURL:documentURL error:error] autorelease];
}

- (id)initWithFormNamed:(NSString *)formName atURL:(NSURL *)documentURL error:(NSError **)error
{
	unsigned int count;
	
	self = [super init];
	if (self == nil) return nil;
	
	fName = formName ? [formName retain] : @"";
	
	// We could use the one line XMLDocument initWithContentsOfURL:options:error: method, but this way we could not set the User-Agent
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:documentURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
	NSHTTPURLResponse *response;
	[request setValue:[[self class] userAgent] forHTTPHeaderField:@"User-Agent"];
	NSError *connectionError = nil;
	NSData *documentData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
	[request release];
		
	if (connectionError) {
		// We must test for connectionError because when an error occurs, a zero length NSData is returned
		// It does NOT "Return nil if a connection could not be created or if the download fails"
		// as written in documentation
		if (error) *error = connectionError;
		return nil;
	}
	
	fDocument = [NSXMLDocument alloc];
	// charset encoding must be set before the document is initialized or xpath maches function will not work because of non matching encoding
	[fDocument setCharacterEncoding:[FormEncoding charsetFromHTTPResponse:response]];
	NSError *xmlError = nil;
	[fDocument initWithData:documentData options:NSXMLDocumentTidyHTML|NSXMLDocumentTidyXML error:&xmlError];
	
	if (!fDocument) {
		// -[NSXMLDocument initWithContentsOfURL...] returns an error when there are html formating warnings only
		// that's why we test !fDocument
		if (error) *error = xmlError;
		return nil;
	}
	
	// If formName is nil or @"", just find the only form, if there are several, fail
	BOOL formByName = [formName length] > 0;
	NSString *formXpathPrefix = formByName ? [NSString stringWithFormat:@"//form[@name=\"%@\"]", fName] : @"//form";
	
	NSArray *forms = [fDocument nodesForXPath:formXpathPrefix error:nil];
	
	if ([forms count] != 1) {
		int errorCode = formByName ? HTMLFormErrorNoSuchNamedForm : HTMLFormErrorNoSuchUnnamedForm;
		
		[fDocument release];
		if (error) *error = [NSError errorWithDomain:HTMLFormErrorDomain code:errorCode userInfo:nil];
		// TODO document the fact the if the error is in the HTMLFormErrorDomain, the form is returned anyway
		return nil;
	}
	
	fFields = [[NSMutableDictionary alloc] initWithCapacity:20];
	
	NSXMLElement *form = [forms objectAtIndex:0];
	
	fAction = [[NSURL alloc] initWithString:[[form attributeForName:@"action"] stringValue] relativeToURL:[response URL]];
	
	// Default value is GET if no method is specified
	fMethod = [[form attributeForName:@"method"] stringValue];
	if (fMethod) {
		fMethod = [[fMethod uppercaseString] retain];
	} else {
		fMethod = @"GET";
	}
		
	// Set input fields
	// BUG in -[NSXMLNode nodesForXPath:error:] ? "//input" also matches input from other forms in the document!
	NSArray *inputs = [form nodesForXPath:[NSString stringWithFormat:@"%@//input", formXpathPrefix] error:nil];
	count = [inputs count];
	for(int i = 0; i < count; i++) {
		NSXMLElement *input = [inputs objectAtIndex:i];
		NSString *name = [[input attributeForName:@"name"] stringValue];
		if (name) {
			// For radio buttons and checkboxes, only set the field if it has the "checked" attribute
			NSString *type = [[input attributeForName:@"type"] stringValue];
			if (([type caseInsensitiveCompare:@"radio"] == NSOrderedSame) || ([type caseInsensitiveCompare:@"checkbox"] == NSOrderedSame)) {
				if ([input attributeForName:@"checked"]) {
					[self setValue:[[input attributeForName:@"value"] stringValue] forField:name];
				}
			} else {
				[self setValue:[[input attributeForName:@"value"] stringValue] forField:name];
			}
		}
	}
	
	// Set select-option fields
	NSArray *selects = [form nodesForXPath:[NSString stringWithFormat:@"%@//select", formXpathPrefix] error:nil];
	count = [selects count];
	for(int i = 0; i < count; i++) {
		NSXMLElement *select = [selects objectAtIndex:i];
		NSString *name = [[select attributeForName:@"name"] stringValue];
		NSArray *options = [select elementsForName:@"option"];
		BOOL selected = NO;
		for(int j = 0; j < [options count]; j++) {
			// Try to find an option that has the "selected" attribute
			NSXMLElement *option = [options objectAtIndex:j];
			NSString *value = [[option attributeForName:@"value"] stringValue];
			if ([option attributeForName:@"selected"] && name) {
				[self setValue:value ? value : [option stringValue] forField:name];
				selected = YES;
				break;
			}
		}
		if (!selected && ([options count] >= 1)) {
			// If no option had the selected attribute, choose the first one
			[self setValue:[[options objectAtIndex:0] stringValue] forField:name];
		}
	}
	
	// Set select-option fields
	NSArray *textareas = [form nodesForXPath:[NSString stringWithFormat:@"%@//textarea", formXpathPrefix] error:nil];
	count = [textareas count];
	for(int i = 0; i < count; i++) {
		NSXMLElement *textarea = [textareas objectAtIndex:i];
		NSString *name = [[textarea attributeForName:@"name"] stringValue];
		if (name) {
			[self setValue:[textarea stringValue] forField:name];
		}
	}
	
	return self;
}

- (NSString *)valueForField:(NSString *)fieldName
{
	return [fFields valueForKey:fieldName];
}

- (void)setValue:(NSString *)fieldValue forField:(NSString *)fieldName
{
	[fFields setValue:fieldValue ? fieldValue : @"" forKey:fieldName];
}

- (void)removeField:(NSString *)fieldName
{
	[fFields removeObjectForKey:fieldName];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <%@> (%@)\n%@", [fName length] > 0 ? fName : @"[unnamed]", [fAction absoluteString], fMethod, fFields];
}

- (BOOL)submitExpectingSuccess:(NSString *)successXpath failures:(NSArray *)failuresXpaths error:(NSError **)error
{
	// Prepare form in "application/x-www-form-urlencoded" format
	NSData *postData = [fFields formDataWithEncoding:[FormEncoding encodingForCharset:[fDocument characterEncoding]]];
	
	// NSLog(@"postData: %@", [[[NSString alloc] initWithData:postData encoding:[FormEncoding encodingForCharset:[fDocument characterEncoding]]] autorelease]);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:fAction cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
	NSHTTPURLResponse *response;
	[request setHTTPMethod:fMethod];
	[request setValue:[[self class] userAgent] forHTTPHeaderField:@"User-Agent"];
	if ([fMethod isEqualToString:@"POST"]) {
		[request setHTTPBody:postData];
	} else {
		[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", [fAction absoluteString], [fAction query] ? @"&" : @"?", postData]]];
	}
	
	NSError *connectionError = nil;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
	[request release];
	
	if (connectionError) {
		// We must test for connectionError because when an error occurs, a zero length NSData is returned
		// It does NOT "Return nil if a connection could not be created or if the download fails"
		// as written in documentation
		if (error) *error = connectionError;
		return NO;
	}
	
	NSXMLDocument *responseDocument = [NSXMLDocument alloc];
	// charset encoding must be set before the document is initialized or xpath maches function will not work because of non matching encoding
	[responseDocument setCharacterEncoding:[FormEncoding charsetFromHTTPResponse:response]];
	NSError *xmlError = nil;
	[responseDocument initWithData:responseData options:NSXMLDocumentTidyHTML|NSXMLDocumentTidyXML error:&xmlError];

	if (!responseDocument) {
		// -[NSXMLDocument initWithContentsOfURL...] returns an error when there are html formating warnings only
		// that's why we test !responseDocument
		if (error) *error = xmlError;
		return NO;
	}
	
	// Check for success
	NSArray *nodes = [responseDocument nodesForXPath:successXpath error:nil];
	if ([nodes count] > 0) {
		[responseDocument release];
		return YES;
	}
	
	// Check for failures
	unsigned count = [failuresXpaths count];
	for(int i = 0; i < count; i++) {
		NSString *failureXpath = [failuresXpaths objectAtIndex:i];
		nodes = [responseDocument nodesForXPath:failureXpath error:nil];
		if ([nodes count] > 0) {
			if (error) *error = [NSError errorWithDomain:HTMLFormUserErrorDomain code:i userInfo:nil];
			[responseDocument release];
			return YES;
		}
	}
	
	// Neither success nor expected failure
	if (error) *error = [NSError errorWithDomain:HTMLFormErrorDomain code:HTMLFormErrorUnexpectedFormReply userInfo:nil];
	[responseDocument release];
	return NO;
}

- (void) dealloc
{
	[fName release];
	[fAction release];
	[fMethod release];
	[fFields release];
	[fDocument release];
	[super dealloc];
}

@end
