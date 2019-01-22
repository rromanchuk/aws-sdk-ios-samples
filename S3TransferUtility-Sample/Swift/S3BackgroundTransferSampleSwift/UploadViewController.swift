/*
 * Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import UIKit
import AWSS3

class UploadViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var statusLabel: UILabel!

    
    let imagePicker = UIImagePickerController()
    let transferUtility = AWSS3TransferUtility.default()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Manager.shared.delegate = self
        self.progressView.progress = 0.0;
        self.statusLabel.text = "Ready"
        self.imagePicker.delegate = self

       
    }

    @IBAction func selectAndUpload(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func uploadImage(with data: Data) {

        DispatchQueue.main.async(execute: {
            self.statusLabel.text = ""
            self.progressView.progress = 0
        })
        
        Manager.shared.upload(data: data)

    }
    
    
}

extension UploadViewController: UploadManagerDelegate {
    func didStart() {
        self.statusLabel.text = "Uploading..."
        print("Upload Starting!")
    }
    
    func didProgress(progress: Progress) {
        if (self.progressView.progress < Float(progress.fractionCompleted)) {
            self.progressView.progress = Float(progress.fractionCompleted)
        }
    }
    
    func didComplete(error: Error?) {
        if let error = error {
            print("Failed with error: \(error)")
            self.statusLabel.text = "Failed"
        }
        else if(self.progressView.progress != 1.0) {
            self.statusLabel.text = "Failed"
            NSLog("Error: Failed - Likely due to invalid region / filename")
        }
        else{
            self.statusLabel.text = "Success"
        }
    }
    
    
}

extension UploadViewController: UIImagePickerControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if "public.image" == info[UIImagePickerControllerMediaType] as? String {
            let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            self.uploadImage(with: UIImagePNGRepresentation(image)!)
        }
        
        
        dismiss(animated: true, completion: nil)
    }
}

protocol UploadManagerDelegate:class {
    func didProgress(progress: Progress)
    func didComplete(error: Error?)
    func didStart()
}


class Manager {
    static let shared = Manager()
    
    var transferUtility: AWSS3TransferUtility!
    var multipartCompletionHandler: AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock!
    let expression = AWSS3TransferUtilityMultiPartUploadExpression()
    var progressBlock: AWSS3TransferUtilityProgressBlock!
    var multipartProgressBlock: AWSS3TransferUtilityMultiPartProgressBlock!
    weak var delegate: UploadManagerDelegate?
    
    
    init() {
        multipartProgressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
                self.delegate?.didProgress(progress: progress)
                print("progressr: \(Float(progress.fractionCompleted))")
            })
        }
        
        multipartCompletionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                self.delegate?.didComplete(error: error)
            })
        }
        
        expression.progressBlock = multipartProgressBlock
        transferUtility = AWSS3TransferUtility.default()
    }
    
    
    func upload(data: Data) {
        transferUtility.uploadUsingMultiPart(data: data, key: S3UploadKeyName, contentType: "image/png", expression: expression, completionHandler: multipartCompletionHandler).continueWith { (task) -> AnyObject! in
            if let error = task.error {
                print("Error: \(error.localizedDescription)")
            }
            
            if let _ = task.result {
                DispatchQueue.main.async {
                    self.delegate?.didStart()
                }
            }
            
            return nil;
        }
    }
    
    func handleForeground() {
        
        if let multiPartUploadTasks = transferUtility.getMultiPartUploadTasks().result, let uploads = multiPartUploadTasks as? [AWSS3TransferUtilityMultiPartUploadTask] {
            for task in uploads {
                task.setCompletionHandler(multipartCompletionHandler!)
                task.setProgressBlock(multipartProgressBlock!)
            }
        }
    }
    
    
}
