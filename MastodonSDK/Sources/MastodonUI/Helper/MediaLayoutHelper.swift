//
//  MediaLayoutHelper.swift
//  
//
//  Created by Grishka on 25.03.2023.
//

import Foundation
import MastodonSDK
import CoreDataStack

public struct MediaLayoutResult {
    let width: Int
    let height: Int
    let columnSizes: [Int]
    let rowSizes: [Int]
    let tiles: [Tile]
    
    public struct Tile {
        var colSpan: Int
        let rowSpan: Int
        var startCol: Int
        let startRow: Int
        var width: Int = 0
    }
}

class MediaLayoutHelper {
    static let maxWidth: Float = 1000
    static let maxHeight: Float = 1777
    static let minHeight: Float = 563
    static let gap: Float = 1.5
    static let maxRatio = maxWidth / maxHeight
    
    public static func generateMediaLayout(attachments: [MastodonAttachment]) -> MediaLayoutResult? {
        if attachments.count<2 {
            return nil
        }
        
        var ratios: [Float] = []
        var allAreWide = true
        var allAreSquare = true
        for att in attachments {
            let ratio: Float = Float(att.size.width/att.size.height)
            if ratio <= 1.2 {
                allAreWide = false
                if ratio<0.8 {
                    allAreSquare = false
                }
            } else {
                allAreSquare = false
            }
            ratios.append(ratio)
        }
        
        let avgRatio: Float = ratios.reduce(0.0, +) / Float(ratios.count)
        
        switch attachments.count {
        case 2:
            if allAreWide && avgRatio>1.4*maxRatio && (ratios[1]-ratios[0])<0.2 {
                // Two wide attachments, one above the other
                let h = Int(max(min(maxWidth/ratios[0], min(maxWidth/ratios[1], (maxHeight-gap)/2.0)), minHeight/2.0).rounded())
                
                return MediaLayoutResult(width: Int(maxWidth),
                                         height: Int((Float(h)*2.0+gap).rounded()),
                                         columnSizes: [Int(maxWidth)],
                                         rowSizes: [h, h],
                                         tiles: [
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 0, startRow: 0),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 0, startRow: 1)
                                         ])
            } else if allAreWide || allAreSquare {
                // Next to each other, same ratio
                let w: Float = (maxWidth-gap) / 2.0
                let h: Float = max(min(w/ratios[0], min(w/ratios[1], maxHeight)), minHeight)
                
                let wInt: Int = Int(w.rounded())
                let hInt: Int = Int(h.rounded())
                
                return MediaLayoutResult(width: Int(maxWidth),
                                         height: hInt,
                                         columnSizes: [wInt, Int(maxWidth)-wInt],
                                         rowSizes: [hInt],
                                         tiles: [
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 0, startRow: 0),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 1, startRow: 0)
                                         ])
            } else {
                // Next to each other, different ratios
                let w0: Float = ((maxWidth - gap) / ratios[1] / (1.0 / ratios[0] + 1.0 / ratios[1]))
                let w1: Float = maxWidth - w0 - gap
                let h: Float = max(min(maxHeight, min(w0/ratios[0], w1/ratios[1])), minHeight)
                
                let w0Int = Int(w0.rounded())
                let w1Int = Int(w1.rounded())
                let hInt = Int(h.rounded())
                
                return MediaLayoutResult(width: Int((w0+w1+gap).rounded()),
                                         height: hInt,
                                         columnSizes: [w0Int, w1Int],
                                         rowSizes: [hInt],
                                         tiles: [
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 0, startRow: 0),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 1, startRow: 0)
                                         ])
            }
        case 3:
            if ratios[0]>1.2*maxRatio || avgRatio>1.5*maxRatio || allAreWide {
                // One above two smaller ones
                var hCover: Float = min(maxWidth/ratios[0], (maxHeight-gap)*0.66)
                let w2: Float = (maxWidth-gap)/2.0
                var h: Float = min(maxHeight-hCover-gap, min(w2/ratios[1], w2/ratios[2]))
                if hCover+h < minHeight {
                    let prevTotalHeight = hCover+h
                    hCover = minHeight*(hCover/prevTotalHeight)
                    h = minHeight*(h/prevTotalHeight)
                }
                
                return MediaLayoutResult(width: Int(maxWidth),
                                         height: Int((hCover+h+gap).rounded()),
                                         columnSizes: [Int(w2.rounded()), Int(maxWidth-w2.rounded())],
                                         rowSizes: [Int(hCover.rounded()), Int(h.rounded())],
                                         tiles: [
                                            MediaLayoutResult.Tile(colSpan: 2, rowSpan: 1, startCol: 0, startRow: 0),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 0, startRow: 1),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 1, startRow: 1)
                                         ])
            } else {
                // One on the left, two smaller ones on the right
                let height: Float = min(maxHeight, maxWidth*0.66/avgRatio)
                let wCover: Float = min(height*ratios[0], (maxWidth-gap)*0.66)
                let h1: Float = ratios[1]*(height-gap)/(ratios[2]+ratios[1])
                let h0: Float = height-h1-gap
                let w: Float = min(maxWidth-wCover-gap, h1*ratios[2], h0*ratios[1])
                
                return MediaLayoutResult(width: Int((wCover+w+gap).rounded()),
                                         height: Int(height.rounded()),
                                         columnSizes: [Int(wCover.rounded()), Int(w.rounded())],
                                         rowSizes: [Int(h0.rounded()), Int(h1.rounded())],
                                         tiles: [
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 2, startCol: 0, startRow: 0),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 1, startRow: 0),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 1, startRow: 1)
                                         ])
            }
        case 4:
            if ratios[0]>1.2*maxRatio || avgRatio>1.5*maxRatio || allAreWide {
                // One above three smaller ones
                var hCover: Float = min(maxWidth/ratios[0], (maxHeight-gap)*0.66)
                var h: Float = (maxWidth-2.0*gap)/(ratios[1]+ratios[2]+ratios[3])
                let w0: Float = h*ratios[1]
                let w1: Float = h*ratios[2]
                h = min(maxHeight-hCover-gap, h)
                if hCover+h<minHeight {
                    let prevTotalHeight = hCover+h
                    hCover = minHeight*(hCover/prevTotalHeight)
                    h = minHeight*(h/prevTotalHeight)
                }
                
                return MediaLayoutResult(width: Int(maxWidth),
                                         height: Int((hCover+h+gap).rounded()),
                                         columnSizes: [Int(w0.rounded()), Int(w1.rounded()), Int(maxWidth-w0.rounded()-w1.rounded())],
                                         rowSizes: [Int(hCover.rounded()), Int(h.rounded())],
                                         tiles: [
                                            MediaLayoutResult.Tile(colSpan: 3, rowSpan: 1, startCol: 0, startRow: 0),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 0, startRow: 1),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 1, startRow: 1),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 2, startRow: 1)
                                         ])
            } else {
                // One on the left, three smaller ones on the right
                let height: Float = min(maxHeight, maxWidth*0.66/avgRatio)
                let wCover: Float = min(height*ratios[0], (maxWidth-gap)*0.66)
                var w: Float = (height-2.0*gap)/(1.0/ratios[1]+1.0/ratios[2]+1.0/ratios[3])
                let h0: Float = w/ratios[1]
                let h1: Float = w/ratios[2]
                let h2: Float = w/ratios[3]+gap
                w = min(maxWidth-wCover-gap, w)
                
                return MediaLayoutResult(width: Int((wCover+gap+w).rounded()),
                                         height: Int(height.rounded()),
                                         columnSizes: [Int(wCover.rounded()), Int(w.rounded())],
                                         rowSizes: [Int(h0.rounded()), Int(h1.rounded()), Int(h2.rounded())],
                                         tiles: [
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 3, startCol: 0, startRow: 0),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 1, startRow: 0),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 1, startRow: 1),
                                            MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 1, startRow: 2)
                                         ])
            }
        default:
            let cnt = attachments.count
            var ratiosCropped: [Float] = []
            if avgRatio>1.1 {
                for ratio in ratios {
                    ratiosCropped.append(max(1.0, ratio))
                }
            } else {
                for ratio in ratios {
                    ratiosCropped.append(min(1.0, ratio))
                }
            }
            
            var tries: [[Int]: [Float]] = [:]
            
            // One line
            tries[[attachments.count]] = [calculateMultiThumbsHeight(ratios: ratiosCropped, width: maxWidth, margin: gap)]
            
            // Two lines
            for firstLine in 1...cnt-1 {
                tries[[firstLine, cnt-firstLine]] = [
                    calculateMultiThumbsHeight(ratios: Array(ratiosCropped[..<firstLine]), width: maxWidth, margin: gap),
                    calculateMultiThumbsHeight(ratios: Array(ratiosCropped[firstLine...]), width: maxWidth, margin: gap)
                ]
            }
            
            // Three lines
            for firstLine in 1...cnt-2 {
                for secondLine in 1...cnt-firstLine-1 {
                    tries[[firstLine, secondLine, cnt-firstLine-secondLine]] = [
                        calculateMultiThumbsHeight(ratios: Array(ratiosCropped[..<firstLine]), width: maxWidth, margin: gap),
                        calculateMultiThumbsHeight(ratios: Array(ratiosCropped[firstLine..<firstLine+secondLine]), width: maxWidth, margin: gap),
                        calculateMultiThumbsHeight(ratios: Array(ratiosCropped[(firstLine+secondLine)...]), width: maxWidth, margin: gap)
                    ]
                }
            }
            
            let realMaxHeight = min(maxWidth, maxHeight)
            
            var optConf: [Int] = []
            var optDiff: Float = Float.greatestFiniteMagnitude
            
            for (conf, heights) in tries {
                let confH: Float = heights.reduce(gap*Float(heights.count-1), +)
                var confDiff = abs(confH-realMaxHeight)
                if conf.count>1 && (conf[0]>conf[1] || (conf.count>2 && conf[1]>conf[2])) {
                    confDiff *= 1.1
                }
                if confDiff<optDiff {
                    optConf = conf
                    optDiff = confDiff
                }
            }
            
            var thumbsRemain: [MastodonAttachment] = Array(attachments)
            var ratiosRemain: [Float] = Array(ratiosCropped)
            let optHeights = tries[optConf]!
            var totalHeight: Float = 0.0
            var rowSizes: [Int] = []
            var gridLineOffsets: [Int] = []
            var rowTiles: [[MediaLayoutResult.Tile]] = []
            
            for (i, lineChunksNum) in optConf.enumerated() {
                var lineThumbs: [MastodonAttachment] = []
                for _ in 0..<lineChunksNum {
                    lineThumbs.append(thumbsRemain.removeFirst())
                }
                let lineHeight = optHeights[i]
                totalHeight += lineHeight
                rowSizes.append(Int(lineHeight.rounded()))
                var totalWidth: Int = 0
                var row: [MediaLayoutResult.Tile] = []
                for (j, _) in lineThumbs.enumerated() {
                    let thumbRatio = ratiosRemain.removeFirst()
                    let w: Float = j==lineThumbs.count-1 ? (maxWidth-Float(totalWidth)) : (thumbRatio*lineHeight)
                    totalWidth += Int(w.rounded())
                    if j<lineThumbs.count-1 && !gridLineOffsets.contains(totalWidth) {
                        gridLineOffsets.append(totalWidth)
                    }
                    var tile = MediaLayoutResult.Tile(colSpan: 1, rowSpan: 1, startCol: 0, startRow: i)
                    tile.width = Int(w.rounded())
                    row.append(tile)
                }
                rowTiles.append(row)
            }
            
            gridLineOffsets = gridLineOffsets.sorted()
            gridLineOffsets.append(Int(maxWidth))
            
            var columnSizes: [Int] = [gridLineOffsets[0]]
            for (i, offset) in gridLineOffsets[1...].enumerated() {
                columnSizes.append(offset - gridLineOffsets[i]) // i is already offset by one here
            }
            
            for row in 0..<rowTiles.count {
                var columnOffset: Int = 0
                for (tile, _) in rowTiles[row].enumerated() {
                    let startColumn = columnOffset
                    rowTiles[row][tile].startCol = startColumn
                    var width: Int = 0
                    rowTiles[row][tile].colSpan = 0
                    for i in startColumn..<columnSizes.count {
                        width += columnSizes[i]
                        rowTiles[row][tile].colSpan += 1
                        if width == rowTiles[row][tile].width {
                            break
                        }
                    }
                    columnOffset += rowTiles[row][tile].colSpan
                }
            }
            
            return MediaLayoutResult(width: Int(maxWidth),
                                     height: Int((totalHeight+gap*Float(optHeights.count-1)).rounded()),
                                     columnSizes: columnSizes,
                                     rowSizes: rowSizes,
                                     tiles: rowTiles.reduce([], +))
        }
    }
    
    private static func calculateMultiThumbsHeight(ratios: [Float], width: Float, margin: Float) -> Float {
        return (width-(Float(ratios.count)-1.0)*margin)/ratios.reduce(0.0, +)
    }
}
