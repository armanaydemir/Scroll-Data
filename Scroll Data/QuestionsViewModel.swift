//
//  QuestionsViewModel.swift
//  Scroll Data
//
//  Created by Deniz Aydemir on 8/26/20.
//  Copyright © 2020 Arman Aydemir. All rights reserved.
//

import UIKit

class QuestionsViewModel {
    let questions: [QuestionViewModel]
    
    init(questions: [Question]) {
//        let testQuestions: [Question] = Array(0..<10).compactMap { number in
//            let dict: [String : Any] = [ "id" : "\(number)",
//                "text" : "\(number) What is going on?",
//                "options" : [
//                    [
//                        "id" : "0",
//                        "text" : "poaiusdf poaisduf paosdiuf aposdiuf apsodiuf apsdoifu aspdoifu aspdoif uapsdof iapaosdiuf apsodiuf"
//                    ],
//                    [
//                        "id" : "1",
//                        "text" : "apsodiuf apsdoifu aspdoifu aspdoif uapsdof iapaosdiuf apsodiuf"
//                    ]
//                ]
//            ]
//            return try? Question(data: dict)
//        }
        
        self.questions = questions.map { QuestionViewModel(question: $0, selectedOption: nil) }
    }
    
    func submitAnswers() {
        
    }
}

class QuestionViewModel {
    let question: Question
    private var selectedOption: Question.Option?
    
    func isOptionSelected(_ option: Question.Option) -> Bool {
        return option == selectedOption
    }
    
    func selectOption(_ option: Question.Option) {
        guard question.options.contains(option) else { return }
        
        selectedOption = option
    }
    
    init(question: Question, selectedOption: Question.Option? = nil) {
        self.question = question
        self.selectedOption = selectedOption
    }
}



