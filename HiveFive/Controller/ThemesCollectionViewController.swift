/**
 *
 *  This file is part of Hive Five.
 *
 *  Hive Five is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Hive Five is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Hive Five.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import UIKit
import Hive5Common

private let reuseIdentifier = "cell3"

class ThemesCollectionViewController: UICollectionViewController {

    var cached = [IndexPath: UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preloadRenderedThemes()
    }
    
    /// Preloads rendered themes into cached dictionary. This solved the issue of lagging.
    private func preloadRenderedThemes() {
        themes.enumerated().map{(IndexPath(row: $0.offset, section: 0), $0.element)}
            .forEach { (indexPath, theme) in
                let cell = collectionView!.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ThemesCollectionViewCell
                prepareCell(cell, theme: theme)
                cached[indexPath] = cell.asImage()
            }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themes.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ThemesCollectionViewCell
        if let cachedImg = cached[indexPath] {
            cell.contentView.isHidden = true
            cell.backgroundView = UIImageView(image: cachedImg)
        } else {
            prepareCell(cell, theme: themes[indexPath.row])
            if !shouldUseRectangularUI() {
                cell.layer.cornerRadius = uiCornerRadius
            }
            cached[indexPath] = cell.asImage()
        }
        return cell
    }
    
    func prepareCell(_ cell: ThemesCollectionViewCell, theme: Theme) {
        cell.boardView.patterns = theme.patterns
        cell.boardView.isUserInteractionEnabled = false
        cell.boardView.nodeRadius = currentNodeSize() / 2
        cell.boardView.root = Hive.defaultHive.root
        cell.boardView.centerHiveStructure()
        cell.nameLabel.text = theme.name
        if !shouldUseRectangularUI() {cell.layer.cornerRadius = uiCornerRadius}
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let theme = themes[indexPath.row]
        NotificationCenter.default.post(
            name: themeUpdateNotification,
            object: theme.patterns
        )
        save(id: themeId, obj: theme.encode())
//        collectionView.visibleCells.forEach{($0 as! ThemesCollectionViewCell).bezel.backgroundColor = nil}
//        (collectionView.cellForItem(at: indexPath) as! ThemesCollectionViewCell).bezel.backgroundColor = UIColor.blue.withAlphaComponent(0.7)
        navigationController?.popToRootViewController(animated: true)
    }

}

// MARK: Data Source

struct Theme {
    var name: String
    var patterns: [Identity: String]
    
    func encode() -> String {
        return name
    }
    
    static func decode(_ name: String) -> Theme {
        return themes.filter{$0.name == name}[0]
    }
}

var themes: [Theme] = [
    .init(name: "Mathematics", patterns: [
        .grasshopper: "𝝣",
        .queenBee: "𝝠",
        .beetle: "𝝧",
        .spider: "𝝮",
        .soldierAnt: "𝝭",
        .dummy: "𝝬",
        .mosquito: "𝝨",
        .ladyBug: "𝝳"
        ]),
    .init(name: "Chinese", patterns: [
        .grasshopper: "蜢",
        .queenBee: "皇",
        .beetle: "甲",
        .spider: "蛛",
        .soldierAnt: "蚁",
        .dummy: "笨"
        ]),
    .init(name: "Letters", patterns: [
        .grasshopper: "𝔾",
        .queenBee: "ℚ",
        .beetle: "𝔹",
        .spider: "𝕊",
        .soldierAnt: "𝔸",
        .dummy: "𝔻"
        ]),
    .init(name: "Chess Dark", patterns: [
        .grasshopper: "♞",
        .queenBee: "♛",
        .beetle: "♙",
        .spider: "♝",
        .soldierAnt: "♜",
        .dummy: "♚"
        ]),
    .init(name: "Chess Light", patterns: [
        .grasshopper: "♘",
        .queenBee: "♕",
        .beetle: "♙",
        .spider: "♗",
        .soldierAnt: "♖",
        .dummy: "♔"
        ]),
    .init(name: "Currency", patterns: [
        .grasshopper: "$",
        .queenBee: "€",
        .beetle: "¥",
        .spider: "¢",
        .soldierAnt: "£",
        .dummy: "₽"
        ]),
    .init(name: "Stars", patterns: [
        .grasshopper: "✡︎",
        .queenBee: "✪",
        .beetle: "✶",
        .spider: "★",
        .soldierAnt: "✩",
        .dummy: "▲"
        ]),
    .init(name: "Physics", patterns: [
        .grasshopper: "𝜞︎",
        .queenBee: "𝜟",
        .beetle: "𝜭",
        .spider: "𝜮",
        .soldierAnt: "𝜴",
        .dummy: "𝜩"
        ]),
    .init(name: "Skewed", patterns: [
        .grasshopper: "𝞝",
        .queenBee: "𝞡",
        .beetle: "𝞨",
        .spider: "𝞚",
        .soldierAnt: "𝞧",
        .dummy: "𝞦"
        ]),
    .init(name: "Trigrams", patterns: [
        .grasshopper: "☱",
        .queenBee: "☲",
        .beetle: "☳",
        .spider: "☵",
        .soldierAnt: "☴",
        .dummy: "☶"
        ]),
]

