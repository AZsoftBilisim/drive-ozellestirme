#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export

EndProcedure

// Adds an object creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
// 	ValueTableRow, Undefined - 
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("View", Metadata.DataProcessors.LogOfSalesDocuments) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.CommonModules.SalesClient.FullName();
		CreateBasedOnCommand.Handler = "GenerateSetOfDocumentsChallenge";
		CreateBasedOnCommand.AdditionalParameters = New FixedStructure("ListOfOrders_", New Array);
		CreateBasedOnCommand.Presentation =  NStr("vi = 'Bộ chứng từ';
													|ru = 'Комплект документов';
													|en = 'Document set'; fa = 'Document set';
													|it = 'Kit di documenti';
													|pl = 'Komplet dokumentów';
													|tr = 'Belge seti'");
		CreateBasedOnCommand.Picture = PictureLib.RegisterSale;
		CreateBasedOnCommand.Order = 0;
		CreateBasedOnCommand.Importance = "Important";
		CreateBasedOnCommand.MultipleChoice = True;
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Private

// Parameters:
// 	Commands - See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.Commands
Procedure OnDefineCommandsAttachedToObject(Commands) Export
	
	ArrayOfReportCommands = Commands.FindRows(New Structure("Kind", "Reports"));
	ArrayOfPrintCommands = Commands.FindRows(New Structure("Kind", "Print"));
	
	ManagerDeviationsFromSalesConditions = Metadata.Reports.VariancesFromSalesTermsAndConditions.FullName();
	ManagerStateOfSettlementsWithClients = Metadata.Reports.StatusOfCustomersARAP.FullName();
	ManagerCardOfSettlementsWithClients = Metadata.Reports.CustomerARAPOpenItems.FullName();
	ManagerPaymentCardForTransferredReturnContainers = Metadata.Reports.ARAPAccountingStatementByReturnablePackagingProvided.FullName();
	ManagerSupplierPriceAnalysis = Metadata.Reports.PriceAnalysis.FullName();
	
	For Each CurTeam In ArrayOfReportCommands Do
		If CurTeam.Manager = ManagerDeviationsFromSalesConditions Then
			CurTeam.Importance = "Ordinary"
		EndIf;
		If CurTeam.Manager = ManagerStateOfSettlementsWithClients Then
			CurTeam.Importance = "Ordinary";
			CurTeam.Order = 1;
		EndIf;
		If CurTeam.Manager = ManagerCardOfSettlementsWithClients Then
			CurTeam.Importance = "Ordinary";
			CurTeam.Order = 2;
		EndIf;
		If CurTeam.Manager = ManagerPaymentCardForTransferredReturnContainers Then
			CurTeam.Order = 3;
		EndIf;
		If CurTeam.Manager = ManagerSupplierPriceAnalysis Then
			CurTeam.Importance = "SeeAlso";
			CurTeam.Order = 2;
		EndIf;
	EndDo;
	
	For Each CurTeam In ArrayOfPrintCommands Do
		CurTeam.VisibilityInForms = "DocumentsList";
	EndDo;
	
EndProcedure

Function NameOfInvoiceListForm()
	
	Return "DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices";
	
EndFunction

Function NameOfFormWorkplaceForRegistration()
	
	Return "DataProcessor.LogOfSalesDocuments.Form.ToRegisterReturnInvoices";
	
EndFunction

#Region CreatingHyperlinkInSalesDocumentLog

// Returns the text of the hyperlink from the document log to the invoice processing workplace.
//
// Parameters:
//	Parameters - Structure - parameters for forming the hyperlink text.
//
// Returns:
//	FormattedString, Undefined - the text of the hyperlink of the transition to the workplace of registration of reports on the commission.
//
Function CreateHyperlinkToDesign(Parameters) Export
	
	RowsArray = New Array;
	
	// Invoices
	
	Organization = Parameters.Organization;
	Warehouse       = Parameters.Warehouse;
	
	UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	UseWarehouseManagemantSystemForGoodsIssue = GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue");
	
	UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	
	ShowOrders = (UseAdvancedFeaturesOfSalesOrder
						And AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
						And AccessRight("Read", Metadata.Documents.SalesOrder)
						And AccessRight("Read", Metadata.Documents.RequestForReturnOfGoodsFromCustomer)
						And AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue))
						And (AccessRight("Insert", Metadata.Documents.TransferOfGoodsToBailee)
						Or AccessRight("Insert", Metadata.Documents.CustomerInvoiceServices)
						Or AccessRight("Insert", Metadata.Documents.CustomerInvoice));
	
	If ShowOrders Then
		
		HyperlinkText = NStr("vi = 'Hóa đơn';
							|ru = 'Накладные';
							|en = 'Invoices'; fa = 'فاکتورها';
							|it = 'Lettere di vettura';
							|pl = 'Listy przewozowe';
							|tr = 'İrsaliye'");
		
		If ThereAreOrdersForRegistration(Organization, Warehouse) Then
			Hyperlink = New FormattedString(HyperlinkText, , , , NameOfInvoiceListForm());
		Else
			Hyperlink = New FormattedString(HyperlinkText, , StyleColors.EmptyTableField, ,
				NameOfInvoiceListForm());
		EndIf;
		
		AddHyperlinkToList(Hyperlink, RowsArray);
		
	EndIf;
	
	// Returns
	
	ShowInvoices = (UseAdvancedFeaturesOfSalesOrder 
		Or UseWarehouseManagemantSystemForGoodsIssue)
		And AccessRight("Read", Metadata.Documents.ReturnOfGoodsFromCustomer)
		And AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences);
	
	ShowAcceptanceOrders = AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
		
	ShowInvoices = ShowInvoices
		Or (GetFunctionalOption("UseTransferToCustodyWithRightOfSale")
			And AccessRight("Read", Metadata.Documents.ReceiptOfGoodsFromCustodian)
			And AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive));
	
	If ShowInvoices
			And ShowAcceptanceOrders Then
		
		HyperlinkText = NStr("vi = 'Trả lại';
							|ru = 'Возвраты';
							|en = 'Returns'; fa = 'مرجوعی‌ها';
							|it = 'Resi';
							|pl = 'Zwroty';
							|tr = 'İadeler'");
		
		If ThereAreOrdersForAcceptanceAndReturn(Organization, Warehouse)
				Or ThereAreOrdersForAcceptanceOfReceiptsFromKeeper(Organization, Warehouse)
				Then
			Hyperlink = New FormattedString(HyperlinkText,
				,
				,
				,
				NameOfFormWorkplaceForRegistration());
		Else
			Hyperlink = New FormattedString(HyperlinkText,
				,
				StyleColors.EmptyTableField,
				,
				NameOfFormWorkplaceForRegistration());
		EndIf;
		
		AddHyperlinkToList(Hyperlink, RowsArray);
		
	EndIf;
	
	If RowsArray.Count() > 0 Then
		Return New FormattedString(RowsArray);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Procedure CreateHyperlinkToBackgroundTaskLayout(Parameters, StorageAddress) Export
	
	Result = New Structure("ToRegister, SeeAlsoInProgress");
	Result.ToRegister = CreateHyperlinkToDesignOfListOfDocuments(Parameters[0], Parameters[1]);
	
	ArrayCalculationManagersSeeAlsoInWork = New Array();
	ArrayCalculationManagersSeeAlsoInWork.Add("Document.SalesOrder");
	ArrayCalculationManagersSeeAlsoInWork.Add("Document.RequestForReturnOfGoodsFromCustomer");
	ArrayCalculationManagersSeeAlsoInWork.Add("Document.IssuedLetterOfAuthority");
	
	ToCompleteArrayOfCalculationManagersSeeAlsoLocalization(ArrayCalculationManagersSeeAlsoInWork);
	
	Result.SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, Parameters[1]);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// Returns the text of the hyperlink of operations from the document log to the waybills
// for the selected business operations and document types.
//
// Parameters:
//	BusinessTransactionsAndDocuments - ValueTable - selected business of operations and document types
//	Parameters - Structure - parameters of hyperlink text formation.
//
// Returns:
//	FormattedString, Undefined - the text of the hyperlink to the selected design jobs.
//
Function CreateHyperlinkToDesignOfListOfDocuments(BusinessTransactionsAndDocuments, GenerationParameters) Export
	
	RowsArray = New Array;
	
	FilterStructure1 = New Structure("Filter", True);
	HyperlinkCalculationManagers = BusinessTransactionsAndDocuments.Copy(FilterStructure1, "HyperlinkCalculationManagerForRegistration");
	
	HyperlinkCalculationManagers.GroupBy("HyperlinkCalculationManagerForRegistration");
	HyperlinkCalculationManagers = HyperlinkCalculationManagers.UnloadColumn("HyperlinkCalculationManagerForRegistration");
	
	For Each HyperlinkCalculationManager In HyperlinkCalculationManagers Do
		If HyperlinkCalculationManager = "" Then
			Continue;
		EndIf;
		
		GenerationParameters.Insert("BusinessTransactionsAndDocuments",BusinessTransactionsAndDocuments);
		ObjectManager = ?(Metadata.CommonModules.Find(HyperlinkCalculationManager) <> Undefined,
							Common.CommonModule(HyperlinkCalculationManager),
							Common.ObjectManagerByFullName(HyperlinkCalculationManager));
		Hyperlink = ObjectManager.CreateHyperlinkToDesign(GenerationParameters);
		
		If TypeOf(Hyperlink) <> Type("Array") Then 
			Hyperlink = CommonClientServer.ValueInArray(Hyperlink);
		EndIf;
		
		For Each CurrentHyperlink In Hyperlink Do
			AddHyperlinkToList(CurrentHyperlink, RowsArray);
		EndDo;
		
	EndDo;
	
	If ValueIsFilled(RowsArray) Then
		Return New FormattedString(RowsArray);
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure AddHyperlinkToList(Hyperlink, RowsArray)
	
	If ValueIsFilled(Hyperlink) Then
		If RowsArray.Count() > 0 Then
			RowsArray.Add("; ");
		EndIf;
		RowsArray.Add(Hyperlink);
	EndIf;

EndProcedure

Function ThereAreOrdersForAcceptanceAndReturn(Organization, Warehouse)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive) Then
		Return False;
	EndIf;
	
	Query = New Query;
	
	Query.Text = 
	"SELECT ALLOWED TOP 1
	|	RegisterRemnants.DocumentInflow
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(,
	|		(DocumentInflow REFS Document.RequestForReturnOfGoodsFromCustomer
	|			OR DocumentInflow REFS Document.ReturnOfGoodsFromCustomer)
	|		AND &WarehouseSelectionCriteria
	|		AND &OrganizationSelectionCriteria
	|		) AS RegisterRemnants
	|WHERE
	|	RegisterRemnants.GoodsReceiptNotesToRegisterBalance <> 0
	|	OR RegisterRemnants.ToRegisterGoodsReceiptsBalance <> 0
	|	OR RegisterRemnants.ToRegisterInvoicesByReferenceBalance <> 0
	|	AND (NOT RegisterRemnants.DocumentInflow REFS Document.RequestForReturnOfGoodsFromCustomer
	|		OR (RegisterRemnants.DocumentInflow REFS Document.RequestForReturnOfGoodsFromCustomer
	|			AND CAST(RegisterRemnants.DocumentInflow AS Document.RequestForReturnOfGoodsFromCustomer).BusinessOperation <> 
	|				VALUE(Enum.BusinessTransactions.ReturnFromCustodian)))";
	
	If ValueIsFilled(Warehouse) Then
		FilterByWarehouse = "AND Warehouse = &Warehouse";
		Query.Text = StrReplace(Query.Text, "AND &WarehouseSelectionCriteria", FilterByWarehouse);
	Else	
		Query.Text = StrReplace(Query.Text, "AND &WarehouseSelectionCriteria", "");
	EndIf;
	If ValueIsFilled(Organization) Then
		FilterByCompany = 
		"AND (CAST(DocumentInflow AS Document.RequestForReturnOfGoodsFromCustomer).Organization = &Organization
		|	OR CAST(DocumentInflow AS Document.ReturnOfGoodsFromCustomer).Organization = &Organization)";
		Query.Text = StrReplace(Query.Text, "AND &OrganizationSelectionCriteria", FilterByCompany);
	Else	
		Query.Text = StrReplace(Query.Text, "AND &OrganizationSelectionCriteria", "");
	EndIf;
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function ThereAreOrdersForAcceptanceOfReceiptsFromKeeper(Organization, Warehouse)
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive) Then
		Return False;
	EndIf;
	
	Query = New Query;
	
	Query.Text = 
	"SELECT ALLOWED TOP 1
	|	RegisterRemnants.DocumentInflow
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(,
	|		(DocumentInflow REFS Document.RequestForReturnOfGoodsFromCustomer
	|			OR DocumentInflow REFS Document.ReceiptOfGoodsFromCustodian)
	|		AND &WarehouseSelectionCriteria
	|		AND &OrganizationSelectionCriteria
	|		) AS RegisterRemnants
	|WHERE
	|	RegisterRemnants.GoodsReceiptNotesToRegisterBalance <> 0
	|	OR RegisterRemnants.ToRegisterGoodsReceiptsBalance <> 0
	|	OR RegisterRemnants.ToRegisterInvoicesByReferenceBalance <> 0
	|	AND (NOT RegisterRemnants.DocumentInflow REFS Document.RequestForReturnOfGoodsFromCustomer
	|		OR (RegisterRemnants.DocumentInflow REFS Document.RequestForReturnOfGoodsFromCustomer
	|			AND CAST(RegisterRemnants.DocumentInflow AS Document.RequestForReturnOfGoodsFromCustomer).BusinessOperation = 
	|				VALUE(Enum.BusinessTransactions.ReturnFromCustodian)))";
	
	If ValueIsFilled(Warehouse) Then
		FilterByWarehouse = "AND Warehouse = &Warehouse";
		Query.Text = StrReplace(Query.Text, "AND &WarehouseSelectionCriteria", FilterByWarehouse);
	Else	
		Query.Text = StrReplace(Query.Text, "AND &WarehouseSelectionCriteria", "");
	EndIf;
	If ValueIsFilled(Organization) Then
		FilterByCompany = 
		"AND (CAST(DocumentInflow AS Document.RequestForReturnOfGoodsFromCustomer).Organization = &Organization
		|	OR CAST(DocumentInflow AS Document.ReceiptOfGoodsFromCustodian).Organization = &Organization)";
		Query.Text = StrReplace(Query.Text, "AND &OrganizationSelectionCriteria", FilterByCompany);
	Else	
		Query.Text = StrReplace(Query.Text, "AND &OrganizationSelectionCriteria", "");
	EndIf;
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Returns an indication of whether it is necessary to issue sales invoices for the organization's warehouse.
//
// Parameters:
//	Organization - CatalogRef.Companies - the organization for which invoices are checked.
//	Warehouse       - CatalogRef.Warehouses      - warehouse for which invoices are checked.
//
// Returnable value:
//	Boolean - True, it is necessary to issue sales invoices for the organization's warehouse.
//
Function ThereAreOrdersForRegistration(Organization = Undefined, Warehouse = Undefined)
	
	If Not AccessRight("Read", Metadata.Documents.SalesOrder) Then
		Return False;
	EndIf;	
		
	QueryText = QueryTextOrdersToBeRegistered(Organization, Warehouse);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse",       Warehouse);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Returns the text of the request that is used to get data about sales invoices being processed.
//
// Parameters:
//	Organization - CatalogRef.Companies - the organization for which you want to issue invoices.
//	Warehouse       - CatalogRef.Warehouses      - the warehouse for which invoices are required to be issued.
//
// Returnable value:
//	String is the text of the request that is used to get data about sales invoices being processed.
//
Function QueryTextOrdersToBeRegistered(Organization = Undefined, Warehouse = Undefined)
	
	UsedTransfersForStorage = GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	
	QueryText =
	"SELECT ALLOWED TOP 1
	|	TRUE AS SelectionField
	|WHERE
	|	(TRUE IN
	|		(SELECT TOP 1
	|			TRUE AS SelectionField
	|		FROM
	|			AccumulationRegister.GoodsForIssue.Balance(, (Warehouse = &Warehouse
	|				OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|				AND DocumentShipments REFS Document.CustomerInvoice
	|				AND &SelectionConditionForTransferDocument
	|			) AS GoodsForIssue
	|		WHERE
	|			(GoodsForIssue.ToShipBalance - GoodsForIssue.AssembledBalance > 0
	|				OR GoodsForIssue.ToRegisterBalance > 0)
	|			AND GoodsForIssue.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|			AND GoodsForIssue.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			AND &SelectionConditionOrganizationOfGoodsForShipment)
	|	OR TRUE IN
	|		(SELECT TOP 1
	|			TRUE AS SelectionField
	|		FROM
	|			AccumulationRegister.GoodsForIssue.Balance(, (Warehouse = &Warehouse
	|				OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|				AND DocumentShipments IN
	|					(SELECT
	|						ReferencesForRegistration.Ref
	|					FROM
	|						Document.RequestForReturnOfGoodsFromCustomer AS ReferencesForRegistration
	|					WHERE
	|						TRUE
	|						AND &RefundSelectionCriteria
	|						AND &SelectionConditionOrganizationOfRefundRequest
	|					)
	|			) AS GoodsForIssue
	|		WHERE
	|			(GoodsForIssue.ToShipBalance - GoodsForIssue.AssembledBalance > 0
	|				OR GoodsForIssue.ToRegisterBalance > 0)
	|			AND GoodsForIssue.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|			AND GoodsForIssue.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			AND &SelectionConditionOrganizationOfGoodsForShipment)
	|	OR TRUE IN
	|		(SELECT TOP 1
	|			TRUE AS SelectionField
	|		FROM
	|			AccumulationRegister.GoodsForIssue.Balance(, (Warehouse = &Warehouse
	|				OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|				AND DocumentShipments IN
	|					(SELECT
	|						ReferencesForRegistration.Ref
	|					FROM
	|						Document.SalesOrder AS ReferencesForRegistration
	|					WHERE
	|						TRUE
	|						AND &TransferSelectionCondition
	|						AND &SelectionConditionOrganizationCustomerOrders
	|					)
	|			) AS GoodsForIssue
	|		WHERE
	|			(GoodsForIssue.ToShipBalance - GoodsForIssue.AssembledBalance > 0
	|				OR GoodsForIssue.ToRegisterBalance > 0)
	|			AND GoodsForIssue.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|			AND GoodsForIssue.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate)
	|	OR TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			#ShipmentOrdersTurnoverExpanded1 AS SalesOrders
	|		WHERE
	|			(SalesOrders.ForRegistrationQuantityTurnover -
	|				SalesOrders.IssuedQuantityTurnover) > 0)
	|	OR TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			#ShipmentOrdersTurnoverExpanded2 AS SalesOrders
	|		WHERE
	|			(SalesOrders.ForRegistrationQuantityTurnover -
	|				SalesOrders.IssuedQuantityTurnover) > 0))";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"(Warehouse = &Warehouse
		|			OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
		|		AND ReferenceOrder IN
		|			(SELECT
		|					ReferencesForRegistration.Ref AS Ref
		|				FROM
		|					Document.RequestForReturnOfGoodsFromCustomer AS ReferencesForRegistration
		|				WHERE
		|					TRUE
		|					AND &RefundSelectionCriteria
		|					AND &SelectionConditionOrganizationOfRefundRequest)";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	TableFormationParameters.ConditionText =
		"(Warehouse = &Warehouse
		|			OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
		|		AND ReferenceOrder IN
		|			(SELECT
		|					ReferencesForRegistration.Ref AS Ref
		|				FROM
		|					Document.SalesOrder AS ReferencesForRegistration
		|				WHERE
		|					TRUE
		|					AND &TransferSelectionCondition
		|					AND &SelectionConditionOrganizationCustomerOrders)";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	
	If Not UsedTransfersForStorage Then
		
		FilterCriterion = "AND ReferencesForRegistration.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)";
		QueryText  = StrReplace(QueryText, "AND &TransferSelectionCondition", FilterCriterion);
		
		FilterCriterion = "AND ReferencesForRegistration.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCustodian)";
		QueryText  = StrReplace(QueryText, "AND &RefundSelectionCriteria", FilterCriterion);
		
		QueryText = StrReplace(QueryText, "AND &SelectionConditionForTransferDocument", "");
		
	Else
		QueryText = StrReplace(QueryText, "AND &TransferSelectionCondition", "");
		QueryText = StrReplace(QueryText, "AND &RefundSelectionCriteria", "");
		
		FilterCriterion = "OR DocumentShipments REFS Document.TransferOfGoodsToBailee";
		QueryText  = StrReplace(QueryText, "AND &SelectionConditionForTransferDocument", FilterCriterion);
		
	EndIf;
	
	If ValueIsFilled(Organization) Then
		FilterCriterion = "
		|		AND CAST(ReferencesForRegistration.Ref AS Document.SalesOrder).Organization = &Organization";
		QueryText = StrReplace(QueryText,"AND &SelectionConditionOrganizationCustomerOrders", FilterCriterion);
		
		FilterCriterion = "
		|		AND CAST(ReferencesForRegistration.Ref AS Document.RequestForReturnOfGoodsFromCustomer).Organization = &Organization";
		QueryText = StrReplace(QueryText,"AND &SelectionConditionOrganizationOfRefundRequest", FilterCriterion);
		
		FilterCriterion = "
		|		CASE
		|			WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
		|				THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Organization
		|			&SelectionConditionForOrganizationOfTransfer
		|		END = &Organization";
		
		If Not UsedTransfersForStorage Then
			FilterCriterion = StrReplace(FilterCriterion, "&SelectionConditionForOrganizationOfTransfer", "");
		Else
			SelectionConditionForOrganizationOfTransfer = "
			|			WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
			|				THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Organization";
			FilterCriterion = StrReplace(FilterCriterion, "&SelectionConditionForOrganizationOfTransfer", SelectionConditionForOrganizationOfTransfer);
		EndIf;
		
		QueryText = StrReplace(QueryText,"&SelectionConditionOrganizationOfGoodsForShipment", FilterCriterion);
	Else
		QueryText = StrReplace(QueryText,"AND &SelectionConditionOrganizationCustomerOrders", "");
		QueryText = StrReplace(QueryText,"AND &SelectionConditionOrganizationOfGoodsForShipment", "");
		QueryText = StrReplace(QueryText,"AND &SelectionConditionOrganizationOfRefundRequest", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region Localization

Procedure ToCompleteArrayOfCalculationManagersSeeAlsoLocalization(ArrayCalculationManagersSeeAlsoInWork)
	
	
	Return;
EndProcedure

#EndRegion

#EndIf
