//
//  OAPublicTransportOptionsBottomSheet.m
//  OsmAnd
//
//  Created by nnngrach on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAPublicTransportOptionsBottomSheet.h"
#import "OABottomSheetHeaderIconCell.h"
#import "OASettingSwitchCell.h"
#import "OAMapStyleSettings.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAColors.h"

#define kButtonsDividerTag 150

@interface OAPublicTransportOptionsBottomSheetScreen ()

@end

@implementation OAPublicTransportOptionsBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAAppSettings* _settings;
    OAMapStyleSettings* _styleSettings;
    OAPublicTransportOptionsBottomSheetViewController *vwController;
    NSArray* _data;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAPublicTransportOptionsBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAPublicTransportOptionsBottomSheetViewController *)viewController
{
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _styleSettings = [OAMapStyleSettings sharedInstance];
    
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void) setupView
{
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableArray *arr = [NSMutableArray array];
    
    [arr addObject:@{
        @"type" : @"OABottomSheetHeaderIconCell",
        @"title" : OALocalizedString(@"public_transport_menu"),
        @"description" : @""
        }];
    
    
    NSArray* params = [_styleSettings getParameters:@"transport"];
    
    for (OAMapStyleParameter *param in params)
    {
        if (!param)
            continue;
        
        NSString* imageName = @"";
        if ([param.name isEqualToString:@"tramTrainRoutes"])
            imageName = @"ic_custom_transport_tram";
        else if ([param.name isEqualToString:@"subwayMode"])
            imageName = @"ic_custom_transport_subway";
        else if ([param.name isEqualToString:@"transportStops"])
            imageName = @"ic_custom_transport_stop";
        else if ([param.name isEqualToString:@"publicTransportMode"])
            imageName = @"ic_custom_transport_stop";
        
        [arr addObject:@{
            @"type" : @"OASettingSwitchCell",
            @"name" : param.name,
            @"title" : param.title,
            @"img" : imageName,
            }];
    }
 
    _data = [NSArray arrayWithArray:arr];
}

-(void) doneButtonPressed
{
    [vwController dismiss];
}

- (BOOL) cancelButtonPressed
{
    [_settings.transportLayersVisible resetToDefault];
    return YES;
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderIconCell"])
    {
        return [OABottomSheetHeaderIconCell getHeight:item[@"title"] cellWidth:DeviceScreenWidth];
    }
    else if ([item[@"type"] isEqualToString:@"OASettingSwitchCell"])
    {
        return [OASettingSwitchCell getHeight:[item objectForKey:@"title"]
                                         desc:[item objectForKey:@"description"]
                              hasSecondaryImg:NO
                                    cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 44.0;
    }
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
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderIconCell"])
    {
        static NSString* const identifierCell = @"OABottomSheetHeaderIconCell";
        OABottomSheetHeaderIconCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OABottomSheetHeaderIconCell" owner:self options:nil];
            cell = (OABottomSheetHeaderIconCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            cell.iconView.hidden = !cell.iconView.image;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OASettingSwitchCell"])
    {
        static NSString* const identifierCell = @"OASettingSwitchCell";
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingSwitchCell" owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [self updateSettingSwitchCell:cell data:item];
            
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = [_settings.transportLayersVisible contain:item[@"name"]];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(onSwitchClick:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (void) updateSettingSwitchCell:(OASettingSwitchCell *)cell data:(NSDictionary *)data
{
    UIImage *img = nil;
    NSString *imgName = data[@"img"];
    NSString *secondaryImgName = data[@"secondaryImg"];
    if (imgName)
        img = [OAUtilities tintImageWithColor:[UIImage imageNamed:imgName] color:UIColorFromRGB(color_primary_purple)];
    
    cell.textView.text = data[@"title"];
    NSString *desc = data[@"description"];
    cell.descriptionView.text = desc;
    cell.descriptionView.hidden = desc.length == 0;
    cell.imgView.image = img;
    [cell setSecondaryImage:secondaryImgName.length > 0 ? [UIImage imageNamed:data[@"secondaryImg"]] : nil];
    if ([cell needsUpdateConstraints])
        [cell setNeedsUpdateConstraints];
}

- (void) onSwitchClick:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    int position = (int)sw.tag;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:position inSection:0];
    NSDictionary * item = [self getItem:indexPath];
    
    if (sw.on)
        [_settings.transportLayersVisible addUnic:item[@"name"]];
    else
        [_settings.transportLayersVisible remove:item[@"name"]];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}


#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 32.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if (![item[@"type"] isEqualToString:@"OASwitchCell"])
        return indexPath;
    else
        return nil;
}

@synthesize vwController;

@end




@interface OAPublicTransportOptionsBottomSheetViewController ()

@end

@implementation OAPublicTransportOptionsBottomSheetViewController

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAPublicTransportOptionsBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:nil];
    
    [super setupView];
}
- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"edit_action") forState:UIControlStateNormal];
}

@end

