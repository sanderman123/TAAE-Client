//
//  ViewController.m
//  taaeTest2
//
//  Created by Sander on 12/30/14.
//  Copyright (c) 2014 Sander. All rights reserved.
//

#import "ViewController.h"
#import "AudioBufferManager.h"
#include <arpa/inet.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    NSString *type = @"TestingProtocol";
    BonjourServer = [[Server alloc] initWithProtocol:type];
    BonjourServer.delegate = self;
    NSError *error = nil;
    if(![BonjourServer start:&error]) {
        NSLog(@"error = %@", error);
    }
    else
    {
        NSLog(@"success");
    }
    
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    initialized = false;
    [self setupSocket];
}

-(void)sliderAction:(UISlider*)sender
{
//    if ([sender isEqual:[sliders objectAtIndex:i]]) {
        //set the volume
    
//    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void){
        //Background Thread
        float vol = sender.value;
        long sTag = sender.tag;
        NSLog(@"Slider: %li, value: %f",sTag, vol);
        [self.audioController setVolume:vol forChannelGroup:self.channels[sTag]];
//        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
            
//        });
//    });

        //    }
//    for(int i = 0; i < numChannels; i++){
//        //Find the slider number equal to the sender
//        
//    }
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touches began");
}
-(void)initializeAll{
    //    numChannels = 8;
    
    dataSize = 512;
    ablSize = sizeof(AudioBufferList);
    
    ablNSArray = [[NSMutableArray alloc]init];
    
    for (int i = 0; i< numChannels; i++) {
        AudioBufferManager *ablManager = [[AudioBufferManager alloc]init];
        ablManager.buffer =AEAllocateAndInitAudioBufferList([AEAudioController nonInterleavedFloatStereoAudioDescription], dataSize);
        
        //AudioBufferList *tmp = AEAllocateAndInitAudioBufferList([AEAudioController nonInterleavedFloatStereoAudioDescription], dataSize);//(AudioBufferList *) malloc(ablSize*2);
        [ablNSArray addObject:ablManager];
    }
    
    
    
    //Make variables public so they can be reused
    self.abl = (AudioBufferList*) malloc(sizeof(AudioBufferList));
    self.abl->mNumberBuffers = numChannels;
    //self.abl = AEAllocateAndInitAudioBufferList([AEAudioController nonInterleavedFloatStereoAudioDescription], 1024);
    self.abl1 = AEAllocateAndInitAudioBufferList([AEAudioController nonInterleavedFloatStereoAudioDescription], dataSize);
    self.abl2 = AEAllocateAndInitAudioBufferList([AEAudioController nonInterleavedFloatStereoAudioDescription], dataSize);
//    self.byteData = (Byte*) malloc(dataSize); //should maybe be a different value in the future
//    self.byteData2 = (Byte*) malloc(dataSize); //should maybe be a different value in the future
    self.byteDataArray = (Byte *) malloc(dataSize*numChannels);
//    self.ablArray = (AudioBufferList *) malloc(ablSize*numChannels*2);
    
    //    self.audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription] inputEnabled: YES];
    //    _audioController.preferredBufferDuration = 0.005;
    //
    self.audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription] inputEnabled:YES];
//            _audioController.preferredBufferDuration = 0.005;
    _audioController.preferredBufferDuration = 0.0029;
//    _audioController.preferredBufferDuration = 0.00145;
    
    
    NSError *error = [NSError alloc];
    if(![self.audioController start:&error]){
        NSLog(@"Error starting AudioController: %@", error.localizedDescription);
    }
    
    
    sliders = [[NSMutableArray alloc] init];
    
    self.players = [[NSMutableArray alloc] init];
    self.channels = (AEChannelGroupRef*)malloc(sizeof(AEChannelGroupRef)*numChannels*2);
    channelNameLabels = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < numChannels; i++){
        //Initialize channel volume slider numbers
        UILabel *sliderNumber = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 147.0+i*60.0, 10.0, 25.0)];
        sliderNumber.text = [NSString stringWithFormat:@"%i",i+1];
        [self.view addSubview:sliderNumber];
        //Initialize channel names
        UILabel *channelName = [[UILabel alloc] initWithFrame:CGRectMake(40.0, 130.0+i*60.0, 200.0, 25.0)];
        channelName.text = [channelNames objectAtIndex:i];
        [channelNameLabels addObject:channelName];
        [self.view addSubview:(UILabel*)[channelNameLabels objectAtIndex:i]];
        //Initialize channel volume sliders
        CGRect frame = CGRectMake(40.0, 150.0+i*60, 200.0, 20.0);
        UISlider *slider = [[UISlider alloc] initWithFrame:frame];
        [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
        [slider setBackgroundColor:[UIColor clearColor]];
        slider.minimumValue = 0.0;
        slider.maximumValue = 1.0;
        slider.continuous = YES;
        slider.value = 0.5;
        slider.tag = i;
        [sliders addObject:slider];
        [self.view addSubview:[sliders objectAtIndex:i]];
        
        //Add channels and players
        [self.players addObject:[[MyAudioPlayer alloc] init]];
        self.channels[i] = [self.audioController createChannelGroup];
        //add channel i with player i to the audio controller as a new channel
        [self.audioController addChannels:[[NSArray alloc] initWithObjects:[self.players objectAtIndex:i], nil] toChannelGroup:self.channels[i]];
        float vol = slider.value;
        //Initialize channel volumes
        [self.audioController setVolume:vol forChannelGroup:self.channels[i]];
    }
    initialized = true;
}

static void inputCallback(__unsafe_unretained ViewController *THIS,
                          __unsafe_unretained AEAudioController *audioController,
                          void                     *source,
                          const AudioTimeStamp     *time,
                          UInt32                    frames,
                          AudioBufferList          *audio) {
    
//    @autoreleasepool {
//        // Code that creates autoreleased objects.
//    
//    
//        //Test encode and decode with NSData
//        NSData *data = [THIS encodeAudioBufferList:audio];
//        AudioBufferList *decodedAbl = [THIS decodeAudioBufferList:data];
//    
//        //Make 2 stereo channels out of 2 mono channels
//        AudioBuffer ab1 = decodedAbl->mBuffers[0];//audio->mBuffers[0];
//        AudioBuffer ab2 = decodedAbl->mBuffers[1];//audio->mBuffers[1];
//    
//        THIS.abl1->mNumberBuffers = 2;
//        THIS.abl1->mBuffers[0] = ab1;
//        THIS.abl1->mBuffers[1] = ab1;
//        THIS.abl2->mNumberBuffers = 2;
//        THIS.abl2->mBuffers[0] = ab2;
//        THIS.abl2->mBuffers[1] = ab2;
//    
//        [THIS->player1 addToBufferAudioBufferList:THIS.abl1 frames:frames timestamp:time];
//        [THIS->player2 addToBufferAudioBufferList:THIS.abl2 frames:frames timestamp:time];
//    }
}

-(AEAudioControllerAudioCallback)receiverCallback{
    return (AEAudioControllerAudioCallback)inputCallback;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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


-(void)decodeAudioBufferListMultiChannel:(NSData *)data {
    //We should do the initialization part at a different place:

    NSUInteger dataLen = [data length];
    if(dataLen > 0){
        //Empty the byteDataArray
//        self.byteDataArray = [self.byteDataArray initWithCapacity:numChannels];
        //Take the start position of the first subrange
        NSUInteger startPos = 0;
        //Calculate the length of the subranges
        NSUInteger rangeLen = dataLen / numChannels;
        NSLog(@"%lu,%d ->rangelen :  %lu %lu",(unsigned long)dataLen,numChannels,(unsigned long)rangeLen, sizeof(_ablArray));
        //Create a uint32 version of the rangelength
        UInt32 rLen = (UInt32) rangeLen;
        
        
        
        
        for(int i = 0; i < numChannels; i++){
            NSRange range = NSMakeRange(startPos, rangeLen);
            NSData *subdata = [data subdataWithRange:range];
            
            //Get the i'th audio buffer list and fill it with data
            
//            self.abl->mBuffers[i].mDataByteSize = rLen;
//            self.abl->mBuffers[i].mNumberChannels = 1;
            memcpy(&self.byteDataArray[dataSize*i], [subdata bytes], rLen);
//            self.abl->mBuffers[i].mData = &self.byteDataArray[dataSize*i];
            
            AudioBufferManager *ablManager =[ablNSArray objectAtIndex:i];
            
//            self.ablArray[ablSize*i].mNumberBuffers = 2;
//            self.ablArray[ablSize*i].mBuffers[0].mDataByteSize = rLen;
//            self.ablArray[ablSize*i].mBuffers[0].mNumberChannels = 1;
//            self.ablArray[ablSize*i].mBuffers[0].mData = &self.byteDataArray[dataSize*i];
////            self.ablArray[16*i].mBuffers[1].mDataByteSize = rLen;
////            self.ablArray[16*i].mBuffers[1].mNumberChannels = 1;
////            self.ablArray[16*i].mBuffers[1].mData = &self.byteDataArray[dataSize*i];
//            self.ablArray[ablSize*i].mBuffers[1] = self.ablArray[ablSize*i].mBuffers[0];
            ablManager.buffer->mNumberBuffers = 2;
            ablManager.buffer->mBuffers[0].mDataByteSize = rLen;
            ablManager.buffer->mBuffers[0].mNumberChannels = 1;
            ablManager.buffer->mBuffers[0].mData = &self.byteDataArray[dataSize*i];
            //            self.ablArray[16*i].mBuffers[1].mDataByteSize = rLen;
            //            self.ablArray[16*i].mBuffers[1].mNumberChannels = 1;
            //            self.ablArray[16*i].mBuffers[1].mData = &self.byteDataArray[dataSize*i];
            ablManager.buffer->mBuffers[1] = ablManager.buffer->mBuffers[0];

            [[self.players objectAtIndex:i] addToBufferWithoutTimeStampAudioBufferList:ablManager.buffer];
            
            startPos += rangeLen;
        }
        //return self.abl;
//        return self.ablArray;
    }
//    return nil;
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address
    withFilterContext:(id)filterContext{
    //For now see the data as text
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg)
    {
        NSLog(@"RECV: %@", msg);
        NSArray *array = [msg componentsSeparatedByString:@":"];
        if(!initialized){
            numChannels = (int)array.count;
            channelNames = [[NSMutableArray alloc]init];
            [channelNames addObjectsFromArray:array];
        
            [self initializeAll];
        } else {
            [self updateChannelNames:array];
        }
    } else {
        [self decodeAudioBufferListMultiChannel:data];
        NSString *host = nil;
        uint16_t port = 0;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
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

-(void)updateChannelNames:(NSArray *)names{
    for (int i = 0; i < numChannels; i++) {
        [channelNames replaceObjectAtIndex:i withObject:[names objectAtIndex:i]];
        ((UILabel*)[channelNameLabels objectAtIndex:i]).text = [names objectAtIndex:i];
        [(UILabel*)[channelNameLabels objectAtIndex:i] setNeedsDisplay];
    }
    [self.view reloadInputViews];
}

#pragma mark Server Delegate Methods

- (void)serverRemoteConnectionComplete:(Server *)server {
    NSLog(@"Server Started");
    // this is called when the remote side finishes joining with the socket as
    // notification that the other side has made its connection with this side
//    serverRunningVC.server = server;
//    [self.navigationController pushViewController:serverRunningVC animated:YES];
}

- (void)serverStopped:(Server *)server {
    NSLog(@"Server stopped");
//    [self.navigationController popViewControllerAnimated:YES];
}

- (void)server:(Server *)server didNotStart:(NSDictionary *)errorDict {
    NSLog(@"Server did not start %@", errorDict);
}

- (void)server:(Server *)server didAcceptData:(NSData *)data {
    NSLog(@"Server did accept data %@", data);
//    NSString *message = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
//    if(nil != message || [message length] > 0) {
//        serverRunningVC.message = message;
//    } else {
//        serverRunningVC.message = @"no data received";
//    }
}

- (void)server:(Server *)server lostConnection:(NSDictionary *)errorDict {
    NSLog(@"Server lost connection %@", errorDict);
//    [self.navigationController popViewControllerAnimated:YES];
}

- (void)serviceAdded:(NSNetService *)service moreComing:(BOOL)more {

    NSLog(@"Added a service: %@, %li", [service name], [service port]);
    
    NetReslover = service;
    NetReslover.delegate = self;
    [NetReslover resolveWithTimeout:0.0];
    
    //direct connect to the server
//    [BonjourServer connectToRemoteService:service];

}

- (void)serviceRemoved:(NSNetService *)service moreComing:(BOOL)more {
//    [serverBrowserVC removeService:service moreComing:more];
    NSLog(@"Removed a service: %@", [service name]);
}

#pragma mark NSNetServiceDelegate methods

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    NSLog(@"test");
    [NetReslover stop];
    NetReslover = nil;
    
}

- (void)netServiceDidResolveAddress:(NSNetService *)service {
    
    char addressBuffer[INET6_ADDRSTRLEN];
    
    for (NSData *data in service.addresses)
    {
        memset(addressBuffer, 0, INET6_ADDRSTRLEN);
        
        typedef union {
            struct sockaddr sa;
            struct sockaddr_in ipv4;
            struct sockaddr_in6 ipv6;
        } ip_socket_address;
        
        ip_socket_address *socketAddress = (ip_socket_address *)[data bytes];
        
        if (socketAddress && (socketAddress->sa.sa_family == AF_INET || socketAddress->sa.sa_family == AF_INET6))
        {
            const char *addressStr = inet_ntop(
                                               socketAddress->sa.sa_family,
                                               (socketAddress->sa.sa_family == AF_INET ? (void *)&(socketAddress->ipv4.sin_addr) : (void *)&(socketAddress->ipv6.sin6_addr)),
                                               addressBuffer,
                                               sizeof(addressBuffer));
            
            int port = ntohs(socketAddress->sa.sa_family == AF_INET ? socketAddress->ipv4.sin_port : socketAddress->ipv6.sin6_port);
            
            if (addressStr && port)
            {
                NSLog(@"Found service at %s:%d", addressStr, port);
            }
        }
    }
    
    assert(service == NetReslover);
    
    [NetReslover stop];
    NetReslover = nil;
    
//    [self _remoteServiceResolved:service];
}



@end
