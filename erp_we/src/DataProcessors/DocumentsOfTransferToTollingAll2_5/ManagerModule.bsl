
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Fills in the list of report commands.
// 
// Parameters:
// 	ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export

EndProcedure

#EndRegion

#Region CalculationOfStates

// Texts of requests for the status of documents processing
// 
// Parameters:
//  FilterParameters - Structure
//  BusinessTransaction - Link enumeration.Business operations, an array of elements of the Enumeration Link type.Economic operations
//  PlaceIWT - Boolean
//  References - ValueList
// 
// Returns:
//  Structure - Request texts:
// * StatusCalculationQueryText - String
// * TextOfDirectiveListRequest - String
//
Function QueriesTexts(FilterParameters, Val BusinessTransaction, PlaceIWT = False, References = Undefined) Export
	
	If TypeOf(BusinessTransaction) = Type("Array") Then
		BsnsTransactions = BusinessTransaction;
	Else
		BsnsTransactions = New Array;
		BsnsTransactions.Add(BusinessTransaction);
	EndIf;
	
	Package = New Array;
	Selection = New Array;
	States1 = InvoicesServer.StatesByBusinessTransactions(BsnsTransactions);
	For Each KZ In States1 Do
		
		Package.Add(InvoicesServer.StateRequestText(KZ.Key, FilterParameters, KZ.Value));
		
		If KZ.Key = "StatesOfSpendingOrders" Then
			Selection.Add(
			"SELECT
			|	StatesOfSpendingOrders.ReferenceOrder AS ReferenceOrder,
			|	StatesOfSpendingOrders.Warehouse AS Warehouse,
			|	UNDEFINED AS Priority,
			|	CASE
			|		WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.SubcontractOrder2_5)
			|			THEN 0
			|		ELSE 4
			|	END AS InvoiceStatus,
			|	StatesOfSpendingOrders.State AS StateOfSpendingOrder,
			|	4 AS StatusOfTheReceiptOrder,
			|	TRUE AS ShippingSlip,
			|	FALSE AS ReceivingDocument
			|FROM
			|	TTStateOfSpendingOrders AS StatesOfSpendingOrders
			|");
		ElsIf KZ.Key = "StatesOfIncomingOrders" Then
			Selection.Add(
			"SELECT
			|	StatesOfIncomingOrders.ReferenceOrder AS ReferenceOrder,
			|	StatesOfIncomingOrders.Warehouse AS Warehouse,
			|	UNDEFINED AS Priority,
			|	CASE
			|		WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.SubcontractOrder2_5)
			|			THEN 0
			|		ELSE 4
			|	END AS InvoiceStatus,
			|	4 AS StateOfSpendingOrder,
			|	StatesOfIncomingOrders.State AS StatusOfTheReceiptOrder,
			|	FALSE AS ShippingSlip,
			|	TRUE AS ReceivingDocument
			|FROM
			|	TTStateOfIncomingOrders AS StatesOfIncomingOrders
			|");
		ElsIf KZ.Key = "ShipmentStates" Then
			Selection.Add(
			"SELECT
			|	ShipmentStates.ReferenceOrder AS ReferenceOrder,
			|	ShipmentStates.Warehouse AS Warehouse,
			|	DocSubcontractOrder.Priority AS Priority,
			|	ShipmentStates.State AS InvoiceStatus,
			|	CASE
			|		WHEN CatWarehousesSender.Ref IS NULL
			|			THEN 4
			|		WHEN ShipmentStates.State = 1
			|			THEN 1
			|		ELSE 0
			|	END AS StateOfSpendingOrder,
			|	4 AS StatusOfTheReceiptOrder,
			|	TRUE AS ShippingSlip,
			|	FALSE AS ReceivingDocument
			|FROM
			|	TTShipmentStates AS ShipmentStates
			|	
			|	LEFT JOIN Catalog.Warehouses AS CatWarehousesSender
			|	ON CatWarehousesSender.Ref = ShipmentStates.Warehouse
			|	AND CatWarehousesSender.UseWarehouseManagemantSystemForGoodsIssue
			|	AND CatWarehousesSender.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart
			|	
			|	LEFT JOIN Document.SubcontractOrder2_5 AS DocSubcontractOrder
			|	ON ShipmentStates.ReferenceOrder = DocSubcontractOrder.Ref
			|");
		ElsIf KZ.Key = "StateOfProceedsFromProcessor2_5" Then
			Selection.Add(
			"SELECT
			|	RevenueStates.ReferenceOrder AS ReferenceOrder,
			|	RevenueStates.Warehouse AS Warehouse,
			|	DocSubcontractOrder.Priority AS Priority,
			|	RevenueStates.State AS InvoiceStatus,
			|	4 AS StateOfSpendingOrder,
			|	CASE
			|		WHEN CatWarehousesRecipient.Ref IS NULL
			|			OR DocSubcontractOrder.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|			THEN 4
			|		WHEN RevenueStates.State = 1
			|			THEN 1
			|		ELSE 0
			|	END AS StatusOfTheReceiptOrder,
			|	FALSE AS ShippingSlip,
			|	TRUE AS ReceivingDocument
			|FROM
			|	TTStateOfRevenueFromProcessor2_5 AS RevenueStates
			|	
			|	LEFT JOIN Catalog.Warehouses AS CatWarehousesRecipient
			|	ON CatWarehousesRecipient.Ref = RevenueStates.Warehouse
			|	AND CatWarehousesRecipient.UseWarehouseManagemantSystemForGoodsReceipt
			|	AND CatWarehousesRecipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDayStart
			|	
			|	LEFT JOIN Document.SubcontractOrder2_5 AS DocSubcontractOrder
			|	ON RevenueStates.ReferenceOrder = DocSubcontractOrder.Ref
			|");
		ElsIf KZ.Key = "StatesOfProcessorReports2_5" Then
			Selection.Add(
			"SELECT
			|	ReportStates.ReferenceOrder   AS ReferenceOrder,
			|	UNDEFINED                    AS Warehouse,
			|	DocSubcontractOrder.Priority AS Priority,
			|	ReportStates.State      AS InvoiceStatus,
			|	4                               AS StateOfSpendingOrder,
			|	4                               AS StatusOfTheReceiptOrder,
			|	FALSE                            AS ShippingSlip,
			|	FALSE                            AS ReceivingDocument
			|FROM
			|	TTStateOfProcessorReports2_5 AS ReportStates
			|	
			|	LEFT JOIN Document.SubcontractOrder2_5 AS DocSubcontractOrder
			|	ON ReportStates.ReferenceOrder = DocSubcontractOrder.Ref
			|");
		EndIf;
		
	EndDo;
	
	StatusCalculationQueryText = StrConcat(Package, Common.QueryBatchSeparator());
	
	TextOfDirectiveListRequest =
		StrReplace(
			"SELECT
			|	NestedQuery.ReferenceOrder AS Ref,
			|	NestedQuery.Warehouse AS Warehouse,
			|	MAX(NestedQuery.Priority) AS Priority,
			|	MAX(NestedQuery.InvoiceStatus) AS InvoiceStatus,
			|	MAX(NestedQuery.StateOfSpendingOrder) AS GoodsIssueNoteState,
			|	MAX(NestedQuery.StatusOfTheReceiptOrder) AS GoodsReceiptNoteState,
			|	MAX(NestedQuery.ShippingSlip) AS ShippingSlip,
			|	MAX(NestedQuery.ReceivingDocument) AS ReceivingDocument
			|FROM
			|	QueryTextNested AS NestedQuery
			|WHERE
			|	&FilterText1
			|
			|GROUP BY
			|	NestedQuery.ReferenceOrder,
			|	NestedQuery.Warehouse
			|",
			"QueryTextNested",
			"(" + StrConcat(Selection, TMCommonUse.QuerySeparatorInJoin()) + ")");
	
	FilterText1 = "TRUE";
	If ValueIsFilled(References) Then
		FilterText1 =
			FilterText1 + Chars.LF + Chars.Tab +
			"AND NestedQuery.ReferenceOrder IN (&References)";
	EndIf;
	
	TextOfDirectiveListRequest =
		StrReplace(TextOfDirectiveListRequest, "&FilterText1", FilterText1);
	
	If PlaceIWT Then
		TextOfDirectiveListRequest=
			RequestSchemes.SetRoomToTemporaryTable(TextOfDirectiveListRequest, "TTRemainsOfState");
	EndIf;
	
	Return New Structure("StatusCalculationQueryText, TextOfDirectiveListRequest",
		StatusCalculationQueryText, TextOfDirectiveListRequest);
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

Function ThereAreDocumentsForRegistration(Parameters, BusinessOperation) Export
	
	FilterParameters =
		InvoicesServer.OrderSelectionParameters(
			Parameters.Organization,,
			Parameters.Warehouse,
			BusinessOperation,
			Parameters.Manager);
	
	If TypeOf(BusinessOperation) = Type("Array") Then
		BsnsTransactions = BusinessOperation;
	Else
		BsnsTransactions = New Array;
		BsnsTransactions.Add(BusinessOperation);
	EndIf;
	
	States1 = InvoicesServer.StatesByBusinessTransactions(BsnsTransactions);
	If Not ValueIsFilled(States1) Then
		Return False;
	EndIf;
	
	TablesNames = InvoicesServer.NamesOfTemporaryTablesByState();
	QueryTextTemplate2 =
	"SELECT
	|	ToRegister
	|FROM &TTName
	|";
	
	Package = New Array;
	Selection = New Array;
	For Each KZ In States1 Do
		Package.Add(InvoicesServer.StateRequestText(KZ.Key, FilterParameters, KZ.Value, True));
		Selection.Add(StrReplace(QueryTextTemplate2, "&TTName", TablesNames[KZ.Key]));
	EndDo;
	
	Package.Add(StrConcat(Selection, TMCommonUse.QuerySeparatorInJoin()));
	
	If ValueIsFilled(Parameters.Organization) Then
		CompaniesList = Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Parameters.Organization);
		CompaniesList.Add(Parameters.Organization);
	Else
		CompaniesList = New Array;
	EndIf;
	
	Query = New Query(StrConcat(Package, Common.QueryBatchSeparator()));
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("BusinessTransaction",       BusinessOperation);
	Query.SetParameter("Organization",       CompaniesList);
	Query.SetParameter("Warehouse",             WarehousesServer.ListOfSubordinateWarehouses(Parameters.Warehouse).UnloadValues());
	Query.SetParameter("Manager",          Parameters.Manager);
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#EndIf
