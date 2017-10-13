
//
//  QRCodeLocation.m
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/29.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import "QRCodeLocation.h"

@interface QRCodeLocation ()

@end

@implementation QRCodeLocation

+ (QRCodeLocation *)share {
    static QRCodeLocation *location = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        location = [QRCodeLocation new];
    });
    return location;
}

+ (CGRect)opencvScanQRCode:(UIImage *)img {
    cv::Mat image,imageGray,imageGuussian;
    cv::Mat imageSobelX,imageSobelY,imageSobelOut;
    UIImageToMat(img, image);

    cv::RNG rng(12345);
   // cv::Mat src_all=image.clone();
    cvtColor( image, imageGray, CV_BGR2GRAY );
    //  src_gray = Scalar::all(255) - src_gray;
    blur( imageGray, imageGray, cv::Size(3,3) );
    equalizeHist( imageGray, imageGray );
   
    
    
    cv::Scalar color = cvScalar(1,1,255 );
    cv::Mat threshold_output;
    std::vector<std::vector<cv::Point>> contours,contours2;
    std::vector<cv::Vec4i> hierarchy;
    cv::Mat drawing = cv::Mat::zeros( image.size(), CV_8UC3 );
    cv::Mat drawing2 = cv::Mat::zeros( image.size(), CV_8UC3 );
    threshold(imageGray, threshold_output, 112, 255, cv::THRESH_BINARY );
    //Canny(src_gray,threshold_output,136,196,3);
    //imshow("预处理后：",threshold_output);
    
    
    findContours(threshold_output, contours, hierarchy,  CV_RETR_TREE, CV_CHAIN_APPROX_NONE, cv::Point(0, 0) );
    //CHAIN_APPROX_NONE全体,CV_CHAIN_APPROX_SIMPLE,,,RETR_TREE    RETR_EXTERNAL    RETR_LIST   RETR_CCOMP
    
    
    int ic=0 ,area=0;
    //
    //程序的核心筛选
    int parentIdx=-1;
    for( int i = 0; i< contours.size(); i++ )
    {
        if (hierarchy[i][2] != -1 && ic==0) {
            parentIdx = i;
            ic++;
        }
        else if (hierarchy[i][2] != -1) {
            ic++;
        }
        else if(hierarchy[i][2] == -1)
        {
            ic = 0;
            parentIdx = -1;
        }
        
        
        if ( ic >= 2)
        {
              cv::RotatedRect rectPoint =  minAreaRect(contours[i]);
            CGFloat w = rectPoint.size.width;
            CGFloat h = rectPoint.size.height;
            
            if (w / h < 1.1 && w / h > 0.9) {
                contours2.push_back(contours[parentIdx]);
                ic = 0;
                parentIdx = -1;
                area = contourArea(contours[i]);//得出一个二维码定位角的面积，以便计算其边长（area_side）（数据覆盖无所谓，三个定位角中任意一个数据都可以）
                
                //NSLog(@"/*/*/*/*/*w=%f, h=%f", rectPoint.size.width, rectPoint.size.height);
            }
            NSLog(@"/*/*/*/*/*w=%f, h=%f", rectPoint.size.width, rectPoint.size.height);
        }
        //cout<<"i= "<<i<<" hierarchy[i][2]= "<<hierarchy[i][2]<<" parentIdx= "<<parentIdx<<" ic= "<<ic<<endl;
        
        
    }
    
    
    for(int i=0; i<contours2.size(); i++){
       // drawContours(drawing2, contours2, i,  CV_RGB(rng.uniform(100,255),rng.uniform(100,255),rng.uniform(100,255)) , -1, 4, hierarchy[k][2], 0, cv::Point() );
    }
    
    
    
    CvPoint point[contours2.size()];
    for(int i=0; i<contours2.size(); i++) {
        
        point[i] = Center_cal(contours2, i);
        
    }
    if (contours2.size() > 0) {
        area = contourArea(contours2[0]);//为什么这一句和前面一句计算的面积不一样呢
    }
    

    int area_side = cvRound (sqrt (double(area)));
    for(int i=0; i<contours2.size(); i++) {
        line(drawing2,point[i%contours2.size()],point[(i+1)%contours2.size()],color,area_side/2,8)
        ;
    }

    
    cv::Mat gray_all,threshold_output_all;
    std::vector<std::vector<cv::Point> > contours_all;
    std::vector<cv::Vec4i> hierarchy_all;
    cvtColor( drawing2, gray_all, CV_BGR2GRAY );
    
    
    threshold(gray_all, threshold_output_all, 45, 255, cv::THRESH_BINARY );
    findContours( threshold_output_all, contours_all, hierarchy_all,  CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE, cv::Point(0, 0) );//RETR_EXTERNAL表示只寻找最外层轮廓
 
    cv::RotatedRect rectPoint = cv::RotatedRect();
    CGRect resoultRect = CGRectMake(0, 0, 0, 0);

    if (contours_all.size() > 0) {
    rectPoint = cv::minAreaRect(contours_all[0]);
        resoultRect = CGRectMake(rectPoint.center.x, rectPoint.center.y, rectPoint.size.width, rectPoint.size.height);
    }
   
   // NSLog(@"%f", rectPoint.angle);
    return resoultRect;
}

+ (UIImage *)imageOpencvScanQRCode:(UIImage *)img {
    cv::Mat image,imageGray,imageGuussian;
    cv::Mat imageSobelX,imageSobelY,imageSobelOut;
    UIImageToMat(img, image);
    
    
    cv::RNG rng(12345);
    // cv::Mat src_all=image.clone();
    cvtColor( image, imageGray, CV_BGR2GRAY );
    //  src_gray = Scalar::all(255) - src_gray;
    blur( imageGray, imageGray, cv::Size(3,3) );
    equalizeHist( imageGray, imageGray );
    
    
    
    cv::Scalar color = cvScalar(1,1,255 );
    cv::Mat threshold_output;
    std::vector<std::vector<cv::Point>> contours,contours2;
    std::vector<cv::Vec4i> hierarchy;
    cv::Mat drawing = cv::Mat::zeros( image.size(), CV_8UC3 );
    cv::Mat drawing2 = cv::Mat::zeros( image.size(), CV_8UC3 );
    threshold(imageGray, threshold_output, 112, 255, cv::THRESH_BINARY );
    //Canny(src_gray,threshold_output,136,196,3);
    //imshow("预处理后：",threshold_output);
    
    
    findContours(threshold_output, contours, hierarchy,  CV_RETR_TREE, CV_CHAIN_APPROX_NONE, cv::Point(0, 0) );
    //CHAIN_APPROX_NONE全体,CV_CHAIN_APPROX_SIMPLE,,,RETR_TREE    RETR_EXTERNAL    RETR_LIST   RETR_CCOMP
    
    
    int ic=0 , k = 0,area=0;
    //
    //程序的核心筛选
    int parentIdx=-1;
    for( int i = 0; i< contours.size(); i++ )
    {
        if (hierarchy[i][2] != -1 && ic==0)
        {
            parentIdx = i;
            ic++;
        }
        else if (hierarchy[i][2] != -1)
        {
            ic++;
        }
        else if(hierarchy[i][2] == -1)
        {
            ic = 0;
            parentIdx = -1;
        }
        
        
        if ( ic >= 2) {
            contours2.push_back(contours[parentIdx]);
            //drawContours(drawing, contours, parentIdx,  CV_RGB(rng.uniform(0,255),rng.uniform(0,255),rng.uniform(0,255)) , 1, 8);
            ic = 0;
            parentIdx = -1;
          //  area = contourArea(contours[i]);//得出一个二维码定位角的面积，以便计算其边长（area_side）（数据覆盖无所谓，三个定位角中任意一个数据都可以）
        }
       // std::cout<<"i= "<<i<<" hierarchy[i][2]= "<<hierarchy[i][2]<<" parentIdx= "<<parentIdx<<" ic= "<<ic<<std::endl;
        
        
    }
    
    
 
    for(int i=0; i<contours2.size(); i++){
        drawContours(drawing2, contours2, i,  CV_RGB(rng.uniform(100,255),rng.uniform(100,255),rng.uniform(100,255)) , -1, 4, hierarchy[k][2], 0, cv::Point() );
    }
    
    CvPoint point[contours2.size()];
    for(int i=0; i<contours2.size(); i++) {
        
        point[i] = Center_cal(contours2, i);
        
    }
    if (contours2.size() > 0) {
        //area = contourArea(contours2[0]);//为什么这一句和前面一句计算的面积不一样呢
    }
    

    uchar* ptr;

    

  
    NSUInteger contours2Size = contours2.size();
    while (contours2Size) {
        
        for(NSUInteger i = contours2.size() - contours2Size; i<contours2.size(); i++) {
            
            
            //
            //cv::LineIterator(drawing2, point[i%contours2.size()], point[(i+1)%contours2.size()], 8, false);
           // max_buffer = cv::LineIterator(threshold_output, point[i%contours2.size()], point[(i+1)%contours2.size()], 8, false).count;
            ptr = cv::LineIterator(threshold_output, point[(contours2.size() - contours2Size)%contours2.size()], point[(i+1)%contours2.size()], 8, false).ptr;
            
           
        
            
            //NSString *ptrStr = [NSString stringWithFormat:@"%s", ptr];
            
            
            
            //if (ptrStr.length == 0) {
                line(image,point[(contours2.size() - contours2Size)%contours2.size()],point[(i+1)%contours2.size()],1,8);
                NSLog(@"/*/*/*/*/*%s", ptr);
                // NSLog(@"/*/*/*/*/*%s", ptr);
           // }
            
         
            //max_buffer = cvInitLineIterator(&drawing2, point[i%contours2.size()], point[(i+1)%contours2.size()], &iterator);
        }
        contours2Size --;
    }
    
    
    
    cv::Mat gray_all,threshold_output_all;
    std::vector<std::vector<cv::Point> > contours_all;
    std::vector<cv::Vec4i> hierarchy_all;
    cvtColor( drawing2, gray_all, CV_BGR2GRAY );
    
    
    threshold( gray_all, threshold_output_all, 45, 255, cv::THRESH_BINARY );
    findContours( threshold_output_all, contours_all, hierarchy_all,  CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE, cv::Point(0, 0) );//RETR_EXTERNAL表示只寻找最外层轮廓
    
    cv::RotatedRect rectPoint = cv::RotatedRect();
    CGRect resoultRect = CGRectMake(0, 0, 0, 0);
    
    if (contours_all.size() > 0) {
        rectPoint = cv::minAreaRect(contours_all[0]);
        resoultRect = CGRectMake(rectPoint.center.x, rectPoint.center.y, rectPoint.size.width, rectPoint.size.height);
    }
    UIImage *resoultImage = MatToUIImage(image);
     NSLog(@"%f", rectPoint.angle);
    return resoultImage;
}
//找到所提取轮廓的中心点
CvPoint Center_cal(std::vector<std::vector<cv::Point>> contours, int i) {
    int centerx=0,centery=0;
    long n=contours[i].size();
    //在提取的小正方形的边界上每隔周长个像素提取一个点的坐标，求所提取四个点的平均坐标（即为小正方形的大致中心）
    centerx = (contours[i][n/4].x + contours[i][n*2/4].x + contours[i][3*n/4].x + contours[i][n-1].x)/4;
    centery = (contours[i][n/4].y + contours[i][n*2/4].y + contours[i][3*n/4].y + contours[i][n-1].y)/4;
    CvPoint point1=cv::Point(centerx,centery);
    return point1;
}


@end
