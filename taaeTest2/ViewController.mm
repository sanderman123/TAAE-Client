//
//  ViewController.m
//  taaeTest2
//
//  Created by Sander on 12/30/14.
//  Copyright (c) 2014 Sander. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupSocket];
    
    numChannels = 8;
    dataSize = 512;
    
    //Make variables public so they can be reused
    self.abl = (AudioBufferList*) malloc(sizeof(AudioBufferList));
    self.abl->mNumberBuffers = numChannels;
    //self.abl = AEAllocateAndInitAudioBufferList([AEAudioController nonInterleavedFloatStereoAudioDescription], 1024);
    self.abl1 = AEAllocateAndInitAudioBufferList([AEAudioController nonInterleavedFloatStereoAudioDescription], dataSize);
    self.abl2 = AEAllocateAndInitAudioBufferList([AEAudioController nonInterleavedFloatStereoAudioDescription], dataSize);
    self.byteData = (Byte*) malloc(dataSize); //should maybe be a different value in the future
    self.byteData2 = (Byte*) malloc(dataSize); //should maybe be a different value in the future
    self.byteDataArray = (Byte *) malloc(dataSize*numChannels);
    self.ablArray = (AudioBufferList *) malloc(sizeof(AudioBufferList)*numChannels);
    
    //Rotate slider
    UIView *superView = self.slider1.superview;
    [self.slider1 removeFromSuperview];
    [self.slider1 removeConstraints:self.view.constraints];
    self.slider1.translatesAutoresizingMaskIntoConstraints = YES;
    self.slider1.transform = CGAffineTransformMakeRotation(-M_PI_2);
    [superView addSubview:self.slider1];
    [self.slider2 removeFromSuperview];
    [self.slider2 removeConstraints:self.view.constraints];
    self.slider2.translatesAutoresizingMaskIntoConstraints = YES;
    self.slider2.transform = CGAffineTransformMakeRotation(-M_PI_2);
    [superView addSubview:self.slider2];

//    self.audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription] inputEnabled: YES];
//    _audioController.preferredBufferDuration = 0.005;
//
    self.audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription] inputEnabled:YES];
//        _audioController.preferredBufferDuration = 0.005;
    _audioController.preferredBufferDuration = 0.0029;
    
    
    NSError *error = [NSError alloc];
    if(![self.audioController start:&error]){
        NSLog(@"Error starting AudioController: %@", error.localizedDescription);
    }
    
    
    self.players = [[NSMutableArray alloc] initWithCapacity:numChannels];
    self.channels = (AEChannelGroupRef*)malloc(sizeof(AEChannelGroupRef)*numChannels);
    
    for(int i = 0; i < numChannels; i++){
        [self.players addObject:[[MyAudioPlayer alloc] init]];
//        [self.channels addObject:(id)[self.audioController createChannelGroup]];
        self.channels[i] = [self.audioController createChannelGroup];
        //add channel i with player i to the audio controller as a new channel
        [self.audioController addChannels:[[NSArray alloc] initWithObjects:[self.players objectAtIndex:i], nil] toChannelGroup:self.channels[i]];
        
//        [self.ablArray addObject:(__bridge id)AEAllocateAndInitAudioBufferList([AEAudioController nonInterleavedFloatStereoAudioDescription], 512)];
    }
    
    
    //Initialize volumes
    volumes = (float *)malloc(sizeof(float) * 2);
    volumes[0] = self.slider1.value;
    volumes[1] = self.slider2.value;

    [self.audioController setVolume:volumes[0] forChannelGroup:self.channels[0]];
    [self.audioController setVolume:volumes[1] forChannelGroup:self.channels[1]];

    
/*    //Initialize audio output channels and audio input
    player1 = [[MyAudioPlayer alloc] init];
    player2 = [[MyAudioPlayer alloc] init];

    channel1 = [self.audioController createChannelGroup];
    channel2 = [self.audioController createChannelGroup];
    
    //[self.audioController addInputReceiver:self];
    [self.audioController addChannels:[[NSArray alloc] initWithObjects:player1, nil] toChannelGroup:channel1];
    [self.audioController addChannels:[[NSArray alloc] initWithObjects:player2, nil] toChannelGroup:channel2];
    
    
    [self.audioController setVolume:volumes[0] forChannelGroup:channel1];
    [self.audioController setVolume:volumes[1] forChannelGroup:channel2];
    
*/
    AudioStreamBasicDescription asbd = [self.audioController inputAudioDescription];
//    [self.audioController set
    
}

static void inputCallback(__unsafe_unretained ViewController *THIS,
                          __unsafe_unretained AEAudioController *audioController,
                          void                     *source,
                          const AudioTimeStamp     *time,
                          UInt32                    frames,
                          AudioBufferList          *audio) {
    
    @autoreleasepool {
        // Code that creates autoreleased objects.
    
    
        //Test encode and decode with NSData
        NSData *data = [THIS encodeAudioBufferList:audio];
        AudioBufferList *decodedAbl = [THIS decodeAudioBufferList:data];
    
        //Make 2 stereo channels out of 2 mono channels
        AudioBuffer ab1 = decodedAbl->mBuffers[0];//audio->mBuffers[0];
        AudioBuffer ab2 = decodedAbl->mBuffers[1];//audio->mBuffers[1];
    
        THIS.abl1->mNumberBuffers = 2;
        THIS.abl1->mBuffers[0] = ab1;
        THIS.abl1->mBuffers[1] = ab1;
        THIS.abl2->mNumberBuffers = 2;
        THIS.abl2->mBuffers[0] = ab2;
        THIS.abl2->mBuffers[1] = ab2;
    
        [THIS->player1 addToBufferAudioBufferList:THIS.abl1 frames:frames timestamp:time];
        [THIS->player2 addToBufferAudioBufferList:THIS.abl2 frames:frames timestamp:time];
    }
}

-(AEAudioControllerAudioCallback)receiverCallback{
    return (AEAudioControllerAudioCallback)inputCallback;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)slider1ValueChanged:(id)sender {
    volumes[0] = self.slider1.value;
    [self.audioController setVolume:volumes[0] forChannelGroup:self.channels[0]];
}
- (IBAction)slider2ValueChanged:(id)sender {
    volumes[1] = self.slider2.value;
    [self.audioController setVolume:volumes[1] forChannelGroup:self.channels[1]];
}


- (IBAction)btnSendClicked:(id)sender {
    NSString *host = _tfIPAddress.text;
    if ([host length] == 0)
    {
        NSLog(@"Error, address required");
        return;
    }
    
    int port = [_tfPort.text intValue];
    if (port <= 0 || port > 65535)
    {
        NSLog(@"Error, valid port required");
        return;
    }
    
    NSString *msg = _tfMessage.text;
    if ([msg length] == 0)
    {
        NSLog(@"Error message required");
        return;
    }
    
    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:tag];
    
    NSLog(@"SENT (%i): %@", (int)tag, msg);
    
    tag++;
}

- (NSData *)encodeAudioBufferList:(AudioBufferList *)abl {
    //NSMutableData *data = [NSMutableData data];
    if(self.mutableData == nil){
        self.mutableData = [NSMutableData data];
    } else {
        [self.mutableData setLength:0];
    }
    
    for (int y = 0; y < abl->mNumberBuffers; y++){
        AudioBuffer ab = abl->mBuffers[y];
        Float32 *frame = (Float32*)ab.mData;
        [self.mutableData appendBytes:frame length:ab.mDataByteSize];
    }
    
    return self.mutableData;
}

- (AudioBufferList *)decodeAudioBufferList:(NSData *)data {
    
    if (data.length > 0) {
        int nc = 2; // This value should be changed once there are more than 2 channels
        
        //AudioBufferList *abl = (AudioBufferList*) malloc(sizeof(AudioBufferList));
        self.abl->mNumberBuffers = nc;
        
        NSUInteger len = [data length];
        
        //Take the range of the first buffer
        NSUInteger olen = 0;
        // NSUInteger lenx = len / nc;
        NSUInteger step = len / nc;
        int i = 0;
        
        while (olen < len) {
            
            //NSData *d = [NSData alloc];
            NSData *pd = [data subdataWithRange:NSMakeRange(olen, step)];
            NSUInteger l = [pd length];
            NSLog(@"l: %lu",(unsigned long)l);
//            Byte *byteData = (Byte*) malloc(l);
            if(i == 0){
                memcpy(self.byteData, [pd bytes], l);
                if(self.byteData){
                    
                    //I think the zero should be 'i', but for some reason that doesn't work...
                    self.abl->mBuffers[i].mDataByteSize = (UInt32)l;
                    self.abl->mBuffers[i].mNumberChannels = 1;
                    self.abl->mBuffers[i].mData = self.byteData;
                    //                memcpy(&self.abl->mBuffers[i].mData, byteData, l);
                }
            } else {
                memcpy(self.byteData2, [pd bytes], l);
                if(self.byteData2){
                    
                    //I think the zero should be 'i', but for some reason that doesn't work...
                    self.abl->mBuffers[i].mDataByteSize = (UInt32)l;
                    self.abl->mBuffers[i].mNumberChannels = 1;
                    self.abl->mBuffers[i].mData = self.byteData2;
                    //                memcpy(&self.abl->mBuffers[i].mData, byteData, l);
                }
            }
            
            
            //Update the range to the next buffer
            olen += step;
            //lenx = lenx + step;
            i++;
//            free(byteData);
        }
        return self.abl;
    }
    return nil;
}


-(AudioBufferList *)decodeAudioBufferListMultiChannel:(NSData *)data {
    //We should do the initialization part at a different place:

    NSUInteger dataLen = [data length];
    if(dataLen > 0){
        //Empty the byteDataArray
//        self.byteDataArray = [self.byteDataArray initWithCapacity:numChannels];
        //Take the start position of the first subrange
        NSUInteger startPos = 0;
        //Calculate the length of the subranges
        NSUInteger rangeLen = dataLen / numChannels;
        //Create a uint32 version of the rangelength
        UInt32 rLen = (UInt32) rangeLen;
        for(int i = 0; i < numChannels; i++){
            NSRange range = NSMakeRange(startPos, rangeLen);
            NSData *subdata = [data subdataWithRange:range];
            /*
            //Get the i'th audio buffer list and fill it with data
            self.abl = (__bridge AudioBufferList *)[self.ablArray objectAtIndex:i];
            self.abl->mBuffers[0].mDataByteSize = rLen;
            self.abl->mBuffers[0].mNumberChannels = 1;
            [data getBytes:self.abl->mBuffers[0].mData range:range];
            self.abl->mBuffers[1].mDataByteSize = rLen;
            self.abl->mBuffers[1].mNumberChannels = 1;
            [data getBytes:self.abl->mBuffers[1].mData range:range];*/
            
            
            self.abl->mBuffers[i].mDataByteSize = rLen;
            self.abl->mBuffers[i].mNumberChannels = 1;
            memcpy(&self.byteDataArray[dataSize*i], [subdata bytes], rLen);
            self.abl->mBuffers[i].mData = &self.byteDataArray[dataSize*i];
            
//            if(i == 0) {
//                self.abl->mBuffers[0].mDataByteSize = rLen;
//                self.abl->mBuffers[0].mNumberChannels = 1;
////                [data getBytes:self.abl->mBuffers[0].mData range:range];
//                memcpy(&self.byteDataArray[0], [subdata bytes], rLen);
//                self.abl->mBuffers[0].mData = &self.byteDataArray[0];
////                memcpy(&byteData3[0], [subdata bytes], rLen);
////                self.abl->mBuffers[0].mData = &byteData3[0];
//            } else if (i == 2 ){
//                self.abl->mBuffers[1].mDataByteSize = rLen;
//                self.abl->mBuffers[1].mNumberChannels = 1;
//                memcpy(&self.byteDataArray[512], [subdata bytes], rLen);
//                self.abl->mBuffers[1].mData = &self.byteDataArray[512];
////                memcpy(&byteData3[1], [subdata bytes], rLen);
////                self.abl->mBuffers[1].mData = &byteData3[1];
////memcpy(self.abl->mBuffers[1].mData, [subdata bytes], rLen);
////                [data getBytes:self.abl->mBuffers[1].mData range:range];
//            }
            startPos += rangeLen;
        }
        return self.abl;
    }
    return nil;
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    //For now see the data as text
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg)
    {
        NSLog(@"RECV: %@", msg);
    }
    else
    {
        //We received audio data, so lets play it!
//        AudioBufferList *bufferList = [self decodeAudioBufferList:data];
        AudioBufferList *bufferList = [self decodeAudioBufferListMultiChannel:data];
        
        
//----------------Add Audio BufferList to TAAE --------------
        //Make 2 stereo channels out of 2 mono channels
        AudioBuffer ab1 = bufferList->mBuffers[0];//audio->mBuffers[0];
        AudioBuffer ab2 = bufferList->mBuffers[7];//audio->mBuffers[1];
        
        self.ablArray[0].mNumberBuffers = 2;
        self.ablArray[0].mBuffers[0] = ab1;
        self.ablArray[0].mBuffers[1] = ab1;
        self.ablArray[16].mNumberBuffers = 2;
        self.ablArray[16].mBuffers[0] = ab2;
        self.ablArray[16].mBuffers[1] = ab2;

//        self.abl1->mNumberBuffers = 2;
//        self.abl1->mBuffers[0] = ab1;
//        self.abl1->mBuffers[1] = ab1;
//        self.abl2->mNumberBuffers = 2;
//        self.abl2->mBuffers[0] = ab2;
//        self.abl2->mBuffers[1] = ab2;
        
//      Add a timestamp later
//        [self->player1 addToBufferAudioBufferList:self.abl1 frames:frames timestamp:time];
//        [self->player2 addToBufferAudioBufferList:self.abl2 frames:frames timestamp:time];
////
//        [self->player1 addToBufferWithoutTimeStampAudioBufferList:self.abl1];
//        [self->player2 addToBufferWithoutTimeStampAudioBufferList:self.abl2];
        [[self.players objectAtIndex:0] addToBufferWithoutTimeStampAudioBufferList:&self.ablArray[0]];
        [[self.players objectAtIndex:1] addToBufferWithoutTimeStampAudioBufferList:&self.ablArray[16]];
        
        
        NSString *host = nil;
        uint16_t port = 0;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
        
        NSLog(@"RECV: Unknown message from: %@:%hu", host, port);
    }
    
}

-(void)setupSocket{
    tag = 0;
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
//    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
//    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)];
    
    NSError *error = nil;
    
    if (![udpSocket bindToPort:0 error:&error])
    {
        NSLog(@"Error binding: %@", error);
        return;
    }
    if (![udpSocket beginReceiving:&error])
    {
        NSLog(@"Error receiving: %@", error);
        return;
    }
    
    NSLog(@"Socket Ready");
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void)clickedBackground{
    [self.view endEditing:YES];
}


@end
