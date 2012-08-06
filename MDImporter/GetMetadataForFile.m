#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#include <Foundation/Foundation.h> 

/* -----------------------------------------------------------------------------
   Step 1
   Set the UTI types the importer supports
  
   Modify the CFBundleDocumentTypes entry in Info.plist to contain
   an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
   that your importer can handle
  
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 2 
   Implement the GetMetadataForFile function
  
   Implement the GetMetadataForFile function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update the schema.xml file
  
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableDictionary *d = (NSMutableDictionary *)attributes;
	NSDictionary *file = [NSDictionary dictionaryWithContentsOfFile:(NSString *)pathToFile];
	//NSLog(@"file: %@", file);
	if(!file) goto error;
	[d setObject:[NSArray arrayWithObjects:[file objectForKey:@"name"], [file objectForKey:@"phone"], nil] forKey:(NSString *)kMDItemRecipients];
	[d setObject:[file objectForKey:@"date"] forKey:(NSString *)kMDItemContentCreationDate];
	[d setObject:[file objectForKey:@"text"]                                forKey:(NSString *)kMDItemTextContent];
	NSString *displayName = [NSString stringWithFormat:@"SMS to %@: %@", [file objectForKey:@"name"], [file objectForKey:@"text"]];
	[d setObject:displayName forKey:(NSString *)kMDItemDisplayName];
	[d setObject:displayName forKey:(NSString *)kMDItemTitle];
	[pool release];
	
    return TRUE;
	
error:
	NSLog(@"Error: SwissSMS Spotlight importer could not import %@", (NSString *)pathToFile);
	[pool release];
	return FALSE;
}
