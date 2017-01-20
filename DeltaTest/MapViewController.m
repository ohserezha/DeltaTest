//
//  MapViewController.m
//  DeltaTest
//
//  Created by ezkeemo on 1/20/17.
//  Copyright © 2017 ezkeemo. All rights reserved.
//

#import "MapViewController.h"
@import MapKit;
@import CoreLocation;


@interface MapViewController () <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.locationManager startUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.locationManager stopUpdatingLocation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Location Methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        NSString *message = nil;
        if (status == kCLAuthorizationStatusDenied) {
            message = @"You've denied this app to use location services. Please, allow it in the settings menu of your device";
        } else {
            message = @"Your device has no ability to determine location";
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Denied" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDestructive handler:nil];
        [alertController addAction:action];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    CLLocation *location = [locations lastObject];
    [self showLocationOnTheMap:location];
}

- (void)showLocationOnTheMap:(CLLocation *)location {
    MKCoordinateSpan span;
    span.latitudeDelta = 0.05;
    span.longitudeDelta = 0.05;
    CLLocationCoordinate2D location2D;
    location2D.latitude = location.coordinate.latitude;
    location2D.longitude = location.coordinate.longitude;
    MKCoordinateRegion region;
    region.span = span;
    region.center = location2D;
    
    [self.mapView setRegion:region animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
