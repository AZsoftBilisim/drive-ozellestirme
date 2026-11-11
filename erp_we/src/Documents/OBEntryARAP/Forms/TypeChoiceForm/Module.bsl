#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TypesList = Documents.OBEntryARAP.ListOfAvailableTypesOfARAPObject(
		Parameters.BusinessOperation,
		Parameters.TheseAreSettlementsBetweenOrganizations,
		Parameters.ThisIsRetailBuyer);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTypesList

&AtClient
Procedure TypesListSelection(Item, RowSelected, Field, StandardProcessing)
	CurrentData = Items.TypesList.CurrentData;
	If CurrentData <> Undefined Then
		Close(CurrentData.Value);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	CurrentData = Items.TypesList.CurrentData;
	If CurrentData <> Undefined Then
		Close(CurrentData.Value);
	Else
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

#EndRegion
