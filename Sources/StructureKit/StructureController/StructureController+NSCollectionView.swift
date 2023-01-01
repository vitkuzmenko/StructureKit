//
//  StructureController+NSCollectionView.swift
//  CollectionCollectionStructured
//
//  Created by Vitaliy Kuzmenko on 02.12.2019.
//  Copyright © 2019 Vitaliy Kuzmenko. All rights reserved.
//

#if os(macOS)
import Cocoa

extension StructureController {
    
    internal func performCollectionViewReload(_ collectionView: NSCollectionView, diff: StructureDiffer, animation: CollectionAnimationRule) {
            
        var hasher = Hasher()
        hasher.combine(Date())
        
        currentCollectionReloadingHasher = hasher
        
        collectionView.animator().performBatchUpdates({
            
            for movement in diff.sectionsToMove {
                collectionView.moveSection(movement.from, toSection: movement.to)
            }
            
            collectionView.deleteSections(diff.sectionsToDelete)
            
            collectionView.insertSections(diff.sectionsToInsert)
            
            for movement in diff.rowsToMove {
                collectionView.moveItem(at: movement.from, to: movement.to)
            }
            
            collectionView.deleteItems(at: Set(diff.rowsToDelete))
            
            collectionView.insertItems(at: Set(diff.rowsToInsert))
            
            if animation.update {
                collectionView.reloadItems(at: Set(diff.rowsToReload))
            } else {
                collectionView.reloadItems(at: Set(diff.rowsToReload))
            }
            
        }, completionHandler: { _ in
            
//            guard !self.shouldReload else {
//                collectionView.reloadData()
//                self.shouldReload = false
//                return
//            }
//
//            guard hasher.finalize() == self.currentCollectionReloadingHasher?.finalize() else {
//                self.shouldReload = true
//                return
//            }
            
            if !diff.sectionHeadersToReload.isEmpty {
                diff.sectionHeadersToReload.forEach { index in
                    if let header = self.structure[index].header, let headerView = collectionView.supplementaryView(forElementKind: NSCollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: index)) {
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
                    if let footer = self.structure[index].footer, let footerView = collectionView.supplementaryView(forElementKind: NSCollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: index)) {
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

extension StructureController: NSCollectionViewDataSource {
    
    public func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return structure.count
    }
    
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return structure[section].rows.count
    }
    
    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let model = cellModel(at: indexPath) as? Structurable else { fatalError("Model should be Structurable") }
        let indetifier = type(of: model).reuseIdentifierForCollectionView()
        let cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: indetifier), for: indexPath)
        model._configure(collectionViewCell: cell)
        return cell
    }
    
    public func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
            let entity: StructureSection.HeaderFooter?
            switch kind {
            case NSCollectionView.elementKindSectionHeader:
                entity = structure[indexPath.section].header
            case NSCollectionView.elementKindSectionFooter:
                entity = structure[indexPath.section].footer
            default:
                return NSView()
            }
            if let entity = entity {
                switch entity {
                case .view(let viewModel):
                    let identifier = type(of: viewModel).reuseIdentifierForCollectionReusableSupplementaryView()
                    let view = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier), for: indexPath)
                    viewModel._configure(collectionViewReusableSupplementaryView: view, isUpdating: false)
                    return view
                default:
                    print("StructureController: NSCollectionView is not support title for header")
                    return NSView()
                }
            } else {
                return NSView()
            }
    }
    
}
//
extension StructureController: NSCollectionViewDelegateFlowLayout {

    fileprivate var collectionViewDeleagteFlowLayout: NSCollectionViewDelegateFlowLayout? {
        return collectionViewDelegate as? NSCollectionViewDelegateFlowLayout
    }

    public func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionViewDeleagteFlowLayout?.responds(to: #selector(collectionView(_:layout:sizeForItemAt:))) == true,
            let value = collectionViewDeleagteFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath) {
            return value
        } else if let object = self.cellModel(at: indexPath) as? StructurableSizable {
            return object.size(for: collectionView)
        } else {
            return (collectionViewLayout as? NSCollectionViewFlowLayout)?.itemSize ?? .zero
        }
    }

    public func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, insetForSectionAt section: Int) -> NSEdgeInsets {
        if collectionViewDeleagteFlowLayout?.responds(to: #selector(collectionView(_:layout:insetForSectionAt:))) == true,
            let value = collectionViewDeleagteFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, insetForSectionAt: section) {
            return value
        } else {
            return (collectionViewLayout as? NSCollectionViewFlowLayout)?.sectionInset ?? NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }

    public func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionViewDeleagteFlowLayout?.responds(to: #selector(collectionView(_:layout:minimumLineSpacingForSectionAt:))) == true,
            let value = collectionViewDeleagteFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, minimumLineSpacingForSectionAt: section) {
            return value
        } else {
            return (collectionViewLayout as? NSCollectionViewFlowLayout)?.minimumLineSpacing ?? .zero
        }
    }

    public func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionViewDeleagteFlowLayout?.responds(to: #selector(collectionView(_:layout:minimumInteritemSpacingForSectionAt:))) == true,
            let value = collectionViewDeleagteFlowLayout?.collectionView?(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: section) {
            return value
        } else {
            return (collectionViewLayout as? NSCollectionViewFlowLayout)?.minimumInteritemSpacing ?? .zero
        }
    }

    public func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
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

    public func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
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
//
extension StructureController: NSCollectionViewDelegate {

    // MARK: - Selection
    
    public func collectionView(_ collectionView: NSCollectionView, shouldSelectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldSelectItemsAt:))) == true,
            let shouldSelect = collectionViewDelegate?.collectionView?(collectionView, shouldSelectItemsAt: indexPaths) {
            return shouldSelect
        } else {
            let values = indexPaths
                .compactMap { cellModel(at: $0) as? StructurableSelectable }
                .filter { $0.shouldSelect }
                .compactMap { $0 as? StructurableIdentifable }
                .compactMap { indexPath(for: $0) }
            return Set(values)
        }
    }
    
    public func collectionView(_ collectionView: NSCollectionView, shouldDeselectItemsAt indexPaths: Set<IndexPath>) -> Set<IndexPath> {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:shouldDeselectItemsAt:))) == true,
            let shouldDeselect = collectionViewDelegate?.collectionView?(collectionView, shouldDeselectItemsAt: indexPaths) {
            return shouldDeselect
        } else {
            let values = indexPaths
                .compactMap { cellModel(at: $0) as? StructurableSelectable }
                .filter { $0.shouldDeselect }
                .compactMap { $0 as? StructurableIdentifable }
                .compactMap { indexPath(for: $0) }
            return Set(values)
        }
    }

    public func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didSelectItemsAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didSelectItemsAt: indexPaths)
        } else {
            
            let toDeselect = indexPaths
                .compactMap { cellModel(at: $0) as? StructurableSelectable }
                .filter { object in
                    object.didSelect?() == true
                }
                .compactMap { $0 as? StructurableIdentifable }
                .compactMap { indexPath(for: $0) }
            
            if !toDeselect.isEmpty {
                collectionView.deselectItems(at: Set(toDeselect))
            }
        }
    }
    
    public func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        if collectionViewDelegate?.responds(to: #selector(collectionView(_:didDeselectItemsAt:))) == true {
            collectionViewDelegate?.collectionView?(collectionView, didDeselectItemsAt: indexPaths)
        } else {
            indexPaths
                .forEach {
                    if let object = cellModel(at: $0) as? StructurableSelectable {
                        object.didDeselect?()
                    }
                }
        }
    }
    
    // MARK: - Drag & Drop
    
    public func collectionView(
        _ collectionView: NSCollectionView,
        canDragItemsAt indexPaths: Set<IndexPath>,
        with event: NSEvent
    ) -> Bool {
        collectionViewDelegate?.collectionView(collectionView, canDragItemsAt: canDragItemsAt, with: event) ?? false
    }
    
    func collectionView(
        _ collectionView: NSCollectionView,
        pasteboardWriterForItemAt indexPath: IndexPath
    ) -> NSPasteboardWriting? {
        collectionViewDelegate?.collectionView(collectionView, pasteboardWriterForItemAt: indexPath)
    }
    
    func collectionView(
        _ collectionView: NSCollectionView,
        validateDrop draggingInfo: NSDraggingInfo,
        proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
        dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>
    ) -> NSDragOperation {
        collectionViewDelegate?.collectionView(collectionView, validateDrop: draggingInfo, proposedIndexPath: proposedDropOperation, dropOperation: proposedDropOperation) ?? []
    }
    
    func collectionView(
        _ collectionView: NSCollectionView,
        acceptDrop draggingInfo: NSDraggingInfo,
        indexPath: IndexPath,
        dropOperation: NSCollectionView.DropOperation
    ) -> Bool {
        collectionViewDelegate?.collectionView(collectionView, acceptDrop: draggingInfo, indexPath: indexPath, dropOperation: dropOperation) ?? false
    }
    
    func collectionView(
        _ collectionView: NSCollectionView,
        draggingSession session: NSDraggingSession,
        willBeginAt screenPoint: NSPoint,
        forItemsAt indexPaths: Set<IndexPath>
    ) {
        collectionViewDelegate?.collectionView(collectionView, draggingSession: session, willBeginAt: screenPoint, forItemsAt: indexPaths)
    }
    
    func collectionView(
        _ collectionView: NSCollectionView,
        draggingSession session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        dragOperation operation: NSDragOperation
    ) {
        collectionViewDelegate?.collectionView(collectionView, draggingSession: session, endedAt: screenPoint, dragOperation: operation)
    }

}

#endif
