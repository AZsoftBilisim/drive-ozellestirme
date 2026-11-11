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
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	
	CorrectionOfSidedBalanceInCompanyGoodsAccountingLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.CorrectionOfSidedBalanceInCompanyGoodsAccounting") Then
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
		
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		CorrectionOfSidedBalanceInCompanyGoodsAccountingLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CorrectionOfSidedBalanceInCompanyGoodsAccountingLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return CorrectionOfSidedBalanceInCompanyGoodsAccountingLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Posting

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfCorrections", QueryTexts) Then
		QueryTextTTTableOfCorrections(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	TableOfCorrections.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableOfCorrections.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	TableOfCorrections.Products AS Products,
	|	TableOfCorrections.Characteristic AS Characteristic,
	|	TableOfCorrections.InventoryOwnerAttributeGoodsReceipts AS InventoryOwnerAttribute,
	|	TableOfCorrections.CCDNumberForReceiving AS CCDNumber,
	|	TableOfCorrections.InventoryOwnerAttributeGoodsReceipts AS CorInventoryOwnerAttribute,
	|	TableOfCorrections.Count AS Count,
	|	TableOfCorrections.QuantityByGBRN AS QuantityByGBRN,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	&Organization AS ShipmentCompany,
	|	UNDEFINED AS VATTaxation,
	|	FALSE AS Primary
	|FROM
	|	TTTableOfCorrections AS TableOfCorrections
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfCorrections.LineNumber,
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	&Organization,
	|	TableOfCorrections.ItemsLocationAttributes,
	|	TableOfCorrections.ItemsLocationAttributes,
	|	TableOfCorrections.Products,
	|	TableOfCorrections.Characteristic,
	|	TableOfCorrections.WriteOffInventoryAttributes,
	|	TableOfCorrections.CCDNumberForWriteOff,
	|	TableOfCorrections.WriteOffInventoryAttributes,
	|	TableOfCorrections.Count,
	|	TableOfCorrections.QuantityByGBRN,
	|	&BusinessOperation,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	&Organization,
	|	UNDEFINED,
	|	FALSE
	|FROM
	|	TTTableOfCorrections AS TableOfCorrections
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfCorrections(Query, QueryTexts)
	
	RegisterName = "TTTableOfCorrections";
	
	QueryText =
	"SELECT
	|	GoodsTable.Ref 							AS Ref,
	|	GoodsTable.LineNumber 						AS LineNumber,
	|	GoodsTable.ItemsLocationAttributes 		AS ItemsLocationAttributes,
	|	KeysWithoutAssignment.DimensionKey				AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryLocationAttributeKeys.Products 	AS Products,
	|	InventoryLocationAttributeKeys.Characteristic 	AS Characteristic,
	|	InventoryLocationAttributeKeys.Series 			AS Series,
	|	InventoryLocationAttributeKeys.StorageLocation 	AS Warehouse,
	|	InventoryLocationAttributeKeys.Purpose 		AS Purpose,
	|	GoodsTable.CCDNumberForReceiving 			AS CCDNumberForReceiving,
	|	GoodsTable.InventoryOwnerAttributeGoodsReceipts 			AS InventoryOwnerAttributeGoodsReceipts,
	|	GoodsTable.CCDNumberForWriteOff 					AS CCDNumberForWriteOff,
	|	GoodsTable.WriteOffInventoryAttributes 				AS WriteOffInventoryAttributes,
	// The type of inventory in the type of inventory entry and the type of inventory entry must be identical
	|	InventoryKinds.InventoryType 							AS InventoryType,
	|	CASE 
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		ELSE CASE WHEN InventoryLocationAttributeKeys.WarehouseArea.ShopFloorStockroom
	|		 OR InventoryLocationAttributeKeys.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		END
	|	END 											AS AccountingSection,
	|	GoodsTable.Count 						AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END											AS QuantityByGBRN,
	|	GoodsTable.QuantityReceived 				AS QuantityReceived,
	|	GoodsTable.QuantityToWriteOff 				AS QuantityToWriteOff,
	|	GoodsTable.RowID               AS RowID
	|INTO TTTableOfCorrections
	|FROM
	|	Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting.Corrections AS GoodsTable
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON GoodsTable.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|	INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON GoodsTable.InventoryOwnerAttributeGoodsReceipts = InventoryKinds.Ref
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS KeysWithoutAssignment
	|	ON KeysWithoutAssignment.Products = GoodsTable.ItemsLocationAttributes.Products
	|		AND KeysWithoutAssignment.Characteristic = GoodsTable.ItemsLocationAttributes.Characteristic
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = KeysWithoutAssignment.ProductCostElement
	|		AND KeysWithoutAssignment.Series = GoodsTable.ItemsLocationAttributes.Series
	|		AND KeysWithoutAssignment.StorageLocation = GoodsTable.ItemsLocationAttributes.StorageLocation
	|		AND KeysWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|WHERE
	|	GoodsTable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfCorrections", QueryTexts) Then
		QueryTextTTTableOfCorrections(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT DISTINCT
	|	&Period AS DateOfReceipt,
	|	TableOfCorrections.Products AS Products,
	|	TableOfCorrections.Characteristic AS Characteristic,
	|	TableOfCorrections.Series AS Series,
	|	TableOfCorrections.Purpose AS Purpose,
	|	TableOfCorrections.InventoryOwnerAttributeGoodsReceipts AS InventoryOwnerAttribute,
	|	TableOfCorrections.CCDNumberForReceiving AS CCDNumber
	|FROM
	|	TTTableOfCorrections AS TableOfCorrections
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|		ON TableOfCorrections.InventoryOwnerAttributeGoodsReceipts = UninvoicedReceipts.InventoryOwnerAttribute
	|			AND TableOfCorrections.Products = UninvoicedReceipts.Products
	|			AND TableOfCorrections.Characteristic = UninvoicedReceipts.Characteristic
	|			AND TableOfCorrections.Series = UninvoicedReceipts.Series
	|			AND TableOfCorrections.Purpose = UninvoicedReceipts.Purpose
	|			AND TableOfCorrections.CCDNumberForReceiving = UninvoicedReceipts.CCDNumber
	|WHERE
	|	(UninvoicedReceipts.DateOfReceipt IS NULL
	|			OR UninvoicedReceipts.DateOfReceipt < &Period)
	|
	|ORDER BY
	|	TableOfCorrections.InventoryOwnerAttributeGoodsReceipts,
	|	TableOfCorrections.Products,
	|	TableOfCorrections.Characteristic,
	|	TableOfCorrections.Series,
	|	TableOfCorrections.Purpose,
	|	TableOfCorrections.CCDNumberForReceiving";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Period AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Department,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	&Comment AS Comment,
	|	UNDEFINED AS Currency,
	|	0 AS Sum,
	|	UNDEFINED AS Status,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Period AS SourceDocumentDate,
	|	&Number AS SourceDocumentNumber,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
		
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert(
		"BusinessOperation", "VALUE(Enum.BusinessTransactions.GoodsAssignmentAdjustments)");
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Number AS Number,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible
	|FROM
	|	Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period", 				Attributes.Period);
	Query.SetParameter("Ref", 				Attributes.Ref);
	Query.SetParameter("Organization", 			Attributes.Organization);
	Query.SetParameter("Number", 					Attributes.Number);
	Query.SetParameter("Comment", 			Attributes.Comment);
	Query.SetParameter("DeletionMark", 		Attributes.DeletionMark);
	Query.SetParameter("Posted", 				Attributes.Posted);
	Query.SetParameter("EmployeeResponsible", 			Attributes.EmployeeResponsible);
	Query.SetParameter("BusinessOperation", 	Enums.BusinessTransactions.GoodsAssignmentAdjustments);
	Query.SetParameter("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.GoodsAssignmentAdjustments);
	Query.SetParameter("MetadataIdentifier", 
		Common.MetadataObjectID("Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting"));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
EndProcedure

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
	AdditionalTables.Add("TTTableOfCorrections");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableOfCorrections(Query, QueryTexts);
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
	|
	// Item accounting fields
	|	DocumentTable.Organization 					 AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	 AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.WriteOffInventoryAttributes			 AS InventoryOwnerAttribute,
	|	UNDEFINED 			 						 AS VATActivityType,
	|	UNDEFINED 		 							 AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                     AS CorCompany,
	|	UNDEFINED 									 AS CorLot,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	 AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipts		 AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 						AS SalesOpportunity,
	|	UNDEFINED						AS Department,
	|	DocumentTable.EmployeeResponsible		AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.GoodsAssignmentAdjustments) AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 										 AS FinRecordID,
	|	&BusinessTransactionSetting												 AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting AS DocumentTable
	|	INNER JOIN TTTableOfCorrections AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.Count <> 0
	|	AND TableTypesOfStocks_.WriteOffInventoryAttributes <> TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipts
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

#EndRegion

#EndIf
