//
//  IntroViewController.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/28/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit
import WebKit

class IntroViewController: UIViewController {

    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var agreeLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    let userInfo = UserInfo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Human Research Study"

        if userInfo.agreedToTerms {
            performSegue(withIdentifier: "start", sender: self)
        } else {
            webView.loadHTMLString(defaultIntroHTML, baseURL: nil)
        }
        
        let adjustToKeyboard: (Notification) -> Void = { notification in
            if let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let frame = value.cgRectValue
                let newInsets = UIEdgeInsets(top: 0, left: 0, bottom: frame.height, right: 0)
                self.scrollView.contentInset = newInsets
                self.scrollView.scrollIndicatorInsets = newInsets
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil, using: adjustToKeyboard)
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil, using: adjustToKeyboard)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}


fileprivate let defaultIntroHTML = """
<h2><strong><em><img src="https://www.colorado.edu/brand/sites/default/files/page/boulder-fl-master-2_0.png" alt="" width="429" height="87" /><br /></em></strong></h2>
<h2>&nbsp;</h2>
<h2><strong><em>Title of research study: </em></strong><span style="font-weight: 400;">Operationalizing Students&rsquo; Textbook Annotations</span></h2>
<h2><strong><em>Investigator: </em></strong><span style="font-weight: 400;">Arman Aydemir</span></h2>
<h2><strong><em>Why am I being invited to take part in a research study?</em></strong></h2>
<p><span style="font-weight: 400;">We invite you to take part in a research study because you are at least 18 years old, have normal vision or wear corrective lenses, are a fluent English speaker and have not previously participated in the experiment.</span></p>
<h2><strong><em>What should I know about a research study?</em></strong></h2>
<ul>
<li style="font-weight: 400;"><span style="font-weight: 400;">This research study will be explained to you.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">Whether or not you take part is up to you.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You can choose not to take part.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You can agree to take part and later change your mind.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">Your decision will not be held against you.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You can ask all the questions you want before you decide.</span></li>
</ul>
<h2><strong><em>Who can I talk to?</em></strong></h2>
<p><span style="font-weight: 400;">If you have questions, concerns, or complaints, or think the research has hurt you, talk to the research team by emailing Arman Aydemir at arman.aydemir@colorado.edu.</span></p>
<p><span style="font-weight: 400;">This research has been reviewed and approved by an Institutional Review Board (&ldquo;IRB&rdquo;). You may talk to them at (303) 735-3702 or </span><strong>irbadmin@colorado.edu</strong><span style="font-weight: 400;"> if:</span></p>
<ul>
<li style="font-weight: 400;"><span style="font-weight: 400;">Your questions, concerns, or complaints are not being answered by the research team.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You cannot reach the research team.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You want to talk to someone besides the research team.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You have questions about your rights as a research subject.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">You want to get information or provide input about this research.</span></li>
</ul>
<h2><strong><em>Why is this research being done?</em></strong></h2>
<p><span style="font-weight: 400;">The purpose of this research is to understand the relationship between the understanding of a presented text and the subject&rsquo;s annotations of and interactions with the text. </span><span style="font-weight: 400;">By conducting a series of such experiments, we hope to enhance online textbooks so as to facilitate students&rsquo; long-term understanding and retention of textbook content.</span></p>
<p>&nbsp;</p>
<h2><strong><em>How long will the research last?</em></strong></h2>
<p><span style="font-weight: 400;">We expect that this research study will last for 3 years.</span></p>
<h2><strong><em>How many people will be studied?</em></strong></h2>
<p><span style="font-weight: 400;">We expect about 40 people will be in this research study.</span></p>
<h2><strong><em>What happens if I say yes, I want to be in this research?</em></strong></h2>
<ul>
<li style="font-weight: 400;"><span style="font-weight: 400;">You will be using your own portable device to complete the study at a time of your choosing.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">This app will allow you to read articles from a news source or science magazine or biology textbook. The app will also allow you to quiz yourself on material you have previously read.&nbsp;</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">When and how much you use this app, and when and whether you take quizzes will be up to you.</span></li>
<li style="font-weight: 400;"><span style="font-weight: 400;">We will record your screen interactions and annotations along with your apple ID. No other personal data will be requested.</span></li>
</ul>
<h2><strong><em>What happens if I do not want to be in this research?</em></strong></h2>
<p><span style="font-weight: 400;">You can leave the research at any time and it will not be held against you.</span></p>
<h2><strong><em>What happens if I say yes, but I change my mind later?</em></strong></h2>
<p><span style="font-weight: 400;">You can leave the research at any time and it will not be held against you. If you choose to leave during the experiment, any data collected will be permanently deleted.</span></p>
<h2><strong><em>What happens to the information collected for the research?</em></strong></h2>
<p><span style="font-weight: 400;">Efforts will be made to limit the use and disclosure of behavioral data collected during this research study to people who have a need to review this information. We cannot promise complete secrecy. Organizations that may inspect and copy your information include the IRB and other representatives of this organization. In addition, representatives of University of Colorado Boulder and the National Science Foundation may inspect and copy this information.</span></p>
<p><span style="font-weight: 400;">All data collected will be stored on a secure server indefinitely and will only be accessible by the research team.</span></p>
<h2><strong><em>Can I be removed from the research without my OK?</em></strong></h2>
<p><span style="font-weight: 400;">The person in charge of the research study or the sponsor can remove you from the research study without your approval. Possible reasons for removal include the inability to follow study procedures.</span></p>
<h2><strong><em>What else do I need to know?</em></strong></h2>
<p><span style="font-weight: 400;">If you agree to take part in this research study, we will offer you a $50 Amazon gift card following 10 hours of use of the app.&nbsp;</span></p>
<p><span style="font-weight: 400;">If you wish to learn more about the results of this research you can contact Arman Aydemir arman.aydemir@colorado.edu.</span></p>
<p><br /><br /></p>
"""
