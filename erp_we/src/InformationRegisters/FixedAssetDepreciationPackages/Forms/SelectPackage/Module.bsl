
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("Filter") And Parameters.Filter.Property("Organization") Then
		Organization = Parameters.Filter.Organization;
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List, "Organization", Organization);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;
	CompleteSelection();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectPackage(Command)
	
	CompleteSelection();
	
EndProcedure

&AtClient
Procedure CalculatePackageNumbers(Command)
	
	CalculatePacketNumbersOnServer();
	Items.List.Refresh();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CompleteSelection()

	RowsArray = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If RowsArray.Count() = 0 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(RowsArray[0]);
	NotifyChoice(RowData.PackageNumber);

EndProcedure

&AtServer
Procedure CalculatePacketNumbersOnServer()

	If ValueIsFilled(Organization) Then
		CompaniesList = CommonClientServer.ValueInArray(Organization);
	Else
		CompaniesList = Undefined;
	EndIf; 
	
	InformationRegisters.FixedAssetDepreciationPackages.CreateDepreciationPackages(CompaniesList);

EndProcedure

#EndRegion
