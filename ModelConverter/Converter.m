//
//  Converter.m
//  ModelConverter
//
//  Created by mac-246 on 10.02.16.
//  Copyright © 2016 mac-246. All rights reserved.
//

#import "Converter.h"


#pragma mark - NSMutableStrign+Join
@interface NSMutableString (Join)
- (void)addNextPart:(NSString *)nextPartString with:(NSString *)withString;
@end

@implementation NSMutableString (Join)
- (void)addNextPart:(NSString *)nextPartString with:(NSString *)withString {
    [self appendFormat:@"%@%@", nextPartString, withString];
}
@end


static NSString *androidProjectModelsPath = @"/Users/mac-246/Documents/Projects/rockspoon-pos/android-sdk/src/main/java/com/rockspoon/models"; // Where to find android models
//static NSString *outputFolder = @"/Users/mac-246/Documents/Projects/rockspoon-models";
//static NSString *outputFolder = @"/Users/mac-246/Documents/Projects Swift/test/test/rockspoon-models";
static NSString *outputFolder = @"/Users/mac-246/Documents/Projects/rockspoon-ios/Models/Models"; // Where to write converted models
static NSString *outputFolder2 = @"/Users/mac-246/Documents/Projects/rockspoon-pos/android-sdk/src/main/java/com/rockspoon/swift-models";
static const NSString *propertyTypeKey = @"propertyType";
static const NSString *propertyNameKey = @"propertyName";
static const NSString *propertyCommentKey = @"propertyComment";
static const NSString *propertyUnavailableKey = @"propertyUnavailable";


@interface Converter ()
@property (nonatomic) NSMutableSet *allEnumsNames;
@property (nonatomic) NSArray *stringEnums;
@end


@implementation Converter

- (instancetype)init
{
    if (!(self = [super init])) return nil;
    
    [[NSFileManager defaultManager] createDirectoryAtPath:outputFolder withIntermediateDirectories:YES attributes:nil error:nil];
    _stringEnums = @[@"UserGender", @"Status", @"ItemCategory", @"FoodServiceType", @"ItemAvailability"];
    [self getEnumsNames];
    [self convertModels];
    
    return self;
}

#pragma mark Covert flow
- (void)getEnumsNames {
    _allEnumsNames = [NSMutableSet set];
    
    NSURL *baseUrl = [NSURL URLWithString:androidProjectModelsPath];
    NSArray *files = [self getFilesUrls:baseUrl];
    for (NSURL *currentUrl in files) {
        NSError *error = nil;
        NSString *stringFromFileAtURL = [[NSString alloc] initWithContentsOfURL:currentUrl encoding:NSASCIIStringEncoding error:&error];
        NSArray *components = [stringFromFileAtURL componentsSeparatedByString:@" enum "];
        for (NSInteger i = 1; i < components.count; i++) {
            NSString *currentComponent = components[i];
            NSString *currentEnumName = [currentComponent componentsSeparatedByString:@" "][0];
            [_allEnumsNames addObject:currentEnumName];
        }
    }
}

- (void)createDirrectories {
    NSURL *directoryURL = [NSURL URLWithString:androidProjectModelsPath];
    NSArray *dirrectories = [self getDirectoriesUrls:directoryURL];
    for (NSURL *currentUrl in dirrectories) {
        NSString *relativePath = [currentUrl.path stringByReplacingOccurrencesOfString:androidProjectModelsPath withString:@""];
        NSString *outputPath = [outputFolder stringByAppendingPathComponent:relativePath];
        NSURL *directoryURL = [[NSURL alloc] initFileURLWithPath:outputPath isDirectory:YES];
        [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (void)convertModels {
    NSURL *baseUrl = [NSURL URLWithString:androidProjectModelsPath];
    NSArray *files = [self getFilesUrls:baseUrl];
    for (NSURL *currentUrl in files) {
        [self convertFile:currentUrl];
    }
}

- (void)convertFile:(NSURL *)fileURL {
    NSString *outputString = nil;
    
    NSError *error;
    NSString *stringFromFileAtURL = [[NSString alloc] initWithContentsOfURL:fileURL encoding:NSASCIIStringEncoding error:&error];
    if (stringFromFileAtURL != nil) {
        // PARSING
        if ([stringFromFileAtURL containsString:@" class "]) {
            // Parse as class
            outputString = [self parseStringAsClass:stringFromFileAtURL];
            // WRITTING
            if (outputString) {
                NSString *newFileName = [NSString stringWithFormat:@"%@.swift", [self getClassName:stringFromFileAtURL]];
                [self writeString:outputString originalFileURL:fileURL newFileName:newFileName];
            }
        } else if ([stringFromFileAtURL containsString:@" enum "]) {
            // Parse as enum
            outputString = [self parseStringAsEnum:stringFromFileAtURL];
            // WRITTING
            if (outputString) {
                NSString *newFileName = [NSString stringWithFormat:@"%@.swift", [self getEnumName:stringFromFileAtURL]];
                [self writeString:outputString originalFileURL:fileURL newFileName:newFileName];
            }
        }
    }
}

#pragma mark Helpers
- (NSArray *)getFilesUrls:(NSURL *)baseUrl {
    NSArray *keys = [NSArray arrayWithObjects: NSURLIsDirectoryKey, NSURLIsPackageKey, NSURLLocalizedNameKey, nil];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:baseUrl includingPropertiesForKeys:keys options:(NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles) errorHandler:^(NSURL *url, NSError *error) { return YES; }];
    
    NSMutableArray *filesUrls = [NSMutableArray array];
    for (NSURL *url in enumerator) {
        NSNumber *isDirectory = nil;
        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        
        if (![isDirectory boolValue]) {
            [filesUrls addObject:url];
        }
    }
    
    return filesUrls;
}

- (NSArray *)getDirectoriesUrls:(NSURL *)baseUrl {
    NSArray *keys = [NSArray arrayWithObjects: NSURLIsDirectoryKey, NSURLIsPackageKey, NSURLLocalizedNameKey, nil];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:baseUrl includingPropertiesForKeys:keys options:(NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles) errorHandler:^(NSURL *url, NSError *error) { return YES; }];
    
    NSMutableArray *directoriesUrl = [NSMutableArray array];
    for (NSURL *url in enumerator) {
        NSNumber *isDirectory = nil;
        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        
        if ([isDirectory boolValue]) {
            NSNumber *isPackage = nil;
            [url getResourceValue:&isPackage forKey:NSURLIsPackageKey error:NULL];
            
            if (![isPackage boolValue]) {
                [directoriesUrl addObject:url];
            }
        }
    }
    
    return directoriesUrl;
}

- (NSString *)intendString:(NSString *)string spaces:(NSString *)spaces {
    NSArray *components = [string componentsSeparatedByString:@"\n"];
    NSMutableArray *intentedComponents = [NSMutableArray arrayWithCapacity:components.count];
    
    for (NSString *currentComponent in components) {
        NSString *intendedComponent = [NSString stringWithFormat:@"%@%@", spaces, currentComponent];
        [intentedComponents addObject:intendedComponent];
    }
    
    NSString *intendedString = [intentedComponents componentsJoinedByString:@"\n"];
    
    return intendedString;
}

- (void)writeString:(NSString *)stringToWrite originalFileURL:(NSURL *)originalFileURL newFileName:(NSString *)newFileName {
    if (!stringToWrite || !originalFileURL) return;
    
    if (!newFileName) {
        newFileName = originalFileURL.lastPathComponent;
    }
    
    newFileName = [newFileName stringByReplacingOccurrencesOfString:@".java" withString:@".swift"];
    NSString *outputPath = [outputFolder stringByAppendingPathComponent:newFileName];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath isDirectory:NO];
    [self writeString:stringToWrite fileURL:outputURL];

    NSString *outputPath2 = [outputFolder2 stringByAppendingPathComponent:newFileName];
    NSURL *outputURL2 = [[NSURL alloc] initFileURLWithPath:outputPath2 isDirectory:NO];
    [self writeString:stringToWrite fileURL:outputURL2];
}

- (void)writeString:(NSString *)stringToWrite fileURL:(NSURL *)urlToWrite {
  NSError *error;
  BOOL ok = [stringToWrite writeToURL:urlToWrite atomically:YES encoding:NSUTF8StringEncoding error:&error];
  if (!ok) {
    // an error occurred
    NSLog(@"Error writing file at %@\n%@", urlToWrite, [error localizedFailureReason]);
  }
}

- (NSString *)titleStringWithName:(NSString *)name {
    NSString *titleSting = [NSString stringWithFormat:@"//\n//  %@.swift\n//  Models\n//\n//  Created by mac-246 on 10.02.16.\n//  Copyright © 2016 RockSpoon. All rights reserved.\n//", name];
    
    return titleSting;
}

- (NSString *)commentsWithText:(NSString *)commentsText spaces:(NSString *)spaces {
    NSString *commentsString = [NSString stringWithFormat:@"//-----------------------------------------------------------------------------\n// MARK: - %@\n//-----------------------------------------------------------------------------", commentsText];
    commentsString = [self intendString:commentsString spaces:spaces];
    
    return commentsString;
}

- (NSString *)commentString:(NSString *)stringToComment {
    return [NSString stringWithFormat:@"//%@", stringToComment];
}

- (BOOL)isUppercaseString:(NSString *)string {
    BOOL isUppercaseString = YES;
    for (NSInteger i = 0; i < string.length; i++) {
        unichar currentCharacter = [string characterAtIndex:i];
        BOOL isLowerCase = [[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:currentCharacter];
        if (isLowerCase) {
            isUppercaseString = NO;
            break;
        }
    }
    
    return isUppercaseString;
}

#pragma mark Creating class methods
- (NSString *)getClassName:(NSString *)classString {
    NSString *cuttedString = [classString componentsSeparatedByString:@" class "][1];
    
    NSString *className = [cuttedString componentsSeparatedByString:@" "][0];
    className = [className stringByReplacingOccurrencesOfString:@"Immutable" withString:@""];
    
    return className;
}

- (NSString *)parseStringAsClass:(NSString *)classString {
    // Cutting beginning
    NSString *cuttedString = [classString componentsSeparatedByString:@" class "][1];
    
    // Inner enum parse
    NSArray *innerEnumsStrings = [self getInnerEnums:classString];
    innerEnumsStrings = [self normalizeInnerEnums:innerEnumsStrings];
    
    cuttedString = [self removeOccurenceOfEnums:cuttedString];
    // Getting class name
    NSString *className = [self getClassName:classString];
    // Cutting to class values
    cuttedString = [cuttedString stringByReplacingOccurrencesOfString:@";" withString:@""];
    cuttedString = [cuttedString componentsSeparatedByString:@"{"][1];
    cuttedString = [cuttedString componentsSeparatedByString:@"}"][0];
    cuttedString = [cuttedString componentsSeparatedByString:@"@Override"][0];
    // Deleting not property lines
    NSArray *tempValues = [cuttedString componentsSeparatedByString:@"\n"];
    NSMutableArray *validValues = [NSMutableArray arrayWithCapacity:tempValues.count];
    NSString *initMethodStartsWithString = [NSString stringWithFormat:@"%@(", className];
    for (NSString *currentValue in tempValues) {
        NSString *noSpaceValue = [currentValue stringByReplacingOccurrencesOfString:@" " withString:@""];
        if (noSpaceValue.length == 0) { continue; }
        if ([currentValue containsString:initMethodStartsWithString]) { continue; }
        if ([currentValue containsString:@"@Deprecated"]) { continue; }
        if ([currentValue containsString:@"@DatabaseField"]) { continue; }
        if ([currentValue containsString:@" static "]) { continue; }
        if ([currentValue containsString:@"()"]) { continue; }
        
        // Removing comments
        NSString *firstPart = [currentValue componentsSeparatedByString:@"//"][0];
        noSpaceValue = [firstPart stringByReplacingOccurrencesOfString:@" " withString:@""];
        if (noSpaceValue.length) {
            [validValues addObject:firstPart];
        }
    }
    
    NSArray *propertiesArray = [self parsePropertiesArray:validValues];
    if (!propertiesArray.count) {
        return nil;
    }
    NSString *classObjectString = [self createClassObjectStringWithName:className propertiesArray:propertiesArray innerEnums:innerEnumsStrings];
    
    return classObjectString;
}

- (NSArray *)getInnerEnums:(NSString *)classString {
    NSMutableArray *innerEnumsStrings = [NSMutableArray array];
    
    NSArray *components = [classString componentsSeparatedByString:@"\n"];
    NSMutableString *enumString = [NSMutableString string];
    BOOL enumHandleStarted = NO;
    for (NSString *currentComponent in components) {
        if ([currentComponent containsString:@" enum "]) {
            enumHandleStarted = YES;
        }
        if (!enumHandleStarted) {
            continue;
        }
        [enumString appendFormat:@"%@\n", currentComponent];
        if ([currentComponent containsString:@"}"]) {
            enumHandleStarted = NO;
            [innerEnumsStrings addObject:enumString];
            enumString = [NSMutableString string];
        }
    }
    
    return innerEnumsStrings;
}

- (NSString *)removeOccurenceOfEnums:(NSString *)classString {
    NSArray *components = [classString componentsSeparatedByString:@"\n"];
    NSMutableArray *newComponents = [NSMutableArray arrayWithCapacity:components.count];
    BOOL enumHandleStarted = NO;
    for (NSString *currentComponent in components) {
        if ([currentComponent containsString:@" enum "]) {
            enumHandleStarted = YES;
            continue;
        }
        if ([currentComponent containsString:@"}"]) {
            enumHandleStarted = NO;
            continue;
        }
        if (enumHandleStarted) {
            continue;
        }
        [newComponents addObject:currentComponent];
    }
    
    NSString *classStringWithoutEnums =[newComponents componentsJoinedByString:@"\n"];
    
    return classStringWithoutEnums;
}

- (NSArray *)parsePropertiesArray:(NSArray *)propertiesArray {
    if (propertiesArray.count == 0) { return nil; }
    NSMutableArray *properties = [NSMutableArray array];
    
    NSString *commentString = nil;
    for (NSString *currentComponent in propertiesArray) {
        // Checking if annotation
        if ([currentComponent containsString:@"@JsonProperty(\""]) {
            commentString = [currentComponent componentsSeparatedByString:@"\""][1];
            continue;
        }
        
        NSArray *components = [currentComponent componentsSeparatedByString:@"private final "];
        if (components.count < 2) {
            components = [currentComponent componentsSeparatedByString:@"private "];
        }
        if (components.count < 2) {
            components = [currentComponent componentsSeparatedByString:@"protected "];
        }
        NSString *tempString = components[1];
        
        // Getting property name
        NSString *propertyNameString = [[tempString componentsSeparatedByString:@" "] lastObject];
        
        // Getting type
        NSString *typeString;
        if ([propertyNameString isEqualToString:@"id"]) {
            typeString = @"Int";
        } else {
            typeString = [tempString stringByReplacingOccurrencesOfString:propertyNameString withString:@""];
            typeString = [self convertTypeName:typeString];
        }
        
        NSMutableDictionary *propertyDictionary = [NSMutableDictionary dictionary];
        if (typeString.length) {
            if ([typeString containsString:@"Command"]) {
                [propertyDictionary setObject:@YES forKey:propertyUnavailableKey];
            }
            [propertyDictionary setObject:typeString forKey:propertyTypeKey];
        }
        if (commentString.length) {
            [propertyDictionary setObject:commentString forKey:propertyCommentKey];
            commentString = nil;
        }
        if (propertyNameString.length) {
            if ([propertyNameString isEqualToString:@"description"]) {
                propertyNameString = @"descriptionString";
            }
            [propertyDictionary setObject:propertyNameString forKey:propertyNameKey];
        }
        [properties addObject:propertyDictionary];
    }
    
    return properties;
}

- (NSString *)convertTypeName:(NSString *)javaTypeNameString {
    NSString *convertedTypeName = javaTypeNameString;
    
    if ([javaTypeNameString containsString:@"BigDecimal"]) {
        NSLog(@"");
    }
    
    convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:@"boolean" withString:@"Bool"];
    convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:@"Boolean" withString:@"Bool"];
    convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:@"int" withString:@"Int"];
    convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:@"Integer" withString:@"Int"];
    convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:@"Short" withString:@"Int"];
    convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:@"short" withString:@"Int"];
    convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:@"BigDecimal" withString:@"Int"];
    convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:@"Long" withString:@"Int"];
    convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:@"Date" withString:@"NSDate"];
    convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:@"Timestamp" withString:@"NSDate"];
    convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:@"UUID" withString:@"NSUUID"];
    convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:@"Object" withString:@"AnyObject"];
    convertedTypeName = [self convertComplexTypes:convertedTypeName];
    
    // Removing excess spaces
    NSInteger length = convertedTypeName.length;
    while ([[convertedTypeName substringFromIndex:length-1] isEqualToString:@" "]) {
        convertedTypeName = [convertedTypeName substringToIndex:length - 1];
        length = convertedTypeName.length;
    }
    
    if ([convertedTypeName containsString:@"[]"]) {
        NSString *typeName = [convertedTypeName componentsSeparatedByString:@"[]"][0];
        convertedTypeName = [NSString stringWithFormat:@"[%@]", typeName];
    }
    
    return convertedTypeName;
}

- (NSString *)convertComplexTypes:(NSString *)typeName {
    NSString *convertedTypeName = typeName;
    
    // Converting List -> []
    while ([convertedTypeName containsString:@"List<"]) {
        NSArray *listSplittedComponents = [convertedTypeName componentsSeparatedByString:@"List<"];
        NSArray *lessSymbolComponentsAfterList = [listSplittedComponents[1] componentsSeparatedByString:@"<"];
        NSInteger innerTypeBraces = lessSymbolComponentsAfterList.count - 1;
        NSArray *moreSymbolComponentsAfterList = [listSplittedComponents[1] componentsSeparatedByString:@">"];
        NSMutableString *innerType = [NSMutableString stringWithString:moreSymbolComponentsAfterList[0]];
        for (NSInteger i = 0; i < innerTypeBraces; i++) {
            NSString *component = moreSymbolComponentsAfterList[i+1];
            [innerType addNextPart:@">" with:component];
        }
        NSString *oldListString = [NSString stringWithFormat:@"List<%@>", innerType];
        NSString *newListString = [NSString stringWithFormat:@"[%@]", innerType];
        convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:oldListString withString:newListString];
    }
    
    // converting Map -> [:]
    while ([convertedTypeName containsString:@"Map<"]) {
        NSArray *mapSplittedComponents = [convertedTypeName componentsSeparatedByString:@"Map<"];
        NSArray *lessSymbolComponentsBeforeMap = [mapSplittedComponents[0] componentsSeparatedByString:@"<"];
        NSInteger multiplicity = lessSymbolComponentsBeforeMap.count - 1;
        NSArray *moreSymbolComponentsAfterMap = [mapSplittedComponents[1] componentsSeparatedByString:@">"];
        NSString *innerType = moreSymbolComponentsAfterMap[multiplicity];
        
        NSString *oldListString = [NSString stringWithFormat:@"Map<%@>", innerType];
        NSString *newListString = [NSString stringWithFormat:@"[%@]", innerType];
        newListString = [newListString stringByReplacingOccurrencesOfString:@" " withString:@""];
        newListString = [newListString stringByReplacingOccurrencesOfString:@"," withString:@": "];
        convertedTypeName = [convertedTypeName stringByReplacingOccurrencesOfString:oldListString withString:newListString];
    }
    
    return convertedTypeName;
}

- (NSString *)createClassObjectStringWithName:(NSString *)className propertiesArray:(NSArray *)propertiesArray innerEnums:(NSArray *)innerEnumsStrings {
    NSMutableString *classObjectSting = [NSMutableString string];
    NSString *titleString = [self titleStringWithName:className];
    [classObjectSting addNextPart:titleString with:@"\n\n"];
  
    NSString *swiftlintDisableString = @"// swiftlint:disable line_length";
    [classObjectSting addNextPart:swiftlintDisableString with:@"\n"];
  
    NSString *importString = @"import Foundation";
    [classObjectSting addNextPart:importString with:@"\n\n"];
    
    NSString *privateConstantsCommentString = [self commentsWithText:@"Private constants" spaces:@""];
    [classObjectSting addNextPart:privateConstantsCommentString with:@"\n\n"];
    
    NSString *privateConstantsString = [self privateConstatnsStringWithPropertiesArray:propertiesArray];
    [classObjectSting addNextPart:privateConstantsString with:@"\n\n"];
    
    NSString *classDeclarationString = [NSString stringWithFormat:@"public final class %@: NSObject, NSCoding {", className];
    [classObjectSting addNextPart:classDeclarationString with:@"\n  \n"];
    
    if (innerEnumsStrings.count) {
        NSString *innerEnumsCommentString = [self commentsWithText:@"Inner enums" spaces:@"  "];
        [classObjectSting addNextPart:innerEnumsCommentString with:@"\n  \n"];
        
        for (NSString *enumString in innerEnumsStrings) {
            NSString *intendedEnumString = [self intendString:enumString spaces:@"  "];
            [classObjectSting addNextPart:intendedEnumString with:@"\n  \n"];
        }
    }
    
    NSString *publicPropertiesCommentString = [self commentsWithText:@"Public properties" spaces:@"  "];
    [classObjectSting addNextPart:publicPropertiesCommentString with:@"\n  \n"];
    
    NSString *publicPropertiesString = [self publicPropertiesStringWithPropertiesArray:propertiesArray];
    [classObjectSting addNextPart:publicPropertiesString with:@"\n  \n"];
    
    NSString *initializersCommentString = [self commentsWithText:@"Initializers" spaces:@"  "];
    [classObjectSting addNextPart:initializersCommentString with:@"\n  \n"];
    
    NSString *publicinitString = @"  public override init() {\n    \n  }";
    [classObjectSting addNextPart:publicinitString with:@"\n  \n"];
    
    NSString *nscodingCommentsString = [self commentsWithText:@"NSCoding" spaces:@"  "];
    [classObjectSting addNextPart:nscodingCommentsString with:@"\n  \n"];
    
    NSString *initDeclarationString = @"  public required init?(coder aDecoder: NSCoder) {";
    [classObjectSting addNextPart:initDeclarationString with:@"\n"];
    
    NSString *initString = [self initmethodStringWithPropertiesArray:propertiesArray];
    [classObjectSting addNextPart:initString with:@"\n"];
    
    NSString *initCloseString = @"  }";
    [classObjectSting addNextPart:initCloseString with:@"\n  \n"];
    
    NSString *encodeDeclarationString = @"  public func encodeWithCoder(aCoder: NSCoder) {";
    [classObjectSting addNextPart:encodeDeclarationString with:@"\n"];
    
    NSString *encodeString = [self encodeStringWithPropertiesArray:propertiesArray];
    [classObjectSting addNextPart:encodeString with:@"\n"];
    
    NSString *encdodeCloseString = @"  }";
    [classObjectSting addNextPart:encdodeCloseString with:@"\n"];
    
    NSString *classCloseString = @"}";
    [classObjectSting addNextPart:classCloseString with:@"\n"];
  
    return classObjectSting;
}

- (NSString *)privateConstatnsStringWithPropertiesArray:(NSArray *)propertiesArray {
    NSMutableArray *privateConstantsStringsArray = [NSMutableArray arrayWithCapacity:propertiesArray.count];
    for (NSDictionary *currentProperty in propertiesArray) {
        NSString *propertyName = currentProperty[propertyNameKey];
        NSNumber *currentPropertyUnavailable = currentProperty[propertyUnavailableKey];
        
        NSString *currentLine = [NSString stringWithFormat:@"private let %@Key = \"%@\"", propertyName, propertyName];
        
        if ([currentPropertyUnavailable isEqualToNumber:@YES]) {
            currentLine = [self commentString:currentLine];
        }
        
        [privateConstantsStringsArray addObject:currentLine];
    }
    
    NSString *privateConstatnsString = [privateConstantsStringsArray componentsJoinedByString:@"\n"];
    
    return privateConstatnsString;
}

- (NSArray *)normalizeInnerEnums:(NSArray *)innerEnumsStrings {
    NSMutableArray *normalizedInnerEnums = [NSMutableArray arrayWithCapacity:innerEnumsStrings.count];
    for (NSString *innerEnumString in innerEnumsStrings) {
        NSString *innerEnumName = [self getEnumName:innerEnumString];
        NSString *cuttedString = [innerEnumString componentsSeparatedByString:@"{"][1];
        cuttedString = [cuttedString componentsSeparatedByString:@"}"][0];
        cuttedString = [cuttedString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        cuttedString = [cuttedString stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSArray *types = [cuttedString componentsSeparatedByString:@","];
        NSMutableArray *normalizedTypes = [NSMutableArray arrayWithCapacity:types.count];
        for (NSString *type in types) {
            NSString *normalizedType = [self normalizeEnumString:type];
            [normalizedTypes addObject:normalizedType];
        }
        
        NSString *normalizedEnumString = [self enumStringWithName:innerEnumName valuesArray:normalizedTypes];
        
        [normalizedInnerEnums addObject:normalizedEnumString];
    }
    
    return normalizedInnerEnums;
}

- (NSString *)publicPropertiesStringWithPropertiesArray:(NSArray *)propertiesArray {
    NSMutableArray *publicPropertiesStringsArray = [NSMutableArray arrayWithCapacity:propertiesArray.count];
    for (NSDictionary *currentProperty in propertiesArray) {
        NSString *currentPropertyName = currentProperty[propertyNameKey];
        NSString *currentPropertyType = currentProperty[propertyTypeKey];
        NSString *currentPropertyComment = currentProperty[propertyCommentKey];
        NSNumber *currentPropertyUnavailable = currentProperty[propertyUnavailableKey];
        
        NSString *currentLine = [NSString stringWithFormat:@"  public var %@: %@?", currentPropertyName, currentPropertyType];
        if (currentPropertyComment) {
            currentLine = [NSString stringWithFormat:@"%@ // %@", currentLine, currentPropertyComment];
        }
        
        if ([currentPropertyUnavailable isEqualToNumber:@YES]) {
            currentLine = [self commentString:currentLine];
        }
        
        [publicPropertiesStringsArray addObject:currentLine];
    }
    
    NSString *publicPropertiesString = [publicPropertiesStringsArray componentsJoinedByString:@"\n"];
    
    return publicPropertiesString;
}

- (NSString *)initmethodStringWithPropertiesArray:(NSArray *)propertiesArray {
    NSMutableArray *initStringsArray = [NSMutableArray arrayWithCapacity:propertiesArray.count];
    for (NSDictionary *currentProperty in propertiesArray) {
        NSString *currentPropertyName = currentProperty[propertyNameKey];
        NSString *currentPropertyType = currentProperty[propertyTypeKey];
        NSNumber *currentPropertyUnavailable = currentProperty[propertyUnavailableKey];
        NSString *currentPropertyArrayType = nil;
        NSString *currentLine = nil;
        BOOL isEnum = NO;
        BOOL isEnumArray = NO;
        for (NSString *currentEnumName in _allEnumsNames) {
            if ([currentPropertyType containsString:currentEnumName]) {
                if ([currentPropertyType isEqualToString:currentEnumName]) {
                    isEnum = YES;
                }
                if ([currentPropertyType containsString:[NSString stringWithFormat:@"[%@]", currentEnumName]] || [currentPropertyType containsString:[NSString stringWithFormat:@".%@]", currentEnumName]]) {
                    isEnumArray = YES;
                    currentPropertyArrayType = [currentPropertyType stringByReplacingOccurrencesOfString:@"[" withString:@""];
                    currentPropertyArrayType = [currentPropertyArrayType stringByReplacingOccurrencesOfString:@"]" withString:@""];
                }
            }
        }
        if (isEnumArray) {
          if ([_stringEnums containsObject:currentPropertyArrayType]) {
            currentLine = [NSString stringWithFormat:@"    %@ = enumsArrayFromArray(aDecoder.decodeObjectForKey(%@Key) as? [String])", currentPropertyName, currentPropertyName];
          } else {
            currentLine = [NSString stringWithFormat:@"    %@ = enumsArrayFromArray(aDecoder.decodeObjectForKey(%@Key) as? [Int])", currentPropertyName, currentPropertyName];
          }
        } else if (isEnum) {
            currentLine = [NSString stringWithFormat:@"    %@ = %@(aDecoder.decodeObjectForKey(%@Key)", currentPropertyName, currentPropertyType, currentPropertyName];
            if ([self isStringEnum:currentPropertyType]) {
                currentLine = [NSString stringWithFormat:@"%@ as? String)", currentLine];
            } else {
                currentLine = [NSString stringWithFormat:@"%@ as? Int)", currentLine];
            }
        } else {
            currentLine = [NSString stringWithFormat:@"    %@ = aDecoder.decodeObjectForKey(%@Key)", currentPropertyName, currentPropertyName];
            if (![currentPropertyType isEqualToString:@"AnyObject"]) {
                currentLine = [currentLine stringByAppendingString:[NSString stringWithFormat:@" as? %@", currentPropertyType]];
            }
        }
        
        if ([currentPropertyUnavailable isEqualToNumber:@YES]) {
            currentLine = [self commentString:currentLine];
        }
        
        [initStringsArray addObject:currentLine];
    }
    
    NSString *publicPropertiesString = [initStringsArray componentsJoinedByString:@"\n"];
    
    return publicPropertiesString;
}

- (NSString *)encodeStringWithPropertiesArray:(NSArray *)propertiesArray {
    NSMutableArray *encodeStringsArray = [NSMutableArray arrayWithCapacity:propertiesArray.count];
    for (NSDictionary *currentProperty in propertiesArray) {
        NSString *currentPropertyName = currentProperty[propertyNameKey];
        NSString *currentPropertyType = currentProperty[propertyTypeKey];
        NSNumber *currentPropertyUnavailable = currentProperty[propertyUnavailableKey];
        NSString *currentPropertyArrayType = nil;
        NSString *currentLine = nil;
        BOOL isEnum = NO;
        BOOL isEnumArray = NO;
        for (NSString *currentEnumName in _allEnumsNames) {
            if ([currentPropertyType containsString:currentEnumName]) {
                if ([currentPropertyType isEqualToString:currentEnumName]) {
                    isEnum = YES;
                }
                if ([currentPropertyType containsString:[NSString stringWithFormat:@"[%@]", currentEnumName]] || [currentPropertyType containsString:[NSString stringWithFormat:@".%@]", currentEnumName]]) {
                    isEnumArray = YES;
                    currentPropertyArrayType = [currentPropertyType stringByReplacingOccurrencesOfString:@"[" withString:@""];
                    currentPropertyArrayType = [currentPropertyArrayType stringByReplacingOccurrencesOfString:@"]" withString:@""];
                }
            }
        }
        if (isEnumArray) {
              currentLine = [NSString stringWithFormat:@"    aCoder.encodeObject(arrayFromEnumsArray(%@), forKey: %@Key)", currentPropertyName, currentPropertyName];
        } else if (isEnum) {
            currentLine = [NSString stringWithFormat:@"    aCoder.encodeObject(%@?.rawValue, forKey: %@Key)", currentPropertyName, currentPropertyName];
        } else {
            currentLine = [NSString stringWithFormat:@"    aCoder.encodeObject(%@, forKey: %@Key)", currentPropertyName, currentPropertyName];
        }
        
        if ([currentPropertyUnavailable isEqualToNumber:@YES]) {
            currentLine = [self commentString:currentLine];
        }
        
        [encodeStringsArray addObject:currentLine];
    }
    
    NSString *publicPropertiesString = [encodeStringsArray componentsJoinedByString:@"\n"];
    
    return publicPropertiesString;
}

#pragma mark Creating enum methods
- (NSString *)getEnumName:(NSString *)enumString {
    NSString *cuttedString = [enumString componentsSeparatedByString:@"public enum "][1];
    
    NSString *enumName = [cuttedString componentsSeparatedByString:@" "][0];
    
    return enumName;
}

- (NSString *)parseStringAsEnum:(NSString *)enumString {
    // Cutting beginning
    NSString *cuttedString = [enumString componentsSeparatedByString:@"public enum "][1];
    // Getting enum name
    NSString *enumName = [self getEnumName:enumString];
    // Cutting to enum values
    cuttedString = [cuttedString stringByReplacingOccurrencesOfString:@";" withString:@""];
    cuttedString = [cuttedString componentsSeparatedByString:@"{"][1];
    cuttedString = [cuttedString componentsSeparatedByString:@"}"][0];
    // Deleting not enum lines
    NSArray *tempValues = [cuttedString componentsSeparatedByString:@"\n"];
    NSString *initMethodStartsWithString = [NSString stringWithFormat:@"%@(", enumName];
    NSMutableArray *validValues = [NSMutableArray arrayWithCapacity:tempValues.count];
    for (NSString *currentValue in tempValues) {
        NSString *noSpaceValue = [currentValue stringByReplacingOccurrencesOfString:@" " withString:@""];
        if ([currentValue containsString:@"private "]) { continue; }
        if ([currentValue containsString:@"public "]) { continue; }
        if ([currentValue containsString:initMethodStartsWithString]) { continue; }
        if (noSpaceValue.length == 0) { continue; }
        
        // Removing comments
        NSString *firstPart = [currentValue componentsSeparatedByString:@"//"][0];
        firstPart = [firstPart stringByReplacingOccurrencesOfString:@" " withString:@""];
        if (firstPart.length) {
            [validValues addObject:firstPart];
        }
    }
    
    cuttedString = [validValues componentsJoinedByString:@""];
    NSArray *clearEnumValuesArray = [cuttedString componentsSeparatedByString:@","];
    
    NSString *convertedModelString = [self createEnumObjectStringWithName:enumName values:clearEnumValuesArray];
    
    return convertedModelString;
}

- (NSString *)createEnumObjectStringWithName:(NSString *)enumName values:(NSArray *)valuesArray {
    NSString *titleString = [self titleStringWithName:enumName];
    NSString *enumString = [self enumStringWithName:enumName valuesArray:valuesArray];
    NSString *enumObjectFullString = [NSString stringWithFormat:@"%@\n\n%@", titleString, enumString];
    
    return enumObjectFullString;
}

- (NSString *)enumStringWithName:(NSString *)enumName valuesArray:(NSArray *)valuesArray {
    NSMutableString *enumString = [NSMutableString string];
    
    NSString *declarationString = nil;
    if ([self isStringEnum:enumName]) {
        declarationString = [NSString stringWithFormat:@"public enum %@: String, EVRawString, StringEnumInit {", enumName];
    } else {
        declarationString = [NSString stringWithFormat:@"public enum %@: Int, EVRawInt, IntEnumInit {", enumName];
    }
    [enumString addNextPart:declarationString with:@"\n"];
    
    NSMutableArray *enumValuesStrings = [NSMutableArray arrayWithCapacity:valuesArray.count];
    for (NSString *currentValueString in valuesArray) {
        NSString *normalizedEnumString = [self normalizeEnumString:currentValueString];
        NSString *caseString = [NSString stringWithFormat:@"%@%@", [[normalizedEnumString substringToIndex:1] uppercaseString], [normalizedEnumString substringFromIndex:1]];
        if ([self isStringEnum:enumName]) {
            caseString = [NSString stringWithFormat:@"  case %@ = \"%@\"", caseString, currentValueString];
        } else {
            caseString = [NSString stringWithFormat:@"  case %@", caseString];
        }
        [enumValuesStrings addObject:caseString];
    }
    NSString *casesString = [enumValuesStrings componentsJoinedByString:@"\n"];
    [enumString addNextPart:casesString with:@"\n\n"];
    
    if ([self isStringEnum:enumName]) {
        NSString *convertFromStringArrayString = [NSString stringWithFormat:@"    static func convertFromStringArray(stringArray: [String]?) -> [%@] {\n      guard let stringArray = stringArray else { return [] }\n      var enumArray = [%@]()\n      for currentValue: String in stringArray {\n        let currentEnum = %@(currentValue)\n        if let currentEnum = currentEnum {\n          enumArray.append(currentEnum)\n        }\n      }\n\n      return enumArray\n    }", enumName, enumName, enumName];
        [enumString addNextPart:convertFromStringArrayString with:@"\n\n"];

        NSString *convertToStringArrayString = [NSString stringWithFormat:@"    static func convertToStringArray(enumArray: [%@]?) -> [String] {\n      guard let enumArray = enumArray else { return [] }\n      var stringArray = [String]()\n      for currentValue: %@ in enumArray {\n        let currentString = currentValue.rawValue\n        stringArray.append(currentString)\n      }\n\n      return stringArray\n    }", enumName, enumName];
        [enumString addNextPart:convertToStringArrayString with:@"\n\n"];
    } else {
        NSString *convertFromIntArrayString = [NSString stringWithFormat:@"  static func convertFromIntArray(intArray: [Int]?) -> [%@] {\n    guard let intArray = intArray else { return [] }\n    var enumArray = [%@]()\n    for currentValue: Int in intArray {\n      let currentEnum = %@(currentValue)\n      if let currentEnum = currentEnum {\n        enumArray.append(currentEnum)\n      }\n    }\n    \n    return enumArray\n  }", enumName, enumName, enumName];
        [enumString addNextPart:convertFromIntArrayString with:@"\n\n"];
        
        NSString *convertToIntArrayString = [NSString stringWithFormat:@"  static func convertToIntArray(enumArray: [%@]?) -> [Int] {\n    guard let enumArray = enumArray else { return [] }\n    var intArray = [Int]()\n    for currentValue: %@ in enumArray {\n      let currentInt = currentValue.rawValue\n      intArray.append(currentInt)\n    }\n    \n    return intArray\n  }", enumName, enumName];
        [enumString addNextPart:convertToIntArrayString with:@"\n\n"];
    }
    
    NSString *initString = nil;
    if ([self isStringEnum:enumName]) {
        initString = [NSString stringWithFormat:@"  public init?(_ value: String?) {\n    guard let v = value, let e = %@(rawValue: v) else { return nil }\n    self = e\n  }\n}", enumName];
    } else {
        initString = [NSString stringWithFormat:@"  public init?(_ value: Int?) {\n    guard let v = value, let e = %@(rawValue: v) else { return nil }\n    self = e\n  }\n}", enumName];
    }
    [enumString addNextPart:initString with:@"\n"];
    
    return enumString;
}

- (NSString *)normalizeEnumString:(NSString *)enumString {
    NSString *normalizedEnumString = enumString;
    // Check if contains _
    if ([normalizedEnumString containsString:@"_"]) {
        NSArray *components = [normalizedEnumString componentsSeparatedByString:@"_"];
        NSMutableArray *newComponents = [NSMutableArray arrayWithCapacity:components.count];
        for (NSString *currentValuePart in components) {
            [newComponents addObject:currentValuePart.capitalizedString];
        }
        
        normalizedEnumString = [newComponents componentsJoinedByString:@""];
    }
    
    // Delete (...)
    normalizedEnumString = [normalizedEnumString componentsSeparatedByString:@"("][0];
    
    NSMutableArray *components = [[normalizedEnumString componentsSeparatedByString:@"("] mutableCopy];
    if ([self isUppercaseString:components[0]]) {
        components[0] = [components[0] capitalizedString];
        normalizedEnumString = [components componentsJoinedByString:@"("];
    }
    
    return normalizedEnumString;
}

- (BOOL)isStringEnum:(NSString *)enumName {
    BOOL stringEnum = NO;
    for (NSString *currentStringEnum in _stringEnums) {
        if ([currentStringEnum isEqualToString:enumName]) {
            stringEnum = YES;
            break;
        }
    }
    
    return stringEnum;
}

@end
