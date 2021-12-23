//
//  FeedbackViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-12-03.
//

import UIKit

class FeedbackViewController: ReportViewController {
    final var subjectTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavItem()
    }
    
    final override func configure() {
        title = "Feedback"
        self.hideKeyboardWhenTappedAround()
        view.backgroundColor = .white
        scrollView = UIScrollView()
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.fill()
        
        alert = Alerts()
        
        customNavView = BackgroundView6()
        customNavView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(customNavView)
        
        colorPatchView.backgroundColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1)
        colorPatchView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colorPatchView)
        
        titleLabel = createTitleLabel(text: "Subject")
        scrollView.addSubview(titleLabel)
        
        subjectTextField = createTextField(placeHolder: "i.e. Technical issue")
        scrollView.addSubview(subjectTextField)
        
        commentTitleLabel = createTitleLabel(text: "Comment")
        commentTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(commentTitleLabel)
        
        textView = UITextView()
        textView.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        textView.layer.cornerRadius = 10
        textView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        textView.clipsToBounds = true
        textView.isScrollEnabled = true
        textView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(textView)
        
        submitButton = UIButton()
        submitButton.setTitle("Submit", for: .normal)
        submitButton.backgroundColor = .black
        submitButton.layer.cornerRadius = 5
        submitButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(submitButton)
    }
    
    final override func setConstraints() {
        NSLayoutConstraint.activate([
            customNavView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            customNavView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavView.heightAnchor.constraint(equalToConstant: 50),
            
            colorPatchView.topAnchor.constraint(equalTo: view.topAnchor),
            colorPatchView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            colorPatchView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            colorPatchViewHeight,
            
            titleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 80),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subjectTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subjectTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subjectTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            subjectTextField.heightAnchor.constraint(equalToConstant: 50),
            
            commentTitleLabel.topAnchor.constraint(equalTo: subjectTextField.bottomAnchor, constant: 40),
            commentTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            commentTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            textView.topAnchor.constraint(equalTo: commentTitleLabel.bottomAnchor, constant: 10),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: TEXTVIEW_HEIGHT),
            
            submitButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 50),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        view.layoutIfNeeded()
    }
    
    @objc final override func buttonPressed(_ sender: UIButton) {
        guard let userId = userId else {
            self.alert.showDetail("User ID Error", with: "Please make sure you're logged in.", for: self)
            return
        }
        
        let whitespaceCharacterSet = CharacterSet.whitespaces
        guard let comment = textView.text else {
            self.alert.showDetail("Empty Comment", with: "The comment cannot be empty. Please make sure to fill it out before submitting the feedback.", for: self)
            return
        }
        
        let strippedString = comment.trimmingCharacters(in: whitespaceCharacterSet)
        guard !strippedString.isEmpty else {
            self.alert.showDetail("Empty Comment", with: "The comment cannot be empty. Please make sure to fill it out before submitting the feedback.", for: self)
            return
        }
        
        guard let subject = subjectTextField.text else {
            self.alert.showDetail("Empty Subject", with: "The subject cannot be empty. Please make sure to fill it out before submitting the feedback.", for: self)
            return
        }
        
        let strippedSubject = subject.trimmingCharacters(in: whitespaceCharacterSet)
        guard !strippedSubject.isEmpty else {
            self.alert.showDetail("Empty Subject", with: "The subject cannot be empty. Please make sure to fill it out before submitting the feedback.", for: self)
            return
        }
        
        let ref = FirebaseService.shared.db
            .collection("feedback")
            .document(userId)
        
        ref.getDocument { [weak self] (snapshot, error) in
            if let _ = error {
                self?.alert.showDetail("Error", with: "There was an error submitting your report.", for: self)
                return
            }
            
            if let documentExists = snapshot?.exists,
               documentExists == false {
                ref.setData([
                    "userId": userId
                ])
            }
        }
        
        ref.collection("detail")
            .addDocument(data: [
                "subject": subject,
                "reporter": userId,
                "comment": comment,
                "date": Date(),
            ]) { [weak self] (error) in
                if let _ = error {
                    self?.alert.showDetail("Error", with: "Unable to submit the report.", for: self)
                }
                
                self?.alert.showDetail(
                    "Success",
                    with: "Your report has been successfully submitted.",
                    for: self,
                    buttonAction: {
                        self?.dismiss(animated: true, completion: {
                            self?.navigationController?.popViewController(animated: true)
                        })
                    }
                )
            }
    }
    
    func setNavItem() {
        let infoImage = UIImage(systemName: "info.circle")
        let rightBarButtonItem = UIBarButtonItem(image: infoImage, style: .plain, target: self, action: #selector(navItemPresssed))
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    @objc func navItemPresssed() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        let buttonInfoArr = [
            ButtonInfo(title: "Visit Website", tag: 500, backgroundColor: .black)
        ]
        
        let infoVC = InfoViewController(
            infoModelArr: [InfoModel(title: "About", detail: InfoText.aboutInfo)],
            buttonInfoArr: buttonInfoArr
        )
        
        infoVC.buttonAction = { [weak self] tag in
            switch tag {
                case 500:
                    self?.dismiss(animated: true, completion: {
//                        guard let url = URL(string: "https://buroku.gatsbyjs.io/") else { return }
//                        UIApplication.shared.open(url)
                        
                        let webVC = WebViewController()
                        webVC.urlString = "https://buroku.gatsbyjs.io/"
                        self?.navigationController?.pushViewController(webVC, animated: true)
                    })
                default:
                    break
            }
        }
        
        self.present(infoVC, animated: true, completion: nil)
    }
}
