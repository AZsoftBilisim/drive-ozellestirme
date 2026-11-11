
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Object.Copies = 1;
	Object.GenerateBarcodes = True;
	
	DefaultTemplate = Catalogs.LabelAndPriceTagTemplates.DefaultTemplate(
		Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape);
		
	If Not ValueIsFilled(DefaultTemplate) Then
		DefaultTemplate = Catalogs.LabelAndPriceTagTemplates.DefaultTemplate(
			Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper);
	EndIf;
	
	Object.LabelsTemplate = DefaultTemplate;
	
	If Parameters.Property("Nodes") Then
		AddOperationObjectNodes(Parameters.Nodes);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNodes

&AtClient
Procedure NodesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	NonCurrentAssetsClientServer.ProcessingElementSelection(
		Object.Nodes, "Node", ValueSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.NodesNode, ThisObject);
	
	OpenForm("Catalog.SubAssets.ChoiceForm", 
					PickingParameters, Items.Nodes,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CommandParameter = New Array;
	CommandParameter.Add(PredefinedValue("Catalog.SubAssets.EmptyRef"));
	
	PrintManagementClient.ExecutePrintCommand(
		"DataProcessor.PrintPriceTagsAndLabels",
		"LabelOfUnitOfObjectOfOperation",
		CommandParameter,
		ThisObject,
		GetPrintSettings_());

EndProcedure

#EndRegion

#Region ServiceProcedures

&AtServer
Function GetPrintSettings_()
	
	PrintData = Object.Nodes.Unload();
	NodesList = PrintData.UnloadColumn("Node");
	
	If Object.GenerateBarcodes Then
		RMManagementServerCall.GenerateNodeBarcodes(NodesList, True);
	EndIf;
	
	ObjectBarcodes_ = Common.ObjectsAttributeValue(NodesList, "Barcode");
	For Each CollectionItem In PrintData Do
		CollectionItem.Barcode = ObjectBarcodes_.Get(CollectionItem.Node);
	EndDo;
	
	PrintParameters = New Structure;
	PrintParameters.Insert("AddressInStorage", PutToTempStorage(PrintData, UUID));
	PrintParameters.Insert("LabelsTemplate", Object.LabelsTemplate);
	PrintParameters.Insert("Copies", Object.Copies);
	
	Return PrintParameters;
	
EndFunction

&AtServer
Procedure AddOperationObjectNodes(Nodes)

	QueryText = 
	"SELECT
	|	SubAssets.Ref AS Ref
	|FROM
	|	Catalog.SubAssets AS SubAssets
	|WHERE
	|	SubAssets.Ref IN HIERARCHY(&Nodes)
	|
	|ORDER BY
	|	SubAssets.Description,
	|	SubAssets.Barcode";
	
	Query = New Query(QueryText);
	Query.SetParameter("Nodes", Nodes);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		RowOfTables = Object.Nodes.Add();
		RowOfTables.Node = Selection.Ref; 
	EndDo;

EndProcedure
 
#EndRegion
