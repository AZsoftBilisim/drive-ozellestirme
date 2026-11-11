
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ListFilter = Parameters.Filter;
	Recorder = Parameters.Recorder;
	Warehouse       = Parameters.Warehouse;
	BasisDocuments = Parameters.BasisDocuments;
	MultipleChoice = Parameters.MultipleChoice;
	
	If ValueIsFilled(Parameters.Title) Then
		Title = Parameters.Title;
	EndIf;
	
	Items.ListOfOrders_Selected.Visible = MultipleChoice;
	
	For Each RowColumn In Items.ListOfOrders_.ChildItems Do
		RowColumn.ReadOnly = True;
	EndDo;
	
	Items.ListOfOrders_Selected.ReadOnly = Not MultipleChoice;
	
	Items.ShowAllItems.Visible = Not Parameters.HideAdditionalSelections;
	
	FillInListOfOrders_();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowAllItemsOnChange(Item)
	
	FillInListOfOrders_()
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	If MultipleChoice Then
		MoveToDocument = True;
		Close(DialogReturnCode.Yes);
	ElsIf TMCommonUseClient.CheckForSelectedLinesInList(Items.ListOfOrders_) Then
		Close(New Structure("PurchaseOrder, ARAPObjectSettings", 
			                Items.ListOfOrders_.CurrentData.Ref,
			                Items.ListOfOrders_.CurrentData.ARAPObjectSettings));
	EndIf;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Not MultipleChoice Then
		Close(New Structure("PurchaseOrder, ARAPObjectSettings", 
			                Items.ListOfOrders_.CurrentData.Ref,
			                Items.ListOfOrders_.CurrentData.ARAPObjectSettings));
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If CloseForm Then
		Return;
	EndIf;
	
	If Modified And Not MoveToDocument Then
		
		HasChanges = False;
		
		RowsSelected = ListOfOrders_.FindRows(New Structure("Selected", True));
		If RowsSelected.Count() <> BasisDocuments.Count() Then
			HasChanges = True;
		ElsIf RowsSelected.Count() = 0 Or BasisDocuments.Count() = 0 Then
			
			HasChanges = True;
			
		Else
			For Each RowSelected In RowsSelected Do
				If BasisDocuments.FindByValue(RowSelected.Ref) = Undefined Then
					HasChanges = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If HasChanges Then
			QueryText = NStr("vi = 'Thành phần chứng từ cơ sở đã thay đổi. Tiếp nhận thay đổi? ';
							|ru = 'Состав документов-оснований был изменен. Принять изменения?';
							|en = 'Content of base documents was changed. Accept changes?'; fa = 'Content of base documents was changed. Accept changes?';
							|it = 'La struttura dei documenti-causali è stata modificata. Accettare le modifiche?';
							|pl = 'Skład dokumentów-podstaw został zmieniony. Akceptować zmiany?';
							|tr = 'Temel belgelerin yapısı değiştirilmiştir. Değişiklikler kabul edilsin mi?'");
			HandlerNotifications = New CallbackDescription("QuestionAboutAcceptingChangesInResponse", ThisForm);
			ShowQueryBox(HandlerNotifications, QueryText, QuestionDialogMode.YesNoCancel);
			Cancel = True;
		EndIf;
		
	ElsIf MoveToDocument  Then
		
		MoveToDocument();
		Cancel = True;
			
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInListOfOrders_()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentGrounds.DocumentBasis
	|INTO SelectedDocuments
	|FROM
	|	&DocumentGrounds AS DocumentGrounds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OrdersTable.PurchaseOrder AS PurchaseOrder,
	|	SUM(OrdersTable.ToRegister) AS ToRegister
	|INTO
	|	TTTableOrders
	|FROM
	|	(SELECT
	|		OrdersBalance.PurchaseOrder AS PurchaseOrder,
	|		OrdersBalance.ToRegisterBalance AS ToRegister
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Balance(
	|				,
	|				CASE
	|					WHEN &UseSelections
	|						AND &DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)
	|						THEN CAST(PurchaseOrder AS Document.MaterialProviderOrder2_5).Organization           = &Organization
	|							AND CAST(PurchaseOrder AS Document.MaterialProviderOrder2_5).Counterparty            = &Counterparty
	|							AND CAST(PurchaseOrder AS Document.MaterialProviderOrder2_5).Contract               = &Contract
	|							AND CAST(PurchaseOrder AS Document.MaterialProviderOrder2_5).GoodsReceiptOption = &GoodsReceiptOption
	|							AND CAST(PurchaseOrder AS Document.MaterialProviderOrder2_5).Partner               = &Partner
	|							AND (NOT &CheckHFCUnit
	|								OR (CAST(PurchaseOrder AS Document.MaterialProviderOrder2_5).FinancialAccountingGroup IN (
	|																								&FinancialAccountingGroup,
	|																								VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef))
	|									AND CAST(PurchaseOrder AS Document.MaterialProviderOrder2_5).Department IN (
	|																								&Department,
	|																								VALUE(Catalog.BusinessStructure.EmptyRef))))
	|							AND (Warehouse = &Warehouse
	|								OR Warehouse IN HIERARCHY (&Warehouse)
	|								OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|					WHEN &UseSelections
	|						THEN CAST(PurchaseOrder AS Document.PurchaseOrder).Organization = &Organization
	|							AND CAST(PurchaseOrder AS Document.PurchaseOrder).Counterparty = &Counterparty
	|							AND CAST(PurchaseOrder AS Document.PurchaseOrder).Contract = &Contract
	|							AND CAST(PurchaseOrder AS Document.PurchaseOrder).GoodsReceiptOption = &GoodsReceiptOption
	|							AND CAST(PurchaseOrder AS Document.PurchaseOrder).Partner = &Partner
	|							AND CAST(PurchaseOrder AS Document.PurchaseOrder).Terms = &Terms
	|							AND (CAST(PurchaseOrder AS Document.PurchaseOrder).PriceIncludesVAT = &PriceIncludesVAT OR &PriceIncludesVAT = UNDEFINED)
	|							AND CAST(PurchaseOrder AS Document.PurchaseOrder).ToReturnReusablePackage = &ToReturnReusablePackage
	|							AND CAST(PurchaseOrder AS Document.PurchaseOrder).PackageDepositIsRequired = &PackageDepositIsRequired
	|							AND ((CAST(PurchaseOrder AS Document.PurchaseOrder).Currency = &Currency
	|								AND CAST(PurchaseOrder AS Document.PurchaseOrder).VATTaxation = &VATTaxation
	|								AND (CAST(PurchaseOrder AS Document.PurchaseOrder).LineOfBusiness IN (&LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|									OR &WithoutSelectionByAreasOfActivity)
	|								) OR CAST(PurchaseOrder AS Document.PurchaseOrder).BusinessOperation = VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale))
	|							AND (NOT &CheckHFCUnit
	|								OR (CAST(PurchaseOrder AS Document.PurchaseOrder).FinancialAccountingGroup IN (&FinancialAccountingGroup, VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef))
	|									AND CAST(PurchaseOrder AS Document.PurchaseOrder).Department IN (&Department, VALUE(Catalog.BusinessStructure.EmptyRef))))
	|							AND (Warehouse = &Warehouse
	|								OR Warehouse IN HIERARCHY (&Warehouse)
	|								OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|							AND CASE WHEN &UseSelectionOfOperationsWithSelfEmployed
	|								THEN CAST(PurchaseOrder AS Document.PurchaseOrder).OperationWithSelfEmployedPerson = &OperationWithSelfEmployedPerson
	|								ELSE TRUE
	|							END)
	|					ELSE TRUE
	|				END) AS OrdersBalance
	|			
	|			UNION ALL
	|			
	|		SELECT
	|			TrafficOrders.PurchaseOrder,
	|			CASE
	|				WHEN TrafficOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN -TrafficOrders.ToRegister
	|				ELSE TrafficOrders.ToRegister
	|			END
	|		FROM
	|			AccumulationRegister.PurchaseOrders AS TrafficOrders
	|		WHERE
	|			TrafficOrders.Recorder = &Recorder
	|			AND CASE
	|					WHEN &UseSelections
	|						AND &DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)
	|						THEN TrafficOrders.Active
	|							AND CAST(TrafficOrders.PurchaseOrder AS Document.MaterialProviderOrder2_5).Organization           = &Organization
	|							AND CAST(TrafficOrders.PurchaseOrder AS Document.MaterialProviderOrder2_5).Counterparty            = &Counterparty
	|							AND CAST(TrafficOrders.PurchaseOrder AS Document.MaterialProviderOrder2_5).Contract               = &Contract
	|							AND CAST(TrafficOrders.PurchaseOrder AS Document.MaterialProviderOrder2_5).GoodsReceiptOption = &GoodsReceiptOption
	|							AND CAST(TrafficOrders.PurchaseOrder AS Document.MaterialProviderOrder2_5).Partner               = &Partner
	|							AND (NOT &CheckHFCUnit
	|								OR (CAST(PurchaseOrder AS Document.MaterialProviderOrder2_5).FinancialAccountingGroup IN (
	|																								&FinancialAccountingGroup,
	|																								VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef))
	|									AND CAST(PurchaseOrder AS Document.MaterialProviderOrder2_5).Department IN (
	|																								&Department,
	|																								VALUE(Catalog.BusinessStructure.EmptyRef))))
	|							AND (TrafficOrders.Warehouse = &Warehouse
	|								OR TrafficOrders.Warehouse IN HIERARCHY (&Warehouse)
	|								OR TrafficOrders.Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|					WHEN &UseSelections
	|						THEN TrafficOrders.Active
	|							AND TrafficOrders.PurchaseOrder.Organization = &Organization
	|							AND TrafficOrders.PurchaseOrder.Counterparty = &Counterparty
	|							AND TrafficOrders.PurchaseOrder.Contract = &Contract
	|							AND TrafficOrders.PurchaseOrder.GoodsReceiptOption = &GoodsReceiptOption
	|							AND TrafficOrders.PurchaseOrder.Partner = &Partner
	|							AND TrafficOrders.PurchaseOrder.Terms = &Terms
	|							AND (TrafficOrders.PurchaseOrder.PriceIncludesVAT = &PriceIncludesVAT OR &PriceIncludesVAT = UNDEFINED)
	|							AND TrafficOrders.PurchaseOrder.ToReturnReusablePackage = &ToReturnReusablePackage
	|							AND TrafficOrders.PurchaseOrder.PackageDepositIsRequired = &PackageDepositIsRequired
	|							AND ((CAST(PurchaseOrder AS Document.PurchaseOrder).Currency = &Currency
	|								AND CAST(PurchaseOrder AS Document.PurchaseOrder).VATTaxation = &VATTaxation
	|								AND (CAST(PurchaseOrder AS Document.PurchaseOrder).LineOfBusiness IN (&LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|									OR &WithoutSelectionByAreasOfActivity)
	|								) OR CAST(PurchaseOrder AS Document.PurchaseOrder).BusinessOperation = VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale))
	|							AND (NOT &CheckHFCUnit
	|								OR (CAST(PurchaseOrder AS Document.PurchaseOrder).FinancialAccountingGroup IN (&FinancialAccountingGroup, VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef))
	|									AND CAST(PurchaseOrder AS Document.PurchaseOrder).Department IN (&Department, VALUE(Catalog.BusinessStructure.EmptyRef))))
	|							AND (TrafficOrders.Warehouse = &Warehouse
	|								OR TrafficOrders.Warehouse IN HIERARCHY (&Warehouse)
	|								OR TrafficOrders.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|							AND CASE WHEN &UseSelectionOfOperationsWithSelfEmployed
	|								THEN TrafficOrders.PurchaseOrder.OperationWithSelfEmployedPerson = &OperationWithSelfEmployedPerson
	|								ELSE TRUE
	|							END)
	|				ELSE TRUE
	|			END) AS OrdersTable
	|WHERE
	|	OrdersTable.ToRegister > 0
	|GROUP BY
	|	OrdersTable.PurchaseOrder
	|
	|INDEX BY
	|	PurchaseOrder
	|;
	|
	|SELECT ALLOWED
	|	PurchaseOrders.Ref AS Ref,
	|	VALUETYPE(PurchaseOrders.Ref) AS TypeOfOrder_,
	|	PurchaseOrders.Date AS Date,
	|	PurchaseOrders.Number AS Number,
	|	PurchaseOrders.Partner AS Partner,
	|	PurchaseOrders.Counterparty AS Counterparty,
	|	PurchaseOrders.Contract AS Contract,
	|	PurchaseOrders.Terms AS Terms,
	|	PurchaseOrders.Organization AS Organization,
	|	PurchaseOrders.Warehouse AS Warehouse,
	|	PurchaseOrders.Currency AS Currency,
	|	PurchaseOrders.Manager AS Manager,
	|	PurchaseOrders.Status AS Status,
	|	PurchaseOrders.DocumentAmount AS DocumentAmount,
	|	PurchaseOrders.Priority AS Priority,
	|	PurchaseOrders.BusinessOperation AS BusinessOperation,
	|	PurchaseOrders.VATTaxation AS VATTaxation,
	|	PurchaseOrders.PriceIncludesVAT AS PriceIncludesVAT,
	|	PurchaseOrders.ARAPObjectSettings AS ARAPObjectSettings,
	|	PurchaseOrders.Comment AS Comment,
	|	CASE
	|		WHEN PurchaseOrders.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN PurchaseOrders.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute DESC)
	|			THEN 2
	|		ELSE 1
	|	END AS PictureOfPriority,
	|	CASE
	|		WHEN SelectedDocuments.DocumentBasis IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Selected
	|
	|FROM
	|	Document.PurchaseOrder AS PurchaseOrders
	|		LEFT JOIN TTTableOrders AS OrdersTable
	|		ON PurchaseOrders.Ref = OrdersTable.PurchaseOrder
	|
	|	LEFT JOIN SelectedDocuments AS SelectedDocuments
	|	ON PurchaseOrders.Ref = SelectedDocuments.DocumentBasis
	|
	|WHERE 
	|	ISNULL(OrdersTable.ToRegister,0) > 0
	|	AND &ConditionOfEconomicOperation
	|
	|UNION ALL
	|
	|SELECT
	|	PurchaseOrders.Ref                                  AS Ref,
	|	VALUETYPE(PurchaseOrders.Ref)                     AS TypeOfOrder_,
	|	PurchaseOrders.Date                                    AS Date,
	|	PurchaseOrders.Number                                   AS Number,
	|	PurchaseOrders.Partner                                 AS Partner,
	|	PurchaseOrders.Counterparty                              AS Counterparty,
	|	PurchaseOrders.Contract                                 AS Contract,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	PurchaseOrders.Organization                             AS Organization,
	|	PurchaseOrders.Warehouse                                   AS Warehouse,
	|	PurchaseOrders.Currency                                  AS Currency,
	|	PurchaseOrders.Manager                                AS Manager,
	|	PurchaseOrders.Status                                  AS Status,
	|	PurchaseOrders.DocumentAmount                          AS DocumentAmount,
	|	PurchaseOrders.Priority                               AS Priority,
	|	PurchaseOrders.BusinessOperation                   AS BusinessOperation,
	|	PurchaseOrders.VATTaxation                      AS VATTaxation,
	|	PurchaseOrders.PriceIncludesVAT                         AS PriceIncludesVAT,
	|	PurchaseOrders.ARAPObjectSettings                         AS ARAPObjectSettings,
	|	PurchaseOrders.Comment                             AS Comment,
	|	CASE
	|		WHEN PurchaseOrders.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN PurchaseOrders.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute DESC)
	|			THEN 2
	|		ELSE 1
	|	END                                                     AS PictureOfPriority,
	|	CASE
	|		WHEN SelectedDocuments.DocumentBasis IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                                     AS Selected
	|
	|FROM
	|	Document.MaterialProviderOrder2_5 AS PurchaseOrders
	|		INNER JOIN TTTableOrders AS OrdersTable
	|		ON PurchaseOrders.Ref = OrdersTable.PurchaseOrder
	|
	|	LEFT JOIN SelectedDocuments AS SelectedDocuments
	|	ON PurchaseOrders.Ref = SelectedDocuments.DocumentBasis
	|
	|WHERE 
	|	ISNULL(OrdersTable.ToRegister,0) > 0
	|	AND &ConditionOfEconomicOperation
	|";
	
	BusinessOperation = Undefined;
	
	If ListFilter.Property("BusinessOperation", BusinessOperation) Then
		
		Condition = "PurchaseOrders.BusinessOperation IN (&BusinessTransactionList)";
		
		If ValueIsFilled(BusinessOperation) Then
			
			If ListFilter.Contract.OptionForRegisteringServiceReceiptDocuments = 
				Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed Then
				
				BusinessTransactionList = New Array;
				BusinessTransactionList.Add(BusinessOperation);
				
				If BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU Then
					BusinessTransactionList.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery); 
					
				ElsIf BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery Then
					BusinessTransactionList.Add(Enums.BusinessTransactions.ImportFromEAEU); 
					
				ElsIf BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier Then
					BusinessTransactionList.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
					
				ElsIf BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt Then
					BusinessTransactionList.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
				EndIf;
				
			Else 
				BusinessTransactionList = ListFilter.BusinessOperation;
			EndIf;
				
			Query.SetParameter("BusinessTransactionList", BusinessTransactionList);
			
		Else
			
			TransactionList = New ValueList;
			TransactionList.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
			
			Condition = "NOT"+ " " + Condition;
			Query.SetParameter("BusinessTransactionList", TransactionList);
			
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&ConditionOfEconomicOperation", Condition);
	Else
		Query.Text = StrReplace(Query.Text, "&ConditionOfEconomicOperation" , "TRUE");
	EndIf;
	
	UseSelections = Not ShowAllItems;
	Query.SetParameter("UseSelections", UseSelections);
	
	DocumentBusinessTransaction = Undefined;
	ListFilter.Property("DocumentBusinessTransaction", DocumentBusinessTransaction);
	Query.SetParameter("DocumentBusinessTransaction", DocumentBusinessTransaction);
	
	If BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		Query.SetParameter("Currency",						Undefined);
		Query.SetParameter("VATTaxation",			Undefined);
		Query.SetParameter("LineOfBusiness",	Undefined);
		Query.SetParameter("FinancialAccountingGroup",		Undefined);
		Query.SetParameter("CheckHFCUnit",	False);
		Query.SetParameter("WithoutSelectionByAreasOfActivity", False);
	ElsIf DocumentBusinessTransaction = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		Query.SetParameter("Currency",						Undefined);
		Query.SetParameter("VATTaxation",			Undefined);
		Query.SetParameter("LineOfBusiness",	Undefined);
		Query.SetParameter("FinancialAccountingGroup",		Undefined);
		Query.SetParameter("CheckHFCUnit",	False);
		Query.SetParameter("WithoutSelectionByAreasOfActivity", True);
	Else
		Query.SetParameter("Currency",						ListFilter.Currency);
		Query.SetParameter("VATTaxation",			ListFilter.VATTaxation);
		Query.SetParameter("LineOfBusiness",	ListFilter.LineOfBusiness);
		Query.SetParameter("FinancialAccountingGroup",		ListFilter.FinancialAccountingGroup);
		Query.SetParameter("CheckHFCUnit",	ListFilter.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
			And GetFunctionalOption("UseLocal"));
	
		If ListFilter.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
			And ListFilter.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef() Then
			Query.SetParameter("WithoutSelectionByAreasOfActivity", True);
		Else
			Query.SetParameter("WithoutSelectionByAreasOfActivity", False);
		EndIf;
		
	EndIf;
	
	Query.SetParameter("Organization",				ListFilter.Organization);
	Query.SetParameter("Counterparty",					ListFilter.Counterparty);
	Query.SetParameter("Partner",					ListFilter.Partner);
	Query.SetParameter("Terms",					ListFilter.Terms);
	Query.SetParameter("PriceIncludesVAT",			ListFilter.PriceIncludesVAT);
	Query.SetParameter("ToReturnReusablePackage",	ListFilter.ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired",		ListFilter.PackageDepositIsRequired);
	Query.SetParameter("Contract",					ListFilter.Contract);
	Query.SetParameter("GoodsReceiptOption",		ListFilter.GoodsReceiptOption);
	Query.SetParameter("Department",				ListFilter.Department);
	
	TableOfDocumentBases = New ValueTable();
	TableOfDocumentBases.Columns.Add("DocumentBasis", 
		New TypeDescription("DocumentRef.PurchaseOrder
		|, DocumentRef.MaterialProviderOrder2_5
		|"));
	
	For Each ListItem In BasisDocuments Do
		NewRow = TableOfDocumentBases.Add();
		NewRow.DocumentBasis = ListItem.Value;
	EndDo;
	
	Query.SetParameter("DocumentGrounds", TableOfDocumentBases);
	
	Query.SetParameter("Recorder", Recorder);
	Query.SetParameter("Warehouse", Warehouse);
	
	OperationWithSelfEmployedPerson = Undefined;
	ListFilter.Property("OperationWithSelfEmployedPerson", OperationWithSelfEmployedPerson);
	Query.SetParameter("UseSelectionOfOperationsWithSelfEmployed", 
		?(OperationWithSelfEmployedPerson = Undefined, False, True));
	Query.SetParameter("OperationWithSelfEmployedPerson", OperationWithSelfEmployedPerson);
	
	Result = Query.Execute();
	ListOfOrders_.Load(Result.Unload());
	
EndProcedure

&AtClient
Procedure QuestionAboutAcceptingChangesInResponse(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		MoveToDocument = True;
		Close();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure MoveToDocument()
	
	ArrayOfSelectedDocuments = New Array;
	RowsSelected = ListOfOrders_.FindRows(New Structure("Selected", True));
	For Each RowSelected In RowsSelected Do
		ArrayOfSelectedDocuments.Add(RowSelected.Ref);
	EndDo;
	
	CloseForm = True;
	NotifyChoice(ArrayOfSelectedDocuments);
	
EndProcedure

#EndRegion