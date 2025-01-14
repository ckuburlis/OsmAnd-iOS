//
//  OAHorizontalCollectionViewIconCell.m
//  OsmAnd
//
//  Created by nnngrach on 08.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAFolderCardsCell.h"
#import "OAFolderCardCollectionViewCell.h"
#import "OAColors.h"
#import "OAUtilities.h"
#import "Localization.h"

#define kDestCell @"OAFolderCardCollectionViewCell"

@interface OAFolderCardsCell() <UICollectionViewDelegate, UICollectionViewDataSource>

@end

@implementation OAFolderCardsCell
{
    NSMutableArray *_data;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerNib:[UINib nibWithNibName:kDestCell bundle:nil] forCellWithReuseIdentifier:kDestCell];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 16.;
    layout.sectionInset = UIEdgeInsetsMake(0, 8, 8, 8);
    [_collectionView setCollectionViewLayout:layout];
    [_collectionView setShowsHorizontalScrollIndicator:NO];
    [_collectionView setShowsVerticalScrollIndicator:NO];
    _data = [NSMutableArray new];
}

- (void) setValues:(NSArray<NSString *> *)values sizes:(NSArray<NSNumber *> *)sizes colors:(NSArray<UIColor *> *)colors addButtonTitle:(NSString *)addButtonTitle withSelectedIndex:(int)index
{
    _data = [NSMutableArray new];
    for (int i = 0; i < values.count; i++)
    {
        NSString *sizeString;
        NSNumber *size = sizes[i];
        sizeString = size ? [NSString stringWithFormat:@"%i", size.intValue] : @"";
        UIColor *color = colors[i] ? colors[i] : UIColorFromRGB(color_primary_purple);
            
        [_data addObject:@{
            @"title" : values[i],
            @"size" : sizeString,
            @"color" : color,
            @"img" : @"ic_custom_folder",
            @"isSelected" : [NSNumber numberWithBool:i == index],
            @"key" : @"home"}];
    }
    
    [_data addObject:@{
        @"title" : addButtonTitle,
        @"size" : @"",
        @"color" : UIColorFromRGB(color_primary_purple),
        @"img" : @"zoom_in_button",
        @"isSelected" : @NO,
        @"key" : @"work"}];
    
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _data.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(120,69);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kDestCell forIndexPath:indexPath];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kDestCell owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    if (cell && [cell isKindOfClass:OAFolderCardCollectionViewCell.class])
    {
        OAFolderCardCollectionViewCell *destCell = (OAFolderCardCollectionViewCell *) cell;
        destCell.titleLabel.text = item[@"title"];
        destCell.descLabel.text = item[@"size"];
        destCell.imageView.tintColor = item[@"color"];
        [destCell.imageView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        
        if ([item[@"isSelected"] boolValue])
        {
            destCell.layer.borderWidth = 2;
            destCell.layer.borderColor = UIColorFromRGB(color_primary_purple).CGColor;
        }
        else
        {
            destCell.layer.borderWidth = 1;
            destCell.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
        }
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)colView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
        [cell setBackgroundColor:UIColorFromRGB(color_tint_gray)];
    }
                     completion:nil];
}

- (void)collectionView:(UICollectionView *)colView  didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
        [cell setBackgroundColor:UIColor.whiteColor];
    }
                     completion:nil];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == _data.count - 1)
    {
        if (_delegate)
            [_delegate onAddFolderButtonPressed];
    }
    else
    {
        if (_delegate)
            [_delegate onItemSelected:indexPath.row];
    }
    
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

@end
