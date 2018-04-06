//
//  HandCollectionViewController.swift
//  Hive Five
//
//  Created by Jiachen Ren on 4/5/18.
//  Copyright © 2018 Greensboro Day School. All rights reserved.
//

import UIKit

private let reuseIdentifier = "cell4"

class HandCollectionViewController: UICollectionViewController {
    
    var hive: Hive {
        return Hive.sharedInstance
    }
    
    var hand = Hive.defaultHand
    var color: Color = .black
    var patterns = Identity.defaultPatterns
    
    /**
     The index of the cell that is currently selected
     */
    var selectedIndex: IndexPath? {
        willSet {
            if let old = selectedIndex {
                getNodeView(at: old).isSelected = false
            }
        }
        didSet {
            if let new = selectedIndex {
                getNodeView(at: new).isSelected = true
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view
        
        //MARK: Notification Binding
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handDidUpdate(_:)),
            name: handUpdateNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidUpdate(_:)),
            name: themeUpdateNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didCancelSelection(_:)),
            name: didCancelNewPiece,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didPlaceSelection(_:)),
            name: didPlaceNewPiece,
            object: nil
        )
    }
    
    @objc func didCancelSelection(_ notification: Notification) {
        selectedIndex = nil
    }
    
    @objc func didPlaceSelection(_ notification: Notification) {
        let boardView = getCell(at: selectedIndex!).boardView!
        let node = boardView.root!
        boardView.root = node.identity.new(color: node.color) // the old node has been used, instantiate a new one.
        selectedIndex = nil
    }
    
    @objc func themeDidUpdate(_ notification: Notification) {
        patterns = notification.object as! [Identity:String]
        collectionView?.reloadData()
    }
    
    @objc func handDidUpdate(_ notification: Notification) {
        if let (hand, color) = notification.object as? (Hand, Color) {
            self.hand = hand
            self.color = color
            collectionView?.reloadData()
        }
    }
    
    private func getCell(at indexPath: IndexPath) -> HandCollectionViewCell {
        return collectionView?.cellForItem(at: selectedIndex!) as! HandCollectionViewCell
    }
    
    private func getNodeView(at indexPath: IndexPath) -> NodeView {
        return getCell(at: indexPath).boardView.nodeViews[0]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return hand.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! HandCollectionViewCell
        let pair = hand.keyValuePairs[indexPath.row]
        let node = pair.key.new(color: color)
        
        cell.boardView.patterns = patterns
        cell.boardView.root = node
        cell.boardView.nodeRadius = cell.bounds.midX
        cell.boardView.isUserInteractionEnabled = false
        cell.indexPath = indexPath
        cell.boardView.nodeViews[0].isSelected = indexPath == selectedIndex
        cell.numLabel.text = String(pair.value)
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath
        NotificationCenter.default.post(
            name: didSelectNewNodeNotification,
            object: hand.keyValuePairs[indexPath.row].key.new(color: color))
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}