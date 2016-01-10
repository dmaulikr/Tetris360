//
//  ViewController.h
//  Tetris360
//
//  Created by Liang Shi on 2013-04-21.
//  Copyright (c) 2013 Liang Shi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PieceView.h"
#import "GameController.h"

@interface ViewController : UIViewController <GameControllerDelegate>

- (IBAction)startGameClicked:(id)sender;
- (IBAction)leftClicked:(id)sender;
- (IBAction)rightClicked:(id)sender;
- (IBAction)stopGame:(id)sender;
- (IBAction)showTutorial:(id)sender;

@end
