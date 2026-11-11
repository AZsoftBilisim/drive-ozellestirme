#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillInDefaultValues();
	
	Object.Documentreceivings = Parameters.Documentreceivings;
	
	If ValueIsFilled(Object.Documentreceivings) Then
		FillInServerAccordingToAcceptanceDocument();
	Else
		MessageText = NStr("vi = 'Xem xét mở biểu mẫu từ chứng từ tiếp nhận hàng hóa vào kho';
							|ru = 'Предусмотрено открытие формы только из документа приемки товаров на склад';
							|en = 'You can open the form only from the document of goods receipt at warehouse'; fa = 'You can open the form only from the document of goods receipt at warehouse';
							|it = 'Viene fornita l''apertura del modulo solo dal documento del ricevimento merci in magazzino';
							|pl = 'Przewidziano otwarcie formularza tylko z dokumentu przyjęcia towarów do magazynu';
							|tr = 'Formu sadece ambara mal girişi belgesinden açmak mümkündür'");
		
		Raise MessageText;
	EndIf;
	
	SetItemsVisibility();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Cancel = True;
		
		Return;
	EndIf;
	
	If Not ClosingInProgress
		And Modified Then
		
		Cancel = True;
		
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		
		CheckModifiability(CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(ResultModifiability, AdditionalParameters) Export
	
	If ResultModifiability = True Then
		Return;
	EndIf;
	
	ClosingInProgress = True;
	
	Close();
	
	ClosingInProgress = False;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMainStorageBins

&AtClient
Procedure MainStorageBinsOnChange(Item)
	
	ThisForm.Modified = True;
	
EndProcedure

&AtClient
Procedure MainStorageBinsOnActivateRow(Item)
	
	CurrentData = Items.MainStorageBins.CurrentData;
	
	If CurrentData <> Undefined Then
		Filter = New FixedStructure("Products, Warehouse", CurrentData.Products, CurrentData.Warehouse);
		
		Items.AdditionalStorageBins.RowFilter = Filter;
	Else
		Filter = New FixedStructure("Products, Warehouse", Undefined, Undefined);
		
		Items.AdditionalStorageBins.RowFilter = Filter;
	EndIf;
	
EndProcedure

&AtClient
Procedure MainStorageBinsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If Item = ThisForm.CurrentItem Then
		DragParameters.Action = DragAction.Cancel;
	Else
		DragParameters.Action = DragAction.Move;
	EndIf;
	
EndProcedure

&AtClient
Procedure MainStorageBinsDragEnd(Item, DragParameters, StandardProcessing)
	
	StandardProcessing = False;
	
	If DragParameters.Action <> DragAction.Cancel Then
		
		CurrentData = Items.MainStorageBins.CurrentData;
		
		ProcessAssignmentOfAdditionalCell(CurrentData.Products, CurrentData.Warehouse, CurrentData.Cell);
		
		Filter = New FixedStructure("Products, Warehouse",CurrentData.Products, CurrentData.Warehouse);
		
		Items.AdditionalStorageBins.RowFilter = Filter;
		Items.AdditionalStorageBins.Refresh();
		
		ThisForm.Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MainStorageBinsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure MainStorageBinsCellOnChange(Item)
	
	CurrentData = Items.MainStorageBins.CurrentData;
	
	ProcessPrimaryCellAssignment(CurrentData.Products, CurrentData.Warehouse, CurrentData.Cell, False);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAdditionalStorageBins

&AtClient
Procedure AdditionalStorageBinsOnChange(Item)
	
	ThisForm.Modified = True;
	
EndProcedure

&AtClient
Procedure AdditionalStorageBinsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Items.AdditionalStorageBins.RowFilter = Undefined
		Or Not ValueIsFilled(Items.AdditionalStorageBins.RowFilter.Products) Then
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalStorageBinsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		CurrentData = Items.AdditionalStorageBins.CurrentData;
		FillPropertyValues(CurrentData, Items.AdditionalStorageBins.RowFilter);
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalStorageBinsCellOnChange(Item)
	
	CurrentData = Items.AdditionalStorageBins.CurrentData;
	
	ProcessAssignmentOfAdditionalCell(CurrentData.Products, CurrentData.Warehouse, CurrentData.Cell);
	
EndProcedure

&AtClient
Procedure AdditionalStorageBinsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If Item = ThisForm.CurrentItem Then
		DragParameters.Action = DragAction.Cancel;
	Else
		DragParameters.Action = DragAction.Move;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalStorageBinsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure AdditionalStorageBinsDragEnd(Item, DragParameters, StandardProcessing)
	
	If DragParameters.Action <> DragAction.Cancel Then
		
		CurrentData = Items.AdditionalStorageBins.CurrentData;
		
		ProcessPrimaryCellAssignment(CurrentData.Products, CurrentData.Warehouse, CurrentData.Cell, True);
		
		Items.MainStorageBins.Refresh();
		
		ThisForm.Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteToRegister(Command)
	
	ThisForm.Modified = WriteToRegisterServer();
	
EndProcedure

&AtClient
Procedure PrintJobsForInventoryPickingPlacementAndRecount(Command)
	
	ClearMessages();
	
	CallbackDescription = New CallbackDescription("PrintJobsForInventoryPickingPlacementAndRecountCompletion", ThisObject);
	
	CheckModifiability(CallbackDescription);
	
EndProcedure

&AtClient
Procedure PrintJobsForInventoryPickingPlacementAndRecountCompletion(ResultModifiability, AdditionalParameters) Export
	
	If ResultModifiability = True Then
		Return;
	EndIf;
	
	Array = New Array;
	Array.Add(Object.Documentreceivings);
	
	PrintRule = PrintRules[0].Value;
	
	PrintParameters = New Structure;
	PrintParameters.Insert("JobType", "PlacementJob");
	PrintParameters.Insert("NoExtraCharge");
	
	If Not PrintRule.ThisIsAnInvoice Then
		PrintParameters.Insert("PrintingFromDocumentData");
	EndIf;
	
	PrintManagementClient.ExecutePrintCommand("DataProcessor.PrintJobsForInventoryPickingPlacementAndRecount",
													"GoodsPickingPlacementJob",
													Array,
													ThisForm,
													PrintParameters);
	
EndProcedure

#Region CommandHandlersFormTablesMainCells

&AtClient
Procedure TurnCellIntoTheAdditionalOne(Command)
	
	CurrentData = Items.MainStorageBins.CurrentData;
	
	If CurrentData <> Undefined Then
		
		ProcessAssignmentOfAdditionalCell(CurrentData.Products, CurrentData.Warehouse, CurrentData.Cell);
		
		Filter = New FixedStructure("Products, Warehouse", CurrentData.Products, CurrentData.Warehouse);
		
		Items.AdditionalStorageBins.RowFilter = Filter;
		Items.AdditionalStorageBins.Refresh();
		
		ThisForm.Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableCommandHandlersAdditionalCells

&AtClient
Procedure TurnCellIntoTheMasterOne(Command)
	
	CurrentData = Items.AdditionalStorageBins.CurrentData;
	
	If CurrentData <> Undefined Then
		
		ProcessPrimaryCellAssignment(CurrentData.Products,CurrentData.Warehouse, CurrentData.Cell, True);
		
		ThisForm.Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure FillInDefaultValues()
	
	Object.Warehouse = SettingsValueCached.GetDefaultWarehouse(Object.Warehouse);
	
EndProcedure

&AtServer
Procedure FillInServerAccordingToAcceptanceDocument()
	
	Object.MainStorageBins.Clear();
	Object.AdditionalStorageBins.Clear();
	
	InitializePrintingRules(Object.Documentreceivings);
	
	DocumentData	= GetDocumentData(Object.Documentreceivings);
	ErrorText		= TextOfDocumentDataValidationError(Object.Documentreceivings, DocumentData);
	
	If Not IsBlankString(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
	InitializeStorageLocations(Object.Documentreceivings, DocumentData);
	InitializeCellTables(DocumentData);
	
EndProcedure

&AtServer
Procedure InitializePrintingRules(Documentreceivings)
	
	ManagerOfDocument		= Common.ObjectManagerByRef(Documentreceivings);
	DocumentPrintingRules	= ManagerOfDocument.RulesForPrintingTasksForSelectionPlacement();
	
	If TypeOf(DocumentPrintingRules) <> Type("Array") Then
		PrintRules.Add(DocumentPrintingRules);
	Else
		For Each PrintRule In DocumentPrintingRules Do
			If Not PrintRule.ReceiptOperation Then
				Continue;
			EndIf;
			
			PrintRules.Add(PrintRule);
		EndDo;
	EndIf;
	
EndProcedure

// Returns the information of the goods acceptance document.
//
// Parameters:
//	Documentreceivings - DocumentRef - link to the document in the information database.
//
// Returns:
//	Structure - a collection containing information from the goods acceptance document and having the following properties:
//		* ResultByDocumentHeader - QueryResult - data for the document header.
//		* DocumentWithoutGoods - Boolean - a sign of the absence of goods in the document.
//		* DocumentVerificationResult - QueryResult - data on the application of the order policy in the document warehouse.
//		* ResultForTabularPart - QueryResult - data about the goods of the document.
//
&AtServer
Function GetDocumentData(Documentreceivings)
	
	DocumentName				= Documentreceivings.Metadata().FullName();
	RequestPacketSeparator	= Common.QueryBatchSeparator();
	
	QueryTexts = New Array;
	QueryTexts.Add(RequestTextTTDocumentData(DocumentName));
	QueryTexts.Add(QueryTextTTGoodsOfAcceptanceDocument(DocumentName));
	QueryTexts.Add(QueryTextTTDocumentGoods(DocumentName));
	QueryTexts.Add(QueryTextDocumentWithoutGoods(DocumentName));
	QueryTexts.Add(DataRequestTextOfAcceptanceDocument());
	QueryTexts.Add(QueryTextDocumentGoods());
	
	QueryText = StrConcat(QueryTexts, RequestPacketSeparator);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Documentreceivings",		Documentreceivings);
	Query.SetParameter("ObjectsArray",			Documentreceivings);
	Query.SetParameter("ReceiptOperation",	True);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatchWithIntermediateData();
	SetPrivilegedMode(False);
	
	MaxIndex = Result.UBound();
	
	DocumentData = New Structure;
	DocumentData.Insert("ResultByDocumentHeader",	Result[MaxIndex - 5]);
	DocumentData.Insert("DocumentWithoutGoods",			Result[MaxIndex - 2].IsEmpty());
	DocumentData.Insert("DocumentVerificationResult",	Result[MaxIndex - 1]);
	DocumentData.Insert("ResultForTabularPart",	Result[MaxIndex]);
	
	Return DocumentData;
	
EndFunction

#Region TextsOfDocumentDataRequests

&AtServer
Function RequestTextTTDocumentData(DocumentName)
	
	TextsOfNestedTables	= New Array;
	MergeText		= TMCommonUse.QuerySeparatorInJoin();
	QueryText			= DocumentDataRequestTextTemplate();
	
	For Each PrintRule In PrintRules Do
		TextOfDocumentDataRequest = TextOfDocumentDataRequest(DocumentName, PrintRule.Value);
		
		TextsOfNestedTables.Add(TextOfDocumentDataRequest);
	EndDo;
	
	QueryTextTT	= StrConcat(TextsOfNestedTables, MergeText);
	QueryText	= StrReplace(QueryText, "&AcceptanceData", "(" + QueryTextTT + ")");
	
	Return QueryText;
	
EndFunction

&AtServer
Function DocumentDataRequestTextTemplate()
	
	QueryTextTemplate2 = 
	"SELECT DISTINCT
	|	AcceptanceData.Ref							AS Ref,
	|	AcceptanceData.Date								AS Date,
	|	AcceptanceData.Warehouse								AS Warehouse,
	|	AcceptanceData.WarehousePresentation				AS WarehousePresentation,
	|	AcceptanceData.Premise							AS Premise,
	|	AcceptanceData.PremisePresentation			AS PremisePresentation,
	|	AcceptanceData.ThisIsAnInvoice						AS ThisIsAnInvoice,
	|	AcceptanceData.BinLocationWarehousingIsUsed		AS BinLocationWarehousingIsUsed,
	|	AcceptanceData.ReferenceStorageIsUsed	AS ReferenceStorageIsUsed,
	|	AcceptanceData.CheckWarehouseOrder			AS CheckWarehouseOrder,
	|	AcceptanceData.AdvancedWarehousingIsUsed			AS AdvancedWarehousingIsUsed
	|INTO AcceptanceData
	|FROM
	|	&AcceptanceData AS AcceptanceData";
	
	Return QueryTextTemplate2;
	
EndFunction

&AtServer
Function TextOfDocumentDataRequest(DocumentName, PrintRule)
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Ref					AS Ref,
	|	DocumentData.Date					AS Date,
	|	PRESENTATION(DocumentData.Ref)	AS RefPresentation,
	|	&Warehouse									AS Warehouse,
	|	PRESENTATION(&Warehouse)					AS WarehousePresentation,
	|	&Premise								AS Premise,
	|	PRESENTATION(&Premise)				AS PremisePresentation,
	|	&ThisIsAnInvoice							AS ThisIsAnInvoice,
	|	&BinLocationWarehousingIsUsed			AS BinLocationWarehousingIsUsed,
	|	&ReferenceStorageIsUsed			AS ReferenceStorageIsUsed,
	|	&CheckWarehouseOrder				AS CheckWarehouseOrder,
	|	&AdvancedWarehousingIsUsed				AS AdvancedWarehousingIsUsed
	|FROM
	|	&TheTableNameOfTheDocument AS DocumentData
	|,&TableJoinText
	|WHERE
	|	DocumentData.Ref = &Documentreceivings
	|AND &TextOfDocumentDataCondition";
	
	If PrintRule.VHFWarehouses Then
		TableJoinText	= TextOfDataConnectionOfSTCHDocument(DocumentName, PrintRule.NameTSGoods);
		ConditionText			= TextOfDocumentDataCondition();
	Else
		TableJoinText	= "";
		ConditionText			= "";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TheTableNameOfTheDocument",			DocumentName);
	QueryText = StrReplace(QueryText, ",&TableJoinText",		TableJoinText);
	QueryText = StrReplace(QueryText, "AND &TextOfDocumentDataCondition",	ConditionText);
	
	DocumentFieldValues = DocumentFieldValues();
	FillInValuesOfDocumentFields(DocumentFieldValues, PrintRule);
	
	For Each Simple In DocumentFieldValues Do
		SearchString = "&" + Simple.Key;
		QueryText = StrReplace(QueryText, SearchString, Simple.Value);
	EndDo;
	
	Return QueryText;
	
EndFunction

&AtServer
Function TextOfDataConnectionOfSTCHDocument(DocumentName, TSName)
	
	DocumentTSName = DocumentName + "." + TSName;
	
	TableJoinText = 
	"		INNER JOIN &NameTSGoods AS DocumentGoods
	|		ON DocumentData.Ref = DocumentGoods.Ref";
	
	TableJoinText = StrReplace(TableJoinText, "&NameTSGoods", DocumentTSName);
	
	Return TableJoinText;
	
EndFunction

&AtServer
Function TextOfDocumentDataCondition()
	
	TextOfDocumentDataCondition = 
	"	AND &Warehouse REFS Catalog.Warehouses
	|	AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)";
	
	Return TextOfDocumentDataCondition;
	
EndFunction

&AtServer
Function DocumentFieldValues()
	
	DocumentFieldValues = New Structure;
	DocumentFieldValues.Insert("Warehouse");
	DocumentFieldValues.Insert("Premise");
	DocumentFieldValues.Insert("ThisIsAnInvoice");
	DocumentFieldValues.Insert("BinLocationWarehousingIsUsed");
	DocumentFieldValues.Insert("ReferenceStorageIsUsed");
	DocumentFieldValues.Insert("CheckWarehouseOrder");
	DocumentFieldValues.Insert("AdvancedWarehousingIsUsed");
	
	Return DocumentFieldValues;
	
EndFunction

&AtServer
Procedure FillInValuesOfDocumentFields(FieldValues, PrintRule)
	
	ThisIsAnInvoice				= PrintRule.ThisIsAnInvoice;
	SurplusesRecord			= PrintRule.SurplusesRecord;
	SourceOfBankingDetails			= ?(PrintRule.VHFWarehouses, "DocumentGoods.", "DocumentData.");
	UsedPremises		= ValueIsFilled(PrintRule.FieldNameRoom);
	DefaultRoom		= "VALUE(Catalog.Warerooms.EmptyRef)";
	CheckWarehouseOrder	= ThisIsAnInvoice
									And Not UsedPremises
									And Not PrintRule.AdjustmentOfGoods;
	
	Warehouse		= SourceOfBankingDetails + PrintRule.WarehouseFieldName;
	Premise	= ?(UsedPremises, "DocumentData." + PrintRule.FieldNameRoom, DefaultRoom);
	
	FieldValues.Warehouse								= Warehouse;
	FieldValues.Premise							= Premise;
	FieldValues.ThisIsAnInvoice						= ?(ThisIsAnInvoice, "TRUE", "FALSE");
	FieldValues.BinLocationWarehousingIsUsed		= TextAddressStorageIsUsed(ThisIsAnInvoice, Warehouse, Premise);
	FieldValues.ReferenceStorageIsUsed	= TextUsedReferenceStorage(UsedPremises,
																							Warehouse,
																							Premise);
	FieldValues.CheckWarehouseOrder			= ?(CheckWarehouseOrder, "TRUE", "FALSE");
	FieldValues.AdvancedWarehousingIsUsed			= TextOrderSchemeIsUsed(CheckWarehouseOrder,
																					SurplusesRecord,
																					Warehouse);
	
EndProcedure

&AtServer
Function TextAddressStorageIsUsed(ThisIsAnInvoice, Source_Warehouse, RoomSource)
	
	If ThisIsAnInvoice Then
		QueryText = "FALSE";
	Else
		QueryText = 
		"ISNULL(CASE
		|		WHEN DocumentData.Warehouse.UseWarerooms
		|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWareroomUse
		|			THEN CASE
		|					WHEN DocumentData.Premise.UseBinLocationWarehousing
		|							AND DocumentData.Date >= DocumentData.Premise.StartDateOfUsingWarehouseBinSystem
		|						THEN TRUE
		|					ELSE FALSE
		|				END
		|		ELSE CASE
		|				WHEN DocumentData.Warehouse.UseBinLocationWarehousing
		|						AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfUsingWarehouseBinSystem
		|					THEN TRUE
		|				ELSE FALSE
		|			END
		|	END, FALSE)";  //@Query-part
		
		QueryText = StrReplace(QueryText, "DocumentData.Warehouse",		Source_Warehouse);
		QueryText = StrReplace(QueryText, "DocumentData.Premise",	RoomSource);
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Function TextUsedReferenceStorage(UsedPremises, Source_Warehouse, RoomSource)
	
	If UsedPremises Then
		QueryText = 
		"ISNULL(CASE
		|		WHEN DocumentData.Warehouse.UseWarerooms
		|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWareroomUse
		|			THEN CASE
		|					WHEN DocumentData.Premise.UseBinLocationWarehousingForInformation
		|							AND (NOT DocumentData.Premise.UseBinLocationWarehousing
		|								OR DocumentData.Date < DocumentData.Premise.StartDateOfUsingWarehouseBinSystem)
		|						THEN TRUE
		|					ELSE FALSE
		|				END
		|		ELSE CASE
		|				WHEN DocumentData.Warehouse.UseBinLocationWarehousingForInformation
		|						AND (NOT DocumentData.Warehouse.UseBinLocationWarehousing
		|							OR DocumentData.Date < DocumentData.Warehouse.StartDateOfUsingWarehouseBinSystem)
		|					THEN TRUE
		|				ELSE FALSE
		|			END
		|	END, FALSE)";  //@Query-part
		
		QueryText = StrReplace(QueryText, "DocumentData.Premise", RoomSource);
	Else
		QueryText = 
		"ISNULL(CASE
		|		WHEN DocumentData.Warehouse.UseBinLocationWarehousingForInformation
		|				AND (NOT DocumentData.Warehouse.UseBinLocationWarehousing
		|					OR DocumentData.Date < DocumentData.Warehouse.StartDateOfUsingWarehouseBinSystem)
		|			THEN TRUE
		|		ELSE FALSE
		|	END, FALSE)";  //@Query-part
	EndIf;
	
	QueryText = StrReplace(QueryText, "DocumentData.Warehouse", Source_Warehouse);
	
	Return QueryText;
	
EndFunction

&AtServer
Function TextOrderSchemeIsUsed(CheckWarehouseOrder, SurplusesRecord, Source_Warehouse)
	
	If CheckWarehouseOrder Then
		QueryText = 
		"ISNULL(CASE
		|		WHEN DocumentData.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|			THEN TRUE
		|		ELSE FALSE
		|	END, FALSE)";  //@Query-part
		
		WarehouseOperation = ?(SurplusesRecord, "WhenReflectingSurplusShortages", "OnReceipt");
		
		QueryText = StrReplace(QueryText, "OnReceipt",			WarehouseOperation);
		QueryText = StrReplace(QueryText, "DocumentData.Warehouse",	Source_Warehouse);
	Else
		QueryText = "FALSE";
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Function DataRequestTextOfAcceptanceDocument()
	
	QueryText = 
	"SELECT
	|	AcceptanceData.Ref							AS Ref,
	|	AcceptanceData.Warehouse								AS Warehouse,
	|	AcceptanceData.WarehousePresentation				AS WarehousePresentation,
	|	AcceptanceData.PremisePresentation			AS PremisePresentation,
	|	AcceptanceData.ThisIsAnInvoice						AS ThisIsAnInvoice,
	|	AcceptanceData.BinLocationWarehousingIsUsed		AS BinLocationWarehousingIsUsed,
	|	AcceptanceData.ReferenceStorageIsUsed	AS ReferenceStorageIsUsed,
	|	AcceptanceData.AdvancedWarehousingIsUsed			AS AdvancedWarehousingIsUsed
	|FROM
	|	AcceptanceData AS AcceptanceData
	|WHERE
	|	AcceptanceData.CheckWarehouseOrder
	|	AND (AcceptanceData.AdvancedWarehousingIsUsed
	|		OR AcceptanceData.BinLocationWarehousingIsUsed
	|		OR NOT AcceptanceData.ReferenceStorageIsUsed)
	|
	|UNION ALL
	|
	|SELECT
	|	AcceptanceData.Ref							AS Ref,
	|	AcceptanceData.Warehouse								AS Warehouse,
	|	AcceptanceData.WarehousePresentation				AS WarehousePresentation,
	|	AcceptanceData.PremisePresentation			AS PremisePresentation,
	|	AcceptanceData.ThisIsAnInvoice						AS ThisIsAnInvoice,
	|	AcceptanceData.BinLocationWarehousingIsUsed		AS BinLocationWarehousingIsUsed,
	|	AcceptanceData.ReferenceStorageIsUsed	AS ReferenceStorageIsUsed,
	|	AcceptanceData.AdvancedWarehousingIsUsed			AS AdvancedWarehousingIsUsed
	|FROM
	|	AcceptanceData AS AcceptanceData
	|WHERE
	|	NOT AcceptanceData.CheckWarehouseOrder
	|	AND (AcceptanceData.BinLocationWarehousingIsUsed
	|		OR NOT AcceptanceData.ReferenceStorageIsUsed)";
	
	Return QueryText;
	
EndFunction

&AtServer
Function QueryTextDocumentWithoutGoods(DocumentName)
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Ref AS Ref
	|FROM
	|	&TheTableNameOfTheDocument AS DocumentData
	|		LEFT JOIN AcceptanceData AS AcceptanceData
	|		ON DocumentData.Ref = AcceptanceData.Ref
	|WHERE
	|	DocumentData.Ref = &Documentreceivings
	|	AND AcceptanceData.Ref IS NULL";
	
	QueryText = StrReplace(QueryText, "&TheTableNameOfTheDocument", DocumentName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region QueriesTextsDocumentGoods

&AtServer
Function QueryTextTTGoodsOfAcceptanceDocument(DocumentName)
	
	If Not UseDocumentData(DocumentName) Then
		ObjectManager	= Common.ObjectManagerByFullName(DocumentName);
		QueryText	= ObjectManager.TextOfGoodsRequestDocumentForPrintingTaskForSelectingPlacingGoods();
		
		QueryText = StrReplace(QueryText, "INTO DocumentGoods", "INTO GoodsOfAcceptanceDocument");
	Else
		TextsOfNestedTables	= New Array;
		MergeText		= TMCommonUse.QuerySeparatorInJoin();
		QueryText			= TemplateForRequestTextOfGoodsAcceptanceDocument();
		
		TSName = "";
		
		For Each ListValue In PrintRules Do
			PrintRule = ListValue.Value;
			
			If PrintRule.NameTSGoods = TSName Then
				Continue;
			EndIf;
			
			QueryTextDocumentGoods = QueryTextGoodsOfAcceptanceDocument(DocumentName, PrintRule);
			
			TextsOfNestedTables.Add(QueryTextDocumentGoods);
		EndDo;
		
		QueryTextTT	= StrConcat(TextsOfNestedTables, MergeText);
		QueryText	= StrReplace(QueryText, "#DocumentGoods", "(" + QueryTextTT + ")");
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Function TemplateForRequestTextOfGoodsAcceptanceDocument()
	
	QueryTextTemplate2 =
	"SELECT
	|	TableOfGoods.Ref				AS Ref,
	|	TableOfGoods.Warehouse				AS Warehouse,
	|	TableOfGoods.Premise			AS Premise,
	|	MIN(TableOfGoods.LineNumber)	AS LineNumber,
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic
	|INTO GoodsOfAcceptanceDocument
	|FROM
	|	#DocumentGoods AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.Premise,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic
	|
	|INDEX BY
	|	Ref,
	|	Warehouse,
	|	Premise,
	|	Products,
	|	Characteristic";
	
	Return QueryTextTemplate2;
	
EndFunction

&AtServer
Function QueryTextGoodsOfAcceptanceDocument(DocumentName, PrintRule)
	
	QueryText =
	"SELECT
	|	DocumentGoods.Ref			AS Ref,
	|	&Warehouse							AS Warehouse,
	|	&Premise						AS Premise,
	|	DocumentGoods.LineNumber		AS LineNumber,
	|	DocumentGoods.Products	AS Products,
	|	DocumentGoods.Characteristic	AS Characteristic
	|FROM
	|	#NameTSGoods AS DocumentGoods
	|	,#TableJoinText AS ExternalTable
	|
	|WHERE
	|	DocumentGoods.Ref = &Documentreceivings";
	
	DocumentTSName = DocumentName + "." + PrintRule.NameTSGoods;
	
	TableJoinText = "";
	
	If Not PrintRule.VHFWarehouses Then
		TableJoinText = 
		"		INNER JOIN &TheTableNameOfTheDocument AS DocumentData
		|		ON DocumentGoods.Ref = DocumentData.Ref";
		
		TableJoinText = StrReplace(TableJoinText, "&TheTableNameOfTheDocument", DocumentName);
	EndIf;
	
	QueryText = StrReplace(QueryText, "#NameTSGoods", DocumentTSName);
	QueryText = StrReplace(QueryText, ",#TableJoinText AS ExternalTable", TableJoinText);
	
	DocumentFieldValues = DocumentFieldValues();
	FillInValuesOfDocumentFields(DocumentFieldValues, PrintRule);
	
	For Each Simple In DocumentFieldValues Do
		SearchString = "&" + Simple.Key;
		QueryText = StrReplace(QueryText, SearchString, Simple.Value);
	EndDo;
	
	Return QueryText;
	
EndFunction

&AtServer
Function QueryTextTTDocumentGoods(DocumentName)
	
	PrintRule = PrintRules[0].Value;
	
	If PrintRule.ThisIsAnInvoice Then
		
		QueryText = 
		"SELECT DISTINCT
		|	ProductStock.Recorder				AS Ref,
		|	ProductStock.Warehouse					AS Warehouse,
		|	ProductStock.Premise				AS Premise,
		|	ISNULL(MIN(DocumentGoods.LineNumber), MIN(ProductStock.LineNumber)) AS LineNumber,
		|	ProductStock.Products			AS Products,
		|	ProductStock.Characteristic			AS Characteristic
		|INTO DocumentGoods
		|FROM
		|	AccumulationRegister.ProductStock AS ProductStock
		|		LEFT JOIN GoodsOfAcceptanceDocument AS DocumentGoods
		|		ON ProductStock.Recorder = DocumentGoods.Ref
		|			AND ProductStock.Warehouse = DocumentGoods.Warehouse
		|			AND ProductStock.Premise = DocumentGoods.Premise
		|			AND ProductStock.Products = DocumentGoods.Products
		|			AND ProductStock.Characteristic = DocumentGoods.Characteristic
		|
		|WHERE
		|	ProductStock.Recorder = &Documentreceivings
		|	AND ProductStock.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND NOT ProductStock.ReversingEntry
		|
		|GROUP BY
		|	ProductStock.Recorder,
		|	ProductStock.Warehouse,
		|	ProductStock.Premise,
		|	ProductStock.Products,
		|	ProductStock.Characteristic";
			
	Else
		
		QueryText = 
		"SELECT DISTINCT
		|	DocumentData.Ref					AS Ref,
		|	DocumentData.Warehouse					AS Warehouse,
		|	&Premise								AS Premise,
		|	MIN(DocumentGoods.LineNumber)	AS LineNumber,
		|	DocumentGoods.Products			AS Products,
		|	DocumentGoods.Characteristic			AS Characteristic
		|INTO DocumentGoods
		|FROM
		|	&TheTableNameOfTheDocument AS DocumentData
		|	,&TableJoinText
		|
		|WHERE
		|	DocumentGoods.Ref = &Documentreceivings
		|	AND &FilterCriterion
		|
		|GROUP BY
		|	DocumentData.Ref,
		|	DocumentData.Warehouse,
		|	&Premise,
		|	DocumentGoods.Products,
		|	DocumentGoods.CHARACTERISTIC";
		
		Premise				= "DocumentData." + PrintRule.FieldNameRoom;
		TableJoinText	= TextOfDataConnectionOfSTCHDocument(DocumentName, PrintRule.NameTSGoods);
		FilterCriterion			= "";
		
		If PrintRule.ThereArePackingLists Then
			FilterCriterion = "AND NOT DocumentGoods.ThisIsAPackingList";
		EndIf;
		
		QueryText = StrReplace(QueryText, "&Premise",					Premise);
		QueryText = StrReplace(QueryText, "&TheTableNameOfTheDocument",		DocumentName);
		QueryText = StrReplace(QueryText, ",&TableJoinText",		TableJoinText);
		QueryText = StrReplace(QueryText, "AND &FilterCriterion",			FilterCriterion);
		
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Function UseDocumentData(DocumentName)
	
	ExclusionDocuments = New Array;
	ExclusionDocuments.Add(Metadata.Documents.ReturnOfGoodsFromCustomer.FullName());
	ExclusionDocuments.Add(Metadata.Documents.AssemblyFromComponents.FullName());
	ExclusionDocuments.Add(Metadata.Documents.RecyclableWasteAllocation.FullName());
	UseDocumentData = ExclusionDocuments.Find(DocumentName) = Undefined;
	
	Return UseDocumentData;
	
EndFunction

&AtServer
Function QueryTextDocumentGoods()
	
	QueryText = 
	"SELECT
	|	TableOfGoods.Warehouse								AS Warehouse,
	|	ISNULL(MainStorageBins.Cell, &DefaultCell)	AS Cell,
	|	ISNULL(MainStorageBins.MainStorageBin, TRUE)		AS MainStorageBin,
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Characteristic						AS Characteristic
	|FROM
	|	DocumentGoods AS TableOfGoods
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|			AND &ConnectionCondition
	|
	|WHERE &FilterCriterion
	|
	|ORDER BY
	|	Warehouse,
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	MainStorageBin DESC,
	|	Cell";
	
	PrintRule		= PrintRules[0].Value;
	
	ConnectionCondition	= "";
	FilterCriterion		= "WHERE";
	
	If ValueIsFilled(PrintRule.FieldNameRoom) Then
		ConnectionCondition	= 
		"			AND CASE
		|				WHEN TableOfGoods.Warehouse.UseWarerooms
		|						AND TableOfGoods.Ref.Date >= TableOfGoods.Warehouse.StartDateOfWareroomUse
		|					THEN TableOfGoods.Premise = MainStorageBins.Premise
		|				ELSE MainStorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)
		|			END";
	EndIf;
	
	If PrintRule.ThisIsAnInvoice
		And Not ValueIsFilled(PrintRule.FieldNameRoom) Then
			
		WarehouseOperation = ?(PrintRule.SurplusesRecord, "WhenReflectingSurplusShortages", "OnReceipt");
		
		FilterCriterion = FilterCriterion + "
		|	TableOfGoods.Warehouse.UseBinLocationWarehousingForInformation
		|	AND (NOT TableOfGoods.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		OR TableOfGoods.Ref.Date < TableOfGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt)";
		
		FilterCriterion = StrReplace(FilterCriterion, "OnReceipt", WarehouseOperation);
		
	Else
		FilterCriterion = FilterCriterion + "
		|	CASE
		|		WHEN TableOfGoods.Warehouse.UseWarerooms
		|				AND TableOfGoods.Ref.Date >= TableOfGoods.Warehouse.StartDateOfWareroomUse
		|			THEN CASE
		|					WHEN TableOfGoods.Premise.UseBinLocationWarehousingForInformation
		|							AND (NOT TableOfGoods.Premise.UseBinLocationWarehousing
		|								OR TableOfGoods.Ref.Date < TableOfGoods.Premise.StartDateOfUsingWarehouseBinSystem)
		|						THEN TRUE
		|					ELSE FALSE
		|				END
		|		ELSE CASE
		|				WHEN TableOfGoods.Warehouse.UseBinLocationWarehousingForInformation
		|						AND (NOT TableOfGoods.Warehouse.UseBinLocationWarehousing
		|							OR TableOfGoods.Ref.Date < TableOfGoods.Warehouse.StartDateOfUsingWarehouseBinSystem)
		|					THEN TRUE
		|				ELSE FALSE
		|			END
		|	END";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&DefaultCell",		"VALUE(Catalog.StorageBins.EmptyRef)");
	QueryText = StrReplace(QueryText, "AND &ConnectionCondition",	ConnectionCondition);
	QueryText = StrReplace(QueryText, "WHERE &FilterCriterion",		FilterCriterion);
	
	Return QueryText;
	
EndFunction

#EndRegion

// the text of the document data validation error.
//
// Parameters:
//	Documentreceivings - DocumentRef - link to the document in the information database.
//	DocumentData - See GetDocumentData.
//
// Returns:
//	String - the text of the document data validation error.
//
&AtServer
Function TextOfDocumentDataValidationError(Documentreceivings, DocumentData)
	
	ErrorText = "";
	
	DataOnDocumentHeader	= DocumentData.ResultByDocumentHeader;
	DocumentWithoutGoods		= DocumentData.DocumentWithoutGoods;
	DocumentVerificationData	= DocumentData.DocumentVerificationResult;
	DataOnTablePart	= DocumentData.ResultForTabularPart;
	
	If Not DocumentWithoutGoods
		Or DataOnTablePart.IsEmpty() Then
			
			ErrorText = NStr("vi = 'Không thể thực hiện thao tác, bởi vì trong chứng từ ""%DocumentName%"" không có mặt hàng được sắp xếp.';
							|ru = 'Невозможно выполнить операцию, потому что в документе ""%DocumentName%"" отсутствует размещаемая номенклатура.';
							|en = 'The operation could not be completed because the ""%DocumentName%"" document does not contain the items being placed.'; fa = 'The operation could not be completed because the ""%DocumentName%"" document does not contain the items being placed.';
							|it = 'Impossibile eseguire l''operazione, nel documento ""%DocumentName%"" manca l''articolo da allocare.';
							|pl = 'Niemożliwe jest wykonanie operacji, ponieważ w dokumencie ""%DocumentName%"" nie istnieje umieszczonej nomenklaturze.';
							|tr = '""%DocumentName%"" belgesi gönderilen öğeyi içermediği için işlem gerçekleştirilemiyor.'");
			ErrorText = StrReplace(ErrorText, "%DocumentName%", String(Documentreceivings));
			
	EndIf;
	
	If Not DocumentVerificationData.IsEmpty() Then
		
		ValidationSample		= DocumentVerificationData.Select();
		ErrorsCount	= ValidationSample.Count();
		
		NumberOfDocumentData = DataOnDocumentHeader.Select().Count();
		
		If NumberOfDocumentData = 1 Then
			
			ValidationSample.Next();
			
			WarehousePresentation_ = WarehousesServer.GetWarehousePresentation(ValidationSample.WarehousePresentation,
																			ValidationSample.PremisePresentation);
			
			If ValidationSample.ThisIsAnInvoice
				And ValidationSample.AdvancedWarehousingIsUsed Then
				
				ErrorText = NStr("vi = 'Trong kho ""%WarehouseName_%"", sử dụng sơ đồ hai pha khi luân chuyển hàng hóa, cần sắp xếp làm từ lệnh.';
								|ru = 'На складе ""%WarehouseName_%"" используется ордерная схема документооборота, размещение нужно делать из ордера.';
								|en = 'Warehouse Management is enabled for %WarehouseName_%. To create a Put-away task, open the Inbound delivery.'; fa = 'Warehouse Management is enabled for %WarehouseName_%. To create a Put-away task, open the Inbound delivery.';
								|it = 'Nel magazzino ""%WarehouseName_%"" viene usato lo schema dei mandati del flusso documentale, l''allocazione deve essere effettuata dal mandato.';
								|pl = 'W magazynie ""%WarehouseName_%"" jest używany schemat zleceniowy obiegu dokumentów, rozmieszczenie należy wykonywać ze zlecenia.';
								|tr = '""%WarehouseName_%"" ambarında emir iş akışı şeması kullanılır, yerleştirmenin emirden yapılması gerekir.'");
				
			Else
				ErrorText = NStr("vi = 'Không thể thực hiện sắp xếp, bởi vì trong kho ""%WarehouseName_%"" không sử dụng phân chia thành ô theo danh mục.';
								|ru = 'Невозможно выполнить размещение, потому что на складе ""%WarehouseName_%"" не используется справочное деление на ячейки.';
								|en = 'Cannot create a Put-away task in warehouse %WarehouseName_%. This warehouse doesn''t use dummy bins.'; fa = 'Cannot create a Put-away task in warehouse %WarehouseName_%. This warehouse doesn''t use dummy bins.';
								|it = 'Impossibile eseguire l''allocazione perché nel magazzino ""%WarehouseName_%"" non si usa la suddivisione di riferimento in celle.';
								|pl = 'Rozmieszczenie jest niemożliwe, ponieważ w magazynie ""%WarehouseName_%"" nie jest używany pomocniczy podział na komórki.';
								|tr = '""%WarehouseName_%"" ambarında referans bazlı hücre bölünmesi kullanılmadığından yerleştirme gerçekleştirilemiyor.'");
			EndIf;
			
			ErrorText = StrReplace(ErrorText, "%WarehouseName_%", WarehousePresentation_);
			
		ElsIf NumberOfDocumentData = ErrorsCount Then
			ErrorText = NStr("vi = 'Không thể thực hiện sắp xếp, bởi vì trong chứng từ ""%DocumentName%"" không có kho bãi mà không sử dụng sơ đồ hai pha nhưng sử dụng phân chia thành các ô theo danh mục.';
							|ru = 'Невозможно выполнить размещение, потому что в документе ""%DocumentName%"" отсутствуют неордерные склады, использующие справочное деление на ячейки.';
							|en = 'Cannot put inventory away. ""%DocumentName%"" doesn''t have a dummy-bin warehouse with disabled Warehouse Management.'; fa = 'Cannot put inventory away. ""%DocumentName%"" doesn''t have a dummy-bin warehouse with disabled Warehouse Management.';
							|it = 'Cannot put inventory away. ""%DocumentName%"" doesn''t have a dummy-bin warehouse with disabled Warehouse Management.';
							|pl = 'Cannot put inventory away. ""%DocumentName%"" doesn''t have a dummy-bin warehouse with disabled Warehouse Management.';
							|tr = '""%DocumentName%"" belgesinde referans bazlı hücre bölünmesi kullanan emir dışı ambar bulunmadığından yerleştirme gerçekleştirilemiyor.'");
			ErrorText = StrReplace(ErrorText, "%DocumentName%", String(Documentreceivings));
		EndIf;
		
	EndIf;
	
	Return ErrorText;
	
EndFunction

// Initialization of information about the places of storage of goods is carried out.
//
// Parameters:
//	Documentreceivings - DocumentRef - link to the document in the information database.
//	DocumentData - See GetDocumentData.
//
&AtServer
Procedure InitializeStorageLocations(Documentreceivings, DocumentData)
	
	PrintRule = PrintRules[0].Value;
	
	SelectionByHeader = DocumentData.ResultByDocumentHeader.Select();
	SelectionByHeader.Next();
	
	If Not PrintRule.VHFWarehouses Then
		FillPropertyValues(Object, SelectionByHeader, "Warehouse");
	Else
		If CommonClientServer.HasAttributeOrObjectProperty(Documentreceivings, "Warehouse") Then
			Object.Warehouse = Common.ObjectAttributeValue(Documentreceivings, "Warehouse");
		Else
			Object.Warehouse = Undefined;
		EndIf;
	EndIf;
	
	FillPropertyValues(Object, SelectionByHeader, "Date, Premise");
	
EndProcedure

&AtServer
Procedure InitializeCellTables(DocumentData)
	
	ProductSelection_1 = DocumentData.ResultForTabularPart.Select();
	
	CurrentProducts		= Undefined;
	CurrentCharacteristic	= Undefined;
	
	While ProductSelection_1.Next() Do
		
		If ProductSelection_1.MainStorageBin
			Or (CurrentProducts <> ProductSelection_1.Products
				And CurrentCharacteristic <> ProductSelection_1.Characteristic) Then
			
			// If the main cell, or the main cell is not assigned.
			NewRow = Object.MainStorageBins.Add();
			FillPropertyValues(NewRow, ProductSelection_1, , "LineNumber");
			
			If Not ProductSelection_1.MainStorageBin Then
				NewRow.Cell = Catalogs.StorageBins.EmptyRef();
				
				Filter = New Structure("Products, Warehouse, Cell");
				FillPropertyValues(Filter, ProductSelection_1);
			
				If Object.AdditionalStorageBins.FindRows(Filter).Count() = 0 Then
					NewRow = Object.AdditionalStorageBins.Add();
					FillPropertyValues(NewRow, ProductSelection_1, , "LineNumber");
				EndIf;
			EndIf;
			
			CurrentProducts		= ProductSelection_1.Products;
			CurrentCharacteristic	= ProductSelection_1.Characteristic;
			
		Else
			
			Filter = New Structure("Products, Warehouse, Cell");
			FillPropertyValues(Filter, ProductSelection_1);
			
			If Object.AdditionalStorageBins.FindRows(Filter).Count() = 0 Then
				NewRow = Object.AdditionalStorageBins.Add();
				FillPropertyValues(NewRow, ProductSelection_1, , "LineNumber");
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetItemsVisibility()
	
	If ValueIsFilled(Object.Warehouse)
		And Common.ObjectAttributeValue(Object.Warehouse, "IsFolder") Then
		Items.Warehouse.Visible				= True;
		Items.Premise.Visible			= False;
		Items.MainStorageBinsWarehouse.Visible	= True;
	Else
		Items.Warehouse.Visible				= ValueIsFilled(Object.Warehouse);
		Items.Premise.Visible			= WarehousesServer.UseWarerooms(Object.Warehouse, Object.Date);
		Items.MainStorageBinsWarehouse.Visible	= Not ValueIsFilled(Object.Warehouse);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckModifiability(NotificationAfterVerification)
	
	If ThisForm.Modified Then
		
		AdditionalParameters	= New Structure("NotificationAfterVerification", NotificationAfterVerification);
		CallbackDescription		= New CallbackDescription("CheckModifiabilityCompletion",
															ThisObject,
															AdditionalParameters);
		QueryText			= NStr("vi = 'Đã thay đổi dữ liệu. Lưu thay đổi?';
									|ru = 'Данные были изменены. Сохранить изменения?';
									|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
									|it = 'I dati sono stati modificati. Salvare le modifiche?';
									|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
									|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
		
		Return;
		
	EndIf;
	
	RunCallback(NotificationAfterVerification, ThisForm.Modified);
	
EndProcedure

&AtClient
Procedure CheckModifiabilityCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ThisForm.Modified = WriteToRegisterServer();
		
		RunCallback(AdditionalParameters.NotificationAfterVerification, ThisForm.Modified);
	ElsIf QuestionResult = DialogReturnCode.Cancel Then
		RunCallback(AdditionalParameters.NotificationAfterVerification, True);
	Else
		RunCallback(AdditionalParameters.NotificationAfterVerification, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessAssignmentOfAdditionalCell(Products, Warehouse, Cell)
	
	If ValueIsFilled(Cell) Then
		
		Filter = New Structure("Products, Warehouse, Cell", Products, Warehouse, Cell);
		
		AdditionalCells = Object.AdditionalStorageBins.FindRows(Filter);
		
		If AdditionalCells.Count() > 1 Then
			
			FirstRow = True;
			
			For Each ArrRow In AdditionalCells Do
				If FirstRow Then
					FirstRow = False;
				Else
					Object.AdditionalStorageBins.Delete(ArrRow);
				EndIf;
			EndDo;
			
		ElsIf AdditionalCells.Count() = 0 Then
			
			NewRow = Object.AdditionalStorageBins.Add();
			NewRow.Products	= Products;
			NewRow.Cell			= Cell;
			NewRow.Warehouse			= Warehouse;
			
		EndIf;
		
		OSNCells = Object.MainStorageBins.FindRows(Filter);
		
		For Each ArrRow In OSNCells Do
			ArrRow.Cell = Undefined;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessPrimaryCellAssignment(Products, Warehouse,Cell, AddToAdditional)
	
	If ValueIsFilled(Cell) Then
		
		Filter		= New Structure("Products, Warehouse, Cell", Products, Warehouse, Cell);
		AdditionalCells	= Object.AdditionalStorageBins.FindRows(Filter);
		
		For Each ArrRow In AdditionalCells Do
			Object.AdditionalStorageBins.Delete(ArrRow);
		EndDo;
		
		SelectionWithoutCells	= New Structure("Products, Warehouse", Products, Warehouse);
		OSNCells		= Object.MainStorageBins.FindRows(SelectionWithoutCells);
		
		For Each ArrRow In OSNCells Do
			
			If AddToAdditional
				And ValueIsFilled(ArrRow.Cell) Then
				
				SearchSelection = New Structure("Products, Warehouse, Cell");
				FillPropertyValues(SearchSelection, ArrRow);
				
				If Object.AdditionalStorageBins.FindRows(SearchSelection).Count() = 0 Then
					NewRow = Object.AdditionalStorageBins.Add();
					FillPropertyValues(NewRow, ArrRow);
				EndIf;
				
			EndIf;
			
			ArrRow.Cell = Cell;
			
		EndDo;
		
		Filter = New FixedStructure("Products, Warehouse", Products, Warehouse);
		
		Items.AdditionalStorageBins.RowFilter = Filter;
		
	EndIf;
	
EndProcedure

&AtServer
Function WriteToRegisterServer()
	
	// We minimize the number of register sets that need to be recorded
	// due to the fact that we will write all the cells for the same nomenclature at once.
	
	CellTable = Object.MainStorageBins.Unload();
	CellTable.Columns.Add("MainStorageBin", New TypeDescription("Boolean"));
	CellTable.FillValues(True, "MainStorageBin");
	
	For Each RowOfTables In Object.AdditionalStorageBins Do
		NewRow = CellTable.Add();
		FillPropertyValues(NewRow, RowOfTables);
		
		NewRow.MainStorageBin = False;
	EndDo;
	
	CellTable.GroupBy("Products, Warehouse, Cell, MainStorageBin");
	CellTable.Sort("Products");
	
	HasErrors			= False;
	CurrentProducts	= Undefined;
	
	Set = InformationRegisters.PlaceProductsInStorageBins.CreateRecordSet();
	
	For Each RowOfTables In CellTable Do
		
		If CurrentProducts <> RowOfTables.Products Then
			
			If ValueIsFilled(Set.Filter.Products.Value) Then
				Try
					Set.Write(True);
				Except
					HasErrors = True;
					
					Common.MessageToUser(ErrorInfo().Description);
				EndTry;
			EndIf;
			
			Set = InformationRegisters.PlaceProductsInStorageBins.CreateRecordSet();
			Set.Filter.Products.Set(RowOfTables.Products);
			Set.Filter.Warehouse.Set(RowOfTables.Warehouse);
			Set.Filter.Premise.Set(Object.Premise);
			
			CurrentProducts = RowOfTables.Products;
			
		EndIf;
		
		If ValueIsFilled(RowOfTables.Cell) Then
			NewRow = Set.Add();
			FillPropertyValues(NewRow, RowOfTables);
			
			NewRow.Warehouse		= RowOfTables.Warehouse;
			NewRow.Premise	= Object.Premise;
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(Set.Filter.Products.Value) Then
		Try
			Set.Write(True);
		Except
			HasErrors = True;
			
			Common.MessageToUser(ErrorInfo().Description);
		EndTry;
	EndIf;
	
	Return HasErrors;
	
EndFunction

#EndRegion

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
