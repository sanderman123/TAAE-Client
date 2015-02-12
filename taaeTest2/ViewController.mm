//
//  ViewController.m
//  taaeTest2
//
//  Created by Sander on 12/30/14.
//  Copyright (c) 2014 Sander. All rights reserved.
//

#import "ViewController.h"
#import "AudioBufferManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    initialized = false;
    numChannels = 0;
    imageFlag = -1;
    [self setupSocket];
    [self setupTCPSocket];
}

-(void)sliderAction:(UISlider*)sender
{
        float vol = sender.value;
        long sTag = sender.tag;
        NSLog(@"Slider: %li, value: %f",sTag, vol);
        [(MonitorChannel*)[self.channels objectAtIndex:sTag] setVolume:vol];
//    [[self.channels objectAtIndex:sTag] setReverbValue:vol*100.f];
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
    channelImageViews = [[NSMutableArray alloc]init];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"music-note" ofType:@"png"];
    defaultImage = [[UIImage alloc] initWithContentsOfFile:path];
    self.channels = [[NSMutableArray alloc]init];
    channelNameLabels = [[NSMutableArray alloc] init];
    sliders = [[NSMutableArray alloc] init];
    
    self.byteDataArray = (Byte *) malloc(dataSize*numChannels);
    
    self.audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription] inputEnabled:NO];
//    _audioController.preferredBufferDuration = 0.005;
    _audioController.preferredBufferDuration = 0.0029;
//    _audioController.preferredBufferDuration = 0.00145;
    
    NSError *error = [NSError alloc];
    if(![self.audioController start:&error]){
        NSLog(@"Error starting AudioController: %@", error.localizedDescription);
    }
    
    
    for(int i = 0; i < numChannels; i++){
        //Add an AudioBufferList for every channel
        AudioBufferManager *ablManager = [[AudioBufferManager alloc]init];
        ablManager.buffer =AEAllocateAndInitAudioBufferList([AEAudioController nonInterleavedFloatStereoAudioDescription], dataSize);
        [ablNSArray addObject:ablManager];
        
        //Initialize channel images
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(250.0, 130.0+i*60, 50.0, 50.0)];
        [imageView setImage:defaultImage];
        imageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(handleTap:)];
        [imageView addGestureRecognizer:gr];
        [channelImageViews addObject:imageView];
        [self.view addSubview:[channelImageViews objectAtIndex:i]];
        
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
        
        //Add a Channel Model for every channel
        MonitorChannel* channel = [[MonitorChannel alloc]initWithAudioController:self.audioController];
        [self.channels addObject:channel];
        
        NSArray* chnls = [self.audioController channels];
        
        float vol = slider.value;
        //Initialize channel volumes
        [(MonitorChannel*)[self.channels objectAtIndex:i] setVolume:vol];
//        [self.audioController setVolume:vol forChannelGroup:[[self.channels objectAtIndex:i]getChannelGroup]];
    }
    
//    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    NSLog(@"Proximity Monitoring Enabled? %@ ",    [UIDevice currentDevice].proximityMonitoringEnabled ? @"YES" : @"NO");
    
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
    [udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:0];
//    [tcpSocket writeData:data withTimeout:-1 tag:localTag];
    
    NSLog(@"SENT (%i): %@", (int)localTag, msg);
    
    localTag++;
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
//        NSLog(@"%lu,%d ->rangelen :  %lu %lu",(unsigned long)dataLen,numChannels,(unsigned long)rangeLen, sizeof(_ablArray));
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

            [[[self.channels objectAtIndex:i] getChannelPlayer] addToBufferWithoutTimeStampAudioBufferList:ablManager.buffer];
            
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
    
//    if(imageFlag != -1){
//        //Update picture of channel with number pictureFlag
//        UIImage *image = [[UIImage alloc]initWithData: data];
//        [((UIImageView*)[channelImageViews objectAtIndex:imageFlag]) setImage:image];
//        [self.view reloadInputViews];
//        imageFlag = -1;
//    } else {
        NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (msg)
        {
            NSLog(@"RECV: %@", msg);
            
            NSArray *array = [msg componentsSeparatedByString:@":"];
//            if(!initialized){
//                numChannels = (int)array.count;
//                channelNames = [[NSMutableArray alloc]init];
//                [channelNames addObjectsFromArray:array];
//                
//                [self initializeAll];
//            } else
            if ((int)array.count == numChannels){
                [self updateChannelNames:array];
            } else if ([[array objectAtIndex:0] isEqual:@"image"]){
                //Initialize standard image already on the phone
                long index = [[array objectAtIndex:1] integerValue];
                NSString *path = [[NSBundle mainBundle] pathForResource:[array objectAtIndex:2] ofType:[array objectAtIndex:3]];
                UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
                [[channelImageViews objectAtIndex:index] setImage:image];
                [self.view reloadInputViews];
            }
            
        }
//        else {
//            [self decodeAudioBufferListMultiChannel:data];
//            NSString *host = nil;
//            uint16_t port = 0;
//            [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
//        }
//    }
    
}

-(void)setupSocket{
    localTag = 0;
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

-(void)setupTCPSocket{
    localTag = 0;
    tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    NSString *host = _tfIPAddress.text;
    uint16_t port = [_tfPort.text intValue];
    NSError *error = nil;
    if (![tcpSocket connectToHost:host onPort:port error:&error])
    {
        NSLog(@"Error connecting: %@", error);
    }
//    NSData *data = [[NSData alloc]init];
//    [tcpSocket readDataToData:data withTimeout:-1 tag:tag];
//    [tcpSocket readDataWithTimeout:-1 tag:0];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void)clickedBackground{
    [self.view endEditing:YES];
}

- (void)handleTap:(UITapGestureRecognizer *)gr {
    NSLog(@"Touched!");

//    gr.view
    lastImageTouched = (UIImageView*)gr.view;
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
    
}

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //You can retrieve the actual UIImage
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [lastImageTouched setImage:image];
    //Or you can get the image url from AssetsLibrary
//    NSURL *path = [info valueForKey:UIImagePickerControllerReferenceURL];
    
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
}

-(void)updateChannelNames:(NSArray *)names{
    for (int i = 0; i < numChannels; i++) {
        [channelNames replaceObjectAtIndex:i withObject:[names objectAtIndex:i]];
        ((UILabel*)[channelNameLabels objectAtIndex:i]).text = [names objectAtIndex:i];
        [(UILabel*)[channelNameLabels objectAtIndex:i] setNeedsDisplay];
    }
    [self.view reloadInputViews];
}

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
    [sock readDataWithTimeout:-1 tag:0];
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSLog(@"socket:%p didReadData:withTag:%ld", sock, tag);
    
//    NSString *ack = [[NSString alloc] initWithFormat:@"received %li",tag];
//    NSData *d = [ack dataUsingEncoding:NSUTF8StringEncoding];
//    [sock writeData:d withTimeout:-1 tag:0];
    
    if(data.length == dataSize * numChannels){
        [self decodeAudioBufferListMultiChannel:data];
    } else {
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
            } else if ((int)array.count == numChannels){
                [self updateChannelNames:array];
            } else if ([[array objectAtIndex:0] isEqual:@"image"]){
                //Initialize standard image already on the phone
                long index = [[array objectAtIndex:1] integerValue];
                NSString *path = [[NSBundle mainBundle] pathForResource:[array objectAtIndex:2] ofType:[array objectAtIndex:3]];
                UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
                [[channelImageViews objectAtIndex:index] setImage:image];
                [self.view reloadInputViews];
            }
        }
    }
    
    int datalength = dataSize * numChannels;
    
//    [sock readDataToLength:dataSize*numChannels withTimeout:15 tag:0];
    [sock readDataToLength:datalength withTimeout:-1 tag:0];
//    [sock readDataWithTimeout:-1 tag:0];
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"Disconnected with error: %@", err.localizedDescription);
}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"Did write data with tag: %li",tag);
   // [sock readDataWithTimeout:-1 tag:0];
}

@end
