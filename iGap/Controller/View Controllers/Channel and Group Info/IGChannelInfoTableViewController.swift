/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the RooyeKhat Media Company - www.RooyeKhat.co
 * All rights reserved.
 */

import UIKit
import ProtocolBuffers
import RealmSwift
import RxRealm
import RxSwift
import RxCocoa
import IGProtoBuff
import MGSwipeTableCell
import MBProgressHUD

class IGChannelInfoTableViewController: UITableViewController , UIGestureRecognizerDelegate {

    
    @IBOutlet weak var channelSignMessageCell: UITableViewCell!
    @IBOutlet weak var channelTypeTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var channelDescriptionTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var channelNameTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var notificationCell: UITableViewCell!
    @IBOutlet weak var sharedMediaCell: UITableViewCell!
    @IBOutlet weak var channelNameCell: UITableViewCell!
    @IBOutlet weak var channelDescriptionCell: UITableViewCell!
    @IBOutlet weak var channelTypeCell: UITableViewCell!
    @IBOutlet weak var deleteChannelLabel: UILabel!
    @IBOutlet weak var channelLinkLabel: UILabel!
    @IBOutlet weak var signMessageSwtich: UISwitch!
    @IBOutlet weak var channelNameLabelTitle: UILabel!
    @IBOutlet weak var channelImage: IGAvatarView!
    @IBOutlet weak var ChannelDescriptionLabel: UILabel!
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var channelTypeLabel: UILabel!
    @IBOutlet weak var numberOfMemberJoinedThisChannelLabel: UILabel!
    @IBOutlet weak var allMemberCell: UITableViewCell!
    @IBOutlet weak var channelLinkCell: UITableViewCell!
    @IBOutlet weak var adminAndModeratorCell: UITableViewCell!

    var selectedChannel : IGChannelRoom?
    private let disposeBag = DisposeBag()
    var room : IGRoom?
    var hud = MBProgressHUD()
    var allMember = [IGChannelMember]()
    var myRole : IGChannelMember.IGRole!
    var signMessageIndexPath : IndexPath?
    var channelLinkIndexPath : IndexPath?
    var imagePicker = UIImagePickerController()
//    var rooms : Results<IGRoom>!
    var notificationToken: NotificationToken?
    var connectionStatus: IGAppManager.ConnectionStatus?


    override func viewDidLoad() {
        super.viewDidLoad()
        requestToGetRoom()
        imagePicker.delegate = self
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        signMessageIndexPath = IndexPath(row: 2, section: 1)
        myRole = room?.channelRoom?.role
        switch myRole! {
        case .member:
            channelSignMessageCell.isHidden = true
            adminAndModeratorCell.isHidden = true
            allMemberCell.isHidden = true
            channelLinkCell.isHidden = true
            tableView.moveRow(at: signMessageIndexPath!, to: IndexPath(row: 0, section: 1))
            channelNameCell.accessoryType = .none
            channelNameTrailingConstraint.constant = 10
            channelTypeCell.accessoryType = .none
            channelTypeTrailingConstraint.constant = 10
            cameraButton.isHidden = true
            break
            
        case .moderator:
            channelSignMessageCell.isHidden = true
            adminAndModeratorCell.isHidden = true
            allMemberCell.isHidden = true
            channelLinkCell.isHidden = true
            tableView.moveRow(at: signMessageIndexPath!, to: IndexPath(row: 0, section: 1))
            channelNameCell.accessoryType = .none
            channelNameTrailingConstraint.constant = 10
            channelDescriptionCell.accessoryType = .none
            channelDescriptionTrailingConstraint.constant = 10
            channelTypeCell.accessoryType = .none
            channelTypeTrailingConstraint.constant = 10
            cameraButton.isHidden = true

            break
        case .owner :
            deleteChannelLabel.text = "Delete Channel"
            channelSignMessageCell.isHidden = false
            cameraButton.isHidden = false
           break
        case .admin :
            channelSignMessageCell.isHidden = true
            cameraButton.isHidden = false
        }
        self.tableView.backgroundView = UIImageView(image: UIImage(named: "IG_Settigns_Bg"))
        tableView.tableFooterView = UIView()
        let navigationItem = self.navigationItem as! IGNavigationItem
        navigationItem.addNavigationViewItems(rightItemText: nil, title: "Channel Info")
        navigationItem.navigationController = self.navigationController as? IGNavigationController
        let navigationController = self.navigationController as! IGNavigationController
        navigationController.interactivePopGestureRecognizer?.delegate = self
        showChannelInfo()
        
        let predicate = NSPredicate(format: "id = %lld", (room?.id)!)
        room =  try! Realm().objects(IGRoom.self).filter(predicate).first!
        self.notificationToken = room?.addNotificationBlock({ (objectChange) in
            self.showChannelInfo()
        })
        
        IGAppManager.sharedManager.connectionStatus.asObservable().subscribe(onNext: { (connectionStatus) in
            DispatchQueue.main.async {
                self.updateConnectionStatus(connectionStatus)
                
            }
        }, onError: { (error) in
            
        }, onCompleted: {
            
        }, onDisposed: {
            
        }).addDisposableTo(disposeBag)

            
            
//            { (changes: RealmCollectionChange) in
//            self.showChannelInfo()
//            switch changes {
//                
//            case .initial:
//                self.tableView.reloadData()
//                break
//            case .update(_, let deletions, let insertions, let modifications):
//                print("updating members tableV")
//                // Query messages have changed, so apply them to the TableView
//                self.tableView.reloadData()
//                break
//            case .error(let err):
//                // An error occurred while opening the Realm file on the background worker thread
//                fatalError("\(err)")
//                break
//            }
//        }

        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       // showChannelInfo()
        self.tableView.isUserInteractionEnabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func changedSignMessageSwitchValue(_ sender: Any) {
        var signMessageSwitchStatus : Bool?
        if signMessageSwtich.isOn {
            signMessageSwitchStatus = true
        } else if signMessageSwtich.isOn == false {
            signMessageSwitchStatus = false
        }
        requestToUpdateChannelSignature(signMessageSwitchStatus!)
        
    }
    
    func updateConnectionStatus(_ status: IGAppManager.ConnectionStatus) {
        
        switch status {
        case .connected:
            connectionStatus = .connected
        case .connecting:
            connectionStatus = .connecting
        case .waitingForNetwork:
            connectionStatus = .waitingForNetwork
        }
        
    }

    @IBAction func didTapOnCameraBtn(_ sender: UIButton) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraOption = UIAlertAction(title: "Take a Photo", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Take a Photo")
            if UIImagePickerController.availableCaptureModes(for: .rear) != nil{
                self.imagePicker.delegate = self
                self.imagePicker.allowsEditing = true
                self.imagePicker.sourceType = .camera
                self.imagePicker.cameraCaptureMode = .photo
                if UIDevice.current.userInterfaceIdiom == .phone {
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
                else {
                    self.present(self.imagePicker, animated: true, completion: nil)//4
                    self.imagePicker.popoverPresentationController?.sourceView = (sender )
                    self.imagePicker.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
                    self.imagePicker.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
                }
            }
        })
        let ChoosePhoto = UIAlertAction(title: "Choose Photo", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Choose Photo")
            self.imagePicker.delegate = self
            self.imagePicker.allowsEditing = true
            self.imagePicker.sourceType = .photoLibrary
            if UIDevice.current.userInterfaceIdiom == .phone {
                self.present(self.imagePicker, animated: true, completion: nil)
            }
            else {
                self.present(self.imagePicker, animated: true, completion: nil)//4
                self.imagePicker.popoverPresentationController?.sourceView = (sender)
                self.imagePicker.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
                self.imagePicker.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(ChoosePhoto)
        optionMenu.addAction(cancelAction)
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) == true {
            optionMenu.addAction(cameraOption)} else {
            print ("I don't have a camera.")
        }
        if let popoverController = optionMenu.popoverPresentationController {
            popoverController.sourceView = cameraButton
        }
        self.present(optionMenu, animated: true, completion: nil)
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return 4
        case 1:
            return 3
        case 2 :
            return 1
        case 3 :
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.section)

        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                if myRole == .owner || myRole == .admin {
                    self.tableView.isUserInteractionEnabled = false
                self.performSegue(withIdentifier: "showChannelInfoSetName", sender: self)
                }
            case 1:
                self.tableView.isUserInteractionEnabled = false
                self.performSegue(withIdentifier: "showChannelInfoSetDescription", sender: self)
                
            case 2:
                if myRole == .owner {
                self.tableView.isUserInteractionEnabled = false
                self.performSegue(withIdentifier: "showChannelInfoSetType", sender: self)
                }
            case 3:
                showChannelLinkAlert()
            default:
                break
            }
        }
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                self.tableView.isUserInteractionEnabled = false
                self.performSegue(withIdentifier: "showChannelInfoSetMembers", sender: self)
            case 1:
                self.tableView.isUserInteractionEnabled = false
                self.performSegue(withIdentifier: "showAdminAndModarators", sender: self)
            default:
                break
            }
        }
        if indexPath.section == 2 {
            switch indexPath.row {
            case 0:
                self.tableView.isUserInteractionEnabled = false
                self.performSegue(withIdentifier: "showSharedMadiaPage", sender: self)
            default:
                break
            }
        }
        if indexPath.section == 3 {
            if indexPath.row == 0 {
                showDeleteChannelActionSheet()

            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        
        if indexPath.section == 1 && indexPath.row == 2 && adminAndModeratorCell.isHidden == true {
            return 0.0
        }
        if indexPath.section == 1 && indexPath.row == 1 && allMemberCell.isHidden == true {
            return 0.0
        }
        if indexPath.section == 0 && indexPath.row == 3 && channelLinkCell.isHidden == true {
            return 0.0
        }
        if indexPath.section == 2 && indexPath.row == 0 && sharedMediaCell.isHidden == true {
            return 0.0
       }
       if indexPath.section == 2 && indexPath.row == 1 && notificationCell.isHidden == true {
            return 0.0
        }
        if indexPath.section == 1 && indexPath.row == 0 && channelSignMessageCell.isHidden == true {
            return 0.0
        }
        
        return 44.0
        
    }

    
    func showDeleteChannelActionSheet() {
        var title : String!
        var actionTitle: String!
        if myRole == .owner {
            title = "Are you sure you want to delete this channel?"
            actionTitle = "Delete"
        } else {
            title = "Are you sure you want to leave this channel?"
            actionTitle = "Leave"
        }
        let deleteConfirmAlertView = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: actionTitle , style:.default , handler: {
            (alert: UIAlertAction) -> Void in
            if self.myRole == .owner {
                if self.connectionStatus == .connecting || self.connectionStatus == .waitingForNetwork {
                    let alert = UIAlertController(title: "Error", message: "No Network Connection", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                self.deleteChannelRequest()
                }
            } else {
                if self.connectionStatus == .connecting || self.connectionStatus == .waitingForNetwork {
                    let alert = UIAlertController(title: "Error", message: "No Network Connection", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                self.leftChannelRequest(room: self.room!)
                }
            }
            
        })
        let cancelAction = UIAlertAction(title: "Cancel", style:.cancel , handler: {
            (alert: UIAlertAction) -> Void in
        })
        deleteConfirmAlertView.addAction(deleteAction)
        deleteConfirmAlertView.addAction(cancelAction)
        let alertActions = deleteConfirmAlertView.actions
        for action in alertActions {
            if action.title == actionTitle{
                let logoutColor = UIColor.red
                action.setValue(logoutColor, forKey: "titleTextColor")
            }
        }
        deleteConfirmAlertView.view.tintColor = UIColor.organizationalColor()
        if let popoverController = deleteConfirmAlertView.popoverPresentationController {
            popoverController.sourceView = self.tableView
            popoverController.sourceRect = CGRect(x: self.tableView.frame.midX-self.tableView.frame.midX/2, y: self.tableView.frame.midX-self.tableView.frame.midX/2, width: self.tableView.frame.midX, height: self.tableView.frame.midY)
            popoverController.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
        }
        present(deleteConfirmAlertView, animated: true, completion: nil)
    }

    func showChannelLinkAlert() {
        if selectedChannel != nil {
            var channelLink: String? = ""
            if room?.channelRoom?.type == .privateRoom {
                channelLink = room?.channelRoom?.privateExtra?.inviteLink
            }
            if room?.channelRoom?.type == .publicRoom {
                channelLink = room?.channelRoom?.publicExtra?.username
            }
            let alert = UIAlertController(title: "Channel Link", message: channelLink, preferredStyle: .alert)
            let copyAction = UIAlertAction(title: "Copy", style: .default, handler: {
                (alert: UIAlertAction) -> Void in
                UIPasteboard.general.string = channelLink
            })
            let shareAction = UIAlertAction(title: "Share", style: .default, handler: nil)
            let changeAction = UIAlertAction(title: "Change", style: .default, handler: {
                (alert: UIAlertAction) -> Void in
                if self.room?.channelRoom?.type == .publicRoom {
                    self.performSegue(withIdentifier: "showChannelInfoSetType", sender: self)
                }
                else if self.room?.channelRoom?.type == .privateRoom {
                    self.requestToRevolLink()
                }
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.view.tintColor = UIColor.organizationalColor()
            alert.addAction(copyAction)
            alert.addAction(shareAction)
            if  myRole == .owner {
            alert.addAction(changeAction)
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showChannelInfo(){
        channelNameLabelTitle.text = room?.title
        channelNameLabel.text = room?.title
        ChannelDescriptionLabel.text = room?.channelRoom?.roomDescription
        if let channelRoom = room {
            channelImage.setRoom(channelRoom)
        }
        if let channelType = room?.channelRoom?.type {
            switch channelType {
            case .privateRoom:
                channelTypeLabel.text = "Private"
                if let link = room?.channelRoom?.privateExtra?.inviteLink {
                    print(room?.channelRoom?.privateExtra?.inviteToken)
                    channelLinkLabel.text = link
                } else {
                    print("private room without a link")
                }
            case .publicRoom:
                channelTypeLabel.text = "Public"
                if let username = room?.channelRoom?.publicExtra?.username {
                    channelLinkLabel.text = "iGap.net/" + username
                } else {
                    print("public room without a username")
                }
            }
        }
        
        if let memberCount = room?.channelRoom?.participantCount {
            numberOfMemberJoinedThisChannelLabel.text = "\(memberCount)"
        }
        
        
        
//        var channelLink: String? = ""
//        if room?.channelRoom?.type == .privateRoom {
//            
//        }
//        if room?.channelRoom?.type == .publicRoom {
//            
//        }
//        if let linkTitile = channelLink {
//            
//        }
        if room?.channelRoom?.isSignature == true {
            signMessageSwtich.isOn = true
        } else { //if room?.channelRoom?.isSignature == false {
            signMessageSwtich.isOn = false
        }
    }
    
    
    func requestToGetRoom() {
        if let channelRoom = room {
            IGClientGetRoomRequest.Generator.generate(roomId: channelRoom.id).success({ (protoResponse) in
                DispatchQueue.main.async {
                    switch protoResponse {
                    case let clientGetRoomResponse as IGPClientGetRoomResponse:
                        IGClientGetRoomRequest.Handler.interpret(response: clientGetRoomResponse)
                        
                    default:
                        break
                    }
                    
                }
            }).error ({ (errorCode, waitTime) in
                switch errorCode {
                case .timeout:
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.hud.hide(animated: true)
                        self.present(alert, animated: true, completion: nil)
                    }
                default:
                    break
                }
                
            }).send()
        }
    }
    
    func requestToUpdateChannelSignature(_ signatureSwitchStatus: Bool) {
        if let channelRoom = room {
            self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            self.hud.mode = .indeterminate
            IGChannelUpdateSignatureRequest.Generator.generate(roomId: channelRoom.id, signatureStatus: signatureSwitchStatus).success({ (protoResponse) in
                DispatchQueue.main.async {
                    switch protoResponse {
                    case let channelUpdateSignatureResponse as IGPChannelUpdateSignatureResponse:
                        IGChannelUpdateSignatureRequest.Handler.interpret(response: channelUpdateSignatureResponse)
                    default:
                        break
                    }
                    self.hud.hide(animated: true)
                }
            }).error ({ (errorCode, waitTime) in
                DispatchQueue.main.async {
                    switch errorCode {
                    case .timeout:
                        let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    default:
                        break
                    }
                    self.hud.hide(animated: true)
                }
                
            }).send()
        }
    }
    
    func requestToRevolLink() {
        
        self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.hud.mode = .indeterminate
        IGChannelRevokeLinkRequest.Generator.generate(roomId: (room?.id)!).success({ (protoResponse) in
            DispatchQueue.main.async {
                switch protoResponse {
                case let channelRevokeLinkRequest as IGPChannelRevokeLinkResponse:
                   let revokeResponse = IGChannelRevokeLinkRequest.Handler.interpret(response: channelRevokeLinkRequest)
                   self.channelLinkLabel.text = revokeResponse.invitedLink
                default:
                    break
                }
                self.hud.hide(animated: true)
            }
        }).error ({ (errorCode, waitTime) in
            DispatchQueue.main.async {
                switch errorCode {
                case .timeout:
                    let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                default:
                    break
                }
                self.hud.hide(animated: true)
            }
        }).send()
    }
    
    func leftChannelRequest(room: IGRoom) {
        self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.hud.mode = .indeterminate
        IGChannelLeftRequest.Generator.generate(room: room).success({ (protoResponse) in
            DispatchQueue.main.async {
                switch protoResponse {
                case let channelLeft as IGPChannelLeftResponse:
                    IGChannelLeftRequest.Handler.interpret(response: channelLeft)
                    if self.navigationController is IGNavigationController {
                        _ = self.navigationController?.popToRootViewController(animated: true)
                    }
                default:
                    break
                }
                self.hud.hide(animated: true)
                
            }
        }).error({ (errorCode , waitTime) in
            DispatchQueue.main.async {
                switch errorCode {
                case .timeout:
                    let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                default:
                    break
                }
                self.hud.hide(animated: true)
            }
        }).send()
    }
    
    func deleteChannelRequest() {
        if let channelRoom = room {
            self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            self.hud.mode = .indeterminate
            IGChannelDeleteRequest.Generator.generate(roomID: channelRoom.id).success({ (protoResponse) in
                DispatchQueue.main.async {
                    switch protoResponse {
                    case let channelDeleteResponse as IGPChannelDeleteResponse:
                        IGChannelDeleteRequest.Handler.interpret(response: channelDeleteResponse)
                        if self.navigationController is IGNavigationController {
                        _ = self.navigationController?.popToRootViewController(animated: true)
                    }
                    default:
                        break
                    }
                    self.hud.hide(animated: true)
                   
                }
            }).error ({ (errorCode, waitTime) in
                DispatchQueue.main.async {
                    switch errorCode {
                    case .timeout:
                        let alert = UIAlertController(title: "Timeout", message: "Please try again later", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    default:
                        break
                    }
                self.hud.hide(animated: true)
                }
            }).send()
        }
        
    }
    
//    func calculateHeight(inString:String) -> CGFloat {
//        
//        let messageString = inString
//        let attributes : [String : Any] = [NSFontAttributeName : UIFont.systemFont(ofSize: 15.0)]
//        let attributedString : NSAttributedString = NSAttributedString(string: messageString, attributes: attributes)
//        let rect : CGRect = attributedString.boundingRect(with: CGSize(width: 222.0, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
//        let requredSize:CGRect = rect
//        return requredSize.height
//    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showChannelInfoSetName" {
             let destination = segue.destination as! IGChannelInfoEditNameTableViewController
                destination.room = room
        }
        if  segue.identifier == "showChannelInfoSetDescription" {
            let destination = segue.destination as! IGChannelInfoEditDescriptionTableViewController
            destination.room = room
        }
        
        if segue.identifier ==  "showChannelInfoSetType" {
            let destination = segue.destination as! IGChannelInfoEditTypeTableViewController
            destination.room = room
        }
        if segue.identifier == "showChannelInfoSetMembers" {
            let destination = segue.destination as! IGChannelInfoMemberListTableViewController
            destination.room = room
        }
        if segue.identifier == "showSharedMadiaPage" {
            let destination = segue.destination as! IGGroupSharedMediaListTableViewController
            destination.room = room
        }
        if segue.identifier == "showAdminAndModarators" {
            let destination = segue.destination as! IGChannelInfoAdminsAndModeratorsTableViewController
            destination.room = room
        }
    }
}

extension IGChannelInfoTableViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.channelImage.setImage(pickedImage)
            
            let avatar = IGFile()
            avatar.attachedImage = pickedImage
            let randString = IGGlobal.randomString(length: 32)
            avatar.primaryKeyId = randString
            avatar.name = randString
            
            IGUploadManager.sharedManager.upload(file: avatar, start: {
                
            }, progress: { (progress) in
                
            }, completion: { (uploadTask) in
                if let token = uploadTask.token {
                    IGChannelAddAvatarRequest.Generator.generate(attachment: token , roomID: (self.room?.id)!).success({ (protoResponse) in
                        DispatchQueue.main.async {
                            switch protoResponse {
                            case let avatarAddResponse as IGPChannelAvatarAddResponse:
                                let userAvatar = IGChannelAddAvatarRequest.Handler.interpret(response: avatarAddResponse)
                            default:
                                break
                            }
                        }
                    }).error({ (error, waitTime) in
                        
                    }).send()
                }
            }, failure: {
                
            })
        }
        imagePicker.dismiss(animated: true, completion: {
        })
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension IGChannelInfoTableViewController: UINavigationControllerDelegate {
    
}

