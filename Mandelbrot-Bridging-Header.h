//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#import <UIKit/UIKit.h>

void calc_mas(long WX,long WY,long WZ,double X0,double Y0,double Scale,BOOL (^update)(CGImageRef));
void calc_mas_line(long WX,long WY,long WZ,double X0,double Y0,double Scale,BOOL (^update)(CGImageRef));
void calc_masD(long WX,long WY,long WZ,double X0,double Y0,double Scale,BOOL (^update)(CGImageRef));
void calc_masD_line(long WX,long WY,long WZ,double X0,double Y0,double Scale,BOOL (^update)(CGImageRef));
void calc_masNoDSP(long WX,long WY,long WZ,double X0,double Y0,double Scale,BOOL (^update)(CGImageRef));

