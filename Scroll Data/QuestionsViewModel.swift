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
        self.questions = questions.map { QuestionViewModel(question: $0, selectedOption: nil) }
    }
    
    func canSubmit() -> Bool {
        return questions.filter { $0.selectedOption == nil }.isEmpty
    }
    
    func submitAnswers() {
        
    }
}

class QuestionViewModel {
    let question: Question
    fileprivate var selectedOption: Question.Option?
    
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



