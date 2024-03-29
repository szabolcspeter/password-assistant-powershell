Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
 
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
function Show-Console {
   $consolePtr = [Console.Window]::GetConsoleWindow()
   #5 show
   [Console.Window]::ShowWindow($consolePtr, 5)
}
 
function Hide-Console {
   $consolePtr = [Console.Window]::GetConsoleWindow()
   #0 hide
   [Console.Window]::ShowWindow($consolePtr, 0)
}

Hide-Console

#Load Keepass
$KeePassProgramFolder = Dir C:\'Program Files'\KeePass* | Select-Object -Last 1
$KeePassEXE = Join-Path -Path $KeePassProgramFolder -ChildPath "KeePass.exe"
[Reflection.Assembly]::LoadFile($KeePassEXE)

#Set Masterkeys kdbx password
$CompositeKey = New-Object -TypeName KeePassLib.Keys.CompositeKey
$Pwd = 'k^u:5ktQs[UD/ca1utJN~;I7S$''E(qbf>QHntj{L&,Kan''QDo&BYW`Xq>u8j<2u@'
$KcpPassword = New-Object -TypeName KeePassLib.Keys.KcpPassword($Pwd)
$CompositeKey.AddUserKey( $KcpPassword )

#Set kdbx 
$IOConnectionInfo = New-Object KeePassLib.Serialization.IOConnectionInfo
$IOConnectionInfo.Path = 'C:\MUNKA\ConnectedCar\SVN_CONCAR\s03-infrastructure\MasterKeys.kdbx'
$StatusLogger = New-Object KeePassLib.Interfaces.NullStatusLogger

#Open Database
$PwDatabase = New-Object -TypeName KeePassLib.PwDatabase
$PwDatabase.Open($IOConnectionInfo, $CompositeKey, $StatusLogger)

#Main Window
$Form = New-Object system.Windows.Forms.Form
$Form.Size = New-Object Drawing.Size @(800,600)
$Form.Text = "Password Assistant"
$Icon = New-Object system.drawing.icon ("C:\Program Files\Microsoft Office\Office14\GRAPH.ICO")
$Form.Icon = $Icon
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$Form.AutoScroll = $True
$Form.MaximizeBox = $False
$Form.StartPosition = "CenterScreen"

#Icons for TreeNodes
$ImageListMain = New-Object System.Windows.Forms.ImageList
$ImageListMain.Images.Add([System.Drawing.Image]::Fromfile("c:\Users\szpeter\Coding\PowerShell\PasswordAssistant\Images\folder_old.gif"))
$ImageListMain.Images.Add([System.Drawing.Image]::Fromfile("c:\Users\szpeter\Coding\PowerShell\PasswordAssistant\Images\images.jpg"))

#TreeView Control
$treeView1Main = New-Object System.Windows.Forms.TreeView
$System_Drawing_SizeMain = New-Object System.Drawing.Size
$System_Drawing_SizeMain.Width = 790
$System_Drawing_SizeMain.Height = $Form.Height - 100
$treeView1Main.Size = $System_Drawing_SizeMain
$treeView1Main.Name = "treeView1"
$System_Drawing_PointMain = New-Object System.Drawing.Point
$System_Drawing_PointMain.X = 0
$System_Drawing_PointMain.Y = 0
$treeView1Main.Location = $System_Drawing_PointMain
$treeView1Main.DataBindings.DefaultDataSourceUpdateMode = 0
$treeView1Main.TabIndex = 0
$treeView1Main.ShowLines = $false
$treeView1Main.BackColor = [System.Drawing.Color]::LightGray
$FontMain = New-Object System.Drawing.Font("Terminal",10,[System.Drawing.FontStyle]::Regular)
$treeView1Main.Font = $FontMain 
$treeView1Main.ImageList = $ImageListMain
$treeView1Main.ImageIndex = 0
$Form.Controls.Add($treeView1Main)

#Building Tree:
$RootNodeMain = New-Object -TypeName System.Windows.Forms.TreeNode 
$RootNodeMain.Text = $PwDatabase.RootGroup.Name
$RootNodeMain.Name = $PwDatabase.RootGroup.Name
$RootNodeMain.Tag = $PwDatabase.RootGroup.Name
$treeView1Main.Nodes.Add($RootNodeMain) | Out-Null
$RootNodeMain.ImageIndex = 0
$RootNodeMain.SelectedImageIndex = 0

    Function ListEntries ($GroupEntryMain, $TreeNodeMain)
    {
    
        foreach ($EntryMain in $GroupEntryMain.GetEntries($false)) 
        {
            $NodeMain = New-Object -TypeName System.Windows.Forms.TreeNode
            $NodeMain.Text = $EntryMain.Strings.ReadSafe("Title")
            $NodeMain.Name = $NodeMain.Text
            $NodeMain.Tag = $EntryMain.Uuid.UuidBytes
            $TreeNodeMain.Nodes.Add($NodeMain) | Out-Null
            $NodeMain.ImageIndex = 1
            $NodeMain.SelectedImageIndex = 1        
        }

        foreach ($ItemMain in $GroupEntryMain.GetGroups($false)) 
        {
            $TreeNodeMain.Expand()
            $NodeMain = New-Object -TypeName System.Windows.Forms.TreeNode
			if (!$ItemMain.IsExpanded) {$NodeMain.Collapse()}
            $NodeMain.Text = $ItemMain.Name
            $NodeMain.Name = $NodeMain.Text
            $NodeMain.Tag = $ItemMain.Uuid.UuidBytes
            $TreeNodeMain.Nodes.Add($NodeMain) | Out-Null
            $NodeMain.ImageIndex = 0
            $NodeMain.SelectedImageIndex = 0
            ListEntries $ItemMain $NodeMain
        }
    }

    ListEntries $PwDatabase.RootGroup $RootNodeMain
    $treeView1Main.Sort()

#Close Database
$PwDatabase.Close()

$OpenButton = New-Object System.Windows.Forms.Button
$OpenButton.Location = New-Object System.Drawing.Size((($Form.Width-100)/2),517)
$OpenButton.Width =  100
$OpenButton.Height = 35
$OpenButton.Font = New-Object System.Drawing.Font("Terminal",13,[System.Drawing.FontStyle]::Bold)
$OpenButton.Text = "Open"
$OpenButton.Enabled = $true
$Form.Controls.Add($OpenButton)

$treeView1Main.Add_KeyPress({
        if ($_.KeyChar -eq 13)
        {
            if ($treeView1Main.SelectedNode.ImageIndex -eq 0)
            {
                if ($treeView1Main.SelectedNode.IsExpanded)
                {
                        $treeView1Main.SelectedNode.Collapse()
                }
                else
                {
                        $treeView1Main.SelectedNode.Expand()
                }
            }
        }
    })

	$treeView1Main.Add_LostFocus({
		$treeView1Main.SelectedNode.BackColor = [System.Drawing.Color]::White
		$treeView1Main.SelectedNode.ForeColor = [System.Drawing.Color]::Red
	})

	$treeView1Main.Add_GotFocus({
		$treeView1Main.SelectedNode.BackColor = [System.Drawing.Color]::LightGray
		$treeView1Main.SelectedNode.ForeColor = [System.Drawing.Color]::Black
	})



$OpenButton.Add_Click({
     #Set Masterkeys kdbx password
    $CompositeKey = New-Object -TypeName KeePassLib.Keys.CompositeKey
    $Pwd = 'k^u:5ktQs[UD/ca1utJN~;I7S$''E(qbf>QHntj{L&,Kan''QDo&BYW`Xq>u8j<2u@'
    $KcpPassword = New-Object -TypeName KeePassLib.Keys.KcpPassword($Pwd)
    $CompositeKey.AddUserKey( $KcpPassword )

    #Set kdbx 
    $IOConnectionInfo = New-Object KeePassLib.Serialization.IOConnectionInfo
    $IOConnectionInfo.Path = 'C:\MUNKA\ConnectedCar\SVN_CONCAR\s03-infrastructure\MasterKeys.kdbx'
    $StatusLogger = New-Object KeePassLib.Interfaces.NullStatusLogger

    #Open Database
    $PwDatabase = New-Object -TypeName KeePassLib.PwDatabase
    $PwDatabase.Open($IOConnectionInfo, $CompositeKey, $StatusLogger)

	#Get KDBX password
	if ($treeView1Main.SelectedNode.ImageIndex -ne 1)
	{
	  return  
    }
	
    $PwdTag = $PwDatabase.RootGroup.FindEntry($treeView1Main.SelectedNode.Tag, $true)
	$Pwd = $PwdTag.Strings.ReadSafe("Password")	
	$KdbxTitle = $PwdTag.Strings.ReadSafe("Title")
    $PwDatabase.Close()
    
    #Set KDBX password
    $CompositeKey = New-Object -TypeName KeePassLib.Keys.CompositeKey
    $KcpPassword = New-Object -TypeName KeePassLib.Keys.KcpPassword($Pwd)
    $CompositeKey.AddUserKey( $KcpPassword )
    
    #Set kdbx 
    $IOConnectionInfo = New-Object KeePassLib.Serialization.IOConnectionInfo
    if ($KdbxTitle -match '.kdbx$')
    {
        $path = Get-ChildItem -Path 'C:\MUNKA\ConnectedCar\SVN_CONCAR\s03-infrastructure\' -Filter $KdbxTitle -Recurse | Select-Object FullName
        if ([string]::IsNullOrEmpty($path))
        {
            [System.Windows.Forms.MessageBox]::Show("No such KDBX file: $KdbxTitle", 'Error', 'OK', 'Error')
            return
        }
        $IOConnectionInfo.Path = $path.fullname
    }
    else
    {
        $tmp = $KdbxTitle + '.kdbx'
        $path = Get-ChildItem -Path 'C:\MUNKA\ConnectedCar\SVN_CONCAR\s03-infrastructure\' -Filter $tmp -Recurse | Select-Object FullName
        if ([string]::IsNullOrEmpty($path))
        {
            [System.Windows.Forms.MessageBox]::Show("No such KDBX file: $tmp", 'Error', 'OK', 'Error')
            return
        }
        $IOConnectionInfo.Path = $path.fullname
    }
    $StatusLogger = New-Object KeePassLib.Interfaces.NullStatusLogger

    #Open Database
    $PwDatabase = New-Object -TypeName KeePassLib.PwDatabase
    $PwDatabase.Open($IOConnectionInfo, $CompositeKey, $StatusLogger)
    
    #Second Window
    $Form2 = New-Object system.Windows.Forms.Form
    $Form2.Size = New-Object Drawing.Size @(800,600)
    $Form2.Text = "Password Assistant"
    $Icon2 = New-Object system.drawing.icon ("C:\Program Files\Microsoft Office\Office14\GRAPH.ICO")
    $Form2.Icon = $Icon
    $Form2.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
    $Form2.AutoScroll = $True
    $Form2.MaximizeBox = $False
    $Form2.StartPosition = "CenterScreen"
    #$Form2.WindowState = "Maximized"
    
    #Icons for TreeNodes
    $ImageList = New-Object System.Windows.Forms.ImageList
    $ImageList.Images.Add([System.Drawing.Image]::Fromfile("c:\Users\szpeter\Coding\PowerShell\PasswordAssistant\Images\folder_old.gif"))
    $ImageList.Images.Add([System.Drawing.Image]::Fromfile("c:\Users\szpeter\Coding\PowerShell\PasswordAssistant\Images\images.jpg"))
    
    #TreeView Control
    $treeView1 = New-Object System.Windows.Forms.TreeView
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Width = 790
    $System_Drawing_Size.Height = $Form2.Height - 100
    $treeView1.Size = $System_Drawing_Size
    $treeView1.Name = "treeView1"
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 0
    $System_Drawing_Point.Y = 0
    $treeView1.Location = $System_Drawing_Point
    $treeView1.DataBindings.DefaultDataSourceUpdateMode = 0
    $treeView1.TabIndex = 0
    $treeView1.ShowLines = $false
    $treeView1.BackColor = [System.Drawing.Color]::LightGray
    $Font = New-Object System.Drawing.Font("Terminal",10,[System.Drawing.FontStyle]::Regular)
    $treeView1.Font = $Font 
    $treeView1.ImageList = $ImageList
    $treeView1.ImageIndex = 0
    $Form2.Controls.Add($treeView1)
    
    $UserButton = New-Object System.Windows.Forms.Button
    $UserButton.Location = New-Object System.Drawing.Size(50,520)
    $UserButton.Width =  200
    $UserButton.Height = 35
    $UserButton.Font = New-Object System.Drawing.Font("Terminal",13,[System.Drawing.FontStyle]::Bold)
    $UserButton.Text = "Copy Username"
    $Form2.Controls.Add($UserButton)
    
    $PwdButton = New-Object System.Windows.Forms.Button
    $PwdButton.Location = New-Object System.Drawing.Size(300,520)
    $PwdButton.Width =  200
    $PwdButton.Height = 35
    $PwdButton.Font = New-Object System.Drawing.Font("Terminal",13,[System.Drawing.FontStyle]::Bold)
    $PwdButton.Text = "Copy Password"
    $Form2.Controls.Add($PwdButton)
    
	$MyButton = New-Object System.Windows.Forms.Button
    $MyButton.Location = New-Object System.Drawing.Size(550,520)
    $MyButton.Width =  200
    $MyButton.Height = 35
    $MyButton.Font = New-Object System.Drawing.Font("Terminal",13,[System.Drawing.FontStyle]::Bold)
    $MyButton.Text = "My Password"
    $Form2.Controls.Add($MyButton)
	
    #Building Tree:
    $RootNode = New-Object -TypeName System.Windows.Forms.TreeNode 
    $RootNode.Text = $PwDatabase.RootGroup.Name
    $RootNode.Name = $PwDatabase.RootGroup.Name
    $RootNode.Tag = $PwDatabase.RootGroup.Name
    $treeView1.Nodes.Add($RootNode) | Out-Null
    $RootNode.ImageIndex = 0
    $RootNode.SelectedImageIndex = 0
    
    Function ListEntries ($GroupEntry, $TreeNode)
    {
    
        foreach ($Entry in $GroupEntry.GetEntries($false)) 
        {
            $Node = New-Object -TypeName System.Windows.Forms.TreeNode
            $Node.Text = $Entry.Strings.ReadSafe("Title")
            $Node.Name = $Node.Text
            $Node.Tag = $Entry.Uuid.UuidBytes
            $TreeNode.Nodes.Add($Node) | Out-Null
            $Node.ImageIndex = 1
            $Node.SelectedImageIndex = 1        
        }

        foreach ($Item in $GroupEntry.GetGroups($false)) 
        {
            $TreeNode.Expand()
            $Node = New-Object -TypeName System.Windows.Forms.TreeNode
			if (!$Item.IsExpanded) {$Node.Collapse()}
            $Node.Text = $Item.Name
            $Node.Name = $Node.Text
            $Node.Tag = $Item.Uuid.UuidBytes
            $TreeNode.Nodes.Add($Node) | Out-Null
            $Node.ImageIndex = 0
            $Node.SelectedImageIndex = 0
            ListEntries $Item $Node
        }
    }

    ListEntries $PwDatabase.RootGroup $RootNode
    $treeView1.Sort()
    $PwDatabase.Close()

    $treeView1.Add_KeyPress({
        if ($_.KeyChar -eq 13)
        {
            if ($treeView1.SelectedNode.ImageIndex -eq 0)
            {
                if ($treeView1.SelectedNode.IsExpanded)
                {
                        $treeView1.SelectedNode.Collapse()
                }
                else
                {
                        $treeView1.SelectedNode.Expand()
                }
            }
        }
    })

	$treeView1.Add_LostFocus({
		$treeView1.SelectedNode.BackColor = [System.Drawing.Color]::White
		$treeView1.SelectedNode.ForeColor = [System.Drawing.Color]::Red
	})

	$treeView1.Add_GotFocus({
		$treeView1.SelectedNode.BackColor = [System.Drawing.Color]::LightGray
		$treeView1.SelectedNode.ForeColor = [System.Drawing.Color]::Black
	})
	
    $UserButton.Add_Click({
        if ($treeView1.SelectedNode.ImageIndex -eq 1)
        {
            $PwDatabase.Open($IOConnectionInfo, $CompositeKey, $StatusLogger)
            $User = $PwDatabase.RootGroup.FindEntry($treeView1.SelectedNode.Tag, $true)
            $Username = $User.Strings.ReadSafe("UserName")
            $PwDatabase.Close()
            [System.Windows.Forms.Clipboard]::Clear()
            [System.Windows.Forms.Clipboard]::SetText($Username)
        }
    })
    
    $PwdButton.Add_Click({
        if ($treeView1.SelectedNode.ImageIndex -eq 1)
        {
            $PwDatabase.Open($IOConnectionInfo, $CompositeKey, $StatusLogger)
            $Password = $PwDatabase.RootGroup.FindEntry($treeView1.SelectedNode.Tag, $true)
            $PWD = $Password.Strings.ReadSafe("Password")
            $PwDatabase.Close()
			[System.Windows.Forms.Clipboard]::Clear()
            [System.Windows.Forms.Clipboard]::SetText($PWD)
        }
    })
	
	$MyButton.Add_Click({
		[System.Windows.Forms.Clipboard]::Clear()
		[System.Windows.Forms.Clipboard]::SetText('Jyn9UXq26uFNHTo9RYZd')
	})
	    
    $Form2.ShowDialog()
})

$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog($this)



