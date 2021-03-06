//
//  CreatedForumsViewController.m
//  JoinUs
//
//  Created by Liang Qian on 26/4/2016.
//  Copyright © 2016 North Gate Code. All rights reserved.
//

#import "CreatedForumsViewController.h"
#import "Utils.h"
#import "NetworkManager.h"
#import "ForumModels.h"
#import "ForumItemTableViewCell.h"
#import "ForumTopicsViewController.h"

@interface CreatedForumsViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *createForumImage;
@end

@implementation CreatedForumsViewController {
    NSMutableArray<ForumItem*>* _listItems;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _listItems = [[NSMutableArray alloc] initWithCapacity:10];
    
        self.createForumImage.layer.shadowColor = [UIColor lightGrayColor].CGColor;
        self.createForumImage.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
        self.createForumImage.layer.shadowRadius = 5.0f;
        self.createForumImage.layer.shadowOpacity = 1.0f;
    
    [self addRefreshViewAndLoadMoreView];
    
    if ([[NetworkManager sharedManager] isLoggedIn]) {
        [self loadWithLoadingView];
    } else {
        [self showLoginView];
    }
}

- (void)presentLoginTapped {
    [self.parentViewController performSegueWithIdentifier:@"PresentLoginAndRegister" sender:self];
}

- (void)viewWillAppear:(BOOL)animated {
    if ([[NetworkManager sharedManager] isLoggedIn] && self.loginView != nil) {
        [self removeLoginView];
        [self loadWithLoadingView];
    }
    
    if (![[NetworkManager sharedManager] isLoggedIn] && self.loginView == nil)
    {
        [self showLoginView];
    }
}

- (void)loadData {
    NSString* url = [NSString stringWithFormat:@"forum/created?offset=%d&limit=%d", self.loadingStatus == LoadingStatusLoadingMore ? (int)_listItems.count : 0, 10];
    [[NetworkManager sharedManager] getDataWithUrl:url completionHandler:^(long statusCode, NSData *data, NSString *errorMessage) {
        if (statusCode == 200) {
            NSError* error;
            ForumListLimited* forumList = [[ForumListLimited alloc] initWithData:data error:&error];
            if (error == nil) {
                if (forumList.limit > forumList.forumItems.count) {
                    self.noMoreData = YES;
                } else {
                    self.noMoreData = NO;
                }
                
                if (self.loadingStatus == LoadingStatusLoadingWithLoadingView
                    || self.loadingStatus == LoadingStatusLoadingWithRefreshView
                    || self.loadingStatus == LoadingStatusLoadingWithToastActivity)
                {
                    [_listItems removeAllObjects];
                }
                
                for (ForumItem* item in forumList.forumItems) {
                    [_listItems addObject:item];
                }
                
                [self.tableView reloadData];
            } else {
                NSLog(@"JSON Error: %@", error);
            }
        } else {
            if (self.loadingStatus == LoadingStatusLoadingWithLoadingView) {
                [self showErrorViewWithMessage:errorMessage];
            } else {
                [self.view makeToast:errorMessage];
            }
        }
        
        [self removeLoadingViews];
    }];
}

- (IBAction)createForumImageTapped:(id)sender {
        [self.parentViewController performSegueWithIdentifier:@"PushCreateForum" sender:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_listItems != nil) {
        return _listItems.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ForumItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    ForumItem* item = _listItems[indexPath.row];
    if (cell.task != nil && cell.task.state == NSURLSessionTaskStateRunning) {
        [cell.task cancel];
    }
    cell.iconImageView.image = [UIImage imageNamed:@"no_image"];
    if (item.icon != nil) {
        cell.task = [[NetworkManager sharedManager] getResizedImageWithName:item.icon dimension:120 completionHandler:^(long statusCode, NSData *data) {
            if (statusCode == 200) {
                cell.iconImageView.image = [UIImage imageWithData:data];
            }
        }];
    }
    cell.nameLabel.text = item.name;
    cell.statisticsLabel.text = [NSString stringWithFormat:@"关注:%d 帖子:%d", item.watch, item.posts];
    cell.descLabel.text = item.desc;
    
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"PresentForumTopics" sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PresentForumTopics"]) {
        UINavigationController* navigationController = [segue destinationViewController];
        ForumTopicsViewController* forumTopicsViewController = navigationController.viewControllers[0];
        
        forumTopicsViewController.forumId = _listItems[self.tableView.indexPathForSelectedRow.row].id;;
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
}


@end
