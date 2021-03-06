//
//  ViewController.m
//  Tetris360
//
//  Created by Liang Shi on 2013-04-21.
//  Copyright (c) 2013 Liang Shi. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "StackView.h"
#import "PieceView.h"
#import "GameController.h"

@interface ViewController () <GameControllerDelegate>

@property (nonatomic, weak) GameController *gameController;

@property (nonatomic, weak) IBOutlet UIButton *startButton;
@property (nonatomic, weak) IBOutlet UIButton *stopButton;
@property (nonatomic, weak) IBOutlet UIButton *tutorialButton;
@property (nonatomic, weak) IBOutlet UILabel *levelLabel;
@property (nonatomic, weak) IBOutlet UILabel *scoreLabel;

@property (nonatomic, weak) IBOutlet UIView *calibratingView;
@property (nonatomic, weak) IBOutlet UILabel *gameStatusLabel;
@property (nonatomic, weak) IBOutlet UIView *tutorialView;
@property (nonatomic, weak) IBOutlet UIView *cameraView;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) NSTimer *calibrationTimer;

@property (nonatomic, strong) PieceView *movingPieceView; // current dropping piece
@property (nonatomic, strong) StackView *pieceStackView; // 60*15 grid view for pieces already dropped

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.gameController = [GameController shareManager];
    [self.gameController setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self setupCameraView];
    [self setupStackView];
    self.calibrationTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self
                                                           selector:@selector(calibrationFinished)
                                                           userInfo:nil
                                                            repeats:NO];
    [self.tutorialView setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    [self.view addSubview:self.tutorialView];
}


- (void)setupCameraView
{
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]){
        self.captureSession = [[AVCaptureSession alloc] init];
        [self.captureSession setSessionPreset:AVCaptureSessionPresetPhoto];

        AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        [self.captureSession addInput:input];
        [self.captureSession setSessionPreset:@"AVCaptureSessionPresetPhoto"];
        [self.captureSession startRunning];

        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.previewLayer.frame = self.view.frame;

        [self.cameraView.layer addSublayer:self.previewLayer];
    }
}


- (void)setupStackView
{
    CGFloat gridWidth = [self.gameController gridWidth];
    self.pieceStackView  = [[StackView alloc] initWithFrame:CGRectMake(0,
                                                                       (CGRectGetHeight(self.view.frame) -
                                                                       gridWidth * kNUMBER_OF_ROW),
                                                                       gridWidth * kNUMBER_OF_COLUMN,
                                                                       gridWidth * kNUMBER_OF_ROW)];
    [self.view addSubview:self.pieceStackView];
    [self.stopButton setHidden:YES];
}

- (IBAction)startGameClicked:(id)sender{
    [self.tutorialView setHidden:YES];
    if ([self.gameController gameStatus] == GameRunning) { //pause game
        [self.gameController pauseGame];
        [self.movingPieceView setHidden:YES];
        [self.startButton setImage:[UIImage imageNamed:@"gtk_media_play_ltr.png"]
                          forState:UIControlStateNormal];
    }
    else if([self.gameController gameStatus] == GameStopped) { //start game
        [self.gameController startGame];
        [self.movingPieceView setHidden:NO];
        [self.startButton setImage:[UIImage imageNamed:@"gtk_media_pause.png"]
                          forState:UIControlStateNormal];
        self.movingPieceView = [self.gameController generatePiece];
        [self.view addSubview:self.movingPieceView];
    }
    else if([self.gameController gameStatus] == GamePaused) { //resume game
        [self.startButton setImage:[UIImage imageNamed:@"gtk_media_pause.png"]
                          forState:UIControlStateNormal];
        [self.gameController resumeGame];
        [self.movingPieceView setHidden:NO];
    }
    [self.stopButton setHidden:NO];
    
}

- (IBAction)stopGame:(id)sender{
    [self.stopButton setHidden:YES];
    [self.startButton setImage:[UIImage imageNamed:@"gtk_media_play_ltr.png"] forState:UIControlStateNormal];

    [self removeCurrentPiece];
    
    [self.gameController gameOver];
}


- (IBAction)showTutorial:(id)sender{
    if (self.tutorialView.isHidden) {
        if ([self.gameController gameStatus] == GameRunning) {
            [self.gameController pauseGame];
            [self.movingPieceView setHidden:YES];
        }
        [self.tutorialView setHidden:NO];
    }
    else{
        [self.tutorialView setHidden:YES];
    }
}

- (void)updateStack{
    if ([self.gameController gameStatus] == GameStopped) {
        self.movingPieceView = nil;
    }
    [self.pieceStackView setNeedsDisplay];
}

- (void)dropNewPiece{
    self.movingPieceView = [self.gameController generatePiece];
    [self.view addSubview:self.movingPieceView];
}


- (void)removeCurrentPiece{
    [self.movingPieceView removeFromSuperview];
    self.movingPieceView = nil;
}

- (IBAction)leftClicked:(id)sender{
    [self.gameController movePieceLeft];
}


- (IBAction)rightClicked:(id)sender{
    [self.gameController movePieceRight];
}

- (IBAction)respondToScreenTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:self.view];
    if (location.x < (self.view.frame.size.width/2)) {
        [self leftClicked:nil];
    }
    else {
        [self rightClicked:nil];
    }
    
}

- (IBAction)respondToSwipe:(UITapGestureRecognizer *)recognizer
{
    if ([self.gameController gameStatus]) {
        [self.gameController dropPiece];
    }
}

- (void)calibrationFinished
{
    [self.calibratingView removeFromSuperview];
}

- (void)updateScore:(NSInteger)newScore{
    self.scoreLabel.text = [NSString stringWithFormat:@"%@", @(newScore)];
}

- (void)updateLevel:(NSInteger)newLevel{
    self.levelLabel.text = [NSString stringWithFormat:@"%@", @(newLevel)];
    self.gameStatusLabel.text = @"Level Up!!";
    [self showGameStatus];
}


- (void)gameOver
{
    [self.startButton setImage:[UIImage imageNamed:@"gtk_media_play_ltr.png"] forState:UIControlStateNormal];
    [self.stopButton setHidden:YES];
    self.gameStatusLabel.text = @"Game Over!";
}

- (void)showGameStatus
{
    self.gameStatusLabel.alpha = 0.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.gameStatusLabel.hidden = NO;
        self.gameStatusLabel.alpha = 1.0;
    } completion:^(BOOL finished){
        self.gameStatusLabel.alpha = 0.0;
        self.gameStatusLabel.hidden = YES;
    }];
}

@end
