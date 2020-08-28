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
    let sessionID: String
    
    init(sessionID: String, questions: [Question]) {
        self.sessionID = sessionID
        self.questions = questions.map { QuestionViewModel(question: $0, selectedOption: nil) }
    }
    
    func canSubmit() -> Bool {
        return questions.filter { $0.selectedOption == nil }.isEmpty
    }
    
    func submitAnswers(completion: @escaping (_ success: Bool) -> Void) {
        let answers: [(questionID: String, optionID: String)] = questions.map { questionVM in
            return (questionID: questionVM.question.id, optionID: questionVM.selectedOption?.id ?? "")
        }
        
        Server.Request.submitAnswers(sessionID: sessionID, answers: answers).startRequest { (result: Result<GenericResponse, Swift.Error>) in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let error):
                print(error)
                completion(false)
            }
        }
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



