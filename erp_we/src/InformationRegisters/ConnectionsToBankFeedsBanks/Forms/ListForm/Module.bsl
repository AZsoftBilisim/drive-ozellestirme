 
 #Region FormEventHandlers

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateFormForBankConnectionListBankFeeds" Then
		
		Items.List.Refresh();
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Connect(Command)
	
	OpenForm("InformationRegister.ConnectionsToBankFeedsBanks.Form.ConnectionForm",, 
								ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

#EndRegion
