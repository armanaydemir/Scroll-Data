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
    
    init() {
        let questions = Array(0..<10).map {
            Question(id: "\($0)",
                text: "\($0) What is going on?",
                options: [
                    Question.Option(id: "0", text: "apsodiufpas paoisduf aps"),
                    Question.Option(id: "1", text: "poaiusdf poaisduf paosdiuf aposdiuf apsodiuf apsdoifu aspdoifu aspdoif uapsdof iapaosdiuf apsodiuf aposdi fuapsdof")
                ]
            )
        }
        
        self.questions = questions.map { QuestionViewModel(question: $0, selectedOption: nil) }
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

struct Question: UID {
    let id: String
    let text: String
    let options: [Option]
    
    struct Option: UID {
        let id: String
        let text: String
    }
}



