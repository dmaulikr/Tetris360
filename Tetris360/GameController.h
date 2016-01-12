//
//  GameController.h
//  Tetris360
//
//  Created by Liang Shi on 4/22/13.
//  Copyright (c) 2013 Liang Shi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PieceView.h"

extern NSInteger const kNUMBER_OF_ROW;
extern NSInteger const kNUMBER_OF_COLUMN;
extern NSInteger const kNUMBER_OF_COLUMN_PER_SCREEN;
extern NSInteger const kDEGREES_PER_COLUMN;

typedef NS_ENUM(NSInteger, GameStatus){
    GameStopped,
    GameRunning,
    GamePaused
};

@class GameController;

@protocol GameControllerDelegate <NSObject>
@required
- (void)dropNewPiece;
- (void)removeCurrentPiece;
- (void)updateStack;
- (void)calibrationFinished;

- (void)updateScore:(NSInteger)newScore;
- (void)updateLevel:(NSInteger)newLevel;
- (void)gameOver;
@end

@interface GameController : NSObject

+ (id)shareManager;

// define delegate property
@property (nonatomic, assign) id<GameControllerDelegate> delegate;


@property (nonatomic, strong) PieceView *currentPieceView;
@property (nonatomic, assign) CGFloat gridWidth;

//game status
@property (nonatomic, assign) GameStatus gameStatus;
@property (nonatomic, assign) NSInteger gameLevel;
@property (nonatomic, assign) NSInteger gameScore;
@property (nonatomic, assign) float gameSpeed;

//game control
- (void)startGame;
- (void)pauseGame;
- (void)resumeGame;
- (void)gameOver;

//piece control
- (PieceView *)generatePiece;
- (void)dropPiece;
- (void)movePieceLeft;
- (void)movePieceRight;
- (void)moveScreenLeft;
- (void)moveScreenRight;
- (PieceType)getTypeAtRow:(NSInteger)row column:(NSInteger)column;
- (NSInteger)columnForScreenColumn:(NSInteger)column;

@end
