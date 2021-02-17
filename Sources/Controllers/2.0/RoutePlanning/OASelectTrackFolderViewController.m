//
//  OASelectTrackFolderViewController.m
//  OsmAnd
//
//  Created by nnngrach on 05.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASelectTrackFolderViewController.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASettingsTableViewCell.h"
#import "OATitleRightIconCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OAAddTrackFolderViewController.h"
#import "OsmAndApp.h"
#import "OALoadGpxTask.h"

#define kCellTypeAction @"OATitleRightIconCell"
#define kMultiIconTextDescCell @"OAMultiIconTextDescCell"
#define kAddNewFolderSection 0
#define kFoldersListSection 1

@interface OASelectTrackFolderViewController() <UITableViewDelegate, UITableViewDataSource, OAAddTrackFolderDelegate>

@end

@implementation OASelectTrackFolderViewController
{
    id<OASelectTrackFolderDelegate> _delegate;
    OAGPX *_gpx;
    NSArray<NSArray<NSDictionary *> *> *_data;
}

- (instancetype) initWithGPX:(OAGPX *)gpx delegate:(id<OASelectTrackFolderDelegate>)delegate;
{
    self = [super initWithNibName:@"OABaseTableViewController" bundle:nil];
    if (self)
    {
        _gpx = gpx;
        _delegate = delegate;
        [self reloadData];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"plan_route_select_folder");
}

- (void) generateData:(NSMutableArray<NSString *> *)allFolderNames foldersData:(NSMutableDictionary *)foldersData
{
    NSString *selectedFolderName = [_gpx.gpxFilePath stringByDeletingLastPathComponent];
    if ([selectedFolderName isEqualToString:@""])
        selectedFolderName = OALocalizedString(@"tracks");
    
    NSMutableArray *data = [NSMutableArray new];
    [data addObject:@[
        @{
            @"type" : kCellTypeAction,
            @"title" : @"Add new folder",
            @"img" : @"ic_custom_add",
        },
    ]];
    
    NSMutableArray *cellFoldersData = [NSMutableArray new];
    for (NSString *folderName in allFolderNames)
    {
        NSArray *folderItems = foldersData[folderName];
        int tracksCount = folderItems ? folderItems.count : 0;
        [cellFoldersData addObject:@{
            @"type" : kMultiIconTextDescCell,
            @"header" : OALocalizedString(@"plan_route_folder"),
            @"title" : folderName,
            @"description" : [NSString stringWithFormat:@"%i", tracksCount],
            @"isSelected" : [NSNumber numberWithBool:[folderName isEqualToString: selectedFolderName]],
            @"img" : @"ic_custom_folder"
        }];
    }
    
    [data addObject: [NSArray arrayWithArray:cellFoldersData]];
    _data = data;
}

- (void) reloadData
{
    NSMutableArray<NSString *> *allFoldersNames = [NSMutableArray new];
    [allFoldersNames addObject:OALocalizedString(@"tracks")];
    NSArray* filesList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:OsmAndApp.instance.gpxPath error:nil];
    for (NSString *name in filesList)
    {
        if (![name hasPrefix:@"."] && ![name.lowerCase hasSuffix:@".gpx"])
            [allFoldersNames addObject:name];
    }
        
    OALoadGpxTask *task = [[OALoadGpxTask alloc] init];
    [task execute:^(NSDictionary<NSString *, NSArray<OAGpxInfo *> *>* gpxFolders) {
        [self generateData:allFoldersNames foldersData:gpxFolders];
        [self.tableView reloadData];
    }];
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:kCellTypeAction])
    {
        static NSString* const identifierCell = kCellTypeAction;
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeAction owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        return cell;
    }
   
    else if ([cellType isEqualToString:kMultiIconTextDescCell])
    {
        OAMultiIconTextDescCell* cell = (OAMultiIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:kMultiIconTextDescCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kMultiIconTextDescCell owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textView.numberOfLines = 3;
            cell.textView.lineBreakMode = NSLineBreakByTruncatingTail;
        }
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
            [cell.descView setText:item[@"description"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
            cell.separatorInset = UIEdgeInsetsMake(0, cell.textView.frame.origin.x, 0, 0);
            
            if ([item[@"isSelected"] boolValue])
            {
                [cell setOverflowVisibility:NO];
                [cell.overflowButton setImage:[[UIImage imageNamed:@"ic_checmark_default"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            }
            else
            {
                [cell setOverflowVisibility:YES];
            }
            
            [cell updateConstraintsIfNeeded];
        }
        return cell;
    }
    
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *item = ((NSArray *)_data[section]).firstObject;
    return item[@"header"];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kAddNewFolderSection)
    {
        OAAddTrackFolderViewController * addFolderVC = [[OAAddTrackFolderViewController alloc] init];
        addFolderVC.delegate = self;
        [self presentViewController:addFolderVC animated:YES completion:nil];
        
    }
    else if (indexPath.section == kFoldersListSection)
    {
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        [self moveTrackToFolder:item[@"title"]];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        NSString *cellType = item[@"type"];
        if ([cellType isEqualToString:kMultiIconTextDescCell])
            return 60;
        else
            return UITableViewAutomaticDimension;
}

- (void) moveTrackToFolder:(NSString *)selectedFolderName
{
    NSString *oldPath = _gpx.gpxFilePath;
    NSString *oldName = _gpx.gpxFileName;
    NSString *sourcePath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:oldPath];
    
    NSString *newFolder = [selectedFolderName isEqualToString:OALocalizedString(@"tracks")] ? @"" : selectedFolderName;
    NSString *newFolderPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:newFolder];
    NSString *newName = [self getUniqueFileName:oldName inFolderPath:newFolderPath];
    NSString *destinationPath = [newFolderPath stringByAppendingPathComponent:newName];
    
    [OAGPXDatabase.sharedDb updateGPXFolderName:[newFolder stringByAppendingPathComponent:newName] oldFilePath:oldPath];
    [OAGPXDatabase.sharedDb save];
    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:sourcePath error:nil];
    [_delegate updateSelectedFolder:_gpx oldFilePath:oldPath newFilePath:[newFolder stringByAppendingPathComponent:newName]];
}

- (NSString *) getUniqueFileName:(NSString *)fileName inFolderPath:(NSString *)folderPath
{
    NSString *name = [fileName stringByDeletingPathExtension];
    NSString *newName = name;
    int i = 2;
    while ([[NSFileManager defaultManager] fileExistsAtPath:[[folderPath stringByAppendingPathComponent:newName] stringByAppendingPathExtension:@"gpx"]])
    {
        newName = [NSString stringWithFormat:@"%@ %i", name, i];
        i++;
    }
    return [newName stringByAppendingPathExtension:@"gpx"];
}

#pragma mark - OAAddTrackFolderDelegate

- (void) onTrackFolderAdded:(NSString *)folderName
{
    NSString *newFolderPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:folderName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:newFolderPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:newFolderPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    [self reloadData];
}

@end