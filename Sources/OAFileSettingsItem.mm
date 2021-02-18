//
//  OAFileSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAFileSettingsItem.h"
#import "OASettingsHelper.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAGPXDocument.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXDatabase.h"
#import "OAIndexConstants.h"
#import "OASettingsItemReader.h"
#import "OASettingsItemWriter.h"

@implementation OAFileSettingsItemFileSubtype

+ (NSString *) getSubtypeName:(EOASettingsItemFileSubtype)subtype
{
    switch (subtype)
    {
        case EOASettingsItemFileSubtypeOther:
            return @"other";
        case EOASettingsItemFileSubtypeRoutingConfig:
            return @"routing_config";
        case EOASettingsItemFileSubtypeRenderingStyle:
            return @"rendering_style";
        case EOASettingsItemFileSubtypeObfMap:
            return @"obf_map";
        case EOASettingsItemFileSubtypeTilesMap:
            return @"tiles_map";
        case EOASettingsItemFileSubtypeWikiMap:
            return @"wiki_map";
        case EOASettingsItemFileSubtypeSrtmMap:
            return @"srtm_map";
        case EOASettingsItemFileSubtypeRoadMap:
            return @"road_map";
        case EOASettingsItemFileSubtypeGpx:
            return @"gpx";
        case EOASettingsItemFileSubtypeVoice:
            return @"voice";
        case EOASettingsItemFileSubtypeTravel:
            return @"travel";
        default:
            return @"";
    }
}

+ (NSString *) getSubtypeFolder:(EOASettingsItemFileSubtype)subtype
{
    NSString *documentsPath = OsmAndApp.instance.documentsPath;
    switch (subtype)
    {
        case EOASettingsItemFileSubtypeOther:
        case EOASettingsItemFileSubtypeObfMap:
        case EOASettingsItemFileSubtypeWikiMap:
        case EOASettingsItemFileSubtypeRoadMap:
        case EOASettingsItemFileSubtypeSrtmMap:
        case EOASettingsItemFileSubtypeRenderingStyle:
            return documentsPath;
        case EOASettingsItemFileSubtypeTilesMap:
            return [OsmAndApp.instance.dataPath stringByAppendingPathComponent:@"Resources"];;
        case EOASettingsItemFileSubtypeRoutingConfig:
            return [documentsPath stringByAppendingPathComponent:@"routing"];
        case EOASettingsItemFileSubtypeGpx:
            return OsmAndApp.instance.gpxPath;
            // unsupported
//        case EOASettingsItemFileSubtypeTravel:
//        case EOASettingsItemFileSubtypeVoice:
//            return [documentsPath stringByAppendingPathComponent:@"Voice"];
        default:
            return @"";
    }
}

+ (EOASettingsItemFileSubtype) getSubtypeByName:(NSString *)name
{
    for (int i = 0; i < EOASettingsItemFileSubtypesCount; i++)
    {
        NSString *subtypeName = [self.class getSubtypeName:(EOASettingsItemFileSubtype)i];
        if ([subtypeName isEqualToString:name])
            return (EOASettingsItemFileSubtype)i;
    }
    return EOASettingsItemFileSubtypeUnknown;
}

+ (EOASettingsItemFileSubtype) getSubtypeByFileName:(NSString *)fileName
{
    NSString *name = fileName;
    if ([fileName hasPrefix:@"/"])
        name = [fileName substringFromIndex:1];

    for (int i = 0; i < EOASettingsItemFileSubtypesCount; i++)
    {
        EOASettingsItemFileSubtype subtype = (EOASettingsItemFileSubtype) i;
        switch (subtype) {
            case EOASettingsItemFileSubtypeUnknown:
            case EOASettingsItemFileSubtypeOther:
                break;
            case EOASettingsItemFileSubtypeObfMap:
            {
                if ([name hasSuffix:BINARY_MAP_INDEX_EXT] && ![name containsString:@"/"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeSrtmMap:
            {
                if ([name hasSuffix:BINARY_SRTM_MAP_INDEX_EXT])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeWikiMap:
            {
                if ([name hasSuffix:BINARY_WIKI_MAP_INDEX_EXT])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeGpx:
            {
                if ([name hasSuffix:@".gpx"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeVoice:
            {
                if ([name hasSuffix:@"tts.js"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeTravel:
            {
                if ([name hasSuffix:@".sqlite"] && [name.lowercaseString containsString:@"travel"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeTilesMap:
            {
                if ([name hasSuffix:@".sqlitedb"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeRoutingConfig:
            {
                if ([name hasSuffix:@".xml"] && ![name hasSuffix:@".render.xml"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeRenderingStyle:
            {
                if ([name hasSuffix:@".render.xml"])
                    return subtype;
                break;
            }
            case EOASettingsItemFileSubtypeRoadMap:
            {
                if ([name containsString:@"road"])
                    return subtype;
                break;
            }
            default:
            {
                NSString *subtypeFolder = [self.class getSubtypeFolder:subtype];
                if ([name hasPrefix:subtypeFolder])
                    return subtype;
                break;
            }
        }
    }
    return EOASettingsItemFileSubtypeUnknown;
}

+ (BOOL) isMap:(EOASettingsItemFileSubtype)type
{
    return type == EOASettingsItemFileSubtypeObfMap || type == EOASettingsItemFileSubtypeWikiMap || type == EOASettingsItemFileSubtypeSrtmMap || type == EOASettingsItemFileSubtypeTilesMap || type == EOASettingsItemFileSubtypeRoadMap;
}

@end

@interface OAFileSettingsItem()

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *docPath;
@property (nonatomic) NSString *libPath;

@end

@implementation OAFileSettingsItem
{
    NSString *_name;
}

@dynamic name;

- (void) commonInit
{
    _docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
}

- (instancetype) initWithFilePath:(NSString *)filePath error:(NSError * _Nullable *)error
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        self.name = [filePath lastPathComponent];
        if (error)
        {
            *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeUnknownFilePath userInfo:nil];
            return nil;
        }
            
        _filePath = filePath;
        _subtype = [OAFileSettingsItemFileSubtype getSubtypeByFileName:filePath];
        if (self.subtype == EOASettingsItemFileSubtypeUnknown)
        {
            if (error)
                *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeUnknownFileSubtype userInfo:nil];
            return nil;
        }
    }
    return self;
}

- (instancetype _Nullable) initWithJson:(NSDictionary *)json error:(NSError * _Nullable *)error
{
    NSError *initError;
    self = [super initWithJson:json error:&initError];
    if (initError)
    {
        if (error)
            *error = initError;
        return nil;
    }
    if (self)
    {
        [self commonInit];
        if (self.subtype == EOASettingsItemFileSubtypeOther)
        {
            _filePath = [_docPath stringByAppendingString:self.name];
        }
        else if (self.subtype == EOASettingsItemFileSubtypeUnknown || !self.subtype)
        {
            if (error)
                *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeUnknownFileSubtype userInfo:nil];
            return nil;
        }
        else if (self.subtype == EOASettingsItemFileSubtypeGpx)
        {
            NSString *path = json[@"file"];
            NSArray *pathComponents = [path pathComponents];
            if (pathComponents.count > 2)
            {
                NSArray *filePathComponents = [pathComponents subarrayWithRange:NSMakeRange(2, pathComponents.count - 2)];
                NSString *subfolderPath = [NSString pathWithComponents:filePathComponents];
                _filePath = [[OAFileSettingsItemFileSubtype getSubtypeFolder:_subtype] stringByAppendingPathComponent:subfolderPath];
            }
            else
            {
                _filePath = [[OAFileSettingsItemFileSubtype getSubtypeFolder:_subtype] stringByAppendingPathComponent:path];
            }
        }
        else
        {
            _filePath = [[OAFileSettingsItemFileSubtype getSubtypeFolder:_subtype] stringByAppendingPathComponent:self.name];
        }
    }
    return self;
}

- (void) installItem:(NSString *)destFilePath
{
    switch (_subtype)
    {
        case EOASettingsItemFileSubtypeGpx:
        {
            OAGPXDocument *doc = [[OAGPXDocument alloc] initWithGpxFile:destFilePath];
            [doc saveTo:destFilePath];
            OAGPXTrackAnalysis *analysis = [doc getAnalysis:0];
            [[OAGPXDatabase sharedDb] addGpxItem:[destFilePath lastPathComponent] path:destFilePath title:doc.metadata.name desc:doc.metadata.desc bounds:doc.bounds analysis:analysis];
            [[OAGPXDatabase sharedDb] save];
            break;
        }
        case EOASettingsItemFileSubtypeRenderingStyle:
        case EOASettingsItemFileSubtypeObfMap:
        case EOASettingsItemFileSubtypeRoadMap:
        case EOASettingsItemFileSubtypeWikiMap:
        case EOASettingsItemFileSubtypeSrtmMap:
        {
            OsmAndApp.instance.resourcesManager->rescanUnmanagedStoragePaths();
            break;
        }
        case EOASettingsItemFileSubtypeTilesMap:
        {
            NSString *path = [destFilePath stringByDeletingLastPathComponent];
            NSString *fileName = destFilePath.lastPathComponent;
            NSString *ext = fileName.pathExtension;
            fileName = [fileName stringByDeletingPathExtension].lowerCase;
            NSString *newFileName = fileName;
            BOOL isHillShade = [fileName containsString:@"hillshade"];
            BOOL isSlope = [fileName containsString:@"slope"];
            if (isHillShade)
            {
                newFileName = [fileName stringByReplacingOccurrencesOfString:@"hillshade" withString:@""];
                newFileName = [newFileName trim];
                newFileName = [newFileName stringByAppendingString:@".hillshade"];
            }
            else if (isSlope)
            {
                newFileName = [fileName stringByReplacingOccurrencesOfString:@"slope" withString:@""];
                newFileName = [newFileName trim];
                newFileName = [newFileName stringByAppendingString:@".slope"];
            }
            newFileName = [newFileName stringByAppendingPathExtension:ext];
            newFileName = [newFileName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            path = [path stringByAppendingPathComponent:newFileName];
            
            NSFileManager *fileManager = NSFileManager.defaultManager;
            [fileManager moveItemAtPath:destFilePath toPath:path error:nil];
            OsmAnd::ResourcesManager::ResourceType resType = OsmAnd::ResourcesManager::ResourceType::Unknown;
            if (isHillShade)
                resType = OsmAnd::ResourcesManager::ResourceType::HillshadeRegion;
            else if (isSlope)
                resType = OsmAnd::ResourcesManager::ResourceType::SlopeRegion;
            
            if (resType != OsmAnd::ResourcesManager::ResourceType::Unknown)
            {
                // TODO: update exisitng sqlite
                OsmAndApp.instance.resourcesManager->installFromFile(QString::fromNSString(path), resType);
            }
        }
        default:
            break;
    }
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeFile;
}

- (NSString *) fileName
{
    return self.name;
}

- (void) setName:(NSString *)name
{
    _name = name;
}

- (NSString *) name
{
    return _name;
}

- (BOOL) exists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:_filePath];
}

- (NSString *) renameFile:(NSString*)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    int number = 0;
    NSString *prefix;
    if ([filePath hasSuffix:BINARY_WIKI_MAP_INDEX_EXT])
        prefix = [filePath substringToIndex:[filePath lastIndexOf:BINARY_WIKI_MAP_INDEX_EXT]];
    else if ([filePath hasSuffix:BINARY_SRTM_MAP_INDEX_EXT])
        prefix = [filePath substringToIndex:[filePath lastIndexOf:BINARY_SRTM_MAP_INDEX_EXT]];
    else if ([filePath hasSuffix:BINARY_ROAD_MAP_INDEX_EXT])
        prefix = [filePath substringToIndex:[filePath lastIndexOf:BINARY_ROAD_MAP_INDEX_EXT]];
    else
        prefix = [filePath substringToIndex:[filePath lastIndexOf:@"."]];
    
    NSString *suffix = [filePath stringByReplacingOccurrencesOfString:prefix withString:@""];

    while (true)
    {
        number++;
        NSString *newFilePath = [NSString stringWithFormat:@"%@_%d%@", prefix, number, suffix];
        if (![fileManager fileExistsAtPath:newFilePath])
            return newFilePath;
    }
}

- (NSString *) getIconName
{
    switch (_subtype)
    {
        case EOASettingsItemFileSubtypeWikiMap:
            return @"ic_custom_wikipedia";
        case EOASettingsItemFileSubtypeSrtmMap:
            return @"ic_custom_contour_lines";
        default:
            return @"ic_custom_show_on_map";
    }
}

- (NSString *) getPluginPath
{
    if (self.pluginId.length > 0)
        return [[_libPath stringByAppendingPathComponent:@"Plugins"] stringByAppendingPathComponent:self.pluginId];
    
    return @"";
}

- (void) readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSError *readError;
    [super readFromJson:json error:&readError];
    if (readError)
    {
        if (error)
            *error = readError;
        return;
    }
    NSString *fileName = json[@"file"];
    if (!_subtype)
    {
        NSString *subtypeStr = json[@"subtype"];
        if (subtypeStr.length > 0)
            _subtype = [OAFileSettingsItemFileSubtype getSubtypeByName:subtypeStr];
        else if (fileName.length > 0)
            _subtype = [OAFileSettingsItemFileSubtype getSubtypeByFileName:fileName];
        else
            _subtype = EOASettingsItemFileSubtypeUnknown;
    }
    if (fileName.length > 0)
    {
        if (self.subtype == EOASettingsItemFileSubtypeOther)
            self.name = fileName;
        else if (self.subtype != EOASettingsItemFileSubtypeUnknown)
            self.name = [fileName lastPathComponent];
    }
}

- (void) writeToJson:(id)json
{
    [super writeToJson:json];
    if (self.subtype != EOASettingsItemFileSubtypeUnknown)
        json[@"subtype"] = [OAFileSettingsItemFileSubtype getSubtypeName:self.subtype];
}

- (OASettingsItemReader *) getReader
{
    return [[OAFileSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *) getWriter
{
    return [[OAFileSettingsItemWriter alloc] initWithItem:self];
}

@end

#pragma mark - OAFileSettingsItemReader

@implementation OAFileSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSString *destFilePath = self.item.filePath;
    if (![self.item exists] || [self.item shouldReplace])
        destFilePath = self.item.filePath;
    else
        destFilePath = [self.item renameFile:destFilePath];
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *directory = [destFilePath stringByDeletingLastPathComponent];
    if (![fileManager fileExistsAtPath:directory])
        [fileManager createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:nil];

    NSError *copyError;
    BOOL res = [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:destFilePath error:&copyError];
    if (error && copyError)
        *error = copyError;
    
    [self.item installItem:destFilePath];
    
    return res;
}

@end

#pragma mark - OAFileSettingsItemWriter

@implementation OAFileSettingsItemWriter

- (BOOL) writeToFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSError *copyError;
    [[NSFileManager defaultManager] copyItemAtPath:self.item.fileName toPath:filePath error:&copyError];
    if (error && copyError)
    {
        *error = copyError;
        return NO;
    }
    return YES;
}

@end
