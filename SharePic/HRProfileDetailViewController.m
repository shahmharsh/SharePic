//
//  FirstViewController.m
//  SharePic
//
//  Created by Harsh Shah on 11/30/14.
//  Copyright (c) 2014 Harsh Shah, Rakshit Pithadia. All rights reserved.
//

#import "HRProfileDetailViewController.h"
#define HRImageViewTag 100
#define HRAccountImageViewTag 101
#define HRTableViewRows 2
#define HRCollectionViewSections 1

@interface HRProfileDetailViewController ()
@property (nonatomic, retain) FKImageUploadNetworkOperation *uploadOp;
@property (nonatomic, strong) DBRestClient *restClient;
@end

@implementation HRProfileDetailViewController
@synthesize currentAlbum = _currentAlbum;
@synthesize gridView = _gridView;
@synthesize albumDescriptionTable = _albumDescriptionTable;
@synthesize currentProfile = _currentProfile;
@synthesize accountImageView = _accountImageView;

- (void)viewDidLoad {
    [super viewDidLoad];
    _currentAlbum = [HRAlbum new];
    _gridView.delegate = self;
    _accountImageView.delegate = self;
    _albumDescriptionTable.scrollEnabled = NO;
    
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
}

- (void)setProfile:(id)profile {
    if (_currentProfile != profile) {
        _currentProfile = profile;

        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (_currentProfile) {
        self.title = _currentProfile.profileName;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)launchPicker {
    
    ELCImagePickerController *imagePicker = [[ELCImagePickerController alloc] initImagePicker];
    
    imagePicker.maximumImagesCount = HRMaximumImageCount;
    imagePicker.returnsOriginalImage = HRReturnOriginalImage;
    imagePicker.returnsImage = HRReturnsImage;
    imagePicker.onOrder = HRDisplayOrder;
    imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
    imagePicker.imagePickerDelegate = self;
    
    [self presentViewController:imagePicker animated:YES completion:nil];
    
}

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    HRPatternViewCell *cell = [[HRPatternViewCell alloc]init];
    
    for (UIView *v in [_gridView subviews]) {
        [v removeFromSuperview];
    }
    
    CGRect workingFrame = _gridView.frame;
    workingFrame.origin.x = 0;
    
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:[info count]];
    for (NSDictionary *dict in info) {
        if ([dict objectForKey:UIImagePickerControllerMediaType] == ALAssetTypePhoto){
            if ([dict objectForKey:UIImagePickerControllerOriginalImage]){
                UIImage* image=[dict objectForKey:UIImagePickerControllerOriginalImage];
                [images addObject:image];
                
                [cell.patternImageView setContentMode:UIViewContentModeScaleAspectFit];
                cell.patternImageView.frame = workingFrame;
                [_gridView addSubview:cell.patternImageView];
                workingFrame.origin.x = workingFrame.origin.x + workingFrame.size.width;
            } else {
                NSLog(@"UIImagePickerControllerReferenceURL = %@", dict);
            }
        } else if ([dict objectForKey:UIImagePickerControllerMediaType] == ALAssetTypeVideo){
            if ([dict objectForKey:UIImagePickerControllerOriginalImage]){
                UIImage* image=[dict objectForKey:UIImagePickerControllerOriginalImage];
                
                [images addObject:image];
                [cell.patternImageView setContentMode:UIViewContentModeScaleAspectFit];
                cell.patternImageView.frame = workingFrame;
                [_gridView addSubview:cell.patternImageView];
                workingFrame.origin.x = workingFrame.origin.x + workingFrame.size.width;
            } else {
                NSLog(@"UIImagePickerControllerReferenceURL = %@", dict);
            }
        } else {
            NSLog(@"Unknown asset type");
        }
    }
    
    _currentAlbum.photos = [images mutableCopy];
    
    [_gridView setPagingEnabled:YES];
    [_gridView setContentSize:CGSizeMake(workingFrame.origin.x, workingFrame.size.height)];
    [_gridView reloadData];
    
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Collection View Methods

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return HRCollectionViewSections;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (collectionView == _gridView) {
        return _currentAlbum.photos.count;
    } else {
        return _currentProfile.accounts.count;
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if(collectionView == _gridView) {
        HRPatternViewCell *cell = (HRPatternViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:HRPatternCell forIndexPath:indexPath];
        UIImageView *imageView = (UIImageView *) [cell viewWithTag:HRImageViewTag];
        imageView.image = [_currentAlbum.photos objectAtIndex:indexPath.row];
        return cell;
    } else {
        
        HRAccountImageCell *cell = (HRAccountImageCell *)[collectionView dequeueReusableCellWithReuseIdentifier:HRAccountCell forIndexPath:indexPath];
        UIImageView *imageView = (UIImageView *) [cell viewWithTag:HRAccountImageViewTag];
        NSMutableArray *accounts = [[NSMutableArray alloc]init];
        for (int i = 0; i < _currentProfile.accounts.count; i++) {
            [accounts addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%@.png",[_currentProfile.accounts objectAtIndex:i]]]];
        }
        imageView.image = [accounts objectAtIndex:indexPath.row];
        return cell;
    }
    return nil;
}

#pragma mark Album Table View

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return HRTableViewRows;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HRAlbumDescriptionCell];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:HRAlbumDescriptionCell];
    }
    
    CGRect screenRect = [[UIScreen mainScreen]bounds];
    
    UITextField *albumDetailsTextField = [[UITextField alloc] initWithFrame:CGRectMake(150, 7, screenRect.size.width - 150, 30)];
    
    albumDetailsTextField.delegate = self;
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    albumDetailsTextField.adjustsFontSizeToFitWidth = YES;
    if ([indexPath row] == 0) {
        albumDetailsTextField.placeholder = HRAlbumNamePlaceholder;
        albumDetailsTextField.keyboardType = UIKeyboardTypeDefault;
        albumDetailsTextField.returnKeyType = UIReturnKeyDone;
        albumDetailsTextField.tag = 0;
    }else{
        albumDetailsTextField.placeholder = HRAlbumDescriptionPlaceholder;
        albumDetailsTextField.keyboardType = UIKeyboardTypeDefault;
        albumDetailsTextField.returnKeyType = UIReturnKeyDone;
        albumDetailsTextField.tag = 1;
    }
    
    albumDetailsTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    albumDetailsTextField.clearButtonMode = UITextFieldViewModeAlways;
    [albumDetailsTextField setEnabled:YES];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.contentView addSubview:albumDetailsTextField];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = HRAlbumName;
    } else {
        cell.textLabel.text = HRAlbumDescription;
    }
    
    if ([cell.textLabel.text isEqualToString:HRAlbumName]) {
        cell.detailTextLabel.text = _currentAlbum.name;
    }
    if ([cell.textLabel.text isEqualToString:HRAlbumDescription]) {
        cell.detailTextLabel.text = _currentAlbum.albumDescription;
    }
    
    return cell;
}

#pragma mark Touch methods

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    [self saveTextFields:textField];
}

-(void) saveTextFields: (UITextField *) textField {
    if (textField.tag == 0) {
        _currentAlbum.name = textField.text;
    }else{
        _currentAlbum.albumDescription = textField.text;
    }
}

#pragma mark Dropbox upload call back methods
- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    NSLog(@"File upload failed with error: %@", error);
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath {
    
    NSLog(@"%.2f",progress); //Correct way to visualice the float
    
}

#pragma mark IBActions

- (IBAction)uploadButtonPressed:(id)sender {
    if (![_currentAlbum.name length] == 0 && ![_currentAlbum.albumDescription length] == 0) {
        NSLog(@"%@",_currentAlbum.name);
        NSLog(@"%@",_currentAlbum.albumDescription);
        
        //int imageNumber = 0;
        /*
         for (UIImage *image in [_currentAlbum photos]) {
         NSString *imageTitle = [NSString stringWithFormat:@"Image %d", ++imageNumber];
         NSDictionary *uploadArgs = @{@"title": imageTitle, @"description": @"A Photo via Share-a-Pic App", @"is_public": @"0", @"is_friend": @"0", @"is_family": @"0", @"hidden": @"2"};
         
         self.uploadOp = [[FlickrKit sharedFlickrKit] uploadImage:image args:uploadArgs completion:^(NSString *imageID, NSError *error) {
         if (error) {
         NSLog(@"Could not upload");
         } else {
         NSString *msg = [NSString stringWithFormat:@"Uploaded image ID %@", imageID];
         NSLog(@"%@ uploaded", msg);
         }
         }];
         }*/
        
        NSData *data = UIImagePNGRepresentation([[_currentAlbum photos] objectAtIndex:0]);
        NSString *filename = @"upload.png";
        //NSString *text = @"Hello world.";
        //NSString *filename = @"working-draft.txt";
        NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *localPath = [localDir stringByAppendingPathComponent:filename];
        //[text writeToFile:localPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [data writeToFile:localPath atomically:YES];
        NSLog(@"%@",localPath);
        // Upload file to Dropbox
        NSString *destDir = @"/";
        [self.restClient uploadFile:filename toPath:destDir withParentRev:nil fromPath:localPath];
    }
}

@end
