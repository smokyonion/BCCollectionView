//  Created by Pieter Omvlee on 25/11/2010.
//  Copyright 2010 Bohemian Coding. All rights reserved.

#import "BCCollectionView+Mouse.h"
#import "BCGeometryExtensions.h"
#import "BCCollectionView+Dragging.h"
#import "BCCollectionViewLayoutManager.h"

@implementation BCCollectionView (BCCollectionView_Mouse)

- (BOOL)shiftOrCommandKeyPressed
{
  return [NSEvent modifierFlags] & NSShiftKeyMask || [NSEvent modifierFlags] & NSCommandKeyMask;
}

- (void)mouseDown:(NSEvent *)theEvent
{
  [[self window] makeFirstResponder:self];
  
  isDragging           = YES;
  mouseDownLocation    = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  mouseDraggedLocation = mouseDownLocation;
  NSUInteger index     = [layoutManager indexOfItemContentRectAtPoint:mouseDownLocation];
  
  if (index != NSNotFound && [delegate respondsToSelector:@selector(collectionView:didClickItem:withViewController:)])
    [delegate collectionView:self didClickItem:[contentArray objectAtIndex:index] withViewController:[visibleViewControllers objectForKey:[NSNumber numberWithInt:index]]];
  
  if (![self shiftOrCommandKeyPressed] && ![selectionIndexes containsIndex:index])
    [self deselectAllItems];
  
  self.originalSelectionIndexes = [[selectionIndexes copy] autorelease];
  
  if ([theEvent clickCount] == 2 && [delegate respondsToSelector:@selector(collectionView:didDoubleClickViewControllerAtIndex:)])
    [delegate collectionView:self didDoubleClickViewControllerAtIndex:[visibleViewControllers objectForKey:[NSNumber numberWithInt:index]]];
  
  if ([self shiftOrCommandKeyPressed] && [self.originalSelectionIndexes containsIndex:index])
    [self deselectItemAtIndex:index];
  else
    [self selectItemAtIndex:index];
}

- (void)regularMouseDragged:(NSEvent *)anEvent
{
  [self deselectAllItems];
  if ([self shiftOrCommandKeyPressed]) {
    [self.originalSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
      [self selectItemAtIndex:idx];
    }];
  }
  [self setNeedsDisplayInRect:BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation)];
  
  mouseDraggedLocation = [self convertPoint:[anEvent locationInWindow] fromView:nil];
  NSIndexSet *suggestedIndexes = [self indexesOfItemContentRectsInRect:BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation)];
  
  if (![self shiftOrCommandKeyPressed]) {
    NSMutableIndexSet *oldIndexes = [[selectionIndexes mutableCopy] autorelease];
    [oldIndexes removeIndexes:suggestedIndexes];
    [self deselectItemsAtIndexes:oldIndexes];
  }
  
  [suggestedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
    if ([self shiftOrCommandKeyPressed]) {
      if ([originalSelectionIndexes containsIndex:idx])
        [self deselectItemAtIndex:idx];
      else
        [self selectItemAtIndex:idx];
    } else
      [self selectItemAtIndex:idx];
  }];
  
  [self setNeedsDisplayInRect:BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation)];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
  if (isDragging) {
    NSUInteger index = [layoutManager indexOfItemContentRectAtPoint:mouseDownLocation];
    if (index != NSNotFound && [selectionIndexes count] > 0 && [self delegateSupportsDragForItemsAtIndexes:selectionIndexes]) {
      NSPoint mouse = [self convertPoint:[theEvent locationInWindow] fromView:nil];
      CGFloat distance = sqrt(pow(mouse.x-mouseDownLocation.x,2)+pow(mouse.y-mouseDownLocation.y,2));
      if (distance > 3)
        [self initiateDraggingSessionWithEvent:theEvent];
    } else
      [self regularMouseDragged:theEvent];
  }
}

- (void)mouseUp:(NSEvent *)theEvent
{
  [self setNeedsDisplayInRect:BCRectFromTwoPoints(mouseDownLocation, mouseDraggedLocation)];
  
  mouseDownLocation    = NSZeroPoint;
  mouseDraggedLocation = NSZeroPoint;
  
  isDragging = NO;
  self.originalSelectionIndexes = nil;
}

@end
