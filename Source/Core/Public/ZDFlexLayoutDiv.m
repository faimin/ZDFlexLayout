//
//  ZDFlexLayoutDiv.m
//  Demo
//
//  Created by Zero.D.Saber on 2019/10/11.
//  Copyright © 2019 Zero.D.Saber. All rights reserved.
//

#import "ZDFlexLayoutDiv.h"
#import <objc/runtime.h>
#import "ZDFlexLayout+Private.h"

@implementation ZDFlexLayoutDiv
@synthesize flexLayout = _flexLayout, layoutFrame = _layoutFrame, parent = _parent, children = _children, owningView = _owningView, isRoot = _isRoot, isNeedLayoutChildren = _isNeedLayoutChildren;

#pragma mark - ZDFlexLayoutNodeProtocol

- (BOOL)isFlexLayoutEnabled {
    return _flexLayout != nil;
}

- (void)configureFlexLayoutWithBlock:(void (NS_NOESCAPE ^)(ZDFlexLayout * _Nonnull))block {
    if (block) {
        block(self.flexLayout);
    }
}

- (void)addChild:(ZDFlexLayoutView)child {
    if (![child conformsToProtocol:@protocol(ZDFlexLayoutViewProtocol)]) {
        NSCAssert1(NO, @"don't support the type：%@", child);
        return;
    }
    
    [self.children removeObjectIdenticalTo:child];
    [self.children addObject:child];
    child.parent = self;
    
    [self addChildSubviews:child];
}

- (void)removeChild:(ZDFlexLayoutView)child {
    if (![child conformsToProtocol:@protocol(ZDFlexLayoutViewProtocol)]) {
        NSCAssert1(NO, @"don't support the type：%@", child);
        return;
    }
    
    [self.children removeObjectIdenticalTo:child];
    
    if ([child isKindOfClass:UIView.class]) {
        [(UIView *)child removeFromSuperview];
    }
    else {
        [child.children enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ZDFlexLayoutView  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [child removeChild:obj];
        }];
    }
    
    child.parent = nil;
}

- (void)addChildren:(NSArray<ZDFlexLayoutView> *)children {
    for (ZDFlexLayoutView view in children) {
        [self addChild:view];
    }
}

- (void)removeChildren:(NSArray<ZDFlexLayoutView> *)children {
    for (ZDFlexLayoutView view in children) {
        [self removeChild:view];
    }
}

- (void)insertChild:(ZDFlexLayoutView)child atIndex:(NSInteger)index {
    if (![child conformsToProtocol:@protocol(ZDFlexLayoutViewProtocol)]) {
        NSCAssert1(NO, @"don't support the type：%@", child);
        return;
    }
    
    [self.children removeObjectIdenticalTo:child];
    NSInteger mapedIndex = index; // realIndex
    if (index > self.children.count || index < 0) {
        mapedIndex = self.children.count;
    }
    [self.children insertObject:child atIndex:mapedIndex];
    child.parent = self;
    child.owningView = _owningView;
    
    if ([child isKindOfClass:UIView.class]) {
        [_owningView insertSubview:(UIView *)child atIndex:mapedIndex];
    }
    else {
        for (ZDFlexLayoutView childChild in child.children) {
            childChild.owningView = child.owningView;
            if ([childChild isKindOfClass:UIView.class]) {
                [_owningView insertSubview:(UIView *)childChild atIndex:mapedIndex++];
            }
        }
    }
}

- (void)removeFromParent {
    if (self.parent) {
        [self.parent removeChild:self];
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeZero;
}

- (void)notifyRootNeedsLayout {
    if (self.isRoot && self.isNeedLayoutChildren) {
        return;
    }
    
    if (self.isRoot && !self.isNeedLayoutChildren) {
        self.isNeedLayoutChildren = YES;
    }
    else if (self.parent) {
        [self.parent notifyRootNeedsLayout];
    }
}

//MARK: Property
- (void)setOwningView:(UIView *)owningView {
    if (_owningView != owningView) {
        _owningView = owningView;
        
        if (!owningView) {
            return;
        }
        for (ZDFlexLayoutView child in self.children) {
            [self addChildSubviews:child];
        }
    }
}

- (ZDFlexLayout *)flexLayout {
    if (!_flexLayout) {
        _flexLayout = [[ZDFlexLayout alloc] initWithView:self];
        _flexLayout.isEnabled = YES;
    }
    return _flexLayout;
}

- (NSMutableArray<ZDFlexLayoutView> *)children {
    if (!_children) {
        _children = @[].mutableCopy;
    }
    return _children;
}

- (void)setGone:(BOOL)gone {
    self.flexLayout.isIncludedInLayout = !gone;
    [self setView:self hidden:gone];
    objc_setAssociatedObject(self, @selector(gone), @(gone), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self notifyRootNeedsLayout];
}

- (BOOL)gone {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

#pragma mark - Private Method

- (void)setView:(ZDFlexLayoutView)view hidden:(BOOL)hidden {
    if ([view respondsToSelector:@selector(setHidden:)]) {
        [(UIView *)view setHidden:hidden];
    }
    else {
        for (ZDFlexLayoutView child in view.children) {
            if ([child respondsToSelector:@selector(setHidden:)]) {
                [(UIView *)child setHidden:hidden];
            }
            else {
                [self setView:child hidden:hidden];
            }
        }
    }
}

- (void)addChildSubviews:(ZDFlexLayoutView)child {
    if (!child || !_owningView) {
        return;
    }
    
    child.owningView = _owningView;
    
    if ([child isKindOfClass:UIView.class]) {
        [_owningView addSubview:(UIView *)child];
    }
    else {
        for (ZDFlexLayoutView childChild in child.children) {
            childChild.owningView = child.owningView;
            if ([childChild isKindOfClass:UIView.class]) {
                [_owningView addSubview:(UIView *)childChild];
            }
        }
    }
}

@end
