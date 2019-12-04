//
//  StructureController+UICollectionView.swift
//  CollectionCollectionStructured
//
//  Created by Vitaliy Kuzmenko on 02.12.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import UIKit

extension StructureController {
    
    
    
}

extension StructureController: UICollectionViewDataSource {
    
    internal func numberOfSections(in collectionView: UICollectionView) -> Int {
        return structure.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return structure[section].rows.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let model = cellModel(at: indexPath) as? Structurable else { fatalError("Model should be Structurable") }
        let indetifier = type(of: model).reuseIdentifier(for: .collectionView(collectionView))
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: indetifier, for: indexPath)
        model.configureAny(cell: cell)
        return cell
    }
    
    // MARK: - Move
    
    @available(iOS 9.0, *)
    internal func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if let model = cellModel(at: indexPath) as? StructurableMovable {
            return model.canMove?() ?? false
        } else {
            return false
        }
    }
    
    @available(iOS 9.0, *)
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let model = cellModel(at: sourceIndexPath) as? StructurableMovable {
            model.didMove?(sourceIndexPath, destinationIndexPath)
        }
    }
    
}

extension StructureController: UICollectionViewDataSourcePrefetching {
        
    @available(iOS 10.0, *)
    internal func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if collectionViewDataSourcePrefetching?.responds(to: #selector(collectionView(_:prefetchItemsAt:))) == true {
            collectionViewDataSourcePrefetching?.collectionView(collectionView, prefetchItemsAt: indexPaths)
        }
    }
    
    @available(iOS 10.0, *)
    internal func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        if collectionViewDataSourcePrefetching?.responds(to: #selector(collectionView(_:cancelPrefetchingForItemsAt:))) == true {
            collectionViewDataSourcePrefetching?.collectionView?(collectionView, cancelPrefetchingForItemsAt: indexPaths)
        }
    }
    
}

extension StructureController: UICollectionViewDelegate {
    
    // MARK: - Highlighting
    
    internal func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldHighlightItemAt:))) == true, let shouldHighlight = collectionViewDelegate?.collectionView?(collectionView, shouldHighlightItemAt: indexPath) {
            return shouldHighlight
        } else if let object = self.cellModel(at: indexPath) as? StructurableHighlightable {
            return object.shouldHighlight
        } else {
            return true
        }
    }

    internal func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didHighlightItemAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didHighlightItemAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructurableHighlightable {
            object.didHighlight?()
        }
    }

    internal func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didUnhighlightItemAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didUnhighlightItemAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructurableHighlightable {
            object.didUnhighlight?()
        }
    }
    
    // MARK: - Selection
    
    internal func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldSelectItemAt:))) == true, let shouldSelect = collectionViewDelegate?.collectionView?(collectionView, shouldSelectItemAt: indexPath) {
            return shouldSelect
        } else if let object = self.cellModel(at: indexPath) as? StructurableSelectable {
            return object.shouldSelect
        } else {
            return true
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldDeselectItemAt:))) == true, let shouldDeselect = collectionViewDelegate?.collectionView?(collectionView, shouldDeselectItemAt: indexPath) {
            return shouldDeselect
        } else if let object = self.cellModel(at: indexPath) as? StructurableSelectable {
            return object.shouldDeselect
        } else {
            return true
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didSelectItemAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructurableSelectable, let cell = collectionView.cellForItem(at: indexPath) {
            if let deselectAnimation = object.didSelect?(cell) {
                collectionView.deselectItem(at: indexPath, animated: deselectAnimation)
            }
        }
    }
        
    internal func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didDeselectItemAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didDeselectItemAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructurableSelectable, let didDeselect = object.didDeselect  {
            let cell = collectionView.cellForItem(at: indexPath)
            didDeselect(cell)
        }
    }
    
    // MARK: - Will Display
    
    internal func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:willDisplay:forItemAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructureViewDisplayable {
            object.willDisplay?(cell)
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, transitionLayoutForOldLayout fromLayout: UICollectionViewLayout, newLayout toLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:transitionLayoutForOldLayout:newLayout:))) == true, let transitionLayout = collectionViewDelegate?.collectionView?(collectionView, transitionLayoutForOldLayout: fromLayout, newLayout: toLayout) {
            return transitionLayout
        } else {
            return UICollectionViewTransitionLayout(currentLayout: fromLayout, nextLayout: toLayout)
        }
    }
    
    // MARK: - Did End Display
    
    internal func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didEndDisplaying:forItemAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructureViewDisplayable {
            object.didEndDisplay?(cell)
        }
    }
    
    // MARK: - Focus
    
    internal func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:canFocusItemAt:))) == true, let canFocus = collectionViewDelegate?.collectionView?(collectionView, canFocusItemAt: indexPath) {
            return canFocus
        } else if let object = self.cellModel(at: indexPath) as? StructurableFocusable {
            return object.canFocus?() ?? false
        } else {
            return false
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldUpdateFocusIn:))) == true, let shouldUpdateFocus = collectionViewDelegate?.collectionView?(collectionView, shouldUpdateFocusIn: context) {
            return shouldUpdateFocus
        } else {
            return true
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didUpdateFocusIn:with:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didUpdateFocusIn: context, with: coordinator)
        }
    }
    
    internal func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        if collectionViewDelegate?.responds(to: #selector(UICollectionViewDelegate.indexPathForPreferredFocusedView(in:))) == true {
            return collectionViewDelegate?.indexPathForPreferredFocusedView?(in: collectionView)
        } else {
            return nil
        }
    }
    
    // MARK: - Moving
    
    internal func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:targetIndexPathForMoveFromItemAt:toProposedIndexPath:))) == true, let indexPath = collectionViewDelegate?.collectionView?(collectionView, targetIndexPathForMoveFromItemAt: sourceIndexPath, toProposedIndexPath: proposedDestinationIndexPath) {
            return indexPath
        } else {
            return proposedDestinationIndexPath
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:targetContentOffsetForProposedContentOffset:))) == true, let indexPath = collectionViewDelegate?.collectionView?(collectionView, targetContentOffsetForProposedContentOffset: proposedContentOffset) {
            return indexPath
        } else {
            return proposedContentOffset
        }
    }
    
    // MARK: - Spring Loading
    
    @available(iOS 11.0, *)
    internal func collectionView(_ collectionView: UICollectionView, shouldSpringLoadItemAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldSpringLoadItemAt:with:))) == true, let shouldSpringLoad = collectionViewDelegate?.collectionView?(collectionView, shouldSpringLoadItemAt: indexPath, with: context) {
            return shouldSpringLoad
        } else if let object = self.cellModel(at: indexPath) as? StructurableSpringLoadable {
            return object.shouldSpringLoad?(context) ?? false
        } else {
            return false
        }
    }
    
    // MARK: - Multiple Selection
    
    @available(iOS 13.0, *)
    internal func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldBeginMultipleSelectionInteractionAt:))) == true, let shouldSpringLoad = collectionViewDelegate?.collectionView?(collectionView, shouldBeginMultipleSelectionInteractionAt: indexPath) {
            return shouldSpringLoad
        } else if let object = self.cellModel(at: indexPath) as? StructurableMultipleSelectable {
            return object.shouldBeginMultipleSelection
        } else {
            return false
        }
    }
    
    @available(iOS 13.0, *)
    internal func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didBeginMultipleSelectionInteractionAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didBeginMultipleSelectionInteractionAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructurableMultipleSelectable {
            object.didBeginMultipleSelection?()
        }
    }
    
    @available(iOS 13.0, *)
    internal func collectionViewDidEndMultipleSelectionInteraction(_ collectionView: UICollectionView) {
        if collectionViewDelegate?.responds(to: #selector(collectionViewDidEndMultipleSelectionInteraction(_:))) == true {
            collectionViewDelegate?.collectionViewDidEndMultipleSelectionInteraction?(collectionView)
        }
    }
    
    // MARK: - Contextual menu
    
    @available(iOS 13.0, *)
    internal func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:contextMenuConfigurationForItemAt:point:))) == true {
            return collectionViewDelegate?.collectionView?(collectionView, contextMenuConfigurationForItemAt: indexPath, point: point)
        } else if let object = self.cellModel(at: indexPath) as? StructurableContextualMenuConfigurable {
            return object.contextMenuConfiguration?(point)
        } else {
            return nil
        }
    }
    
    @available(iOS 13.0, *)
    internal func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:previewForHighlightingContextMenuWithConfiguration:))) == true {
            return collectionViewDelegate?.collectionView?(collectionView, previewForHighlightingContextMenuWithConfiguration: configuration)
        } else {
            return nil
        }
    }

    @available(iOS 13.0, *)
    internal func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:previewForDismissingContextMenuWithConfiguration:))) == true {
            return collectionViewDelegate?.collectionView?(collectionView, previewForDismissingContextMenuWithConfiguration: configuration)
        } else {
            return nil
        }
    }

    @available(iOS 13.0, *)
    internal func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:willPerformPreviewActionForMenuWith:animator:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
        }
    }

}
