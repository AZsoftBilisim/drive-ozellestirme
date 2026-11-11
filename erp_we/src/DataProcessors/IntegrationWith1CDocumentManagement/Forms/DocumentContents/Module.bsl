
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Document = Parameters.Document;
	DocumentID = Parameters.DocumentID;
	DocumentType = Parameters.DocumentType;
	
	SheetQuantity = Parameters.SheetQuantity;
	Copies = Parameters.Copies;
	NumberOfApplications = Parameters.NumberOfApplications;
	SheetsInApplications = Parameters.SheetsInApplications;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("SheetQuantity", SheetQuantity);
	Result.Insert("NumberOfApplications", NumberOfApplications);
	Result.Insert("Copies", Copies);
	Result.Insert("SheetsInApplications", SheetsInApplications);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion
