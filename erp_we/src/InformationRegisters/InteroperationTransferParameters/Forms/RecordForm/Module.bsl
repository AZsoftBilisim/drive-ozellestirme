
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	If Not ValueIsFilled(Record.SourceRecordKey) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If WorkCenterTypeSource = 0 And Not CurrentObject.WorkCenterTypeSource.IsEmpty() Then
		CurrentObject.WorkCenterTypeSource = Catalogs.WorkCenterTypes.EmptyRef();
	EndIf; 
	
	If WorkCenterTypeDestination = 0 And Not CurrentObject.WorkCenterTypeDestination.IsEmpty() Then
		CurrentObject.WorkCenterTypeDestination = Catalogs.WorkCenterTypes.EmptyRef();
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WorkCenterTypeSourceOnChange(Item)
	
	WorkCenterTypeSource = 1
	
EndProcedure

&AtClient
Procedure WorkCenterTypeDestinationOnChange(Item)
	
	WorkCenterTypeDestination = 1;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure OnReadCreateAtServer()

	If Not Record.WorkCenterTypeSource.IsEmpty() Then
		WorkCenterTypeSource = 1
	EndIf; 
	If Not Record.WorkCenterTypeDestination.IsEmpty() Then
		WorkCenterTypeDestination = 1
	EndIf; 
	
EndProcedure

#EndRegion

#EndRegion
