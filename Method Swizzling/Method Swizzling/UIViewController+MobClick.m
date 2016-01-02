//
//  UIViewController+MobClick.m
//  Method Swizzling
//
//  Created by sky on 16/1/2.
//  Copyright © 2016年 bluesky. All rights reserved.
//

#import "UIViewController+MobClick.h"
#import <objc/runtime.h>
#import "MobClick.h"

/**
 *  通过 method swizzling 实现每个页面友盟统计
 */

@implementation UIViewController (MobClick)

/**
 *  在load中实现 类在被加载时会被调用，必然会走保证被调用，
 *  另外 子类、父类、分类的+load方法的实现是区别对待的，即 runtime自动调用+load方法时
 *  分类中的 +load方法并不会对主类中的+load方法造成覆盖
 */
+ (void)load {
    /**
     *  采用 dispatch_once 避免坑的同学 对+load方法手动调用
     */
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(mob_viewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL addMethodResult = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (addMethodResult) {
            /**
             *  主类本身没有实现需要替换的方法，而是继承了父类的实现，此时使用class_getInstanceMethod获取的 originalMethod 指向的是父类的方法
             *  采用下面方式将 父类的实现替换为 自定义的 swizzledSelector，
             *  这样就达到在 swizzledSelector方法的实现中调用父类实现的目的
             */
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            /**
             *  主类本身有实现需要替换的方法时  直接交换连个方法的实现
             */
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

#pragma mark -- will swizzled method
- (void)mob_viewWillAppear:(BOOL)animated {
    [self mob_viewWillAppear:animated];
    
    NSLog(@"Mobclick log");
    [MobClick beginLogPageView:NSStringFromClass([self class])];
}

@end
