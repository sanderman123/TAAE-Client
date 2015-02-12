//
//  ChannelGroupRefModel.h
//  taaeTest2
//
//  Created by Sander Valstar on 2/12/15.
//  Copyright (c) 2015 Sander. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "TheAmazingAudioEngine.h"
#import "TPCircularBuffer.h"
#import "TPCircularBuffer+AudioBufferList.h"
#import "ChannelPlayer.h"

@interface MonitorChannel: NSObject
{
    
}

@property (nonatomic, assign) TPCircularBuffer cbuffer;
@property (nonatomic, assign) AEAudioController *audioController;
@property (nonatomic, assign) AEChannelGroupRef channelGroup;
@property (nonatomic, strong) ChannelPlayer *channelPlayer;
@property (nonatomic, strong) AEAudioUnitFilter *reverb;

-(MonitorChannel*)initWithAudioController:(AEAudioController*)audioController;
-(ChannelPlayer*)getChannelPlayer;
-(void)addReverb;
-(void)setReverbValue:(float)reverbValue;
-(void)setVolume:(float)volume;
-(void)setPan:(float)pan;
-(void)setMuted:(BOOL)muted;
@end
