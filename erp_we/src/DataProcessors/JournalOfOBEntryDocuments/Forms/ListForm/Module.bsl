#Region Variables
&AtClient
Var FormElementRowsToValueTreeRows; 
#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// DynamicListsSettings
	InitiateDynamicListSettings();
	// End DynamicListsSettings
	
	URL = "e1cib/app/DataProcessor.JournalOfOBEntryDocuments";
	
	UseLocal              = GetFunctionalOption("UseLocal");
	UseMultipleCompanies  = GetFunctionalOption("UseMultipleCompanies");
	UseMultipleCurrencies        = GetFunctionalOption("UseMultipleCurrencies");
	OldDocumentOfBalanceEntry       = Common.MetadataObjectID(Metadata.Documents.OBEntry);
	WannaMaintainTheChartOfAccountsSelfSupporting = False;
	OBEntryARAP        = Common.MetadataObjectID(Metadata.Documents.OBEntryARAP);

	
	ListOfTypesOfSelectionByAccountingSections = DataProcessors.JournalOfOBEntryDocuments.InitializeListOfSelectionTypesByAccountingSection();
	
	Items.FilterByAccountingKind.ChoiceList.Clear();
	For Each FilterElement In ListOfTypesOfSelectionByAccountingSections Do
		Items.FilterByAccountingKind.ChoiceList.Add(FilterElement.Value, FilterElement.Presentation);
	EndDo;
	
	FilterByAccountingKind = "NoFilter";
	
	TableOfSectionsAndBusinessOfOperations = DataProcessors.JournalOfOBEntryDocuments.InitializeTreeOfBusinessOperationsForEnteringInitialBalances();
	PopulateDocumentPartitionTreeByEnteringInitialResiduals(TableOfSectionsAndBusinessOfOperations);
	
	GenerateListRequestText();
	
	DescriptionOfBusinessTransactions = OBEntryServer.DescriptionOfBalanceEntrySections();
	DescriptionOfBusinessTransactions.GroupBy("BalanceInputDocument");
	DocumentsUsed = DescriptionOfBusinessTransactions.UnloadColumn("BalanceInputDocument");

	DocumentTypesUsed = New Array;
	For Each DocumentUsed In  DocumentsUsed Do
	
		If Not ValueIsFilled(DocumentUsed) Then 
			Continue;
		EndIf;
		
		DocumentTypesUsed.Add(Common.MetadataObjectByID(DocumentUsed));
		
	EndDo;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = DocumentTypesUsed;
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	SetVisibility1();
	SetConditionalAppearance();
	
	RunPerformanceMeasurements = PerformanceMonitorServerCallCached.RunPerformanceMeasurements();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	#If MobileClient Then
	List.Parameters.SetParameterValue("FilterByTransactionTypes", FilterByTransactionTypes);
	List.Parameters.SetParameterValue("FilterByDocumentType", FilterByDocumentType);
	#EndIf
	
	// DynamicListsSettings
	SetParametersForUpdatingDocumentLists(False, 0);
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_OBEntry" Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("List", Parameter);
		// End DynamicListsSettings
		
		ActiveRowOldState = Items.TransactionTree.CurrentData;
		UpdateListData(Parameter);
		RestoreStateOfTree(TransactionTree);
		Items.TransactionTree.CurrentRow = SearchForActiveTreeRow(TransactionTree, ActiveRowOldState.AccountingSection, ActiveRowOldState.DocumentBusinessTransaction);
		
	EndIf;
EndProcedure



&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListOfDocumentsAutoUpdateMode = True;
	
	ListAutoUpdateMode = Settings.Get("ListOfDocumentsAutoUpdateMode");
	
	If Not ListAutoUpdateMode = Undefined Then
		ListOfDocumentsAutoUpdateMode = ListAutoUpdateMode;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	ActiveRowOldState = Items.TransactionTree.CurrentData;
	
	UpdateFormBasedOnSelectionData();
	
	RestoreStateOfTree(TransactionTree);
	Items.TransactionTree.CurrentRow = SearchForActiveTreeRow(TransactionTree, ActiveRowOldState.AccountingSection, ActiveRowOldState.DocumentBusinessTransaction);
	
EndProcedure

&AtClient
Procedure FilterByAccountingKindOnChange(Item)
	
	ActiveRowOldState = Items.TransactionTree.CurrentData;
	
	UpdateFormBasedOnSelectionData();
	
	RestoreStateOfTree(TransactionTree);
	Items.TransactionTree.CurrentRow = SearchForActiveTreeRow(TransactionTree, ActiveRowOldState.AccountingSection, ActiveRowOldState.DocumentBusinessTransaction);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransactionTree

&AtClient
Procedure TransactionTreeBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure TransactionTreeOnActivateRow(Item)
	
	CurrentTreeRow   = Items.TransactionTree.CurrentData;
	If CurrentTreeRow = Undefined Then
		Return;
	EndIf;
	
	BusinessOperation = CurrentTreeRow.DocumentBusinessTransaction;
	DocumentType          = CurrentTreeRow.BalanceInputDocument;
	
	FilterByTransactionTypes.Clear();
	
	If Not ValueIsFilled(BusinessOperation) Then
		FilterByTransactionTypes.LoadValues(DataForAccountingSection(CurrentTreeRow, "DocumentBusinessTransaction"));
	Else
		FilterByTransactionTypes.Add(BusinessOperation);
	EndIf;
	
	List.Parameters.SetParameterValue("FilterByTransactionTypes", FilterByTransactionTypes);
	
	FilterByDocumentType.Clear();
	
	If Not ValueIsFilled(DocumentType) Then
		FilterByDocumentType.LoadValues(DataForAccountingSection(CurrentTreeRow, "BalanceInputDocument"));
	Else
		FilterByDocumentType.Add(DocumentType);
	EndIf;
	
	FilterByDocumentType.Add(OldDocumentOfBalanceEntry);
	
	
	List.Parameters.SetParameterValue("FilterByDocumentType", FilterByDocumentType);
	
	ThisIsInputOfBalancesOfMutualSettlements = FilterByDocumentType.FindByValue(OBEntryARAP) <> Undefined;
	Items.Currency.Visible = Not ThisIsInputOfBalancesOfMutualSettlements;
	Items.Sum.Visible = Not (UseMultipleCurrencies And ThisIsInputOfBalancesOfMutualSettlements);
	
	// DynamicListsSettings
	OperationsWithDocumentJournalsClient.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure TransactionTreeBeforeExpand(Item, String, Cancel)

	CurrentRow = TransactionTree.FindByID(String);
	
	If Not CurrentRow = Undefined Then
		
		SectionOfAccountingOfExpandedNode.Add(CurrentRow.AccountingSection, , , )
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TransactionTreeBeforeCollapse(Item, String, Cancel)
	
	CurrentRow = TransactionTree.FindByID(String);
	
	If Not CurrentRow = Undefined Then
		
		ItemToRemove = SectionOfAccountingOfExpandedNode.FindByValue(CurrentRow.AccountingSection);
		
		If Not ItemToRemove = Undefined Then
			SectionOfAccountingOfExpandedNode.Delete(ItemToRemove);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy Then
		
		Cancel = True;
		
		FormParameters = New Structure;
		FormParameters.Insert("FilterByTransactionTypes", FilterByTransactionTypes);
		FormParameters.Insert("FillParameters",  PrepareParametersForFillingInBalanceEntryDocument());
		
		OpenForm("DataProcessor.JournalOfOBEntryDocuments.Form.BusinessTransactionSelection", FormParameters);
		
	Else
		Cancel = True;
		TMCommonUseClient.CopyItem(Items.List);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Item, Title);
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If RunPerformanceMeasurements Then
		
		NameOfKeyOperationForOpeningForm = GetKeyOperationForOpeningDocumentFormByClickingOnLink(Item.CurrentData.Ref);
		If Not IsBlankString(NameOfKeyOperationForOpeningForm) Then
			// StandardSubsystems.PerformanceMeasurement
			PerformanceMonitorClient.TimeMeasurement(NameOfKeyOperationForOpeningForm);
			// End StandardSubsystems.PerformanceMeasurement
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
EndProcedure

&AtServer
Procedure ListOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenTheBalanceControlReportEnteringBalances(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("VariantKey", "ControlOfInputOfBalances");
	FormParameters.Insert("GenerateOnOpen", True); 

	OpenForm("Report.FinancialCondition.Form", FormParameters, , "OBEntry");

EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.List, Title, Undefined,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("List");
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure CreateDocument(Command)
	FormParameters = New Structure;
		FormParameters.Insert("FilterByTransactionTypes", FilterByTransactionTypes);
		FormParameters.Insert("FillParameters",  PrepareParametersForFillingInBalanceEntryDocument());
		
		OpenForm("DataProcessor.JournalOfOBEntryDocuments.Form.BusinessTransactionSelection", FormParameters);
EndProcedure

&AtClient
Procedure CopyDocument(Command)
	
	TMCommonUseClient.CopyItem(Items.List);
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.List);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateFormBasedOnSelectionData()
	
	FilterParameters = DataProcessors.JournalOfOBEntryDocuments.InitializeSelectionParametersForEnteringInitialBalances();
	
	FilterParameters.Organization             = FilterByCompany;
	FilterParameters.FilterByAccountingKind = FilterByAccountingKind;
	
	TableOfSectionsAndBusinessOfOperations = DataProcessors.JournalOfOBEntryDocuments.InitializeTreeOfBusinessOperationsForEnteringInitialBalances(FilterParameters);
	PopulateDocumentPartitionTreeByEnteringInitialResiduals(TableOfSectionsAndBusinessOfOperations);
	
	ListSelectionsClientServer.ChangeListSelectionElement(List, "Organization", FilterByCompany, ValueIsFilled(FilterByCompany));
	
	ListOfTypesOfSelectionByAccountingSections = DataProcessors.JournalOfOBEntryDocuments.InitializeListOfSelectionTypesByAccountingSection();
	
	For Each FilterElement In ListOfTypesOfSelectionByAccountingSections Do
		
		ValueOfSelectionElement = FilterElement.Value;
		
		If ValueOfSelectionElement = "NoFilter" Then
			Continue;
		EndIf;
		
		ListSelectionsClientServer.ChangeListSelectionElement(List, ValueOfSelectionElement, True, FilterByAccountingKind = ValueOfSelectionElement);
		
	EndDo;
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Function PrepareParametersForFillingInBalanceEntryDocument()
	
	FillParameters = OBEntryServerCall.InitializeDocumentFillValuesEnteringBalances();
	FillParameters.Organization = FilterByCompany;
	FillParameters.RecordInOperationalAccounting = 
		FilterByAccountingKind = "RecordInOperationalAccounting" Or FilterByAccountingKind = "NoFilter";
	FillParameters.PostInFinancialAndTaxAccounting = 
		FilterByAccountingKind = "PostInFinancialAndTaxAccounting" Or (FilterByAccountingKind = "NoFilter" And UseLocal);
	FillParameters.RecordInMA = 
		FilterByAccountingKind = "RecordInMA" Or (FilterByAccountingKind = "NoFilter" And WannaMaintainTheChartOfAccountsSelfSupporting);
	
	Return FillParameters;
	
EndFunction

&AtClient
Function DataForAccountingSection(TreeRows, DataType)
	
	DataForAccountingSection = New Array();
	
	For Each TreeRow In TreeRows.GetItems() Do
		DataForAccountingSection.Add(TreeRow[DataType]);
	EndDo;
	
	Return DataForAccountingSection;
	
EndFunction

&AtClient
Procedure RestoreStateOfTree(TransactionTree)
	
	ElementsOfOperationTree = TransactionTree.GetItems();

	For Each TreeItem In ElementsOfOperationTree Do
		
		If Not SectionOfAccountingOfExpandedNode.FindByValue(TreeItem.AccountingSection) = Undefined Then 
			Items.TransactionTree.Expand(TreeItem.GetID());
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Function SearchForActiveTreeRow(TransactionTree, AccountingSection, DocumentBusinessTransaction)
	
	ActiveString         = Undefined;
	ElementsOfOperationTree = TransactionTree.GetItems();
	
	For Each TreeItem In ElementsOfOperationTree Do
		If TreeItem.AccountingSection = AccountingSection Then
			
			If ValueIsFilled(DocumentBusinessTransaction) Then
				
				If ValueIsFilled(TreeItem.DocumentBusinessTransaction) Then
					
					If TreeItem.DocumentBusinessTransaction = DocumentBusinessTransaction Then
						ActiveString = TreeItem.GetID();
					EndIf
					
				Else
					//We perform a search among the node elements
					ActiveString = SearchForActiveTreeRow(TreeItem, AccountingSection, DocumentBusinessTransaction);
					
				EndIf;
				
			Else
				ActiveString = TreeItem.GetID();
			EndIf;
			
		EndIf;
	EndDo;
	
	Return ActiveString;
	
EndFunction

&AtServer
Procedure PopulateDocumentPartitionTreeByEnteringInitialResiduals(TableOfSectionsAndBusinessOfOperations)
	
	Tree = TransactionTree;
	Tree.GetItems().Clear();
	
	For Each AccountingSection In TableOfSectionsAndBusinessOfOperations.Rows Do
		
		GroupRow = Tree.GetItems().Add();
		GroupRow.OperationStatus = 2;
		GroupRow.PresentationOperation = AccountingSection.AccountingSection;
		FillPropertyValues(GroupRow, AccountingSection);
		
		For Each EconomicOperationOfAccountingSection In AccountingSection.Rows Do
			
			LineOperation = GroupRow.GetItems().Add();
			
			LineOperation.DocumentBusinessTransaction = EconomicOperationOfAccountingSection.DocumentBusinessTransaction;
			LineOperation.DocumentsCount           = EconomicOperationOfAccountingSection.DocumentsCount;
			LineOperation.ExplanationOfAccountingSection          = String(EconomicOperationOfAccountingSection.ExplanationOfAccountingSection);
			LineOperation.OperationStatus                 = 1;
			If EconomicOperationOfAccountingSection.DocumentBusinessTransaction = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse Then
				Postfix = ConsignmentSalesServer.PostfixCommissionSchemes20();
				LineOperation.PresentationOperation = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Nhập số dư hàng hóa đã chuyển đi ký gửi (%1)';
																													|ru = 'Ввод остатков товаров, переданных на комиссию (%1)';
																													|en = 'Enter remaining consignment stock (%1)'; fa = 'Enter remaining consignment stock (%1)';
																													|it = 'Ввод остатков товаров, переданных на комиссию (%1)';
																													|pl = 'Enter remaining consignment stock (%1)';
																													|tr = 'Konsinye stok üzerine transfer edilen ürün bakiyelerinin girişi (%1)'"), Postfix);
			ElsIf EconomicOperationOfAccountingSection.DocumentBusinessTransaction = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5 Then
				
				If Not GetFunctionalOption("ConsignmentSaleIsUsed20")
					Or GetFunctionalOption("OnlyConsignmentSales25") Then
					LineOperation.PresentationOperation          = NStr("vi = 'Nhập số dư hàng hóa chuyển đi ký gửi';
																		|ru = 'Ввод остатков товаров, переданных на комиссию';
																		|en = 'Enter remaining consignment stock'; fa = 'ورود موجودی امانی باقی‌مانده';
																		|it = 'Inserimento saldi delle merci trasferite in commissione';
																		|pl = 'Wprowadzenie sald towarów, przekazanych do komisu';
																		|tr = 'Komisyona aktarılan malların kalıntılarının girilmesi'");
				Else
					Postfix = ConsignmentSalesServer.PostfixCommissionSchemes25();
					LineOperation.PresentationOperation = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Nhập số dư hàng hóa đã chuyển đi ký gửi (%1)';
																														|ru = 'Ввод остатков товаров, переданных на комиссию (%1)';
																														|en = 'Enter remaining consignment stock (%1)'; fa = 'Enter remaining consignment stock (%1)';
																														|it = 'Ввод остатков товаров, переданных на комиссию (%1)';
																														|pl = 'Enter remaining consignment stock (%1)';
																														|tr = 'Konsinye stok üzerine transfer edilen ürün bakiyelerinin girişi (%1)'"), Postfix);
				EndIf;
				
			Else
				LineOperation.PresentationOperation          = EconomicOperationOfAccountingSection.DocumentBusinessTransaction;
			EndIf;
			LineOperation.AccountingSection                    = EconomicOperationOfAccountingSection.AccountingSection;
			LineOperation.BalanceInputDocument          = EconomicOperationOfAccountingSection.BalanceInputDocument;
			
			If LineOperation.DocumentsCount > 0 Then
				LineOperation.PresentationOperation = LineOperation.PresentationOperation + " ("+EconomicOperationOfAccountingSection.DocumentsCount+")";
				LineOperation.OperationStatus = 0;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateListData(Parameter)
	FilterParameters                      = DataProcessors.JournalOfOBEntryDocuments.InitializeSelectionParametersForEnteringInitialBalances();
	FilterParameters.Organization          = FilterByCompany;
	FilterParameters.FilterByAccountingKind     = FilterByAccountingKind;
	TableOfSectionsAndBusinessOfOperations = DataProcessors.JournalOfOBEntryDocuments.InitializeTreeOfBusinessOperationsForEnteringInitialBalances(FilterParameters);
	PopulateDocumentPartitionTreeByEnteringInitialResiduals(TableOfSectionsAndBusinessOfOperations);
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Items.FilterByCompany.Visible = UseMultipleCompanies;
	Items.FilterByAccountingKind.Visible = UseLocal Or WannaMaintainTheChartOfAccountsSelfSupporting;
	
	If Not AccessRight("View", Metadata.Reports.BalanceSheetStatement) Then
		Items.OpenTheBalanceControlReportEnteringBalances.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateListRequestText()
	
	ListOfTypesOfSelectionByAccountingSections = DataProcessors.JournalOfOBEntryDocuments.InitializeListOfSelectionTypesByAccountingSection();
	ReflectByTypeOfAccounting              = "";
	DescriptionOfRazedelovInputBalances   = OBEntryServer.DescriptionOfBalanceEntrySections();
	DescriptionOfRazedelovInputBalances.GroupBy("BalanceInputDocument");
	
	For Each FilterElement In ListOfTypesOfSelectionByAccountingSections Do
		
		ValueOfSelectionElement = FilterElement.Value;
		
		If ValueOfSelectionElement = "NoFilter" Then
			Continue;
		EndIf;
		
		If ValueIsFilled(ReflectByTypeOfAccounting) Then
			ReflectByTypeOfAccounting = ReflectByTypeOfAccounting + ",
				|	";
		EndIf;
		ReflectByTypeOfAccounting = ReflectByTypeOfAccounting + "CASE";  //@Query-part
		
		SequenceNumberOfParameter = 0;
		
		For Each DetailsString In DescriptionOfRazedelovInputBalances Do
			
			SequenceNumberOfParameter = SequenceNumberOfParameter + 1;
			BalanceInputDocument    = DetailsString.BalanceInputDocument;
			DocumentTypeByString      = Common.ObjectAttributeValue(BalanceInputDocument, "FullName");
			MetadataOfDocument      = Common.MetadataObjectByID(BalanceInputDocument);
			ParameterByString          = "&RefType" + SequenceNumberOfParameter;
			
			If Common.HasObjectAttribute(ValueOfSelectionElement, MetadataOfDocument) Then
				ReflectByTypeOfAccounting = ReflectByTypeOfAccounting + "
					|		WHEN DocumentsRegistryOverridable.RefType = " + ParameterByString + "
					|			THEN CAST(DocumentsRegistryOverridable.Ref AS " + DocumentTypeByString + ")." + ValueOfSelectionElement;
			EndIf;
		EndDo;
		
		ReflectByTypeOfAccounting = ReflectByTypeOfAccounting + "
			|		ELSE FALSE
			|	END AS " + ValueOfSelectionElement;
	EndDo;
	
	DynamicListPropertiesStructure = Common.DynamicListPropertiesStructure();
	FillPropertyValues(DynamicListPropertiesStructure, List);
	DynamicListPropertiesStructure.QueryText = StrReplace(List.QueryText , "&ReflectByTypeOfAccounting", ReflectByTypeOfAccounting);
	
	Common.SetDynamicListProperties(Items.List, DynamicListPropertiesStructure);
	
	SequenceNumberOfParameter  = 0;
	
	For Each DetailsString In DescriptionOfRazedelovInputBalances Do 
		
		SequenceNumberOfParameter = SequenceNumberOfParameter + 1;
		BalanceInputDocument    = DetailsString.BalanceInputDocument;
		MetadataOfDocument      = Common.MetadataObjectByID(BalanceInputDocument);
		ParameterByString          = "RefType" + SequenceNumberOfParameter;
		
		If Common.HasObjectAttribute("RecordInOperationalAccounting", MetadataOfDocument)
			Or Common.HasObjectAttribute("PostInFinancialAndTaxAccounting", MetadataOfDocument) Then
				List.Parameters.SetParameterValue(ParameterByString, BalanceInputDocument);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	Setting = ConditionalAppearance.Items;
	
	// Currency and Amount
	SettingItem = Setting.Add();
	FieldCurrency = SettingItem.Fields.Items.Add();
	FieldCurrency.Field = New DataCompositionField("Currency");
	FieldAmount = SettingItem.Fields.Items.Add();
	FieldAmount.Field = New DataCompositionField("Sum");
	
	CashTransactions = New ValueList;
	CashTransactions.Add(Enums.BusinessTransactions.OBEntryCashInHand);
	CashTransactions.Add(Enums.BusinessTransactions.OBEntryOpenSalesInvoicesFromRetailCashRegisters);
	CashTransactions.Add(Enums.BusinessTransactions.OBEntryCashInRetailCashRegister);
	CashTransactions.Add(Enums.BusinessTransactions.OBEntryCashInBankAccounts);
	CashTransactions.Add(Enums.BusinessTransactions.OBEntryAdvanceHolderReceivables);
	CashTransactions.Add(Enums.BusinessTransactions.OBEntryOpenExpenseReportOfEmployees);
	CashTransactions.Add(Enums.BusinessTransactions.OBEntryDebtOutstandingOfLoansAndBorrowings);
	CashTransactions.Add(Enums.BusinessTransactions.OBEntryOpenOrderForCashToBeReceivedFromAcquirer);
	
	FinancialReportingServer.NewFilter(
		SettingItem.Filter,
		"List.BusinessOperation",
		CashTransactions, ,
		DataCompositionComparisonType.InList);
	FinancialReportingServer.NewFilter(
		SettingItem.Filter,
		"List.Currency", , ,
		DataCompositionComparisonType.NotFilled);
	FinancialReportingServer.NewFilter(
		SettingItem.Filter,
		"List.Sum", , ,
		DataCompositionComparisonType.NotFilled);
	
	SettingItem.Appearance.SetParameterValue("Text", NStr("vi = '<nhiều tiền tệ>';
															|ru = '<несколько валют>';
															|en = '<multiple currencies>'; fa = '<multiple currencies>';
															|it = '<несколько валют>';
															|pl = '<multiple currencies>';
															|tr = '<birden fazla para birimi>'"));
	SettingItem.Appearance.SetParameterValue("TextColor", StyleColors.HelpText);

EndProcedure

&AtClient
Function GetKeyOperationForOpeningDocumentFormByClickingOnLink(Ref)
	
	NameOfDocumentForm = "";
	
	If Ref <> Undefined And ValueIsFilled(Ref) Then
		
		If TypeOf(Ref) = Type("DocumentRef.OBEntryGoods") Then
			NameOfDocumentForm = "Document.OBEntryGoods.OpenDocumentForm";
		EndIf;
		
	EndIf;
	
	Return NameOfDocumentForm;
	
EndFunction

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListKeys = New Map();
	ListKeys.Insert("RefType", "RefType");
	ListKeys.Insert("BusinessOperation", "BusinessOperation");
	ListKeys.Insert("Date", "DocumentDate");
	ListKeys.Insert("RecordID", "RecordID");
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "List";
	ListParameterStructure.ListKeys = ListKeys;
	ListParameterStructure.PlacementGroupSettings = Items.DocumentListSettingsGroup;
	ListParameterStructure.AttributeNameAutoUpdateMode = "ListOfDocumentsAutoUpdateMode";
	ListParameterStructure.NameOfListUpdateCommands = Commands.DocumentsListRefresh.Name;
	DocumentListParameters.Add(ListParameterStructure);
	
	OperationsWithDocumentJournals.InitiateDynamicListSettings(ThisObject, DocumentListParameters);

EndProcedure

&AtClient
Procedure DisplayingGroupOfUserSelectionsAndSettings(ListName)
	
	LongTermUpdate = OperationsWithDocumentJournalsClient.TimeToUpdateListExceedsAllowedTime(ThisObject,
		ListName);
		
	If LongTermUpdate Then
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataLayoutSettingsHaveBeenChecked", True);
		DataCompositionSettingStructure = GetPerformingDataCompositionSettings(ListName);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataCompositionSettings", DataCompositionSettingStructure.DataCompositionSettings);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"StructureOfUserSettings", DataCompositionSettingStructure.StructureOfUserSettings);
	Else
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataLayoutSettingsHaveBeenChecked", False);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataCompositionSettings", New DataCompositionSettings);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"StructureOfUserSettings", New Structure);
	EndIf;

	OperationsWithDocumentJournalsClient.DocumentsDisplayGroupOfUserSelectionsAndSettings(ThisObject, ListName);
	
EndProcedure

&AtServer
Function GetPerformingDataCompositionSettings(ListName)
	
	TagName = OperationsWithDocumentJournals.ValueOfDocumentListSettings(ThisObject, ListName,
		"NameOfListItem");
	ListFormElement = Items[TagName];
	DataCompositionSettings = ListFormElement.GetPerformingDataCompositionSettings();

	ReturnStructure = New Structure;
	ReturnStructure.Insert("DataCompositionSettings", DataCompositionSettings);

	ListOfCompositeTypeFields = OperationsWithDocumentJournals.ValueOfDocumentListSettings(ThisObject,
		ListName, "ListOfCompositeTypeFields");

	StructureOfUserSettings = OperationsWithDocumentJournals.CheckUserSettingsOfDynamicList(
		DataCompositionSettings, ListOfCompositeTypeFields);

	ReturnStructure.Insert("StructureOfUserSettings", StructureOfUserSettings);
	
	Return ReturnStructure;
	
EndFunction

&AtClient
Procedure SetParametersForUpdatingDocumentLists(DataIsOutdated, UpdatingDuration = Undefined)
	
	SettingName = "ListOfDocumentsCacheSettings";
	ListName = "";
	For Each SettingUpListOfDocuments In ThisObject[SettingName] Do
		ListName = SettingUpListOfDocuments.Key;
		OperationsWithDocumentJournalsClient.SetParametersForUpdatingDocumentList(ThisObject, ListName, DataIsOutdated,
			UpdatingDuration);
		DisplayingGroupOfUserSelectionsAndSettings(ListName);
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateDocumentListDataWithTimeMeasurement(ListName, ConsiderAutoUpdateParameter = False)

	If Not ConsiderAutoUpdateParameter Then

		TheListNeedsToBeUpdated = True;

	Else

		TheListNeedsToBeUpdated = OperationsWithDocumentJournalsClient.SettingValueForAutoUpdatingListOfDocuments(
			ThisObject, ListName);

		If Not TheListNeedsToBeUpdated Then
			OperationsWithDocumentJournalsClient.SetFlagForDisplayingIrrelevantDataInList(ThisObject, ListName);
		EndIf;

	EndIf;

	If TheListNeedsToBeUpdated Then

		OperationsWithDocumentJournalsClient.UpdateDocumentListDataWithTimeMeasurement(ThisObject, ListName);
		DisplayingGroupOfUserSelectionsAndSettings(ListName);

	EndIf;

EndProcedure

&AtClient
Procedure UpdateListOfDocumentsEventNotificationProcessing(ListName, Parameter = Undefined)
	
	OperationsWithDocumentJournalsClient.UpdateListOfDocumentsEventNotificationProcessing(ThisObject, ListName, Parameter);
	DisplayingGroupOfUserSelectionsAndSettings(ListName);

EndProcedure

// Processing the form element event.
// 
// Parameters:
//  Item - FormField
//@skip-check module-unused-method
&AtClient
Procedure ListOfDocumentsFormElementEventHandling(Item)

	ActionForList = OperationsWithDocumentJournalsClient.NameOfListOfDocumentsByNameOfFormElement(ThisObject, Item.Name);
	
	If ActionForList.ListName = "" Then
		Return;
	EndIf;
	
	ListName = ActionForList.ListName;
	Action = ActionForList.Action;
	
	If Action = "Filters" Or Action = "Order" Or Action = "ConditionalAppearance" Then
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataLayoutSettingsHaveBeenChecked", True);
		DataCompositionSettingStructure = GetPerformingDataCompositionSettings(ListName);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataCompositionSettings", DataCompositionSettingStructure.DataCompositionSettings);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"StructureOfUserSettings", DataCompositionSettingStructure.StructureOfUserSettings);
	EndIf;
	
	If Action = "Filters" Then
		OperationsWithDocumentJournalsClient.FixCustomSelectionsInDocumentList(ThisObject, ListName);
	ElsIf Action = "Order" Then
		OperationsWithDocumentJournalsClient.FixSortingSettingsInDocumentList(ThisObject, ListName);
	ElsIf Action = "ConditionalAppearance" Then
		OperationsWithDocumentJournalsClient.FixConditionalAppearanceSettingsInDocumentList(ThisObject, ListName);
	ElsIf Action = "RefreshEnabled" Then
		UpdateDocumentListDataWithTimeMeasurement(ListName);
	ElsIf Action = "SpeedingUpListUpdates" Then
		OperationsWithDocumentJournalsClient.SaveSettingProductiveListUpdateMode(ThisObject, ListName);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
