//
//  PoseListTableViewController.swift
//  ASLVisionTranslator
//
//  Created by Roman Auersvald on 02.12.2020.
//

import UIKit

class PoseListTableViewController: UITableViewController {
    
    var savedPoses : [ASLLetterPose]? {
        didSet{
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    var newPoseLetter : String?

    override func viewDidLoad() {
        super.viewDidLoad()

        
        loadPosesList()
        
         self.navigationItem.leftBarButtonItem = self.editButtonItem
    }
    
    func loadPosesList(){
        self.savedPoses = PoseDataManager.shared.loadData()
        
//        let defaults = UserDefaults.standard
//        if let savedPosesFromDefaults = defaults.object(forKey: "savedLetterPoses") as? Data {
//            let decoder = JSONDecoder()
//            if let loadedPoses = try? decoder.decode([ASLLetterPose].self, from: savedPosesFromDefaults) {
//                self.savedPoses = loadedPoses
//            }
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.loadPosesList()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.savedPoses?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ident", for: indexPath) as! LetterDateTableViewCell
        cell.lblLetter?.text = self.savedPoses![indexPath.row].letter
        cell.lblDate?.text = self.savedPoses![indexPath.row].dateTaken.toString(dateFormat: .short, timeFormat: .medium)
        cell.accessoryType = .none

        return cell
    }
    

    @IBAction func newPoseAction(_ sender: Any) {
        let ac = UIAlertController(title: "Název nového znaku", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "OK", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
            if answer.text != ""{
                self.newPoseLetter = answer.text
                self.performSegue(withIdentifier: "captureNewPose", sender: self)
            }
        }
        let cancelAction = UIAlertAction(title: "Zrušit", style: .cancel){
            [unowned ac] _ in
            ac.dismiss(animated: true, completion: nil)
        }
        ac.addAction(submitAction)
        ac.addAction(cancelAction)
        present(ac, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let letterToDelete = self.savedPoses?[indexPath.row]
            if letterToDelete != nil{
                let result = PoseDataManager.shared.deletePoseData(poseToDelete: letterToDelete!)
                let _ = result.map{if $0 == 1 {
                    self.loadPosesList()
                }}
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "captureNewPose"{
            let dest = (segue.destination as! UINavigationController).topViewController as! PoseEstimationViewController
            dest.poseForLetter = self.newPoseLetter!
            dest.poseMatching = false
        }
    }

}

extension Date{
    func toString(dateFormat: DateFormatter.Style, timeFormat: DateFormatter.Style) -> String{
        let formatter = DateFormatter()
        formatter.dateStyle = dateFormat
        formatter.timeStyle = timeFormat
        return formatter.string(from: self)
    }
}
