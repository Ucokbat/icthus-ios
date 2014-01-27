//
//  BookCollectionViewCell.h
//  Bible
//
//  Created by Matthew Lorentz on 1/13/14.
//  Copyright (c) 2014 Matthew Lorentz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Book.h"

@interface BookCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UILabel *label;
@property Book *book;
@property UICollectionView *collectionView;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
