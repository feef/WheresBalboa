import UIKit
import FirebaseAuth
import PopupDialog
import KeychainAccess

class LoginViewController: UIViewController, UITextFieldDelegate, AccountEditor {
    @IBOutlet private var emailTextField: UITextField!
    @IBOutlet private var passwordTextField: UITextField!
    
    // MARK: - Init
    
    init() {
        super.init(nibName: nil, bundle: nil)
        guard #available(iOS 11.0, *) else {
            edgesForExtendedLayout = []
            return
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        emailTextField.text = nil
        passwordTextField.text = nil
    }
    
    // MARK: - Button response
    
    @IBAction private func tappedLoginOrSignUp() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        guard
            let email = emailTextField.text,
            let password = passwordTextField.text
            else {
                return
        }
        
        guard isValid(email: email) else {
            showAlert(message: "You must enter a valid email address")
            return
        }
        
        guard isValid(password: password) else {
            showAlert(message: "You must enter a password that's at least 6 letters long")
            return
        }
        
        let loginInfo = LoginInfo(email: email, password: password)
        beginLoginFlow(with: loginInfo)
    }
    
    @IBAction private func tappedForgotPassword() {
        guard let email = emailTextField.text else {
            let okButton = DefaultButton(title: "Ok") { }
            showAlert(title: "Where?", message: "Put your email in the email field so we know where to send the email to.", buttons: [okButton])
            return
        }
        
        showLoadingAlert()
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.dismiss(animated: true) {
                if error != nil {
                    strongSelf.showRetryAlert(message: "We failed to send your password reset email. Retry?", retryHandler: strongSelf.tappedForgotPassword)
                } else {
                    strongSelf.showAlert(title: "Check your email", message: "You should have a password reset email in your inbox. Remember to check your spam too!")
                }
            }
        }
    }
    
    // MARK: - Login and signup
    
    private func beginLoginFlow(with loginInfo: LoginInfo) {
        let operation = LoginOperation(loginInfo) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.dismiss(animated: true) {
                    switch result {
                        case .failure(let error):
                            guard
                                let authError = error as NSError?,
                                authError.code == AuthErrorCode.userNotFound.rawValue
                            else {
                                    strongSelf.showAlert(message: error?.localizedDescription)
                                    return
                            }
                            
                            let createButton = DefaultButton(title: "Yep!") {
                                strongSelf.startCreateBalbabeFlow(with: loginInfo)
                            }
                            let cancelButton = CancelButton(title: "Nope") {
                                strongSelf.dismiss(animated: true)
                            }
                            strongSelf.showAlert(title: "No user found", message: "We didn't find an account with that email. Would you like to create an account?", buttons: [createButton, cancelButton])
                        case .success(let balbabe):
                            Keychain.standard.setLoginInfo(loginInfo)
                            UserManager.shared.setCurrentUser(balbabe)
                            let homeViewController = HomeViewController(balbabe)
                            strongSelf.navigationController?.pushViewController(homeViewController, animated: true)
                    }
                }
            }
        }
        showLoadingAlert()
        OperationQueue.main.addOperation(operation)
    }
    
    private func startCreateBalbabeFlow(with loginInfo: LoginInfo) {
        let signUpViewController = SignUpViewController(loginInfo)
        navigationController?.pushViewController(signUpViewController, animated: true)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
