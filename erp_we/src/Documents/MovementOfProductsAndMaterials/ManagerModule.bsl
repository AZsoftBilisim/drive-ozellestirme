#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("Production");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	MovementOfProductsAndMaterialsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.MovementOfProductsAndMaterials") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableOrdersOfMaterialsForProduction(Query, QueryTexts, Registers);
		QueryTextTableReferencesToTransferFromProduction(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		MovementOfProductsAndMaterialsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	ToIssuePurchaseOfGoodsOnDvukhodovka(Query, QueryTexts, Registers);
	ToIssueReceiptOfGoodsOnDvukhodovka(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.MovementOfProductsAndMaterials);
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(
		DocumentRef, Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region FillType

// Returns the structure required for further use when filling out the document.
//
// Returns:
//   Structure - structure of document filling parameters.
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("AnArrayOfOrders",         Undefined);
	FillParameters.Insert("FormIsOpen",          False);
	FillParameters.Insert("FillByWarehouseDocument",     Undefined);
	
	FillParameters.Insert("HeaderAttributes",        Undefined);
	FillParameters.Insert("Organization",           Undefined);
	FillParameters.Insert("Sender",           Undefined);
	FillParameters.Insert("Recipient",            Undefined);
	FillParameters.Insert("BusinessOperation", Enums.BusinessTransactions.EmptyRef());
	
	FillParameters.Insert("DocumentName",          "MovementOfProductsAndMaterials");
	FillParameters.Insert("RegisterNameOrder",      "OrdersOfMaterialsForProduction");
	FillParameters.Insert("FieldNameOrder",          "ReferenceOrder");
	
	FillParameters.Insert("KeyFields",          "Products, Characteristic, Series, Purpose, AssignmentSender");
	
	Return FillParameters;
	
EndFunction

// Initializes the structure of filling parameters based on header details and orders.
//
// Parameters:
//  FillParameters	 - Structure - The default settings get in the method of Parametrization()
//  HeaderAttributes		 - Structure - Contains the keys that will be used for filling in
//  AnArrayOfOrders		 - Array - Links to orders that will be filled in.
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.AnArrayOfOrders	= AnArrayOfOrders;
	FillParameters.HeaderAttributes	= HeaderAttributes;
	
	If Not ValueIsFilled(FillParameters.Organization) Then
		FillParameters.Organization = HeaderAttributes.Organization;
	EndIf;
	If Not ValueIsFilled(FillParameters.Sender) Then
		FillParameters.Sender = HeaderAttributes.Sender;
	EndIf;
	If Not ValueIsFilled(FillParameters.Recipient) Then
		FillParameters.Recipient = HeaderAttributes.Recipient;
	EndIf;
	If Not ValueIsFilled(FillParameters.BusinessOperation) Then
		FillParameters.BusinessOperation = HeaderAttributes.BusinessOperation;
	EndIf;
	
	If FillParameters.FillByWarehouseDocument = Undefined Then
		
		If FillParameters.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
			Or FillParameters.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
			
			FillParameters.FillByWarehouseDocument = InvoicesServer.FillByWarehouseDocument(FillParameters.Sender);
			
		Else
			
			FillParameters.FillByWarehouseDocument = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Creates a structure for creating a document for one or more orders
//  If the header details differ in the transmitted orders, an error message is displayed.
//
// Parameters:
//  ReferencesArrray			- Array - instructions for entering the document
//  OrderProperties_			- Structure
//
// Returns:
//  Boolean - False if the details of the header differ in the transmitted orders.
//
Function InvoiceFillingData(ReferencesArrray, OrderProperties_ = Undefined) Export
	
	QueryTexts = New ValueList();
	RowFilter = Undefined;
	
	If OrderProperties_ = Undefined Then
		BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom;
	Else
		
		BusinessOperation = OrderProperties_.BusinessOperation;
		
		If CommonClientServer.HasAttributeOrObjectProperty(OrderProperties_, "Sender")
			And (BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
				Or BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom
				Or BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom) Then
			RowFilter = OrderProperties_.Sender;
		ElsIf CommonClientServer.HasAttributeOrObjectProperty(OrderProperties_, "Recipient")
			And (BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
				Or BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction) Then
			RowFilter = OrderProperties_.Recipient;
		EndIf;
		
	EndIf;
	
	OrderOrderingMaterials = TypeOf(ReferencesArrray[0]) = Type("DocumentRef.OrderOfMaterialsForProduction");
	FirstStageOfProduction = TypeOf(ReferencesArrray[0]) = Type("DocumentRef.ProductionStage2_2");
	MovementOfProductsAndMaterials_ = TypeOf(ReferencesArrray[0]) = Type("DocumentRef.MovementOfProductsAndMaterials");
	
	ByReferences = BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
						Or (BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
							And Not MovementOfProductsAndMaterials_)
						Or BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
						Or (BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom
							And OrderOrderingMaterials);
	
	If ByReferences Then
		If BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
			Or BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
			QueryTexts.Add(CreateBasedOnCheckoutShip(), "TableIsShip");
		ElsIf (BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
					Or BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom)
					And MovementOfProductsAndMaterials_ Then
			QueryTexts.Add(CreationBasedOnCheckingAvailabilityOfMaterialsAvailableForReturn(), "TableHasReturn");
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
			QueryTexts.Add(CreationBasedOnCheckingForUnspentMaterials(), "TableHasReturn");
		ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
			QueryTexts.Add(CreationBasedOnVerificationMade(RowFilter), "TableIsProduced");
		Else
			ExceptionText = NStr("vi = 'Lỗi gọi ra ""%1"". Hãy liên hệ với người quản trị.';
								|ru = 'Ошибка вызова ""%1"". Обратитесь к администратору.';
								|en = 'An error occurred when calling ""%1"". Please contact the administrator.'; fa = 'An error occurred when calling ""%1"". Please contact the administrator.';
								|it = 'Errore di chiamata ""%1"". Rivolgersi all''amministratore.';
								|pl = 'Błąd wywołania ""%1"". Zwróć się do administratora.';
								|tr = '""%1"" çağrısı hatası. Yöneticiye başvurun.'");
			Raise StrTemplate(ExceptionText, "MovementOfProductsAndMaterials.InvoiceFillingData()");
		EndIf;
	EndIf;
	
	QueryTexts.Add(CreatingAndVerifyingHeaderDetails(BusinessOperation, RowFilter), "HeaderDetailsTable");
	
	If BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		OrdersFirst = (Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get()
							= Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst);
	Else
		OrdersFirst = False;
	EndIf;
	
	If OrdersFirst Then
		QueryTexts.Add(CreationBasedOnCheckingAvailabilityOfOrders(), "TableHasOrders");
	EndIf;
	
	Query = New Query();
	Query.SetParameter("ReferencesArrray",          ReferencesArrray);
	Query.SetParameter("CurrentDayStart",     BegOfDay(CurrentSessionDate()));
	Query.SetParameter("RowFilter",            RowFilter);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts);
	
	HeaderAttributes = New Structure("BusinessOperation, DifferentOperations,
	                                 |Organization, VariousOrganizations_,
	                                 |Sender, DifferentSenders,
	                                 |Recipient, VariousRecipients,
	                                 |OrderStatus_, ThereAreErrorsPosted, ThereAreErrorsStatus,
	                                 |LineOfBusiness, VATTaxation,
	                                 |InternalSubcontracting, MaterialProviderCompany,
	                                 |GoodsReceiptOption, VariousOptionsForAcceptingGoods");
	
	FillPropertyValues(HeaderAttributes, Tables.HeaderDetailsTable[0]);

	If BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction Then
		HeaderAttributes.Insert("Department", HeaderAttributes.Recipient);
		HeaderAttributes.Insert("Warehouse", HeaderAttributes.Sender);
	Else
		HeaderAttributes.Insert("Warehouse");
	EndIf;
	
	If ByReferences Then
		HeaderAttributes.Insert("ThereAreWarrants", Not OrdersFirst Or Tables.TableHasOrders.Count() > 0);
		If BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
			Or BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
			HeaderAttributes.Insert("ThereIsShip", Tables.TableIsShip.Count() > 0);
			HeaderAttributes.Insert("ShipmentFromPantryIsCarriedOutByOrder", False);
			HeaderAttributes.Insert("ShipmentFromPantryIsCarriedOutByOrder", FirstStageOfProduction);
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
			HeaderAttributes.Insert("ThereIsRefund", Tables.TableHasReturn.Count() > 0);
		ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
			HeaderAttributes.Insert("ThereIsProduced", Tables.TableIsProduced.Count() > 0);
		EndIf;
	EndIf;
	
	ArrayOfValidStatuses = New Array;
	
	If OrderOrderingMaterials Then
		
		ArrayOfValidStatuses.Add(Enums.StatusesOfOrdersForMaterialsForProduction.ForCompletion);
		ArrayOfValidStatuses.Add(Enums.StatusesOfOrdersForMaterialsForProduction.Closed);
	ElsIf FirstStageOfProduction Then
		
		ArrayOfValidStatuses.Add(Enums.StatusesOfProductionStages2_2.ForCompletion);
		ArrayOfValidStatuses.Add(Enums.StatusesOfProductionStages2_2.Initiated);
		ArrayOfValidStatuses.Add(Enums.StatusesOfProductionStages2_2.Completed);
	EndIf;
	If FirstStageOfProduction
		And (BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
			Or BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction) Then
		
		AddressInStorage = GoodsTransferredByBusinessTransactionToTemporaryStorage(ReferencesArrray, BusinessOperation);
		
		HeaderAttributes.Insert("RequiredGoods", AddressInStorage);
		
	EndIf;
	If TypeOf(OrderProperties_) = Type("Structure") And OrderProperties_.Property("FilterByGoods") Then
		HeaderAttributes.Insert("FilterByGoods", OrderProperties_.FilterByGoods);	
	EndIf;	
	
	HeaderAttributes.Insert("ArrayOfValidStatuses", ArrayOfValidStatuses);
	HeaderAttributes.Insert("ByReferences", ByReferences);
	
	Return HeaderAttributes;
	
EndFunction

// Generates the parameters necessary to verify the entry of the invoice based on orders.
// See GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder
//
// Parameters:
//  References - Array - list of orders on the basis of which the invoice is issued
//  BusinessOperation - EnumRef.BusinessTransactions - type of operation of the invoice to be issued.
//
// Returns:
//  Structure - data for input verification.
//
Function DataForInputValidationBasedOn(References, BusinessOperation = Undefined) Export
	
	DataToEnter = New Structure("Basis, Status, ThereIsShip, InstructionsForRegistration, CanBeGrouped");
	DataToEnter.ThereIsShip = False;
	DataToEnter.CanBeGrouped = False;
	DataToEnter.Insert("Sender");
	DataToEnter.Insert("Recipient");
	DataToEnter.Insert("InternalSubcontracting");
	DataToEnter.Insert("MaterialProviderCompany");
	DataToEnter.Insert("BusinessOperation", BusinessOperation);
	
	QueriesTexts = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		
		QueriesTexts.Add(
			"SELECT
			|	OrderOfMaterialsForProduction.Ref                AS Basis,
			|	OrderOfMaterialsForProduction.Status                AS Status,
			|	OrderOfMaterialsForProduction.Warehouse                 AS Sender,
			|	OrderOfMaterialsForProduction.ShopFloorStockroom       AS Recipient
			|FROM
			|	Document.OrderOfMaterialsForProduction AS OrderOfMaterialsForProduction
			|WHERE
			|	OrderOfMaterialsForProduction.Ref IN(&References)
			|	AND OrderOfMaterialsForProduction.BusinessOperation = &Operation
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	ProductionStage.Ref                              AS Basis,
			|	ProductionStage.Status                              AS Status,
			|	StageOfProductionProvisionOfMaterials.Warehouse         AS Sender,
			|	StageOfProductionProvisionOfMaterials.Department AS Recipient
			|FROM
			|	Document.ProductionStage2_2 AS ProductionStage
			|		LEFT JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS StageOfProductionProvisionOfMaterials
			|		ON ProductionStage.Ref = StageOfProductionProvisionOfMaterials.Ref
			|			AND StageOfProductionProvisionOfMaterials.Products.ItemsType IN (
			|				VALUE(Enum.ItemsTypes.OwnGoods),
			|				VALUE(Enum.ItemsTypes.ReusablePackage))
			|			AND (NOT StageOfProductionProvisionOfMaterials.Warehouse.ShopFloorStockroom
			|				OR StageOfProductionProvisionOfMaterials.Warehouse.Department <> StageOfProductionProvisionOfMaterials.Department)
			|			AND NOT StageOfProductionProvisionOfMaterials.Canceled
			|WHERE
			|	ProductionStage.Ref IN(&References)
			|");
		QueriesTexts.Add(
			"SELECT TOP 1
			|	1
			|FROM
			|	Document.OrderOfMaterialsForProduction.Goods AS GoodsFromOrder
			|WHERE
			|	GoodsFromOrder.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
			|	AND GoodsFromOrder.Ref IN(&References)
			|	AND NOT GoodsFromOrder.Canceled
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	1
			|FROM
			|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS GoodsFromOrder
			|WHERE
			|	GoodsFromOrder.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
			|	AND (NOT GoodsFromOrder.Warehouse.ShopFloorStockroom
			|		OR GoodsFromOrder.Warehouse.Department <> GoodsFromOrder.Department
			|		OR &Operation = VALUE(Enum.BusinessTransactions.MaterialTransferToProduction))
			|	AND GoodsFromOrder.Ref IN(&References)
			|	AND NOT GoodsFromOrder.Canceled
			|");
			
		Filter = New Map;
		AddSelectionElement(Filter, "ReferenceOrder", False);
		
		QueriesTexts.Add(AccumulationRegisters.OrdersOfMaterialsForProduction.QueryTextBalance(
			"TTBalancesForRegistration",	Filter, "ToRegister <> 0"));
		
		QueriesTexts.Add(
			"SELECT DISTINCT
			|	RequirementsForRegistration_1.ReferenceOrder AS InstructionsForRegistration
			|FROM
			|	TTBalancesForRegistration AS RequirementsForRegistration_1");
		QueriesTexts.Add(
			"SELECT
			|	MAX(RequirementsForRegistration_1.Warehouse) AS Sender,
			|	MAX(RequirementsForRegistration_1.Recipient) AS Recipient,
			|	MAX(ISNULL(Data_Stage.InternalSubcontracting, FALSE)) AS InternalSubcontracting,
			|	MAX(ISNULL(Data_Stage.MaterialProviderCompany, VALUE(Catalog.Companies.EmptyRef))) AS MaterialProviderCompany,
			|	COUNT(DISTINCT ISNULL(Data_Stage.InternalSubcontracting, FALSE)) > 1 AS DifferentInternalProcessing,
			|	COUNT(DISTINCT ISNULL(Data_Stage.MaterialProviderCompany, VALUE(Catalog.Companies.EmptyRef))) > 1 AS DifferentCompanyGiver,
			|	COUNT(DISTINCT RequirementsForRegistration_1.Warehouse) > 1
			|		OR COUNT(DISTINCT RequirementsForRegistration_1.Recipient) > 1 AS DifferentSendersRecipients
			|FROM
			|	TTBalancesForRegistration AS RequirementsForRegistration_1
			|
			|	LEFT JOIN Document.ProductionStage2_2 AS Data_Stage
			|	ON Data_Stage.Ref = RequirementsForRegistration_1.ReferenceOrder
			|");
	Else
		
		If BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
			QueriesTexts.Add(
				"SELECT DISTINCT
				|	NestedQuery.Basis AS Basis,
				|	NestedQuery.Status AS Status,
				|	NestedQuery.Sender AS Sender,
				|	NestedQuery.Recipient AS Recipient
				|FROM
				|	(SELECT
				|		ProductionStage.Ref AS Basis,
				|		ProductionStage.Status AS Status,
				|		ProductionStageOutputProducts.Department AS Sender,
				|		ProductionStageOutputProducts.Recipient AS Recipient
				|	FROM
				|		Document.ProductionStage2_2 AS ProductionStage
				|			LEFT JOIN Document.ProductionStage2_2.ManufacturedProducts AS ProductionStageOutputProducts
				|			ON ProductionStage.Ref = ProductionStageOutputProducts.Ref
				|				AND (NOT ProductionStageOutputProducts.ToExpenseAs)
				|				AND (ProductionStageOutputProducts.Manufactured)
				|				AND (ProductionStageOutputProducts.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage)))
				|				AND (VALUETYPE(ProductionStageOutputProducts.Recipient) = TYPE(Catalog.Warehouses))
				|				AND (NOT CAST(ProductionStageOutputProducts.Recipient AS Catalog.Warehouses).ShopFloorStockroom
				|					OR CAST(ProductionStageOutputProducts.Recipient AS Catalog.Warehouses).Department <> ProductionStageOutputProducts.Department)
				|	WHERE
				|		ProductionStage.Ref IN(&References)
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		ProductionStage.Ref,
				|		ProductionStage.Status,
				|		ProductionStageByProducts.Department,
				|		ProductionStageByProducts.Recipient
				|	FROM
				|		Document.ProductionStage2_2 AS ProductionStage
				|			LEFT JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS ProductionStageByProducts
				|			ON ProductionStage.Ref = ProductionStageByProducts.Ref
				|				AND (NOT ProductionStageByProducts.ToExpenseAs)
				|				AND (ProductionStageByProducts.Manufactured)
				|				AND (ProductionStageByProducts.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage)))
				|				AND (VALUETYPE(ProductionStageByProducts.Recipient) = TYPE(Catalog.Warehouses))
				|				AND (NOT CAST(ProductionStageByProducts.Recipient AS Catalog.Warehouses).ShopFloorStockroom
				|					OR CAST(ProductionStageByProducts.Recipient AS Catalog.Warehouses).Department <> ProductionStageByProducts.Department)
				|	WHERE
				|		ProductionStage.Ref IN(&References)) AS NestedQuery");
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
			QueriesTexts.Add(
				"SELECT DISTINCT
				|	ProductionStage.Ref                          AS Basis,
				|	ProductionStage.Status                          AS Status,
				|	ProductionStageSavingMaterials.Department AS Sender,
				|	ProductionStageSavingMaterials.Recipient    AS Recipient
				|FROM
				|	Document.ProductionStage2_2 AS ProductionStage
				|		LEFT JOIN Document.ProductionStage2_2.UnusedMaterials AS ProductionStageSavingMaterials
				|		ON ProductionStage.Ref = ProductionStageSavingMaterials.Ref
				|			AND NOT ProductionStageSavingMaterials.ToExpenseAs
				|			AND VALUETYPE(ProductionStageSavingMaterials.Recipient) = TYPE(Catalog.Warehouses)
				|			AND (NOT CAST(ProductionStageSavingMaterials.Recipient AS Catalog.Warehouses).ShopFloorStockroom
				|				OR CAST(ProductionStageSavingMaterials.Recipient AS Catalog.Warehouses).Department <> ProductionStageSavingMaterials.Department)
				|WHERE
				|	ProductionStage.Ref IN(&References)");
		EndIf;
		QueriesTexts.Add(
			"SELECT TOP 1
			|	1");
		
		Filter = New Map;
		AddSelectionElement(Filter, "ReferenceOrder", False);
		AddSelectionElementOperation(Filter);
		
		QueriesTexts.Add(AccumulationRegisters.ReferencesToTransferFromProduction.QueryTextBalance(
			"TTBalancesForRegistration",	Filter, "Count <> 0"));
		
		QueriesTexts.Add(
			"SELECT DISTINCT
			|	RequirementsForRegistration_1.ReferenceOrder AS InstructionsForRegistration
			|FROM
			|	TTBalancesForRegistration AS RequirementsForRegistration_1");
		QueriesTexts.Add(
			"SELECT
			|	MAX(RequirementsForRegistration_1.Sender) AS Sender,
			|	MAX(RequirementsForRegistration_1.Recipient) AS Recipient,
			|	MAX(ISNULL(Data_Stage.InternalSubcontracting, FALSE)) AS InternalSubcontracting,
			|	MAX(ISNULL(Data_Stage.MaterialProviderCompany, VALUE(Catalog.Companies.EmptyRef))) AS MaterialProviderCompany,
			|	COUNT(DISTINCT ISNULL(Data_Stage.InternalSubcontracting, FALSE)) > 1 AS DifferentInternalProcessing,
			|	COUNT(DISTINCT ISNULL(Data_Stage.MaterialProviderCompany, VALUE(Catalog.Companies.EmptyRef))) > 1 AS DifferentCompanyGiver,
			|	COUNT(DISTINCT RequirementsForRegistration_1.Sender) > 1
			|		OR COUNT(DISTINCT RequirementsForRegistration_1.Recipient) > 1 AS DifferentSendersRecipients
			|FROM
			|	TTBalancesForRegistration AS RequirementsForRegistration_1
			|
			|	LEFT JOIN Document.ProductionStage2_2 AS Data_Stage
			|	ON Data_Stage.Ref = RequirementsForRegistration_1.ReferenceOrder
			|");
	EndIf;
	
	Query = New Query(StrConcat(QueriesTexts, Common.QueryBatchSeparator()));
	Query.SetParameter("References" , References);
	Query.SetParameter("Recorder"  , Undefined);
	Query.SetParameter("Operation"     , BusinessOperation);
	Result = Query.ExecuteBatch();
	
	Selection = Result[0].Select();
	If Selection.Count() = 1 And Selection.Next() Then
		DataToEnter.Basis     = Selection.Basis;
		DataToEnter.Status        = Selection.Status;
		DataToEnter.ThereIsShip = Not Result[1].IsEmpty();
	EndIf;
	
	If Not Result[3].IsEmpty() Then
		DataToEnter.InstructionsForRegistration = Result[3].Unload().UnloadColumn("InstructionsForRegistration");
		Selection = Result[4].Select();
		If Selection.Next() Then
			
			DataToEnter.CanBeGrouped =
				Not Selection.DifferentSendersRecipients
				And Not Selection.DifferentInternalProcessing
				And Not Selection.DifferentCompanyGiver
				And True;
				
			FillPropertyValues(DataToEnter, Selection, "Sender, Recipient");
			FillPropertyValues(DataToEnter, Selection, "InternalSubcontracting, MaterialProviderCompany");
		EndIf;
	EndIf;
	
	Return DataToEnter;
	
EndFunction

// Generates parameters for opening the workplace form "Documents for registration".
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - type of operation of the invoice to be issued
// Returns:
// 	Structure - LongDesc:
// * FormName - String - the name of the form RM
// * FormParameters - Structure - the shape parameters of the RM
//
Function ParametersForOpeningWorkplaceForm(BusinessOperation = Undefined) Export
	
	FilterBusinessTransactions = New ValueList;
	If ValueIsFilled(BusinessOperation) Then
		FilterBusinessTransactions.Add(BusinessOperation);
	Else
		FilterBusinessTransactions = TransactionList();
	EndIf;
	
	FilterDocumentTypes = New ValueList;
	FilterDocumentTypes.Add(Common.MetadataObjectID(Metadata.Documents.MovementOfProductsAndMaterials));
	
	FilterParameters = New Structure;
	FilterParameters.Insert("FilterBusinessTransactions", FilterBusinessTransactions);
	FilterParameters.Insert("FilterDocumentTypes", FilterDocumentTypes);
	
	OpeningParameters = New Structure("FormName, FormParameters");
	OpeningParameters.FormName = "Document.MovementOfProductsAndMaterials.Form.Workplace";
	OpeningParameters.FormParameters = New Structure;
	OpeningParameters.FormParameters.Insert("FormAssignmentKey",     "ProductionDocumentsAll");
	OpeningParameters.FormParameters.Insert("QuickFilterStructure", FilterParameters);
	
	Return OpeningParameters;
	
EndFunction

// Checks whether a document can be created based on orders.
//
// Parameters:
//  HeaderAttributes	 - Structure - details of orders.
//
// Returns:
//  Structure - contains the fields "There are errors" - True if it is possible to create one internal consumption, otherwise - false,
//  "Warning text" - error text if available.
//
Function CheckInvoiceFillingData(HeaderAttributes) Export
	
	ErrorsTexts = New Array();
	If HeaderAttributes.Property("ThereIsShip") And Not HeaderAttributes.ThereIsShip Then
		
		If HeaderAttributes.ShipmentFromPantryIsCarriedOutByOrder Then
			Texts = New Array;
			Texts.Add(ProvisionInDocumentsServer.ErrorTextNoProductsAvailableForShipment());
			Texts.Add(NStr("vi = 'Khi giao hàng từ kho xưởng, không cần lập hóa đơn.';
							|ru = 'При отгрузке из цеховой кладовой оформление накладной не требуется.';
							|en = 'When you ship from the shop floor stockroom, you do not need to register an invoice.'; fa = 'When you ship from the shop floor stockroom, you do not need to register an invoice.';
							|it = 'При отгрузке из цеховой кладовой оформление накладной не требуется.';
							|pl = 'When you ship from the shop floor stockroom, you do not need to register an invoice.';
							|tr = 'Atölye deposundan sevk edildiğinde irsaliye gerekmemektedir.'"));
			ErrorText = StrConcat(Texts, " ");
		Else
			ErrorText = ProvisionInDocumentsServer.ErrorTextNoProductsAvailableForShipment();
		EndIf;
		
		ErrorsTexts.Add(ErrorText);
		
	ElsIf HeaderAttributes.Property("ThereIsRefund") And Not HeaderAttributes.ThereIsRefund Then
		
		ErrorText = NStr("vi = 'Không có nguyên vật liệu để chuyển đến kho.';
						|ru = 'Нет материалов, которые требуется передать на склад.';
						|en = 'No materials which should be transferred to the warehouse.'; fa = 'No materials which should be transferred to the warehouse.';
						|it = 'Non ci sono materiali da trasferire in magazzino.';
						|pl = 'Brak materiałów, które należy przekazać do magazynu.';
						|tr = 'Ambara transfer edilecek malzeme yok.'");
		ErrorsTexts.Add(ErrorText);
		
	ElsIf HeaderAttributes.Property("ThereIsProduced") And Not HeaderAttributes.ThereIsProduced Then
		
		ErrorText = NStr("vi = 'Không có hàng hóa sản xuất cần phải được chuyển từ đơn vị.';
						|ru = 'Нет произведенной продукции, которую требуется передать из подразделения.';
						|en = 'No manufactured products to transfer from business unit.'; fa = 'No manufactured products to transfer from business unit.';
						|it = 'Non ci sono prodotti fabbricati da trasferire dal reparto.';
						|pl = 'Brak wyprodukowanej produkcji, którą należy przekazać z działu.';
						|tr = 'Departmandan transfer edilmesi gereken üretilmiş ürün bulunmamaktadır.'");
		ErrorsTexts.Add(ErrorText);
		
	EndIf;
	
	If HeaderAttributes.DifferentOperations = 1 Then
		
		If HeaderAttributes.VariousOrganizations_ > 1 Then
			ErrorsTexts.Add(NStr("vi = 'Các đơn hàng được chọn có các doanh nghiệp khác nhau.';
								|ru = 'У выбранных распоряжений различные организации.';
								|en = 'Selected references have different companies.'; fa = 'Selected references have different companies.';
								|it = 'Per le disposizioni selezionate sono specificate le società diverse.';
								|pl = 'Dla wybranych zamówień są różne firmy.';
								|tr = 'Seçili talimatların iş yerleri farklı.'"));
		EndIf;
		
		If HeaderAttributes.DifferentSenders > 1 Then
			ErrorsTexts.Add(NStr("vi = 'Lệnh được chọn có người gửi khác nhau.';
								|ru = 'У выбранных распоряжений различные отправители.';
								|en = 'Selected references have different senders.'; fa = 'Selected references have different senders.';
								|it = 'Per le disposizioni selezionate sono specificati i mittenti diversi.';
								|pl = 'Dla wybranych zamówień są różne nadawcy.';
								|tr = 'Seçili talimatların göndericileri farklı.'"));
		EndIf;

		If HeaderAttributes.VariousRecipients > 1 Then
			ErrorsTexts.Add(NStr("vi = 'Các đơn hàng được chọn có người nhận khác nhau.';
								|ru = 'У выбранных распоряжений различные получатели.';
								|en = 'Selected references have different recipients.'; fa = 'Selected references have different recipients.';
								|it = 'Per le disposizioni selezionate sono specificati i destinatari diversi.';
								|pl = 'Dla wybranych zamówień są różne odbiorcy.';
								|tr = 'Seçili talimatların alıcıları farklı.'"));
		EndIf;

		ErrorText = InvoicesServer.CheckPossibilityOfEnteringBasedOn(
							Undefined, 
							HeaderAttributes.OrderStatus_, 
							HeaderAttributes.ThereAreErrorsPosted, 
							HeaderAttributes.ThereAreErrorsStatus, 
							HeaderAttributes.ArrayOfValidStatuses);
			
		If ErrorText <> "" Then
			ErrorsTexts.Add(ErrorText);
		EndIf;
		
	ElsIf HeaderAttributes.DifferentOperations > 1 Then
		
		ErrorsTexts.Add(NStr("vi = 'Các lệnh được lựa chọn phản ánh các hoạt động khác nhau của sự lưu chuyển của nguyên vật liệu.';
							|ru = 'Выбранные распоряжения отражают различные операции движения материалов.';
							|en = 'Selected references record different material movement operations.'; fa = 'Selected references record different material movement operations.';
							|it = 'Le disposizioni selezionate riportano le operazioni del movimento di materiali diverse.';
							|pl = 'Wybrane zamówienia odzwierciedlają różne ruchy materiałów.';
							|tr = 'Seçili talimatlar, malzeme hareketinin farklı işlemlerini yansıtmaktadır.'"));
		
	EndIf;
	
	If HeaderAttributes.VariousOptionsForAcceptingGoods > 1 Then
		WarningText = NStr("vi = 'Trong các lệnh đã chọn, trường ""Phương án nhận hàng"" khác nhau';
							|ru = 'У выбранных распоряжений отличается поле ""Вариант приемки товаров""';
							|en = 'The ""Goods receipt option"" field of the selected commands is different'; fa = 'The ""Goods receipt option"" field of the selected commands is different';
							|it = 'Per le disposizioni selezionate è specificato il campo ""Variante di accettazione delle merci"" diverso';
							|pl = 'Dla wybranych zamówień różni się pole ""Wariant przyjęcia towarów""';
							|tr = 'Seçili talimatların ""Mal Girişi Seçeneği"" alanı farklı'");
		ErrorsTexts.Add(WarningText);
	EndIf;
	
	ThereAreWarnings = HeaderAttributes.Property("ThereAreWarrants") And Not HeaderAttributes.ThereAreWarrants;
	WarningText = NStr("vi = 'Không có dữ liệu để điền vào chứng từ, vì lô hàng theo lệnh chưa bắt đầu.';
						|ru = 'Нет данных для заполнения документа, так как отгрузка по распоряжению еще не начата.';
						|en = 'No data for document population as shipment under the reference has not been started yet.'; fa = 'No data for document population as shipment under the reference has not been started yet.';
						|it = 'Non ci sono dati per la compilazione del documento, perché la spedizione per disposizione non è ancora iniziata.';
						|pl = 'Brak danych do wypełnienia dokumentu, ponieważ jeszcze nie zaczęto wysyłki według zamówienia.';
						|tr = 'Sipariş üzerine sevkiyat henüz başlamadığından dolayı belgenin doldurulması için veri yok.'");
	
	Result = New Structure;
	Result.Insert("HasErrors", ErrorsTexts.Count() > 0);
	Result.Insert("ErrorText", ErrorsTexts);
	Result.Insert("ThereAreWarnings", ThereAreWarnings);
	Result.Insert("WarningText", WarningText);
	
	Return Result;
	
EndFunction

// Used when filling out an order document.
//
// Parameters:
//  Object				 - FormDataStructure, DocumentObject.MovementOfProductsAndMaterials - The document in which you need to fill in the banking details.
//  FillParameters	 - Structure - Contains settings for the fill.
//  AnArrayOfOrders		 - Array - List of orders.
//
Procedure FillInHeaderOfOrderDocument(Object, FillParameters, AnArrayOfOrders) Export
	
	FillPropertyValues(Object, FillParameters.HeaderAttributes);
	
	Object.Recipient            = FillParameters.Recipient;
	Object.Sender           = FillParameters.Sender;
	Object.BusinessOperation = FillParameters.BusinessOperation;
	Object.ByReferences       = True;
	
	If GetFunctionalOption("UseStatusesOfProductsAndMaterialsMovements") Then
		Object.Status = Enums.StatusesOfProductsAndMaterialMovement.Shipped;
	Else
		Object.Status = Enums.StatusesOfProductsAndMaterialMovement.Accepted;
	EndIf;
	
	// Filling in the series.
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.MovementOfProductsAndMaterials);
	ProductsServer.FillInSeriesByFEFO(Object, SeriesSpecificationParameters, False);
	
	// Filling out the order(s) in the header.
	OrdersServer.FillInOrderInOrderHeaderInTableSection(Object.ReferenceOrder, Object.Goods, FillParameters.FieldNameOrder);
	
EndProcedure

// The procedure recalculates the quantity of Packages field and other dependent fields.
//
// Parameters:
//  Goods				 - FormDataCollection	 - Table part "Products".
//  FillParameters	 - Structure			 - Contains settings for the fill.
//
Procedure UpdateDependentDetailsOfTablePart(Goods, FillParameters) Export
	
	StructureOfActions = New Structure;
	
	If FillParameters.FormIsOpen Then
		
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		
	EndIf;
	
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

// Fills in the passed parameter table for orders and warehouse orders.
//
// Parameters:
//  Goods				 - ValueTable - Table products to fill In
//  Recorder			 - DocumentRef.MovementOfProductsAndMaterials - Link to the current invoice
//  FillParameters	 - Structure - The default parameters are defined in the document parameters () method.
//  PackageBarcodes	 - Undefined, ValueTable - Table of packaging barcodes
//
Procedure FillInByOrdersOrders(Goods, Recorder, FillParameters, PackageBarcodes = Undefined) Export
	
	InvoiceIsOrder = PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(FillParameters.HeaderAttributes.GoodsReceiptOption);
	
	// If you do not need to fill in an order, we pass empty query parameters - an empty table will be returned for orders.
	If FillParameters.FillByWarehouseDocument Then
		ReferencesForOrders = FillParameters.AnArrayOfOrders;
		RegistrarForOrders  = Recorder;
	Else
		ReferencesForOrders = Undefined;
		RegistrarForOrders  = Undefined;
	EndIf;
	
	UseExcludedGoods = False;
	
	FiltersSettings = GetSelectionSettings_(FillParameters.HeaderAttributes);
	
	If FillParameters.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom
		Or FillParameters.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
		
		Filter = New Map;
		If FiltersSettings <> Undefined Then
			AddSelectionElement(Filter, "DocumentInflow");
		EndIf;
		
		QueryText = ?(FiltersSettings = Undefined, 
					     "", QueryTextTableFilters(FiltersSettings.ReplacementParameters) + Common.QueryBatchSeparator())
					   + AccumulationRegisters.GoodsToReceive.TextOfRequestRemainsToIssueOrders(, Filter);
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("References", ReferencesForOrders);
		Query.SetParameter("Recorder",  RegistrarForOrders);
		
		If FiltersSettings <> Undefined Then
			Query.SetParameter("TableFilters", FiltersSettings.TableFilters);
		EndIf;
		
		TableOrders = Query.Execute().Unload();
		ColumnQuantity = TableOrders.Columns.Count; // ValueTableColumn
		ColumnQuantity.Name = "NoteQuantity";
		
		// Distribution of the resulting tables
		Var_Key = StrReplace(FillParameters.KeyFields, "AssignmentSender", "");
		
		Condition = "[Count]";
		InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
		
		TableOrders.Columns.Add("AssignmentSender");
		TableOrders.LoadColumn(TableOrders.UnloadColumn("AssignmentSender"), "AssignmentSender");
		InvoicesServer.SupplementTable(TableOrders, Goods, "NoteQuantity");
		Return;
	
	ElsIf FillParameters.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or FillParameters.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		
		Filter = New Map;
		AddSelectionItem(Filter);
		AddRecipientSelectionElement(Filter);
		AddSelectionElement(Filter, "ReferenceOrder", FiltersSettings <> Undefined);
			
		RequestTextForOrders = ?(FiltersSettings = Undefined, 
			"", QueryTextTableFilters(FiltersSettings.ReplacementParameters) + Common.QueryBatchSeparator());
				
		RequestTextForOrders = RequestTextForOrders 		
			+ AccumulationRegisters.OrdersOfMaterialsForProduction.QueryTextBalance("TTAccountingData", Filter, "ToRegister <> 0");
			
		Filter = New Structure();
		Filter.Insert("Ref", "References");
		
		QueryTextOrderDocument = Documents.OrderOfMaterialsForProduction.QueryTextDocumentGoods(Filter);
		QueryTextOrderDocument = QueryTextOrderDocument
			+ "
			|
			|UNION ALL
			|
			|"
			+ Documents.ProductionStage2_2.QueryTextDocumentGoods(Filter, FillParameters.BusinessOperation);
		QueryText = RequestTextForOrders
						+ Common.QueryBatchSeparator()
						+ QueryTextOrderDocument;
	Else
		
		Filter = New Map;
		AddSelectionElementOperation(Filter);
		AddRecipientSelectionElement(Filter);
		AddSelectionElement(Filter, "ReferenceOrder", FiltersSettings <> Undefined);
			
		RequestTextForOrders = ?(FiltersSettings = Undefined, 
			"", QueryTextTableFilters(FiltersSettings.ReplacementParameters) + Common.QueryBatchSeparator());
				
		RequestTextForOrders = RequestTextForOrders 		
			+ AccumulationRegisters.ReferencesToTransferFromProduction.QueryTextBalance("TTAccountingData", Filter, "Count <> 0");
			
		Filter = New Structure();
		Filter.Insert("Ref", "References");
		
		RequestTextExcludedProducts = "";
		If FillParameters.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
			RequestTextExcludedProducts = 
			"SELECT DISTINCT
			|	Table.Products AS Products
			|FROM
			|	Document.ProductionStage2_2.ManufacturedProducts AS Table
			|WHERE
			|	Table.Ref IN (&References)
			|	AND NOT Table.Canceled
			|
			|UNION ALL
			|
			|SELECT
			|	Table.Products AS Products
			|FROM
			|	Document.ProductionStage2_2.SideAndIntermediateRelease AS Table
			|WHERE
			|	Table.Ref IN (&References)
			|	AND NOT Table.Canceled";
		ElsIf FillParameters.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
			RequestTextExcludedProducts = 
			"SELECT DISTINCT
			|	Table.Products AS Products
			|FROM
			|	Document.ProductionStage2_2.UnusedMaterials AS Table
			|WHERE
			|	Table.Ref IN (&References)";
		EndIf;
		
		UseExcludedGoods = Not IsBlankString(RequestTextExcludedProducts);
		
		QueryTextConversionFactor =
			"SELECT DISTINCT
			|	NestedQuery.Currency AS Currency
			|INTO DocumentsCurrencies
			|FROM
			|	(SELECT
			|		Attributes.Currency AS Currency
			|	FROM
			|		Document.ProductionStage2_2 AS Attributes
			|	WHERE
			|		Attributes.Ref IN(&References)
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		ManagementAccountingCurrency.Value
			|	FROM
			|		Constant.ManagementAccountingCurrency AS ManagementAccountingCurrency) AS NestedQuery
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ExchangeRates.Currency AS Currency,
			|	ExchangeRates.CourseNumerator AS CourseNumerator,
			|	ExchangeRates.CourseDenominator AS CourseDenominator
			|INTO DocumentExchangeRates_
			|FROM
			|	InformationRegister.RelativeExchangeRates.SliceLast(
			|			,
			|			Currency IN
			|				(SELECT
			|					T.Currency
			|				FROM
			|					DocumentsCurrencies AS T)
			|			AND BaseCurrency = &BaseCurrency) AS ExchangeRates
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DocumentCourse.Currency,
			|	CASE
			|        WHEN DocumentCourse.Currency = CurrencyOfManAccounting.Value
			|			THEN 1
			|		WHEN DocumentCourse.CourseDenominator * ISNULL(ExchangeRateOfManCurrency.CourseNumerator, 0) = 0
			|			THEN 1
			|		ELSE DocumentCourse.CourseNumerator * ExchangeRateOfManCurrency.CourseDenominator / (DocumentCourse.CourseDenominator * ExchangeRateOfManCurrency.CourseNumerator)
			|	END AS ConversionRateToManCurrency
			|INTO TTCurrencyConversionFactors
			|FROM
			|	DocumentExchangeRates_ AS DocumentCourse
			|		LEFT JOIN Constant.ManagementAccountingCurrency AS CurrencyOfManAccounting
			|		ON TRUE
			|		LEFT JOIN DocumentExchangeRates_ AS ExchangeRateOfManCurrency
			|		ON ExchangeRateOfManCurrency.Currency = CurrencyOfManAccounting.Value
			|
			|INDEX BY
			|	DocumentCourse.Currency";
		
		QueryTextOrderDocument = Documents.ProductionStage2_2.QueryTextDocumentGoods(Filter, FillParameters.BusinessOperation);
		
		QueryText = RequestTextForOrders
						+ Common.QueryBatchSeparator()
						+ QueryTextConversionFactor
						+ Common.QueryBatchSeparator()
						+ QueryTextOrderDocument
						+ Common.QueryBatchSeparator()
						+ RequestTextExcludedProducts;
	EndIf;
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("References", FillParameters.AnArrayOfOrders);
	Query.SetParameter("Recorder",  Recorder);
	Query.SetParameter("Warehouse",        FillParameters.Sender);
	Query.SetParameter("Recipient",   FillParameters.Recipient);
	Query.SetParameter("Operation",     FillParameters.BusinessOperation);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillParameters.Organization));
	
	If FiltersSettings <> Undefined Then
		Query.SetParameter("TableFilters", FiltersSettings.TableFilters);
	EndIf;	
	
	PackageTableOrders = Query.ExecuteBatch();
	OrdersTable = PackageTableOrders[PackageTableOrders.UBound() - ?(UseExcludedGoods, 1, 0)].Unload();
	
	If UseExcludedGoods Then
		TableExcludedProducts = PackageTableOrders[PackageTableOrders.UBound()].Unload();
	EndIf;
	
	ColumnToDesign = OrdersTable.Columns.ToRegister; // ValueTableColumn
	ColumnToDesign.Name = "QuantityInOrder";
	
	// Orders_3
	FillingInAccordingToAcceptanceData = Not (FillParameters.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
									Or FillParameters.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom);
	
	Query = New Query;
	
	Filter = New Map;
	AddSelectionItem(Filter);
	
	If FiltersSettings <> Undefined Then
		AddSelectionElement(Filter, ?(FillingInAccordingToAcceptanceData, "DocumentInflow", "DocumentShipments"));	
	EndIf;	 
	
	TextOfRequestRemainsToIssue = ?(FillingInAccordingToAcceptanceData, 
									 AccumulationRegisters.GoodsToReceive.TextOfRequestRemainsToIssueOrders(, Filter), 
									 AccumulationRegisters.GoodsForIssue.TextOfRequestRemainsToIssue(Filter));
	
	If FiltersSettings <> Undefined Then

		QueriesTexts = New Array;	
		QueriesTexts.Add(QueryTextTableFilters(FiltersSettings.ReplacementParameters));	
		QueriesTexts.Add(TextOfRequestRemainsToIssue);
		
		TextOfRequestRemainsToIssue = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		
		Query.SetParameter("TableFilters", FiltersSettings.TableFilters);
		
	EndIf;
	
	Query.Text = TextOfRequestRemainsToIssue;
	
	Query.SetParameter("References", ReferencesForOrders);
	Query.SetParameter("Recorder",  RegistrarForOrders);
	Query.SetParameter("Warehouse", 
		?(FillingInAccordingToAcceptanceData, FillParameters.Recipient, FillParameters.Sender));
	
	TableOrders = Query.Execute().Unload();
	
	ColumnQuantity = TableOrders.Columns.Count; // ValueTableColumn
	ColumnQuantity.Name = "NoteQuantity";
	If TableOrders.Columns.Find("AssemblyInProgress") <> Undefined Then
		ColumnIsCollected = TableOrders.Columns.AssemblyInProgress; // ValueTableColumn
		ColumnIsCollected.Name = "NumberInProgress";
	EndIf;
	
	If Not FillingInAccordingToAcceptanceData Then
		DestinationColumn_ = TableOrders.Columns.Purpose; // ValueTableColumn
		DestinationColumn_.Name = "AssignmentSender";
	EndIf;
	
	KeyFields = StrReplace(FillParameters.KeyFields, 
							   "Purpose, AssignmentSender", 
							   ?(FillingInAccordingToAcceptanceData, "Purpose", "AssignmentSender"));
	
	// Distribution of the resulting tables
	
	Goods.Indexes.Add("ReferenceOrder, " + FillParameters.KeyFields);
	
	// Adding the number of orders
	Var_Key = "ReferenceOrder, RowCode, " + FillParameters.KeyFields;
	Var_Key = ?(FillingInAccordingToAcceptanceData, StrReplace(Var_Key, "Series", ""), Var_Key);
	
	Condition = "On [Count]";
	InvoicesServer.AllocateQuantity(OrdersTable, Goods, "QuantityInOrder", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(OrdersTable, Goods, "QuantityInOrder");
	
	// Adding the number of orders.
	Var_Key = ?(FillingInAccordingToAcceptanceData And InvoiceIsOrder, "", "ReferenceOrder, ") + KeyFields;
	Var_Key = ?(FillingInAccordingToAcceptanceData, StrReplace(Var_Key, "Series", ""), Var_Key);
	
	// In addition to the distribution of the quantity, it is necessary to copy as is the values of the Series field according to order data.
	FieldsToFillIn = ?(FillingInAccordingToAcceptanceData, "Series", "");
	
	// There are invoices and orders
	Condition = "[Count], [QuantityInOrder], On [QuantityInOrder]";
	InvoicesServer.DistributeQuantityAndFill(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, False, FieldsToFillIn);
	
	// There are orders, no invoices
	Condition = "NOT [Count], [QuantityInOrder], On [QuantityInOrder]";
	InvoicesServer.DistributeQuantityAndFill(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, False, FieldsToFillIn);
	
	// There are invoices, no orders
	Condition = "[Count], NOT [QuantityInOrder]";
	InvoicesServer.DistributeQuantityAndFill(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True, FieldsToFillIn);
	
	// There are measured goods and the permissible deviation is set
	InvoicesServer.DistributeDeviationOfDimensionalGoods(TableOrders, Goods, "QuantityInOrder", "NoteQuantity", Var_Key);
	
	// Adding an undistributed number of orders in separate lines
	// Except for the excluded items of the nomenclature.
	If UseExcludedGoods Then
		Var_Key = "Products";
		Condition = "";
		InvoicesServer.AllocateQuantity(TableOrders, TableExcludedProducts, "NoteQuantity", Var_Key, Condition, True);
	EndIf;
	InvoicesServer.SupplementTable(TableOrders, Goods, "NoteQuantity");
	
	// Additional information - how much product is collected
	If TableOrders.Columns.Find("NumberInProgress") <> Undefined Then
		InvoicesServer.AllocateQuantity(TableOrders, Goods, "NumberInProgress", Var_Key, "", True);
	EndIf;
	
	If ReferencesForOrders <> Undefined Then
		MovementOfProductsAndMaterialsLocalization.FillInBarcodesOfPackages(ReferencesForOrders, Goods, PackageBarcodes);
	EndIf;
	
EndProcedure

// Returns the Products table
//
// Parameters:
// 	Invoice - DocumentRef.MovementOfProductsAndMaterials - Link to the invoice, the table part of the Goods to be returned.
//
// Returns:
// 	ValueTable
//
Function TableDataAndDocument(Invoice) Export
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	Table.LineNumber                    AS LineNumber,
	|	Table.Products                   AS Products,
	|	Table.Characteristic                 AS Characteristic,
	|	Table.Series                          AS Series,
	|	Table.Purpose                     AS Purpose,
	|	Table.AssignmentSender          AS AssignmentSender,
	|	Table.Package                       AS Package,
	|	Table.Count                     AS Count,
	|	Table.NumberOfPackages             AS NumberOfPackages,
	|	Table.ItemsLocationAttributes     AS ItemsLocationAttributes,
	|	Table.RowID            AS RowID,
	|	Table.BatchesIndicationStatus            AS BatchesIndicationStatus,
	|	Table.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
	|	Table.BatchesIndicationStatusRecipient  AS BatchesIndicationStatusRecipient,
	|	CASE
	|		WHEN Table.Ref.ByReferences
	|			THEN Table.ReferenceOrder
	|		ELSE Table.Ref
	|	END                                  AS ReferenceOrder,
	|	Table.RowCode                      AS RowCode,
	|	Table.ProductsGroup                AS ProductsGroup,
	|	Table.Price                           AS Price,
	|	Table.Sum                          AS Sum
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS Table
	|WHERE
	|	Table.Ref = &Invoice";
	
	Query.SetParameter("Invoice", Invoice);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// Returns an array containing the passed invoice, as well as:
// A. an Order from an array of orders (if there is one element in the array)
// B. All orders that fit the selection by header details.
//
// Parameters:
//  Invoice		 - DocumentRef.MovementOfProductsAndMaterials -
//  HeaderAttributes	 - Structure - Must contain the keys Organization, business Operation
//  								Sender, Recipient, and directionsof Activity.
//
// Returns:
//  Array - an array of documents is ordered for internal use, ordered for repair.
//
Function WaybillOrders(Invoice, HeaderAttributes) Export
	
	Query = New Query();
	Query.SetParameter("Recorder",             Invoice);
	Query.SetParameter("Organization",             HeaderAttributes.Organization);
	Query.SetParameter("Sender",             HeaderAttributes.Sender);
	Query.SetParameter("Recipient",              HeaderAttributes.Recipient);
	Query.SetParameter("InternalSubcontracting",   HeaderAttributes.InternalSubcontracting);
	Query.SetParameter("MaterialProviderCompany",      HeaderAttributes.MaterialProviderCompany);
	Query.SetParameter("BusinessOperation",   HeaderAttributes.BusinessOperation);
	
	If HeaderAttributes.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		Query.Text =
		"SELECT DISTINCT
		|	DocumentTable.Ref AS OrderDocument
		|FROM
		|	Document.OrderOfMaterialsForProduction AS DocumentTable
		|WHERE
		|	&Filter
		|	AND DocumentTable.Posted";
		
		ConditionTextByKeyFields = 
		"DocumentTable.Organization               = &Organization
		|AND DocumentTable.Warehouse                   = &Sender
		|AND DocumentTable.ShopFloorStockroom         = &Recipient
		|AND DocumentTable.BusinessOperation   = &BusinessOperation";
	ElsIf HeaderAttributes.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction Then
		Query.Text =
		"SELECT DISTINCT
		|	DocumentTable.Ref AS OrderDocument
		|FROM
		|	Document.ProductionStage2_2 AS DocumentTable
		|		INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Goods
		|		ON DocumentTable.Ref = Goods.Ref
		|WHERE
		|	&Filter
		|	AND NOT Goods.Canceled
		|	AND DocumentTable.Posted";
		
		ConditionTextByKeyFields = 
		"DocumentTable.Organization               = &Organization
		|AND DocumentTable.InternalSubcontracting   = &InternalSubcontracting
		|AND DocumentTable.MaterialProviderCompany      = &MaterialProviderCompany
		|AND Goods.Warehouse                             = &Sender
		|AND Goods.Department                     = &Recipient
		|AND &BusinessOperation                   = VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)";
		
	ElsIf HeaderAttributes.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
		Query.Text =
		"SELECT DISTINCT
		|	DocumentTable.Ref AS OrderDocument
		|FROM
		|	Document.ProductionStage2_2 AS DocumentTable
		|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS Goods
		|		ON DocumentTable.Ref = Goods.Ref
		|WHERE
		|	&Filter
		|	AND DocumentTable.Posted
		|	AND NOT Goods.Canceled
		|
		|UNION
		|
		|SELECT DISTINCT
		|	DocumentTable.Ref AS OrderDocument
		|FROM
		|	Document.ProductionStage2_2 AS DocumentTable
		|		INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS Goods
		|		ON DocumentTable.Ref = Goods.Ref
		|WHERE
		|	&Filter
		|	AND DocumentTable.Posted
		|	AND NOT Goods.Canceled";
		
		ConditionTextByKeyFields = 
		"DocumentTable.Organization               = &Organization
		|AND DocumentTable.InternalSubcontracting   = &InternalSubcontracting
		|AND DocumentTable.MaterialProviderCompany      = &MaterialProviderCompany
		|AND Goods.Department                     = &Sender
		|AND Goods.Recipient                        = &Recipient
		|AND &BusinessOperation                   = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)";
		
	ElsIf HeaderAttributes.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
		Query.Text =
		"SELECT DISTINCT
		|	DocumentTable.Ref AS OrderDocument
		|FROM
		|	Document.ProductionStage2_2 AS DocumentTable
		|		INNER JOIN Document.ProductionStage2_2.UnusedMaterials AS Goods
		|		ON DocumentTable.Ref = Goods.Ref
		|WHERE
		|	&Filter
		|	AND DocumentTable.Posted";
		
		ConditionTextByKeyFields = 
		"DocumentTable.Organization               = &Organization
		|AND DocumentTable.InternalSubcontracting   = &InternalSubcontracting
		|AND DocumentTable.MaterialProviderCompany      = &MaterialProviderCompany
		|AND Goods.Department                     = &Sender
		|AND Goods.Recipient                        = &Recipient
		|AND &BusinessOperation                   = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction)";
	EndIf;
	
	If Not IsBlankString(Query.Text) Then
		
		Query.Text =
			StrReplace(
				Query.Text,
				"&Filter",
				ConditionTextByKeyFields);
		
		ReturnedArray = Query.Execute().Unload().UnloadColumn("OrderDocument");
		
	Else
		
		ReturnedArray = New Array;
		
	EndIf;
	
	If ValueIsFilled(Invoice) Then
		ReturnedArray.Add(Invoice);
	EndIf;
	
	Return ReturnedArray;
	
EndFunction

// Returns a list of details that can be used to group orders within a single invoice.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function KeyFieldsOfHeader() Export
	
	Return "Organization, Department";
	
EndFunction

// Returns a list of Attributes that can be used to group stages within a single invoice.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function KeyFieldsOfStageOrderHeader() Export
	
	Return "Organization, Department, InternalSubcontracting, MaterialProviderCompany";
	
EndFunction
#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Status,Sender,Recipient,Date,BusinessOperation,ByReferences";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.MovementOfProductsAndMaterials";
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
		SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.TransferToProductionShipment);
		If Object.Status = Enums.StatusesOfProductsAndMaterialMovement.Accepted Then
			SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.TransferToProductionReceiving);
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
		
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipProductsFromProduction);
		If Object.Status = Enums.StatusesOfProductsAndMaterialMovement.Accepted Then
			SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ProductReceivingFromManufacturing);
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom Then
		
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReturnMaterialsFromProductionShipment);
		If Object.Status = Enums.StatusesOfProductsAndMaterialMovement.Accepted Then
			SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReturnMaterialsFromProductionReceiving);
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
		
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ProductionTransferShipment);
		If Object.Status = Enums.StatusesOfProductsAndMaterialMovement.Accepted Then
			SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingByTransfersInProduction);
		EndIf;
		
	EndIf; 
	
	If TypeOf(Object.Sender) = Type("CatalogRef.Warehouses") Then
		SenderSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Sender, False);
	Else
		SenderSeriesParameters = ProductionServer.UseOfSeriesInProduction22();
	EndIf;
	
	If TypeOf(Object.Recipient) = Type("CatalogRef.Warehouses") Then
		RecipientSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Recipient, False);
	Else
		RecipientSeriesParameters = ProductionServer.UseOfSeriesInProduction22();
	EndIf;
	
	SeriesSpecificationParameters.UseItemsBatch = SenderSeriesParameters.UseItemsBatch
															Or TypeOf(Object.Recipient) = Type("CatalogRef.Warehouses")
																And RecipientSeriesParameters.UseItemsBatch
																And Not WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Recipient, Object.Date)
															Or RecipientSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = SenderSeriesParameters.UseCostAccountingByBatches
															Or RecipientSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.WarehouseFieldName = "Sender";
	SeriesSpecificationParameters.NameOfSenderWarehouseField = "Sender";
	SeriesSpecificationParameters.NameOfRecipientWarehouseField  = "Recipient";
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("AssignmentSender");
		
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	
	SeriesSpecificationParameters.ShipmentPlanning = False;
	SeriesSpecificationParameters.SelectionPlanning   = False;
	SeriesSpecificationParameters.FactOfSelection           = True;
	
	SeriesSpecificationParameters.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(SeriesSpecificationParameters);
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusSender");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusRecipient");
	
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_ReferenceOrder");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_RowCode");
		
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the value of the receipt or shipment order.
//
// Parameters:
//  FieldValuesToIdentifyReferences	 - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef.ProductionStage2_2, DocumentRef.OrderOfMaterialsForProduction, Undefined - Link to the order.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	
	If FieldValuesToIdentifyReferences.Goods_RowCode <> 0 Then
		Return FieldValuesToIdentifyReferences.Goods_ReferenceOrder;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.AssignmentSender AS AssignmentSender,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
	|	Goods.BatchesIndicationStatusRecipient AS BatchesIndicationStatusRecipient,
	|	Goods.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.AssignmentSender AS AssignmentSender,
	|	Goods.Series AS Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.AssignmentSender,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.AssignmentSender AS AssignmentSender,
	|	SetOfSeries.Count AS Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.AssignmentSender AS AssignmentSender,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.AssignmentSender
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS StatusOfSpecifyingSeriesIsOld,
	|	CASE
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy IS NULL
	|				AND SeriesAccountingPolicyProduction.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy IS NOT NULL 
	|			THEN CASE
	|					WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.UseCostAccountingByBatches
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 14
	|								ELSE 13
	|							END
	|					WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|											AND ProductsToRequest.Count > 0
	|										OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 10
	|								ELSE 9
	|							END
	|					WHEN SourceWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|							AND &Date >= SourceWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|						THEN 0
	|					WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|											AND ProductsToRequest.Count > 0
	|										OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN CASE
	|											WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.BatchesAccountingByFEFO
	|												THEN 6
	|											ELSE 8
	|										END
	|								ELSE CASE
	|										WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.BatchesAccountingByFEFO
	|											THEN 5
	|										ELSE 7
	|									END
	|							END
	|					WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyByPickingResult
	|							AND BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyOnShipmentForInternalNeeds
	|							AND &FactOfSelection
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|											AND ProductsToRequest.Count > 0
	|										OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN CASE
	|											WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.AccountForRemainingSeries
	|												THEN 4
	|											ELSE 2
	|										END
	|								ELSE CASE
	|										WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.AccountForRemainingSeries
	|											THEN 3
	|										ELSE 1
	|									END
	|							END
	|					ELSE 0
	|				END
	|		WHEN SeriesAccountingPolicyProduction.BatchAccountingPolicy IS NOT NULL 
	|			THEN CASE
	|					WHEN SeriesAccountingPolicyProduction.BatchAccountingPolicy.UseCostAccountingByBatches
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 14
	|								ELSE 13
	|							END
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO SenderStatuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|				AND ProductsToRequest.AssignmentSender = SeriesToRequest.AssignmentSender
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPoliciesWarehouse
	|				INNER JOIN Catalog.Warehouses AS SourceWarehouse
	|				ON (SourceWarehouse.Ref = &SourceWarehouse)
	|					AND (BatchAccountingPoliciesWarehouse.Warehouse = &SourceWarehouse)
	|			ON (BatchAccountingPoliciesWarehouse.Warehouse = &SourceWarehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPoliciesWarehouse.Ref
	|				AND (VALUETYPE(&SourceWarehouse) = TYPE(Catalog.Warehouses))
	|			LEFT JOIN Catalog.ItemKinds AS SeriesAccountingPolicyProduction
	|			ON ProductsToRequest.ProductKind = SeriesAccountingPolicyProduction.Ref
	|				AND (VALUETYPE(&SourceWarehouse) = TYPE(Catalog.BusinessStructure))
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.AssignmentSender = ProductsToRequest.AssignmentSender
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS StatusOfSpecifyingSeriesIsOld,
	|	CASE
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy IS NULL
	|				AND SeriesAccountingPolicyProduction.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy IS NOT NULL 
	|			THEN CASE
	|					WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.UseCostAccountingByBatches
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 14
	|								ELSE 13
	|							END
	|					WHEN DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|							AND &Date >= DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|						THEN 0
	|					WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|											AND ProductsToRequest.Count > 0
	|										OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 10
	|								WHEN &ShipProductsFromProduction
	|									THEN 11
	|								ELSE 9
	|							END
	|					WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|											AND ProductsToRequest.Count > 0
	|										OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 8
	|								WHEN &ShipProductsFromProduction
	|									THEN 27
	|								ELSE 7
	|							END
	|					WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyOnReceiving
	|							AND BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.SpecifyOnReceivingByTransfer
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|											AND ProductsToRequest.Count > 0
	|										OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN CASE
	|											WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.AccountForRemainingSeries
	|												THEN 4
	|											ELSE 2
	|										END
	|								WHEN &ShipProductsFromProduction
	|									THEN CASE
	|											WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.AccountForRemainingSeries
	|												THEN 23
	|											ELSE 21
	|										END
	|								ELSE CASE
	|										WHEN BatchAccountingPoliciesWarehouse.BatchAccountingPolicy.AccountForRemainingSeries
	|											THEN 3
	|										ELSE 1
	|									END
	|							END
	|					ELSE 0
	|				END
	|		WHEN SeriesAccountingPolicyProduction.BatchAccountingPolicy IS NOT NULL 
	|			THEN CASE
	|					WHEN SeriesAccountingPolicyProduction.BatchAccountingPolicy.UseCostAccountingByBatches
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 14
	|								ELSE 13
	|							END
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO RecipientStatuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|				AND ProductsToRequest.AssignmentSender = SeriesToRequest.AssignmentSender
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPoliciesWarehouse
	|				INNER JOIN Catalog.Warehouses AS DestinationWarehouse
	|				ON (DestinationWarehouse.Ref = &DestinationWarehouse)
	|					AND (BatchAccountingPoliciesWarehouse.Warehouse = &DestinationWarehouse)
	|			ON (BatchAccountingPoliciesWarehouse.Warehouse = &DestinationWarehouse)
	|				AND (BatchAccountingPoliciesWarehouse.Ref = ProductsToRequest.ProductKind)
	|				AND (VALUETYPE(&DestinationWarehouse) = TYPE(Catalog.Warehouses))
	|			LEFT JOIN Catalog.ItemKinds AS SeriesAccountingPolicyProduction
	|			ON ProductsToRequest.ProductKind = SeriesAccountingPolicyProduction.Ref
	|				AND (VALUETYPE(&DestinationWarehouse) = TYPE(Catalog.BusinessStructure))
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.AssignmentSender = ProductsToRequest.AssignmentSender
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	SenderStatuses.BatchesIndicationStatus AS BatchesIndicationStatusSender,
	|	CASE
	|		WHEN &ReceivingByTransfersInProduction
	|				OR &ReturnMaterialsFromProductionReceiving
	|				OR &ProductReceivingFromManufacturing
	|				OR &TransferToProductionReceiving
	|				OR &ShipProductsFromProduction
	|					AND RecipientStatuses.BatchesIndicationStatus IN (11, 21, 23, 27)
	|			THEN RecipientStatuses.BatchesIndicationStatus
	|		ELSE 0
	|	END AS BatchesIndicationStatusRecipient,
	|	CASE
	|		WHEN RecipientStatuses.BatchesIndicationStatus IN (13, 14)
	|				AND SenderStatuses.BatchesIndicationStatus <> 0
	|			THEN RecipientStatuses.BatchesIndicationStatus
	|		WHEN SenderStatuses.BatchesIndicationStatus IN (5, 6)
	|			THEN SenderStatuses.BatchesIndicationStatus
	|		WHEN SenderStatuses.BatchesIndicationStatus > CASE
	|				WHEN &ReceivingByTransfersInProduction
	|						OR &ReturnMaterialsFromProductionReceiving
	|						OR &ProductReceivingFromManufacturing
	|						OR &TransferToProductionReceiving
	|						OR &ShipProductsFromProduction
	|							AND RecipientStatuses.BatchesIndicationStatus IN (11, 21, 23, 27)
	|					THEN RecipientStatuses.BatchesIndicationStatus
	|				ELSE 0
	|			END
	|			THEN SenderStatuses.BatchesIndicationStatus
	|		ELSE CASE
	|				WHEN &ReceivingByTransfersInProduction
	|						OR &ReturnMaterialsFromProductionReceiving
	|						OR &ProductReceivingFromManufacturing
	|						OR &TransferToProductionReceiving
	|						OR &ShipProductsFromProduction
	|							AND RecipientStatuses.BatchesIndicationStatus IN (11, 21, 23, 27)
	|					THEN RecipientStatuses.BatchesIndicationStatus
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN SenderStatuses AS SenderStatuses
	|		ON (SenderStatuses.LineNumber = Goods.LineNumber)
	|		LEFT JOIN RecipientStatuses AS RecipientStatuses
	|		ON (RecipientStatuses.LineNumber = Goods.LineNumber)
	|WHERE
	|	(SenderStatuses.BatchesIndicationStatus <> Goods.BatchesIndicationStatusSender
	|			OR CASE
	|				WHEN &ReceivingByTransfersInProduction
	|						OR &ReturnMaterialsFromProductionReceiving
	|						OR &ProductReceivingFromManufacturing
	|						OR &TransferToProductionReceiving
	|						OR &ShipProductsFromProduction
	|							AND RecipientStatuses.BatchesIndicationStatus IN (11, 21, 23, 27)
	|					THEN RecipientStatuses.BatchesIndicationStatus
	|				ELSE 0
	|			END <> Goods.BatchesIndicationStatusRecipient
	|			OR CASE
	|				WHEN RecipientStatuses.BatchesIndicationStatus IN (13, 14)
	|						AND SenderStatuses.BatchesIndicationStatus <> 0
	|					THEN RecipientStatuses.BatchesIndicationStatus
	|				WHEN SenderStatuses.BatchesIndicationStatus IN (5, 6)
	|					THEN SenderStatuses.BatchesIndicationStatus
	|				WHEN SenderStatuses.BatchesIndicationStatus > CASE
	|						WHEN &ReceivingByTransfersInProduction
	|								OR &ReturnMaterialsFromProductionReceiving
	|								OR &ProductReceivingFromManufacturing
	|								OR &TransferToProductionReceiving
	|								OR &ShipProductsFromProduction
	|									AND RecipientStatuses.BatchesIndicationStatus IN (11, 21, 23, 27)
	|							THEN RecipientStatuses.BatchesIndicationStatus
	|						ELSE 0
	|					END
	|					THEN SenderStatuses.BatchesIndicationStatus
	|				ELSE CASE
	|						WHEN &ReceivingByTransfersInProduction
	|								OR &ReturnMaterialsFromProductionReceiving
	|								OR &ProductReceivingFromManufacturing
	|								OR &TransferToProductionReceiving
	|								OR &ShipProductsFromProduction
	|									AND RecipientStatuses.BatchesIndicationStatus IN (11, 21, 23, 27)
	|							THEN RecipientStatuses.BatchesIndicationStatus
	|						ELSE 0
	|					END
	|			END <> Goods.BatchesIndicationStatus)
	|
	|ORDER BY
	|	Goods.LineNumber";
	
	Return QueryText;

EndFunction

// The procedure fills in a series of items for expenditure orders issued based on this document.
//
// Parameters:
//  Object	- DocumentObject, FormDataStructure - The document to be filled in.
//	Filter   - ValueTable - table of selection on the item (characterization). Undefined by default
//
Procedure FillInShippingInstructions(Object, Filter = Undefined) Export
	
	UseWarehouseManagemantSystemForGoodsIssue = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Object.Sender, Object.Date);
	
	SenderSeriesAreUsed = GetFunctionalOption("UseItemsBatchWarehouse", New Structure("Warehouse", Object.Sender));
	
	If Not UseWarehouseManagemantSystemForGoodsIssue
		Or Not SenderSeriesAreUsed Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryText =
	"SELECT
	|	GoodsIssueNote.Ref AS Ref
	|INTO GoodsIssueNotes
	|FROM
	|	Document.GoodsIssueNote AS GoodsIssueNote
	|WHERE
	|	GoodsIssueNote.Posted
	|	AND GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.Shipped_)
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.GoodsIssueNote.GoodsByReferences AS GoodsByReferences
	|			WHERE
	|				GoodsByReferences.Ref = GoodsIssueNote.Ref
	|				AND (&ByReferences
	|						AND GoodsByReferences.ReferenceOrder IN (&References)
	|					OR NOT &ByReferences
	|						AND GoodsByReferences.ReferenceOrder = &ReferenceOrder))
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TSGoods.Ref                AS Ref,
	|	TSGoods.Series                 AS Series,
	|	TSGoods.Products          AS Products,
	|	TSGoods.Characteristic        AS Characteristic,
	|	TSGoods.Purpose            AS Purpose,
	|	TSGoods.AssignmentSender AS AssignmentSender,
	|	TSGoods.Count            AS Count
	|INTO TSGoods
	|FROM
	|	Document.MovementOfProductsAndMaterials AS MovementOfProductsAndMaterials
	|		INNER JOIN Document.MovementOfProductsAndMaterials.Goods AS TSGoods
	|		ON MovementOfProductsAndMaterials.Ref = TSGoods.Ref
	|WHERE
	|	MovementOfProductsAndMaterials.Posted
	|	AND MovementOfProductsAndMaterials.Ref <> &ReferenceOrder
	|	AND TSGoods.ReferenceOrder IN(&References)
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	AssignmentSender
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RemainingSeries.Series                 AS Series,
	|	RemainingSeries.Products          AS Products,
	|	RemainingSeries.Characteristic        AS Characteristic,
	|	RemainingSeries.AssignmentSender AS AssignmentSender,
	|	SUM(RemainingSeries.Count)     AS Count
	|FROM
	|	(SELECT
	|		ShippedGoods.Series          AS Series,
	|		ShippedGoods.Products   AS Products,
	|		ShippedGoods.Characteristic AS Characteristic,
	|		ShippedGoods.Purpose     AS AssignmentSender,
	|		ShippedGoods.Count     AS Count
	|	FROM
	|		GoodsIssueNotes AS GoodsIssueNotes
	|			INNER JOIN Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|			ON GoodsIssueNotes.Ref = ShippedGoods.Ref
	|	WHERE
	|		ShippedGoods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship)
	|		AND ShippedGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TSGoods.Series,
	|		TSGoods.Products,
	|		TSGoods.Characteristic,
	|		TSGoods.AssignmentSender,
	|		- TSGoods.Count
	|	FROM
	|		TSGoods AS TSGoods
	|	WHERE
	|		TSGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TSSetOfSeries.Series,
	|		TSSetOfSeries.Products,
	|		TSSetOfSeries.Characteristic,
	|		TSSetOfSeries.AssignmentSender,
	|		- TSSetOfSeries.Count
	|	FROM
	|		Document.MovementOfProductsAndMaterials.SetOfSeries AS TSSetOfSeries
	|	WHERE
	|		TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TSGoods AS TSGoods
	|				WHERE
	|					TSGoods.Ref                  = TSSetOfSeries.Ref
	|					AND TSGoods.Products          = TSSetOfSeries.Products
	|					AND TSGoods.Characteristic        = TSSetOfSeries.Characteristic
	|					AND TSGoods.Purpose            = TSSetOfSeries.Purpose
	|					AND TSGoods.AssignmentSender = TSSetOfSeries.AssignmentSender)) AS RemainingSeries
	|
	|GROUP BY
	|	RemainingSeries.Series,
	|	RemainingSeries.Characteristic,
	|	RemainingSeries.Products,
	|	RemainingSeries.AssignmentSender
	|
	|HAVING
	|	SUM(RemainingSeries.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LinkFields,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.LineNumber    AS LineNumber,
	|	GoodsTable.Count     AS Count
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|WHERE
	|	GoodsTable.Count > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsTable.LineNumber AS LineNumber
	|FROM
	|	(SELECT
	|		GoodsTable.LineNumber AS LineNumber
	|	FROM
	|		GoodsTable AS GoodsTable
	|
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON (CAST(GoodsTable.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref)
	|		AND (BatchAccountingPolicies.Warehouse IN (&DestinationWarehouse, &SourceWarehouse))
	|	WHERE
	|		ISNULL(BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches, FALSE)
	|	
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTable.LineNumber AS LineNumber
	|	FROM
	|		GoodsTable AS GoodsTable
	|
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON (CAST(GoodsTable.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref)
	|		AND (BatchAccountingPolicies.Warehouse IN (&DestinationWarehouse, &SourceWarehouse))
	|	WHERE
	|		ISNULL(BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment, FALSE)
	|	) AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LinkFields,
	|	GoodsTable.Products      AS Products,
	|	GoodsTable.Characteristic    AS Characteristic,
	|	SUM(GoodsTable.Count) AS Count
	|FROM
	|	GoodsTable AS GoodsTable
	|
	|WHERE
	|	TRUE IN(
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		WHERE
	|			CAST(GoodsTable.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
	|			AND BatchAccountingPolicies.Warehouse IN (&DestinationWarehouse, &SourceWarehouse)
	|			AND NOT ISNULL(BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches, TRUE)
	|			AND NOT ISNULL(BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment, TRUE)
	|		)
	|
	|GROUP BY
	|	GoodsTable.LinkFields,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic";
	
	LinkFields = "";
	LinkFieldsInRequest = "";
	Comma = "";
	For Each Field In SeriesSpecificationParameters(Object).LinkFields Do
		LinkFields = Field + Comma + LinkFields;
		LinkFieldsInRequest = LinkFieldsInRequest + "
			|	GoodsTable." + Field + ",";
		Comma = ",";
	EndDo;
	QueryText = StrReplace(QueryText, "GoodsTable.LinkFields,", LinkFieldsInRequest);
	Query = New Query(QueryText);
	
	GoodsTable      = Object.Goods.Unload(, 
		"LineNumber, Products, Characteristic, ReferenceOrder, Count," + LinkFields);
	
	ReferenceArray = ?(Object.ByReferences, GoodsTable.UnloadColumn("ReferenceOrder"), New Array);
	
	If ValueIsFilled(Filter) Then                                                   
		
		FilterStructure1 = New Structure("Ref, Products, Characteristic");
				
		RowIndex = GoodsTable.Count() - 1;
		While RowIndex > - 1 Do
			
			TableRow = GoodsTable[RowIndex];
			FillPropertyValues(FilterStructure1, TableRow);
			FilterStructure1.Ref = ?(ValueIsFilled(TableRow.ReferenceOrder), TableRow.ReferenceOrder, Object.Ref);
			
			ArrayOfFoundSelectionStrings = Filter.FindRows(FilterStructure1);
			If ArrayOfFoundSelectionStrings.Count() = 0 Then
				GoodsTable.Delete(TableRow);
			EndIf;
			
			RowIndex = RowIndex - 1;
			
		EndDo;
		
	EndIf;
	
	Query.SetParameter("References",     ReferenceArray);
	Query.SetParameter("ReferenceOrder",     Object.Ref);
	Query.SetParameter("GoodsTable",    GoodsTable);
	Query.SetParameter("DestinationWarehouse",  Object.Recipient);
	Query.SetParameter("SourceWarehouse", Object.Sender);
	Query.SetParameter("ByReferences",  Object.ByReferences);
	
	QueryResult = Query.ExecuteBatch();
	OrderSeriesTable = QueryResult[2].Unload();
	
	TheStructureOfTheSearch        = New Structure("Products, Characteristic, AssignmentSender");
	SearchStructureWithSeries = New Structure("Products, Characteristic, Series, AssignmentSender");
	StructureOfActions      = New Structure("RecalculateNumberOfPackages");
	
	RowsToProcess = New Array;
	
	// Fill in the "Series" column in the "Products" tabular part
	SelectingLineNumbersWithWHSeries = QueryResult[4].Select();
	While SelectingLineNumbersWithWHSeries.Next() Do
		
		StringWithSeriesOfVHFProducts = Object.Goods[SelectingLineNumbersWithWHSeries.LineNumber - 1];
		
		ProductBalance = StringWithSeriesOfVHFProducts.Count;
		BalanceOfOriginalProduct = ProductBalance;
		
		// First we will try to leave the invoice series
		FillPropertyValues(SearchStructureWithSeries, StringWithSeriesOfVHFProducts);
		ArrayOfRowsAndSeries = OrderSeriesTable.FindRows(SearchStructureWithSeries);
		
		If ArrayOfRowsAndSeries.Count() > 0 Then
			FirstRow = True;
			For Each Page1 In ArrayOfRowsAndSeries Do
				
				If Not FirstRow Then
					NewRow = Object.Goods.Add();
					FillPropertyValues(NewRow, StringWithSeriesOfVHFProducts);
					StringWithSeriesOfVHFProducts = NewRow;
				Else
					FirstRow = False;
				EndIf;
				
				FillingCount = Min(ProductBalance,Page1.Count);
				StringWithSeriesOfVHFProducts.Count = FillingCount;
				
				RowsToProcess.Add(StringWithSeriesOfVHFProducts);
				
				Page1.Count  = Page1.Count  - FillingCount;
				ProductBalance = ProductBalance - FillingCount;
				
				If Page1.Count = 0 Then
					OrderSeriesTable.Delete(Page1);
				EndIf;
				
				If ProductBalance = 0 Then
					Break;
				EndIf;
				
			EndDo;
		EndIf;
		
		If ProductBalance = 0 Then
			Continue;
		EndIf;
		
		// Fill in a series of orders
		FillPropertyValues(TheStructureOfTheSearch, StringWithSeriesOfVHFProducts);
		ArrayOfRowsAndSeries = OrderSeriesTable.FindRows(TheStructureOfTheSearch);
		
		If ArrayOfRowsAndSeries.Count() > 0 Then
			FirstRow = True;
			For Each Page1 In ArrayOfRowsAndSeries Do
				
				If Not FirstRow Then
					NewRow = Object.Goods.Add();
					FillPropertyValues(NewRow, StringWithSeriesOfVHFProducts);
					StringWithSeriesOfVHFProducts = NewRow;
				Else
					FirstRow = False;
				EndIf;
				
				StringWithSeriesOfVHFProducts.Series = Page1.Series;
				FillingCount = Min(ProductBalance,Page1.Count);
				StringWithSeriesOfVHFProducts.Count = FillingCount;
				
				RowsToProcess.Add(StringWithSeriesOfVHFProducts);
				
				Page1.Count  = Page1.Count  - FillingCount;
				ProductBalance = ProductBalance - FillingCount;
				
				If Page1.Count = 0 Then
					OrderSeriesTable.Delete(Page1);
				EndIf;
				
				If ProductBalance = 0 Then
					Break;
				EndIf;
				
			EndDo;
		EndIf;
		
		If ProductBalance > 0 Then
			If BalanceOfOriginalProduct > ProductBalance Then
				NewRow = Object.Goods.Add();
				FillPropertyValues(NewRow, StringWithSeriesOfVHFProducts);
				StringWithSeriesOfVHFProducts = NewRow;
				StringWithSeriesOfVHFProducts.Count = ProductBalance;
				
				RowsToProcess.Add(StringWithSeriesOfVHFProducts);
				
			EndIf;
			StringWithSeriesOfVHFProducts.Series = Undefined;
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	If ValueIsFilled(Filter) Then
		
		For Each LineTT In GoodsTable Do
			
			FilterStructure1 = New Structure("Products, Characteristic," + LinkFields);
			FillPropertyValues(FilterStructure1, LineTT);
			
			FoundRows = Object.SetOfSeries.FindRows(FilterStructure1);
			RowIndex    = FoundRows.UBound();
			While RowIndex > - 1 Do
				Object.SetOfSeries.Delete(FoundRows[RowIndex]);
				RowIndex = RowIndex - 1;
			EndDo;
			
		EndDo;	
		
	Else
		Object.SetOfSeries.Clear();
	EndIf;
	
	// It is necessary to bypass the Goods in order to distribute the series according to the communication fields that are not in the order (Appointment and document Reserveseries).
	SampleProducts_ = QueryResult[5].Select();
	While SampleProducts_.Next() Do
		ProductBalance = SampleProducts_.Count;
		FillPropertyValues(TheStructureOfTheSearch, SampleProducts_);
		ArrayOfRowsAndSeries = OrderSeriesTable.FindRows(TheStructureOfTheSearch);
		For Each TableRow_ In ArrayOfRowsAndSeries Do
			NewLineTSSeries = Object.SetOfSeries.Add();
			FillPropertyValues(NewLineTSSeries,SampleProducts_);
			NewLineTSSeries.Series = TableRow_.Series;
			FillingCount = Min(ProductBalance,TableRow_.Count);
			NewLineTSSeries.Count = FillingCount;
			TableRow_.Count = TableRow_.Count - FillingCount;
			ProductBalance           = ProductBalance           - FillingCount;
			If TableRow_.Count = 0 Then
				OrderSeriesTable.Delete(TableRow_);
			EndIf;
			If ProductBalance = 0 Then
				Break;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// Fills in the series in the document by production stages
//
// Parameters:
//  Object	 - DocumentObject.MovementOfProductsAndMaterials	 - the document in which you need to fill out the series.
//
Procedure FillSeriesByProductionStages(Object) Export
	
	If Object.Goods.Count() = 0 Then
		Return;
	EndIf;
	
	If Not Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
		ExceptionText = NStr("vi = 'Lỗi gọi ra thủ tục ""%1"". Hãy liên hệ với người quản trị';
							|ru = 'Ошибка вызова процедуры ""%1"". Обратитесь к администратору';
							|en = 'An error occurred when calling the ""%1"" procedure. Please contact the administrator.'; fa = 'An error occurred when calling the ""%1"" procedure. Please contact the administrator.';
							|it = 'Errore di chiamata della procedura ""%1"". Rivolgersi all''amministratore';
							|pl = 'Błąd wywołania procedury ""%1"". Zwróć się do administratora';
							|tr = '""%1"" prosedür çağrısı hatası. Yöneticiye başvurun'");
		Raise StrTemplate(ExceptionText, "MovementOfProductsAndMaterials.FillSeriesByProductionStages()");
	EndIf;
	
	// We will get a series of stages in the context of orders and line codes.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text =
	"SELECT ALLOWED
	|	SeriesTable.Ref                AS ReferenceOrder,
	|	SeriesTable.Series                 AS Series,
	|	SeriesTable.Products          AS Products,
	|	SeriesTable.Characteristic        AS Characteristic,
	|	SeriesTable.Recipient            AS Recipient,
	|	SeriesTable.Purpose            AS Purpose,
	|	SeriesTable.ProductionDate      AS ProductionDate,
	|	SeriesTable.Canceled              AS Canceled,
	|	SeriesTable.Department         AS Department,
	|	SUM(SeriesTable.Count)     AS Count
	|INTO SeriesOfStages
	|FROM
	|	(SELECT
	|		SeriesTable.Ref            AS Ref,
	|		SeriesTable.Series             AS Series,
	|		SeriesTable.Products      AS Products,
	|		SeriesTable.Characteristic    AS Characteristic,
	|		SeriesTable.Recipient        AS Recipient,
	|		SeriesTable.Purpose        AS Purpose,
	|		SeriesTable.ProductionDate  AS ProductionDate,
	|		SeriesTable.Canceled          AS Canceled,
	|		SeriesTable.Department     AS Department,
	|		SeriesTable.Count        AS Count
	|	FROM
	|		Document.ProductionStage2_2.BatchFinishedProducts AS SeriesTable
	|	WHERE
	|		SeriesTable.Ref IN (&ListOfOrders_)
	|		AND SeriesTable.Recipient = &Recipient
	|		AND SeriesTable.Manufactured
	|
	|	UNION ALL
	|
	|	SELECT
	|		SeriesTable.Ref            AS Ref,
	|		SeriesTable.Series             AS Series,
	|		SeriesTable.Products      AS Products,
	|		SeriesTable.Characteristic    AS Characteristic,
	|		SeriesTable.Recipient        AS Recipient,
	|		SeriesTable.Purpose        AS Purpose,
	|		SeriesTable.ProductionDate  AS ProductionDate,
	|		SeriesTable.Canceled          AS Canceled,
	|		SeriesTable.Department     AS Department,
	|		SeriesTable.Count        AS Count
	|	FROM
	|		Document.ProductionStage2_2.BatchSideAndIntermediateRelease AS SeriesTable
	|	WHERE
	|		SeriesTable.Ref IN (&ListOfOrders_)
	|		AND SeriesTable.Recipient = &Recipient
	|		AND SeriesTable.Manufactured
	|
	|	) AS SeriesTable
	|
	|GROUP BY
	|	SeriesTable.Ref,
	|	SeriesTable.Series,
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Recipient,
	|	SeriesTable.Purpose,
	|	SeriesTable.ProductionDate,
	|	SeriesTable.Canceled,
	|	SeriesTable.Department
	|
	|INDEX BY
	|	ReferenceOrder,
	|	Department,
	|	Recipient,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ProductionDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ProductItemTable.Ref                AS ReferenceOrder,
	|	ProductItemTable.RowCode             AS RowCode,
	|	ProductItemTable.Products          AS Products,
	|	ProductItemTable.Characteristic        AS Characteristic,
	|	ProductItemTable.Recipient            AS Recipient,
	|	ProductItemTable.Purpose            AS Purpose,
	|	ProductItemTable.ProductionDate      AS ProductionDate,
	|	ProductItemTable.Department         AS Department,
	|	SUM(ProductItemTable.Count)     AS Count
	|INTO ProductsOfStages
	|FROM
	|	(SELECT
	|		ProductItemTable.Ref            AS Ref,
	|		ProductItemTable.RowCode         AS RowCode,
	|		ProductItemTable.Products      AS Products,
	|		ProductItemTable.Characteristic    AS Characteristic,
	|		ProductItemTable.Recipient        AS Recipient,
	|		ProductItemTable.Purpose        AS Purpose,
	|		ProductItemTable.ProductionDate  AS ProductionDate,
	|		ProductItemTable.Department     AS Department,
	|		ProductItemTable.Count        AS Count
	|	FROM
	|		Document.ProductionStage2_2.ManufacturedProducts AS ProductItemTable
	|	WHERE
	|		(ProductItemTable.Ref,
	|		ProductItemTable.Department,
	|		ProductItemTable.Recipient,
	|		ProductItemTable.Products,
	|		ProductItemTable.Characteristic,
	|		ProductItemTable.Purpose,
	|		ProductItemTable.ProductionDate,
	|		ProductItemTable.Manufactured)
	|			IN(SELECT
	|				SeriesTable.ReferenceOrder,
	|				SeriesTable.Department,
	|				SeriesTable.Recipient,
	|				SeriesTable.Products,
	|				SeriesTable.Characteristic,
	|				SeriesTable.Purpose,
	|				SeriesTable.ProductionDate,
	|				TRUE
	|			FROM
	|				SeriesOfStages AS SeriesTable)
	|
	|	UNION ALL
	|
	|	SELECT
	|		ProductItemTable.Ref            AS Ref,
	|		ProductItemTable.RowCode         AS RowCode,
	|		ProductItemTable.Products      AS Products,
	|		ProductItemTable.Characteristic    AS Characteristic,
	|		ProductItemTable.Recipient        AS Recipient,
	|		ProductItemTable.Purpose        AS Purpose,
	|		ProductItemTable.ProductionDate  AS ProductionDate,
	|		ProductItemTable.Department     AS Department,
	|		ProductItemTable.Count        AS Count
	|	FROM
	|		Document.ProductionStage2_2.SideAndIntermediateRelease AS ProductItemTable
	|	WHERE
	|		(ProductItemTable.Ref,
	|		ProductItemTable.Department,
	|		ProductItemTable.Recipient,
	|		ProductItemTable.Products,
	|		ProductItemTable.Characteristic,
	|		ProductItemTable.Purpose,
	|		ProductItemTable.ProductionDate,
	|		ProductItemTable.Manufactured)
	|			IN(SELECT
	|				SeriesTable.ReferenceOrder,
	|				SeriesTable.Department,
	|				SeriesTable.Recipient,
	|				SeriesTable.Products,
	|				SeriesTable.Characteristic,
	|				SeriesTable.Purpose,
	|				SeriesTable.ProductionDate,
	|				TRUE
	|			FROM
	|				SeriesOfStages AS SeriesTable)
	|
	|	) AS ProductItemTable
	|
	|GROUP BY
	|	ProductItemTable.Ref,
	|	ProductItemTable.RowCode,
	|	ProductItemTable.Products,
	|	ProductItemTable.Characteristic,
	|	ProductItemTable.Recipient,
	|	ProductItemTable.Purpose,
	|	ProductItemTable.ProductionDate,
	|	ProductItemTable.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProductTable_.ReferenceOrder AS ReferenceOrder,
	|	ProductTable_.RowCode    AS RowCode
	|INTO ProductsOfStagesByLineCodes
	|FROM
	|	ProductsOfStages AS ProductTable_
	|
	|INDEX BY
	|	ReferenceOrder,
	|	RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ProductItemTable.Ref                AS Ref,
	|	ProductItemTable.ReferenceOrder          AS ReferenceOrder,
	|	ProductItemTable.RowCode             AS RowCode,
	|	ProductItemTable.Products          AS Products,
	|	ProductItemTable.Characteristic        AS Characteristic,
	|	ProductItemTable.Purpose            AS Purpose,
	|	ProductItemTable.AssignmentSender AS AssignmentSender,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	SUM(ProductItemTable.Count)     AS Count
	|INTO InvoiceProducts
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS ProductItemTable
	|WHERE
	|	NOT ProductItemTable.Ref = &Ref
	|	AND ProductItemTable.Ref.Posted
	|	AND ProductItemTable.Ref.BusinessOperation =
	|		VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|	AND (ProductItemTable.ReferenceOrder, ProductItemTable.RowCode)
	|		IN(SELECT
	|			ProductsOfStagesByLineCodes.ReferenceOrder AS ReferenceOrder,
	|			ProductsOfStagesByLineCodes.RowCode    AS RowCode
	|		FROM
	|			ProductsOfStagesByLineCodes AS ProductsOfStagesByLineCodes)
	|
	|GROUP BY
	|	ProductItemTable.Ref,
	|	ProductItemTable.ReferenceOrder,
	|	ProductItemTable.RowCode,
	|	ProductItemTable.Products,
	|	ProductItemTable.Characteristic,
	|	ProductItemTable.Purpose,
	|	ProductItemTable.AssignmentSender
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	AssignmentSender
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SeriesTable.Ref                AS Ref,
	|	SeriesTable.Series                 AS Series,
	|	SeriesTable.Products          AS Products,
	|	SeriesTable.Characteristic        AS Characteristic,
	|	SeriesTable.Purpose            AS Purpose,
	|	SeriesTable.AssignmentSender AS AssignmentSender,
	|	SUM(SeriesTable.Count)     AS Count
	|FROM
	|	Document.MovementOfProductsAndMaterials.SetOfSeries AS SeriesTable
	|WHERE
	|	(SeriesTable.Ref,
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.AssignmentSender)
	|		IN(SELECT
	|			InvoiceProducts.Ref                AS Ref,
	|			InvoiceProducts.Products          AS Products,
	|			InvoiceProducts.Characteristic        AS Characteristic,
	|			InvoiceProducts.Purpose            AS Purpose,
	|			InvoiceProducts.AssignmentSender AS AssignmentSender
	|		FROM
	|			InvoiceProducts AS InvoiceProducts)
	|
	|GROUP BY
	|	SeriesTable.Ref,
	|	SeriesTable.Series,
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.AssignmentSender
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductItemTable.ReferenceOrder      AS ReferenceOrder,
	|	ProductItemTable.RowCode         AS RowCode,
	|	SUM(ProductItemTable.Count) AS Count
	|INTO InvoiceItemsGroupedByLineCodes
	|FROM
	|	InvoiceProducts AS ProductItemTable
	|
	|GROUP BY
	|	ProductItemTable.ReferenceOrder,
	|	ProductItemTable.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsOfStages.ReferenceOrder          AS ReferenceOrder,
	|	ProductsOfStages.RowCode             AS RowCode,
	|	ProductsOfStages.Products          AS Products,
	|	ProductsOfStages.Characteristic        AS Characteristic,
	|	ProductsOfStages.Recipient            AS Recipient,
	|	ProductsOfStages.Purpose            AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	ProductsOfStages.ProductionDate      AS ProductionDate,
	|	ProductsOfStages.Department         AS Department,
	|	ProductsOfStages.Count - ISNULL(InvoiceProducts.Count, 0) AS Count
	|FROM
	|	ProductsOfStages AS ProductsOfStages
	|	
	|	LEFT JOIN InvoiceItemsGroupedByLineCodes AS InvoiceProducts
	|	ON InvoiceProducts.ReferenceOrder = ProductsOfStages.ReferenceOrder
	|	AND InvoiceProducts.RowCode = ProductsOfStages.RowCode
	|
	|WHERE
	|	ProductsOfStages.Count - ISNULL(InvoiceProducts.Count, 0) > 0
	|
	|ORDER BY
	|	ReferenceOrder,
	|	ProductionDate,
	|	RowCode
	|";
	
	If TypeOf(Object.Goods) = Type("FormDataCollection") Then
		ListOfOrders_ = TMCommonUse.DeleteDuplicateElementsFromArray(Object.Goods.Unload(, "ReferenceOrder").UnloadColumn("ReferenceOrder"));
	Else
		ListOfOrders_ = TMCommonUse.DeleteDuplicateElementsFromArray(Object.Goods.UnloadColumn("ReferenceOrder"));
	EndIf;
	
	Query.SetParameter("ListOfOrders_", ListOfOrders_);
	Query.SetParameter("Recipient",         Object.Recipient);
	Query.SetParameter("Ref",             Object.Ref);
	
	Result       = Query.ExecuteBatchWithIntermediateData();
	SeriesOfStages     = Result[0].Unload();
	GoodsFromInvoices = Result[3].Unload();
	SeriesOfInvoices  = Result[4].Unload();
	ProductsOfStages   = Result[6].Unload();
	
	// We distribute the Order in a series of invoices with verification of the availability of the series at the disposal.
	SeriesOfInvoicesForOrders = GoodsFromInvoices.CopyColumns("ReferenceOrder, Series, Count");
	
	KeyToFindingInvoiceSeries = "Ref, Products, Characteristic, Purpose, AssignmentSender";
	SeriesOfInvoices.Indexes.Add(KeyToFindingInvoiceSeries);
	
	SeriesOfStages.Indexes.Add("ReferenceOrder, Series");
	
	SelectionOfConsignmentNoteSeries = New Structure(KeyToFindingInvoiceSeries);
	SelectionOfSeriesCheck  = New Structure("ReferenceOrder, Series");
	
	For Each RowOfProduct In GoodsFromInvoices Do
		
		ProductQuantity_ = RowOfProduct.Count;
		
		FillPropertyValues(SelectionOfConsignmentNoteSeries, RowOfProduct);
		
		For Each RowSeries In SeriesOfInvoices.FindRows(SelectionOfConsignmentNoteSeries) Do
			
			If RowSeries.Count = 0 Then
				Continue;
			EndIf;
			
			SelectionOfSeriesCheck.ReferenceOrder = RowOfProduct.ReferenceOrder;
			SelectionOfSeriesCheck.Series        = RowSeries.Series;
			
			If SeriesOfStages.FindRows(SelectionOfSeriesCheck).Count() = 0 Then
				Continue;
			EndIf;
			
			NumberOfSeries_ = Min(RowSeries.Count, ProductQuantity_);
			
			NewRow = SeriesOfInvoicesForOrders.Add();
			NewRow.ReferenceOrder = RowOfProduct.ReferenceOrder;
			NewRow.Series        = RowSeries.Series;
			NewRow.Count   = NumberOfSeries_;
			
			ProductQuantity_       = ProductQuantity_ - NumberOfSeries_;
			RowSeries.Count = RowSeries.Count - NumberOfSeries_;
			
			If ProductQuantity_ = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// We reduce the number of stage series by previously designed series.
	SeriesReductionSelection = New Structure("ReferenceOrder, Series");
	
	For Each InvoiceBatch In SeriesOfInvoicesForOrders Do
		
		SeriesReductionSelection.ReferenceOrder = InvoiceBatch.ReferenceOrder;
		SeriesReductionSelection.Series        = InvoiceBatch.Series;
		
		QuantityToDeduct = InvoiceBatch.Count;
		
		For Each StageBatch In SeriesOfStages.FindRows(SeriesReductionSelection) Do
			
			If StageBatch.Count = 0 Then
				Continue;
			EndIf;
			
			NumberOfSeries_ = Min(QuantityToDeduct, StageBatch.Count);
			StageBatch.Count = StageBatch.Count - NumberOfSeries_;
			QuantityToDeduct     = QuantityToDeduct - NumberOfSeries_;
			
			If QuantityToDeduct = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// We distribute the remaining series to the remaining products.
	BalanceOfSeriesOfStages = ProductsOfStages.CopyColumns("ReferenceOrder, RowCode, Series, Count");
	
	SearchKey = "ReferenceOrder, Products, Characteristic, Recipient, Purpose, ProductionDate, Department";
	SeriesOfStages.Indexes.Add(SearchKey);
	Filter = New Structure(SearchKey);
	
	For Each RowOfProducts In ProductsOfStages Do
		
		ManufacturedProductQuantity = RowOfProducts.Count;
		
		If ManufacturedProductQuantity = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(Filter, RowOfProducts);
		
		For Each RowSeries In SeriesOfStages.FindRows(Filter) Do
			
			If RowSeries.Count = 0 Then
				Continue;
			EndIf;
			
			NumberOfSeries_ = Min(RowSeries.Count, ManufacturedProductQuantity);
			
			ProductLineIsNew = BalanceOfSeriesOfStages.Add();
			FillPropertyValues(ProductLineIsNew, RowOfProducts);
			
			ProductLineIsNew.Series      = RowSeries.Series;
			ProductLineIsNew.Count = NumberOfSeries_;
			
			ManufacturedProductQuantity      = ManufacturedProductQuantity - NumberOfSeries_;
			RowSeries.Count = RowSeries.Count - NumberOfSeries_;
			
			If ManufacturedProductQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Let's select a series of stages in the invoice.
	If TypeOf(Object.Goods) = Type("FormDataCollection") Then
		Rows = New Array;
		Rows.Add(Object.Goods[0]);
		ProductsNew = Object.Goods.Unload(Rows);
		ProductsNew.Clear();
	Else
		ProductsNew = Object.Goods.UnloadColumns();
	EndIf; 
	
	Object.SetOfSeries.Clear();
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.MovementOfProductsAndMaterials);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	CachedValues = Undefined;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	TheStructureOfTheSearch = New Structure("ReferenceOrder, RowCode");
	
	RowsToProcess = New Array;
	For Each RowGoods In Object.Goods Do
		
		RowProductNew = ProductsNew.Add();
		FillPropertyValues(RowProductNew, RowGoods);
		
		FirstRow = True;
		
		CountBalance = RowGoods.Count;
		
		FillPropertyValues(TheStructureOfTheSearch, RowGoods);
		For Each StringSeries In BalanceOfSeriesOfStages.FindRows(TheStructureOfTheSearch) Do
			
			If StringSeries.Count = 0 Then
				Continue;
			EndIf;
			
			NumberOfSeries_ = Min(StringSeries.Count, CountBalance);
			
			If RowGoods.BatchesIndicationStatus <> 0
				And ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(RowGoods.BatchesIndicationStatus, SeriesSpecificationParameters) Then
				
				If Not FirstRow Then
					RowProductNew = ProductsNew.Add();
					FillPropertyValues(RowProductNew, RowGoods);
				EndIf; 
				
				RowProductNew.Series = StringSeries.Series;
				RowProductNew.Count = NumberOfSeries_;
				
				RowsToProcess.Add(RowProductNew);
				
			Else
				
				NewSeries_ = Object.SetOfSeries.Add();
				FillPropertyValues(NewSeries_, RowGoods);
				NewSeries_.Series = StringSeries.Series;
				NewSeries_.Count = NumberOfSeries_;
				
			EndIf; 
			
			CountBalance = CountBalance - NumberOfSeries_;
			StringSeries.Count = StringSeries.Count - NumberOfSeries_;
			
			FirstRow = False;
			
			If CountBalance = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ProductsNew,
		CachedValues);
	
	Object.Goods.Load(ProductsNew);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure
#EndRegion

#Region QualityControl

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.MovementOfProductsAndMaterials - Object.
// 
// Returns:
//  Structure - structure with fields:
// * Key - String - An identifier used when there are two or more data sources to fill in in the same object.
// * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.FullObjectName = "Document.MovementOfProductsAndMaterials";
	ActionParameters.ReadableFields = "Products";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.Recipient);
	ActionParameters.QueryOptions.Insert("QualityControlBusinessTransaction", Object.BusinessOperation);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt =InvoicesServer.DateOfReceipt(
		Object.DateOfReceipt, Object.Date, True);
	
	ActionParameters.KeyDetailsOfHeader.Insert("QualityControlByOrder", Object.ByReferences);
	
	ActionParameters.QueryTextDocumentData =
	"SELECT
	|	Table.IdOfTTRow    AS IdOfTTRow,
	|	Table.Products             AS Products,
	|	&WarehouseQualityControl           AS Warehouse,
	|	UNDEFINED                     AS Contract,
	|	&QualityControlDateOfReceipt AS DateOfReceipt,
	|	FALSE                             AS Set,
	|	CASE
	|		WHEN &QualityControlBusinessTransaction IN(
	|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|				VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|				VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                            AS Reset
	|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
	|FROM
	|	#DataSource AS Table
	|INDEX BY
	|	Products,
	|	Warehouse,
	|	Contract
	|";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Command = Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	If Command <> Undefined Then
		
		ListForSettingVisibility = New Array();
		ListForSettingVisibility.Add(Enums.BusinessTransactions.MaterialTransferToProduction);
		ListForSettingVisibility.Add(Enums.BusinessTransactions.TransferOfMaterialsToStoreroom);
		AttachableCommands.AddCommandVisibilityCondition(Command,
		                                                    "BusinessOperation",
		                                                    ListForSettingVisibility,
		                                                    DataCompositionComparisonType.InList);
		
	EndIf;
	
	Command = Documents.PriceSetup.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		
		ListOfBusinessTransactions = New Array;
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.TransferOfProductsFromProduction);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.TransferOfProductsFromStoreroom);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.ReturnOfMaterialsFromProduction);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom);
		
		AttachableCommands.AddCommandVisibilityCondition(Command, "BusinessOperation", ListOfBusinessTransactions, DataCompositionComparisonType.InList);
		
	EndIf;
	
	Command = DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		
		ListOfBusinessTransactions = New Array();
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.TransferOfProductsFromProduction);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.TransferOfProductsFromStoreroom);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.ReturnOfMaterialsFromProduction);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProducts);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices);
		
		AttachableCommands.AddCommandVisibilityCondition(Command, "BusinessOperation", ListOfBusinessTransactions, DataCompositionComparisonType.InList);
		
	EndIf;
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	Command = Documents.GoodsQualityControlCertificate.AddGenerateCommand(GenerationCommands);
	
	ListForSettingVisibility = New Array();
	ListForSettingVisibility.Add(Enums.BusinessTransactions.TransferOfProductsFromStoreroom);
	ListForSettingVisibility.Add(Enums.BusinessTransactions.TransferOfMaterialsToStoreroom);
	ListForSettingVisibility.Add(Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom);
	ListForSettingVisibility.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProducts);
	ListForSettingVisibility.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices);
	
	If Command <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			ListForSettingVisibility,
			DataCompositionComparisonType.InList);
		
	EndIf;
	
	Command = Documents.RequestForGoodsQualityControl.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			ListForSettingVisibility,
			DataCompositionComparisonType.InList);
		
	EndIf;
	
	MovementOfProductsAndMaterialsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	MovementOfProductsAndMaterialsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

#Region PrintOutput
	
	BusinessTransactionList = New Array();
	BusinessTransactionList.Add(Enums.BusinessTransactions.TransferOfProductsFromProduction);
	BusinessTransactionList.Add(Enums.BusinessTransactions.TransferOfProductsFromStoreroom);
	
	If AccessRight("Read", Metadata.Documents.MovementOfProductsAndMaterials) Then
		
		// Production output
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "Invoice";
		PrintCommand.Presentation = NStr("vi = 'Xuất xưởng thành phẩm';
										|ru = 'Выпуск продукции';
										|en = 'Product release'; fa = 'تولید محصول';
										|it = 'Emissione di prodotti';
										|pl = 'Wyprodukowanie';
										|tr = 'Ürün sürümü'");
		PrintCommand.CheckPostingBeforePrint = True;
		
		AddConditionForVisibilityOfCommandForBusinessOperation(PrintCommand, BusinessTransactionList);
		
	EndIf;
	
#EndRegion

#Region PrintingTransferMaterials
	
	BusinessTransactionList = New Array();
	BusinessTransactionList.Add(Enums.BusinessTransactions.MaterialTransferToProduction);
	BusinessTransactionList.Add(Enums.BusinessTransactions.TransferOfMaterialsToStoreroom);
	
	If AccessRight("Update", Metadata.Documents.MovementOfProductsAndMaterials) Then
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "MaterialTransferToProduction";
		PrintCommand.Presentation = NStr("vi = 'Chuyển giao nguyên vật liệu vào sản xuất';
										|ru = 'Передача материалов в производство';
										|en = 'Transfer of materials to production'; fa = 'انتقال مواد به تولید';
										|it = 'Consegna materiali in produzione';
										|pl = 'Przekazanie materiałów do produkcji';
										|tr = 'Malzemelerin üretime aktarımı'");
		PrintCommand.CheckPostingBeforePrint = True;
		AddConditionForVisibilityOfCommandForBusinessOperation(PrintCommand, BusinessTransactionList);
	EndIf;

#EndRegion

#Region PrintingReturnMaterials
	
	BusinessTransactionList = New Array();
	BusinessTransactionList.Add(Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom);
	BusinessTransactionList.Add(Enums.BusinessTransactions.ReturnOfMaterialsFromProduction);
	// Registering goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ReturnInvoice";
	PrintCommand.Presentation = NStr("vi = 'Trả lại từ sản xuất';
									|ru = 'Возврат из производства';
									|en = 'Return from production'; fa = 'برگشت از تولید';
									|it = 'Reso dalla produzione';
									|pl = 'Zwrot z produkcji';
									|tr = 'Üretimden iade'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	AddConditionForVisibilityOfCommandForBusinessOperation(PrintCommand, BusinessTransactionList);
	
#EndRegion

#Region PrintingMovingSemiFinishedProducts
	
	BusinessTransactionList = New Array();
	BusinessTransactionList.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProducts);
	BusinessTransactionList.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices);
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "TransferNote";
	PrintCommand.Presentation = NStr("vi = 'Phiếu điều chuyển hàng hóa';
									|ru = 'Накладная на перемещение';
									|en = 'Goods transfer'; fa = 'انتقال کالا';
									|it = 'Bolla per trasferimento';
									|pl = 'Faktura na przemieszczenie';
									|tr = 'Taşıma senedi'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	AddConditionForVisibilityOfCommandForBusinessOperation(PrintCommand, BusinessTransactionList);
	
#EndRegion

#Region GoodsPickingPlacementJob
	
	// Task for the selection of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(
		PrintCommands,
		"SelectionTask");
	
	BusinessTransactionList = New Array();
	BusinessTransactionList.Add(Enums.BusinessTransactions.MaterialTransferToProduction);
	BusinessTransactionList.Add(Enums.BusinessTransactions.TransferOfMaterialsToStoreroom);
	BusinessTransactionList.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProducts);
	BusinessTransactionList.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices);
	
	AddConditionForVisibilityOfCommandForBusinessOperation(PrintCommand, BusinessTransactionList);
	
	// Assignment for the placement of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(
		PrintCommands,
		"PlacementJob");
	
	BusinessTransactionList = New Array();
	BusinessTransactionList.Add(Enums.BusinessTransactions.TransferOfProductsFromProduction);
	BusinessTransactionList.Add(Enums.BusinessTransactions.TransferOfProductsFromStoreroom);
	BusinessTransactionList.Add(Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom);
	BusinessTransactionList.Add(Enums.BusinessTransactions.ReturnOfMaterialsFromProduction);
	BusinessTransactionList.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProducts);
	BusinessTransactionList.Add(Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices);
	
	AddConditionForVisibilityOfCommandForBusinessOperation(PrintCommand, BusinessTransactionList);
	
#EndRegion

	MovementOfProductsAndMaterialsLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Adds a command to create an object based on.
// 
// Parameters:
// 	CreateCommandsBasedOn - ValueTable - list of commands
// 	Multiple Choice - Boolean - Multiple Choice
// Returns:
// 	Undefined, ValueTableRow - added command.
//
Function AddCreateProductTransferToWarehouseCommandBasedOn(CreateCommandsBasedOn) Export
	
	If AccessRight("Insert", Metadata.Documents.MovementOfProductsAndMaterials) Then
		
		TransactionList = TransactionList();
		Operation = TransactionList.FindByValue(Enums.BusinessTransactions.TransferOfProductsFromStoreroom);
		
		If Operation <> Undefined Then
			
			CreateBasedOnCommand = CreateCommandsBasedOn.Add();
			CreateBasedOnCommand.Manager = Metadata.Documents.MovementOfProductsAndMaterials.FullName();
			CreateBasedOnCommand.Presentation = NStr("vi = 'Chuyển sản phẩm sản xuất vào kho';
													|ru = 'Передача выпущенной продукции на склад';
													|en = 'Transfer released products to warehouse'; fa = 'Transfer released products to warehouse';
													|it = 'Consegna dei prodotti emessi al magazzino';
													|pl = 'Przekazanie wypuszczonej produkcji do magazynu';
													|tr = 'İmal edilen ürünlerin ambara transferi'");
			CreateBasedOnCommand.Handler = "ProductionClient.CreateTransferOfProductsFromPantryBasedOn";
			CreateBasedOnCommand.WriteMode = "Post";
			CreateBasedOnCommand.FunctionalOptions = "UseProductionManagement2_2";
			CreateBasedOnCommand.MultipleChoice = True;
			
			Return CreateBasedOnCommand;
			
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds the command to create the document "Transfer of manufactured products to the warehouse".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateSecuringOrderCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.MovementOfProductsAndMaterials) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.MovementOfProductsAndMaterials.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateSecuringOrder";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Chuyển giao thành phẩm xuất xưởng vào kho';
												|ru = 'Передача выпущенной продукции на склад';
												|en = 'Transfer released products to warehouse'; fa = 'Transfer released products to warehouse';
												|it = 'Consegna dei prodotti emessi al magazzino';
												|pl = 'Przekazanie wypuszczonej produkcji do magazynu';
												|tr = 'İmal edilen ürünlerin ambara transferi'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProductionManagement2_2";
		CreationParameters = ProvisionInDocumentsServer.ParametersForCreatingSecuringOrder(
			CreateBasedOnCommand.AdditionalParameters);
		CreationParameters.NameOfDocumentManager = "MovementOfProductsAndMaterials";
		CreationParameters.FormName = "Document.MovementOfProductsAndMaterials.ObjectForm";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Creation parameters based on the providing order.
// Returns:
// See ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder
Function CreationParametersBasedOnProvidingOrder() Export
	
	ProductTableParameters = ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder();
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	ProductTableParameters.OneWarehouse = True;
	Return ProductTableParameters;
	
EndFunction

// Adds a command to create a document
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
// 	Undefined, ValueTableRow - description of the added command
//
Function AddCommandCreateTransferToPantryBasedOnOrder(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.MovementOfProductsAndMaterials)
		And TransactionList().FindByValue(Enums.BusinessTransactions.TransferOfMaterialsToStoreroom) <> Undefined Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.MovementOfProductsAndMaterialsCreateTransferToPantryBasedOnOrder";
		CreateBasedOnCommand.Manager = Metadata.Documents.MovementOfProductsAndMaterials.FullName();
		CreateBasedOnCommand.Presentation = NStr("vi = 'Chuyển nguyên vật liệu vào kho tại xưởng';
												|ru = 'Передача материалов в кладовую';
												|en = 'Transfer of materials to storeroom'; fa = 'Transfer of materials to storeroom';
												|it = 'Consegna dei materiali al deposito';
												|pl = 'Przekazanie materiałów do komórki';
												|tr = 'Malzemelerin ambara transferi'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		CreateBasedOnCommand.FunctionalOptions = "UseProductionManagement2_2";
			
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command to create a document "Transfer of manufactured products".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
// 	Undefined, ValueTableRow - description of the added command
//
Function AddCreateTransferFromProductionBasedOnOrderCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.MovementOfProductsAndMaterials)
		And TransactionList().FindByValue(Enums.BusinessTransactions.TransferOfProductsFromProduction) <> Undefined Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.MovementOfProductsAndMaterialsCreateTransferOutOfProductionBasedOnOrder";
		CreateBasedOnCommand.Manager = Metadata.Documents.MovementOfProductsAndMaterials.FullName();
		CreateBasedOnCommand.Presentation = NStr("vi = 'Chuyển sản phẩm';
												|ru = 'Передача выпущенной продукции';
												|en = 'Transfer released products'; fa = 'Transfer released products';
												|it = 'Consegna dei prodotti emessi';
												|pl = 'Przekazanie wypuszczonej produkcji';
												|tr = 'İmal edilen ürünlerin transferi'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		CreateBasedOnCommand.FunctionalOptions = "UseProductionManagement2_2";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command to create a document
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
// 	Undefined, ValueTableRow - description of the added command
//
Function AddCommandCreateTransferToProductionBasedOnOrder(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.MovementOfProductsAndMaterials)
		And TransactionList().FindByValue(Enums.BusinessTransactions.MaterialTransferToProduction) <> Undefined Then
	
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.MovementOfProductsAndMaterialsCreateTransferToProductionBasedOnOrder";
		CreateBasedOnCommand.Manager = Metadata.Documents.MovementOfProductsAndMaterials.FullName();
		CreateBasedOnCommand.Presentation = NStr("vi = 'Chuyển giao nguyên vật liệu vào sản xuất';
												|ru = 'Передача материалов в производство';
												|en = 'Transfer of materials to production'; fa = 'انتقال مواد به تولید';
												|it = 'Consegna materiali in produzione';
												|pl = 'Przekazanie materiałów do produkcji';
												|tr = 'Malzemelerin üretime aktarımı'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		CreateBasedOnCommand.FunctionalOptions = "UseProductionManagement2_2";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command to create a document
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
// 	Undefined, ValueTableRow - description of the added command
//
Function AddCreateRefundFromProductionBasedOnOrderCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.MovementOfProductsAndMaterials)
		And TransactionList().FindByValue(Enums.BusinessTransactions.ReturnOfMaterialsFromProduction) <> Undefined Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.MovementOfProductsAndMaterialsCreateReturnFromProductionBasedOnOrder";
		CreateBasedOnCommand.Manager = Metadata.Documents.MovementOfProductsAndMaterials.FullName();
		CreateBasedOnCommand.Presentation = NStr("vi = 'Hoàn trả nguyên liệu từ sản xuất';
												|ru = 'Возврат материалов из производства';
												|en = 'Return materials from production'; fa = 'برگشت مواد از تولید';
												|it = 'Reso dei materiali dalla produzione';
												|pl = 'Zwrot materiałów z produkcji';
												|tr = 'Malzemelerin üretimden iadesi'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		CreateBasedOnCommand.FunctionalOptions = "UseProductionManagement2_2";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

#EndRegion

#Region Other

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.MovementOfProductsAndMaterials, DocumentRef.MovementOfProductsAndMaterials - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
//
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Ref,
		|Date,
		|DateOfReceipt,
		|Number,
		|Sender,
		|BusinessOperation,
		|LineOfBusiness,
		|Organization,
		|CompanyRecipient,
		|Patch,
		|CorrectedDocument");
	
	If ObjectAttributes.Ref <> Undefined And ObjectAttributes.Patch Then
		Attributes = AttributesOfControlledLotReference(ObjectAttributes.CorrectedDocument, FieldNameControlledLotReference);
		Return Attributes;
	EndIf;
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.DateOfReceipt = InvoicesServer.DateOfReceipt(ObjectAttributes.DateOfReceipt, ObjectAttributes.Date);
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = ObjectAttributes.Date;
	If Attributes.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
		Attributes.Organization = ObjectAttributes.CompanyRecipient;
	Else
		Attributes.Organization = ObjectAttributes.Organization;
	EndIf;
	Attributes.Department = Catalogs.BusinessStructure.EmptyRef();
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.Sender = ObjectAttributes.Sender;
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	If ObjectAttributes.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
		Attributes.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
	EndIf;
	Return Attributes;
	
EndFunction

Procedure AddConditionForVisibilityOfCommandForBusinessOperation(Command, List) Export
	
	If Command <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(Command, "BusinessOperation",
			List, DataCompositionComparisonType.InList);
		
	EndIf;
	
EndProcedure

// Returns a table of used document statuses depending on functional options and other parameters.
//
// Returns:
//  See TMCommonUse.TableOfStatusesToChangeFromList
//
Function DocumentStatusesThatCanBeChangedFromList() Export
		
	Table = TMCommonUse.TableOfStatusesToChangeFromList();
	
	TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfProductsAndMaterialMovement.Shipped);
	TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfProductsAndMaterialMovement.Accepted);
	
	Return Table;
	
EndFunction

// Returns the request text for writing data to the data register of internal Documents.
//
//	Returns:
//		String - Query text
//
Function QueryTextInternalDocumentData() Export
	
	QueryText = 
	"SELECT
	|	DocumentTable.Ref,
	|	DocumentTable.Number,
	|	DocumentTable.Date,
	|	DocumentTable.Organization,
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
	|			OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom)
	|		THEN DocumentTable.Sender
	|		ELSE DocumentTable.Recipient
	|	END AS Warehouse,
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
	|			OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom)
	|		THEN DocumentTable.Recipient
	|		ELSE DocumentTable.Sender
	|	END AS Department,
	|	DocumentTable.EmployeeResponsible,
	|	DocumentTable.Comment,
	|	"""" AS More,
	|	DocumentTable.BusinessOperation,
	|	DocumentTable.Status,
	|	DocumentTable.Posted,
	|	DocumentTable.DeletionMark
	|FROM
	|	Document.MovementOfProductsAndMaterials AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref";
	
	Return QueryText;
	
EndFunction

// Fills in the table of details that depend on the business transaction
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - economic operation
//	ArrayOfAllProps - Array - Bank details that do not depend on the business transaction
//	ArrayOfOperationDetails - Array - Bank details that depend on the business transaction.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("CompanyRecipient");
	ArrayOfAllProps.Add("Goods.ProductsGroup");
	ArrayOfAllProps.Add("Goods.Price");
	ArrayOfAllProps.Add("Goods.Sum");
	ArrayOfAllProps.Add("Goods.ToControlQuality");
	ArrayOfAllProps.Add("Goods.QualityConfirmationDate");
	
	ArrayOfOperationDetails = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.Sum");
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
		ArrayOfOperationDetails.Add("Goods.ToControlQuality");
		ArrayOfOperationDetails.Add("Goods.QualityConfirmationDate");
	ElsIf BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction Then
		ArrayOfOperationDetails.Add("Goods.ProductsGroup");
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		ArrayOfOperationDetails.Add("Goods.ProductsGroup");
		ArrayOfOperationDetails.Add("Goods.ToControlQuality");
		ArrayOfOperationDetails.Add("Goods.QualityConfirmationDate");
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
		ArrayOfOperationDetails.Add("CompanyRecipient");
		ArrayOfOperationDetails.Add("Goods.ProductsGroup");
		ArrayOfOperationDetails.Add("Goods.ToControlQuality");
		ArrayOfOperationDetails.Add("Goods.QualityConfirmationDate");
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom Then
		ArrayOfOperationDetails.Add("Goods.ProductsGroup");
		ArrayOfOperationDetails.Add("Goods.ToControlQuality");
		ArrayOfOperationDetails.Add("Goods.QualityConfirmationDate");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
		ArrayOfOperationDetails.Add("Goods.ProductsGroup");
	EndIf;
	
EndProcedure

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Goods");
	
	Return DocumentTables;
	
EndFunction

#EndRegion

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object		- DocumentObject.MovementOfProductsAndMaterials, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Date								= Object.Date;
	FillParameters.Warehouse								= Object.Recipient;
	FillParameters.LineOfBusiness				= Object.LineOfBusiness;
	FillParameters.MovementOfGoodsAndWorksInProduction	= True;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
		FillParameters.Organization = Object.CompanyRecipient;
	Else
		FillParameters.Organization = Object.Organization;
	EndIf;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region PrintJobsForInventoryPickingPlacementAndRecount

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Array of See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	PrintRules = New Array;
	
	// Consumption of goods
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.WarehouseFieldName = "Sender";
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
	
	PrintRules.Add(JobPrintingRules);
	
	// The arrival of the goods
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation = True;
	JobPrintingRules.WarehouseFieldName = "Recipient";
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
	
	PrintRules.Add(JobPrintingRules);
	
	Return PrintRules;
	
EndFunction

#EndRegion

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway21));
	DestinationPattern.VisibleSelectionsOnForm.Insert("LineOfBusiness", NStr("vi = 'Chỉ đến ""%1""';
																			|ru = 'Только назначения направления деятельности ""%1""';
																			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
																			|it = 'Solo assegnazioni del settore di attività ""%1""';
																			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
																			|tr = 'Sadece ""%1"" iş kolunun atamaları'"));
	
	// Remnants of goods in the sender warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "Sender");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.BusinessOperation IN(
		|VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
		|VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom),
		|VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom),
		|VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
		|VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices))";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Sender";
	
	// Needs for goods in the receiving warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "Recipient");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.BusinessOperation IN(
		|VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
		|VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
		|VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
		|VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom),
		|VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
		|VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices))";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Recipient";
	
	// Needs for goods in the receiving warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.Goods.Purpose", "AllWarehouses");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.BusinessOperation IN(
		|VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
		|VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
		|VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
		|VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom),
		|VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
		|VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices))";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	
	Return FormTemplate;
	
EndFunction

#Region InterfaceImplementation

// To use in the procedure add a create command Based on other object Manager modules.
// Adds this object to the list of base creation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - description of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.MovementOfProductsAndMaterials);
	
EndFunction

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND( ValueAllowed(Sender)
	|	OR ValueAllowed(Recipient))
	|	AND ValueAllowed(BusinessOperation)
	|	AND ValueAllowed(Status)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion
#Region Excisable_Items

// Returns an indication of the use of excisable items of own production in the document.
//
// Parameters:
//	DocumentObject - DocumentObject.MovementOfProductsAndMaterials, FormDataStructure - Document data.
//
// Returns:
//	Boolean - excisable items of own production are used.
//
Function ExcisableGoodsAreUsed(DocumentObject) Export
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Return False;
	EndIf;
	
	Return DocumentObject.BusinessOperation <> Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices;
	
EndFunction

#EndRegion
#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If ValueIsFilled(Data.BusinessOperation) Then

		PresentationOperation = TransactionList().FindByValue(Data.BusinessOperation);
		If PresentationOperation <> Undefined Then
			PresentationOperation = PresentationOperation.Presentation;
		Else
			PresentationOperation = Data.BusinessOperation;
		EndIf;
		
		StandardProcessing = False;
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 %2 ngày %3';
				|ru = '%1 %2 от %3';
				|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
				|it = '%1 %2 del %3';
				|pl = '%1 %2 z dnia %3';
				|tr = '%3 tarihli %1 %2'"),
			PresentationOperation,
			Data.Number,
			Data.Date);
		
	EndIf;
		
EndProcedure

#EndRegion

#Region Other

Function TransactionList() Export
	
	TransactionList = New ValueList;
	
	TransferOfSemiFinishedProducts               = PredefinedValue("Enum.BusinessTransactions.TransferOfSemiFinishedProducts");
	TransferOfSemiFinishedProductsBetweenBranchOffices = PredefinedValue("Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices");
	
	TransferOfProductsFromStoreroom     = PredefinedValue("Enum.BusinessTransactions.TransferOfProductsFromStoreroom");
	TransferOfMaterialsToStoreroom     = PredefinedValue("Enum.BusinessTransactions.TransferOfMaterialsToStoreroom");
	ReturnOfMaterialsFromStoreroom     = PredefinedValue("Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom");
	TransferOfProductsFromProduction = PredefinedValue("Enum.BusinessTransactions.TransferOfProductsFromProduction");
	MaterialTransferToProduction = PredefinedValue("Enum.BusinessTransactions.MaterialTransferToProduction");
	ReturnOfMaterialsFromProduction = PredefinedValue("Enum.BusinessTransactions.ReturnOfMaterialsFromProduction");
	
	TransactionList.Add(TransferOfProductsFromProduction, NStr("vi = 'Chuyển hàng hóa từ sản xuất';
																|ru = 'Передача продукции из производства';
																|en = 'Transfer of products from production'; fa = 'Transfer of products from production';
																|it = 'Consegna dei prodotti dalla produzione';
																|pl = 'Przekazanie produkcji z produkcji';
																|tr = 'İmal edilen ürünlerin üretimden transferi'"));
	TransactionList.Add(MaterialTransferToProduction, NStr("vi = 'Chuyển giao nguyên vật liệu vào sản xuất';
															|ru = 'Передача материалов в производство';
															|en = 'Transfer of materials to production'; fa = 'انتقال مواد به تولید';
															|it = 'Consegna materiali in produzione';
															|pl = 'Przekazanie materiałów do produkcji';
															|tr = 'Malzemelerin üretime aktarımı'"));
	TransactionList.Add(ReturnOfMaterialsFromProduction, NStr("vi = 'Hoàn trả nguyên liệu từ sản xuất';
																|ru = 'Возврат материалов из производства';
																|en = 'Return of materials from production'; fa = 'Return of materials from production';
																|it = 'Reso dei materiali dalla produzione';
																|pl = 'Zwrot materiałów z produkcji';
																|tr = 'Malzemelerin üretimden iadesi'"));
	If GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		TransactionList.Add(TransferOfSemiFinishedProductsBetweenBranchOffices, NStr("vi = 'Điều chuyển bán thành phẩm giữa các chi nhánh';
																					|ru = 'Перемещение полуфабрикатов между филиалами';
																					|en = 'Transfer of semi-finished products between branch offices'; fa = 'انتقال محصولات نیمه‌ساخته بین شعب';
																					|it = 'Trasferimento dei prodotti semilavorati tra le società affiliate';
																					|pl = 'Przemieszczenie półproduktów pomiędzy filiami';
																					|tr = 'Şubeler arası yarı mamul ürünlerin transferi'"));
	EndIf;
	
	If GetFunctionalOption("UseSeveralWarehouses") Then
		
		TransactionList.Add(TransferOfProductsFromStoreroom, NStr("vi = 'Chuyển hàng hóa từ kho tại xưởng';
																	|ru = 'Передача продукции из кладовой';
																	|en = 'Transfer of products from shop floor stockroom'; fa = 'Transfer of products from shop floor stockroom';
																	|it = 'Consegna dei prodotti dal deposito';
																	|pl = 'Przekazanie produkcji z komórki';
																	|tr = 'İmal edilen ürünlerin ambardan transferi'"));
		TransactionList.Add(TransferOfMaterialsToStoreroom, NStr("vi = 'Chuyển nguyên vật liệu vào kho tại xưởng';
																|ru = 'Передача материалов в кладовую';
																|en = 'Transfer of materials to shop floor stockroom'; fa = 'Transfer of materials to shop floor stockroom';
																|it = 'Consegna dei materiali al deposito';
																|pl = 'Przekazanie materiałów do komórki';
																|tr = 'Malzemelerin ambara transferi'"));
		TransactionList.Add(ReturnOfMaterialsFromStoreroom, NStr("vi = 'Trả lại nguyên vật liệu từ kho';
																|ru = 'Возврат материалов из кладовой';
																|en = 'Return of materials from storeroom'; fa = 'Return of materials from storeroom';
																|it = 'Reso di materiali dal deposito';
																|pl = 'Zwrot materiałów z komórki';
																|tr = 'Malzemelerin ambardan iadesi'"));
		TransactionList.Add(TransferOfSemiFinishedProducts,   NStr("vi = 'Điều chuyển bán thành phẩm';
																	|ru = 'Перемещение полуфабрикатов';
																	|en = 'Transfer of semi-finished products'; fa = 'انتقال محصولات نیمه‌ساخته';
																	|it = 'Trasferimento dei prodotti semilavorati';
																	|pl = 'Przemieszczenie półproduktów';
																	|tr = 'Yarı mamul ürün transferi'"));
		
	EndIf;
	
	AvailableBusinessTransactions = GeneralPurposeTMServerCall.AvailableBusinessTransactions("Document.MovementOfProductsAndMaterials");
	
	If AvailableBusinessTransactions <> Undefined Then
		
		IndexOf = TransactionList.Count()-1;
		
		While IndexOf >= 0 Do
			
			If AvailableBusinessTransactions.Find(TransactionList[IndexOf].Value) = Undefined Then
				TransactionList.Delete(IndexOf);
			EndIf;
			
			IndexOf = IndexOf -1;
			
		EndDo;
		
	EndIf;
	
	Return TransactionList;
	
EndFunction

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.MovementOfProductsAndMaterials";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",           """""");
	RedefiningParameterCalculation.Insert("RecipientInformation",  """""");
	RedefiningParameterCalculation.Insert("SenderInformation", """""");
	RedefiningParameterCalculation.Insert("SenderOrderScheme",
		"	CASE
		|		WHEN VALUETYPE(GoodsTable.Ref.Sender) = TYPE(Catalog.Warehouses)
		|				AND CAST(GoodsTable.Ref.Sender AS Catalog.Warehouses).UseWarehouseManagemantSystemForGoodsIssue
		|				AND GoodsTable.Ref.Date >= CAST(GoodsTable.Ref.Sender AS Catalog.Warehouses).StartDateOfWarehouseManagemantSystemForGoodsIssue
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	RedefiningParameterCalculation.Insert("RecipientOrderScheme",
		"	CASE
		|		WHEN VALUETYPE(GoodsTable.Ref.Recipient) = TYPE(Catalog.Warehouses)
		|				AND CAST(GoodsTable.Ref.Recipient AS Catalog.Warehouses).UseWarehouseManagemantSystemForGoodsReceipt
		|				AND GoodsTable.Ref.Date >= CAST(GoodsTable.Ref.Recipient AS Catalog.Warehouses).StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	RedefiningParameterCalculation.Insert("WarehouseOperation", 
		"	CASE
		|		WHEN GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|			OR GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom)
		|			THEN VALUE(Enum.WarehouseTransactions.ProductReceivingFromManufacturing)
		|		WHEN GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
		|			OR GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom)
		|			THEN VALUE(Enum.WarehouseTransactions.TransferToProductionShipment)
		|		WHEN GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts)
		|			OR GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
		|			THEN VALUE(Enum.WarehouseTransactions.ProductionTransferShipment)
		|		WHEN GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction)
		|			OR GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom)
		|			THEN VALUE(Enum.WarehouseTransactions.ReturnMaterialsFromProductionReceiving)
		|	END");
	RedefiningParameterCalculation.Insert("EnteringPantry",
		"ISNULL(CAST(GoodsTable.Ref.Recipient AS Catalog.Warehouses).ShopFloorStockroom, FALSE)");
	RedefiningParameterCalculation.Insert("TransferFromPantry",
		"ISNULL(CAST(GoodsTable.Ref.Sender AS Catalog.Warehouses).ShopFloorStockroom, FALSE)");
	RedefiningParameterCalculation.Insert("RecipientSDivision",
		"	CASE
		|		WHEN VALUETYPE(GoodsTable.Ref.Recipient) = TYPE(Catalog.Warehouses)
		|			THEN ISNULL(CAST(GoodsTable.Ref.Recipient AS Catalog.Warehouses).Department, VALUE(Catalog.BusinessStructure.EmptyRef))
		|		ELSE GoodsTable.Ref.Recipient
		|	END");
	RedefiningParameterCalculation.Insert("SenderSDivision",
		"	CASE
		|		WHEN VALUETYPE(GoodsTable.Ref.Sender) = TYPE(Catalog.Warehouses)
		|			THEN ISNULL(CAST(GoodsTable.Ref.Sender AS Catalog.Warehouses).Department, VALUE(Catalog.BusinessStructure.EmptyRef))
		|		ELSE GoodsTable.Ref.Sender
		|	END");
	RedefiningParameterCalculation.Insert("InvoiceIsOrder",
		"GoodsTable.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)");
	
	If RegisterName = "GoodsBatchMovement" Then
		
		QueryText = QueryTextTableGoodsBatchMovement(Undefined, QueryTexts, Undefined);
		SynonymForDocumentTable = "GoodsTable";
	ElsIf RegisterName = "ReferencesToTransferFromProduction" Then
		
		QueryText = QueryTextTableReferencesToTransferFromProduction(Undefined, QueryTexts, Undefined);
		SynonymForDocumentTable = "TabularSection";
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Undefined, QueryTexts, Undefined);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Undefined, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydına göre hareketlerin düzenlenmesi talebinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If SynonymForDocumentTable <> "GoodsTable" Then
		For Each CalculationParameter In RedefiningParameterCalculation Do
			RedefiningParameterCalculation[CalculationParameter.Key] = StrReplace(
				CalculationParameter.Value, "GoodsTable", SynonymForDocumentTable);
		EndDo;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
		"SELECT
		|	Table.Date                           AS Period,
		|	Table.Organization                    AS Organization,
		|	Table.InternalSubcontracting          AS InternalSubcontracting,
		|	Table.MaterialProviderCompany             AS MaterialProviderCompany,
		|	Table.CompanyRecipient          AS CompanyRecipient,
		|	Table.Sender                    AS Sender,
		|	Table.Recipient                     AS Recipient,
		|	Table.ControlledLotReference           AS ControlledLotReference,
		|	Table.Recipient.Presentation       AS RecipientPresentation,
		|	Table.Sender.Presentation      AS SenderPresentation,
		|	Table.EmployeeResponsible                  AS EmployeeResponsible,
		|	Table.Author                          AS Author,
		|	Table.Comment                    AS Comment,
		|	Table.DeletionMark                AS DeletionMark,
		|	Table.Patch                    AS Patch,
		|	Table.ReversedDocument           AS ReversedDocument,
		|	Table.CorrectedDocument           AS CorrectedDocument,
		|	Table.Posted                       AS Posted,
		|	Table.Number                          AS Number,
		|	ISNULL(CAST(Table.Recipient AS Catalog.Warehouses).ShopFloorStockroom, FALSE)  AS EnteringPantry,
		|	ISNULL(CAST(Table.Sender AS Catalog.Warehouses).ShopFloorStockroom, FALSE) AS TransferFromPantry,
		|	CASE
		|		WHEN VALUETYPE(Table.Recipient) = TYPE(Catalog.Warehouses)
		|			THEN CAST(Table.Recipient AS Catalog.Warehouses).Department
		|		ELSE Table.Recipient
		|	END                                  AS RecipientSDivision,
		|	CASE
		|		WHEN VALUETYPE(Table.Sender) = TYPE(Catalog.Warehouses)
		|			THEN CAST(Table.Sender AS Catalog.Warehouses).Department
		|		ELSE Table.Sender
		|	END                                  AS SenderSDivision,
		|	CASE
		|		WHEN VALUETYPE(Table.Sender) = TYPE(Catalog.Warehouses)
		|			THEN CAST(Table.Sender AS Catalog.Warehouses).Department.OptionOfAssignedAccountingOfGoods
		|		ELSE Table.Sender.OptionOfAssignedAccountingOfGoods
		|	END                                  AS OptionOfAssignedAccountingOfGoods,
		|	Table.Ref                         AS Ref,
		|	Table.Status                         AS Status,
		|	Table.BusinessOperation          AS BusinessOperation,
		|	Table.ReferenceOrder                   AS ReferenceOrder,
		|	Table.ByReferences                AS ByReferences,
		|	Table.VATTaxation             AS VATTaxation,
		|	CASE
		|		WHEN VALUETYPE(Table.Sender) = TYPE(Catalog.Warehouses)
		|				AND CAST(Table.Sender AS Catalog.Warehouses).UseWarehouseManagemantSystemForGoodsIssue
		|				AND Table.Date >= CAST(Table.Sender AS Catalog.Warehouses).StartDateOfWarehouseManagemantSystemForGoodsIssue
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                  AS SenderOrderScheme,
		|	CASE
		|		WHEN VALUETYPE(Table.Recipient) = TYPE(Catalog.Warehouses)
		|				AND CAST(Table.Recipient AS Catalog.Warehouses).UseWarehouseManagemantSystemForGoodsReceipt
		|				AND Table.Date >= CAST(Table.Recipient AS Catalog.Warehouses).StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                  AS RecipientOrderScheme,
		|	CASE
		|		WHEN Table.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|			OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom)
		|			THEN VALUE(Enum.WarehouseTransactions.ProductReceivingFromManufacturing)
		|		WHEN Table.BusinessOperation = VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
		|			OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom)
		|			THEN VALUE(Enum.WarehouseTransactions.TransferToProductionShipment)
		|		WHEN Table.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts)
		|			OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
		|			THEN VALUE(Enum.WarehouseTransactions.ProductionTransferShipment)
		|		WHEN Table.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction)
		|			OR Table.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom)
		|			THEN VALUE(Enum.WarehouseTransactions.ReturnMaterialsFromProductionReceiving)
		|	END                                  AS WarehouseOperation,
		|	Table.ByGoodsForRegistrationInReportsToConsignor AS ByGoodsForRegistrationInReportsToConsignor,
		|	Table.GoodsReceiptOption AS GoodsReceiptOption,
		|	Table.CorrectedDocument.Date AS AdjustmentPeriod_
		|FROM
		|	Document.MovementOfProductsAndMaterials AS Table
		|WHERE
		|	Table.Ref = &Ref";

	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	InvoiceIsOrder = PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(Attributes.GoodsReceiptOption);
	
	Query.SetParameter("Currency", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("InvoiceIsOrder", InvoiceIsOrder);
	Query.SetParameter("AnalyticalAccountingByProductsGroups", GetFunctionalOption("AnalyticalAccountingByProductsGroups"));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID("Document.MovementOfProductsAndMaterials"));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure InitializeProductAnalysisKeys(Query)

	If Query = Undefined Or Query.Parameters.Property("ProductAnalysisKeysInitialized") Then
		Return;
	EndIf;

	QueryText =
	"SELECT DISTINCT
	|	Table.Products         AS Products,
	|	Table.Characteristic       AS Characteristic,
	|	Table.Purpose           AS Purpose,
	|	Table.Series                AS Series,
	|	Table.Warehouse                AS Warehouse
	|FROM
	|	(SELECT DISTINCT
	|		&Recipient                                                  AS Warehouse,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products   AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		TableTypesOfStocks_.AssignmentRecipient                      AS Purpose,
	|		TableTypesOfStocks_.Series                                     AS Series
	|	FROM
	|		Document.MovementOfProductsAndMaterials.InventoryKinds AS TableTypesOfStocks_
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Keys
	|			ON TableTypesOfStocks_.ItemsLocationAttributes.Products = Keys.Products
	|				AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = Keys.Characteristic
	|				AND TableTypesOfStocks_.Series = Keys.Series
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Keys.ProductCostElement
	|				AND TableTypesOfStocks_.AssignmentRecipient = Keys.Purpose
	|				AND &Recipient = Keys.StorageLocation
	|	WHERE
	|		Keys.Products IS NULL
	|		AND TableTypesOfStocks_.Ref = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		&Recipient                                                  AS Warehouse,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products   AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)                 AS Purpose,
	|		TableTypesOfStocks_.Series                                     AS Series
	|	FROM
	|		Document.MovementOfProductsAndMaterials.InventoryKinds AS TableTypesOfStocks_
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Keys
	|			ON TableTypesOfStocks_.ItemsLocationAttributes.Products = Keys.Products
	|				AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = Keys.Characteristic
	|				AND TableTypesOfStocks_.Series = Keys.Series
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Keys.ProductCostElement
	|				AND VALUE(Catalog.Assignments.EmptyRef) = Keys.Purpose
	|				AND &Recipient = Keys.StorageLocation
	|
	|	WHERE
	|		Keys.Products IS NULL
	|		AND TableTypesOfStocks_.Ref = &Ref
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation  AS Warehouse,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products   AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)                 AS Purpose,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Series          AS Series
	|	FROM
	|		Document.MovementOfProductsAndMaterials.InventoryKinds AS TableTypesOfStocks_
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Keys
	|			ON TableTypesOfStocks_.ItemsLocationAttributes.Products = Keys.Products
	|				AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = Keys.Characteristic
	|				AND TableTypesOfStocks_.ItemsLocationAttributes.Series = Keys.Series
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Keys.ProductCostElement
	|				AND VALUE(Catalog.Assignments.EmptyRef) = Keys.Purpose
	|				AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = Keys.StorageLocation
	|
	|	WHERE
	|		Keys.Products IS NULL
	|		AND TableTypesOfStocks_.Ref = &Ref
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner                 AS Warehouse,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products   AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)                 AS Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)          AS Series
	|	FROM
	|		Document.MovementOfProductsAndMaterials.InventoryKinds AS TableTypesOfStocks_
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Keys
	|			ON TableTypesOfStocks_.ItemsLocationAttributes.Products = Keys.Products
	|				AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = Keys.Characteristic
	|				AND VALUE(Catalog.ItemsBatches.EmptyRef) = Keys.Series
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Keys.ProductCostElement
	|				AND VALUE(Catalog.Assignments.EmptyRef) = Keys.Purpose
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = Keys.StorageLocation
	|	WHERE
	|		Keys.Products IS NULL
	|		AND TableTypesOfStocks_.Ref = &Ref
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	) AS Table";
	
	AnalyticsRequest = New Query(QueryText);
	AnalyticsRequest.SetParameter("Ref", Query.Parameters.Ref);
	AnalyticsRequest.SetParameter("Recipient", Query.Parameters.Recipient);
	AnalyticsRequest.SetParameter("Sender", Query.Parameters.Sender);
	AnalyticsRequest.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = AnalyticsRequest.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;

	Query.SetParameter("ProductAnalysisKeysInitialized", True);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	SourceData.Ref							AS Ref,
	|	SourceData.Ref.Date						AS Period,
	|	CASE
	|		WHEN SourceData.ReferenceOrder IN(
	|				VALUE(Document.OrderOfMaterialsForProduction.EmptyRef),
	|				VALUE(Document.ProductionStage2_2.EmptyRef),
	|				UNDEFINED)
	|			THEN UNDEFINED
	|		ELSE SourceData.ReferenceOrder
	|	END											AS OrderDocument,
	|	SourceData.Ref							AS Invoice,
	|	SourceData.Ref.Patch				AS Patch,
	|	SourceData.Ref.CorrectedDocument		AS CorrectedDocument,
	|	SourceData.Ref.Recipient				AS Recipient,
	|	SourceData.Ref.Sender				AS Warehouse,
	|	SourceData.Products					AS Products,
	|	SourceData.Characteristic					AS Characteristic,
	|	SourceData.AssignmentSender			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	SourceData.Series							AS Series,
	|	SourceData.BatchesIndicationStatusSender	AS BatchesIndicationStatus,
	|	SourceData.Count						AS Count,
	|	CASE
	|		WHEN SourceData.Ref.ByReferences
	|			AND SourceData.RowCode = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END											AS ExceedingOrder,
	|	FALSE											AS Canceled,
	|	TRUE											AS ThisIsAnInvoice,
	|	SourceData.Ref.ByReferences			AS ShipmentByOrder
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS SourceData
	|
	|WHERE
	|	SourceData.Ref IN(&Ref)
	|	AND VALUETYPE(SourceData.Ref.Sender) = TYPE(Catalog.Warehouses)
	|";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ArrangeShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	SourceData.Ref							AS Ref,
	|	SourceData.Ref.Date						AS Period,
	|	CASE
	|		WHEN SourceData.ReferenceOrder IN(
	|				VALUE(Document.OrderOfMaterialsForProduction.EmptyRef),
	|				VALUE(Document.ProductionStage2_2.EmptyRef),
	|				UNDEFINED)
	|			THEN UNDEFINED
	|		ELSE SourceData.ReferenceOrder
	|	END											AS OrderDocument,
	|	SourceData.Ref							AS Invoice,
	|	SourceData.Ref.Patch				AS Patch,
	|	SourceData.Ref.CorrectedDocument		AS CorrectedDocument,
	|	SourceData.Ref.Recipient				AS Recipient,
	|	SourceData.Ref.Sender				AS Warehouse,
	|	SourceData.Products					AS Products,
	|	SourceData.Characteristic					AS Characteristic,
	|	SourceData.AssignmentSender			AS Purpose,
	|	SourceData.Purpose						AS PurposeForConnection,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	SourceData.Series							AS Series,
	|	SourceData.BatchesIndicationStatusSender	AS BatchesIndicationStatus,
	|	SourceData.Count						AS Count,
	|	CASE
	|		WHEN SourceData.Ref.ByReferences
	|			AND SourceData.RowCode = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END											AS ExceedingOrder,
	|	SourceData.Ref.ByReferences			AS ShipmentByOrder
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS SourceData
	|WHERE
	|	SourceData.Ref IN(&Ref)
	|	AND VALUETYPE(SourceData.Ref.Sender) = TYPE(Catalog.Warehouses)
	|";
	
	RedefinedSeriesConnectionFields = New Map;
	RedefinedSeriesConnectionFields.Insert("Purpose", "PurposeForConnection");
	
	ParametersOfModularHolding = WarehousesServer.ParametersOfModularHolding();
	ParametersOfModularHolding.TSSeriesName = "SetOfSeries";
	ParametersOfModularHolding.SynonymForDocumentTable = "SourceData";
	ParametersOfModularHolding.RedefinedSeriesConnectionFields = RedefinedSeriesConnectionFields;
	ParametersOfModularHolding.MetadataObject = Metadata.Documents.MovementOfProductsAndMaterials;
	
	WarehousesServer.ArrangeShipmentOfGoodsBySettingParameters(
		Query,
		QueryTexts,
		Registers,
		TextOfDocumentDataRequest,
		ParametersOfModularHolding);
	
EndProcedure

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref							AS Ref,
	|	DataSource.Ref							AS Invoice,
	|	DataSource.Ref.Patch				AS Patch,
	|	DataSource.Ref.CorrectedDocument		AS CorrectedDocument,
	|	CASE
	|		WHEN DataSource.ReferenceOrder IN(
	|				VALUE(Document.OrderOfMaterialsForProduction.EmptyRef),
	|				VALUE(Document.ProductionStage2_2.EmptyRef),
	|				UNDEFINED)
	|			THEN UNDEFINED
	|		ELSE DataSource.ReferenceOrder
	|	END											AS OrderDocument,
	|	UNDEFINED									AS Contract,
	|	UNDEFINED									AS Terms,
	|	DataSource.Ref.GoodsReceiptOption		AS GoodsReceiptOption,
	|	
	|	CASE WHEN DataSource.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
	|				DataSource.Ref.DateOfReceipt
	|			ELSE
	|				DataSource.Ref.Date
	|		END AS Date,
	|	
	|	DataSource.Products						AS Products,
	|	DataSource.Characteristic					AS Characteristic,
	|	DataSource.Purpose						AS Purpose,
	|	DataSource.ToControlQuality        AS ToControlQuality,
	|	FALSE                                            AS RecordOfAPreviouslyReceivedLot,
	|	DataSource.Ref.ControlledLotReference      AS ControlledLotReference,
	|	DataSource.Series							AS Series,
	|	DataSource.BatchesIndicationStatusRecipient	AS BatchesIndicationStatus,
	|	DataSource.Ref.ByReferences
	|		AND DataSource.RowCode = 0				AS ExceedingOrder,
	|	DataSource.Ref.Recipient				AS Warehouse,
	|	DataSource.Ref.Sender				AS Sender,
	|	CASE
	|		WHEN DataSource.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction)
	|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|		ELSE DataSource.Ref.BusinessOperation
	|	END											AS BusinessOperation,
	|	DataSource.Count						AS Count,
	|	TRUE											AS ThisIsAnInvoice,
	|	DataSource.Ref.ByReferences			AS ReceiptUnderOrders
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS DataSource
	|WHERE
	|	DataSource.Ref IN(&Ref)
	|	AND DataSource.Ref.ByReferences
	|	AND DataSource.Ref.BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|		 VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
	|		 VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|		 VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
	|	AND VALUETYPE(DataSource.Ref.Recipient) = TYPE(Catalog.Warehouses)
	|
	|UNION ALL
	|
	|SELECT
	|	DataSource.Ref							AS Ref,
	|	DataSource.Ref							AS Invoice,
	|	DataSource.Ref.Patch				AS Patch,
	|	DataSource.Ref.CorrectedDocument		AS CorrectedDocument,
	|	UNDEFINED									AS OrderDocument,
	|	UNDEFINED									AS Contract,
	|	UNDEFINED									AS Terms,
	|	DataSource.Ref.GoodsReceiptOption		AS GoodsReceiptOption,
	|	
	|	CASE WHEN DataSource.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
	|				DataSource.Ref.DateOfReceipt
	|			ELSE
	|				DataSource.Ref.Date
	|		END AS Date,
	|	
	|	DataSource.Products						AS Products,
	|	DataSource.Characteristic					AS Characteristic,
	|	DataSource.Purpose						AS Purpose,
	|	DataSource.ToControlQuality        AS ToControlQuality,
	|	FALSE                                            AS RecordOfAPreviouslyReceivedLot,
	|	DataSource.Ref.ControlledLotReference      AS ControlledLotReference,
	|	DataSource.Series							AS Series,
	|	DataSource.BatchesIndicationStatusRecipient	AS BatchesIndicationStatus,
	|	DataSource.Ref.ByReferences
	|		AND DataSource.RowCode = 0				AS ExceedingOrder,
	|	DataSource.Ref.Recipient				AS Warehouse,
	|	DataSource.Ref.Sender				AS Sender,
	|	CASE
	|		WHEN DataSource.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction)
	|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|		ELSE DataSource.Ref.BusinessOperation
	|	END											AS BusinessOperation,
	|	DataSource.Count						AS Count,
	|	TRUE											AS ThisIsAnInvoice,
	|	DataSource.Ref.ByReferences			AS ReceiptUnderOrders
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS DataSource
	|WHERE
	|	DataSource.Ref IN(&Ref)
	|	AND NOT DataSource.Ref.ByReferences
	|	AND VALUETYPE(DataSource.Ref.Recipient) = TYPE(Catalog.Warehouses)
	|";
	
	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Procedure ToIssuePurchaseOfGoodsOnDvukhodovka(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	DataSource.Ref                        AS Ref,
	|	CASE
	|		WHEN DataSource.ReferenceOrder IN(
	|				VALUE(Document.OrderOfMaterialsForProduction.EmptyRef),
	|				VALUE(Document.ProductionStage2_2.EmptyRef),
	|				UNDEFINED)
	|			THEN UNDEFINED
	|		ELSE DataSource.ReferenceOrder
	|	END                                        AS OrderDocument,
	|	CASE
	|		WHEN DataSource.Ref.Patch THEN
	|			DataSource.Ref.CorrectedDocument
	|		ELSE
	|			DataSource.Ref
	|	END                                        AS Invoice,
	|	DataSource.Ref.Patch            AS Patch,
	|	DataSource.Ref.CorrectedDocument   AS CorrectedDocument,
	|	DataSource.Ref.Date                   AS Date,
	|	DataSource.Ref.Date                   AS DateOfPlannedReceipt,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	UNDEFINED                                 AS Terms,
	|	DataSource.Ref.GoodsReceiptOption  AS GoodsReceiptOption,
	|	DataSource.Ref.Recipient             AS Warehouse,
	|	DataSource.Ref.Sender            AS Sender,
	|	CASE
	|		WHEN DataSource.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction)
	|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|		ELSE DataSource.Ref.BusinessOperation
	|	END                                        AS BusinessOperation,
	|	DataSource.Products                  AS Products,
	|	DataSource.Characteristic                AS Characteristic,
	|	DataSource.Purpose                    AS Purpose,
	|	DataSource.ToControlQuality     AS ToControlQuality,
	|	FALSE                                         AS RecordOfAPreviouslyReceivedLot,
	|	DataSource.Ref.ControlledLotReference   AS ControlledLotReference,
	|	DataSource.BatchesIndicationStatusRecipient AS BatchesIndicationStatus,
	|	DataSource.Ref.ByReferences
	|		AND DataSource.RowCode = 0           AS ExceedingOrder,
	|	DataSource.Series                         AS Series,
	|	DataSource.Count                    AS Count,
	|	DataSource.Ref.ByReferences        AS ReceiptUnderOrders,
	|	TRUE                                       AS ThisIsAnInvoice
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS DataSource
	|WHERE
	|	DataSource.Ref IN(&Ref)
	|	AND VALUETYPE(DataSource.Ref.Recipient) = TYPE(Catalog.Warehouses)
	|";
	
	WarehousesServer.ToIssuePurchaseOfGoodsOnDvukhodovka(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_);
		
EndProcedure

Procedure ToIssueReceiptOfGoodsOnDvukhodovka(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	DataSource.Ref                         AS Ref,
	|	CASE
	|		WHEN DataSource.ReferenceOrder IN(
	|				VALUE(Document.OrderOfMaterialsForProduction.EmptyRef),
	|				VALUE(Document.ProductionStage2_2.EmptyRef),
	|				UNDEFINED)
	|			THEN UNDEFINED
	|		ELSE DataSource.ReferenceOrder
	|	END                                         AS OrderDocument,
	|	CASE
	|		WHEN DataSource.Ref.Patch THEN
	|			DataSource.Ref.CorrectedDocument
	|		ELSE
	|			DataSource.Ref
	|	END                                         AS Invoice,
	|	DataSource.Ref.Date                    AS Date,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	UNDEFINED                                  AS Terms,
	|	DataSource.Ref.GoodsReceiptOption   AS GoodsReceiptOption,
	|	DataSource.Ref.Recipient              AS Warehouse,
	|	DataSource.Ref.Sender             AS Sender,
	|	CASE
	|		WHEN DataSource.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction)
	|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|		ELSE DataSource.Ref.BusinessOperation
	|	END                                         AS BusinessOperation,
	|	DataSource.Products                   AS Products,
	|	DataSource.Characteristic                 AS Characteristic,
	|	DataSource.Purpose                     AS Purpose,
	|	DataSource.ToControlQuality      AS ToControlQuality,
	|	FALSE                                          AS RecordOfAPreviouslyReceivedLot,
	|	DataSource.Ref.ControlledLotReference    AS ControlledLotReference,
	|	DataSource.BatchesIndicationStatus            AS BatchesIndicationStatus,
	|	DataSource.BatchesIndicationStatusRecipient  AS BatchesIndicationStatusInWarehouses,
	|	DataSource.BatchesIndicationStatusSender AS BatchesIndicationStatusGoodsAtPartners,
	|	DataSource.Ref.ByReferences
	|		AND DataSource.RowCode = 0            AS ExceedingOrder,
	|	DataSource.Series                          AS Series,
	|	DataSource.Count                     AS Count,
	|	DataSource.Ref.ByReferences         AS ReceiptUnderOrders,
	|	TRUE                                        AS ThisIsAnInvoice
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS DataSource
	|WHERE
	|	DataSource.Ref IN(&Ref)
	|	AND VALUETYPE(DataSource.Ref.Recipient) = TYPE(Catalog.Warehouses)
	|	AND DataSource.Ref.Status = VALUE(Enum.StatusesOfProductsAndMaterialMovement.Accepted)
	|";

	CurrentMetadataObject1 = Metadata.Documents.MovementOfProductsAndMaterials;
	
	WarehousesServer.ToIssueReceiptOfGoodsOnDvukhodovka(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		CurrentMetadataObject1,
		"SetOfSeries");
		
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)

	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|SELECT
	|	&Period                                                AS Period,
	|	GoodsTable.Products                              AS Products,
	|	GoodsTable.Characteristic                            AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END   	  				                           AS Purpose,
	|	GoodsTable.Series                                     AS Series,
	|	GoodsTable.Count                                AS Count,
	|	&Sender                                           AS Sender,
	|	&Recipient                                            AS Recipient,
	|	&WarehouseOperation                                     AS WarehouseOperation,
	|	&Ref                                                AS Document,
	|	NOT &SenderOrderScheme                           AS ThisIsWarehouseRecord
	|FROM
	|	Document.MovementOfProductsAndMaterials.SetOfSeries AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                AS Period,
	|	GoodsTable.Products                             AS Products,
	|	GoodsTable.Characteristic                           AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                  AS Purpose,
	|	GoodsTable.Series                                    AS Series,
	|	GoodsTable.Count                               AS Count,
	|	&Sender                                           AS Sender,
	|	&Recipient                                            AS Recipient,
	|	&WarehouseOperation                                     AS WarehouseOperation,
	|	&Ref                                                AS Document,
	|	NOT &SenderOrderScheme                           AS ThisIsWarehouseRecord
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	// consumption from the warehouse, workshop
	|SELECT
	|	1                                              AS Order,
	|	TableTypesOfStocks_.LineNumber                 AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)         AS RecordType,
	|	&Period                                        AS Period,
	|	TableTypesOfStocks_.Organization                 AS ShipmentCompany,
	|	CASE
	|		WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|		ELSE TableTypesOfStocks_.Organization
	|	END                                          AS Organization,
	|
	|	CASE WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory THEN
	|		TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner
	|	ELSE
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	END                                          AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute        AS CorInventoryOwnerAttribute,
	|
	|	TableTypesOfStocks_.Products                AS Products,
	|	TableTypesOfStocks_.Characteristic              AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber                    AS CCDNumber,
	|	TableTypesOfStocks_.Count                  AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN            AS QuantityByGBRN,
	|	&BusinessOperation                         AS BusinessOperation,
	|	TableTypesOfStocks_.VATTaxation          AS VATTaxation,
	|	TableTypesOfStocks_.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.AnalysisOfAccountingForRecipientProducts AS CorItemsLocationAttributes,
	|	FALSE                                           AS Primary
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|UNION ALL
	|
	// arrival at the warehouse, in the workshop
	|SELECT
	|	2                                              AS Order,
	|	TableTypesOfStocks_.LineNumber                 AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)         AS RecordType,
	|	&Period                                        AS Period,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
	|			THEN &Organization
	|		ELSE UNDEFINED
	|	END                                          AS ShipmentCompany,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
	|			THEN &CompanyRecipient
	|		ELSE TableTypesOfStocks_.Organization
	|	END                                          AS Organization,
	|
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute        AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE UNDEFINED
	|	END                                          AS CorInventoryOwnerAttribute,
	|
	|	TableTypesOfStocks_.Products                AS Products,
	|	TableTypesOfStocks_.Characteristic              AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber                    AS CCDNumber,
	|	TableTypesOfStocks_.Count                  AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN            AS QuantityByGBRN,
	|	&BusinessOperation                         AS BusinessOperation,
	|	TableTypesOfStocks_.VATTaxation          AS VATTaxation,
	|	TableTypesOfStocks_.AnalysisOfAccountingForRecipientProducts AS ItemsLocationAttributes,
	|	UNDEFINED                                   AS CorItemsLocationAttributes,
	|	FALSE                                           AS Primary
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	&Status = VALUE(Enum.StatusesOfProductsAndMaterialMovement.Accepted)
	|
	|ORDER BY
	|	Order,
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoodsForTransfer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	TableTypesOfStocks_.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)             AS RecordType,
	|	&Period                                            AS Period,
	|	&Sender                                       AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization AS CompanyOwner,
	|	TableTypesOfStocks_.ItemsLocationAttributes      AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                      AS SellerInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                        AS CCDNumber,
	|	TableTypesOfStocks_.Products                    AS Products,
	|	TableTypesOfStocks_.Characteristic                  AS Characteristic,
	|	TableTypesOfStocks_.Count                      AS Count,
	|	&BusinessOperation                             AS BusinessOperation,
	|	TableTypesOfStocks_.VATTaxation              AS VATTaxation
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|	AND &BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|		 VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber            AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&Period                                   AS Period,
	|	&Organization                              AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute             AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CommitteeAnalytics     AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency      AS Currency,
	|	TableTypesOfStocks_.CCDNumber               AS CCDNumber,
	|	0                                         AS Count,
	|	0                                         AS RevenueAmount,
	|	0                                         AS RevenueAmountExclVATLocal,
	|	0                                         AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count             AS QuantityConsumed,
	|	0                                         AS QuantityToRegister,
	|	0                                         AS QuantityForRegistrationByProductBatchID,
	|	0                                         AS RevenueAmountToRegister,
	|	TableTypesOfStocks_.Count             AS QuantityConsumedForIncoiceRegistration,
	|	TableTypesOfStocks_.QuantityByGBRN       AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	TableTypesOfStocks_.Products           AS Products,
	|	TableTypesOfStocks_.Characteristic         AS Characteristic,
	|	&BusinessOperation                    AS BusinessOperation,
	|	UNDEFINED                              AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.AnalysisOfAccountingForRecipientProducts AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.VATTaxation     AS VATTaxation,
	|	TableTypesOfStocks_.RowID    AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ConsignedGoodsWriteOff) AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID    AS RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND TableTypesOfStocks_.RecipientInventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|	AND &BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|		VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)

	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                           AS Period,
	|	&BusinessOperation                            AS BusinessOperation,
	|	Rows.Organization                                AS Organization,
	|	CASE
	|		WHEN VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|			THEN &Sender
	|		WHEN &TransferFromPantry
	|			THEN &SenderSDivision
	|		WHEN VALUETYPE(&Recipient) = TYPE(Catalog.BusinessStructure)
	|			THEN &Recipient
	|		WHEN &EnteringPantry
	|			THEN &RecipientSDivision
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END                                             AS Department,
	|	Rows.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments THEN
	|			Rows.ItemsLocationAttributes
	|		ELSE Rows.AnalysisOfAccountingForProductsWithoutAssignment
	|	END                                             AS ItemsLocationAttributes,
	|	&Sender                                      AS Warehouse,
	|	CASE
	|		WHEN Rows.SaleOfAnotherCompanyInventory THEN
	|			Rows.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType
	|		ELSE Rows.InventoryType
	|	END                                             AS InventoryType,
	|	CASE
	|		WHEN Rows.SaleOfAnotherCompanyInventory THEN
	|				Rows.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE Rows.InventoryOwnerAttribute
	|	END                                             AS InventoryOwnerAttribute,
	|	Rows.AnalysisOfAccountingForRecipientProducts.Purpose.LineOfBusiness AS CorLineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments THEN
	|			Rows.AnalysisOfAccountingForRecipientProducts
	|		ELSE
	|			Rows.AnalysisOfAccountingForRecipientProductsWithoutAssignment
	|	END                                             AS CorItemsLocationAttributes,
	|	&Recipient                                       AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	Rows.RecipientInventoryType                       AS CorInventoryType,
	|	Rows.RecipientInventoryOwnerAttribute                       AS CorInventoryOwnerAttribute,
	|
	|	Rows.Count                                 AS Count,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
	|			THEN 0
	|		ELSE Rows.Count
	|	END                                             AS CorQuantity,
	|
	|	0                                                 AS Cost,
	|	0                                                 AS CostExcludingVAT,
	|	0                                                 AS LocalCost,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|			Rows.InventoryOwnerAttribute
	|		ELSE
	|			Rows.Products
	|	END                                             AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|			Rows.InventoryOwnerAttribute
	|		ELSE
	|			Rows.Products
	|	END                                             AS CorSourceOfItemsFinancialAccountingGroup,
	|	UNDEFINED                                      AS DocumentRegisterRecords,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
	|			THEN &CompanyRecipient
	|		ELSE UNDEFINED
	|	END                                             AS CorCompany
	|FROM
	|	TTTypesOfStocks AS Rows
	|WHERE
	|	&BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|		 VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom),
	|		 VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices))
	|	AND &Status = VALUE(Enum.StatusesOfProductsAndMaterialMovement.Accepted)
	|	AND Rows.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods),
	|							VALUE(Enum.InventoryTypes.ConsignedGoods))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                           AS Period,
	|	&BusinessOperation                            AS BusinessOperation,
	|	Rows.Organization                                AS Organization,
	|	CASE
	|		WHEN VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|			THEN &Sender
	|		WHEN &TransferFromPantry
	|			THEN &SenderSDivision
	|		WHEN VALUETYPE(&Recipient) = TYPE(Catalog.BusinessStructure)
	|			THEN &Recipient
	|		WHEN &EnteringPantry
	|			THEN &RecipientSDivision
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END                                             AS Department,
	|	Rows.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	Rows.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Sender AS Warehouse,
	|	Rows.InventoryType AS InventoryType,
	|	Rows.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Rows.AnalysisOfAccountingForRecipientProducts.Purpose.LineOfBusiness AS CorLineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments THEN
	|			Rows.AnalysisOfAccountingForRecipientProducts
	|		ELSE
	|			Rows.AnalysisOfAccountingForRecipientProductsWithoutAssignment
	|	END                                             AS CorItemsLocationAttributes,
	|	&Recipient                                       AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	CASE
	|		WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			Rows.RecipientInventoryType
	|		ELSE Rows.InventoryType
	|	END                                             AS CorInventoryType,
	|	CASE
	|		WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			Rows.RecipientInventoryOwnerAttribute
	|		ELSE Rows.InventoryOwnerAttribute
	|	END                                             AS CorInventoryOwnerAttribute,
	|	Rows.Count                                 AS Count,
	|	Rows.Count                                 AS CorQuantity,
	|	0                                                 AS Cost,
	|	0                                                 AS CostExcludingVAT,
	|	0                                                 AS LocalCost,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|			Rows.InventoryOwnerAttribute
	|		ELSE
	|			Rows.Products
	|	END                                             AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|			Rows.InventoryOwnerAttribute
	|		ELSE
	|			Rows.Products
	|	END                                             AS CorSourceOfItemsFinancialAccountingGroup,
	|	UNDEFINED                                      AS DocumentRegisterRecords,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
	|			THEN &Organization
	|		ELSE UNDEFINED
	|	END                                             AS CorCompany
	|FROM
	|	TTTypesOfStocks AS Rows
	|WHERE
	|	&BusinessOperation IN (VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|							VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
	|							VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
	|							VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
	|							VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom))
	|	AND &Status = VALUE(Enum.StatusesOfProductsAndMaterialMovement.Accepted)
	|	AND Rows.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods),
	|							VALUE(Enum.InventoryTypes.ConsignedGoods))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                           AS Period,
	|	VALUE(Enum.BusinessTransactions.InternalGoodsReceipt) AS BusinessOperation,
	|	&CompanyRecipient                            AS Organization,
	|	CASE
	|		WHEN VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|			THEN &Sender
	|		WHEN &TransferFromPantry
	|			THEN &SenderSDivision
	|		WHEN VALUETYPE(&Recipient) = TYPE(Catalog.BusinessStructure)
	|			THEN &Recipient
	|		WHEN &EnteringPantry
	|			THEN &RecipientSDivision
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END                                             AS Department,
	|	Rows.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments THEN
	|			Rows.ItemsLocationAttributes
	|		ELSE Rows.AnalysisOfAccountingForProductsWithoutAssignment
	|	END                                             AS ItemsLocationAttributes,
	|	&Sender                                      AS Warehouse,
	|	CASE
	|		WHEN Rows.SaleOfAnotherCompanyInventory THEN
	|			Rows.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType
	|		ELSE Rows.InventoryOwnerAttribute.InventoryType
	|	END                                             AS InventoryType,
	|	CASE
	|		WHEN Rows.SaleOfAnotherCompanyInventory THEN
	|			Rows.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE Rows.InventoryOwnerAttribute
	|	END                                             AS InventoryOwnerAttribute,
	|	Rows.AnalysisOfAccountingForRecipientProducts.Purpose.LineOfBusiness AS CorLineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments THEN
	|			Rows.AnalysisOfAccountingForRecipientProducts
	|		ELSE
	|			Rows.AnalysisOfAccountingForRecipientProductsWithoutAssignment
	|	END                                             AS CorItemsLocationAttributes,
	|	&Recipient                                       AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	Rows.RecipientInventoryOwnerAttribute.InventoryType            AS CorInventoryType,
	|	Rows.RecipientInventoryOwnerAttribute                       AS CorInventoryOwnerAttribute,
	|
	|	0                                                 AS Count,
	|	Rows.Count                                 AS CorQuantity,
	|
	|	0                                                 AS Cost,
	|	0                                                 AS CostExcludingVAT,
	|	0                                                 AS LocalCost,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|			Rows.InventoryOwnerAttribute
	|		ELSE
	|			Rows.Products
	|	END                                             AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|			Rows.InventoryOwnerAttribute
	|		ELSE
	|			Rows.Products
	|	END                                             AS CorSourceOfItemsFinancialAccountingGroup,
	|	UNDEFINED                                      AS DocumentRegisterRecords,
	|	&Organization                                      AS CorCompany
	|FROM
	|	TTTypesOfStocks AS Rows
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
	|	AND Rows.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods),
	|							VALUE(Enum.InventoryTypes.ConsignedGoods))";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableOrdersOfMaterialsForProduction(Query, QueryTexts, Registers)

	RegisterName = "OrdersOfMaterialsForProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"
	|SELECT
	|	TableMaterialsAndServices.LineNumber             AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	&Period                                         AS Period,
	|	TableMaterialsAndServices.ReferenceOrder            AS ReferenceOrder,
	|	&RecipientSDivision                        AS Department,
	|	&Recipient                                     AS Recipient,
	|	TableMaterialsAndServices.Products            AS Products,
	|	TableMaterialsAndServices.Characteristic          AS Characteristic,
	|	CASE 
	|		WHEN TableMaterialsAndServices.BatchesIndicationStatusSender IN (10, 14) 
	|			THEN TableMaterialsAndServices.Series
	|	END                                           AS Series,
	|	&Sender                                    AS Warehouse,
	|	TableMaterialsAndServices.Purpose              AS Purpose,
	|	TableMaterialsAndServices.AssignmentSender   AS AssignmentSender,
	|	TableMaterialsAndServices.RowCode               AS RowCode,
	|	TableMaterialsAndServices.Count              AS Ordered,
	|	TableMaterialsAndServices.Count              AS ToRegister,
	|	0                                              AS ShippedNotReceived
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS TableMaterialsAndServices
	|WHERE
	|	TableMaterialsAndServices.Ref = &Ref
	|	AND &BusinessOperation IN (VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|								VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
	|	AND TableMaterialsAndServices.RowCode <> 0
	|	AND &ByReferences
	|
	|UNION ALL
	|
	|SELECT
	|	TableMaterialsAndServices.LineNumber             AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	&Period                                         AS Period,
	|	TableMaterialsAndServices.ReferenceOrder            AS ReferenceOrder,
	|	&RecipientSDivision                        AS Department,
	|	&Recipient                                     AS Recipient,
	|	TableMaterialsAndServices.Products            AS Products,
	|	TableMaterialsAndServices.Characteristic          AS Characteristic,
	|	CASE 
	|		WHEN TableMaterialsAndServices.BatchesIndicationStatusSender IN (10, 14) 
	|			THEN TableMaterialsAndServices.Series
	|	END                                           AS Series,
	|	&Sender                                    AS Warehouse,
	|	TableMaterialsAndServices.Purpose              AS Purpose,
	|	TableMaterialsAndServices.AssignmentSender   AS AssignmentSender,
	|	TableMaterialsAndServices.RowCode               AS RowCode,
	|	0                                               AS Ordered,
	|	0                                               AS ToRegister,
	|	TableMaterialsAndServices.Count              AS ShippedNotReceived
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS TableMaterialsAndServices
	|WHERE
	|	TableMaterialsAndServices.Ref = &Ref
	|	AND &BusinessOperation IN (VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|								VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
	|	AND TableMaterialsAndServices.RowCode <> 0
	|	AND &ByReferences
	|	AND &Status <> VALUE(Enum.StatusesOfProductsAndMaterialMovement.Accepted)
	|
	|ORDER BY
	|	LineNumber";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableReferencesToTransferFromProduction(Query, QueryTexts, Registers)
	
	RegisterName = "ReferencesToTransferFromProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
	|	&Period                                      AS Period,
	|	&Sender                                 AS Sender,
	|	&Recipient                                  AS Recipient,
	|	&Organization                                 AS Organization,
	|	&BusinessOperation                       AS Operation,
	|	TabularSection.ReferenceOrder                  AS ReferenceOrder,
	|	TabularSection.Products                  AS Products,
	|	TabularSection.Characteristic                AS Characteristic,
	|	TabularSection.Purpose                    AS Purpose,
	|	TabularSection.AssignmentSender         AS AssignmentSender,
	|	CASE
	|		WHEN TabularSection.BatchesIndicationStatusSender = 14
	|			THEN TabularSection.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                                        AS Series,
	|	TabularSection.RowCode                     AS RowCode,
	|	TabularSection.Count                    AS Count
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|		VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction))";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction
Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBases", QueryTexts) Then
		QueryTextTTBases(Query, QueryTexts);
	EndIf;
	
	SetRequestParametersSenderAndRecipientInformation(Query);
	
	QueryText =
	"SELECT
	|	DocumentData.RefType                AS RefType,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.BusinessOperation    AS BusinessOperation,
	|	DocumentData.Partner                  AS Partner,
	|	DocumentData.Counterparty               AS Counterparty,
	|	DocumentData.LineOfBusiness  AS LineOfBusiness,
	|	DocumentData.AdditionalRecord     AS AdditionalRecord,
	|	DocumentData.Department            AS Department,
	|	DocumentData.StorageLocation            AS StorageLocation,
	|	DocumentData.IBDocumentDate          AS IBDocumentDate,
	|	DocumentData.Ref                   AS Ref,
	|	DocumentData.IBDocumentNumber         AS IBDocumentNumber,
	|	DocumentData.EmployeeResponsible            AS EmployeeResponsible,
	|	DocumentData.Author                    AS Author,
	|	DocumentData.Comment              AS Comment,
	|	DocumentData.Currency                   AS Currency,
	|	DocumentData.Sum                    AS Sum,
	|	DocumentData.Status                   AS Status,
	|	DocumentData.Posted                 AS Posted,
	|	DocumentData.DeletionMark          AS DeletionMark,
	|	DocumentData.More            AS More,
	|	DocumentData.SourceDocumentDate  AS SourceDocumentDate,
	|	DocumentData.SourceDocumentNumber AS SourceDocumentNumber,
	|	DocumentData.IBDocumentDate          AS RecordingInAccountingDate,
	|	DocumentData.ReverseTransactionCorrection        AS ReverseTransactionCorrection,
	|	DocumentData.ReversedDocument     AS ReversedDocument,
	|	DocumentData.CorrectedDocument     AS CorrectedDocument,
	|	UNDEFINED                             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	TableDocumentRegistry.RefType                          AS RefType,
	|	TableDocumentRegistry.Organization                        AS Organization,
	|	TableDocumentRegistry.BusinessOperation              AS BusinessOperation,
	|	TableDocumentRegistry.Partner                            AS Partner,
	|	TableDocumentRegistry.Counterparty                         AS Counterparty,
	|	CASE
	|		WHEN TableDocumentRegistry.NumberOfActivities = 1
	|			THEN TableDocumentRegistry.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                                                      AS LineOfBusiness,
	|	MIN(TableDocumentRegistry.AdditionalRecord)      AS AdditionalRecord,
	|	TableDocumentRegistry.Department                      AS Department,
	|	TableDocumentRegistry.StorageLocation                      AS StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate                    AS IBDocumentDate,
	|	TableDocumentRegistry.Ref                             AS Ref,
	|	MAX(TableDocumentRegistry.IBDocumentNumber)         AS IBDocumentNumber,
	|	MAX(TableDocumentRegistry.EmployeeResponsible)            AS EmployeeResponsible,
	|	MAX(TableDocumentRegistry.Author)                    AS Author,
	|	MAX(TableDocumentRegistry.Comment)              AS Comment,
	|	MAX(TableDocumentRegistry.Currency)                   AS Currency,
	|	MAX(TableDocumentRegistry.Sum)                    AS Sum,
	|	MAX(TableDocumentRegistry.Status)                   AS Status,
	|	MAX(TableDocumentRegistry.Posted)                 AS Posted,
	|	MAX(TableDocumentRegistry.DeletionMark)          AS DeletionMark,
	|	MAX(TableDocumentRegistry.More)            AS More,
	|	MAX(TableDocumentRegistry.SourceDocumentDate)  AS SourceDocumentDate,
	|	MAX(TableDocumentRegistry.SourceDocumentNumber) AS SourceDocumentNumber,
	|	MAX(TableDocumentRegistry.ReverseTransactionCorrection)        AS ReverseTransactionCorrection,
	|	MAX(TableDocumentRegistry.ReversedDocument)     AS ReversedDocument,
	|	MAX(TableDocumentRegistry.CorrectedDocument)     AS CorrectedDocument
	|INTO TTBases
	|	FROM
	|	(SELECT
	|		DocumentData.Ref                        AS Ref,
	|		&Period                                       AS IBDocumentDate,
	|		&Number                                        AS IBDocumentNumber,
	|		&MetadataIdentifier                      AS RefType,
	|		&Organization                                  AS Organization,
	|		&BusinessOperation                        AS BusinessOperation,
	|		VALUE(Catalog.Partners.EmptyRef)    AS Partner,
	|		VALUE(Catalog.DocumentRegistryKeys.EmptyRef) AS Counterparty,
	|		CASE
	|			WHEN VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|				THEN &Recipient
	|			ELSE &Sender
	|		END                                  AS StorageLocation,
	|		CASE
	|			WHEN VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|				THEN &Sender
	|			WHEN &TransferFromPantry
	|				THEN &SenderSDivision
	|			WHEN VALUETYPE(&Recipient) = TYPE(Catalog.BusinessStructure)
	|				THEN &Recipient
	|			WHEN &EnteringPantry
	|				THEN &RecipientSDivision
	|			ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|		END                                         AS Department,
	|		&EmployeeResponsible                                AS EmployeeResponsible,
	|		&Author                                        AS Author,
	|		CAST(&Comment AS STRING(100))        AS Comment,
	|		VALUE(Catalog.Currencies.EmptyRef)      AS Currency,
	|		0                                             AS Sum,
	|		&Status                                       AS Status,
	|		&Posted                                     AS Posted,
	|		&DeletionMark                              AS DeletionMark,
	|		FALSE                                          AS AdditionalRecord,
	|		CASE
	|			WHEN VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|				THEN &SenderInformation
	|			ELSE &RecipientInformation
	|		END                                         AS More,
	|		&Period                                       AS SourceDocumentDate,
	|		&NumberForPrinting                                AS SourceDocumentNumber,
	|		&Patch                                  AS ReverseTransactionCorrection,
	|		&ReversedDocument                         AS ReversedDocument,
	|		&CorrectedDocument                         AS CorrectedDocument,
	|		MAX(
	|			ISNULL(GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		                                              AS LineOfBusiness,
	|		COUNT(
	|			DISTINCT ISNULL(GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		                                              AS NumberOfActivities
	|	FROM
	|		Document.MovementOfProductsAndMaterials AS DocumentData
	|		
	|		LEFT JOIN Document.MovementOfProductsAndMaterials.Goods AS GoodsTable
	|		ON DocumentData.Ref = GoodsTable.Ref
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	GROUP BY
	|		DocumentData.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref                        AS Ref,
	|		&Period                                       AS IBDocumentDate,
	|		&Number                                        AS IBDocumentNumber,
	|		&MetadataIdentifier                      AS RefType,
	|		CASE
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
	|				THEN &CompanyRecipient
	|			ELSE ISNULL(GoodsTable.InventoryOwnerAttribute.Organization, &Organization)
	|		END                                         AS Organization,
	|		&BusinessOperation                        AS BusinessOperation,
	|		VALUE(Catalog.Partners.EmptyRef)    AS Partner,
	|		VALUE(Catalog.DocumentRegistryKeys.EmptyRef) AS Counterparty,
	|		CASE
	|			WHEN NOT VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|				THEN &Recipient
	|			ELSE &Sender
	|		END                                  AS StorageLocation,
	|		CASE
	|			WHEN VALUETYPE(&Recipient) = TYPE(Catalog.BusinessStructure)
	|				THEN &Recipient
	|			WHEN &EnteringPantry
	|				THEN &RecipientSDivision
	|			WHEN VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|				THEN &Sender
	|			WHEN &TransferFromPantry
	|				THEN &SenderSDivision
	|			ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|		END                                         AS Department,
	|		&EmployeeResponsible                                AS EmployeeResponsible,
	|		&Author                                        AS Author,
	|		CAST(&Comment AS STRING(100))        AS Comment,
	|		VALUE(Catalog.Currencies.EmptyRef)      AS Currency,
	|		0                                             AS Sum,
	|		&Status                                       AS Status,
	|		&Posted                                     AS Posted,
	|		&DeletionMark                              AS DeletionMark,
	|		TRUE                                        AS AdditionalRecord,
	|		CASE
	|			WHEN NOT VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|				THEN &SenderInformation
	|			ELSE &RecipientInformation
	|		END                                         AS More,
	|		&Period                                       AS SourceDocumentDate,
	|		&NumberForPrinting                                AS SourceDocumentNumber,
	|		&Patch                                  AS ReverseTransactionCorrection,
	|		&ReversedDocument                         AS ReversedDocument,
	|		&CorrectedDocument                         AS CorrectedDocument,
	|		MAX(
	|			ISNULL(GoodsTable.AssignmentRecipient.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		                                              AS LineOfBusiness,
	|		COUNT(
	|			DISTINCT ISNULL(GoodsTable.AssignmentRecipient.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		                                              AS NumberOfActivities
	|	FROM
	|		Document.MovementOfProductsAndMaterials AS DocumentData
	|			LEFT JOIN Document.MovementOfProductsAndMaterials.InventoryKinds AS GoodsTable
	|			ON DocumentData.Ref = GoodsTable.Ref
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	GROUP BY
	|		DocumentData.Ref,
	|		CASE
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
	|				THEN &CompanyRecipient
	|			ELSE ISNULL(GoodsTable.InventoryOwnerAttribute.Organization, &Organization)
	|		END
	|	
	|	UNION ALL
	|	
	// Internal Processing
	|	SELECT
	|		DocumentData.Ref                        AS Ref,
	|		&Period                                       AS IBDocumentDate,
	|		&Number                                        AS IBDocumentNumber,
	|		&MetadataIdentifier                      AS RefType,
	|		&MaterialProviderCompany                           AS Organization,
	|		&BusinessOperation                        AS BusinessOperation,
	|		VALUE(Catalog.Partners.EmptyRef)    AS Partner,
	|		VALUE(Catalog.DocumentRegistryKeys.EmptyRef) AS Counterparty,
	|		CASE
	|			WHEN VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|				THEN &Recipient
	|			ELSE &Sender
	|		END                                  AS StorageLocation,
	|		CASE
	|			WHEN VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|				THEN &Sender
	|			WHEN &TransferFromPantry
	|				THEN &SenderSDivision
	|			WHEN VALUETYPE(&Recipient) = TYPE(Catalog.BusinessStructure)
	|				THEN &Recipient
	|			WHEN &EnteringPantry
	|				THEN &RecipientSDivision
	|			ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|		END                                         AS Department,
	|		&EmployeeResponsible                                AS EmployeeResponsible,
	|		&Author                                        AS Author,
	|		CAST(&Comment AS STRING(100))        AS Comment,
	|		VALUE(Catalog.Currencies.EmptyRef)      AS Currency,
	|		0                                             AS Sum,
	|		&Status                                       AS Status,
	|		&Posted                                     AS Posted,
	|		&DeletionMark                              AS DeletionMark,
	|		TRUE                                        AS AdditionalRecord,
	|		CASE
	|			WHEN VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|				THEN &SenderInformation
	|			ELSE &RecipientInformation
	|		END                                         AS More,
	|		&Period                                       AS SourceDocumentDate,
	|		&NumberForPrinting                                AS SourceDocumentNumber,
	|		&Patch                                  AS ReverseTransactionCorrection,
	|		&ReversedDocument                         AS ReversedDocument,
	|		&CorrectedDocument                         AS CorrectedDocument,
	|		MAX(
	|			ISNULL(GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		                                              AS LineOfBusiness,
	|		COUNT(
	|			DISTINCT ISNULL(GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		                                              AS NumberOfActivities
	|	FROM
	|		Document.MovementOfProductsAndMaterials AS DocumentData
	|		
	|		INNER JOIN Document.MovementOfProductsAndMaterials.InventoryKinds AS GoodsTable
	|		ON DocumentData.Ref = GoodsTable.Ref
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND &InternalSubcontracting
	|	
	|	GROUP BY
	|		DocumentData.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref                        AS Ref,
	|		&Period                                       AS IBDocumentDate,
	|		&Number                                        AS IBDocumentNumber,
	|		&MetadataIdentifier                      AS RefType,
	|		&MaterialProviderCompany                           AS Organization,
	|		&BusinessOperation                        AS BusinessOperation,
	|		VALUE(Catalog.Partners.EmptyRef)    AS Partner,
	|		VALUE(Catalog.DocumentRegistryKeys.EmptyRef) AS Counterparty,
	|		CASE
	|			WHEN NOT VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|				THEN &Recipient
	|			ELSE &Sender
	|		END                                  AS StorageLocation,
	|		CASE
	|			WHEN VALUETYPE(&Recipient) = TYPE(Catalog.BusinessStructure)
	|				THEN &Recipient
	|			WHEN &EnteringPantry
	|				THEN &RecipientSDivision
	|			WHEN VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|				THEN &Sender
	|			WHEN &TransferFromPantry
	|				THEN &SenderSDivision
	|			ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|		END                                         AS Department,
	|		&EmployeeResponsible                                AS EmployeeResponsible,
	|		&Author                                        AS Author,
	|		CAST(&Comment AS STRING(100))        AS Comment,
	|		VALUE(Catalog.Currencies.EmptyRef)      AS Currency,
	|		0                                             AS Sum,
	|		&Status                                       AS Status,
	|		&Posted                                     AS Posted,
	|		&DeletionMark                              AS DeletionMark,
	|		TRUE                                        AS AdditionalRecord,
	|		CASE
	|			WHEN NOT VALUETYPE(&Sender) = TYPE(Catalog.BusinessStructure)
	|				THEN &SenderInformation
	|			ELSE &RecipientInformation
	|		END                                         AS More,
	|		&Period                                       AS SourceDocumentDate,
	|		&NumberForPrinting                                AS SourceDocumentNumber,
	|		&Patch                                  AS ReverseTransactionCorrection,
	|		&ReversedDocument                         AS ReversedDocument,
	|		&CorrectedDocument                         AS CorrectedDocument,
	|		MAX(
	|			ISNULL(GoodsTable.AssignmentRecipient.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		                                              AS LineOfBusiness,
	|		COUNT(
	|			DISTINCT ISNULL(GoodsTable.AssignmentRecipient.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		                                              AS NumberOfActivities
	|	FROM
	|		Document.MovementOfProductsAndMaterials AS DocumentData
	|		
	|		INNER JOIN Document.MovementOfProductsAndMaterials.InventoryKinds AS GoodsTable
	|		ON DocumentData.Ref = GoodsTable.Ref
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND &InternalSubcontracting
	|	
	|	GROUP BY
	|		DocumentData.Ref
	|	) AS TableDocumentRegistry
	|
	|GROUP BY
	|	TableDocumentRegistry.RefType,
	|	TableDocumentRegistry.Organization,
	|	TableDocumentRegistry.BusinessOperation,
	|	TableDocumentRegistry.Partner,
	|	TableDocumentRegistry.Counterparty,
	|	CASE
	|		WHEN TableDocumentRegistry.NumberOfActivities = 1
	|			THEN TableDocumentRegistry.LineOfBusiness
	|		ELSE UNDEFINED
	|	END,
	|	TableDocumentRegistry.Department,
	|	TableDocumentRegistry.StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate,
	|	TableDocumentRegistry.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	InitializeProductAnalysisKeys(Query);
	SetRequestParametersCurrencyCoefficients(Query);
		
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Organization     AS Organization,
	|	CatInventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	CatInventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner            AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute       AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey          AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	CASE
	|		WHEN &AnalyticalAccountingByProductsGroups
	|			THEN TableTypesOfStocks_.ProductsGroup
	|		ELSE VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|	END                                         AS ProductsGroup,
	|	CASE
	|		WHEN &AnalyticalAccountingByProductsGroups
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes.Products.AnalyticalGroup
	|		ELSE VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|	END                                         AS SemiFinishedProductGroup_,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityByGBRN,
	|	&BusinessOperation                        AS BusinessOperation,
	|	CASE
	|		WHEN ISNULL(TableTypesOfStocks_.AssignmentRecipient.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN CASE WHEN TableTypesOfStocks_.AssignmentRecipient.VATActivityType = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|					CASE WHEN TableTypesOfStocks_.ItemsLocationAttributes.Products.FEACNCode.Commodity
	|						THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|						ELSE VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
	|					END
	|			ELSE TableTypesOfStocks_.AssignmentRecipient.VATActivityType END
	|		ELSE &VATTaxation
	|	END 										  AS VATTaxation,
	|	CommitteeAnalytics.DimensionKey              AS CommitteeAnalytics,
	|	CASE WHEN VALUETYPE(CatInventoryKinds.GoodsOwner) = TYPE(Catalog.Companies)
	|		THEN AnalysisOfIntercampaniCalculations.DimensionKey
	|		ELSE AnalysisOfSettlementsWithCommittee.DimensionKey
	|	END                                         AS AccountingDimensionByPartners,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType      AS InventoryType,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute.InventoryType AS RecipientInventoryType,
	|	RecipientKeys.DimensionKey                 AS AnalysisOfAccountingForRecipientProducts,
	|	RecipientKeysWithoutAssignment.DimensionKey    AS AnalysisOfAccountingForRecipientProductsWithoutAssignment,
	|	CASE
	// tolling materials and semi-finished products are always on a separate accounting section
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider) THEN
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider) THEN
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	// commission goods are always on a separate accounting section
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	// accepted for storage with the right to sell on a separate accounting section
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell) THEN
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	// if we transfer from the warehouse
	|		WHEN NOT ISNULL(TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, TRUE) THEN
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	// if we transmit from a division
	|		ELSE
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|	END                                         AS AccountingSection,
	|	CASE
	// tolling materials and semi-finished products are always on a separate accounting section
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider) THEN
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider) THEN
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	// commission goods are always on a separate accounting section
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	// accepted for storage with the right to sell on a separate accounting section
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell) THEN
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	// if we transfer to the warehouse
	|		WHEN NOT ISNULL(RecipientKeys.StorageLocation.ShopFloorStockroom, TRUE) THEN
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	// if we transfer it to the division
	|		ELSE
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|	END                                         AS RecipientAccountingSection,
	|	CASE
	|		WHEN TRUE
	|			THEN 0
	|	END AS Cost,
	|	CASE
	|		WHEN TRUE
	|			THEN 0
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN TRUE
	|			THEN 0
	|	END AS LocalCost,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN ISNULL(TableTypesOfStocks_.Sum, 0) * &ConversionRateToManCurrency
	|		ELSE
	|			0
	|	END AS CostMan,
	|	TableTypesOfStocks_.RowID        AS RowID,
	|	BusinessTransactionsSettings.Ref         AS BusinessTransactionSetting
	|
	|INTO TTTypesOfStocks
	|FROM
	|	Document.MovementOfProductsAndMaterials.InventoryKinds AS TableTypesOfStocks_
	|
	|	INNER JOIN
	|		Catalog.InventoryKinds AS CatInventoryKinds
	|	ON
	|		TableTypesOfStocks_.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|
	|		LEFT JOIN Document.ProductionStage2_2.ManufacturedProducts AS StageProducts
	|		ON TableTypesOfStocks_.ReferenceOrder = StageProducts.Ref
	|			AND TableTypesOfStocks_.RowCode = StageProducts.RowCode
	|	
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS CommitteeAnalytics
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = CommitteeAnalytics.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = CommitteeAnalytics.Characteristic
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeAnalytics.ProductCostElement
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeAnalytics.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeAnalytics.Series
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = CommitteeAnalytics.StorageLocation
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS RecipientKeys
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = RecipientKeys.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = RecipientKeys.Characteristic
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = RecipientKeys.ProductCostElement
	|		AND TableTypesOfStocks_.AssignmentRecipient = RecipientKeys.Purpose
	|		AND TableTypesOfStocks_.Series = RecipientKeys.Series
	|		AND &Recipient = RecipientKeys.StorageLocation
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS RecipientKeysWithoutAssignment
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = RecipientKeysWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = RecipientKeysWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = RecipientKeysWithoutAssignment.ProductCostElement
	|		AND VALUE(Catalog.Assignments.EmptyRef) = RecipientKeysWithoutAssignment.Purpose
	|		AND TableTypesOfStocks_.Series = RecipientKeysWithoutAssignment.Series
	|		AND &Recipient = RecipientKeysWithoutAssignment.StorageLocation
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfSettlementsWithCommittee
	|		ON AnalysisOfSettlementsWithCommittee.Organization = CatInventoryKinds.Organization
	|		AND AnalysisOfSettlementsWithCommittee.Partner = CatInventoryKinds.GoodsOwner
	|		AND AnalysisOfSettlementsWithCommittee.Counterparty = CatInventoryKinds.Counterparty
	|		AND AnalysisOfSettlementsWithCommittee.Contract = CatInventoryKinds.Contract
	|		AND AnalysisOfSettlementsWithCommittee.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfIntercampaniCalculations
	|		ON AnalysisOfIntercampaniCalculations.Organization = CatInventoryKinds.Organization
	|		AND AnalysisOfIntercampaniCalculations.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|		AND AnalysisOfIntercampaniCalculations.Counterparty = CatInventoryKinds.Counterparty
	|		AND AnalysisOfIntercampaniCalculations.Contract = CatInventoryKinds.Contract
	|		AND AnalysisOfIntercampaniCalculations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON &BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersSenderAndRecipientInformation(Query)
	
	If Query = Undefined
		Or (Query.Parameters.Property("SenderInformation")
				And Query.Parameters.Property("RecipientInformation")) Then
		
		Return;
		
	EndIf;
	
	If Query.Parameters.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
		Or Query.Parameters.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
		
		SenderInformation = ?(TypeOf( Query.Parameters.Sender) = Type("CatalogRef.BusinessStructure"),
									"vi = 'Chuyển hàng hóa từ đơn vị %1';
									|ru = 'Передача продукции из подразделения ""%1""';
									|en = 'Transfer products from the ""%1"" business unit';
									|it = 'Consegna dei prodotti dal reparto ""%1""';
									|pl = 'Przekazanie produkcji z działu ""%1""';
									|tr = 'İmal edilen ürünlerin ""%1"" departmandan transferi'",
									"vi = 'Chuyển hàng hóa từ kho tại xưởng ""%1""';
									|ru = 'Передача продукции из кладовой ""%1""';
									|en = 'Transfer products from the ""%1"" storeroom';
									|it = 'Consegna dei prodotti dal deposito ""%1""';
									|pl = 'Przekazanie produkcji z komórki ""%1""';
									|tr = 'İmal edilen ürünlerin ""%1"" ambarından transferi'"); // @NStr-2 @
		RecipientInformation  = "vi = 'Chuyển hàng hóa vào kho ""%1""';
								|ru = 'Передача продукции на склад ""%1""';
								|en = 'Transfer products to the ""%1"" warehouse';
								|it = 'Consegna dei prodotti al magazzino ""%1""';
								|pl = 'Przekazanie produkcji do magazynu ""%1""';
								|tr = 'İmal edilen ürünlerin ""%1"" ambarına transferi'"; // @NStr
		
	ElsIf Query.Parameters.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or Query.Parameters.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		
		SenderInformation = "vi = 'Chuyển nguyên vật liệu từ kho ""%1""';
							|ru = 'Передача материалов со склада ""%1""';
							|en = 'Transfer materials from the ""%1"" warehouse';
							|it = 'Consegna dei prodotti dal magazzino ""%1""';
							|pl = 'Przekazanie materiaów z magazynu ""%1""';
							|tr = 'Malzemelerin ""%1"" ambarından transferi'"; // @NStr
		RecipientInformation  = ?(TypeOf( Query.Parameters.Recipient) = Type("CatalogRef.BusinessStructure"),
									"vi = 'Chuyển nguyên vật liệu sang đơn vị ""%1""';
									|ru = 'Передача материалов в подразделение ""%1""';
									|en = 'Transfer materials to the ""%1"" business unit';
									|it = 'Consegna dei materiali al reparto ""%1""';
									|pl = 'Przekazanie materiałów do działu ""%1""';
									|tr = 'Malzemelerin ""%1"" departmana transferi'",
									"vi = 'Chuyển nguyên vật liệu vào kho ""%1""';
									|ru = 'Передача материалов в кладовую ""%1""';
									|en = 'Transfer materials to the ""%1"" storeroom';
									|it = 'Consegna dei materiali al deposito ""%1""';
									|pl = 'Przekazanie  materiałów do komórki ""%1""';
									|tr = 'Malzemelerin ""%1"" ambarına transferi'"); // @NStr-2 @
									
	ElsIf Query.Parameters.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
		Or Query.Parameters.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom Then
		
		SenderInformation = ?(TypeOf( Query.Parameters.Sender) = Type("CatalogRef.BusinessStructure"),
									"vi = 'Trả lại nguyên vật liệu từ bộ phận ""%1""';
									|ru = 'Возврат материалов из подразделения ""%1""';
									|en = 'Return materials from the ""%1"" business unit';
									|it = 'Reso dei materiali dal reparto ""%1""';
									|pl = 'Zwrot materiałów z działu ""%1""';
									|tr = 'Malzemelerin ""%1"" departmandan iadesi'",
									"vi = 'Trả lại nguyên vật liệu từ kho ""%1""';
									|ru = 'Возврат материалов из кладовой ""%1""';
									|en = 'Return materials from the ""%1"" storeroom';
									|it = 'Reso di materiali dal deposito ""%1""';
									|pl = 'Zwrot materiałów z komórki ""%1""';
									|tr = 'Malzemelerin ""%1"" ambarından iadesi'"); // @NStr-2 @
									
		RecipientInformation  = "vi = 'Trả nguyên vật liệu về kho ""%1""';
								|ru = 'Возврат материалов на склад ""%1""';
								|en = 'Return materials to the ""%1"" warehouse';
								|it = 'Reso di materiali al magazzino ""%1""';
								|pl = 'Zwrot materiałów do magazynu ""%1""';
								|tr = 'Malzemelerin ""%1"" ambarına iadesi'"; // @NStr
		
	ElsIf Query.Parameters.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts
		Or Query.Parameters.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
		
		SenderInformation = "vi = 'Chuyển từ kho tại xưởng ""%1""';
							|ru = 'Передача из кладовой ""%1""';
							|en = 'Transfer from the ""%1"" storeroom';
							|it = 'Consegna dal deposito ""%1""';
							|pl = 'Przekazanie z komórki ""%1""';
							|tr = '""%1"" ambarından transfer'"; // @NStr
		RecipientInformation  = "vi = 'Chuyển sang kho tại xưởng ""%1""';
								|ru = 'Передача в кладовую ""%1""';
								|en = 'Transfer to ""%1"" storeroom';
								|it = 'Consegna al deposito ""%1""';
								|pl = 'Przekazanie do komórki ""%1""';
								|tr = '""%1"" ambarına transfer'"; // @NStr
		
	Else
		
		SenderInformation = "%1";
		RecipientInformation  = "%1";
		
	EndIf; 
	
	SenderInformation = StrTemplate(SenderInformation, Query.Parameters.SenderPresentation);
	RecipientInformation  = StrTemplate(RecipientInformation,  Query.Parameters.RecipientPresentation);
	
	Query.SetParameter("SenderInformation", SenderInformation);
	Query.SetParameter("RecipientInformation", RecipientInformation);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Sender AS Warehouse,
		|	TabPart.AssignmentSender AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.MovementOfProductsAndMaterials.Goods AS TabPart
		|WHERE
		|	TabPart.RowCode = 0
		|	AND VALUETYPE(TabPart.Ref.Sender) = TYPE(Catalog.Warehouses)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
		// Arrival at an irregular warehouse or for old purposes.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Recipient AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	&ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	TabPart.Ref.ByReferences
		|	AND TabPart.RowCode <> 0 AS OnSchedule,
		|	TabPart.ReferenceOrder AS OrderInSchedule
		|FROM
		|	Document.MovementOfProductsAndMaterials.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.BusinessOperation IN(
		|			VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
		|			VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
		|			VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
		|			VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom),
		|			VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom),
		|			VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
		|			VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices))
		|		AND TabPart.Ref.Status = VALUE(Enum.StatusesOfProductsAndMaterialMovement.Accepted)
		|		
		|		AND (NOT TabPart.Ref.Recipient.UseWarehouseManagemantSystemForGoodsReceipt
		|			OR TabPart.Ref.Recipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt > TabPart.Ref.Date
		|			OR TabPart.Purpose.RecordsInWarehouseRegisters = FALSE)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
	QueryTextTabPart =
		// The reverse of the receipt order for the old appointments.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Recipient AS Warehouse,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	-TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.MovementOfProductsAndMaterials.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.BusinessOperation IN
		|		(VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
		|		VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
		|		VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
		|		VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom),
		|		VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom),
		|		VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
		|		VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices))
		|	AND TabPart.Ref.Status = VALUE(Enum.StatusesOfProductsAndMaterialMovement.Accepted)
		|	AND TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|	AND TabPart.Ref.Ref.Recipient.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND TabPart.Ref.Ref.Recipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Recipient AS Warehouse,
		|	CASE
		|		WHEN TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE TabPart.Purpose
		|	END AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	
		|	CASE
		|		WHEN TabPart.Ref.ByReferences
		|				AND TabPart.Ref.GoodsReceiptOption
		|					<> VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|			THEN TabPart.ReferenceOrder
		|		ELSE
		|			CASE
		|				WHEN TabPart.Ref.CorrectedDocument = VALUE(Document.MovementOfProductsAndMaterials.EmptyRef)
		|					THEN TabPart.Ref
		|				ELSE TabPart.Ref.CorrectedDocument
		|			END
		|	END AS OrderDocument,
		|	
		|	CASE
		|		WHEN TabPart.Ref.DateOfReceipt <> DATETIME(1, 1, 1)
		|			THEN TabPart.Ref.DateOfReceipt
		|		ELSE TabPart.Ref.Date
		|	END AS DateOfReceipt,
		|	
		|	TRUE AS AvailableForConsumption,
		|	TabPart.Ref.ByReferences
		|	AND TabPart.RowCode <> 0 AS OnSchedule,
		|	TabPart.ReferenceOrder AS OrderInSchedule,
		|	TabPart.Count AS QuantityInGraph
		|FROM
		|	Document.MovementOfProductsAndMaterials.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.BusinessOperation IN(
		|			VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
		|			VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
		|			VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
		|			VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom),
		|			VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom),
		|			VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
		|			VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices))
		|		AND (TabPart.Ref.Recipient.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND TabPart.Ref.Recipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|				AND (TabPart.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|					OR NOT TabPart.Ref.ByReferences
		|					OR TabPart.RowCode = 0)
		|			OR TabPart.Ref.Status = VALUE(Enum.StatusesOfProductsAndMaterialMovement.Shipped)
		|				AND(NOT TabPart.Ref.ByReferences
		|					OR TabPart.RowCode = 0))";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
EndProcedure

// End StandardSubsystems.ObjectsVersioning

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	
	If Query <> Undefined Then
		// There are no additional parameters.
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTypesOfStocks(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region Moving_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	TableTypesOfStocks_.Organization					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation			AS VATActivityType,
	|	DocumentTable.VATTaxation				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
	|			THEN DocumentTable.CompanyRecipient
	|		ELSE UNDEFINED
	|	END                                              		AS CorCompany,
	|	UNDEFINED 									   		AS CorLot,
	|	TableTypesOfStocks_.AnalysisOfAccountingForRecipientProducts AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			AND TableTypesOfStocks_.RecipientInventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|			OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
	|			THEN TableTypesOfStocks_.RecipientInventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END                                           		AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 					AS SalesOpportunity,
	|	&SenderSDivision 		AS Department,
	|	DocumentTable.EmployeeResponsible	AS Manager,
	|	CASE
	|		WHEN NOT TableTypesOfStocks_.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|		 AND DocumentTable.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|				VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom),
	|				VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
	|				VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom),
	|				VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
	|				VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices))
	|			THEN TableTypesOfStocks_.ProductsGroup
	|		WHEN NOT TableTypesOfStocks_.SemiFinishedProductGroup_ = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|		 AND DocumentTable.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom))
	|			THEN TableTypesOfStocks_.SemiFinishedProductGroup_
	|		ELSE UNDEFINED
	|	END                           AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.Cost            AS Cost,
	|	TableTypesOfStocks_.CostExcludingVAT      AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost        AS LocalCost,
	|	TableTypesOfStocks_.CostMan         AS CostMan,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 				AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 				AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.MovementOfProductsAndMaterials AS DocumentTable
	|	LEFT JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Status = VALUE(Enum.StatusesOfProductsAndMaterialMovement.Accepted)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
		
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#Region ConductingRegulatedAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return MovementOfProductsAndMaterialsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
// 
// Returns:
// 	See MovementOfProductsAndMaterialsLocalization.RequestTextTTReflectedInLocalAccounting
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return MovementOfProductsAndMaterialsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Invoice") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"Invoice",
			NStr("vi = 'Xuất xưởng thành phẩm';
				|ru = 'Выпуск продукции';
				|en = 'Product release'; fa = 'تولید محصول';
				|it = 'Emissione di prodotti';
				|pl = 'Wyprodukowanie';
				|tr = 'Ürün sürümü'"),
			FormPrintedFormOfInvoice(ObjectsArray, PrintObjects));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "MaterialTransferToProduction") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"MaterialTransferToProduction",
			NStr("vi = 'Chuyển giao nguyên vật liệu vào sản xuất';
				|ru = 'Передача материалов в производство';
				|en = 'Transfer of materials to production'; fa = 'انتقال مواد به تولید';
				|it = 'Consegna materiali in produzione';
				|pl = 'Przekazanie materiałów do produkcji';
				|tr = 'Malzemelerin üretime aktarımı'"),
			PrintingTransferOfMaterialsToProduction(ObjectsArray, PrintObjects));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ReturnInvoice") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ReturnInvoice",
			NStr("vi = 'Ghi tăng hàng hóa';
				|ru = 'Оприходование товаров';
				|en = 'Receipt of goods'; fa = 'رسید کالا';
				|it = 'Registrazione delle merci in contabilità';
				|pl = 'Zaksięgowanie towarów';
				|tr = 'Ürünlerin girilmesi'"),
			FormPrintedFormReturn(ObjectsArray, PrintObjects));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "TransferNote") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"TransferNote",
			NStr("vi = 'Phiếu điều chuyển hàng hóa';
				|ru = 'Накладная на перемещение';
				|en = 'Goods transfer'; fa = 'انتقال کالا';
				|it = 'Bolla per trasferimento';
				|pl = 'Faktura na przemieszczenie';
				|tr = 'Taşıma senedi'"),
			FormPrintedFormOfInvoiceForMovementOfSemiFinishedProducts(ObjectsArray, PrintObjects));
		
	EndIf;
	
	MovementOfProductsAndMaterialsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

Function FormPrintedFormOfInvoice(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);

	Template = PrintManagement.PrintFormTemplate("Document.MovementOfProductsAndMaterials.PF_MXL_Invoice");
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Ref,
	|	DocumentData.Number,
	|	DocumentData.Date,
	|	DocumentData.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	DocumentData.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.Organization,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.Sender.Presentation AS DivisionRepresentation
	|FROM
	|	Document.MovementOfProductsAndMaterials AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|	AND DocumentData.BusinessOperation IN 
	|		(VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|		 VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom))
	|
	|ORDER BY
	|	DocumentData.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref                                AS Ref,
	|	GoodsTable.LineNumber                           AS LineNumber,
	|	GoodsTable.Products                          AS Products,
	|	GoodsTable.Characteristic                        AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	GoodsTable.Ref.Recipient                     AS Warehouse,
	|	GoodsTable.Ref.Sender                    AS Department,
	|	GoodsTable.Package                              AS Package,
	|	GoodsTable.NumberOfPackages                    AS Count,
	|	GoodsTable.Series                                 AS Series
	|
	|INTO TTProducts_1
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref IN(&DocumentsArray)
	|	AND GoodsTable.Ref.BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|		 VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom))
	|	AND NOT GoodsTable.BatchesIndicationStatus IN (4, 6, 8)
	|	AND GoodsTable.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Ref,
	|	MAX(GoodsTable.LineNumber),
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.Ref.Recipient,
	|	SeriesTable.Ref.Sender,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	|	SeriesTable.Count,
	|	SeriesTable.Series
	|FROM
	|	Document.MovementOfProductsAndMaterials.SetOfSeries AS SeriesTable
	|		INNER JOIN Document.MovementOfProductsAndMaterials.Goods AS GoodsTable
	|		ON SeriesTable.Ref = GoodsTable.Ref
	|			AND SeriesTable.Products = GoodsTable.Products
	|			AND SeriesTable.Characteristic = GoodsTable.Characteristic
	|			AND SeriesTable.Purpose = GoodsTable.Purpose
	|WHERE
	|	SeriesTable.Ref IN(&DocumentsArray)
	|	AND SeriesTable.Ref.BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|		 VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom))
	|	AND SeriesTable.Count <> 0
	|	AND GoodsTable.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	SeriesTable.Ref,
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	| 	SeriesTable.Purpose,
	|	SeriesTable.Series,
	|	SeriesTable.Count
	|
	|HAVING
	|	MAX(GoodsTable.BatchesIndicationStatus) IN (4, 6, 8)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.Products,
	|	GoodsTable.Products." + ?(NameOfCodeColumn = "", "Code", NameOfCodeColumn) + " AS CodeArticle,
	|	GoodsTable.Products.DescriptionFull AS Products,
	|	GoodsTable.Products.DescriptionFull AS ProductItemName,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Characteristic.Description AS CharacteristicName,
	|	GoodsTable.Series.Description AS SeriesName_,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure.Description
	|		ELSE GoodsTable.Package.Description
	|	END AS UnitOfMeasure,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Ref.BusinessOperation AS DirectionOfProductionIssue,
	|	GoodsTable.Ref.Recipient.Presentation AS RecipientPresentation1,
	|	CASE
	|		WHEN GoodsTable.Ref.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|			 VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom))
	|			THEN &RecipientTypeWarehouse
	|		ELSE &RecipientTypeDepartment
	|	END AS TypeRecipient
	|FROM
	|	TTProducts_1 AS GoodsTable
	|
	|ORDER BY
	|	GoodsTable.Ref,
	|	GoodsTable.LineNumber
	|TOTALS
	|	MAX(TypeRecipient)
	|BY
	|	Ref,
	|	RecipientPresentation1";

	Query.SetParameter("DocumentsArray",           ObjectsArray);
	Query.SetParameter("RecipientTypeWarehouse",         NStr("vi = 'Kho bãi';
																|ru = 'Склад';
																|en = 'Warehouse'; fa = 'Warehouse';
																|it = 'Magazzino';
																|pl = 'Magazyn';
																|tr = 'Ambar'", Common.DefaultLanguageCode()));
	Query.SetParameter("RecipientTypeDepartment", NStr("vi = 'Bộ phận';
														|ru = 'Подразделение';
														|en = 'Business unit'; fa = 'Business unit';
														|it = 'Reparto';
														|pl = 'Business unit';
														|tr = 'Departman'", Common.DefaultLanguageCode()));
	Query.SetParameter("DocumentsArray",           ObjectsArray);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.LeftMargin = 5;
	SpreadsheetDocument.RightMargin = 5;
	SpreadsheetDocument.HeaderSize = 0;
	SpreadsheetDocument.FooterSize = 0;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Landscape;
	
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ProductsRelease_Invoice";
	
	ResultsArray 		= Query.ExecuteBatch();
	PrintData			= ResultsArray[0].Select();
	SelectionByDocuments 	= ResultsArray[2].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		SelectionByRecipients = SelectionByDocuments.Select(QueryResultIteration.ByGroups);
		
		If SelectionByRecipients.Count() = 0 Then
			MessageText = NStr("vi = 'Trong chứng từ ""%1"" không có dữ liệu về các sản phẩm được sản xuất.';
								|ru = 'В документе ""%1"" отсутствуют данные о выпускаемой продукции.';
								|en = 'The document ""%1"" has no data on manufactured products.'; fa = 'The document ""%1"" has no data on manufactured products.';
								|it = 'Nel documento ""%1""mancano dari dei prodotti fabricati.';
								|pl = 'W dokumencie ""%1"" brakuje danych o wydawanej produkcji.';
								|tr = '""%1"" belgesinde imal edilecek ürünler hakkında veri bulunmamaktadır.'");
			MessageText = StrTemplate(MessageText, PrintData.Ref);
			CommonClientServer.MessageToUser(MessageText);
		EndIf;
		
		While SelectionByRecipients.Next() Do
			
			If Not FirstDocument Then
				SpreadsheetDocument.PutHorizontalPageBreak();
			EndIf;
			
			PageNumber = 1;
			
			FirstDocument    = False;
			RowNumberStart = SpreadsheetDocument.TableHeight + 1;
			
			// We output the general details of the header
			TemplateArea = Template.GetArea("Header");
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
			TemplateArea.Parameters.Fill(PrintData);
			TemplateArea.Parameters.RecipientPresentation1 = SelectionByRecipients.RecipientPresentation1;
			TemplateArea.Parameters.TypeRecipient = SelectionByRecipients.TypeRecipient;
			
			AreaParameters_ = New Structure;
			AreaParameters_.Insert(
				"TitleText",
				TMCommonUseClientServer.GenerateDocumentTitle(
					PrintData,
					NStr("vi = 'Xuất xưởng thành phẩm';
						|ru = 'Выпуск продукции';
						|en = 'Product release'; fa = 'تولید محصول';
						|it = 'Emissione di prodotti';
						|pl = 'Wyprodukowanie';
						|tr = 'Ürün sürümü'", Common.DefaultLanguageCode())));
			TemplateArea.Parameters.Fill(AreaParameters_);
			
			CompanyInformation = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, ?(PrintData.Patch, PrintData.DateOfDocumentBeingCorrected, PrintData.Date));
			TemplateArea.Parameters.RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(CompanyInformation);
			
			SpreadsheetDocument.Put(TemplateArea);
			
			// Creating an array to check the output
			ArrayOfOutputAreas = New Array;
			
			// We output the multiline part of the document
			OutputAdditionalColumn = NameOfCodeColumn <> "";
			
			TableHeaderArea = Template.GetArea(?(OutputAdditionalColumn, "TabHeaderWithCode", "TabHeader"));
			TemplateArea           = Template.GetArea(?(OutputAdditionalColumn, "StringWithCode", "String"));
			BasementArea_          = Template.GetArea("Footer");
			
			If OutputAdditionalColumn Then
				TableHeaderArea.Parameters.Column = PresentationOfCodesColumn;
			EndIf;
			
			LineProducts_ = SelectionByRecipients.Select();
			RowsCount = LineProducts_.Count();
			LineNumber = 0;
			ProductLineParameters = New Structure("LineNumber,ProductItemName");
			While LineProducts_.Next() Do
				
				LineNumber = LineNumber + 1;
				
				ProductLineParameters.LineNumber = LineNumber;
				ProductLineParameters.ProductItemName = ProductsClientServer.PresentationOfProductsForPrinting(
																LineProducts_.ProductItemName, 
																LineProducts_.CharacteristicName,,
																LineProducts_.SeriesName_,
																AdditionalParametersProductPresentation);
																
				TemplateArea.Parameters.Fill(LineProducts_);
				TemplateArea.Parameters.Fill(ProductLineParameters);
				
				If LineNumber = 1 Then
					
					TableHeaderArea.Parameters.PageNumber = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trang %1';
							|ru = 'Страница %1';
							|en = 'Page %1'; fa = 'Page %1';
							|it = 'Pagina %1';
							|pl = 'Strona %1';
							|tr = 'Sayfa %1'", Common.DefaultLanguageCode()), PageNumber); 
					SpreadsheetDocument.Put(TableHeaderArea);
					
				Else
					
					ArrayOfOutputAreas.Clear();
					ArrayOfOutputAreas.Add(TemplateArea);
					
					If LineNumber = RowsCount Then
						
						ArrayOfOutputAreas.Add(BasementArea_);
						
					EndIf;
					
					If LineNumber <> 1 And Not SpreadsheetDocument.CheckPut(ArrayOfOutputAreas) Then
						
						PageNumber = PageNumber + 1;
						SpreadsheetDocument.PutHorizontalPageBreak();
						TableHeaderArea.Parameters.PageNumber = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Trang %1';
								|ru = 'Страница %1';
								|en = 'Page %1'; fa = 'Page %1';
								|it = 'Pagina %1';
								|pl = 'Strona %1';
								|tr = 'Sayfa %1'", Common.DefaultLanguageCode()), PageNumber);
						SpreadsheetDocument.Put(TableHeaderArea);
						
					EndIf;
					
				EndIf;
				
				SpreadsheetDocument.Put(TemplateArea);
				
			EndDo;
			
			// Output the document's basement
			BasementArea_.Parameters.TotalString = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tổng số mục %1';
					|ru = 'Всего наименований %1';
					|en = 'Total items %1'; fa = 'Total items %1';
					|it = 'Totale articoli %1';
					|pl = 'Razem pozycji %1';
					|tr = 'Toplam tanım %1'", Common.DefaultLanguageCode()), LineProducts_.Count());
			
			SpreadsheetDocument.Put(BasementArea_);
			
			PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
			
		EndDo;
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function FormPrintedFormReturn(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	AdditionalColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	
	If ValueIsFilled(AdditionalColumn) Then
		OutputAdditionalColumn = True;
	Else
		OutputAdditionalColumn = False;
		AdditionalColumn = "Code";
	EndIf;

	Query = New Query;
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Number AS Number,
	|	DocumentTable.Date AS Date,
	|	DocumentTable.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	DocumentTable.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	DocumentTable.Recipient AS Warehouse,
	|	DocumentTable.Sender AS Department,
	|	DocumentTable.Organization AS Organization,
	|	PRESENTATION(DocumentTable.Recipient) AS WarehousePresentation,
	|	PRESENTATION(DocumentTable.Sender) AS DepartmentPresentation
	|FROM
	|	Document.MovementOfProductsAndMaterials AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN(&ObjectsArray)
	|	AND DocumentTable.BusinessOperation IN 
	|		(VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
	|		 VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom))
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Products.Code AS AdditionalColumn,
	|	GoodsTable.Products.DescriptionFull AS ProductsPresentation,
	|	GoodsTable.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|	&QueryTextUnitOfMeasurePresentation AS UnitOfMeasurePresentation,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.Count AS Count,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatus = 14
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	GoodsTable.Series.Presentation
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|	AND GoodsTable.Ref.BusinessOperation IN 
	|		(VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
	|		 VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom))
	|	AND NOT GoodsTable.BatchesIndicationStatus IN (4, 6, 8)
	|	AND GoodsTable.Ref IN(&ObjectsArray)
	|	AND GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Products.Code,
	|	GoodsTable.Products.DescriptionFull,
	|	GoodsTable.Characteristic.DescriptionFull,
	|	PRESENTATION(GoodsTable.Products.UnitOfMeasure),
	|	MAX(SeriesTable.Count),
	|	GoodsTable.Ref,
	|	MAX(SeriesTable.Count),
	|	SeriesTable.Series,
	|	SeriesTable.Series.Presentation
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS GoodsTable
	|		INNER JOIN Document.MovementOfProductsAndMaterials.SetOfSeries AS SeriesTable
	|		ON GoodsTable.Products = SeriesTable.Products
	|			AND GoodsTable.Characteristic = SeriesTable.Characteristic
	|			AND GoodsTable.Purpose = SeriesTable.Purpose
	|			AND GoodsTable.Ref = SeriesTable.Ref
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|	AND GoodsTable.Ref.BusinessOperation  IN 
	|		(VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
	|		 VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom))
	|	AND GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Products.Code,
	|	GoodsTable.Products.DescriptionFull,
	|	GoodsTable.Characteristic.DescriptionFull,
	|	SeriesTable.LineNumber,
	|	GoodsTable.Ref,
	|	SeriesTable.Series,
	|	SeriesTable.Series.Presentation,
	|	PRESENTATION(GoodsTable.Products.UnitOfMeasure)
	|
	|HAVING
	|	MAX(GoodsTable.BatchesIndicationStatus) IN (4, 6, 8)
	|
	|ORDER BY
	|	Ref
	|TOTALS BY
	|	Ref";
	
	If OutputAdditionalColumn And AdditionalColumn <> "Code" Then 
		QueryText = StrReplace(QueryText, "Products.Code", "Products." + AdditionalColumn);
	EndIf;
	
	QueryText = StrReplace(QueryText, "&QueryTextUnitOfMeasurePresentation",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description", "GoodsTable.Package", "GoodsTable.Products"));
			
	Query.Text = QueryText;
	
	DocumentAttributes = New Structure("Number, Date, NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected");
	DocumentSynonym = NStr("vi = 'Trả lại từ sản xuất';
							|ru = 'Возврат из производства';
							|en = 'Return from production'; fa = 'برگشت از تولید';
							|it = 'Reso dalla produzione';
							|pl = 'Zwrot z produkcji';
							|tr = 'Üretimden iade'", Common.DefaultLanguageCode());

	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_ReturnOfMaterialsFromProduction_ReturnFromProduction";
	
	Template = PrintManagement.PrintFormTemplate("Document.MovementOfProductsAndMaterials.PF_MXL_ReturnOfMaterialsFromProduction");
	
	If GetFunctionalOption("UseBusinessUnits") Then
		HeaderArea_ = Template.GetArea("Title");
	Else
		HeaderArea_ = Template.GetArea("TitleWithoutDivision");
	EndIf;
	
	HeaderArea_ = Template.GetArea("Title");

	If OutputAdditionalColumn Then
		Area_TableHeader        = Template.GetArea("TableHeader");
		AreaRow              = Template.GetArea("String");
		TableBasementArea       = Template.GetArea("TableFooter");
		Area_TableHeader.Parameters.AdditionalColumn = PresentationOfCodesColumn;
	Else
		Area_TableHeader        = Template.GetArea("TableHeaderWithoutAdditionalColumn");
		AreaRow              = Template.GetArea("RowWithoutAdditionalColumn");	
		TableBasementArea       = Template.GetArea("TableBasementWithoutAdditionalColumn");
	EndIf;
	
	LabelArea = Template.GetArea("Signatures");
	AreaResults = Template.GetArea("Totals");
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	QueryResults = Query.ExecuteBatch();
	
	DocumentsSelection = QueryResults[0].Select();
	SelectionByTableParts = QueryResults[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	While DocumentsSelection.Next() Do
		
		If Not FirstDocument Then
			TabDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		RowNumberStart = TabDocument.TableHeight + 1;
		
		// We display the header of the invoice.
		FillPropertyValues(DocumentAttributes, DocumentsSelection);
		HeaderArea_.Parameters.Fill(DocumentsSelection);
		
		AreaParameters_ = New Structure;
		AreaParameters_.Insert(
			"TitleText",
			TMCommonUseClientServer.GenerateDocumentTitle(
				DocumentAttributes,
				DocumentSynonym));  
		NamesAsOfDate = CompaniesCached.NamesAsOfDate(DocumentsSelection.Organization, DocumentsSelection.Date);
		AreaParameters_.Insert("OrganizationPresentation", NamesAsOfDate.AbbreviatedDescription);
		HeaderArea_.Parameters.Fill(AreaParameters_);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(TabDocument, Template, HeaderArea_, DocumentsSelection.Ref);
		TabDocument.Put(HeaderArea_);
		// Output of the header.
		
		TabDocument.Put(Area_TableHeader);
		
		TotalItems_1 = 0;
		
		// Output of strings.
		SelectionByTableParts.FindNext(New Structure("Ref",DocumentsSelection.Ref));
		
		SelectionByLines = SelectionByTableParts.Select();
		
		While SelectionByLines.Next() Do
			
			// Nomenclature.
			AreaRow.Parameters.OwnGoodsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
				SelectionByLines.ProductsPresentation,
				SelectionByLines.CharacteristicPresentation,
				,
				SelectionByLines.SeriesPresentation,
				AdditionalParametersProductPresentation);
			
			// Quantity data.
			AreaRow.Parameters.Fill(SelectionByLines);
			
			TotalItems_1 = TotalItems_1 + 1;
			
			AreaParameters_ = New Structure;
			AreaParameters_.Insert("LineNumber", TotalItems_1);
			AreaRow.Parameters.Fill(AreaParameters_);
			
			TabDocument.Put(AreaRow);
			
		EndDo;
		
		// Output of the basement.
		TabDocument.Put(TableBasementArea);
		
		TextOfResultingLine = NStr("vi = 'Số lượng các dòng là: %TotalItems_1%';
									|ru = 'Всего наименований %TotalItems_1%';
									|en = 'Total items %TotalItems_1%'; fa = 'Total items %TotalItems_1%';
									|it = 'Totale articoli %TotalItems_1%';
									|pl = 'Razem pozycji %TotalItems_1%';
									|tr = 'Toplam tanım %TotalItems_1%'", Common.DefaultLanguageCode());
		
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", TotalItems_1);
		
		AreaResults.Parameters.TotalString = TextOfResultingLine;
		
		TabDocument.Put(AreaResults);
		
		// Output of signatures.
		TabDocument.Put(LabelArea);
		
		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, DocumentsSelection.Ref);
		
	EndDo;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return TabDocument;
	
EndFunction

Function FormPrintedFormOfInvoiceForMovementOfSemiFinishedProducts(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	Column = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(Column);
	
	UseItemPackages = GetFunctionalOption("UseItemPackages");

	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_TransferOfSemiFinishedProducts_Invoice";
	Template = PrintManagement.PrintFormTemplate("Document.MovementOfProductsAndMaterials.PF_MXL_TransferNote");
	
	HeaderAreaMove         = Template.GetArea("TitleMove");
	HeaderAreaInternalTransfer  = Template.GetArea("TitleInternalTransfer");
	
	If OutputCodes Then
		AreaCodesHeader  = Template.GetArea("TableHeader|ColumnOfCodes");
		AreaCodesHeader.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		
		AreaCodesString = Template.GetArea("String|ColumnOfCodes");
		AreaCodesBasement = Template.GetArea("Footer|ColumnOfCodes");
	Else
		ScopeOfApplication_10 = Template.Area("OwnGoods");
		ScopeOfApplication_10.ColumnWidth = ScopeOfApplication_10.ColumnWidth + Template.Area("ColumnOfCodes").ColumnWidth;
	EndIf;
	
	If UseItemPackages Then
		PackagingAreaHeader  =  Template.GetArea("TableHeader|ColumnOfPackages");
		PackagingAreaString =  Template.GetArea("String|ColumnOfPackages");
		PackingAreaBasement =  Template.GetArea("Footer|ColumnOfPackages");
	Else
		ScopeOfApplication_10 = Template.Area("OwnGoods");
		ScopeOfApplication_10.ColumnWidth = ScopeOfApplication_10.ColumnWidth 
									  + Template.Area("ColumnOfPackagesQuantity").ColumnWidth
									  + Template.Area("ColumnOfPackagesPresentation").ColumnWidth;
	EndIf;
	
	AreaOfHeaderNumber = Template.GetArea("TableHeader|LineNumber");
	HeaderDataArea = Template.GetArea("TableHeader|OwnGoods");
	AreaEndOfLineHeader = Template.GetArea("TableHeader|EndOfRow");
	
	NumberAreaLine = Template.GetArea("String|LineNumber");
	DataAreaRow = Template.GetArea("String|OwnGoods");
	AreaEndOfLineString = Template.GetArea("String|EndOfRow");
	
	RoomAreaBasement = Template.GetArea("Footer|LineNumber");
	DataAreaBasement = Template.GetArea("Footer|OwnGoods");
	AreaEndOfLineBasement = Template.GetArea("Footer|EndOfRow");
	
	SignatureArea = Template.GetArea("Signatures");
	
	RequestByHeader = New Query;
	RequestByHeader.Text = 
	"SELECT
	|	DocumentTable.Ref                              AS Ref,
	|	DocumentTable.Number                               AS Number,
	|	DocumentTable.Date                                AS Date,
	|	DocumentTable.CorrectedDocument.Number          AS NumberOfDocumentBeingCorrected,
	|	DocumentTable.CorrectedDocument.Date           AS DateOfDocumentBeingCorrected,
	|	DocumentTable.Organization.Prefix                 AS Prefix,
	|	DocumentTable.BusinessOperation               AS BusinessOperation,
	|	DocumentTable.Sender.Presentation           AS SenderPresentation,
	|	DocumentTable.Recipient.Presentation            AS RecipientPresentation,
	|	CASE WHEN DocumentTable.Organization.AbbreviatedDescription = """" THEN
	|		DocumentTable.Organization.Description
	|	ELSE
	|		DocumentTable.Organization.AbbreviatedDescription
	|	END                                                  AS OrganizationPresentation,
	|	CASE WHEN DocumentTable.CompanyRecipient.AbbreviatedDescription = """" THEN
	|		DocumentTable.CompanyRecipient.Description
	|	ELSE
	|		DocumentTable.CompanyRecipient.AbbreviatedDescription
	|	END                                                  AS CompanyRecipientPresentation,
	|	CASE WHEN DocumentTable.Sender.UseItemsBatch
	|	 OR DocumentTable.Recipient.UseItemsBatch THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS UseItemsBatch
	|FROM
	|	Document.MovementOfProductsAndMaterials AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN(&DocumentsArray)
	|	AND DocumentTable.BusinessOperation IN 
	|		(VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
	|		 VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices))
	|
	|ORDER BY
	|	Ref,
	|	Date
	|TOTALS BY
	|	UseItemsBatch
	|";
	
	RequestByHeader.SetParameter("DocumentsArray", ObjectsArray);
	
	ObjectsTree = RequestByHeader.Execute().Unload(QueryResultIteration.ByGroups);
	
	FirstLineOfObjects = True;  // There can be a maximum of 2 lines in the object tree, this variable is used to 
									// determine that the second line has started to output the border separator
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	For Each UsingSeries In ObjectsTree.Rows Do
		
		RequestForProducts = New Query;
		RequestForProducts.SetParameter("ObjectsArray", UsingSeries.Rows.UnloadColumn("Ref"));
		
		If UsingSeries.UseItemsBatch Then
			
			QueryTextByGoods = 
			"SELECT
			|	GoodsTable.Ref AS Ref,
			|	GoodsTable.LineNumber AS LineNumber,
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	CASE
			|		WHEN GoodsTable.BatchesIndicationStatus IN(10, 14)
			|			THEN GoodsTable.Series
			|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
			|	END AS Series,
			|	GoodsTable.Package AS Package,
			|	GoodsTable.NumberOfPackages AS NumberOfPackages,
			|	GoodsTable.Count AS Count
			|INTO TableOfGoods
			|FROM
			|	Document.MovementOfProductsAndMaterials.Goods AS GoodsTable
			|WHERE
			|	GoodsTable.Ref IN(&ObjectsArray)
			|	AND NOT GoodsTable.BatchesIndicationStatus IN (2, 4, 6, 8)
			|
			|UNION ALL
			|
			|SELECT
			|	SeriesTable.Ref,
			|	MIN(GoodsTable.LineNumber),
			|	SeriesTable.Products,
			|	SeriesTable.Characteristic,
			|	SeriesTable.Series,
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
			|	SeriesTable.Count,
			|	SeriesTable.Count
			|FROM
			|	Document.MovementOfProductsAndMaterials.SetOfSeries AS SeriesTable
			|		INNER JOIN Document.MovementOfProductsAndMaterials.Goods AS GoodsTable
			|		ON SeriesTable.Ref = GoodsTable.Ref
			|			AND SeriesTable.Products = GoodsTable.Products
			|			AND SeriesTable.Characteristic = GoodsTable.Characteristic
			|WHERE
			|	SeriesTable.Ref IN(&ObjectsArray)
			|
			|GROUP BY
			|	SeriesTable.Ref,
			|	SeriesTable.Products,
			|	SeriesTable.Characteristic,
			|	SeriesTable.Series,
			|	SeriesTable.Count,
			|	SeriesTable.Count
			|
			|HAVING
			|	MAX(GoodsTable.BatchesIndicationStatus) IN (2, 4, 6, 8)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Ref,
			|	MIN(TableOfGoods.LineNumber) AS LineNumber,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN TableOfGoods.Products.UnitOfMeasure
			|		ELSE TableOfGoods.Package
			|	END AS Package,
			|	SUM(TableOfGoods.NumberOfPackages) AS NumberOfPackages,
			|	SUM(TableOfGoods.Count) AS Count,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN NULL
			|		ELSE TableOfGoods.Series
			|	END AS Series
			|INTO SummaryTableOfProducts
			|FROM
			|	TableOfGoods AS TableOfGoods
			|
			|GROUP BY
			|	TableOfGoods.Ref,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN TableOfGoods.Products.UnitOfMeasure
			|		ELSE TableOfGoods.Package
			|	END,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN NULL
			|		ELSE TableOfGoods.Series
			|	END
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	GoodsTable.Ref AS Ref,
			|	GoodsTable.LineNumber AS LineNumber,
			|	GoodsTable.Products AS OwnGoods,
			|	GoodsTable.Products.DescriptionFull AS ProductItemName,
			|	GoodsTable.Products.Code AS Code,
			|	GoodsTable.Products.SKU AS SKU,
			|	GoodsTable.Characteristic.DescriptionFull AS CharacteristicName,
			|	GoodsTable.Characteristic AS Characteristic,
			|	GoodsTable.Series AS Series,
			|	CASE
			|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|			THEN REFPRESENTATION(GoodsTable.Products.UnitOfMeasure)
			|		ELSE REFPRESENTATION(GoodsTable.Package)
			|	END AS PresentationOfPackingUnit,
			|	REFPRESENTATION(GoodsTable.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
			|	GoodsTable.NumberOfPackages AS NumberOfPackages,
			|	GoodsTable.Count AS Count,
			|	GoodsTable.Products.ProductKind.BatchUsageSettings AS BatchUsageSettings
			|FROM
			|	SummaryTableOfProducts AS GoodsTable
			|
			|ORDER BY
			|	Ref,
			|	LineNumber,
			|	OwnGoods,
			|	Characteristic
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Ref AS Ref,
			|	MIN(TableOfGoods.LineNumber) AS LineNumber,
			|	TableOfGoods.Products AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Series.Description AS BatchPresentation
			|FROM
			|	TableOfGoods AS TableOfGoods
			|WHERE
			|	TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|	AND NOT TableOfGoods.Series IS NULL 
			|
			|GROUP BY
			|	TableOfGoods.Ref,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	TableOfGoods.Series.Description
			|
			|ORDER BY
			|	Ref,
			|	LineNumber,
			|	Products,
			|	Characteristic,
			|	BatchPresentation";
			
			RequestForProducts.Text = QueryTextByGoods;
			QueryResult		 = RequestForProducts.ExecuteBatch();
			ProductSelection_1		 = QueryResult[2].Select(QueryResultIteration.ByGroups);
			SelectionBySeries 		 = QueryResult[3].Select();
			
		Else
			
			QueryTextByGoods = 
			"SELECT
			|	GoodsTable.Ref AS Ref,
			|	GoodsTable.Products AS OwnGoods,
			|	GoodsTable.Products.DescriptionFull AS ProductItemName,
			|	GoodsTable.Products.Code AS Code,
			|	GoodsTable.Products.SKU AS SKU,
			|	GoodsTable.Characteristic.DescriptionFull AS CharacteristicName,
			|	GoodsTable.Characteristic AS Characteristic,
			|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
			|	CASE
			|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|			THEN REFPRESENTATION(GoodsTable.Products.UnitOfMeasure)
			|		ELSE REFPRESENTATION(GoodsTable.Package)
			|	END AS PresentationOfPackingUnit,
			|	REFPRESENTATION(GoodsTable.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
			|	GoodsTable.NumberOfPackages AS NumberOfPackages,
			|	GoodsTable.Count AS Count,
			|	FALSE AS BatchUsageSettings,
			|	GoodsTable.LineNumber
			|FROM
			|	Document.MovementOfProductsAndMaterials.Goods AS GoodsTable
			|WHERE
			|	GoodsTable.Ref IN(&ObjectsArray)
			|
			|ORDER BY
			|	Ref,
			|	GoodsTable.LineNumber,
			|	OwnGoods,
			|	Characteristic";
			
			RequestForProducts.Text = QueryTextByGoods;
			ProductSelection_1 = RequestForProducts.Execute().Select();
			
		EndIf;
		
		FirstDocument = True;

		For Each Header In UsingSeries.Rows Do
			
			DocumentDetails = New Structure("Ref");
			FillPropertyValues(DocumentDetails, Header);
			
			RowNumberStart = SpreadsheetDocument.TableHeight + 1;
			If Not FirstDocument Or (FirstDocument And Not FirstLineOfObjects) Then
				SpreadsheetDocument.PutHorizontalPageBreak();
			EndIf;
			FirstDocument = False;
			
			// We display the header of the invoice
			If Header.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts Then

				TitleArea  = HeaderAreaMove;

			Else //The hat.Business Operation = Transfers.Economic operations.Relocation of half-factories between branches

				TitleArea = HeaderAreaInternalTransfer;

			EndIf;
			
			TitleArea.Parameters.Fill(Header);
			
			AreaParameters_ = New Structure;
			AreaParameters_.Insert(
				"TitleText",
				TMCommonUseClientServer.GenerateDocumentTitle(
					Header,
					NStr("vi = 'Phiếu điều chuyển hàng hóa';
						|ru = 'Накладная на перемещение';
						|en = 'Goods transfer'; fa = 'انتقال کالا';
						|it = 'Bolla per trasferimento';
						|pl = 'Faktura na przemieszczenie';
						|tr = 'Taşıma senedi'", Common.DefaultLanguageCode())));
			TitleArea.Parameters.Fill(AreaParameters_);
			
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TitleArea, DocumentDetails.Ref);
			SpreadsheetDocument.Put(TitleArea);
			
			SpreadsheetDocument.Put(AreaOfHeaderNumber);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodesHeader);
			EndIf;
			
			SpreadsheetDocument.Join(HeaderDataArea);
			
			If UseItemPackages Then
				SpreadsheetDocument.Join(PackagingAreaHeader);
			EndIf;
			
			SpreadsheetDocument.Join(AreaEndOfLineHeader);
			
			// The sample of goods
			
			LineNumber = 1;
			
			While ProductSelection_1.FindNext(New Structure("Ref", DocumentDetails.Ref)) Do
				
				AreaParameters_ = New Structure;
				AreaParameters_.Insert("LineNumber", LineNumber);
				NumberAreaLine.Parameters.Fill(AreaParameters_);
				
				SpreadsheetDocument.Put(NumberAreaLine);
				
				If OutputCodes Then
					AreaCodesString.Parameters.SKU = ProductSelection_1[Column];
					SpreadsheetDocument.Join(AreaCodesString);
				EndIf;
				
				If ProductSelection_1.BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
					
					TheStructureOfTheSearch = New Structure;
					TheStructureOfTheSearch.Insert("Ref", ProductSelection_1.Ref);
					TheStructureOfTheSearch.Insert("LineNumber", ProductSelection_1.LineNumber);
					TheStructureOfTheSearch.Insert("Products", ProductSelection_1.OwnGoods);
					TheStructureOfTheSearch.Insert("Characteristic", ProductSelection_1.Characteristic);
					
					SeriesString = "";
					While SelectionBySeries.FindNext(TheStructureOfTheSearch) Do
						SeriesString = SeriesString + SelectionBySeries.BatchPresentation + ", ";
					EndDo;
					
					If StrLen(SeriesString) <> 0 Then
						SeriesString = Left(SeriesString, StrLen(SeriesString) - 2);
					EndIf;
					
				Else
					
					SeriesString = ProductSelection_1.Series;
					
				EndIf;
				
				DataAreaRow.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
					TrimAll(ProductSelection_1.ProductItemName),
					TrimAll(ProductSelection_1.CharacteristicName),
					, // Package
					TrimAll(SeriesString),
					AdditionalParametersProductPresentation);
				
				SpreadsheetDocument.Join(DataAreaRow);
				
				If UseItemPackages Then
					PackagingAreaString.Parameters.Fill(ProductSelection_1);
					SpreadsheetDocument.Join(PackagingAreaString);
				EndIf;
				
				AreaEndOfLineString.Parameters.Fill(ProductSelection_1);
				SpreadsheetDocument.Join(AreaEndOfLineString);
				
				LineNumber = LineNumber + 1;
				
			EndDo;
			
			SpreadsheetDocument.Put(RoomAreaBasement);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodesBasement);
			EndIf;
			
			SpreadsheetDocument.Join(DataAreaBasement);
			
			If UseItemPackages Then
				SpreadsheetDocument.Join(PackingAreaBasement);
			EndIf;
			
			SpreadsheetDocument.Join(AreaEndOfLineBasement);
			
			// Print signatures.
			SpreadsheetDocument.Put(SignatureArea);
			
			PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, DocumentDetails.Ref);
			
		EndDo;
		
		FirstLineOfObjects = False;
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction

Function PrintingTransferOfMaterialsToProduction(ObjectsArray, PrintObjects)

	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	AdditionalColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputAdditionalColumn = ValueIsFilled(AdditionalColumn);

	Query = New Query;
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Text =
	"SELECT
	|	DocumentTable.Ref                           AS Ref,
	|	DocumentTable.Number                            AS Number,
	|	DocumentTable.Date                             AS Date,
	|	DocumentTable.CorrectedDocument.Number       AS NumberOfDocumentBeingCorrected,
	|	DocumentTable.CorrectedDocument.Date        AS DateOfDocumentBeingCorrected,
	|	REFPRESENTATION(DocumentTable.Sender) AS Warehouse,
	|	REFPRESENTATION(DocumentTable.Recipient)  AS Department
	|FROM
	|	Document.MovementOfProductsAndMaterials AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN(&ObjectsArray)
	|	AND DocumentTable.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|		VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
	|
	|GROUP BY
	|	DocumentTable.Ref,
	|	DocumentTable.Number,
	|	DocumentTable.Date,
	|	DocumentTable.Sender,
	|	DocumentTable.Recipient,
	|	DocumentTable.CorrectedDocument
	|
	// Sorting must match the query by row
	|ORDER BY
	|	Date,
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// We will get the line numbers for the correct order in the printed forms.
	|SELECT
	|	GoodsTable.Ref                     AS Ref,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.Package                   AS Package,
	|	MIN(GoodsTable.LineNumber)       AS LineNumber
	|INTO WLineNumbers
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|	AND GoodsTable.Ref.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|		VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
	|	AND GoodsTable.Ref.InternalSubcontracting
	|	AND GoodsTable.Ref.PackagingUnitsInInventoryOwnerAttributes
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.Package
	|
	|INDEX BY
	|	Ref,
	|	ItemsLocationAttributes,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref.Date                                 AS Date,
	|	GoodsTable.Ref                                      AS Ref,
	|	REFPRESENTATION(GoodsTable.InventoryOwnerAttribute.Organization) AS Organization,
	|	GoodsTable.InventoryOwnerAttribute.Organization.Prefix              AS Prefix,
	|	ISNULL(WLineNumbers.LineNumber, GoodsTable.LineNumber) AS LineNumber,
	|	&AdditionalColumnKey,
	|	GoodsTable.ItemsLocationAttributes.Products.DescriptionFull   AS Products,
	|	GoodsTable.ItemsLocationAttributes.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			REFPRESENTATION(GoodsTable.ItemsLocationAttributes.Products.UnitOfMeasure)
	|		ELSE 
	|			REFPRESENTATION(GoodsTable.Package)
	|	END                                                     AS Package,
	|	GoodsTable.NumberOfPackages                          AS Count
	|FROM
	|	Document.MovementOfProductsAndMaterials.InventoryKinds AS GoodsTable
	|	
	|	LEFT JOIN WLineNumbers AS WLineNumbers
	|	ON WLineNumbers.Ref = GoodsTable.Ref
	|	AND WLineNumbers.ItemsLocationAttributes = GoodsTable.ItemsLocationAttributes
	|	AND WLineNumbers.Package = GoodsTable.Package
	|	
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|	AND GoodsTable.Ref.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|		VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
	|	AND GoodsTable.Ref.InternalSubcontracting
	|	AND GoodsTable.Ref.PackagingUnitsInInventoryOwnerAttributes
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref.Date                                 AS Date,
	|	GoodsTable.Ref                                      AS Ref,
	|	REFPRESENTATION(GoodsTable.Ref.Organization)     AS Organization,
	|	GoodsTable.Ref.Organization.Prefix                  AS Prefix,
	|	GoodsTable.LineNumber                                 AS LineNumber,
	|	&AdditionalColumnItem,
	|	GoodsTable.Products.DescriptionFull   AS Products,
	|	GoodsTable.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			REFPRESENTATION(GoodsTable.Products.UnitOfMeasure)
	|		ELSE 
	|			REFPRESENTATION(GoodsTable.Package)
	|	END                                                     AS Package,
	|	GoodsTable.NumberOfPackages                          AS Count
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|	AND GoodsTable.Ref.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|		VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
	|	AND (NOT GoodsTable.Ref.PackagingUnitsInInventoryOwnerAttributes
	|		OR NOT GoodsTable.Ref.InternalSubcontracting
	|		OR FALSE)
	|
	// Sorting must match the request for documents
	|ORDER BY
	|	Date,
	|	Ref,
	|	LineNumber
	|
	|TOTALS
	|	MAX(Prefix)
	|BY
	|	Ref,
	|	Organization
	|";
	
	If OutputAdditionalColumn Then
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnKey,", "GoodsTable.ItemsLocationAttributes.Products." + AdditionalColumn +" AS AdditionalColumn,");
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnItem,", "GoodsTable.Products." + AdditionalColumn +" AS AdditionalColumn,");
	Else
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnKey,", "");
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnItem,", "");
	EndIf;
	
	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_MaterialTransferToProduction";

	DocumentAttributes = New Structure("Number, Date, Prefix, Warehouse, Department, DateOfDocumentBeingCorrected, NumberOfDocumentBeingCorrected");
	DocumentSynonym = String(Enums.BusinessTransactions.MaterialTransferToProduction);

	Template =
		PrintManagement.PrintFormTemplate("Document.MovementOfProductsAndMaterials.PF_MXL_MaterialTransferToProduction");
	
	HeaderArea_ = Template.GetArea("Title");
	LabelArea   = Template.GetArea("Signatures");
	If OutputAdditionalColumn Then
		AreaRow       = Template.GetArea("RowColumn");
		Area_TableHeader = Template.GetArea("TableHeaderAdditionalColumn");
	Else
		AreaRow       = Template.GetArea("String");
		Area_TableHeader = Template.GetArea("TableHeader");
	EndIf;
	
	ResultsArray 		= Query.ExecuteBatch();
	PrintData			= ResultsArray[0].Select();
	SelectionByDocuments 	= ResultsArray[2].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		SelectionByOrganization_ = SelectionByDocuments.Select(QueryResultIteration.ByGroups);
		While SelectionByOrganization_.Next() Do
			
			RowNumberStart = TabDocument.TableHeight + 1;
			
			If Not FirstDocument Then
				TabDocument.PutHorizontalPageBreak();
			EndIf;
			FirstDocument = False;
			
			// Header output.
			FillPropertyValues(DocumentAttributes, PrintData);
			HeaderArea_.Parameters.Fill(DocumentAttributes);
			HeaderArea_.Parameters.Fill(SelectionByOrganization_);
			
			AreaParameters_ = New Structure;
			AreaParameters_.Insert(
				"TitleText",
				TMCommonUseClientServer.GenerateDocumentTitle(
					DocumentAttributes,
					DocumentSynonym));
			AreaParameters_.Insert("Organization", SelectionByOrganization_.Organization);
			
			HeaderArea_.Parameters.Fill(AreaParameters_);
			
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
				TabDocument,
				Template,
				HeaderArea_,
				SelectionByDocuments.Ref);
			
			TabDocument.Put(HeaderArea_);
			
			// Output of the header.
			If OutputAdditionalColumn Then
				Area_TableHeader.Parameters.AdditionalColumn = PresentationOfCodesColumn;
			EndIf;
			TabDocument.Put(Area_TableHeader);
			
			// Output of document lines.
			
			RowIndex = 1;
			StringSelection = SelectionByOrganization_.Select();
			While StringSelection.Next() Do
				
				AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
				
				AreaRow.Parameters.Fill(StringSelection);
				
				AreaRow.Parameters.Products = ProductsClientServer.PresentationOfProductsForPrinting(
					StringSelection.Products,
					StringSelection.Characteristic,
					,
					,
					AdditionalParametersProductPresentation);
				
				AreaRow.Parameters.LineNumber = RowIndex;
				
				TabDocument.Put(AreaRow);
				
				RowIndex = RowIndex + 1;
				
			EndDo;
			
			// Output of the basement.
			TabDocument.Put(LabelArea);

			PrintManagement.SetDocumentPrintArea(
				TabDocument,
				RowNumberStart,
				PrintObjects,
				SelectionByDocuments.Ref);
			
		EndDo;
	EndDo;
	
	Return TabDocument;
	
EndFunction

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// 
// Parameters:
// 	ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Document.MovementOfProductsAndMaterials.Form.Workplace";
	
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("Insert", Metadata.Documents.MovementOfProductsAndMaterials))
		And GetFunctionalOption("UseProductionManagement2_2");
		
	If Not Enabled Then
		Return;
	EndIf;
	
	FilterBusinessTransactions = New ValueList;
	FilterBusinessTransactions.Add(Enums.BusinessTransactions.TransferOfMaterialsToStoreroom);
	FilterBusinessTransactions.Add(Enums.BusinessTransactions.MaterialTransferToProduction);
	FilterDocumentTypes = New ValueList;
	FullNames = New Array;
	FullNames.Add(Metadata.Documents.MovementOfProductsAndMaterials.FullName());
	FilterDocumentTypes.Add(Common.MetadataObjectIDs(FullNames)[FullNames[0]]);
	
	TransferMaterialsForRegistration = NumberOfLinesForLayout(FilterBusinessTransactions.UnloadValues());
	
	CaseFileID = "TransferOfMaterialsToProduction22";
	If GetFunctionalOption("EnabledOnlyProductionManagement21And22") Then
		UserTaskPresentation = NStr("vi = 'Chuyển nguyên liệu sang sản xuất 2.2';
									|ru = 'Передачи материалов в производство 2.2';
									|en = 'Transfer materials to production 2.2'; fa = 'Transfer materials to production 2.2';
									|it = 'Consegne materiali alla produzione 2.2';
									|pl = 'Przekazanie materiałów do produkcji 2.2';
									|tr = 'Malzemelerin 2.2 üretime transferleri'");
	Else
		UserTaskPresentation = NStr("vi = 'Chuyển nguyên liệu sang sản xuất';
									|ru = 'Передачи материалов в производство';
									|en = 'Transfer materials to production'; fa = 'انتقال مواد به تولید';
									|it = 'Consegne materiali alla produzione';
									|pl = 'Przekazania materiałów do produkcji';
									|tr = 'Malzemelerin üretime transferleri'");
	EndIf;
	
	// Filling out cases.
	// TransmisSionmateriALsproduction
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = CaseFileID;
	UserTaskParent.Presentation  = UserTaskPresentation;
	UserTaskParent.HasToDoItems       = TransferMaterialsForRegistration > 0;
	UserTaskParent.Owner       = Metadata.Subsystems.Production;

	FilterParameters = New Structure;
	FilterParameters.Insert("FilterBusinessTransactions", FilterBusinessTransactions);
	FilterParameters.Insert("FilterDocumentTypes", FilterDocumentTypes);
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", FilterParameters);
	FormParameters.Insert("FormAssignmentKey", "ToDoList");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "TransferOfMaterialsToProduction2_2CDesign";
	ToDoItem.HasToDoItems       = TransferMaterialsForRegistration > 0;
	ToDoItem.Presentation  = NStr("vi = 'Chuyển chứng từ đăng ký';
									|ru = 'Передачи материалов к оформлению';
									|en = 'Transfer materials for registration'; fa = 'Transfer materials for registration';
									|it = 'Consegne materiali per formalizzazione';
									|pl = 'Przekazanie materiałów do rejestracji';
									|tr = 'Malzemelerin düzenlemeye transferleri'");
	ToDoItem.Count     = TransferMaterialsForRegistration;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = CaseFileID;
	
EndProcedure

Function NumberOfLinesForLayout(BsnsTransactions)
	
	FilterParameters = InvoicesServer.OrderSelectionParameters(,,, BsnsTransactions);
	
	Package = New Array;
	Selection = New Array;
	States1 = InvoicesServer.StatesByBusinessTransactions(BsnsTransactions);
	For Each KZ In States1 Do
		Package.Add(InvoicesServer.StateRequestText(KZ.Key, FilterParameters, KZ.Value));
		
		If KZ.Key = "StatesOfSpendingOrders" Then
			Selection.Add(
			"SELECT
			|	StatesOfSpendingOrders.ReferenceOrder AS ReferenceOrder,
			|	StatesOfSpendingOrders.Warehouse AS Sender,
			|	StatesOfSpendingOrders.Recipient AS Recipient,
			|	CASE
			|		WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
			|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
			|		WHEN TRUE
			|			THEN NULL
			|	END AS BusinessTransaction
			|FROM
			|	TTStateOfSpendingOrders AS StatesOfSpendingOrders");
		ElsIf KZ.Key = "StatesOfIncomingOrders" Then
			Selection.Add(
			"SELECT
			|	StatesOfIncomingOrders.ReferenceOrder AS ReferenceOrder,
			|	StatesOfIncomingOrders.Sender AS Sender,
			|	StatesOfIncomingOrders.Warehouse AS Recipient,
			|	StatesOfIncomingOrders.BusinessTransaction AS BusinessTransaction
			|FROM
			|	TTStateOfIncomingOrders AS StatesOfIncomingOrders");
		ElsIf KZ.Key = "StatesOfTransfersToProduction" Then
			Selection.Add(
			"SELECT
			|	StatesOfTransfersToProduction.ReferenceOrder AS ReferenceOrder,
			|	StatesOfTransfersToProduction.Warehouse AS Sender,
			|	StatesOfTransfersToProduction.Recipient AS Recipient,
			|	CASE
			|		WHEN VALUETYPE(StatesOfTransfersToProduction.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
			|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
			|		WHEN TRUE
			|			THEN NULL
			|	END AS BusinessTransaction
			|FROM
			|	TTStatesOfTransfersToProduction AS StatesOfTransfersToProduction");
		ElsIf KZ.Key = "StatesOfTransfersFromProduction" Then
			Selection.Add(
			"SELECT
			|	StatesOfTransfersFromProduction.ReferenceOrder AS ReferenceOrder,
			|	StatesOfTransfersFromProduction.Sender AS Sender,
			|	StatesOfTransfersFromProduction.Warehouse AS Recipient,
			|	StatesOfTransfersFromProduction.BusinessTransaction AS BusinessTransaction
			|FROM
			|	TTTransfersStateOfTransferFromProduction AS StatesOfTransfersFromProduction");
		EndIf;
		
	EndDo;
	
	Package.Add(
		StrReplace(
		"SELECT DISTINCT
		|	NestedQuery.ReferenceOrder AS ReferenceOrder,
		|	NestedQuery.Sender AS Sender,
		|	NestedQuery.Recipient AS Recipient,
		|	NestedQuery.BusinessTransaction AS BusinessTransaction
		|FROM
		|	QueryTextNested AS NestedQuery",
		"QueryTextNested", "(" + StrConcat(Selection, TMCommonUse.QuerySeparatorInJoin()) + ")"));
	
	Query = New Query(StrConcat(Package, Common.QueryBatchSeparator()));
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("BusinessTransaction", BsnsTransactions);
	
	Return Query.Execute().Select().Count();
	
EndFunction

#EndRegion

#Region Other

Function FieldsPresentation(Object) Export

	BusinessOperation = Object.BusinessOperation;
	
	FieldsPresentation = New Structure;
	FieldsPresentation.Insert("Organization", NStr("vi = 'Doanh nghiệp';
													|ru = 'Организация';
													|en = 'Company'; fa = 'Company';
													|it = 'Azienda';
													|pl = 'Company';
													|tr = 'İş yeri'"));
	
	If BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
		FieldsPresentation.Insert("Goods", NStr("vi = 'Sản phẩm';
												|ru = 'Продукция';
												|en = 'Manufactured products'; fa = 'محصولات تولیدی';
												|it = 'Prodotti';
												|pl = 'Wiersze pozycji';
												|tr = 'İmal edilen ürünler'"));
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
		FieldsPresentation.Insert("Goods", NStr("vi = 'Hàng hóa';
												|ru = 'Товары';
												|en = 'Goods'; fa = 'کالاها';
												|it = 'Merci';
												|pl = 'Wiersze pozycji';
												|tr = 'Ürünler'"));
		FieldsPresentation.Insert("Organization", NStr("vi = 'Doanh nghiệp-người gửi';
														|ru = 'Организация-отправитель';
														|en = 'Shipping company'; fa = 'شرکت ارسال‌کننده';
														|it = 'Azienda-mittente';
														|pl = 'Shipping company';
														|tr = 'Gönderici iş yeri'"));
	Else
		FieldsPresentation.Insert("Goods", NStr("vi = 'Nguyên vật liệu';
												|ru = 'Материалы';
												|en = 'Materials'; fa = 'مواد';
												|it = 'Materiali';
												|pl = 'Materials';
												|tr = 'Malzemeler'"));
	EndIf;

	If BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
		
		TypeRecipient = "Warehouse";
		SenderType = "Storeroom";
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
		
		TypeRecipient = "Warehouse";
		SenderType = "Department";
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
		
		TypeRecipient = "Warehouse";
		SenderType = "Department";
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom Then
		
		TypeRecipient = "Warehouse";
		SenderType = "Storeroom";
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction Then
		
		SenderType = "Warehouse";
		TypeRecipient  = "Department";
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		
		SenderType = "Warehouse";
		TypeRecipient  = "Storeroom";
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
		
		SenderType = "Storeroom";
		TypeRecipient  = "Storeroom";
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom Then
		RecipientHeader = NStr("vi = 'Kho bãi';
								|ru = 'Склад';
								|en = 'Warehouse'; fa = 'Warehouse';
								|it = 'Magazzino';
								|pl = 'Magazyn';
								|tr = 'Ambar'");
		If SenderType = "Storeroom" Then
			SenderHeader_ = NStr("vi = 'Kho trong phân xưởng';
								|ru = 'Цеховая кладовая';
								|en = 'Shop floor stockroom'; fa = 'انبار کارگاه';
								|it = 'Magazzino del reparto';
								|pl = 'Magazyn spiżarni';
								|tr = 'Atölye deposu'");
		Else	
			SenderHeader_ = NStr("vi = 'Bộ phận';
								|ru = 'Подразделение';
								|en = 'Business unit'; fa = 'Business unit';
								|it = 'Reparto';
								|pl = 'Dział';
								|tr = 'Departman'");
		EndIf; 
	ElsIf BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		SenderHeader_ = NStr("vi = 'Kho bãi';
							|ru = 'Склад';
							|en = 'Warehouse'; fa = 'Warehouse';
							|it = 'Magazzino';
							|pl = 'Magazyn';
							|tr = 'Ambar'");
		If TypeRecipient = "Storeroom" Then
			RecipientHeader = NStr("vi = 'Kho trong phân xưởng';
									|ru = 'Цеховая кладовая';
									|en = 'Shop floor stockroom'; fa = 'انبار کارگاه';
									|it = 'Magazzino del reparto';
									|pl = 'Magazyn spiżarni';
									|tr = 'Atölye deposu'");
		Else	
			RecipientHeader = NStr("vi = 'Bộ phận';
									|ru = 'Подразделение';
									|en = 'Business unit'; fa = 'Business unit';
									|it = 'Reparto';
									|pl = 'Dział';
									|tr = 'Departman'");
		EndIf; 
	ElsIf BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		SenderHeader_ = NStr("vi = 'Người gửi';
							|ru = 'Отправитель';
							|en = 'Sender'; fa = 'فرستنده';
							|it = 'Mittente';
							|pl = 'Nadawca';
							|tr = 'Gönderici'");
		RecipientHeader  = NStr("vi = 'Người nhận';
								|ru = 'Получатель';
								|en = 'Recipient'; fa = 'گیرنده';
								|it = 'Destinatario';
								|pl = 'Odbiorca';
								|tr = 'Alıcı'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
		SenderHeader_ = NStr("vi = 'Người gửi';
							|ru = 'Отправитель';
							|en = 'Sender'; fa = 'فرستنده';
							|it = 'Mittente';
							|pl = 'Nadawca';
							|tr = 'Gönderici'");
		RecipientHeader  = NStr("vi = 'Người nhận';
								|ru = 'Получатель';
								|en = 'Recipient'; fa = 'گیرنده';
								|it = 'Destinatario';
								|pl = 'Odbiorca';
								|tr = 'Alıcı'");
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
		
		If SenderType = "Storeroom" Then
			SenderHint = NStr("vi = 'Kho trong phân xưởng từ đó hàng hóa được chuyển.';
								|ru = 'Цеховая кладовая, из которой передается продукция.';
								|en = 'Shop floor stockroom from which products are transferred.'; fa = 'Shop floor stockroom from which products are transferred.';
								|it = 'Deposito di reparto dal quale il prodotto viene consegnato.';
								|pl = 'Magazyn spiżarni, z którego są przekazywane wiersze pozycji.';
								|tr = 'İmal edilen ürünlerin buradan transfer edildiği atölye deposu.'");
		Else
			SenderHint = NStr("vi = 'Bộ phận phát hành các sản phẩm.';
								|ru = 'Подразделение, которое выпустило продукцию.';
								|en = 'Business unit that released products.'; fa = 'Business unit that released products.';
								|it = 'Reparto che ha emesso i prodotti.';
								|pl = 'Dział, który wypuścił produkcję.';
								|tr = 'Ürün imal eden departman.'");
		EndIf; 
		
		RecipientHint = NStr("vi = 'Kho mà các hàng hóa phát hành được chuyển giao.';
							|ru = 'Склад, на который передается выпущенная продукция.';
							|en = 'Warehouse to which released products are transferred.'; fa = 'Warehouse to which released products are transferred.';
							|it = 'Magazzino al quale viene consegnato il prodotto fabbricato.';
							|pl = 'Magazyn do którego jest są przekazywane wypuszczone wiersze pozycji.';
							|tr = 'İmal edilen ürünlerin buraya transfer edildiği ambar.'");
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom Then
		
		If SenderType = "Storeroom" Then
			SenderHint = NStr("vi = 'Kho trong phân xưởng từ đó nguyên vật liệu được trả lại.';
								|ru = 'Цеховая кладовая, из которой возвращаются материалы.';
								|en = 'Shop floor stockroom from which materials are returned.'; fa = 'Shop floor stockroom from which materials are returned.';
								|it = 'Deposito di reparto dal quale i materiali vengono restituiti.';
								|pl = 'Magazyn spiżarni, z którego są zwracane materiały.';
								|tr = 'Malzemelerin buradan geri gönderildiği atölye deposu.'");
		Else
			SenderHint = NStr("vi = 'Các Bộ phận mà các chứng từ được trả lại.';
								|ru = 'Подразделение, с которого возвращаются материалы.';
								|en = 'Business unit from which materials are returned.'; fa = 'Business unit from which materials are returned.';
								|it = 'Reparto dal quale i materiali vengono restituiti.';
								|pl = 'Dział, z którego są zwracane materiały.';
								|tr = 'Malzemelerin geri gönderildiği departman.'");
		EndIf;
		
		RecipientHint = NStr("vi = 'Kho nhận nguyên vật liệu.';
							|ru = 'Склад, который получает материалы.';
							|en = 'Warehouse that receives materials.'; fa = 'Warehouse that receives materials.';
							|it = 'Magazzino che riceve materiali.';
							|pl = 'Magazyn, który otrzymuje materiały.';
							|tr = 'Malzemeleri alan ambar.'");
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		
		SenderHint = NStr("vi = 'Kho từ đó nguyên vật liệu được chuyển.';
							|ru = 'Склад, с которого передаются материалы.';
							|en = 'Warehouse from which materials are transferred.'; fa = 'Warehouse from which materials are transferred.';
							|it = 'Magazzino dal quale vengono trasferiti i materiali.';
							|pl = 'Magazyn, z którego są przekazywane materiały.';
							|tr = 'Malzemelerin transfer edildiği ambar.'");
		
		If TypeRecipient = "Storeroom" Then
			RecipientHint = NStr("vi = 'Kho trong phân xưởng, trong đó các nguyên vật liệu được chuyển giao.';
								|ru = 'Цеховая кладовая, в которую передаются материалы.';
								|en = 'Shop floor stockroom to which materials are transferred.'; fa = 'Shop floor stockroom to which materials are transferred.';
								|it = 'Il deposito di reparto al quale vengono trasferiti i materiali.';
								|pl = 'Magazyn spiżarni, do którego są przekazywane materiały.';
								|tr = 'Malzemelerin buraya transfer edildiği atölye deposu.'");
		Else
			RecipientHint = NStr("vi = 'Bộ phận nhận nguyên vật liệu.';
								|ru = 'Подразделение, которое получает материалы.';
								|en = 'Business unit that receives materials.'; fa = 'Business unit that receives materials.';
								|it = 'Il reparto che riceve materiali.';
								|pl = 'Dział, który otrzymuje materiały.';
								|tr = 'Malzemeleri alan departman.'");
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts Then
		
		SenderHint = NStr("vi = 'Kho trong phân xưởng từ đó nguyên vật liệu được chuyển.';
							|ru = 'Цеховая кладовая, из которой передаются материалы.';
							|en = 'Shop floor stockroom from which materials are transferred.'; fa = 'Shop floor stockroom from which materials are transferred.';
							|it = 'Deposito di reparto dal quale i materiali vengono consegnati.';
							|pl = 'Magazyn spiżarni, z którego są przekazywane materiały.';
							|tr = 'Malzemelerin buradan transfer edildiği atölye deposu.'");
		RecipientHint = NStr("vi = 'Kho trong phân xưởng, trong đó các nguyên vật liệu được chuyển giao.';
							|ru = 'Цеховая кладовая, в которую передаются материалы.';
							|en = 'Shop floor stockroom to which materials are transferred.'; fa = 'Shop floor stockroom to which materials are transferred.';
							|it = 'Il deposito di reparto al quale vengono trasferiti i materiali.';
							|pl = 'Magazyn spiżarni, do którego są przekazywane materiały.';
							|tr = 'Malzemelerin buraya transfer edildiği atölye deposu.'");
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
		
		SenderHint = NStr("vi = 'Phân xưởng xuất sản phẩm/vật tư.';
							|ru = 'Цеховая кладовая, из которой передаются продукция/материалы.';
							|en = 'Shop floor stockroom from which products/materials are transferred.'; fa = 'Shop floor stockroom from which products/materials are transferred.';
							|it = 'Deposito di reparto dal quale vengono consegnati i prodotti/materiali.';
							|pl = 'Magazyn spiżarni, z którego są przekazywane wiersze pozycji/materiały.';
							|tr = 'İmal edilen ürünlerin/malzemelerin buradan transfer edildiği atölye deposu.'");
		RecipientHint = NStr("vi = 'Phân xưởng nhận sản phẩm/vật tư.';
							|ru = 'Цеховая кладовая, в которую передаются продукция/материалы.';
							|en = 'Shop floor stockroom to which products/materials are transferred.'; fa = 'Shop floor stockroom to which products/materials are transferred.';
							|it = 'Il deposito di reparto al quale vengono trasferiti i prodotti/materiali.';
							|pl = 'Magazyn spiżarni, do którego są przekazywane wiersze pozycji/materiały.';
							|tr = 'İmal edilen ürünlerin/malzemelerin buraya transfer edildiği atölye deposu.'");
		
	EndIf;
	
	FieldsPresentation.Insert("Sender", SenderHeader_);
	FieldsPresentation.Insert("Recipient", RecipientHeader);
	FieldsPresentation.Insert("SenderHint", SenderHint);
	FieldsPresentation.Insert("RecipientHint", RecipientHint);
	FieldsPresentation.Insert("SenderType", SenderType);
	FieldsPresentation.Insert("TypeRecipient", TypeRecipient);
	
	Return FieldsPresentation;
	
EndFunction

Function EmptyOrderValues() Export
	
	EmptyOrderValues = New Array;
	EmptyOrderValues.Add(Undefined);
	EmptyOrderValues.Add(Documents.OrderOfMaterialsForProduction.EmptyRef());
	EmptyOrderValues.Add(Documents.ProductionStage2_2.EmptyRef());
	Return EmptyOrderValues;

EndFunction

// Unties goods from orders.
// 
// Parameters:
// 	Object - DocumentObject.MovementOfProductsAndMaterials - Document.
//
Procedure UntieFromOrders(Object) Export
	
	Object.ReferenceOrder = Undefined;
	Object.InternalSubcontracting = Undefined;
	Object.MaterialProviderCompany = Undefined;
	For Each CurRow In Object.Goods Do
		
		CurRow.RowCode = 0;
		CurRow.ReferenceOrder = Undefined;
		CurRow.Purpose = Undefined;
		CurRow.AssignmentSender = Undefined;
		
	EndDo;
	
	For Each CurRow In Object.SetOfSeries Do
		
		CurRow.Purpose = Undefined;
		CurRow.AssignmentSender = Undefined;
		
	EndDo;
	
EndProcedure

// Setting up conditional registration for a business transaction
// 
// Parameters:
// 	ConditionalAppearance - DataCompositionConditionalAppearance - conditional design
// 	NameOfOperationField - String - field name
// 	PathToPropsOperation - String - the path to the props
//
Procedure SetConditionalAppearanceOfOperation(ConditionalAppearance, NameOfOperationField = "BusinessOperation", PathToPropsOperation = "BusinessOperation") Export

	TransactionList = TransactionList();
	For Each NameAndPresentation In TransactionList Do
		
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(NameOfOperationField);

		ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToPropsOperation);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = NameAndPresentation.Value;
		
		ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NameAndPresentation.Presentation);
			
	EndDo; 
	
EndProcedure

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfProductsAndMaterialMovement[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	DocumentsTable.Status AS CurrentStatus,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.MovementOfProductsAndMaterials AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
// 	ValidationSample - QueryResultSelection - Current selection string
// 	NewStatus - EnumRef.StatusesOfProductsAndMaterialMovement - New status
// 	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
// 	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True;
	
EndFunction

Function CreateBasedOnCheckoutShip()
	
	QueryText =
		"SELECT TOP 1
		|	1
		|FROM
		|	Document.MovementOfProductsAndMaterials.Goods AS GoodsFromOrder
		|		INNER JOIN Document.MovementOfProductsAndMaterials AS DocumentTable
		|			ON DocumentTable.Ref = GoodsFromOrder.Ref
		|WHERE
		|	DocumentTable.ByReferences = FALSE
		|	AND DocumentTable.Ref IN(&ReferencesArrray)
		|	AND DocumentTable.Posted
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	1
		|FROM
		|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS GoodsFromOrder
		|WHERE
		|	GoodsFromOrder.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND GoodsFromOrder.Ref IN(&ReferencesArrray)
		|	AND GoodsFromOrder.Ref.Posted
		|	AND (NOT GoodsFromOrder.Warehouse.ShopFloorStockroom
		|		OR GoodsFromOrder.Warehouse.Department <> GoodsFromOrder.Department)
		|	AND NOT GoodsFromOrder.Canceled
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	1
		|FROM
		|	Document.OrderOfMaterialsForProduction.Goods AS GoodsFromOrder
		|WHERE
		|	GoodsFromOrder.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND GoodsFromOrder.Ref IN(&ReferencesArrray)
		|	AND NOT GoodsFromOrder.Canceled
		|	AND GoodsFromOrder.Ref.Posted
		|
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

Function CreationBasedOnCheckingForUnspentMaterials()
	
	QueryText =
		"SELECT TOP 1
		|	1
		|FROM
		|	Document.ProductionStage2_2.UnusedMaterials AS GoodsFromOrder
		|WHERE
		|	NOT GoodsFromOrder.ToExpenseAs
		|	AND GoodsFromOrder.Ref IN(&ReferencesArrray)
		|	AND GoodsFromOrder.Ref.Posted
		|	AND VALUETYPE(GoodsFromOrder.Recipient) = TYPE(Catalog.Warehouses)
		|	AND (NOT CAST(GoodsFromOrder.Recipient AS Catalog.Warehouses).ShopFloorStockroom
		|		OR CAST(GoodsFromOrder.Recipient AS Catalog.Warehouses).Department <> GoodsFromOrder.Department)
		|
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction
Function CreationBasedOnVerificationMade(PropertiesOfOrders)
	
	QueryText =
		"SELECT TOP 1
		|	1
		|FROM
		|	Document.MovementOfProductsAndMaterials.Goods AS GoodsFromOrder
		|		INNER JOIN Document.MovementOfProductsAndMaterials AS DocumentTable
		|			ON DocumentTable.Ref = GoodsFromOrder.Ref
		|WHERE
		|	DocumentTable.ByReferences = FALSE
		|	AND DocumentTable.Ref IN(&ReferencesArrray)
		|	AND DocumentTable.Posted
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	1
		|FROM
		|	Document.ProductionStage2_2.ManufacturedProducts AS GoodsFromOrder
		|WHERE
		|	GoodsFromOrder.Manufactured
		|	AND NOT GoodsFromOrder.Canceled
		|	AND NOT GoodsFromOrder.ToExpenseAs
		|	AND GoodsFromOrder.Ref IN(&ReferencesArrray)
		|	AND GoodsFromOrder.Ref.Posted
		|	AND &RowFilter
		|	AND VALUETYPE(GoodsFromOrder.Recipient) = TYPE(Catalog.Warehouses)
		|	AND (NOT CAST(GoodsFromOrder.Recipient AS Catalog.Warehouses).ShopFloorStockroom
		|		OR CAST(GoodsFromOrder.Recipient AS Catalog.Warehouses).Department <> GoodsFromOrder.Department)
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	1
		|FROM
		|	Document.ProductionStage2_2.SideAndIntermediateRelease AS GoodsFromOrder
		|WHERE
		|	GoodsFromOrder.Manufactured
		|	AND NOT GoodsFromOrder.Canceled
		|	AND NOT GoodsFromOrder.ToExpenseAs
		|	AND GoodsFromOrder.Ref IN(&ReferencesArrray)
		|	AND GoodsFromOrder.Ref.Posted
		|	AND &RowFilter
		|	AND VALUETYPE(GoodsFromOrder.Recipient) = TYPE(Catalog.Warehouses)
		|	AND (NOT CAST(GoodsFromOrder.Recipient AS Catalog.Warehouses).ShopFloorStockroom
		|		OR CAST(GoodsFromOrder.Recipient AS Catalog.Warehouses).Department <> GoodsFromOrder.Department)
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|";
	
	QueryText =
		StrReplace(
			QueryText,
			"&RowFilter",
			?(PropertiesOfOrders <> Undefined,
				"GoodsFromOrder.Recipient IN (&RowFilter)",
				"TRUE"));
	
	Return QueryText;
	
EndFunction

Function CreatingAndVerifyingHeaderDetails(BusinessOperation, PropertiesOfOrders)
	
	If BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		
		QueryTexts = New Array;
		
		If AccessRight("Read", Metadata.Documents.OrderOfMaterialsForProduction) Then
			QueryTexts.Add(
			"SELECT
			|	OrderDocument.Status                  AS Status,
			|	OrderDocument.Organization             AS Organization,
			|	OrderDocument.Warehouse                   AS Warehouse,
			|	CASE
			|		WHEN OrderDocument.ProductionManagement2_2
			|			THEN OrderDocument.ShopFloorStockroom
			|		ELSE OrderDocument.Department
			|	END                         AS Recipient,
			|	FALSE                          AS InternalSubcontracting,
			|	VALUE(Catalog.Companies.EmptyRef) AS MaterialProviderCompany,
			|	OrderDocument.Posted                AS Posted,
			|	OrderDocument.ConsumptionForActivity AS VATTaxation,
			|	OrderDocument.LineOfBusiness AS LineOfBusiness,
			|	UNDEFINED                  AS GoodsReceiptOption,
			|	CASE
			|		WHEN NOT OrderDocument.Status IN(
			|					VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion),
			|					VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.Closed))
			|			THEN TRUE
			|		ELSE FALSE
			|	END                         AS ThereAreErrorsStatus
			|FROM
			|	Document.OrderOfMaterialsForProduction AS OrderDocument
			|WHERE
			|	OrderDocument.Ref IN(&ReferencesArrray)");
		EndIf;
		If AccessRight("Read", Metadata.Documents.ProductionStage2_2) Then
			QueryTexts.Add(
			"SELECT
			|	OrderDocument.Ref.Status                AS Status,
			|	OrderDocument.Ref.Organization           AS Organization,
			|	OrderDocument.Warehouse	                       AS Warehouse,
			|	OrderDocument.Department                AS Recipient,
			|	OrderDocument.Ref.InternalSubcontracting AS InternalSubcontracting,
			|	OrderDocument.Ref.MaterialProviderCompany    AS MaterialProviderCompany,
			|	OrderDocument.Ref.Posted              AS Posted,
			|	OrderDocument.Ref.ProductionIssueForActivity AS VATTaxation,
			|	OrderDocument.Ref.LineOfBusiness AS LineOfBusiness,
			|	OrderDocument.Ref.GoodsReceiptOption AS GoodsReceiptOption,
			|	CASE
			|		WHEN NOT OrderDocument.Ref.Status IN(
			|					VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion),
			|					VALUE(Enum.StatusesOfProductionStages2_2.Initiated),
			|					VALUE(Enum.StatusesOfProductionStages2_2.Completed))
			|			THEN TRUE
			|		ELSE FALSE
			|	END                              AS ThereAreErrorsStatus
			|FROM
			|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS OrderDocument
			|WHERE
			|	OrderDocument.Ref IN(&ReferencesArrray)
			|	AND (NOT OrderDocument.Warehouse.ShopFloorStockroom
			|		OR OrderDocument.Warehouse.Department <> OrderDocument.Department)
			|	AND OrderDocument.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
			|	AND NOT OrderDocument.Canceled
			|	AND &RowFilter");
		EndIf;
		QueryText =
		"SELECT ALLOWED
		|	ISNULL(MAX(NOT Set.Posted), FALSE)         AS ThereAreErrorsPosted,
		|	ISNULL(MAX(Set.ThereAreErrorsStatus), FALSE)    AS ThereAreErrorsStatus,
		|	CASE WHEN COUNT(DISTINCT Set.Status) = 1
		|		THEN MIN(Set.Status) 
		|		ELSE UNDEFINED 
		|	END                                               AS OrderStatus_,
		|	MIN(Set.Organization)                          AS Organization,
		|	MIN(Set.Warehouse)                                AS Sender,
		|	MIN(Set.Recipient)                           AS Recipient,
		|	MIN(Set.InternalSubcontracting)                AS InternalSubcontracting,
		|	MIN(Set.MaterialProviderCompany)                   AS MaterialProviderCompany,
		|	MIN(Set.VATTaxation)                   AS VATTaxation,
		|	MIN(Set.LineOfBusiness)              AS LineOfBusiness,
		|	MIN(Set.GoodsReceiptOption)                AS GoodsReceiptOption,
		|	&BusinessOperation                              AS BusinessOperation,
		|	1                                                   AS DifferentOperations,
		|	COUNT(DISTINCT Set.Organization)             AS VariousOrganizations_,
		|	COUNT(DISTINCT Set.Warehouse)                   AS DifferentSenders,
		|	COUNT(DISTINCT Set.Recipient)              AS VariousRecipients,
		|	COUNT(DISTINCT Set.InternalSubcontracting)   AS VariousInternalProcessing,
		|	COUNT(DISTINCT Set.MaterialProviderCompany)      AS VariousGiverCompanies,
		|	COUNT(DISTINCT Set.GoodsReceiptOption)   AS VariousOptionsForAcceptingGoods
		|FROM
		|	&Set AS Set
		|;
		|
		|/////////////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText =
			StrReplace(
				QueryText,
				"&Set",
				"(" + StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin()) + ")");
		QueryText =
			StrReplace(
				QueryText,
				"&RowFilter",
				?(PropertiesOfOrders <> Undefined,
					"OrderDocument.Warehouse IN (&RowFilter)",
					"TRUE"));
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then

		QueryText =
		"SELECT ALLOWED
		|	ISNULL(MAX(NOT Set.Posted), FALSE) AS ThereAreErrorsPosted,
		|	ISNULL(MAX(CASE WHEN NOT Set.Status IN (
		|				VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion),
		|				VALUE(Enum.StatusesOfProductionStages2_2.Initiated),
		|				VALUE(Enum.StatusesOfProductionStages2_2.Completed))
		|			THEN TRUE
		|			ELSE FALSE 
		|		END), FALSE)                            AS ThereAreErrorsStatus,
		|	CASE WHEN COUNT(DISTINCT Set.Status) = 1
		|		THEN MIN(Set.Status) 
		|		ELSE UNDEFINED 
		|	END                                      AS OrderStatus_,
		|	MIN(Set.Organization)                 AS Organization,
		|	MIN(Set.LineOfBusiness)     AS LineOfBusiness,
		|	MIN(Set.Sender)                 AS Sender,
		|	MIN(Set.Recipient)                  AS Recipient,
		|	MIN(Set.InternalSubcontracting)       AS InternalSubcontracting,
		|	MIN(Set.MaterialProviderCompany)          AS MaterialProviderCompany,
		|	MIN(Set.GoodsReceiptOption)       AS GoodsReceiptOption,
		|	MIN(Set.VATTaxation)          AS VATTaxation,
		|
		|	&BusinessOperation                     AS BusinessOperation,
		|
		|	1                                          AS DifferentOperations,
		|	COUNT(DISTINCT Set.Organization)    AS VariousOrganizations_,
		|	COUNT(DISTINCT Set.Sender)    AS DifferentSenders,
		|	COUNT(DISTINCT Set.Recipient)     AS VariousRecipients,
		|	COUNT(DISTINCT Set.InternalSubcontracting) AS VariousInternalProcessing,
		|	COUNT(DISTINCT Set.MaterialProviderCompany)    AS VariousGiverCompanies,
		|	COUNT(DISTINCT Set.GoodsReceiptOption) AS VariousOptionsForAcceptingGoods
		|FROM
		|	(SELECT
		|		ProductionStage2_2.Posted                          AS Posted,
		|		ProductionStage2_2.Status                            AS Status,
		|		ProductionStage2_2.Organization                       AS Organization,
		|		ProductionStage2_2.LineOfBusiness           AS LineOfBusiness,
		|		ProductionStage2_2.ReferenceOrder.OrderForActivity AS VATTaxation,
		|		Set.Department                                   AS Sender,
		|		ProductionStage2_2.InternalSubcontracting             AS InternalSubcontracting,
		|		ProductionStage2_2.MaterialProviderCompany                AS MaterialProviderCompany,
		|		ProductionStage2_2.GoodsReceiptOption             AS GoodsReceiptOption,
		|		Set.Recipient                                      AS Recipient
		|	FROM
		|		Document.ProductionStage2_2.ManufacturedProducts AS Set
		|			INNER JOIN Document.ProductionStage2_2 AS ProductionStage2_2
		|			ON Set.Ref = ProductionStage2_2.Ref
		|	WHERE
		|		Set.Ref IN(&ReferencesArrray)
		|		AND Set.Manufactured
		|		AND NOT Set.Canceled
		|		AND NOT Set.ToExpenseAs
		|		AND VALUETYPE(Set.Recipient) = TYPE(Catalog.Warehouses)
		|		AND (NOT CAST(Set.Recipient AS Catalog.Warehouses).ShopFloorStockroom
		|			OR CAST(Set.Recipient AS Catalog.Warehouses).Department <> Set.Department)
		|		AND &RowFilter
		|
		|	UNION ALL
		|
		|	SELECT
		|		ProductionStage2_2.Posted                          AS Posted,
		|		ProductionStage2_2.Status                            AS Status,
		|		ProductionStage2_2.Organization                       AS Organization,
		|		ProductionStage2_2.LineOfBusiness           AS LineOfBusiness,
		|		ProductionStage2_2.ReferenceOrder.OrderForActivity AS VATTaxation,
		|		Set.Department                                   AS Sender,
		|		ProductionStage2_2.InternalSubcontracting             AS InternalSubcontracting,
		|		ProductionStage2_2.MaterialProviderCompany                AS MaterialProviderCompany,
		|		ProductionStage2_2.GoodsReceiptOption             AS GoodsReceiptOption,
		|		Set.Recipient                                      AS Recipient
		|	FROM
		|		Document.ProductionStage2_2.SideAndIntermediateRelease AS Set
		|			INNER JOIN Document.ProductionStage2_2 AS ProductionStage2_2
		|			ON Set.Ref = ProductionStage2_2.Ref
		|	WHERE
		|		Set.Ref IN(&ReferencesArrray)
		|		AND Set.Manufactured
		|		AND NOT Set.Canceled
		|		AND NOT Set.ToExpenseAs
		|		AND VALUETYPE(Set.Recipient) = TYPE(Catalog.Warehouses)
		|		AND (NOT CAST(Set.Recipient AS Catalog.Warehouses).ShopFloorStockroom
		|			OR CAST(Set.Recipient AS Catalog.Warehouses).Department <> Set.Department)
		|		AND &RowFilter
		|	) AS Set
		|
		|;
		|
		|/////////////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText =
			StrReplace(
				QueryText,
				"&RowFilter",
				?(PropertiesOfOrders <> Undefined,
					"Set.Recipient IN (&RowFilter)",
					"TRUE"));
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
		
		QueryTexts = New Array;
		
		If AccessRight("Read", Metadata.Documents.SalesOrder) Then
			QueryTexts.Add(
			"SELECT
			|	Set.Ref.Posted                AS Posted,
			|	Set.Ref.Status                  AS Status,
			|	Set.Ref.Organization             AS Organization,
			|	Set.Ref.LineOfBusiness AS LineOfBusiness,
			|	Set.Ref.VATTaxation      AS VATTaxation,
			|	Set.Ref.Department           AS Sender,
			|	UNDEFINED                         AS GoodsReceiptOption,
			|	Set.Warehouse                          AS Recipient
			|FROM
			|	Document.SalesOrder.Goods AS Set
			|WHERE
			|	Set.Ref IN(&ReferencesArrray)
			|	AND NOT Set.Canceled
			|	AND NOT Set.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
			|	AND &RowFilter");
		EndIf;
		
		
		If AccessRight("Read", Metadata.Documents.MaterialProviderOrder2_5) Then
			QueryTexts.Add(
			"SELECT
			|	Set.Ref.Posted                AS Posted,
			|	Set.Ref.Status                  AS Status,
			|	Set.Ref.Organization             AS Organization,
			|	Set.Ref.LineOfBusiness AS LineOfBusiness,
			|	Set.Ref.VATTaxation      AS VATTaxation,
			|	Set.Ref.Department           AS Sender,
			|	Set.Ref.GoodsReceiptOption   AS GoodsReceiptOption,
			|	Set.Warehouse                          AS Recipient
			|FROM
			|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS Set
			|WHERE
			|	Set.Ref IN(&ReferencesArrray)
			|	AND NOT Set.Canceled
			|	AND NOT Set.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
			|	AND &RowFilter");
		EndIf;
		QueryText =
		"SELECT ALLOWED
		|	ISNULL(MAX(NOT Set.Posted), FALSE) AS ThereAreErrorsPosted,
		|	FALSE                                       AS ThereAreErrorsStatus,
		|	TRUE                                     AS OrderStatus_,
		|	MIN(Set.Organization)                 AS Organization,
		|	MIN(Set.LineOfBusiness)     AS LineOfBusiness,
		|	MIN(Set.Sender)                 AS Sender,
		|	MIN(Set.Recipient)                  AS Recipient,
		|	MIN(Set.VATTaxation)          AS VATTaxation,
		|	FALSE                                       AS InternalSubcontracting,
		|	VALUE(Catalog.Companies.EmptyRef) AS MaterialProviderCompany,
		|	MIN(Set.GoodsReceiptOption)       AS GoodsReceiptOption,
		|
		|	&BusinessOperation                     AS BusinessOperation,
		|
		|	1                                          AS DifferentOperations,
		|	COUNT(DISTINCT Set.Organization)    AS VariousOrganizations_,
		|	COUNT(DISTINCT Set.Sender)    AS DifferentSenders,
		|	COUNT(DISTINCT Set.Recipient)     AS VariousRecipients,
		|	1                                          AS VariousInternalProcessing,
		|	1                                          AS VariousGiverCompanies,
		|	COUNT(DISTINCT Set.GoodsReceiptOption) AS VariousOptionsForAcceptingGoods
		|FROM
		|	&Set AS Set
		|
		|;
		|
		|/////////////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText =
			StrReplace(
				QueryText,
				"&Set",
				"(" + StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin()) + ")");
		
		QueryText =
			StrReplace(
				QueryText,
				"&RowFilter",
				?(PropertiesOfOrders <> Undefined,
					"Set.Warehouse IN (&RowFilter)",
					"TRUE"));
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
		
		QueryText =
		"SELECT ALLOWED
		|	ISNULL(MAX(NOT Set.Ref.Posted), FALSE) AS ThereAreErrorsPosted,
		|	ISNULL(MAX(CASE WHEN NOT Set.Ref.Status IN (
		|				VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion),
		|				VALUE(Enum.StatusesOfProductionStages2_2.Initiated),
		|				VALUE(Enum.StatusesOfProductionStages2_2.Completed))
		|			THEN TRUE
		|			ELSE FALSE 
		|		END), FALSE)                                  AS ThereAreErrorsStatus,
		|	CASE WHEN COUNT(DISTINCT Set.Ref.Status) = 1
		|		THEN MIN(Set.Ref.Status) 
		|		ELSE UNDEFINED 
		|	END                                             AS OrderStatus_,
		|	MIN(Set.Ref.Organization)                 AS Organization,
		|	MIN(Set.Ref.LineOfBusiness)     AS LineOfBusiness,
		|	MIN(Set.Department)                      AS Sender,
		|	MIN(Set.Recipient)                         AS Recipient,
		|	MIN(Set.Ref.InternalSubcontracting)       AS InternalSubcontracting,
		|	MIN(Set.Ref.MaterialProviderCompany)          AS MaterialProviderCompany,
		|	MIN(Set.Ref.GoodsReceiptOption)       AS GoodsReceiptOption,
		|
		|	&BusinessOperation                            AS BusinessOperation,
		|
		|	1                                                 AS DifferentOperations,
		|
		|	COUNT(DISTINCT Set.Ref.Organization)    AS VariousOrganizations_,
		|	COUNT(DISTINCT Set.Department)         AS DifferentSenders,
		|	COUNT(DISTINCT Set.Recipient)            AS VariousRecipients,
		|	COUNT(DISTINCT Set.Ref.InternalSubcontracting) AS VariousInternalProcessing,
		|	COUNT(DISTINCT Set.Ref.MaterialProviderCompany)    AS VariousGiverCompanies,
		|	COUNT(DISTINCT Set.Ref.GoodsReceiptOption) AS VariousOptionsForAcceptingGoods
		|FROM
		|	Document.ProductionStage2_2.UnusedMaterials AS Set
		|WHERE
		|	Set.Ref IN(&ReferencesArrray)
		|	AND NOT Set.ToExpenseAs
		|	AND VALUETYPE(Set.Recipient) = TYPE(Catalog.Warehouses)
		|	AND (NOT CAST(Set.Recipient AS Catalog.Warehouses).ShopFloorStockroom
		|		OR CAST(Set.Recipient AS Catalog.Warehouses).Department <> Set.Department)
		|	AND &RowFilter
		|;
		|
		|/////////////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText =
			StrReplace(
				QueryText,
				"&RowFilter",
				?(PropertiesOfOrders <> Undefined,
					"Set.Recipient IN (&RowFilter)",
					"TRUE"));
	EndIf;
	
	Return QueryText;
	
EndFunction

Function CreationBasedOnCheckingAvailabilityOfOrders()

	QueryText =
		"SELECT TOP 1
		|	1
		|FROM
		|	AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(,,,, DocumentShipments IN (&ReferencesArrray)) AS TableRevolutions
		|		INNER JOIN Catalog.Warehouses AS CatWarehouses
		|		ON CatWarehouses.Ref = TableRevolutions.Warehouse
		|WHERE
		|	TableRevolutions.ToShipReceipt > 0 AND(
		|		TableRevolutions.ToShipExpense > 0
		|		OR NOT CatWarehouses.UseWarehouseManagemantSystemForGoodsIssue
		|		OR CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue > &CurrentDayStart)";
	
	Return QueryText;
	
EndFunction

Function GoodsTransferredByBusinessTransactionToTemporaryStorage(ReferencesArrray, BusinessOperation)
	
	QueryText =
	"SELECT
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic
	|FROM
	|	Document.ProductionStage2_2.ManufacturedProducts AS Table
	|WHERE
	|	Table.Ref IN (&AnArrayOfOrders)
	|	AND VALUETYPE(Table.Recipient) = TYPE(Catalog.Warehouses)
	|	AND &BusinessTransaction = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|	AND NOT Table.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic
	|FROM
	|	Document.ProductionStage2_2.SideAndIntermediateRelease AS Table
	|WHERE
	|	Table.Ref IN (&AnArrayOfOrders)
	|	AND VALUETYPE(Table.Recipient) = TYPE(Catalog.Warehouses)
	|	AND &BusinessTransaction = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|	AND NOT Table.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Table
	|WHERE
	|	Table.Ref IN (&AnArrayOfOrders)
	|	AND &BusinessTransaction = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction)
	|	AND NOT Table.Canceled";
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("AnArrayOfOrders", ReferencesArrray);
	Query.SetParameter("BusinessTransaction",   BusinessOperation);
	
	RequiredGoods = Query.Execute().Unload();
	
	AddressInStorage = PutToTempStorage(RequiredGoods, New UUID());
	Return AddressInStorage;
	
EndFunction
Function GetSelectionSettings_(SelectionParameters_2) Export
	
	TableFilters  = New ValueTable;
	ReplacementParameters = New Structure;
	
	FilterByGoods = Undefined;
	SelectionParameters_2.Property("FilterByGoods", FilterByGoods);
	
	If ValueIsFilled(FilterByGoods) Then
		
		RefsTypes = Metadata.Documents.MovementOfProductsAndMaterials.TabularSections.Goods.Attributes.ReferenceOrder.Type.Types();
		RefsTypes.Add(Type("DocumentRef.MovementOfProductsAndMaterials"));
		
		TableFilters.Columns.Add("Ref",
			Documents.AllRefsType());
		
		TableFilters.Columns.Add("Products"   , 
			New TypeDescription("CatalogRef.Products"));
			
		TableFilters.Columns.Add("Characteristic" , 
			New TypeDescription("CatalogRef.ItemsCharacteristics"));
			
		For Each FilterElement In FilterByGoods Do
			
			DocumentSource = FilterElement.Key;
			
			FilterValues   = FilterElement.Value;
			For Each FilterValue In FilterValues Do
				
				SelectionTableRow = TableFilters.Add();
				SelectionTableRow.Ref = DocumentSource;
				FillPropertyValues(SelectionTableRow, FilterValue.Value);
				
			EndDo;
			
		EndDo;
		
		ReplacementParameters.Insert("ProductsField");//To replace in query texts
		
	EndIf;
	
	AdvancedFilter = ?(TableFilters.Columns.Count() = 0, 
		Undefined, New Structure("TableFilters, ReplacementParameters", TableFilters, ReplacementParameters));	
	
	Return AdvancedFilter;
	
EndFunction

Function QueryTextTableFilters(ReplacementParameters = Undefined)
	
	QueryText = 
	"SELECT
	|	&Fields AS Fields,
	|	TableFilters.Ref         AS Ref
	|INTO TableFilters
	|FROM
	|	&TableFilters AS TableFilters
	|
	|INDEX BY
	|	Fields,
	|	Ref
	|";
	
	If ReplacementParameters <> Undefined Then
		
		For Each ReplacementParameter In ReplacementParameters Do
			
			If ReplacementParameter.Key = "ProductsField" Then
				Continue;
			EndIf;
			
			QueryText = StrReplace(QueryText, ReplacementParameter.Key, ReplacementParameter.Value);
			
		EndDo;
		
	EndIf;
	
	InvoicesServer.ConfigureProductsField(
		QueryText, ReplacementParameters, "&Fields AS Fields,", "TableFilters",,, "Fields,");
	
	Return QueryText;
	
EndFunction

Procedure AddSelectionItem(Filter)
	
	TMCommonUse.AddSelectionItemToCollection(Filter, "Warehouse", "&Warehouse");
	
EndProcedure	

Procedure AddSelectionElementOperation(Filter)
	
	TMCommonUse.AddSelectionItemToCollection(Filter, "Operation", "&Operation");
	
EndProcedure	
Procedure AddRecipientSelectionElement(Filter)
	
	TMCommonUse.AddSelectionItemToCollection(Filter, "Recipient", "&Recipient");
	
EndProcedure	

Procedure AddSelectionElement(Filter, NameOrderField, RemainingGoodsByShelfLives = True)
	
	TMCommonUse.AddSelectionItemToCollection(
		Filter, 
		?(Not RemainingGoodsByShelfLives, NameOrderField , 
							 NameOrderField + ", Products, Characteristic"
		), 
		?(Not RemainingGoodsByShelfLives, "&References", 
							 "SELECT 
							 |	TableFilters.Ref		  AS Ref, 
							 |	TableFilters.Products   AS Products, 
							 |	TableFilters.Characteristic AS Characteristic 
							 |FROM 
							 |	TableFilters AS TableFilters"
		)
	);
	
EndProcedure	

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency,
		Undefined,
		Query.Parameters.Period,
		Query.Parameters.Organization);
	
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("ConversionRateToManCurrency", Coefficients.ConversionRateToManCurrency);
	
EndProcedure

#EndRegion

#Region FormationOfHyperlinkInJournalOfProductionDocuments

Function ThereAreDocumentsForRegistration(Parameters)
	
	FilterParameters = InvoicesServer.OrderSelectionParameters(Parameters.Organization, Parameters.Department,,
		Parameters.FilterBusinessTransactions, Parameters.Manager);
	
	States1 = InvoicesServer.StatesByBusinessTransactions(Parameters.FilterBusinessTransactions.UnloadValues());
	TablesNames = InvoicesServer.NamesOfTemporaryTablesByState();
	If Not ValueIsFilled(States1) Then
		Return False;
	EndIf;
	
	Package = New Array;
	Selection = New Array;
	Text = "SELECT
		|	ToRegister
		|FROM &TableName";
	For Each KZ In States1 Do
		Package.Add(InvoicesServer.StateRequestText(KZ.Key, FilterParameters, KZ.Value, True));
		Selection.Add(StrReplace(Text, "&TableName", TablesNames[KZ.Key]));
	EndDo;
	
	Package.Add(StrConcat(Selection, TMCommonUse.QuerySeparatorInJoin()));
	
	If ValueIsFilled(Parameters.Organization) Then
		CompaniesList = Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Parameters.Organization);
		CompaniesList.Add(Parameters.Organization);
	Else
		CompaniesList = New Array;
	EndIf;
	
	Query = New Query(StrConcat(Package, Common.QueryBatchSeparator()));
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Organization",       CompaniesList);
	Query.SetParameter("Department",     Parameters.Department);
	Query.SetParameter("Manager",          Parameters.Manager);
	Query.SetParameter("BusinessTransaction",       Parameters.FilterBusinessTransactions.UnloadValues());
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Returns the hyperlink text for the transition from the document log to the design workspace.
//
// Parameters:
//	Parameters - Structure - parameters for forming the hyperlink text.
// Returns:
// 	Undefined, FormattedString - the text of the hyperlink of the transition to the workplace of the registration of transfers.
//
Function CreateHyperlinkToDesign(Parameters) Export
	
	HaveReadRights = AccessRight("Read", Metadata.AccumulationRegisters.OrdersOfMaterialsForProduction)
		And AccessRight("Read", Metadata.AccumulationRegisters.ReferencesToTransferFromProduction)
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue)
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
	
	If Not HaveReadRights Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Hóa đơn';
						|ru = 'Накладные';
						|en = 'Invoices'; fa = 'فاکتورها';
						|it = 'Lettere di vettura';
						|pl = 'Listy przewozowe';
						|tr = 'İrsaliye'");
	HyperlinkAnchorText = "Document.MovementOfProductsAndMaterials.Form.Workplace";
	
	If ThereAreDocumentsForRegistration(Parameters) Then
		Return New FormattedString(HyperlinkText,,,, HyperlinkAnchorText);
	Else
		Return New FormattedString(HyperlinkText,, StyleColors.EmptyTableField,, HyperlinkAnchorText);
	EndIf;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

Function CreationBasedOnCheckingAvailabilityOfMaterialsAvailableForReturn()
	
	QueryText =
		"SELECT TOP 1
		|	1
		|FROM
		|	Document.MovementOfProductsAndMaterials.Goods AS GoodsFromOrder
		|WHERE
		|	GoodsFromOrder.Ref IN(&ReferencesArrray)
		|	AND GoodsFromOrder.Ref.Posted
		|	AND GoodsFromOrder.Ref.BusinessOperation IN
		|		(VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
		|		 VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|";
		
	Return QueryText;
	
EndFunction

// Generates a list of documents based on the passed parameters.
// 
// Parameters:
// 	Parameters - Structure - parameters for generating documents.
// Returns:
// 	Array - array of generated documents
//
Function DocumentsOnParameters(Parameters) Export
	
	DocumentsArray = New Array;
	
	Query = New Query;
	Query.SetParameter("ObjectsOfBases", Parameters.ObjectsOfBases);
	Query.TempTablesManager = New TempTablesManager();
	QueryTexts = New Array;
	If AccessRight("Read", Metadata.Documents.BackflushProduction) Then
		Query.Text =
		"SELECT
		|	GoodsTable.Ref                          AS Ref,
		|	GoodsTable.CostGroupNumber               AS CostGroupNumber,
		|	MAX(GoodsTable.InternalSubcontracting) AS InternalSubcontracting,
		|	MAX(GoodsTable.MaterialProviderCompany)    AS MaterialProviderCompany
		|INTO CostGroups
		|FROM
		|	Document.BackflushProduction AS DocumentAttributes
		|	
		|	INNER JOIN Document.BackflushProduction.ManufacturedProducts AS GoodsTable
		|	ON GoodsTable.Ref = DocumentAttributes.Ref
		|
		|WHERE
		|	DocumentAttributes.Ref IN(&ObjectsOfBases)
		|
		|GROUP BY
		|	GoodsTable.Ref,
		|	GoodsTable.CostGroupNumber
		|
		|INDEX BY
		|	Ref,
		|	CostGroupNumber
		|";
		Query.Execute();
		QueryTexts.Add("
		// ManufacturedProducts
		|SELECT
		|	BackflushProduction.Ref					AS DocumentBasis,
		|	CASE
		|		WHEN GoodsTable.InternalSubcontracting
		|			THEN GoodsTable.MaterialProviderCompany
		|		WHEN TRUE
		|			THEN BackflushProduction.Organization
		|	END											AS Organization,
		|	GoodsTable.Recipient						AS Sender,
		|	BackflushProduction.ProductionIssueForActivity		AS VATTaxation,
		|	BackflushProduction.LineOfBusiness	AS LineOfBusiness,
		|	GoodsTable.Products						AS Products,
		|	GoodsTable.Characteristic					AS Characteristic,
		|	GoodsTable.Series								AS Series,
		|	GoodsTable.Purpose						AS Purpose,
		|	GoodsTable.Purpose						AS AssignmentSender,
		|	GoodsTable.Package							AS Package,
		|	SUM(GoodsTable.Count)					AS Count,
		|	SUM(GoodsTable.NumberOfPackages)			AS NumberOfPackages,
		|	GoodsTable.BatchesIndicationStatus				AS BatchesIndicationStatus,
		|	GoodsTable.BatchesIndicationStatus				AS BatchesIndicationStatusSender
		|FROM
		|	Document.BackflushProduction AS BackflushProduction
		|	
		|	INNER JOIN Document.BackflushProduction.ManufacturedProducts AS GoodsTable
		|	ON GoodsTable.Ref = BackflushProduction.Ref
		|
		|WHERE
		|	BackflushProduction.Ref IN(&ObjectsOfBases)
		|	AND GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
		|	AND NOT GoodsTable.BatchesIndicationStatus IN (4, 6, 8, 10)
		|	AND GoodsTable.Recipient.ShopFloorStockroom
		|
		|GROUP BY
		|	BackflushProduction.Ref,
		|	GoodsTable.Package,
		|	CASE
		|		WHEN GoodsTable.InternalSubcontracting
		|			THEN GoodsTable.MaterialProviderCompany
		|		WHEN TRUE
		|			THEN BackflushProduction.Organization
		|	END,
		|	GoodsTable.Recipient,
		|	BackflushProduction.ProductionIssueForActivity,
		|	BackflushProduction.LineOfBusiness,
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Series,
		|	GoodsTable.Purpose,
		|	GoodsTable.BatchesIndicationStatus
		|
		|UNION ALL
		|
		// BatchFinishedProducts
		|SELECT
		|	BackflushProduction.Ref					AS DocumentBasis,
		|	CASE
		|		WHEN GoodsTable.InternalSubcontracting
		|			THEN GoodsTable.MaterialProviderCompany
		|		WHEN TRUE
		|			THEN BackflushProduction.Organization
		|	END											AS Organization,
		|	TableOfSeries.Recipient							AS Sender,
		|	BackflushProduction.ProductionIssueForActivity		AS VATTaxation,
		|	BackflushProduction.LineOfBusiness	AS LineOfBusiness,
		|	TableOfSeries.Products						AS Products,
		|	TableOfSeries.Characteristic						AS Characteristic,
		|	TableOfSeries.Series								AS Series,
		|	TableOfSeries.Purpose							AS Purpose,
		|	TableOfSeries.Purpose							AS AssignmentSender,
		|	TableOfSeries.Products.UnitOfMeasure		AS Package,
		|	TableOfSeries.Count							AS Count,
		|	TableOfSeries.Count							AS NumberOfPackages,
		|	MIN(GoodsTable.BatchesIndicationStatus)		AS BatchesIndicationStatus,
		|	MIN(GoodsTable.BatchesIndicationStatus)		AS BatchesIndicationStatusSender
		|FROM
		|	Document.BackflushProduction AS BackflushProduction
		|	
		|	INNER JOIN Document.BackflushProduction.BatchFinishedProducts AS TableOfSeries
		|	ON (TableOfSeries.Ref = BackflushProduction.Ref)
		|	
		|	INNER JOIN Document.BackflushProduction.ManufacturedProducts AS GoodsTable
		|	ON TableOfSeries.Ref = GoodsTable.Ref
		|	AND TableOfSeries.Products = GoodsTable.Products
		|	AND TableOfSeries.Characteristic = GoodsTable.Characteristic
		|	AND TableOfSeries.Purpose = GoodsTable.Purpose
		|	AND TableOfSeries.Recipient = GoodsTable.Recipient
		|	AND TableOfSeries.CostGroupNumber = GoodsTable.CostGroupNumber
		|	
		|WHERE
		|	BackflushProduction.Ref IN(&ObjectsOfBases)
		|	AND GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
		|	AND GoodsTable.BatchesIndicationStatus IN (4, 6, 8, 10)
		|	AND GoodsTable.Recipient.ShopFloorStockroom
		|
		|GROUP BY
		|	BackflushProduction.Ref,
		|	CASE
		|		WHEN GoodsTable.InternalSubcontracting
		|			THEN GoodsTable.MaterialProviderCompany
		|		WHEN TRUE
		|			THEN BackflushProduction.Organization
		|	END,
		|	TableOfSeries.Recipient,
		|	BackflushProduction.ProductionIssueForActivity,
		|	BackflushProduction.LineOfBusiness,
		|	TableOfSeries.Products,
		|	TableOfSeries.Characteristic,
		|	TableOfSeries.Series,
		|	TableOfSeries.Purpose,
		|	TableOfSeries.Count
		|
		|UNION ALL
		|
		//SideAndIntermediateRelease
		|SELECT
		|	BackflushProduction.Ref					AS DocumentBasis,
		|	CASE
		|		WHEN NOT GoodsTable.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
		|			THEN GoodsTable.ProductOwner
		|		WHEN CostGroups.MaterialProviderCompany IS NOT NULL
		|				THEN CostGroups.MaterialProviderCompany
		|		WHEN TRUE
		|			THEN BackflushProduction.Organization
		|	END											AS Organization,
		|	GoodsTable.Recipient						AS Sender,
		|	BackflushProduction.ProductionIssueForActivity		AS VATTaxation,
		|	BackflushProduction.LineOfBusiness	AS LineOfBusiness,
		|	GoodsTable.Products						AS Products,
		|	GoodsTable.Characteristic					AS Characteristic,
		|	GoodsTable.Series								AS Series,
		|	GoodsTable.Purpose						AS Purpose,
		|	GoodsTable.Purpose						AS AssignmentSender,
		|	GoodsTable.Package							AS Package,
		|	SUM(GoodsTable.Count)					AS Count,
		|	SUM(GoodsTable.NumberOfPackages)			AS NumberOfPackages,
		|	GoodsTable.BatchesIndicationStatus				AS BatchesIndicationStatus,
		|	GoodsTable.BatchesIndicationStatus				AS BatchesIndicationStatusSender
		|FROM
		|	Document.BackflushProduction AS BackflushProduction
		|	
		|	INNER JOIN Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
		|	ON GoodsTable.Ref = BackflushProduction.Ref
		|	
		|	LEFT JOIN CostGroups AS CostGroups
		|	ON CostGroups.Ref = GoodsTable.Ref
		|	AND CostGroups.CostGroupNumber = GoodsTable.CostGroupNumber
		|	AND CostGroups.InternalSubcontracting
		|	
		|WHERE
		|	BackflushProduction.Ref IN(&ObjectsOfBases)
		|	AND GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
		|	AND NOT GoodsTable.BatchesIndicationStatus IN (4, 6, 8, 10)
		|	AND GoodsTable.Recipient.ShopFloorStockroom
		|
		|GROUP BY
		|	BackflushProduction.Ref,
		|	BackflushProduction.ProductionIssueForActivity,
		|	GoodsTable.Characteristic,
		|	CASE
		|		WHEN NOT GoodsTable.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
		|			THEN GoodsTable.ProductOwner
		|		WHEN CostGroups.MaterialProviderCompany IS NOT NULL
		|				THEN CostGroups.MaterialProviderCompany
		|		WHEN TRUE
		|			THEN BackflushProduction.Organization
		|	END,
		|	GoodsTable.Products,
		|	GoodsTable.Series,
		|	GoodsTable.Package,
		|	BackflushProduction.LineOfBusiness,
		|	GoodsTable.Recipient,
		|	GoodsTable.Purpose,
		|	GoodsTable.BatchesIndicationStatus
		|
		|UNION ALL
		|
		//BatchSideAndIntermediateRelease
		|SELECT
		|	BackflushProduction.Ref					AS DocumentBasis,
		|	CASE
		|		WHEN NOT GoodsTable.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
		|			THEN GoodsTable.ProductOwner
		|		WHEN CostGroups.MaterialProviderCompany IS NOT NULL
		|				THEN CostGroups.MaterialProviderCompany
		|		WHEN TRUE
		|			THEN BackflushProduction.Organization
		|	END											AS Organization,
		|	TableOfSeries.Recipient							AS Sender,
		|	BackflushProduction.ProductionIssueForActivity		AS VATTaxation,
		|	BackflushProduction.LineOfBusiness	AS LineOfBusiness,
		|	TableOfSeries.Products						AS Products,
		|	TableOfSeries.Characteristic						AS Characteristic,
		|	TableOfSeries.Series								AS Series,
		|	TableOfSeries.Purpose							AS Purpose,
		|	TableOfSeries.Purpose							AS AssignmentSender,
		|	TableOfSeries.Products.UnitOfMeasure		AS Package,
		|	TableOfSeries.Count							AS Count,
		|	TableOfSeries.Count							AS NumberOfPackages,
		|	MIN(GoodsTable.BatchesIndicationStatus)		AS BatchesIndicationStatus,
		|	MIN(GoodsTable.BatchesIndicationStatus)		AS BatchesIndicationStatusSender
		|FROM
		|	Document.BackflushProduction AS BackflushProduction
		|	
		|	INNER JOIN Document.BackflushProduction.BatchSideAndIntermediateRelease AS TableOfSeries
		|	ON (TableOfSeries.Ref = BackflushProduction.Ref)
		|	
		|	INNER JOIN Document.BackflushProduction.SideAndIntermediateRelease AS GoodsTable
		|	ON TableOfSeries.Ref = GoodsTable.Ref
		|	AND TableOfSeries.Products = GoodsTable.Products
		|	AND TableOfSeries.Characteristic = GoodsTable.Characteristic
		|	AND TableOfSeries.Purpose = GoodsTable.Purpose
		|	AND TableOfSeries.Recipient = GoodsTable.Recipient
		|	AND TableOfSeries.CostGroupNumber = GoodsTable.CostGroupNumber
		|	AND TableOfSeries.ProductOwner = GoodsTable.ProductOwner
		|	
		|	LEFT JOIN CostGroups AS CostGroups
		|	ON CostGroups.Ref = GoodsTable.Ref
		|	AND CostGroups.CostGroupNumber = GoodsTable.CostGroupNumber
		|	AND CostGroups.InternalSubcontracting
		|	
		|WHERE
		|	BackflushProduction.Ref IN(&ObjectsOfBases)
		|	AND GoodsTable.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse)
		|	AND GoodsTable.BatchesIndicationStatus IN (4, 6, 8, 10)
		|	AND GoodsTable.Recipient.ShopFloorStockroom
		|
		|GROUP BY
		|	BackflushProduction.Ref,
		|	BackflushProduction.ProductionIssueForActivity,
		|	TableOfSeries.Characteristic,
		|	CASE
		|		WHEN NOT GoodsTable.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
		|			THEN GoodsTable.ProductOwner
		|		WHEN CostGroups.MaterialProviderCompany IS NOT NULL
		|				THEN CostGroups.MaterialProviderCompany
		|		WHEN TRUE
		|			THEN BackflushProduction.Organization
		|	END,
		|	TableOfSeries.Products,
		|	TableOfSeries.Series,
		|	BackflushProduction.LineOfBusiness,
		|	TableOfSeries.Recipient,
		|	TableOfSeries.Purpose,
		|	TableOfSeries.Count
		|");
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.RecyclableWasteAllocation) Then
		QueryTexts.Add(
		//RecyclableWasteAllocation
		"SELECT
		|	RecyclableWasteAllocation.Ref							AS DocumentBasis,
		|	RecyclableWasteAllocation.Organization						AS Organization,
		|	RecyclableWasteAllocation.Recipient						AS Sender,
		|	RecyclableWasteAllocation.ProductionIssueForActivity			AS VATTaxation,
		|	RecyclableWasteAllocation.LineOfBusiness			AS LineOfBusiness,
		|	RecyclableWasteAllocation.Products						AS Products,
		|	RecyclableWasteAllocation.Characteristic					AS Characteristic,
		|	RecyclableWasteAllocation.Series							AS Series,
		|	RecyclableWasteAllocation.Purpose						AS Purpose,
		|	RecyclableWasteAllocation.Purpose						AS AssignmentSender,
		|	RecyclableWasteAllocation.Products.UnitOfMeasure	AS Package,
		|	SUM(RecyclableWasteAllocation.Count)				AS Count,
		|	SUM(RecyclableWasteAllocation.Count)				AS NumberOfPackages,
		|	RecyclableWasteAllocation.BatchesIndicationStatus				AS BatchesIndicationStatus,
		|	RecyclableWasteAllocation.BatchesIndicationStatus				AS BatchesIndicationStatusSender
		|FROM
		|	Document.RecyclableWasteAllocation AS RecyclableWasteAllocation
		|WHERE
		|	RecyclableWasteAllocation.Ref IN(&ObjectsOfBases)
		|	AND VALUETYPE(RecyclableWasteAllocation.Recipient) = TYPE(Catalog.Warehouses)
		|	AND NOT RecyclableWasteAllocation.BatchesIndicationStatus IN (4, 6, 8, 10)
		|	AND RecyclableWasteAllocation.Recipient.ShopFloorStockroom
		|
		|GROUP BY
		|	RecyclableWasteAllocation.Ref,
		|	RecyclableWasteAllocation.Series,
		|	RecyclableWasteAllocation.Organization,
		|	RecyclableWasteAllocation.ProductionIssueForActivity,
		|	RecyclableWasteAllocation.Recipient,
		|	RecyclableWasteAllocation.LineOfBusiness,
		|	RecyclableWasteAllocation.Products,
		|	RecyclableWasteAllocation.Characteristic,
		|	RecyclableWasteAllocation.Purpose,
		|	RecyclableWasteAllocation.Products.UnitOfMeasure,
		|	RecyclableWasteAllocation.BatchesIndicationStatus
		|
		|UNION ALL
		|
		//Distributionreferencesexternal links
		|SELECT
		|	RecyclableWasteAllocation.Ref					AS DocumentBasis,
		|	RecyclableWasteAllocation.Organization				AS Organization,
		|	RecyclableWasteAllocation.Recipient				AS Sender,
		|	RecyclableWasteAllocation.ProductionIssueForActivity	AS VATTaxation,
		|	RecyclableWasteAllocation.LineOfBusiness	AS LineOfBusiness,
		|	TableOfSeries.Products								AS Products,
		|	TableOfSeries.Characteristic								AS Characteristic,
		|	TableOfSeries.Series										AS Series,
		|	TableOfSeries.Purpose									AS Purpose,
		|	TableOfSeries.Purpose									AS AssignmentSender,
		|	TableOfSeries.Products.UnitOfMeasure				AS Package,
		|	TableOfSeries.Count									AS Count,
		|	TableOfSeries.Count									AS NumberOfPackages,
		|	RecyclableWasteAllocation.BatchesIndicationStatus		AS BatchesIndicationStatus,
		|	RecyclableWasteAllocation.BatchesIndicationStatus		AS BatchesIndicationStatusSender
		|FROM
		|	Document.RecyclableWasteAllocation AS RecyclableWasteAllocation
		|		INNER JOIN Document.RecyclableWasteAllocation.SetOfSeries AS TableOfSeries
		|		ON TableOfSeries.Ref = RecyclableWasteAllocation.Ref
		|WHERE
		|	RecyclableWasteAllocation.Ref IN(&ObjectsOfBases)
		|	AND VALUETYPE(RecyclableWasteAllocation.Recipient) = TYPE(Catalog.Warehouses)
		|	AND RecyclableWasteAllocation.BatchesIndicationStatus IN (4, 6, 8, 10)
		|	AND RecyclableWasteAllocation.Recipient.ShopFloorStockroom
		|
		|GROUP BY
		|	RecyclableWasteAllocation.Ref,
		|	TableOfSeries.Series,
		|	RecyclableWasteAllocation.Organization,
		|	RecyclableWasteAllocation.ProductionIssueForActivity,
		|	RecyclableWasteAllocation.Recipient,
		|	RecyclableWasteAllocation.LineOfBusiness,
		|	TableOfSeries.Products,
		|	TableOfSeries.Characteristic,
		|	TableOfSeries.Purpose,
		|	TableOfSeries.Products.UnitOfMeasure,
		|	RecyclableWasteAllocation.BatchesIndicationStatus,
		|	TableOfSeries.Count
		|");
	EndIf;
	
	QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
	QueryText = RequestSchemes.SetSelectionOfAllowedRecords(QueryText, True);
	QueryText = QueryText + "
		|ORDER BY
		|	DocumentBasis,
		|	Organization,
		|	Sender,
		|	Products,
		|	Characteristic,
		|	Series,
		|	Purpose,
		|	AssignmentSender,
		|	Package
		|"; // @query-part
	
	QueryText = QueryText + "
		|TOTALS BY
		|	DocumentBasis,
		|	Organization,
		|	VATTaxation,
		|	LineOfBusiness,
		|	Sender
		|"; // @query-part
	
	Query.Text = QueryText;
	SampleFoundationDocuments = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	DateOfNewDocuments = CurrentSessionDate();
	While SampleFoundationDocuments.Next() Do
		
		OrganizationSelection = SampleFoundationDocuments.Select(QueryResultIteration.ByGroups);
		While OrganizationSelection.Next() Do
			SamplingTaxation = OrganizationSelection.Select(QueryResultIteration.ByGroups);
			While SamplingTaxation.Next() Do
				
				SamplingActivities = SamplingTaxation.Select(QueryResultIteration.ByGroups);
				While SamplingActivities.Next() Do
					
					SelectionSender = SamplingActivities.Select(QueryResultIteration.ByGroups);
					While SelectionSender.Next() Do
						
						CurDocument = Documents.MovementOfProductsAndMaterials.CreateDocument();
						CurDocument.GetNewObjectRef();
						DocumentsArray.Add(CurDocument);
						
						FillPropertyValues(CurDocument, SelectionSender);
						CurDocument.Date = DateOfNewDocuments;
						CurDocument.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom;
						CurDocument.Fill(Undefined);
						
						DetailedRecords = SelectionSender.Select(QueryResultIteration.ByGroups);
						While DetailedRecords.Next() Do
							NewRow = CurDocument.Goods.Add();
							FillPropertyValues(NewRow, DetailedRecords);
							
							If DetailedRecords.BatchesIndicationStatus = 4
								Or DetailedRecords.BatchesIndicationStatus = 6
								Or DetailedRecords.BatchesIndicationStatus = 8
								Or DetailedRecords.BatchesIndicationStatus = 10 Then
								NewRow = CurDocument.SetOfSeries.Add();
								FillPropertyValues(NewRow, DetailedRecords);
							EndIf;
						EndDo;
						
						SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(CurDocument, Documents.MovementOfProductsAndMaterials);
						ProductsServer.FillInStatusesForSpecifyingSeries(CurDocument, SeriesSpecificationParameters);
						
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
	Return DocumentsArray;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
