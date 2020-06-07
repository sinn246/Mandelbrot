//
//  calc.m
//  Mandelbrot
//
//  Created by 西村 信一 on 2020/06/07.
//  Copyright © 2020 sinn246. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Accelerate/Accelerate.h>


UIColor* makeColor(int z){
    double h = (double)(z % 32) / 32.0;
    return([UIColor colorWithHue:h saturation:1.0 brightness:1.0 alpha:1.0]);
}

void HSVtoRGB(unsigned char* RGB,CGFloat H,CGFloat S,CGFloat V){
    int H2 = ((int)(H*6)) % 6;
    CGFloat f = H*6 - floor(H*6);
    V = V*255;
    unsigned char p,q,t,v;
    p = V*(1-S);
    q = V*(1-f*S);
    t = V*(1-(1-f)*S);
    v = floor(V);
    switch (H2) {
        case 0:
            RGB[0]=v;RGB[1]=t;RGB[2]=p;
            break;
        case 1:
            RGB[0]=q;RGB[1]=v;RGB[2]=p;
            break;
        case 2:
            RGB[0]=p;RGB[1]=v;RGB[2]=t;
            break;
        case 3:
            RGB[0]=p;RGB[1]=q;RGB[2]=v;
            break;
        case 4:
            RGB[0]=t;RGB[1]=p;RGB[2]=v;
            break;
        case 5:
            RGB[0]=v;RGB[1]=p;RGB[2]=q;
            break;
        default:
            break;
    }
}

static void releaseData(void *info, const void *data, size_t size)
{
    NSLog(@"%@\n", (__bridge_transfer NSString*)info);
    free((unsigned char *)data);
}

void calc_mas(long WX,long WY,long WZ,double X0,double Y0,double Scale,BOOL (^update)(CGImageRef)){
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    BOOL stop = false;
    double two = 2.0;
    long len = WX*WY;
    unsigned char* ptr = malloc(len * 4);
    memset(ptr, 0, len*4);
    unsigned char* p;
    size_t total = len * sizeof(double);
    double* c_r = malloc(total);
    double* c_i = malloc(total);
    double* z_r = malloc(total);
    double* z_i = malloc(total);
    double* zr2 = malloc(total);
    double* zi2 = malloc(total);
    double* tmp = malloc(total);
    
    int x,y,z,i;
    
    double* p_r = c_r;
    double* p_i = c_i;
    for(y = 0;y<WY;y++){
        for(x = 0;x<WX;x++){
            *p_r++ = X0 + Scale *(double)x;
            *p_i++ = Y0 - Scale *(double)y;
        }
    }
    memcpy(z_r, c_r, total);
    memcpy(z_i, c_i, total);
    for(z=1;z<WZ;z++){
        vDSP_vmulD(z_r, 1, z_r, 1, zr2, 1, len);
        vDSP_vmulD(z_i, 1, z_i, 1, zi2, 1, len);
        vDSP_vaddD(zr2, 1, zi2, 1, tmp, 1, len);
        p = ptr;
        for(i=0;i<len;i++){
            if(p[3]==0){
                if(tmp[i]>4.0){
                    HSVtoRGB(p, (double)(z % 128) / 128.0, 1.0, 1.0);
                    p[3]=255;
                }
            }
            p+=4;
        }
        vDSP_vmulD(z_r, 1, z_i, 1, tmp, 1, len);
        vDSP_vsmaD(tmp, 1, &two, c_i, 1, z_i, 1, len);
        vDSP_vsubD(zi2, 1, zr2, 1, tmp, 1, len);
        vDSP_vaddD(tmp, 1, c_r, 1, z_r, 1, len);
        if(z%10==0){
            CGDataProviderRef provider = CGDataProviderCreateWithData(nil, ptr ,WX*WY*4,nil);
            CGImageRef image = CGImageCreate(WX, WY, 8, 32, WX*4, colorSpace, kCGImageAlphaLast | kCGBitmapByteOrder32Big
                                             ,provider, NULL, FALSE, kCGRenderingIntentDefault);
            stop = update(image);
            CGImageRelease(image);
            CGDataProviderRelease(provider);
            if(stop) goto abort;
        }
    }
    p = ptr;
    for(i=0;i<len;i++){
        if(p[3]==0) p[3]=255;
        p+=4;
    }
    CGDataProviderRef provider = CGDataProviderCreateWithData(nil, ptr ,WX*WY*4,releaseData);
    CGImageRef image = CGImageCreate(WX, WY, 8, 32, WX*4, colorSpace, kCGImageAlphaLast | kCGBitmapByteOrder32Big
                                     ,provider, NULL, FALSE, kCGRenderingIntentDefault);
    stop = update(image);
    CGImageRelease(image);
    CGDataProviderRelease(provider);
abort:
    free(tmp);
    free(c_r);free(c_i);
    free(z_r);free(z_i);
    free(zr2);free(zi2);
}


void calc_masOLD(long WX,long WY,long WZ, double X0,double Y0,double Scale,BOOL (^update)(CGImageRef)){
    unsigned char* ptr = malloc(WX * WY * 4);
    unsigned char* p = ptr;
    
    NSLog(@"start one");
        double c_r,c_i,z_r,z_i,zr2,zi2;
        int x,y,z;
        for(y = 0;y<WY;y++){
            for(x = 0;x<WX;x++){
                z_r = c_r = X0 + Scale * (double)x;
                z_i = c_i = Y0 - Scale * (double)y;
                for(z=1;z<WZ;z++){
                    zr2 = z_r*z_r;
                    zi2 = z_i*z_i;
                    if(zr2+zi2>4) break;
                    z_i = 2*z_r*z_i + c_i;
                    z_r = zr2 - zi2 + c_r;
                }
                if(z==WZ){
                    p[0] = p[1] = p[2] = 0; p[3] = 255;
                }else{
                    HSVtoRGB(p, (double)(z % 32) / 32.0, 1.0, 1.0);
                    p[3] = 255;
                }
                p += 4;
            }
        }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(nil, ptr ,WX*WY*4,releaseData);
    CGImageRef image = CGImageCreate(WX, WY, 8, 32, WX*4, colorSpace, kCGImageAlphaLast | kCGBitmapByteOrder32Big
                                     ,provider, NULL, FALSE, kCGRenderingIntentDefault);
    update(image);
    NSLog(@"quit one");
    CGImageRelease(image);
    CGDataProviderRelease(provider);
}
