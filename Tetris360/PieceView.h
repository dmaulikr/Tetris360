//
//  PieceView.h
//  Tetris360
//
//  Created by Liang Shi on 4/22/13.
//  Copyright (c) 2013 Liang Shi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#define kNUMBER_OF_BLOCKS 4


typedef NS_ENUM(NSInteger, PieceType){
    PieceTypeNone = 0,
    PieceTypeI, // □□□□

    PieceTypeO, // □□
                // □□
    
    PieceTypeJ, // □
                // □□□
    
    PieceTypeL, //   □
                // □□□

    PieceTypeS,  //  □□
                 // □□

    PieceTypeZ, // □□
                //  □□

    PieceTypeT //   □
              //  □□□
    
};


typedef NS_ENUM(NSInteger, PieceRotation){
    PieceOriginal = 0,
    PieceRotateOnce,
    PieceRotateTwice,
    PieceRotateThreeTimes,
    PieceRotateStoped
};

@interface PieceView : UIView

@property (nonatomic, assign) PieceType pieceType;
@property (nonatomic, assign) PieceRotation pieceRotated;
@property (nonatomic, assign) CGPoint pieceCenter; //absolute location in the game grid view, e.g (3, 5), so the coordinate or the piece center is (3*32, 5*32)
@property (nonatomic, strong) NSMutableArray *blocksCenter; //relative location of other blocks to the piece center, 3 for each block, e.g (-1, 0) means one block left

- (id)initWithPieceType:(PieceType)type pieceCenter:(CGPoint)center;
+ (UIColor*)getColorOfType: (PieceType)type;
@end
