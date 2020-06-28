//
//  calc.m
//  Mandelbrot
//
//  Created by 西村 信一 on 2020/06/07.
//  Copyright © 2020 sinn246. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accelerate/Accelerate.h>
#import "Mandelbrot-Swift.h"

#define VEC_THRESHOLD 16
// for smaller number than this I wont use vDSP

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

static CGFloat zCycle = 128;
static int colorMode = 0;
static CGFloat colorOffset = 0.6;

void putZ(unsigned char* p,int z){
    CGFloat h ;
    switch(colorMode){
        case 0:
            h = (CGFloat)z / zCycle;
            break;
        case 1:
            h = log2(z+32)/5.0;
            break;
        case 2:
            h = (CGFloat)z * 0.5 / zCycle + log2(z+32)/5.0;
            break;
        default:
            p[0] = (z*3)%251+4;
            p[1] = (z)%127;
            p[2] = 255 - ((z*2)%251);
            return;
    }
    h += colorOffset;
    h = h - floor(h);
    HSVtoRGB(p,h, 1.0, 1.0);
}

static void releaseData(void *info, const void *data, size_t size)
{
    NSLog(@"Release Data");
    free((unsigned char *)data);
}

static NSTimeInterval start = 0;
static void start_calc(){
    start = CACurrentMediaTime();
    NSLog(@"Calc start");
}

static double finish_calc(){
    NSLog(@"Finished after %f seconds",CACurrentMediaTime()-start);
    return (double)(CACurrentMediaTime()-start);
}

size_t align16(size_t n) {return ((n-1)/16+1)*16;}


void calc_mas(long WX,long WY,long WZ,double X0,double Y0,double Scale,BOOL (^update)(CGImageRef)){
    colorMode = (int)[Bridge getColorMode];
    colorOffset = [Bridge getColorHue];
    CFTimeInterval now,timer = CACurrentMediaTime();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    start_calc();
    if(WZ > 100){
        [Bridge calcStartStop:FALSE time:0.0];
    }
    
    BOOL stop = false;
    float two = 2.0;
    long len = WX*WY;
    unsigned char* ptr = malloc(len * 4);
    memset(ptr, 0, len*4);
    unsigned char* p;
    size_t SX = align16(WX*sizeof(float));
    size_t sx = SX/sizeof(float);
    size_t SY = WY*sizeof(float);
    
    size_t total = SX * WY;
    float* c_r = malloc(SX);
    float* c_i = malloc(SY);
    float* tmp = malloc(SX*2);
    float* tmp2 = tmp + sx;
    float* base = malloc(total*4);
    float* Z;
    size_t z_r = 0;
    size_t z_i = sx;
    size_t zr2 = sx*2;
    size_t zi2 = sx*3;
    int* iFrom = malloc(WY*sizeof(int));
    int* iTo = malloc(WY*sizeof(int));
    int x,y,z,i;
    float cr,ci,zr,zi,r2,i2;
    
    
    for(x = 0;x<WX;x++){
        c_r[x] = X0 + Scale *(float)x;
    }
    for(y = 0;y<WY;y++){
        c_i[y] = Y0 - Scale *(float)y;
        Z = base + y*sx*4;
        for(x = 0;x<WX;x++){
            Z[z_i+x] = c_i[y];
            Z[z_r+x] = c_r[x];
        }
        iFrom[y] = 0;
        iTo[y] = (int)WX;
    }
    BOOL push_back;
    int iLast;
    int zStep = 100;
    int zTo;
    for(int zFrom=1;zFrom<WZ;zFrom+=zStep,zStep*=2){
        zTo = zFrom+zStep<WZ ? zFrom+zStep : (int)WZ;
        for(y = 0;y<WY;y++){
            if(iTo[y]==iFrom[y]) continue;
            Z = base + y*sx*4;
            if( iTo[y] - iFrom[y] <  VEC_THRESHOLD){
                p = ptr+y*WX*4+iFrom[y]*4;
                iLast = iTo[y];
                for(i = iFrom[y];i<iTo[y];i++,p+=4){
                    if(p[3]!=0) continue;
                    zr = Z[z_r+i]; zi = Z[z_i+i];
                    cr = c_r[i]; ci = c_i[y];
                    push_back = TRUE;
                    for(z=zFrom;z<zTo;z++){
                        r2 = zr*zr;
                        i2 = zi*zi;
                        if(r2+i2>4){
                            if(push_back) iFrom[y]++;
                            putZ(p,z);
                            p[3] = 255;
                            break;
                        }
                        zi = 2*zr*zi + ci;
                        zr = r2 - i2 + cr;
                    }
                    if(z==zTo){
                        push_back = FALSE;
                        iLast = i+1;
                    }
                    Z[z_r+i]=zr; Z[z_i+i]=zi;
                }
                iTo[y] = iLast;
            }else{
                for(z=zFrom;z<zTo;z++){
                    vDSP_vsq(Z+z_r+iFrom[y], 1, Z+zr2+iFrom[y], 1, (iTo[y]-iFrom[y]));
                    vDSP_vsq(Z+z_i+iFrom[y], 1, Z+zi2+iFrom[y], 1, (iTo[y]-iFrom[y]));
                    vDSP_vaddsub(Z+zi2+iFrom[y], 1, Z+zr2+iFrom[y], 1, tmp+iFrom[y], 1, tmp2 = tmp + sx, 1, (iTo[y]-iFrom[y]));
                    p = ptr+y*WX*4+iFrom[y]*4;
                    push_back = TRUE;
                    iLast = iTo[y];
                    for(i=iFrom[y];i<iTo[y];i++,p+=4){
                        if(p[3]==0){
                            if(tmp[i]>4.0){
                                if(push_back) { iFrom[y]++; tmp2++; }
                                putZ(p, z);
                                p[3]=255;
                            }else{
                                push_back = FALSE;
                                iLast = i+1;
                            }
                        }
                    }
                    iTo[y] = iLast;
                    if(iTo[y]==iFrom[y]) break;
                    vDSP_vmul(Z+z_r+iFrom[y], 1, Z+z_i+iFrom[y], 1, tmp, 1, (iTo[y]-iFrom[y]));
                    vDSP_vsmul(tmp, 1, &two, tmp, 1, (iTo[y]-iFrom[y]));
                    vDSP_vsadd(tmp, 1, &c_i[y], Z+z_i+iFrom[y], 1, (iTo[y]-iFrom[y]));
                    vDSP_vadd(tmp2, 1, c_r+iFrom[y], 1, Z+z_r+iFrom[y], 1, (iTo[y]-iFrom[y]));
                }
            }
        }
        now = CACurrentMediaTime();
        if(timer+1.0 < now){
            timer = now;
            CGDataProviderRef provider = CGDataProviderCreateWithData(nil, ptr ,WX*WY*4,nil);
            CGImageRef image = CGImageCreate(WX, WY, 8, 32, WX*4, colorSpace, kCGImageAlphaLast | kCGBitmapByteOrder32Big
                                             ,provider, NULL, FALSE, kCGRenderingIntentDefault);
            stop = update(image);
            CGImageRelease(image);
            CGDataProviderRelease(provider);
            if(stop){
                NSLog(@"Stopped");
                free(ptr);
                goto abort;
            }
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
    [Bridge setLastImage:image];
    CGImageRelease(image);
    CGDataProviderRelease(provider);
    if(WZ>100){
        [Bridge calcStartStop:TRUE time:finish_calc()];
    }
abort:
    free(iTo); free(iFrom);
    free(tmp);
    free(base);
    free(c_i);free(c_r);
}




void calc_masD(long WX,long WY,long WZ,double X0,double Y0,double Scale,BOOL (^update)(CGImageRef)){
    colorMode = (int)[Bridge getColorMode];
    colorOffset = [Bridge getColorHue];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    start_calc();
    if(WZ > 100){
        [Bridge calcStartStop:FALSE time:0.0];
    }
    
    BOOL stop = false;
    double two = 2.0;
    long len = WX*WY;
    unsigned char* ptr = malloc(len * 4);
    memset(ptr, 0, len*4);
    unsigned char* p;
    size_t SX = align16(WX*sizeof(double));
    size_t sx = SX/sizeof(double);
    size_t SY = WY*sizeof(double);
    
    size_t total = SX * WY;
    double* c_r = malloc(SX);
    double* c_i = malloc(SY);
    double* tmp = malloc(SX*2);
    double* tmp2 = tmp + sx;
    double* base = malloc(total*4);
    double* Z;
    size_t z_r = 0;
    size_t z_i = sx;
    size_t zr2 = sx*2;
    size_t zi2 = sx*3;
    int* iFrom = malloc(WY*sizeof(int));
    int* iTo = malloc(WY*sizeof(int));
    int x,y,z,i;
    double cr,ci,zr,zi,r2,i2;
    
    
    for(x = 0;x<WX;x++){
        c_r[x] = X0 + Scale *(double)x;
    }
    for(y = 0;y<WY;y++){
        c_i[y] = Y0 - Scale *(double)y;
        Z = base + y*sx*4;
        for(x = 0;x<WX;x++){
            Z[z_i+x] = c_i[y];
            Z[z_r+x] = c_r[x];
        }
        iFrom[y] = 0;
        iTo[y] = (int)WX;
    }
    BOOL push_back;
    int iLast;
    int zStep = 100;
    int zTo;
    for(int zFrom=1;zFrom<WZ;zFrom+=zStep,zStep*=2){
        zTo = zFrom+zStep<WZ ? zFrom+zStep : (int)WZ;
        for(y = 0;y<WY;y++){
            if(iTo[y]==iFrom[y]) continue;
            Z = base + y*sx*4;
            if( iTo[y] - iFrom[y] <  VEC_THRESHOLD){
                p = ptr+y*WX*4+iFrom[y]*4;
                iLast = iTo[y];
                for(i = iFrom[y];i<iTo[y];i++,p+=4){
                    if(p[3]!=0) continue;
                    zr = Z[z_r+i]; zi = Z[z_i+i];
                    cr = c_r[i]; ci = c_i[y];
                    push_back = TRUE;
                    for(z=zFrom;z<zTo;z++){
                        r2 = zr*zr;
                        i2 = zi*zi;
                        if(r2+i2>4){
                            if(push_back) iFrom[y]++;
                            putZ(p, z);
                            p[3] = 255;
                            break;
                        }
                        zi = 2*zr*zi + ci;
                        zr = r2 - i2 + cr;
                    }
                    if(z==zTo){
                        push_back = FALSE;
                        iLast = i+1;
                    }
                    Z[z_r+i]=zr; Z[z_i+i]=zi;
                }
                iTo[y] = iLast;
            }else{
                for(z=zFrom;z<zTo;z++){
                    vDSP_vsqD(Z+z_r+iFrom[y], 1, Z+zr2+iFrom[y], 1, (iTo[y]-iFrom[y]));
                    vDSP_vsqD(Z+z_i+iFrom[y], 1, Z+zi2+iFrom[y], 1, (iTo[y]-iFrom[y]));
                    vDSP_vaddsubD(Z+zi2+iFrom[y], 1, Z+zr2+iFrom[y], 1, tmp+iFrom[y], 1, tmp2 = tmp + sx, 1, (iTo[y]-iFrom[y]));
                    p = ptr+y*WX*4+iFrom[y]*4;
                    push_back = TRUE;
                    iLast = iTo[y];
                    for(i=iFrom[y];i<iTo[y];i++,p+=4){
                        if(p[3]==0){
                            if(tmp[i]>4.0){
                                if(push_back) { iFrom[y]++; tmp2++; }
                                putZ(p, z);
                                p[3]=255;
                            }else{
                                push_back = FALSE;
                                iLast = i+1;
                            }
                        }
                    }
                    iTo[y] = iLast;
                    if(iTo[y]==iFrom[y]) break;
                    vDSP_vmulD(Z+z_r+iFrom[y], 1, Z+z_i+iFrom[y], 1, tmp, 1, (iTo[y]-iFrom[y]));
                    vDSP_vsmulD(tmp, 1, &two, tmp, 1, (iTo[y]-iFrom[y]));
                    vDSP_vsaddD(tmp, 1, &c_i[y], Z+z_i+iFrom[y], 1, (iTo[y]-iFrom[y]));
                    vDSP_vaddD(tmp2, 1, c_r+iFrom[y], 1, Z+z_r+iFrom[y], 1, (iTo[y]-iFrom[y]));
                }
            }
        }
        CGDataProviderRef provider = CGDataProviderCreateWithData(nil, ptr ,WX*WY*4,nil);
        CGImageRef image = CGImageCreate(WX, WY, 8, 32, WX*4, colorSpace, kCGImageAlphaLast | kCGBitmapByteOrder32Big
                                         ,provider, NULL, FALSE, kCGRenderingIntentDefault);
        stop = update(image);
        CGImageRelease(image);
        CGDataProviderRelease(provider);
        if(stop){
            NSLog(@"Stopped");
            free(ptr);
            goto abort;
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
    [Bridge setLastImage:image];
    CGImageRelease(image);
    CGDataProviderRelease(provider);
    if(WZ>100){
        [Bridge calcStartStop:TRUE time:finish_calc()];
    }
abort:
    free(iTo); free(iFrom);
    free(tmp);
    free(base);
    free(c_i);free(c_r);
}

void calc_masD_line(long WX,long WY,long WZ,double X0,double Y0,double Scale,BOOL (^update)(CGImageRef)){
    colorMode = (int)[Bridge getColorMode];
    colorOffset = [Bridge getColorHue];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    start_calc();
    if(WZ > 100){
        [Bridge calcStartStop:FALSE time:0.0];
    }
    
    int iFrom,iTo;
    int x,y,z,i;
    double cr,ci,zr,zi,r2,i2;
    BOOL stop = false;
    double two = 2.0;
    long len = WX*WY;
    unsigned char* ptr = malloc(len * 4);
    memset(ptr, 0, len*4);
    unsigned char* p,*py;
    size_t SX = align16(WX*sizeof(double));
    size_t sx = SX/sizeof(double);
    size_t SY = WY*sizeof(double);
    
    double* c_r = malloc(SX);
    double* c_i = malloc(SY);
    double* base = malloc(SX*6);
    double* tmp = base;
    double* tmp2 = base + sx;
    double* z_r = base + sx*2;
    double* z_i = base + sx*3;
    double* zr2 = base + sx*4;
    double* zi2 = base + sx*5;
    
    for(x = 0;x<WX;x++){
        c_r[x] = X0 + Scale *(double)x;
    }
    for(y = 0;y<WY;y++){
        c_i[y] = Y0 - Scale *(double)y;
    }
    BOOL push_back;
    int iLast;
    int yStep = 16;
    for(int yy=0;yy < yStep;yy++){
        for(y = yy;y<WY;y+=yStep){
            py = ptr+y*WX*4;
            memcpy(z_r,c_r,SX);
            for(i = 0;i<WX;i++) z_i[i] = c_i[y];
            iFrom = 0;
            iTo = (int)WX;
            
            for(z = 1;z<WZ;z++){
                p = py+iFrom*4;
                if( iTo - iFrom <  VEC_THRESHOLD){
                    for(i = iFrom; i<iTo; i++,p+=4){
                        if(p[3]!=0) continue;
                        zr = z_r[i]; zi = z_i[i];
                        cr = c_r[i]; ci = c_i[y];
                        for(int zz = z;zz<WZ;zz++){
                            r2 = zr*zr;
                            i2 = zi*zi;
                            if(r2+i2>4){
                                putZ(p, zz);
                                p[3] = 255;
                                break;
                            }
                            zi = 2*zr*zi + ci;
                            zr = r2 - i2 + cr;
                        }
                        if(p[3]==0) p[3] = 255;
                    }
                    break;
                }else{
                    vDSP_vsqD(z_r+iFrom, 1, zr2+iFrom, 1, iTo-iFrom);
                    vDSP_vsqD(z_i+iFrom, 1, zi2+iFrom, 1, iTo-iFrom);
                    vDSP_vaddsubD(zi2+iFrom, 1, zr2+iFrom, 1, tmp+iFrom, 1, tmp2 = tmp + sx, 1, iTo-iFrom);
                    push_back = TRUE;
                    iLast = iTo;
                    for(i=iFrom;i<iTo;i++,p+=4){
                        if(p[3]==0){
                            if(tmp[i]>4.0){
                                if(push_back) { iFrom++; tmp2++; }
                                putZ(p, z);
                                p[3]=255;
                            }else{
                                push_back = FALSE;
                                iLast = i+1;
                            }
                        }
                    }
                    iTo = iLast;
                    if(iTo==iFrom) break;
                    vDSP_vmulD(z_r+iFrom, 1, z_i+iFrom, 1, tmp, 1, iTo-iFrom);
                    vDSP_vsmulD(tmp, 1, &two, tmp, 1, iTo-iFrom);
                    vDSP_vsaddD(tmp, 1, &c_i[y], z_i+iFrom, 1, iTo-iFrom);
                    vDSP_vaddD(tmp2, 1, c_r+iFrom, 1, z_r+iFrom, 1, iTo-iFrom);
                }
            }
        }
        CGDataProviderRef provider = CGDataProviderCreateWithData(nil, ptr ,WX*WY*4,nil);
        CGImageRef image = CGImageCreate(WX, WY, 8, 32, WX*4, colorSpace, kCGImageAlphaLast | kCGBitmapByteOrder32Big
                                         ,provider, NULL, FALSE, kCGRenderingIntentDefault);
        stop = update(image);
        CGImageRelease(image);
        CGDataProviderRelease(provider);
        if(stop){
            NSLog(@"Stopped");
            free(ptr);
            goto abort;
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
    [Bridge setLastImage:image];
    CGImageRelease(image);
    CGDataProviderRelease(provider);
    if(WZ>100){
        [Bridge calcStartStop:TRUE time:finish_calc()];
    }
abort:
    free(base);
    free(c_i);free(c_r);
}

void calc_mas_line(long WX,long WY,long WZ,double X0,double Y0,double Scale,BOOL (^update)(CGImageRef)){
    colorMode = (int)[Bridge getColorMode];
    colorOffset = [Bridge getColorHue];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    start_calc();
    if(WZ > 100){
        [Bridge calcStartStop:FALSE time:0.0];
    }
    
    int iFrom,iTo;
    int x,y,z,i;
    float cr,ci,zr,zi,r2,i2;
    BOOL stop = false;
    float two = 2.0;
    long len = WX*WY;
    unsigned char* ptr = malloc(len * 4);
    memset(ptr, 0, len*4);
    unsigned char* p,*py;
    size_t SX = align16(WX*sizeof(float));
    size_t sx = SX/sizeof(float);
    size_t SY = WY*sizeof(float);
    
    float* c_r = malloc(SX);
    float* c_i = malloc(SY);
    float* base = malloc(SX*6);
    float* tmp = base;
    float* tmp2 = base + sx;
    float* z_r = base + sx*2;
    float* z_i = base + sx*3;
    float* zr2 = base + sx*4;
    float* zi2 = base + sx*5;
    
    for(x = 0;x<WX;x++){
        c_r[x] = X0 + Scale *(float)x;
    }
    for(y = 0;y<WY;y++){
        c_i[y] = Y0 - Scale *(float)y;
    }
    BOOL push_back;
    int iLast;
    int yStep = 16;
    for(int yy=0;yy < yStep;yy++){
        for(y = yy;y<WY;y+=yStep){
            py = ptr+y*WX*4;
            memcpy(z_r,c_r,SX);
            for(i = 0;i<WX;i++) z_i[i] = c_i[y];
            iFrom = 0;
            iTo = (int)WX;
            
            for(z = 1;z<WZ;z++){
                p = py+iFrom*4;
                if( iTo - iFrom <  VEC_THRESHOLD){
                    for(i = iFrom; i<iTo; i++,p+=4){
                        if(p[3]!=0) continue;
                        zr = z_r[i]; zi = z_i[i];
                        cr = c_r[i]; ci = c_i[y];
                        for(int zz = z;zz<WZ;zz++){
                            r2 = zr*zr;
                            i2 = zi*zi;
                            if(r2+i2>4){
                                putZ(p, zz);
                                p[3] = 255;
                                break;
                            }
                            zi = 2*zr*zi + ci;
                            zr = r2 - i2 + cr;
                        }
                        if(p[3]==0) p[3] = 255;
                    }
                    break;
                }else{
                    vDSP_vsq(z_r+iFrom, 1, zr2+iFrom, 1, iTo-iFrom);
                    vDSP_vsq(z_i+iFrom, 1, zi2+iFrom, 1, iTo-iFrom);
                    vDSP_vaddsub(zi2+iFrom, 1, zr2+iFrom, 1, tmp+iFrom, 1, tmp2 = tmp + sx, 1, iTo-iFrom);
                    push_back = TRUE;
                    iLast = iTo;
                    for(i=iFrom;i<iTo;i++,p+=4){
                        if(p[3]==0){
                            if(tmp[i]>4.0){
                                if(push_back) { iFrom++; tmp2++; }
                                putZ(p, z);
                                p[3]=255;
                            }else{
                                push_back = FALSE;
                                iLast = i+1;
                            }
                        }
                    }
                    iTo = iLast;
                    if(iTo==iFrom) break;
                    vDSP_vmul(z_r+iFrom, 1, z_i+iFrom, 1, tmp, 1, iTo-iFrom);
                    vDSP_vsmul(tmp, 1, &two, tmp, 1, iTo-iFrom);
                    vDSP_vsadd(tmp, 1, &c_i[y], z_i+iFrom, 1, iTo-iFrom);
                    vDSP_vadd(tmp2, 1, c_r+iFrom, 1, z_r+iFrom, 1, iTo-iFrom);
                }
            }
        }
        CGDataProviderRef provider = CGDataProviderCreateWithData(nil, ptr ,WX*WY*4,nil);
        CGImageRef image = CGImageCreate(WX, WY, 8, 32, WX*4, colorSpace, kCGImageAlphaLast | kCGBitmapByteOrder32Big
                                         ,provider, NULL, FALSE, kCGRenderingIntentDefault);
        stop = update(image);
        CGImageRelease(image);
        CGDataProviderRelease(provider);
        if(stop){
            NSLog(@"Stopped");
            free(ptr);
            goto abort;
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
    [Bridge setLastImage:image];
    CGImageRelease(image);
    CGDataProviderRelease(provider);
    if(WZ>100){
        [Bridge calcStartStop:TRUE time:finish_calc()];
    }
abort:
    free(base);
    free(c_i);free(c_r);
}
