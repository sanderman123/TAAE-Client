//
//  ViewController.h
//  taaeTest2
//
//  Created by Sander on 12/30/14.
//  Copyright (c) 2014 Sander. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "TheAmazingAudioEngine.h"
#import "AEPlaythroughChannel.h"
#import "TPCircularBuffer.h"
#import "TPCircularBuffer+AudioBufferList.h"
#import <Accelerate/Accelerate.h>

#import "GCDAsyncUdpSocket.h"
#import "GCDAsyncSocket.h"

//#import "MyAudioReceiver.h"

#import "MonitorChannel.h"

#import <dispatch/dispatch.h>

@interface ViewController : UIViewController<AEAudioReceiver, GCDAsyncUdpSocketDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GCDAsyncSocketDelegate> {
    @public
    GCDAsyncUdpSocket *udpSocket;
    long localTag;
    int numChannels;
    NSMutableArray *channelNames;
    NSMutableArray *channelNameLabels;
    NSMutableArray *channelImageViews;
    UIImage *defaultImage;
    int dataSize;
    int ablSize;
    NSMutableArray *sliders;
    NSMutableArray *ablNSArray;
    bool initialized;
    int imageFlag;
    UIImageView *lastImageTouched;
    GCDAsyncSocket *tcpSocket;
}

//------MVC classes------
@property (nonatomic, strong) NSMutableArray* channels;


//-----------------------



@property (retain, nonatomic) AEAudioController *audioController;
@property (nonatomic, strong) AEPlaythroughChannel *playthrough;
@property (nonatomic, assign) TPCircularBuffer cb;
@property (nonatomic) AudioBufferList *abl;// = (AudioBufferList*) malloc(sizeof(AudioBufferList));
@property (nonatomic) AudioBufferList *abl1;
@property (nonatomic) AudioBufferList *abl2;
@property (nonatomic) Byte *byteData;// = (Byte*) malloc(l);
@property (nonatomic) Byte *byteData2;// = (Byte*) malloc(l);

//multichannel stuff
@property (nonatomic) Byte *byteDataArray;
@property (nonatomic) AudioBufferList *ablArray;
@property (nonatomic) NSMutableData *mutableData;
//@property (nonatomic) AudioBufferList *decodedAbl;

//@property  MyAudioPlayer *player1;

@property (weak, nonatomic) IBOutlet UIButton *btnSend;
- (IBAction)btnSendClicked:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *tfIPAddress;
@property (weak, nonatomic) IBOutlet UITextField *tfPort;
@property (weak, nonatomic) IBOutlet UITextField *tfMessage;

-(void)sliderAction:(UISlider*)sender;

- (NSData *) encodeAudioBufferList:(AudioBufferList *)abl;

- (void) decodeAudioBufferListMultiChannel: (NSData *) data;

-(void) initializeAll;

- (void) updateChannelNames:(NSArray*)names;

-(void) setupSocket;
-(void) setupTCPSocket;
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
- (IBAction)clickedBackground;

@end

