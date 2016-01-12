//
//  StackView.m
//  Tetris360
//
//  Created by Liang Shi on 4/24/13.
//  Copyright (c) 2013 Liang Shi. All rights reserved.
//

#import "StackView.h"
#import "GameController.h"

@implementation StackView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();

    for (NSInteger i = 0; i < kNUMBER_OF_ROW; i++) {
        for (NSInteger j = 0; j < kNUMBER_OF_COLUMN_PER_SCREEN; j++) {

            PieceType type = [[GameController alloc] getTypeAtRow:i
                                                        column:[[GameController shareManager] columnForScreenColumn:j]];
            CGRect rectangle = CGRectMake(j * kGridSize([UIScreen mainScreen].bounds.size.width), i * kGridSize([UIScreen mainScreen].bounds.size.width), kGridSize([UIScreen mainScreen].bounds.size.width), kGridSize([UIScreen mainScreen].bounds.size.width));
            
            if (type != PieceTypeNone) {
                UIColor *color = [PieceView getColorOfType:type];
                CGContextSetAlpha(context, 1);
                CGContextSetFillColorWithColor(context, color.CGColor);
                CGContextFillRect(context, rectangle);
            }

            CGContextSetAlpha(context, 0.1);
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextStrokeRect(context, rectangle);
            
            if (i == kNUMBER_OF_ROW - 1) {
                NSString *columnNumber = [NSString stringWithFormat:@"%@", @([[GameController shareManager] columnForScreenColumn:j])];
                [columnNumber drawInRect:rectangle
                          withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}];
                
            }
        }
    }
    
}


@end
