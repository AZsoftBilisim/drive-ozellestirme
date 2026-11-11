#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	#If MobileClient Then
	If MainServerAvailable() = False Then
		OpenForm("InformationRegister.ReportsSnapshots.Form.ReportViewForm");
	Else
		OpenForm("Catalog.ReportsOptions.ListForm", , , "ReportsOptions.AllReports");
	EndIf;	
	#Else
	OpenForm("Catalog.ReportsOptions.ListForm", , , "ReportsOptions.AllReports");
	#EndIf
EndProcedure

#EndRegion