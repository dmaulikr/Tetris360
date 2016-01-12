//
//  PieceView.m
//  Tetris360
//
//  Created by Liang Shi on 4/22/13.
//  Copyright (c) 2013 Liang Shi. All rights reserved.
//

#import "PieceView.h"
#import "GameController.h"

#define DegreesToRadians(x) ((x) * M_PI / 180.0)

@implementation PieceView

- (id)initWithPieceType:(PieceType)type pieceCenter:(CGPoint)center {
    self.pieceType = type;
    self.pieceCenter = center;
    CGRect frame;
    CGFloat gridWidth = [[GameController shareManager] gridWidth];
    switch (type) {
        case PieceTypeI:
            frame = CGRectMake(gridWidth*4.0, 0, gridWidth * 4, gridWidth * 4);
            break;
        case PieceTypeO:
            frame = CGRectMake(gridWidth*4, 0, gridWidth * 2, gridWidth * 2);
            break;
        case PieceTypeJ:
        case PieceTypeL:
        case PieceTypeS:
        case PieceTypeT:
        case PieceTypeZ:
            frame = CGRectMake(gridWidth*4.0, 0, gridWidth * 3, gridWidth * 3);
            break;
        default:
            break;
    }

    return [self initWithFrame:frame];
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor clearColor]];
        self.pieceRotated = PieceOriginal;
        //initializing blocks
        self.blocksCenter = [[NSMutableArray alloc] initWithCapacity:kNUMBER_OF_BLOCKS];
        CGPoint point = CGPointMake(1, 1);
        [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];

        switch (self.pieceType) {
            case PieceTypeJ:
                point = CGPointMake(0, 0);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(0, 1);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(2, 1);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                break;
            case PieceTypeL:
                point = CGPointMake(0, 1);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(2, 1);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(2, 0);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                break;
            case PieceTypeS:
                point = CGPointMake(0, 1);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(1, 0);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(2, 0);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                break;
            case PieceTypeT:
                point = CGPointMake(0, 1);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(2, 1);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(1, 0);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                break;
            case PieceTypeZ:
                point = CGPointMake(0, 0);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(1, 0);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(2, 1);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                break;
            case PieceTypeI:
                point = CGPointMake(0, 1);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(2, 1);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(3, 1);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                break;
            case PieceTypeO:
                point = CGPointMake(0, 0);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(0, 1);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                point = CGPointMake(1, 0);
                [self.blocksCenter addObject:[NSValue valueWithCGPoint:point]];
                break;
            default:
                break;
        }

    }
    return self;
}


+ (UIColor*)getColorOfType: (PieceType)type{
    switch (type) {
        case PieceTypeI:
            return [UIColor redColor];
            break;
        case PieceTypeO:
            return [UIColor orangeColor];
            break;
        case PieceTypeJ:
            return [UIColor yellowColor];
            break;
        case PieceTypeL:
            return [UIColor greenColor];
            break;
        case PieceTypeS:
            return [UIColor blueColor];
            break;
        case PieceTypeT:
            return [UIColor purpleColor];
            break;
        case PieceTypeZ:
            return [UIColor cyanColor];
            break;
        default:
            return nil;
            break;
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    //draw each piece based on piece type
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] setStroke];
    [[PieceView getColorOfType:self.pieceType] setFill];
    CGFloat gridWidth = [[GameController shareManager] gridWidth];
    for (NSInteger i = 0; i < kNUMBER_OF_BLOCKS; i++) {
        //draw each block
        CGRect rectangle = CGRectMake(([[self.blocksCenter objectAtIndex:i] CGPointValue].x) * gridWidth, ([[self.blocksCenter objectAtIndex:i] CGPointValue].y) * gridWidth, gridWidth, gridWidth);
        CGContextFillRect(context, rectangle);
        CGContextStrokeRect(context, rectangle);
    }
}


#pragma mark - touch events
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;{
    if (self.pieceRotated != PieceRotateStoped) {
        if (self.pieceRotated == PieceRotateThreeTimes) {
            self.pieceRotated = PieceOriginal;
        }
        else{
            self.pieceRotated++;
        }


        //rotate the piece 90 degrees clockwise
        if (self.pieceType == PieceTypeI) {
            if (self.pieceRotated%2 == 0) {
                CGPoint newPoint = CGPointMake(0, 1);
                self.blocksCenter[1] = [NSValue valueWithCGPoint:newPoint];
                newPoint = CGPointMake(2, 1);
                self.blocksCenter[2] = [NSValue valueWithCGPoint:newPoint];
                newPoint = CGPointMake(3, 1);
                self.blocksCenter[3] = [NSValue valueWithCGPoint:newPoint];
            }
            else{
                CGPoint newPoint = CGPointMake(1, 0);
                self.blocksCenter[1] = [NSValue valueWithCGPoint:newPoint];
                newPoint = CGPointMake(1, 2);
                self.blocksCenter[2] = [NSValue valueWithCGPoint:newPoint];
                newPoint = CGPointMake(1, 3);
                self.blocksCenter[3] = [NSValue valueWithCGPoint:newPoint];
            }
        }
        else if (self.pieceType != PieceTypeO) {
            for (NSInteger i = 1; i < kNUMBER_OF_BLOCKS; i++) {
                NSInteger x = [self.blocksCenter[i] CGPointValue].x;
                NSInteger y = [self.blocksCenter[i] CGPointValue].y;

                //up down left right
                if (x == 1 && y == 0) {
                    x = 2; y = 1;
                }
                else if (x == 2 && y == 1){
                    x = 1;  y = 2;
                }
                else if(x == 1 && y == 2){
                    x = 0; y = 1;
                }
                else if(x == 0 && y == 1){
                    x = 1; y = 0;
                }
                //for corners
                if (x == 0 && y == 0) {
                    x = 2; y = 0;
                }
                else if (x == 2 && y == 0){
                    x = 2;  y = 2;
                }
                else if(x == 2 && y == 2){
                    x = 0; y = 2;
                }
                else if(x == 0 && y == 2){
                    x = 0; y = 0;
                }
                
                CGPoint newPoint = CGPointMake(x, y);
                self.blocksCenter[i] = [NSValue valueWithCGPoint:newPoint];
            }
        }
        
        
        [self setNeedsDisplay];
    }
}

@end
