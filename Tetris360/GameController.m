//
//  GameController.m
//  Tetris360
//
//  Created by Liang Shi on 4/22/13.
//  Copyright (c) 2013 Liang Shi. All rights reserved.
//

#import "GameController.h"
#import "ViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import <CoreLocation/CoreLocation.h>

NSInteger const kNUMBER_OF_ROW = 16;
NSInteger const kNUMBER_OF_COLUMN = 30;
NSInteger const kNUMBER_OF_COLUMN_PER_SCREEN = 10;
NSInteger const kDEGREES_PER_COLUMN = 12;
NSInteger const kPUZZLE_COUNT = 3;

static PieceType pieceStack[kNUMBER_OF_ROW][kNUMBER_OF_COLUMN];

float nfmod(float a,float b)
{
    return a - b * floor(a / b);
}

@interface GameController () <CLLocationManagerDelegate, AVAudioPlayerDelegate>

@property CLLocationManager *locationManager;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSTimer *gameTimer;

@property (nonatomic, assign) float lastHeading;
@property (nonatomic, assign) float zeroColumnHeading;
@property (nonatomic, assign) NSInteger columnOffset;
@property (nonatomic, assign) BOOL isCurrentPieceMoving;

@end

@implementation GameController

//game manager singleton
+ (id)shareManager{
    static GameController *sharedGameManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedGameManager = [[self alloc] init];
    });
    return sharedGameManager;
}

- (id)init {
    if (self = [super init]) { 
        [self initCompass];
        [self initAudioPlayer];
        _gameSpeed = 1.0f;
        _gridWidth = [UIScreen mainScreen].bounds.size.width/kNUMBER_OF_COLUMN_PER_SCREEN;
        
    }
    return self;
}

- (void)initCompass
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.headingFilter = 1;
    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];
}

- (void)initAudioPlayer
{
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"TetrisTheme" ofType:@"mp3"];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
    self.audioPlayer.delegate = self;
    self.audioPlayer.numberOfLoops = -1; //infinite
}

- (void)initGameTimer
{
    self.gameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/self.gameSpeed
                                                      target:self
                                                    selector:@selector(movePieceDown)
                                                    userInfo:nil
                                                     repeats:YES];
}

#pragma mark - game play
- (void)startGame{
    // Read random puzzle
    NSInteger randomInteger = arc4random_uniform(kPUZZLE_COUNT)+1;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"puzzle%@", @(randomInteger)] ofType:@"txt"];
    NSString *fileString = [NSString stringWithContentsOfFile:filePath encoding:NSASCIIStringEncoding error:nil];
    NSArray *lines = [fileString componentsSeparatedByString:@"\n"];
    
    //initialize bitmap for current stack, number in each grid stands for different type of piece; 0 means the grid is empty
    for (NSInteger row_index = 0; row_index < kNUMBER_OF_ROW; row_index++) {
        NSString *row = [lines objectAtIndex:row_index];
        for (NSInteger column_index = 0; column_index < kNUMBER_OF_COLUMN; column_index++) {
            NSString *typeString = [row substringWithRange:NSMakeRange(column_index, 1)];
            NSInteger type = [typeString intValue];
            pieceStack[row_index][column_index] = type;
        }
    }
    
    //init game status
    self.gameStatus = GameRunning;
    self.gameLevel = 1; //the higher the level, the faster the dropping speed
    self.gameScore = 0;

    //start the loop of game control and add piece into map when it reaches the bottom line in bitmap
    self.zeroColumnHeading = self.lastHeading;
    [self.delegate updateStack];
    [self initGameTimer];
    
    //start background music
    [self.audioPlayer play];
}


- (void)pauseGame{
    //freeze piece and pause timer
    self.gameStatus = GamePaused;
    //once invalidated, the timer can't bereused
    [self.gameTimer invalidate];
    self.gameTimer = nil;
    [self.audioPlayer pause];
}


- (void)resumeGame{
    //freeze piece and pause timer
    self.gameStatus = GameRunning;
    [self initGameTimer];
    [self.audioPlayer play];
}


- (BOOL)checkClearLine{
    NSInteger numberOfClearLine = 0;
    // check from top to bottom
    for (NSInteger row_index = 0; row_index < kNUMBER_OF_ROW; row_index++) {
        // check for one line
        BOOL thislineClear = YES;
        for (NSInteger column_index = 0; column_index < kNUMBER_OF_COLUMN; column_index++) {
            if (pieceStack[row_index][column_index] == PieceTypeNone) {
                thislineClear = NO;
                break;
            }
        }
        if (thislineClear) {
            numberOfClearLine++;

            // move all the pieces above down one row
            for (NSInteger i = row_index; i > 0; i--) {
                for (NSInteger column_index = 0; column_index < kNUMBER_OF_COLUMN; column_index++) {
                    pieceStack[i][column_index] = pieceStack[i - 1][column_index];
                }
            }
        }
    }

    if (numberOfClearLine > 0) {
        // add score
        self.gameScore += 5 * pow(3, numberOfClearLine);
        [self.delegate updateScore:self.gameScore];
    }
    
    // level up
    if (self.gameScore >= self.gameLevel * 40) {
        self.gameLevel++;
        [self.gameTimer invalidate];
        self.gameTimer = nil;
        self.gameSpeed *= 1.5;
        [self.delegate updateLevel:self.gameLevel];
        [self initGameTimer];
    }

    return numberOfClearLine > 0;
}


- (void)gameOver{
    self.gameStatus = GameStopped;
    [self.gameTimer invalidate];
    self.gameTimer = nil;
    self.gameScore = 0;
    self.gameLevel = 1;
    [self.delegate updateLevel:self.gameLevel];
    [self.delegate updateScore:self.gameScore];
    if([self.delegate respondsToSelector:@selector(removeCurrentPiece)]) {
        [self.delegate removeCurrentPiece];
    }
    
    [self.delegate gameOver];

    //initialize bitmap for current stack, number in each grid stands for different type of piece; 0 means the grid is empty
    for (NSInteger row_index = 0; row_index < kNUMBER_OF_ROW; row_index++) {
        for (NSInteger column_index = 0; column_index < kNUMBER_OF_COLUMN; column_index++) {
            pieceStack[row_index][column_index] = 0;
        }
    }

    [self.audioPlayer stop];
    [self.audioPlayer setCurrentTime:0];
    [self.delegate updateStack];
}

#pragma mark - control of pieces

- (PieceView *)generatePiece{
    self.isCurrentPieceMoving = YES;
    //generate a random tetris piece
    NSInteger randomNumber = arc4random() % 7 +1; //7 types of pieces
    self.currentPieceView = [[PieceView alloc] initWithPieceType:randomNumber pieceCenter:CGPointMake((self.columnOffset + 4)%kNUMBER_OF_COLUMN, 0)];
    
    return self.currentPieceView;
}

- (BOOL)movePieceDown {
    
    if (self.gameStatus != GameRunning) {
        return NO;
    }
    CGPoint newViewCenter = CGPointMake(self.currentPieceView.center.x, self.currentPieceView.center.y + self.gridWidth);
    CGPoint newLogicalCenter = CGPointMake(self.currentPieceView.pieceCenter.x, self.currentPieceView.pieceCenter.y + 1);

    NSArray *blocks = [self.currentPieceView blocksCenter];
    BOOL hittingAPiece = NO;
    BOOL hittingTheFloor = NO;
    for (NSValue *block in blocks) {
        CGPoint blockPoint = [block CGPointValue];
        if (pieceStack[(NSInteger)(newLogicalCenter.y+blockPoint.y)][(NSInteger)(newLogicalCenter.x+blockPoint.x)%kNUMBER_OF_COLUMN] != PieceTypeNone) {
            hittingAPiece = YES;
        }
        if ((newLogicalCenter.y + blockPoint.y) > kNUMBER_OF_ROW - 1) {
            hittingTheFloor = YES;
        }
    }

    if (self.isCurrentPieceMoving) {
        if (hittingAPiece || hittingTheFloor) {
            //stop moving pieces
            self.isCurrentPieceMoving = NO;
            self.currentPieceView.pieceRotated = PieceRotateStoped;
            
            //record this piece to bitmap and remove the subview of this piece
            [self recordBitmapWithCurrentPiece];
            if([self.delegate respondsToSelector:@selector(removeCurrentPiece)])
                [self.delegate removeCurrentPiece];

            //check whether we can clear a line
            [self checkClearLine];
            
            //check whether it's game over
            if (self.currentPieceView.frame.origin.y == 0) {
                [self gameOver];
            }
            else{
                //drop a new piece
                if([self.delegate respondsToSelector:@selector(dropNewPiece)])
                    [self.delegate dropNewPiece];
            }
        }
        else{
            self.currentPieceView.center = newViewCenter;
            self.currentPieceView.pieceCenter = newLogicalCenter;
        }
    }
    
    [self.delegate updateStack];
    
    return hittingAPiece || hittingTheFloor;
}

- (void)dropPiece
{
    if (self.gameStatus != GameRunning) {
        return;
    }
    
    while (![self movePieceDown] && self.isCurrentPieceMoving) {
        continue;
    }
}

- (BOOL)lateralCollisionForLocation:(CGPoint)location
{
    NSArray *blocks = [self.currentPieceView blocksCenter];
    BOOL hittingAPiece = NO;
    for (NSValue *block in blocks) {
        CGPoint blockPoint = [block CGPointValue];
        if (pieceStack[(NSInteger)(location.y+blockPoint.y)][(NSInteger)(location.x+blockPoint.x)] != PieceTypeNone) {
            hittingAPiece = YES;
        }
    }
    return hittingAPiece;
}

- (BOOL)screenBorderCollisionForLocation:(CGPoint)location
{
    NSArray *blocks = [self.currentPieceView blocksCenter];
    BOOL hittingEdgeOfScreen = NO;
    for (NSValue *block in blocks) {
        CGPoint blockPoint = [block CGPointValue];
        if (
            (location.x + blockPoint.x*self.gridWidth) <= (self.gridWidth/2) ||
            (location.x + blockPoint.x*self.gridWidth) > ((kNUMBER_OF_COLUMN_PER_SCREEN+0.5) * self.gridWidth)) {
            hittingEdgeOfScreen = YES;
        }
    }
    return hittingEdgeOfScreen;
}

- (void)movePieceLeft{
    if (self.gameStatus != GameRunning) {
        return;
    }
    
    CGPoint newViewCenter = CGPointMake(self.currentPieceView.center.x - self.gridWidth, self.currentPieceView.center.y);
    CGPoint newLogicalCenter = CGPointMake(nfmod(self.currentPieceView.pieceCenter.x-1, kNUMBER_OF_COLUMN), self.currentPieceView.pieceCenter.y);
    
    if (![self screenBorderCollisionForLocation:newViewCenter] && ![self lateralCollisionForLocation:newLogicalCenter] && self.isCurrentPieceMoving) {
        self.currentPieceView.center = newViewCenter;
        self.currentPieceView.pieceCenter = newLogicalCenter;
    }
}

- (void)movePieceRight{
    if (self.gameStatus != GameRunning) {
        return;
    }
    
    CGPoint newViewCenter = CGPointMake(self.currentPieceView.center.x + self.gridWidth, self.currentPieceView.center.y);
    CGPoint newLogicalCenter = CGPointMake(self.currentPieceView.pieceCenter.x + 1, self.currentPieceView.pieceCenter.y);
    
    if (![self screenBorderCollisionForLocation:newViewCenter] && ![self lateralCollisionForLocation:newLogicalCenter] && self.isCurrentPieceMoving) {
        self.currentPieceView.center = newViewCenter;
        self.currentPieceView.pieceCenter = newLogicalCenter;
    }
}


- (void)moveScreenLeft{
    CGPoint newLogicalCenter = CGPointMake(nfmod(self.currentPieceView.pieceCenter.x-1, kNUMBER_OF_COLUMN), self.currentPieceView.pieceCenter.y);

    if (![self lateralCollisionForLocation:newLogicalCenter] && self.isCurrentPieceMoving) {
        self.currentPieceView.pieceCenter = newLogicalCenter;
        self.columnOffset = nfmod((self.columnOffset+ kNUMBER_OF_COLUMN-1)%kNUMBER_OF_COLUMN, kNUMBER_OF_COLUMN);
    }
    
    [self.delegate updateStack];
}


- (void)moveScreenRight{
    CGPoint newLogicalCenter = CGPointMake(nfmod(self.currentPieceView.pieceCenter.x+1, kNUMBER_OF_COLUMN), self.currentPieceView.pieceCenter.y);
    
    if (![self lateralCollisionForLocation:newLogicalCenter] && self.isCurrentPieceMoving) {
        self.currentPieceView.pieceCenter = newLogicalCenter;
        self.columnOffset = nfmod((self.columnOffset+1)%kNUMBER_OF_COLUMN, kNUMBER_OF_COLUMN);
    }
    
    [self.delegate updateStack];
}

- (void)moveToColumn:(NSInteger)column
{
    if (column == self.columnOffset) {
        return;
    }
    
    if (column == 0) {
        // Recalibrate when passing through 0
        self.zeroColumnHeading = self.lastHeading;
    }
    
    if (column >= 0 & column < kNUMBER_OF_COLUMN) {
        NSInteger columnsToMoveLeft;
        NSInteger columnsToMoveRight;
        
        if (column < self.columnOffset) {
            columnsToMoveLeft = labs(self.columnOffset - column);
            columnsToMoveRight = kNUMBER_OF_COLUMN - columnsToMoveLeft;
        }
        else {
            columnsToMoveRight = labs(self.columnOffset - column);
            columnsToMoveLeft = kNUMBER_OF_COLUMN - columnsToMoveRight;
        }
        
        NSInteger columnsToMove = MIN(columnsToMoveLeft, columnsToMoveRight);
        
        if (columnsToMove == columnsToMoveLeft) {
            for (NSInteger i = columnsToMove; i > 0; i--) {
                [self moveScreenLeft];
            }
        }
        else if (columnsToMove == columnsToMoveRight) {
            for (NSInteger i = labs(columnsToMove); i > 0; i--) {
                [self moveScreenRight];
            }
        }
    }
}


- (void)recordBitmapWithCurrentPiece{
    NSArray *blocks = [self.currentPieceView blocksCenter];
    for (NSValue *block in blocks) {
        CGPoint blockPoint = [block CGPointValue];
        NSInteger column = (NSInteger)(self.currentPieceView.pieceCenter.x + blockPoint.x) % kNUMBER_OF_COLUMN;
        NSInteger row = (NSInteger)(self.currentPieceView.pieceCenter.y + blockPoint.y);
        [self updateViewAtColumn:column andRow:row withType:self.currentPieceView.pieceType];
    }

    [self.delegate updateStack];
}

- (PieceType)getTypeAtRow:(NSInteger)row column:(NSInteger)column{
    return pieceStack[row][column];
}

- (NSInteger)columnForScreenColumn:(NSInteger)column
{
    NSInteger realColumn = (self.columnOffset + column) % kNUMBER_OF_COLUMN;
    return realColumn;
}

- (void)updateViewAtColumn:(NSInteger)column andRow: (NSInteger)row withType:(PieceType)type{
    pieceStack[row][column] = type;
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if (self.gameStatus == GameRunning) {
        float relativeHeading = newHeading.trueHeading - self.zeroColumnHeading;
        NSInteger column = nfmod((NSInteger)(relativeHeading / kDEGREES_PER_COLUMN), kNUMBER_OF_COLUMN);
        [self moveToColumn:column];
    }
    
    self.lastHeading = newHeading.trueHeading;
}

@end
