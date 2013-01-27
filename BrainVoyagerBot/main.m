//
//  main.m
//  BrainVoyagerBot
//
//  Created by Deb on 12/3/12.
//  Copyright (c) 2012 Deb. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AppleScriptObjC/AppleScriptObjC.h>


int main(int argc, char *argv[])
{

    [[NSBundle mainBundle] loadAppleScriptObjectiveCScripts];
    return NSApplicationMain(argc, (const char **)argv);
    
}
