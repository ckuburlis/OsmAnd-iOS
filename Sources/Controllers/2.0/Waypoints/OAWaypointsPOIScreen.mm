//
//  OAWaypointsPOIScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAWaypointsPOIScreen.h"
#import "OAWaypointsViewController.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAWaypointHelper.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OAUtilities.h"
#import "OALocationPointWrapper.h"

#import "OALocationPointWrapper.h"
#import "OASettingsImageCell.h"

@implementation OAWaypointsPOIScreen
{
    OsmAndAppInstance _app;
    OAWaypointHelper *_waypointHelper;
    OAPOIFiltersHelper *_poiFilters;
    
    NSMutableArray* _data;
    BOOL _multiSelect;
}

@synthesize waypointsScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OAWaypointsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _waypointHelper = [OAWaypointHelper sharedInstance];
        _poiFilters = [OAPOIFiltersHelper sharedInstance];
        
        if (param)
            _multiSelect = [param boolValue];
        else
            _multiSelect = NO;

        _multiSelect = YES;

        title = OALocalizedString(@"poi");
        waypointsScreen = EWaypointsScreenPOI;
        
        vwController = viewController;
        tblView = tableView;
        if (_multiSelect)
            tblView.allowsMultipleSelectionDuringEditing = YES;
        
        //tblView.separatorInset = UIEdgeInsetsMake(0, 44, 0, 0);
        
        [self initData];
    }
    return self;
}

- (void) setupView
{
    [vwController.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    if (_multiSelect)
    {
        [vwController.okButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
        vwController.okButton.hidden = NO;
    }
    
    if (_multiSelect && !tblView.editing)
        [tblView setEditing:YES animated:NO];
    
    NSMutableArray *arr = [NSMutableArray array];
    NSMutableArray<NSIndexPath *> *selectedPaths = [NSMutableArray array];
    int i = 0;
    if (!_multiSelect)
    {
        [arr addObject: [@{
                           @"name" : OALocalizedString(@"shared_string_search"),
                           @"value" : [_poiFilters getCustomPOIFilter],
                           @"selectable" : @NO,
                           @"selected" : @NO,
                           @"img" : @"search_icon" } mutableCopy]];
        i++;
    }

    for (OAPOIUIFilter *f in [_poiFilters getTopDefinedPoiFilters])
    {
        BOOL selected = [_poiFilters isPoiFilterSelected:f];
        if (selected)
            [selectedPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            
        [arr addObject: [@{
                          @"name" : [f getName],
                          @"selectable" : @YES,
                          @"selected" : @(selected),
                          @"value" : f } mutableCopy]];
        i++;
    }
    
    for (OAPOIUIFilter *f in [_poiFilters getSearchPoiFilters])
    {
        BOOL selected = [_poiFilters isPoiFilterSelected:f];
        if (selected)
            [selectedPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        
        [arr addObject: [@{
                          @"name" : [f getName],
                          @"selectable" : @YES,
                          @"selected" : @(selected),
                          @"value" : f } mutableCopy]];
        i++;
    }
    
    _data = arr;
    
    if (_multiSelect && selectedPaths.count > 0)
    {
        [tblView reloadData];
        [tblView beginUpdates];
        
        for (NSIndexPath *p in selectedPaths)
            [tblView selectRowAtIndexPath:p animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        [tblView endUpdates];
    }
}

- (void) initData
{
}

- (BOOL) okButtonPressed
{
    NSArray<NSIndexPath *> *selected = [tblView indexPathsForSelectedRows];
    int i = 0;
    for (NSDictionary *item in _data)
    {
        OAPOIUIFilter *filter = item[@"value"];
        NSIndexPath *p = [NSIndexPath indexPathForRow:i++ inSection:0];
        if (selected && [selected containsObject:p])
            [_poiFilters addSelectedPoiFilter:filter];
        else
            [_poiFilters removeSelectedPoiFilter:filter];
    }
    
    if ([_poiFilters isShowingAnyPoi])
        [OAWaypointsViewController setRequest:EWaypointsViewControllerEnableTypeAction type:LPW_POI param:@YES];
    else
        [OAWaypointsViewController setRequest:EWaypointsViewControllerEnableTypeAction type:LPW_POI param:@NO];
    
    return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const identifierCell = @"OASettingsImageCell";
    OASettingsImageCell* cell = nil;
    
    NSDictionary *item = _data[indexPath.row];
    OAPOIUIFilter *f = item[@"value"];
    NSString *name = item[@"name"];
    NSString *imgName = item[@"img"];

    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsImageCell" owner:self options:nil];
        cell = (OASettingsImageCell *)[nib objectAtIndex:0];
        [cell setSecondaryImage:nil];
    }
    
    if (cell)
    {
        [cell.textView setText:name];
        if (imgName)
        {
            [cell.imgView setImage:[UIImage imageNamed:imgName]];
        }
        else
        {
            NSString *imgName = [f getIconId];
            UIImage *img = [OAUtilities getMxIcon:imgName];
            if (!img)
                img = [OAUtilities getMxIcon:@"user_defined"];
            
            [cell.imgView setImage:img];
        }
    }
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    return [OASettingsImageCell getHeight:item[@"name"] hasSecondaryImg:NO cellWidth:tableView.bounds.size.width - (_multiSelect ? 38.0 : 0.0)];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *item = _data[indexPath.row];
    if (!tableView.editing)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
