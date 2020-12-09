//
//  PoseListTableViewController.swift
//  ASLVisionTranslator
//
//  Created by Roman Auersvald on 02.12.2020.
//

import UIKit

class PoseListTableViewController: UITableViewController {
    
    var savedPoses : [LetterPoseDict]? {
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
        let defaults = UserDefaults.standard
        if let savedPosesFromDefaults = defaults.object(forKey: "savedLetterPoses") as? Data {
            let decoder = JSONDecoder()
            if let loadedPoses = try? decoder.decode([LetterPoseDict].self, from: savedPosesFromDefaults) {
                self.savedPoses = loadedPoses
            }
        }
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

            let submitAction = UIAlertAction(title: "ok", style: .default) { [unowned ac] _ in
                let answer = ac.textFields![0]
                if answer.text != ""{
                    self.newPoseLetter = answer.text
                    self.performSegue(withIdentifier: "newPoseController", sender: self)
                }
                
            }

            ac.addAction(submitAction)

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
                UserDefaults.standard.removeObject(forKey: letterToDelete!.letter)
            }
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newPoseController"{
            let dest = segue.destination as! PoseCaptureViewController
            dest.poseForLetter = self.newPoseLetter!
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
