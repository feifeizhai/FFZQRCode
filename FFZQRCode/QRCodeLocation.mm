
//
//  QRCodeLocation.m
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/29.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import "QRCodeLocation.h"
@implementation QRCodeModel
- (void)dealloc {
    
    
}
@end

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


//找到所提取轮廓的中心点
cv::Point Center_cal(std::vector<std::vector<cv::Point>> contours, int i) {
    int centerx=0,centery=0;
    long n=contours[i].size();
    cv::Point pt;;
    double avg_px = 0, avg_py = 0;
    for (int j = 0; j < n; j++)
    {
        pt = contours[i][j];
        avg_px += pt.x;
        avg_py += pt.y;
    }
    centerx = avg_px / n;
    centery = avg_py / n;
    cv::Point point1=cv::Point(centerx,centery);
    return point1;
}

void Sharpenx (const cv::Mat myPicture , cv::Mat resultPicture)
{
    cv::Mat kern = (cv::Mat_<char>(3,3) << 0, -1 , 0 ,
                    -1, 5 ,-1 ,
                    0, -1, 0);
    filter2D(myPicture,resultPicture, myPicture.depth(), kern);
}



+ (UIImage *)sharpenx:(UIImage *)image {
    
    cv::Mat myPictureMat;
    UIImageToMat(image, myPictureMat);
    Sharpenx(myPictureMat, myPictureMat);
    UIImage *resoultImage = MatToUIImage(myPictureMat);
    return resoultImage;
    
}

+ (QRCodeModel *)imageOpencvQRCode:(UIImage *)img {
    
    cv::Mat image,imageGray;
    std::vector<std::vector<cv::Point>> contours,markContours;
    UIImageToMat(img, image);
    
    if (img.size.width * img.size.height < 90000) {
        
        cv::resize(image, image, cv::Size(800, 600));
        
    }
    cv::Mat image_all = image.clone();
    cvtColor(image, imageGray, CV_BGR2GRAY );
    //blur(imageGray, imageGray, cv::Size(3,3));
    cv::Canny(imageGray, imageGray, 100, 255);
    
    std::vector<cv::Vec4i> hierachy;
    cv::findContours(imageGray, contours, hierachy, CV_RETR_TREE, CV_CHAIN_APPROX_NONE);
    
    for (int i = 0; i < contours.size(); i ++) {
        
        std::vector<cv::Point> newMtx = contours[i];
        cv::RotatedRect rotRect = cv::minAreaRect(newMtx);
        double w = rotRect.size.width;
        double h = rotRect.size.height;
        double rate =  MAX(w, h)/MIN(w, h);
        /***
         * 长短轴比小于1.3
         */
        if (rate < 1.3 && w < imageGray.cols/4 && h < imageGray.cols/4) {
            
            cv::Vec4i ds = hierachy[i];
            
            int count = 0;
            if (ds[3] == -1) {
                continue;
            }
            
            while (ds[2] != -1) {
                ++count;
                ds = hierachy[ds(2)];
            }
            //应该是4 但是迫于实际二维码有的很不标准定位不到三个角的方框, 只能找二维码内部的方框
            if (count >= 3){
                
                markContours.push_back(contours[i]);
                
            }
            
        }
        
    }
    
    
    std::vector<cv::Point> pointCenter;
    //std::vector<cv::Point> pointthree;
    for (int i = 0; i < markContours.size();  i ++) {
        
        cv::RotatedRect rectPoint = cv::RotatedRect();
        rectPoint = cv::minAreaRect(markContours[i]);
        pointCenter.push_back(cv::Point(rectPoint.center.x, rectPoint.center.y));
        
        
    }
    long count = pointCenter.size();
    for (int i = 0;  i < count - 1; i ++) {
        for (int j = i + 1 ; j < count; j ++) {
            cv::Point pointI = pointCenter[i];
            cv::Point pointJ = pointCenter[j];
            if ((abs(pointI.x - pointJ.x) < 2 && abs(pointI.y - pointJ.y) < 2) || (abs(pointI.x - pointJ.y) < 2 && abs(pointI.y - pointJ.x) < 2) ) {
                
                //for (int k = j + 1; k < count; k ++) {
                std::vector<cv::Point>::iterator it = pointCenter.begin()+j;
                pointCenter.erase(it);
                
                //}
                j --;
                count --;
            }
        }
    }
    //    for(int i=0; i<markContours.size(); i++){
    //        cv::drawContours(image_all, markContours, i, cv::Scalar(0,255,0), -1);
    //
    //    }
    //    for(int i=0; i<pointCenter.size(); i++){
    //        line(image_all, pointCenter[i], pointCenter[i + 1], 1, 8);
    //    }
    //    UIImage *resoultImage = MatToUIImage(image_all);
    //
    //    if (resoultImage) {
    //        QRCodeModel *model = [[QRCodeModel alloc] init];
    //        model.image = resoultImage;
    //        model.w = @(0);
    //        model.h = @(0);
    //
    //        return model;
    //    }
    std::vector<cv::Point> pointthree = pointCenter;
    
    if (pointthree.size() < 3){
        
        
        return nil;
        
    }else{
        
        for (int i=0; i<pointthree.size()-2; i++){
            std::vector<cv::Point> threePointList;
            for (int j=i+1;j<pointthree.size()-1; j++){
                for (int k=j+1;k<pointthree.size();k ++){
                    threePointList.push_back(pointthree[i]);
                    threePointList.push_back(pointthree[j]);
                    threePointList.push_back(pointthree[k]);
                    @autoreleasepool {
                        QRCodeModel *result = [self capture:threePointList image:image];
                        threePointList.clear();
                        if (result) {
                            return result;
                        }
                        
                    }
                }
            }
        }
    }
    return nil;
}

+ (QRCodeModel *)capture:(std::vector<cv::Point>)contours image:(cv::Mat)image {
    std::vector<cv::Point> pointthree = contours;
    cv::Vec2i ca;
    cv::Vec2i cb;
    
    ca[0] =  pointthree[1].x - pointthree[0].x;
    ca[1] =  pointthree[1].y - pointthree[0].y;
    cb[0] =  pointthree[2].x - pointthree[0].x;
    cb[1] =  pointthree[2].y - pointthree[0].y;
    
    double angle1 = 180/3.1415*acos((ca[0]*cb[0]+ca[1]*cb[1])/(sqrt(ca[0]*ca[0]+ca[1]*ca[1])*sqrt(cb[0]*cb[0]+cb[1]*cb[1])));
    double ccw1;
    if(ca[0]*cb[1] - ca[1]*cb[0] > 0) {
        ccw1 = 0;
    } else {
        ccw1 = 1;
    }
    ca[0] =  pointthree[0].x - pointthree[1].x;
    ca[1] =  pointthree[0].y - pointthree[1].y;
    cb[0] =  pointthree[2].x - pointthree[1].x;
    cb[1] =  pointthree[2].y - pointthree[1].y;
    double angle2 = 180/3.1415*acos((ca[0]*cb[0]+ca[1]*cb[1])/(sqrt(ca[0]*ca[0]+ca[1]*ca[1])*sqrt(cb[0]*cb[0]+cb[1]*cb[1])));
    double ccw2;
    if(ca[0]*cb[1] - ca[1]*cb[0] > 0) {
        ccw2 = 0;
    }else {
        ccw2 = 1;
    }
    
    ca[0] =  pointthree[1].x - pointthree[2].x;
    ca[1] =  pointthree[1].y - pointthree[2].y;
    cb[0] =  pointthree[0].x - pointthree[2].x;
    cb[1] =  pointthree[0].y - pointthree[2].y;
    double angle3 = 180/3.1415*acos((ca[0]*cb[0]+ca[1]*cb[1])/(sqrt(ca[0]*ca[0]+ca[1]*ca[1])*sqrt(cb[0]*cb[0]+cb[1]*cb[1])));
    int ccw3;
    if(ca[0]*cb[1] - ca[1]*cb[0] > 0) {
        ccw3 = 0;
    }else {
        ccw3 = 1;
    }
    
    if (isnan(angle1) || isnan(angle2) || isnan(angle3)){
        return nil;
    }
    
    std::vector<cv::Point2f> poly(4);
    if(angle3>angle2 && angle3>angle1) {
        
        if(ccw3==1) {
            
            poly[1] = pointthree[1];
            poly[3] = pointthree[0];
        }
        else {
            poly[1] = pointthree[0];
            poly[3] = pointthree[1];
        }
        poly[0] = pointthree[2];
        cv::Point temp = cv::Point(pointthree[0].x + pointthree[1].x - pointthree[2].x , pointthree[0].y + pointthree[1].y - pointthree[2].y );
        poly[2] = temp;
    } else if(angle2>angle1 && angle2>angle3) {
        
        if(ccw2==1) {
            
            poly[1] = pointthree[0];
            poly[3] = pointthree[2];
            
        }else {
            
            poly[1] = pointthree[2];
            poly[3] = pointthree[0];
            
        }
        poly[0] = pointthree[1];
        cv::Point temp = cv::Point(pointthree[0].x + pointthree[2].x - pointthree[1].x , pointthree[0].y + pointthree[2].y - pointthree[1].y );
        poly[2] = temp;
    } else if(angle1>angle2 && angle1 > angle3) {
        if(ccw1==1) {
            poly[1] = pointthree[1];
            poly[3] = pointthree[2];
        } else {
            poly[1] = pointthree[2];
            poly[3] = pointthree[1];
        }
        poly[0] = pointthree[0];
        cv::Point temp = cv::Point(pointthree[1].x + pointthree[2].x - pointthree[0].x , pointthree[1].y + pointthree[2].y - pointthree[0].y );
        poly[2] = temp;
    }
    
    std::vector<cv::Point2f> trans(4);
    
    int temp = 50;
    trans[0] = cv::Point(0+temp,0+temp);
    trans[1] = cv::Point(0+temp,100+temp);
    trans[2] = cv::Point(100+temp,100+temp);
    trans[3] = cv::Point(100+temp,0+temp);
    
    double maxAngle = MAX(angle3,MAX(angle1,angle2));
    
    if (maxAngle<75 || maxAngle>115){ /**二维码为直角，最大角过大或者过小都判断为不是二维码*/
        return nil;
    }
    
    cv::RotatedRect rectPoint = cv::RotatedRect();
    rectPoint = cv::minAreaRect(poly);
    
    double w = rectPoint.size.width;
    double h = rectPoint.size.height;
    double rate =  MAX(w, h)/MIN(w, h);
    if (rate > 1.3) {
        return nil;
    }
    cv::Mat warp_mat = cv::getPerspectiveTransform(poly, trans);
    
    cv::Mat dst;
    
    //计算变换结果
    
    cv::warpPerspective(image, dst, warp_mat, image.size(),cv::INTER_LINEAR);
    std::vector<std::vector<cv::Point>> transContourse;
    
    cv::Rect roiArea = cv::Rect(0, 0, 200, 200);
    cv::Mat dstRoi = cv::Mat(dst, roiArea);
    
    
    
    UIImage *resoultImage = MatToUIImage(dstRoi);
    
    if (resoultImage) {
        
        QRCodeModel *model = [[QRCodeModel alloc] init];
        model.image = resoultImage;
        model.w = @(w);
        model.h = @(h);
        model.x = @(rectPoint.center.x);
        model.y = @(rectPoint.center.y);
        return model;
    }
    return nil;
    // Imgcodecs.imwrite("F:\\output\\dstRoi-"+idx+".jpg", dstRoi);
    
}


@end
