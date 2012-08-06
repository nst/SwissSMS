/*!
	@header HTMLForm
	@abstract Retrieve, fill and submit HTML forms
		
	@copyright Copyright 2007 Cédric Luthi.
*/

#import <Cocoa/Cocoa.h>

/*!
	@abstract HTMLForm error domain
    @discussion See the <a href="../Enums/Enums.html#//apple_ref/c/tag/Error" target="doc">Error codes</a>
	section for all error codes belonging to this domain.
    @constant HTMLFormErrorDomain
*/
extern NSString * const HTMLFormErrorDomain;

/*!
	@abstract HTMLForm user error domain
    @discussion Constants used by NSError to differentiate between "domains" of error codes, 
    serving as a discriminator for error codes that originate from different subsystems or sources.
    @constant HTMLFormUserErrorDomain
*/
extern NSString * const HTMLFormUserErrorDomain;

/*!
    @enum Error codes
    @abstract Constants used by the <a href="../Constants/Constants.html#//apple_ref/c/data/HTMLFormErrorDomain" target="doc">HTMLFormErrorDomain</a>.
    @discussion Documentation on each constant forthcoming.
*/
enum
{
	HTMLFormErrorNoSuchNamedForm     = -1,
	HTMLFormErrorNoSuchUnnamedForm   = -2,
	
	HTMLFormErrorUnexpectedFormReply = -100,
};

/*!
	@class HTMLForm
	@abstract The HTMLForm class represents a HTML form, as defined in the <a href="http://www.w3.org/TR/html4/interact/forms.html">HTML 4.01 Specification</a>
*/
@interface HTMLForm : NSObject {

	NSURL *fAction;
	NSString *fName;
	NSString *fMethod;
	
	NSMutableDictionary *fFields;
	
	NSXMLDocument *fDocument;

}

+ (NSString *)userAgent;
+ (void)setUserAgent:(NSString *)userAgent;

+ (id)formNamed:(NSString *)formName atURL:(NSURL *)documentURL error:(NSError **)error;
- (id)initWithFormNamed:(NSString *)formName atURL:(NSURL *)documentURL error:(NSError **)error;

/*!
	@method valueForField:
	@param fieldName The name of the field
	@return The value associated with fieldName, or nil if no value is associated with fieldName.
*/
- (NSString *)valueForField:(NSString *)fieldName;

- (void)setValue:(NSString *)fieldValue forField:(NSString *)fieldName;
- (void)removeField:(NSString *)fieldName;

- (BOOL)submitExpectingSuccess:(NSString *)successXpath failures:(NSArray *)failuresXpaths error:(NSError **)error;


@end
