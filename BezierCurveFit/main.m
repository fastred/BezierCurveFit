//
//  main.m
//  BezierCurveFit
//
//  Created by Arkadiusz on 08-07-14.
//  Copyright (c) 2014 Arkadiusz Holko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSBezierPath+FitCurve.h"

// Reads points from the file with two double numbers in each line separated by spaces. The first number corresponds to `x` coordinate, second to `y` coordinate.
NSArray * pointsFromFileAtURL(NSURL *fileURL) {
    NSError *error;

    NSString *fileContents = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    if (!fileContents) {
        NSLog(@"Error: %@", error);
    }

    NSArray *lines = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    NSMutableArray *points = [NSMutableArray array];

    [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL *stop) {
        NSScanner *scanner = [NSScanner scannerWithString:line];

        double x, y;
        BOOL xScanned = [scanner scanDouble:&x];
        BOOL yScanned = [scanner scanDouble:&y];

        if (xScanned && yScanned) {
            [points addObject:[NSValue valueWithPoint:NSMakePoint(x, y)]];
        } else {
            if (!xScanned) {
                NSLog(@"Error during scanning `x` on line %td.", idx);
            }
            if (!yScanned) {
                NSLog(@"Error during scanning `y` on line %td.", idx);
            }

            *stop = YES;
        }
    }];

    return [points copy];
}

/// Constructs a path consisting of straight lines between data points.
NSBezierPath * pathWithStraightLinesFromPoints(NSArray *points)
{
    NSBezierPath *path = [NSBezierPath bezierPath];

    [points enumerateObjectsUsingBlock:^(NSValue *value, NSUInteger idx, BOOL *stop) {
        NSPoint point = [value pointValue];

        if (idx == 0) {
            [path moveToPoint:point];
        } else {
            [path lineToPoint:point];
        }
    }];

    return path;
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"points" withExtension:@"txt"];
        NSArray *points = pointsFromFileAtURL(url);
        NSBezierPath *path = pathWithStraightLinesFromPoints(points);

        // Finds a cubic Bezier curve with the smallest error.
        // You may need to adjust the errorTreshold starting point and step if you're trying to fit a curve with a bounding box different than [(0,0) (100, 100)].
        for (float errorTreshold = 0; true; errorTreshold += 0.1) {

            @autoreleasepool {
                NSBezierPath *newPath = [path fb_fitCurve:errorTreshold];
                if ([newPath elementCount] == 2) {
                    for (int i = 0; i < [newPath elementCount]; i++) {

                        NSPoint pointArray[3];
                        NSBezierPathElement element = [newPath elementAtIndex:i associatedPoints:pointArray];

                        if (element == NSMoveToBezierPathElement) {
                            NSLog(@"Move to Point: %@", NSStringFromPoint(pointArray[0]));
                        } else if (element == NSLineToBezierPathElement) {
                            NSLog(@"Line to Point: %@", NSStringFromPoint(pointArray[0]));
                        } else if (element == NSCurveToBezierPathElement) {
                            NSLog(@"Curve;\nControl Point 1: %@,\nControl Point 2: %@,\nEnd Point: %@", NSStringFromPoint(pointArray[0]), NSStringFromPoint(pointArray[1]), NSStringFromPoint(pointArray[2]));
                        }
                    }
                    break;
                }
            }
        }
    }
    return 0;
}

