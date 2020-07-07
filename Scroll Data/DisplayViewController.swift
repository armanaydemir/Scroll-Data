//
//  DisplayViewController.swift
//  Scroll Data
//
//  Created by Arman Aydemir on 7/6/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit

class DisplayViewController: UIViewController {
    var data: [String:Any]  = [:]
    var content: Array<Content> = []
    let time_offset = 100000000.0
    var contentTopOffsets: [CGFloat] = []
    var contentBottomOffsets: [CGFloat] = []
    var image = UIImage.init(named: "test")
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    
     override func viewDidAppear(_ animated: Bool) {
        let imageView = UIImageView(image: self.image!)
        imageView.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(imageView)
                self.view.bringSubviewToFront(imageView)
                var ww = self.view.frame.width
                NSLayoutConstraint.activate([
//                    imageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
//                    imageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
//                    imageView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
//                    imageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
//                    imageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: (ww-self.image!.size.width)/2),
                    imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: self.image!.size.width),
                    imageView.heightAnchor.constraint(equalToConstant: self.image!.size.height),
                    imageView.topAnchor.constraint(equalTo: self.view.topAnchor)
                    ])
                self.view.layoutIfNeeded()
                imageView.layoutIfNeeded()
                self.view.backgroundColor = UIColor.white
                imageView.backgroundColor = UIColor.white
        startAutoScroll(imageView: imageView, data: self.data)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
     
    func startAutoScroll(imageView: UIView, data: [String:Any]) {
        let s = self.data["session_data"] as! Array<[String:Any]>
        let time_key = "appeared"
        let key = "scrollAnim"
        let stime = Double(s[0]["startTime"] as! NSNumber)/self.time_offset
//        let diffH = viewableAreaHeight(showOnBottom: true) - viewableAreaHeight(showOnBottom: false)
        let offset_val = self.view.safeAreaInsets.bottom + self.view.safeAreaInsets.top
        let anim = CAKeyframeAnimation(keyPath: "position.y")
        var anim_vals: [CGFloat] = []
        var anim_keyTimes: [NSNumber] = []
        
//        anim.duration = (Double(s.last![time_key] as! NSNumber)/self.time_offset)-stime
        anim.duration = 10 + (Double(s.last![time_key] as! NSNumber)/self.time_offset)-stime
        //        let tsize = table.rect(forSection: 0).size
        //        let height_per_line = (tsize.height-screenH) / CGFloat.init(exactly: s.count-2)!
        
        var i = 0
        while(i < s.count){
            let t1  = Double(s[i][time_key] as! NSNumber)/self.time_offset
            
            let last_cell = Double(s[i]["last_cell"] as! NSNumber)
            let first_cell = Double(s[i]["first_cell"] as! NSNumber)
            
            if(Int(last_cell) > self.content.count - 2){
                let c = data["content"] as! Array<[String:Any]>
                let first_percen = (first_cell/Double(c.count))*Double(self.content.count)
                let tottemp = -self.contentTopOffsets[Int(first_percen)]
                
                anim_vals.append(offset_val + tottemp)
            }else if(first_cell <= 1){
                let c = data["content"] as! Array<[String:Any]>
                let last_percen = (last_cell/Double(c.count))*Double(self.content.count)
                let tottemp = -self.contentBottomOffsets[Int(last_percen)]
                
                anim_vals.append(offset_val + tottemp)
            }else{
                let c = data["content"] as! Array<[String:Any]>
                let first_percen = (first_cell/Double(c.count))*Double(self.content.count)
                let last_percen = (last_cell/Double(c.count))*Double(self.content.count)
                let tottemp = (-self.contentTopOffsets[Int(first_percen)] - self.contentBottomOffsets[Int(last_percen)])/2
                
                anim_vals.append(offset_val + tottemp)
            }
            anim_keyTimes.append(NSNumber(value: (5 + t1-stime)/anim.duration))
//            anim_keyTimes.append(NSNumber(value: (t1-stime)/anim.duration))
            i += 1
        }
        anim.values = anim_vals
        anim.keyTimes = anim_keyTimes
        anim.isAdditive = true

        imageView.superview?.layer.add(anim, forKey: key)
        
    }

}
