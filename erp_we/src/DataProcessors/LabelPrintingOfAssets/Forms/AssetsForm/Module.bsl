
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Object.Copies = 1;
	
	DefaultTemplate = Catalogs.LabelAndPriceTagTemplates.DefaultTemplate(
		Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape);
		
	If Not ValueIsFilled(DefaultTemplate) Then
		DefaultTemplate = Catalogs.LabelAndPriceTagTemplates.DefaultTemplate(
			Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper);
	EndIf;
	
	Object.LabelsTemplate = DefaultTemplate;
		
	If Parameters.Property("Assets") Then
		AddOperationObjects(Parameters.Assets);
	EndIf;
	
EndProcedure

#EndRegion

#Region TableEventHandlersAssets

&AtClient
Procedure AssetsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	NonCurrentAssetsClientServer.ProcessingElementSelection(Object.Assets, "Asset", ValueSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.AssetsAsset, ThisForm);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.Assets,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CommandParameter = New Array;
	CommandParameter.Add(PredefinedValue("Catalog.Assets.EmptyRef"));
	
	PrintManagementClient.ExecutePrintCommand(
		"DataProcessor.PrintPriceTagsAndLabels",
		"LabelOfObjectsOfOperation",
		CommandParameter,
		ThisForm,
		GetPrintSettings_());

EndProcedure

#EndRegion

#Region ServiceProcedures

&AtServer
Function GetPrintSettings_()
	
	PrintData = Object.Assets.Unload();
	InventoryNumbersOfObjects = Common.ObjectsAttributeValue(PrintData.UnloadColumn("Asset"), "AssetID");
	For Each CollectionItem In PrintData Do
		CollectionItem.Barcode = InventoryNumbersOfObjects.Get(CollectionItem.Asset);
	EndDo;
	
	PrintParameters = New Structure;
	PrintParameters.Insert("AddressInStorage", PutToTempStorage(PrintData, UUID));
	PrintParameters.Insert("LabelsTemplate", Object.LabelsTemplate);
	PrintParameters.Insert("Copies", Object.Copies);
	
	Return PrintParameters;
	
EndFunction

&AtServer
Procedure AddOperationObjects(Assets)

	QueryText = 
	"SELECT
	|	Assets.Ref AS Ref
	|FROM
	|	Catalog.Assets AS Assets
	|WHERE
	|	Assets.Ref IN HIERARCHY(&Assets)
	|	AND NOT Assets.IsFolder
	|
	|ORDER BY
	|	Assets.Description,
	|	Assets.AssetID";
	
	Query = New Query(QueryText);
	Query.SetParameter("Assets", Assets);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		RowOfTables = Object.Assets.Add();
		RowOfTables.Asset = Selection.Ref; 
	EndDo;
	

EndProcedure
 
#EndRegion
