//
//  StructureController+UICollectionView.swift
//  CollectionCollectionStructured
//
//  Created by Vitaliy Kuzmenko on 02.12.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

import UIKit

extension StructureController {
    
    internal func performCollectionViewReload(_ collectionView: UICollectionView, diff: StructureDiffer, animation: CollectionAnimationRule) {
            
        var hasher = Hasher()
        hasher.combine(Date())
        
        currentCollectionReloadingHasher = hasher
        
        collectionView.performBatchUpdates({
            
            for movement in diff.sectionsToMove {
                collectionView.moveSection(movement.from, toSection: movement.to)
            }
            
            collectionView.deleteSections(diff.sectionsToDelete)
            
            collectionView.insertSections(diff.sectionsToInsert)
            
            for movement in diff.rowsToMove {
                collectionView.moveItem(at: movement.from, to: movement.to)
            }
            
            collectionView.deleteItems(at: diff.rowsToDelete)
            
            collectionView.insertItems(at: diff.rowsToInsert)
            
        }, completion: { _ in
            
            guard !self.shouldReload else {
                collectionView.reloadData()
                self.shouldReload = false
                return
            }
            
            guard hasher.finalize() == self.currentCollectionReloadingHasher?.finalize() else {
                self.shouldReload = true
                return
            }
            
            if !diff.rowsToReload.isEmpty {
                if !animation.update {
                    UIView.setAnimationsEnabled(false)
                }
                
                collectionView.reloadItems(at: diff.rowsToReload)
                
                if !animation.update {
                    UIView.setAnimationsEnabled(true)
                }
            }
            
            if !diff.sectionHeadersToReload.isEmpty {
                diff.sectionHeadersToReload.forEach { index in
                    if let header = self.structure[index].header, let headerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: index)) {
                        switch header {
                        case .view(let viewModel):
                            viewModel._configure(collectionViewReusableSupplementaryView: headerView, isUpdating: true)
                        default:
                            break
                        }
                    }
                }
            }
            
            if !diff.sectionFootersToReload.isEmpty {
                diff.sectionFootersToReload.forEach { index in
                    if let footer = self.structure[index].footer, let footerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: index)) {
                        switch footer {
                        case .view(let viewModel):
                            viewModel._configure(collectionViewReusableSupplementaryView: footerView, isUpdating: true)
                        default:
                            break
                        }
                    }
                }
            }
        })
        
        DispatchQueue.main.async {
            
        }
        
    }
    
}

extension StructureController: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return structure.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return structure[section].rows.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let model = cellModel(at: indexPath) as? Structurable else { fatalError("Model should be Structurable") }
        let indetifier = type(of: model).reuseIdentifierForCollectionView()
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: indetifier, for: indexPath)
        model._configure(collectionViewCell: cell)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let entity: StructureSection.HeaderFooter?
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            entity = structure[indexPath.section].header
        case UICollectionView.elementKindSectionFooter:
            entity = structure[indexPath.section].footer
        default:
            return UICollectionReusableView()
        }
        if let entity = entity {
            switch entity {
            case .view(let viewModel):
                let identifier = type(of: viewModel).reuseIdentifierForCollectionReusableSupplementaryView()
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath)
                viewModel._configure(collectionViewReusableSupplementaryView: view, isUpdating: false)
                return view
            default:
                print("StructureController: UICollectionView is not support title for header")
                return UICollectionReusableView()
            }
        } else {
            return UICollectionReusableView()
        }
    }
    
    // MARK: - Move
    
    @available(iOS 9.0, *)
    public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if let model = cellModel(at: indexPath) as? StructurableMovable {
            return model.canMove
        } else {
            return false
        }
    }
    
    @available(iOS 9.0, *)
    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let model = cellModel(at: sourceIndexPath) as? StructurableMovable,
            let sModel = cellModel(at: sourceIndexPath) as? Structurable,
            let castModel = cellCast(at: sourceIndexPath) {
            structure[sourceIndexPath.section].rows.remove(at: sourceIndexPath.item)
            structure[destinationIndexPath.section].rows.insert(sModel, at: destinationIndexPath.item)
            structureCast[sourceIndexPath.section].rows.remove(at: sourceIndexPath.item)
            structureCast[destinationIndexPath.section].rows.insert(castModel, at: destinationIndexPath.item)
            model.didMove?(sourceIndexPath, destinationIndexPath)
        }
    }
    
}

extension StructureController: UICollectionViewDelegateFlowLayout {
    
    fileprivate var collectionViewDeleagteFlowLayout: UICollectionViewDelegateFlowLayout? {
        return collectionViewDelegate as? UICollectionViewDelegateFlowLayout
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionViewDeleagteFlowLayout?.responds(to: #selector(collectionView(_:layout:sizeForItemAt:))) == true,
            let value = collectionViewDeleagteFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath) {
            return value
        } else if let object = self.cellModel(at: indexPath) as? StructurableSizable {
            return object.size(for: collectionView)
        } else {
            return (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize ?? .zero
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionViewDeleagteFlowLayout?.responds(to: #selector(collectionView(_:layout:insetForSectionAt:))) == true,
            let value = collectionViewDeleagteFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, insetForSectionAt: section) {
            return value
        } else {
            return (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionViewDeleagteFlowLayout?.responds(to: #selector(collectionView(_:layout:minimumLineSpacingForSectionAt:))) == true,
            let value = collectionViewDeleagteFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, minimumLineSpacingForSectionAt: section) {
            return value
        } else {
            return (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing ?? .zero
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionViewDeleagteFlowLayout?.responds(to: #selector(collectionView(_:layout:minimumInteritemSpacingForSectionAt:))) == true,
            let value = collectionViewDeleagteFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: section) {
            return value
        } else {
            return (collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? .zero
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if collectionViewDeleagteFlowLayout?.responds(to: #selector(collectionView(_:layout:referenceSizeForHeaderInSection:))) == true,
            let value = collectionViewDeleagteFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section) {
            return value
        } else if let header = structure[section].header {
            switch header {
            case .view(let viewModel):
                if let viewModel = viewModel as? StructurableSizable {
                    return viewModel.size(for: collectionView)
                } else {
                    return .zero
                }
            default:
                return .zero
            }
        } else {
            return .zero
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if collectionViewDeleagteFlowLayout?.responds(to: #selector(collectionView(_:layout:referenceSizeForFooterInSection:))) == true,
            let value = collectionViewDeleagteFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, referenceSizeForFooterInSection: section) {
            return value
        } else if let footer = structure[section].footer {
            switch footer {
            case .view(let viewModel):
                if let viewModel = viewModel as? StructurableSizable {
                    return viewModel.size(for: collectionView)
                } else {
                    return .zero
                }
            default:
                return .zero
            }
        } else {
            return .zero
        }
    }
    
}

extension StructureController: UICollectionViewDelegate {
    
    // MARK: - Highlighting
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldHighlightItemAt:))) == true,
            let shouldHighlight = collectionViewDelegate?.collectionView?(collectionView, shouldHighlightItemAt: indexPath) {
            return shouldHighlight
        } else if let object = self.cellModel(at: indexPath) as? StructurableHighlightable {
            return object.shouldHighlight
        } else {
            return true
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didHighlightItemAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didHighlightItemAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructurableHighlightable, let cell = collectionView.cellForItem(at: indexPath) {
            object.didHighlight?(cell)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didUnhighlightItemAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didUnhighlightItemAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructurableHighlightable, let cell = collectionView.cellForItem(at: indexPath) {
            object.didUnhighlight?(cell)
        }
    }
    
    // MARK: - Selection
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldSelectItemAt:))) == true,
            let shouldSelect = collectionViewDelegate?.collectionView?(collectionView, shouldSelectItemAt: indexPath) {
            return shouldSelect
        } else if let object = self.cellModel(at: indexPath) as? StructurableSelectable {
            return object.shouldSelect
        } else {
            return true
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldDeselectItemAt:))) == true,
            let shouldDeselect = collectionViewDelegate?.collectionView?(collectionView, shouldDeselectItemAt: indexPath) {
            return shouldDeselect
        } else if let object = self.cellModel(at: indexPath) as? StructurableSelectable {
            return object.shouldDeselect
        } else {
            return true
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didSelectItemAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructurableSelectable, let cell = collectionView.cellForItem(at: indexPath) {
            if let deselectAnimation = object.didSelect?(cell) {
                collectionView.deselectItem(at: indexPath, animated: deselectAnimation)
            }
        }
    }
        
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didDeselectItemAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didDeselectItemAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructurableSelectable, let didDeselect = object.didDeselect  {
            let cell = collectionView.cellForItem(at: indexPath)
            didDeselect(cell)
        }
    }
    
    // MARK: - Will Display
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:willDisplay:forItemAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructurableDisplayable {
            object.willDisplay?(cell)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:willDisplaySupplementaryView:forElementKind:at:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, willDisplaySupplementaryView: view, forElementKind: elementKind, at: indexPath)
        } else {
            let entity: StructureSection.HeaderFooter?
            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                entity = structure[indexPath.section].header
            case UICollectionView.elementKindSectionFooter:
                entity = structure[indexPath.section].footer
            default:
                entity = nil
            }
            if let entity = entity {
                switch entity {
                case .view(let viewModel):
                    if let viewModel = viewModel as? StructurableDisplayable {
                        viewModel.willDisplay?(view)
                    }
                default:
                    break
                }
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didEndDisplayingSupplementaryView:forElementOfKind:at:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: elementKind, at: indexPath)
        } else {
            let entity: StructureSection.HeaderFooter?
            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                entity = header(at: indexPath.section)
            case UICollectionView.elementKindSectionFooter:
                entity = footer(at: indexPath.section)
            default:
                entity = nil
            }
            if let entity = entity {
                switch entity {
                case .view(let viewModel):
                    if let viewModel = viewModel as? StructurableDisplayable {
                        viewModel.didEndDisplay?(view)
                    }
                default:
                    break
                }
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, transitionLayoutForOldLayout fromLayout: UICollectionViewLayout, newLayout toLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:transitionLayoutForOldLayout:newLayout:))) == true,
            let transitionLayout = collectionViewDelegate?.collectionView?(collectionView, transitionLayoutForOldLayout: fromLayout, newLayout: toLayout) {
            return transitionLayout
        } else {
            return UICollectionViewTransitionLayout(currentLayout: fromLayout, nextLayout: toLayout)
        }
    }
    
    // MARK: - Did End Display
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didEndDisplaying:forItemAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructurableDisplayable {
            object.didEndDisplay?(cell)
        }
    }
    
    // MARK: - Focus
    
    public func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:canFocusItemAt:))) == true,
            let canFocus = collectionViewDelegate?.collectionView?(collectionView, canFocusItemAt: indexPath) {
            return canFocus
        } else if let object = self.cellModel(at: indexPath) as? StructurableFocusable {
            return object.canFocus?() ?? false
        } else {
            return false
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldUpdateFocusIn:))) == true,
            let shouldUpdateFocus = collectionViewDelegate?.collectionView?(collectionView, shouldUpdateFocusIn: context) {
            return shouldUpdateFocus
        } else {
            return true
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didUpdateFocusIn:with:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didUpdateFocusIn: context, with: coordinator)
        }
    }
    
    public func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        if collectionViewDelegate?.responds(to: #selector(UICollectionViewDelegate.indexPathForPreferredFocusedView(in:))) == true {
            return collectionViewDelegate?.indexPathForPreferredFocusedView?(in: collectionView)
        } else {
            return nil
        }
    }
    
    // MARK: - Moving
    
    public func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:targetIndexPathForMoveFromItemAt:toProposedIndexPath:))) == true,
            let indexPath = collectionViewDelegate?.collectionView?(collectionView, targetIndexPathForMoveFromItemAt: sourceIndexPath, toProposedIndexPath: proposedDestinationIndexPath) {
            return indexPath
        } else {
            return proposedDestinationIndexPath
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:targetContentOffsetForProposedContentOffset:))) == true,
            let indexPath = collectionViewDelegate?.collectionView?(collectionView, targetContentOffsetForProposedContentOffset: proposedContentOffset) {
            return indexPath
        } else {
            return proposedContentOffset
        }
    }
    
    // MARK: - Spring Loading
    
    #if os(iOS)
    
    @available(iOS 11.0, *)
    public func collectionView(_ collectionView: UICollectionView, shouldSpringLoadItemAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldSpringLoadItemAt:with:))) == true,
            let shouldSpringLoad = collectionViewDelegate?.collectionView?(collectionView, shouldSpringLoadItemAt: indexPath, with: context) {
            return shouldSpringLoad
        } else if let object = self.cellModel(at: indexPath) as? StructurableSpringLoadable {
            return object.shouldSpringLoad?(context) ?? false
        } else {
            return false
        }
    }
    
    // MARK: - Multiple Selection
    
    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldBeginMultipleSelectionInteractionAt:))) == true,
            let shouldSpringLoad = collectionViewDelegate?.collectionView?(collectionView, shouldBeginMultipleSelectionInteractionAt: indexPath) {
            return shouldSpringLoad
        } else if let object = self.cellModel(at: indexPath) as? StructurableMultipleSelectable {
            return object.shouldBeginMultipleSelection
        } else {
            return false
        }
    }
    
    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didBeginMultipleSelectionInteractionAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didBeginMultipleSelectionInteractionAt: indexPath)
        } else if let object = self.cellModel(at: indexPath) as? StructurableMultipleSelectable {
            object.didBeginMultipleSelection?()
        }
    }
    
    @available(iOS 13.0, *)
    public func collectionViewDidEndMultipleSelectionInteraction(_ collectionView: UICollectionView) {
        if collectionViewDelegate?.responds(to: #selector(collectionViewDidEndMultipleSelectionInteraction(_:))) == true {
            collectionViewDelegate?.collectionViewDidEndMultipleSelectionInteraction?(collectionView)
        }
    }
    
    // MARK: - Contextual menu
    
    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:contextMenuConfigurationForItemAt:point:))) == true {
            return collectionViewDelegate?.collectionView?(collectionView, contextMenuConfigurationForItemAt: indexPath, point: point)
        } else if let object = self.cellModel(at: indexPath) as? StructurableContextualMenuConfigurable {
            return object.contextMenuConfiguration?(point)
        } else {
            return nil
        }
    }
    
    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:previewForHighlightingContextMenuWithConfiguration:))) == true {
            return collectionViewDelegate?.collectionView?(collectionView, previewForHighlightingContextMenuWithConfiguration: configuration)
        } else {
            return nil
        }
    }

    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:previewForDismissingContextMenuWithConfiguration:))) == true {
            return collectionViewDelegate?.collectionView?(collectionView, previewForDismissingContextMenuWithConfiguration: configuration)
        } else {
            return nil
        }
    }

    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:willPerformPreviewActionForMenuWith:animator:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
        }
    }
    
    #endif

}
