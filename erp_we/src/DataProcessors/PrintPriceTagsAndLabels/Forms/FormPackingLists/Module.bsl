
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Object.Copies = 1;
	BasicTemplate = Constants.PackingListLabelTemplate.Get();
	
	If ValueIsFilled(BasicTemplate) Then
		Object.LabelsTemplate = BasicTemplate;
	Else	
		Object.LabelsTemplate = Catalogs.LabelAndPriceTagTemplates.DefaultTemplate(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel);
	EndIf;
	
	Object.TemplateAssignment = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel;
		
	If IsTempStorageURL(Parameters.AddressInStorage) Then
		
		StructureOfParameters = GetFromTempStorage(Parameters.AddressInStorage);
		
		Object.PackingLists.Load(StructureOfParameters.PackingLists);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GeneratePackingLists(Command)
	
	NumberOfPackingSheets = 0;
	
	ToolTipText = NStr("vi = 'Hãy nhập số lượng danh sách gói';
						|ru = 'Введите количество упаковочных листов';
						|en = 'Enter quantity of packing lists'; fa = 'Enter quantity of packing lists';
						|it = 'Inserire il numero di liste di imballaggio';
						|pl = 'Wpisz ilość listów pakowych';
						|tr = 'Ürün listesi miktarını girin'");
	AddlParameters = New Structure("NumberOfPackingSheets", NumberOfPackingSheets);
	CallbackDescription = New CallbackDescription("GeneratePackingListsCompletion", ThisObject, AddlParameters);
	ShowInputValue(CallbackDescription, NumberOfPackingSheets, ToolTipText, Type("Number"));
	
EndProcedure

&AtClient
Procedure GeneratePackingListsCompletion(Value, AdditionalParameters) Export
	
	NumberOfPackingSheets = ?(Value = Undefined, AdditionalParameters.NumberOfPackingSheets, Value);
	
	If (Value <> Undefined) Then
		GeneratePackingListsServer(NumberOfPackingSheets);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPackingLists

&AtClient
Procedure PackingListsOnEditEnd(Item, NewRow, CancelEdit)
	CurrentData = Item.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.Ref) Then
		CurrentData.Barcode = PackingListBarcode(CurrentData.Ref);
	Else
		CurrentData.Barcode = "";
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Print(Command)
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CommandParameter = New Array;
	CommandParameter.Add(PredefinedValue("Document.PackingList.EmptyRef"));
	
	PrintManagementClient.ExecutePrintCommand(
		"DataProcessor.PrintPriceTagsAndLabels",
		"LabelPackingSheets",
		CommandParameter,
		ThisForm,
		GetParametersForPackingSheets());

EndProcedure

#EndRegion

#Region ServiceProcedures

&AtServer
Procedure GeneratePackingListsServer(NumberOfPackingSheets)
	
	For Account = 1 To NumberOfPackingSheets Do
		NewRow = Object.PackingLists.Add();
		DocStructure = New Structure("Kind",Enums.PackingListKinds.Outgoing);
		NewRow.Ref = Documents.PackingList.CreateHoldNew(DocStructure);
		NewRow.Barcode = Common.ObjectAttributeValue(NewRow.Ref, "Code");
	EndDo;
	
EndProcedure

&AtServer
Function GetParametersForPackingSheets()
	
	PackingLists = Object.PackingLists.Unload();
	
	PrintParameters = New Structure;
	PrintParameters.Insert("AddressInStorage",       PutToTempStorage(PackingLists, UUID));
	PrintParameters.Insert("LabelsTemplate",         Object.LabelsTemplate);
	PrintParameters.Insert("Copies",  Object.Copies);
	
	Return PrintParameters;
	
EndFunction

&AtServerNoContext
Function PackingListBarcode(Ref)

	Return Common.ObjectAttributeValue(Ref, "Code");
	
EndFunction	
	
#EndRegion
