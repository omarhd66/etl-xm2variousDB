Set lstArgs = WScript.Arguments
For I = 0 to lstArgs.Count - 1 ' Loop through each file

    FullName = lstArgs(I)
    FileName = Left(lstArgs(I), InStrRev(lstArgs(I), ".") )

' Create Excel Objects
    Set objWS = CreateObject("Excel.application")
    set objWB = objWS.Workbooks.Open(FullName)
    

    objWS.application.visible=false
    objWS.application.displayalerts=false

	'On Error Resume Next

	For Each objWSh In objWB.Sheets
	
		If objWSh.Name = "Data" Then 
			MsgBox objWSh.Name
			
			objWSh.Copy 

			objWS.ActiveWorkbook.SaveAs objWB.Path & "\FullName " & objwsh.Name & ".csv", 6
			
			objWS.ActiveWorkbook.Close False 
		end If		
	Next
	
		objWS.Application.Quit
		objWS.Quit 
' Destroy Excel Objects


	Set objWS = Nothing
    set objWB = Nothing
    
Next

MsgBox "Successfull!"

