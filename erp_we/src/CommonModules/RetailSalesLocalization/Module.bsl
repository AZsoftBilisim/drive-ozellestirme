
#Region Public

// Updates Statuses and information about sales of goods
// 
// Parameters:
//  Object - DocumentObject.CashRegisterReceipt - The document from which the procedure is called:
//  	* Goods - ValueTable - Goods of the document
Procedure UpdateStatusesAndAllowedItems(Object) Export
	
	
EndProcedure

// Updates the Status and information about the sale permission of the goods in the current line
// 
// Parameters:
//  CurrentRow - FormDataCollection - Processed String
//  Object - DocumentObject.CashRegisterReceipt - The document from which the procedure is called:
//  	* Goods - ValueTable - Goods of the document
Procedure UpdateStatusAndPermissionToSell(CurrentRow, Object) Export
	
	
EndProcedure

// Removes sales permissions for unrelated goods
// 
// Parameters:
//  Form - ClientApplicationForm - The Form of the CWP
Procedure DeletePermissionsToSellUnrelatedProducts(Form) Export
	
	
EndProcedure

// Deletes the sales permission if it is not required in the current line for the goods
// 
// Parameters:
//  CurrentRow - FormDataCollection - Processed String
//  Form - ClientApplicationForm - The Form of the CWP
Procedure DeletePermissionToSellWithoutLinkedProduct(CurrentRow, Form) Export
	
	
EndProcedure

// Set the conditional design.
// 
// Parameters:
//  Form - ClientApplicationForm - 
Procedure SetConditionalAppearance(Form) Export


EndProcedure

// Establish the availability of the use of retail localization sales.
// 
// Parameters:
//  Form - ClientApplicationForm - Form
//  UseRetailSales - Boolean - Use retail sales
Procedure EstablishAvailabilityOfRetailSalesLocalization(Form, UseRetailSales) Export
	
	
EndProcedure

#Region FiscalTransactions


// Checks whether goods are allowed in the document
// 
// Parameters:
//  DocumentRef - DocumentRef - Document for verification
// 
// Returns:
//  Boolean - Products Without Stamps In The Document Are Allowed
Function ProductsWithoutStampsInDocumentAreAllowed(DocumentRef) Export
	
	ProductsWithoutStampsAreAllowedForDocument = False;
	
	
	Return ProductsWithoutStampsAreAllowedForDocument;
	
EndFunction

// Query Text for receiving documents by order (customer's order)
// 
// Returns:
//  String - Request Text Order Documents
Function QueryTextDocumentsByOrder() Export
	
	//@skip-check bsl-ql-hub
	QueryText = "SELECT
	|	ARAPObjects.Ref AS ARAPObject
	|INTO TTCalculationObjects_
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE
	|	ARAPObjects.Object = &ARAPObject
	|	AND NOT ARAPObjects.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerInvoice.Ref AS Ref,
	|	CustomerInvoice.Date AS Date
	|INTO TTDocumentsByOrder
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.Posted
	|	AND CustomerInvoice.SalesOrder = &ReferenceOrder
	|
	|UNION
	|
	|SELECT
	|	CashAccountReceiptNote.Ref,
	|	CashAccountReceiptNote.Ref.Date
	|FROM
	|	Document.CashAccountReceiptNote.ARAPDetails AS CashAccountReceiptNote
	|		INNER JOIN TTCalculationObjects_ AS ARAPObjects
	|		ON CashAccountReceiptNote.ARAPObject = ARAPObjects.ARAPObject
	|			AND (CashAccountReceiptNote.Ref.Posted)
	|
	|UNION
	|
	|SELECT
	|	PaymentCardTransaction.Ref,
	|	PaymentCardTransaction.Ref.Date
	|FROM
	|	Document.PaymentCardTransaction.ARAPDetails AS PaymentCardTransaction
	|		INNER JOIN TTCalculationObjects_ AS ARAPObjects
	|		ON PaymentCardTransaction.ARAPObject = ARAPObjects.ARAPObject
	|			AND (PaymentCardTransaction.Ref.Posted)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsByOrder.Ref AS Ref,
	|	DocumentsByOrder.Date AS Date,
	|	BEGINOFPERIOD(DocumentsByOrder.Date, DAY) AS DateDay
	|FROM
	|	TTDocumentsByOrder AS DocumentsByOrder
	|
	|ORDER BY
	|	DocumentsByOrder.Date DESC
	|TOTALS BY
	|	DateDay";
	
	Return QueryText;
	
EndFunction

// Returns the tax system of the organization on the date
// 
// Parameters:
// 	Organization - CatalogRef.Companies - The organization for which the tax system is defined
// 	Date - Date - The date on which the tax system is determined
// Returns:
// 	EnumRef.CRETaxationSystemTypes - The taxation system for the parameters of fiscal checks
Function FiscalTransactionTaxationSystem(Organization, Date = Undefined) Export
	
	If TypeOf(Organization) <> Type("CatalogRef.Companies")
		Or Not ValueIsFilled(Organization) Then
		Return Undefined;
	EndIf;
	
	QueryText = "SELECT
	|	T.TaxationSystem AS TaxationSystem,
	|	&ParameterForSubstitution AS STSTaxationObject
	|FROM
	|	InformationRegister.TaxationSystemSettings.SliceLast(&CurrentDate, Organization = &Organization) AS T
	|";

	Query = New Query(QueryText);
	Query.SetParameter("ParameterForSubstitution", Undefined);
	
	If Date = Undefined Then
		Query.SetParameter("CurrentDate", CurrentSessionDate());
	Else
		Query.SetParameter("CurrentDate", Date);
	EndIf;
	
	CompanyDetails = Common.ObjectAttributesValues(
		Organization,
		"ParentCompany, BranchOffice");
		
	If CompanyDetails.BranchOffice = True Then
		Query.SetParameter("Organization", CompanyDetails.ParentCompany);
	Else
		Query.SetParameter("Organization", Organization);
	EndIf;
	
	TaxSystemData = Query.Execute().Select();
	TaxSystemData.Next();
	
	TaxationSystem = Undefined;
	
	If TaxSystemData.TaxationSystem = Enums.TaxationSystems.Shared3 Then
		
		TaxationSystem = Enums.CRETaxationSystemTypes.GTS;

		
	EndIf;
	
	Return TaxationSystem;
	
EndFunction

// determines whether the item is an alcoholic beverage that has a unique identifier (labeled)
// 
// Parameters:
//  Products - CatalogRef.Products - item to check
// 
// Returns:
//  Boolean - true if the item is an alcoholic product that has a unique identifier (marked)
Function EGAISLabeledAlcoholicBeverages(Products) Export
	
	
	//@skip-check bsl-legacy-check-method-for-statements-after-return
	Return False;

EndFunction

// Returns the ability to print a separate receipt slip for the acquiring operation.
// If True, it is assumed that the acquiring terminal's slip check is displayed separately and
// the fiscal check does not contain the data of the acquiring operation.
// 
// Returns:
// 	Boolean
Function PrintSeparateSlipReceiptOfAcquiringOperation() Export

	Result = False;
	
	
	Return Result;

EndFunction

// Checks whether the document allows the sale of a gift certificate of operation of the document, depending
// on the business operation of the document.
// 
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - A business of operation that checks
//  	whether the sale of a gift certificate is allowed in the document.
// 
// Returns:
//  Boolean - It Is Allowed To Sell A Gift Certificate In The Document
Function ItIsAllowedToSellGiftCertificateInDocument(BusinessOperation) Export
	
	ItIsAllowedToSellGiftCertificateInDocument = False;
	
	
	Return ItIsAllowedToSellGiftCertificateInDocument;
	
EndFunction

// Records the form object
// 
// Parameters:
//  Form - ClientApplicationForm - Client Application Form:
//  * Object - DocumentObject - The main Attribute of the document form
//  FiscalizationParameters - Structure -
//  WriteParameters - Structure -
//  DocumentWrittenSuccessfully - Boolean - indicates that the document was successfully recorded
Procedure RecordFiscalTransaction(Form, FiscalizationParameters, WriteParameters, DocumentWrittenSuccessfully) Export
	
	
EndProcedure

// Checks the data of the marked goods of the document before performing the fiscal of operation
//
// Parameters:
//  Object - DocumentObject - Object of the document being checked
//  AdditionalParameters - Structure of KeyAndValue - An arbitrary structure for Transferring data from the client context
//
// Returns:
//  Boolean - 
//
Function VerificationOfDataOfMarkedGoodsDocument(Object, AdditionalParameters = Undefined) Export
	Result = True;
	Return Result;
EndFunction

#EndRegion


#Region ConsigneeInReceipt

// Returns a list of requests (in the form of a list) for making a batch request. 
// The last query in the list is actually the resulting one. Composition of the fields of the last request:
//	   Nomenclature - Reference link.Nomenclature
//	   Feature - Reference link.Nomenclature specificationsreferences
//	   Series - Reference link.Seriinomenclatures
//	   Committee - Directory link.Organizations,Directory link.Counterparties.
//
// Parameters:
//	Organization - CatalogRef.Companies
//	Warehouse - CatalogRef.Warehouses
//	KeysTableName - String - The name of the TT in which the rows with the data keys will be transferred, the empty row is for the exchange (all products). Required columns:
//	 *Products - CatalogRef.Products
//	 *Characteristic - CatalogRef.ItemsCharacteristics
//	 *Series - CatalogRef.ItemsBatches
//	SuffixOfTTNames - String - Ending the names of all TT packages, to avoid name conflicts in the overall package
//	
// Returns:
//	Structure - structure with properties:
//	*QueryOptions - Structure - structure with properties:
//	 **Key - String
//	*QueryBatch - ValueList of ValueListItem:
//	 **Presentation - String - Name of the temporary table that is being created in the request
//	 **Value - String - Text of a single request
//
Function RequestingConsignorsGoodsData(Val Organization, Val Warehouse, Val KeysTableName = "", Val SuffixOfTTNames = "") Export
	
	UseCommission = True;
	UseIntercampany = 
		UseCommission And GetFunctionalOption("UseCustomerInvoiceIntercompany");
	ThisIsExchangeRequest = IsBlankString(KeysTableName);
	If Not UseCommission And Not ThisIsExchangeRequest Then
		
		QueryText = 
		"SELECT
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|	UNDEFINED AS Consignor
		|INTO BalanceDataIncludingConsignors_SubstitutionSuffix
		|WHERE
		|	FALSE";
		QueryText = StrReplace(QueryText, "_SubstitutionSuffix", TrimAll(SuffixOfTTNames));
		
		PackageQueries = New ValueList;
		PackageQueries.Add(QueryText, "BalanceDataIncludingConsignors"+TrimAll(SuffixOfTTNames)); 
		Result = New Structure("QueryOptions, QueryBatch", New Structure, PackageQueries);
		
		Return Result;
		
	EndIf; 
	
	DefaultNameSuffix = "DataOfConsignorsOnGoods";
	NameSuffix = ?(IsBlankString(SuffixOfTTNames), DefaultNameSuffix, SuffixOfTTNames);
	
	RequestParametersAreOriginal = New Structure();
	
	RequestParametersAreOriginal.Insert("SelectionCompanySeller_SubstitutionSuffix", Organization);
	RequestParametersAreOriginal.Insert("SelectionOfSellerSStorageLocation_SubstitutionSuffix", Warehouse);
	RequestParametersAreOriginal.Insert("LowerDateOfOpenShifts_SubstitutionSuffix", CurrentSessionDate()-60*60*24*2);
	
	GoodsTransferMethods = New Array;
	GoodsTransferMethods.Add(Enums.GoodsTransferMethods.Sale);
	RequestParametersAreOriginal.Insert("MethodsOfTransferringGoods_SubstitutionSuffix", GoodsTransferMethods);
	
	FilterInventoryTypes = New Array;
	FilterInventoryTypes.Add(Enums.InventoryTypes.OwnGoods);
	FilterInventoryTypes.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	RequestParametersAreOriginal.Insert("SelectionInventoryTypes_SubstitutionSuffix", FilterInventoryTypes);
	
		RequestParametersAreOriginal.Insert("RequestExclusionCondition_Intercampany_SubstitutionSuffix", UseIntercampany);
	
	PackageQueries = New ValueList;
	RequestParametersAreFinal = New Structure;
	
	NameSubstitution = New ValueList();
	NameSubstitution.Add("#CollectionProducts", KeysTableName);
	For Each Itm In RequestParametersAreOriginal Do
		NewKeyName = StrReplace(Itm.Key, "_SubstitutionSuffix", NameSuffix);
		NameSubstitution.Add(Itm.Key, NewKeyName);
		RequestParametersAreFinal.Insert(NewKeyName,Itm.Value);
	EndDo;
	
	QueryText = 
	"SELECT
	|	CustomizeCustomerInvoiceIntercompany.CompanyCustomer AS CompanyCustomer,
	|	CustomizeCustomerInvoiceIntercompany.GoodsTransferMethod AS GoodsTransferMethod,
	|	CustomizeCustomerInvoiceIntercompany.CompanyOwner AS CompanyOwner,
	|	CustomizeCustomerInvoiceIntercompany.InventoryType AS InventoryTypeOfOwner
	|INTO TransferSettings_SubstitutionSuffix
	|FROM
	|	InformationRegister.CustomizeCustomerInvoiceIntercompany AS CustomizeCustomerInvoiceIntercompany
	|WHERE
	|	CustomizeCustomerInvoiceIntercompany.CompanyCustomer = &SelectionCompanySeller_SubstitutionSuffix
	|	AND CustomizeCustomerInvoiceIntercompany.GoodsTransferMethod IN(&MethodsOfTransferringGoods_SubstitutionSuffix)
	|	AND &RequestExclusionCondition_Intercampany_SubstitutionSuffix
	|
	|INDEX BY
	|	CompanyOwner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE AS ThereAreRecords
	|INTO ThereAreTransferSettings_SubstitutionSuffix
	|FROM
	|	TransferSettings_SubstitutionSuffix AS TransferSettings
	|WHERE
	|	&RequestExclusionCondition_Intercampany_SubstitutionSuffix
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocReceipt.Ref AS Ref,
	|	DocReceipt.Organization AS Organization,
	|	NULL AS CommunicationStorno
	|INTO ReceiptsForOpenShifts_SubstitutionSuffix
	|FROM
	|	Document.CashRegisterReceipt AS DocReceipt
	|	INNER JOIN Document.CashRegisterShift AS DocShift
	|	ON DocReceipt.CashRegisterShift = DocShift.Ref
	|WHERE
	|	DocReceipt.Warehouse = &SelectionOfSellerSStorageLocation_SubstitutionSuffix
	|	AND DocReceipt.Organization = &SelectionCompanySeller_SubstitutionSuffix
	|	AND DocReceipt.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND DocShift.CashRegisterShiftEnd = DATETIME(1, 1, 1)
	|	AND DocReceipt.Date > &LowerDateOfOpenShifts_SubstitutionSuffix
	|
	|UNION ALL
	|
	|SELECT
	|	DocReceipt.Ref AS Receipt,
	|	DocReceipt.Organization AS Organization,
	|	NULL
	|FROM
	|	Document.CashRegisterReceiptReturn AS DocReceipt
	|	INNER JOIN Document.CashRegisterShift AS DocShift
	|	ON DocReceipt.CashRegisterShift = DocShift.Ref
	|WHERE
	|	DocReceipt.Warehouse = &SelectionOfSellerSStorageLocation_SubstitutionSuffix
	|	AND DocReceipt.Organization = &SelectionCompanySeller_SubstitutionSuffix
	|	AND DocReceipt.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND DocShift.CashRegisterShiftEnd = DATETIME(1, 1, 1)
	|	AND DocReceipt.Date > &LowerDateOfOpenShifts_SubstitutionSuffix
	|
	|UNION ALL
	|
	|SELECT 
	|	DocReceipt.CashRegisterReceipt AS Receipt,
	|	DocReceipt.Organization AS Organization,
	|	DocReceipt.Ref
	|FROM
	|	Document.ReceiptOfCashRegisterAdjustment AS DocReceipt
	|	INNER JOIN Document.CashRegisterShift AS DocShift
	|	ON DocReceipt.CashRegisterShift = DocShift.Ref
	|	INNER JOIN Document.CashRegisterReceipt AS ReceiptIsBeingCancelled
	|	ON DocReceipt.CashRegisterReceipt = ReceiptIsBeingCancelled.Ref
	|WHERE
	|	DocReceipt.Warehouse = &SelectionOfSellerSStorageLocation_SubstitutionSuffix
	|	AND DocReceipt.Organization = &SelectionCompanySeller_SubstitutionSuffix
	|	AND DocReceipt.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND DocShift.CashRegisterShiftEnd = DATETIME(1, 1, 1)
	|	AND DocReceipt.Date > &LowerDateOfOpenShifts_SubstitutionSuffix
	|	AND ReceiptIsBeingCancelled.Warehouse = &SelectionOfSellerSStorageLocation_SubstitutionSuffix
	|
	|UNION ALL
	|
	|SELECT
	|	DocReceipt.Ref AS Receipt,
	|	DocReceipt.Organization AS Organization,
	|	DocReceipt.CashRegisterReceipt
	|FROM
	|	Document.ReceiptOfCashRegisterAdjustment AS DocReceipt
	|	INNER JOIN Document.CashRegisterShift AS DocShift
	|	ON DocReceipt.CashRegisterShift = DocShift.Ref
	|WHERE
	|	DocReceipt.Warehouse = &SelectionOfSellerSStorageLocation_SubstitutionSuffix
	|	AND DocReceipt.Organization = &SelectionCompanySeller_SubstitutionSuffix
	|	AND DocReceipt.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND DocShift.CashRegisterShiftEnd = DATETIME(1, 1, 1)
	|	AND DocReceipt.Date > &LowerDateOfOpenShifts_SubstitutionSuffix
	|
	|INDEX BY 
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Receipt.Ref AS Receipt,
	|	Receipt.CommunicationStorno AS CommunicationStorno,
	|	Receipt.Organization AS Organization,
	|	ReceiptGoods.Products AS Products,
	|	ReceiptGoods.Characteristic AS Characteristic,
	|	ReceiptGoods.Series AS Series,
	|	ReceiptGoods.Consignor AS ConsignorOfReceipt,
	|	CASE
	|		WHEN VALUETYPE(ReceiptGoods.Consignor) = TYPE(Catalog.Counterparties)
	|			THEN VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END AS TypeOfStock,
	|	CASE
	|		WHEN VALUETYPE(ReceiptGoods.Consignor) = TYPE(Catalog.Companies)
	|			THEN 2
	|		ELSE 1
	|	END AS PriorityByGoodsStockType,
	|	CASE
	|		WHEN Receipt.CommunicationStorno IS NULL
	|			THEN -1
	|		ELSE 1
	|	END * ReceiptGoods.Count AS Count
	|INTO OpenShiftData_SubstitutionSuffix
	|FROM
	|	ReceiptsForOpenShifts_SubstitutionSuffix AS Receipt
	|		INNER JOIN Document.CashRegisterReceipt.Goods AS ReceiptGoods
	|		ON Receipt.Ref = ReceiptGoods.Ref
	|WHERE
	|	&SubstitutionCondition_SelectionOfChecksByComposition
	|
	|UNION ALL
	|
	|SELECT
	|	Receipt.Ref,
	|	Receipt.CommunicationStorno,
	|	Receipt.Organization,
	|	ReceiptGoods.Products,
	|	ReceiptGoods.Characteristic,
	|	ReceiptGoods.Series,
	|	ReceiptGoods.Consignor,
	|	CASE
	|		WHEN VALUETYPE(ReceiptGoods.Consignor) = TYPE(Catalog.Counterparties)
	|			THEN VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END,
	|	CASE
	|		WHEN VALUETYPE(ReceiptGoods.Consignor) = TYPE(Catalog.Companies)
	|			THEN 2
	|		ELSE 1
	|	END,
	|	ReceiptGoods.Count
	|FROM
	|	ReceiptsForOpenShifts_SubstitutionSuffix AS Receipt
	|		INNER JOIN Document.CashRegisterReceiptReturn.Goods AS ReceiptGoods
	|		ON Receipt.Ref = ReceiptGoods.Ref
	|WHERE
	|	&SubstitutionCondition_SelectionOfChecksByComposition
	|
	|UNION ALL
	|
	|SELECT
	|	Receipt.Ref,
	|	Receipt.CommunicationStorno,
	|	Receipt.Organization,
	|	ReceiptGoods.Products,
	|	ReceiptGoods.Characteristic,
	|	ReceiptGoods.Series,
	|	ReceiptGoods.Consignor,
	|	CASE
	|		WHEN VALUETYPE(ReceiptGoods.Consignor) = TYPE(Catalog.Counterparties)
	|			THEN VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END,
	|	CASE
	|		WHEN VALUETYPE(ReceiptGoods.Consignor) = TYPE(Catalog.Companies)
	|			THEN 2
	|		ELSE 1
	|	END,
	|	ReceiptGoods.Count * -1
	|FROM
	|	ReceiptsForOpenShifts_SubstitutionSuffix AS Receipt
	|		INNER JOIN Document.ReceiptOfCashRegisterAdjustment.Goods AS ReceiptGoods
	|		ON Receipt.Ref = ReceiptGoods.Ref
	|WHERE
	|	&SubstitutionCondition_SelectionOfChecksByComposition
	|
	|INDEX BY 
	|	Products,
	|	Characteristic,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.InventoryType AS InventoryType
	|INTO SelectionTypesOfStocks_SubstitutionSuffix
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE 
	|	InventoryKinds.InventoryType IN (&SelectionInventoryTypes_SubstitutionSuffix)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	TransferSettings.CompanyCustomer AS CompanyCustomer,
	|	TransferSettings.GoodsTransferMethod AS GoodsTransferMethod,
	|	TransferSettings.CompanyOwner AS CompanyOwner,
	|	TransferSettings.InventoryTypeOfOwner AS InventoryTypeOfOwner,
	|	InventoryKinds.Ref AS InventoryOwnerAttributeOfCompanyGoodsOwner
	|INTO TransferSettingsSupplementedWithInventoryViews_SubstitutionSuffix
	|FROM
	|	SelectionTypesOfStocks_SubstitutionSuffix AS InventoryKinds
	|	INNER JOIN TransferSettings_SubstitutionSuffix AS TransferSettings
	|	ON InventoryKinds.InventoryType = TransferSettings.InventoryTypeOfOwner
	|WHERE
	|	&RequestExclusionCondition_Intercampany_SubstitutionSuffix
	|
	|INDEX BY 
	|	InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	CompanyOwner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	CompanyGoodsBalance.Organization AS Organization,
	|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanyGoodsBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanyGoodsBalance.CountBalance AS CountBalance
	|INTO QuotesFromOwnerCompanies_SubstitutionSuffix
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|			,
	|			Organization IN
	|					(SELECT
	|						TransferSettings.CompanyOwner
	|					FROM
	|						TransferSettings_SubstitutionSuffix AS TransferSettings)
	|				AND ItemsLocationAttributes IN
	|					(SELECT
	|						InventoryLocationAttributeKeys.DimensionKey
	|					FROM
	|						InformationRegister.ItemsLocationAttributes AS InventoryLocationAttributeKeys
	|					WHERE
	|						InventoryLocationAttributeKeys.StorageLocation = &SelectionOfSellerSStorageLocation_SubstitutionSuffix
	|						AND &SubstitutionCondition_SelectionByCollectionOfGoods)
	|				AND InventoryOwnerAttribute IN (SELECT Ref FROM SelectionTypesOfStocks_SubstitutionSuffix)) AS CompanyGoodsBalance
	|		INNER JOIN ThereAreTransferSettings_SubstitutionSuffix AS ThereAreTransferSettings
	|		ON ThereAreTransferSettings.ThereAreRecords
	|WHERE
	|	&RequestExclusionCondition_Intercampany_SubstitutionSuffix
	|INDEX BY
	|	InventoryOwnerAttribute,
	|	Organization 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	""Balance"" AS Receipt,
	|	""Native"" AS AddlInfo,
	|	CompanyGoodsBalance.Organization AS Organization,
	|	CompanyGoodsBalance.ItemsLocationAttributes.Products AS DimensionProducts,
	|	CompanyGoodsBalance.ItemsLocationAttributes.Characteristic AS DimensionCharacteristic,
	|	CompanyGoodsBalance.ItemsLocationAttributes.Series AS DimensionSeries,
	|	CompanyGoodsBalance.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	CASE 
	|		WHEN CompanyGoodsBalance.InventoryOwnerAttribute.InventoryType = 
	|				VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 3
	|		ELSE 1
	|	END PriorityByGoodsStockType,
	|	CompanyGoodsBalance.InventoryOwnerAttribute.Counterparty AS Consignor,
	|	CompanyGoodsBalance.CountBalance AS CountBalance
	|INTO DataOnInventoryTypesBeforeFolding_SubstitutionSuffix
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|			,
	|			Organization = &SelectionCompanySeller_SubstitutionSuffix
	|				AND ItemsLocationAttributes IN
	|					(SELECT
	|						InventoryLocationAttributeKeys.DimensionKey
	|					FROM
	|						InformationRegister.ItemsLocationAttributes AS InventoryLocationAttributeKeys
	|					WHERE
	|						InventoryLocationAttributeKeys.StorageLocation = &SelectionOfSellerSStorageLocation_SubstitutionSuffix
	|						AND &SubstitutionCondition_SelectionByCollectionOfGoods)
	|				AND InventoryOwnerAttribute IN (SELECT Ref FROM SelectionTypesOfStocks_SubstitutionSuffix)) AS CompanyGoodsBalance
	|
	|UNION ALL
	|
	|SELECT
	|	""Balance"",
	|	""Intercompany"",
	|	CompanyGoodsBalance.Organization,
	|	CompanyGoodsBalance.ItemsLocationAttributes.Products,
	|	CompanyGoodsBalance.ItemsLocationAttributes.Characteristic,
	|	CompanyGoodsBalance.ItemsLocationAttributes.Series,
	|	CASE
	|		WHEN TransferSettings.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.Sale)
	|			THEN VALUE(Enum.InventoryTypes.OwnGoods)
	|		ELSE VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	END,
	|	2,
	|	CASE 
	|		WHEN TransferSettings.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.Sale) 
	|			THEN UNDEFINED 
	|		ELSE TransferSettings.CompanyOwner 
	|	END,
	|	CompanyGoodsBalance.CountBalance
	|FROM
	|	QuotesFromOwnerCompanies_SubstitutionSuffix AS CompanyGoodsBalance
	|		INNER JOIN TransferSettingsSupplementedWithInventoryViews_SubstitutionSuffix AS TransferSettings
	|		ON CompanyGoodsBalance.Organization = TransferSettings.CompanyOwner
	|			AND CompanyGoodsBalance.InventoryOwnerAttribute = TransferSettings.InventoryOwnerAttributeOfCompanyGoodsOwner
	|WHERE
	|	&RequestExclusionCondition_Intercampany_SubstitutionSuffix
	|
	|UNION ALL
	|
	|SELECT
	|	OpenShiftData.Receipt,
	|	OpenShiftData.CommunicationStorno,
	|	OpenShiftData.Organization,
	|	OpenShiftData.Products,
	|	OpenShiftData.Characteristic,
	|	OpenShiftData.Series,
	|	OpenShiftData.TypeOfStock,
	|	OpenShiftData.PriorityByGoodsStockType,
	|	OpenShiftData.ConsignorOfReceipt,
	|	OpenShiftData.Count
	|FROM
	|	OpenShiftData_SubstitutionSuffix AS OpenShiftData
	|
	|INDEX BY
	|	DimensionProducts,
	|	DimensionCharacteristic,
	|	DimensionSeries
	|	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataOnTypesOfStocks.Organization AS Organization,
	|	DataOnTypesOfStocks.DimensionProducts AS DimensionProducts,
	|	DataOnTypesOfStocks.DimensionCharacteristic AS DimensionCharacteristic,
	|	DataOnTypesOfStocks.DimensionSeries AS DimensionSeries,
	|	DataOnTypesOfStocks.InventoryType AS InventoryType,
	|	DataOnTypesOfStocks.PriorityByGoodsStockType AS PriorityByGoodsStockType,
	|	DataOnTypesOfStocks.Consignor AS Consignor,
	|	SUM(DataOnTypesOfStocks.CountBalance) AS CountBalance
	|INTO DataOnInventoryTypes_SubstitutionSuffix
	|FROM
	|	DataOnInventoryTypesBeforeFolding_SubstitutionSuffix AS DataOnTypesOfStocks
	|
	|GROUP BY
	|	DataOnTypesOfStocks.Organization,
	|	DataOnTypesOfStocks.DimensionProducts,
	|	DataOnTypesOfStocks.DimensionCharacteristic,
	|	DataOnTypesOfStocks.DimensionSeries,
	|	DataOnTypesOfStocks.InventoryType,
	|	DataOnTypesOfStocks.PriorityByGoodsStockType,
	|	DataOnTypesOfStocks.Consignor
	|
	|HAVING
	|	SUM(DataOnTypesOfStocks.CountBalance) > 0
	|
	|INDEX BY
	|	DimensionProducts,
	|	DimensionCharacteristic,
	|	DimensionSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataOnTypesOfStocks.DimensionProducts AS Products,
	|	DataOnTypesOfStocks.DimensionCharacteristic AS Characteristic,
	|	DataOnTypesOfStocks.DimensionSeries AS Series,
	|	MIN(DataOnTypesOfStocks.PriorityByGoodsStockType) AS PriorityByGoodsStockType
	|INTO PrioritySelection_SubstitutionSuffix
	|	FROM
	|		DataOnInventoryTypes_SubstitutionSuffix AS DataOnTypesOfStocks
	|	
	|GROUP BY
	|	DataOnTypesOfStocks.DimensionProducts,
	|	DataOnTypesOfStocks.DimensionCharacteristic,
	|	DataOnTypesOfStocks.DimensionSeries
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataOnTypesOfStocks.DimensionProducts AS Products,
	|	DataOnTypesOfStocks.DimensionCharacteristic AS Characteristic,
	|	DataOnTypesOfStocks.DimensionSeries AS Series,
	|	DataOnTypesOfStocks.PriorityByGoodsStockType AS PriorityByGoodsStockType,
	|	MAX(DataOnTypesOfStocks.CountBalance) AS CountBalance
	|	
	|INTO SelectionByPriorityOfQuantity_SubstitutionSuffix
	|
	|FROM
	|	DataOnInventoryTypes_SubstitutionSuffix AS DataOnTypesOfStocks
	|	INNER JOIN PrioritySelection_SubstitutionSuffix AS FilterByPriority
	|	ON DataOnTypesOfStocks.DimensionProducts = FilterByPriority.Products
	|	AND DataOnTypesOfStocks.DimensionCharacteristic = FilterByPriority.Characteristic
	|	AND DataOnTypesOfStocks.DimensionSeries = FilterByPriority.Series
	|	AND DataOnTypesOfStocks.PriorityByGoodsStockType = FilterByPriority.PriorityByGoodsStockType
	|
	|GROUP BY
	|	DataOnTypesOfStocks.DimensionProducts,
	|	DataOnTypesOfStocks.DimensionCharacteristic,
	|	DataOnTypesOfStocks.DimensionSeries,
	|	DataOnTypesOfStocks.PriorityByGoodsStockType
	|
	|INDEX BY 
	|	Products,
	|	Characteristic,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataOnTypesOfStocks.DimensionProducts AS Products,
	|	DataOnTypesOfStocks.DimensionCharacteristic AS Characteristic,
	|	DataOnTypesOfStocks.DimensionSeries AS Series,
	|	MAX(DataOnTypesOfStocks.Consignor) AS Consignor
	|INTO BalanceDataIncludingConsignors_SubstitutionSuffix
	|
	|FROM
	|	DataOnInventoryTypes_SubstitutionSuffix AS DataOnTypesOfStocks
	|	INNER JOIN SelectionByPriorityOfQuantity_SubstitutionSuffix AS FilterByPriority
	|	ON DataOnTypesOfStocks.DimensionProducts = FilterByPriority.Products
	|	AND DataOnTypesOfStocks.DimensionCharacteristic = FilterByPriority.Characteristic
	|	AND DataOnTypesOfStocks.DimensionSeries = FilterByPriority.Series
	|	AND DataOnTypesOfStocks.PriorityByGoodsStockType = FilterByPriority.PriorityByGoodsStockType
	|	AND DataOnTypesOfStocks.CountBalance = FilterByPriority.CountBalance
	|GROUP BY
	|	DataOnTypesOfStocks.DimensionProducts,
	|	DataOnTypesOfStocks.DimensionCharacteristic,
	|	DataOnTypesOfStocks.DimensionSeries
	|INDEX BY 
	|	Products,
	|	Characteristic,
	|	Series
	|";
	
	SubstitutionCondition = "&SubstitutionCondition_SelectionByCollectionOfGoods";
	If ThisIsExchangeRequest Then
		Value_Substitution = "TRUE";
	Else
		Value_Substitution = "(InventoryLocationAttributeKeys.Products, InventoryLocationAttributeKeys.Characteristic, InventoryLocationAttributeKeys.Series) 
							|		IN (SELECT Products, Characteristic, Series FROM  #CollectionProducts)";
	EndIf;
	QueryText = StrReplace(QueryText, SubstitutionCondition, Value_Substitution);
	
	SubstitutionCondition = "&SubstitutionCondition_SelectionOfChecksByComposition";
	If ThisIsExchangeRequest Then
		Value_Substitution = "TRUE";
	Else
		Value_Substitution = "	(ReceiptGoods.Products, ReceiptGoods.Characteristic, ReceiptGoods.Series) IN
					|			(SELECT
					|				CollectionProducts.Products,
					|				CollectionProducts.Characteristic,
					|				CollectionProducts.Series
					|			FROM
					|				#CollectionProducts AS CollectionProducts)";
	EndIf;
	QueryText = StrReplace(QueryText, SubstitutionCondition, Value_Substitution);
	
	PackageQueries = SplitBatchRequest(QueryText);

	PackageRequestsThatAreBeingDeleted = New Array;
	AdjustedPackageRequests = New Array;
	If Not UseIntercampany Then
		PackageRequestsThatAreBeingDeleted.Add("TransferSettings_SubstitutionSuffix");
		PackageRequestsThatAreBeingDeleted.Add("ThereAreTransferSettings_SubstitutionSuffix");
		PackageRequestsThatAreBeingDeleted.Add("QuotesFromOwnerCompanies_SubstitutionSuffix");
		PackageRequestsThatAreBeingDeleted.Add("TransferSettingsSupplementedWithInventoryViews_SubstitutionSuffix");
		AdjustedPackageRequests.Add("DataOnInventoryTypesBeforeFolding_SubstitutionSuffix");
	EndIf;
	
	PackageSize = PackageQueries.Count();
	For SchIndexOfQuery = 1 To PackageSize Do
		ListItem = PackageQueries.Get(PackageSize - SchIndexOfQuery);
		If PackageRequestsThatAreBeingDeleted.Find(ListItem.Presentation) <> Undefined Then
			PackageQueries.Delete(ListItem);
		ElsIf AdjustedPackageRequests.Find(ListItem.Presentation) <> Undefined Then
			LiteralSeparator = "UNION ALL";
			PartsOfAssociation = 
				StringFunctionsClientServer.SplitStringIntoSubstringsArray(ListItem.Value, LiteralSeparator);
			NumberOfParts = PartsOfAssociation.Count();
			ThereIsCorrection = False;
			For SchIndexOfPart = 1 To NumberOfParts-2 Do
				UnionElement = PartsOfAssociation[NumberOfParts-1-SchIndexOfPart];
				If Not UseIntercampany 
					And StrFind(UnionElement, "RequestExclusionCondition_Intercampany_SubstitutionSuffix") Then
					PartsOfAssociation.Delete(NumberOfParts-1-SchIndexOfPart);
					ThereIsCorrection = True;
				EndIf;
			EndDo;
			If ThereIsCorrection Then
				ListItem.Value = StrConcat(PartsOfAssociation, LiteralSeparator);
			EndIf;
		EndIf;
	EndDo;
	
	For Each ElemRequest In PackageQueries Do
		NameSubstitution.Add(ElemRequest.Presentation, StrReplace(ElemRequest.Presentation, "_SubstitutionSuffix", NameSuffix));
		For Each AleSubstitution In NameSubstitution Do
			ElemRequest.Value = StrReplace(ElemRequest.Value, AleSubstitution.Value, AleSubstitution.Presentation);
			ElemRequest.Presentation = StrReplace(ElemRequest.Presentation, AleSubstitution.Value, AleSubstitution.Presentation);
		EndDo;
	EndDo;
	
	Result = New Structure("QueryOptions, QueryBatch", RequestParametersAreFinal, PackageQueries);
	
	Return Result;
	
EndFunction

#EndRegion

#Region GetAddIns

// Fill in the description of custom scheduled tasks.
// 
// Parameters:
//  DescriptionOfCustomScheduledTasks - Structure - Description Of Custom Scheduled Tasks
Procedure FillInDescriptionOfCustomRoutineTasks(DescriptionOfCustomScheduledTasks) Export
	
	
EndProcedure

// Sets the visibility of Internet support sections on the form
// 
// Parameters:
//  Form - ClientApplicationForm - Form
Procedure SetPartitionVisibility(Form) Export
	
	
EndProcedure

#EndRegion

// Receives the payment link from the transmitted document, converts it into an image of the QR code of the SBP
// and sets the value of the QR Code card parameter. If successful, it returns True.
// 
// Parameters:
//  PrintData - Structure:
//    *Organization - CatalogRef.Companies
//    *Ref - DocumentRef
//  QRCode_Picture - Picture
//  Size - Number
//  
// Returns:
//  Boolean - 
//
Function OutputQRCode(PrintData, QRCode_Picture, Size) Export
	
	Result = False;
	

	Return Result;
EndFunction

// Managing the visibility of form elements for managing the settings for working with connected equipment
//
// Parameters:
//  Form - ClientApplicationForm -
//
Procedure TMAdministrationPanelHardwareSettingsAdjustVisibilityOfItems(Form) Export
EndProcedure

// Description of collection string handlers:
// 
// Parameters:
//  StringHandlers - ValueList of String - Contains the correspondence of the action on the string and the method.
//
Procedure WhenAddingCollectionLineHandlers(StringHandlers) Export
	
	
EndProcedure

// Divides the rows of the transmitted table into those in which the price needs to be filled in and those in which the price does not need to be filled in. 
// It is used to separate batch processing actions of tabular parts in retail documents.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  OriginalLines - DocumentTabularSection.CashRegisterReceipt.Goods, DocumentTabularSection.CashRegisterReceiptReturn.Goods - 
//  StringsForDifferentTypesOfActions - Structure:
//		*NotItIsRequiredToFillInPrice - Array of DocumentTabularSectionRow.CashRegisterReceipt.Goods, DocumentTabularSectionRow.CashRegisterReceiptReturn.Goods -
//		*ItIsRequiredToFillInPrice - Array of DocumentTabularSectionRow.CashRegisterReceipt.Goods, DocumentTabularSectionRow.CashRegisterReceiptReturn.Goods -
//
Procedure SplitArrayOfStringsForDifferentTypesOfBatchProcessing(Form, OriginalLines, StringsForDifferentTypesOfActions) Export

	
EndProcedure

#EndRegion

#Region Private


#Region ConsigneeInReceipt

// Represents the incoming text of the batch query as a list of values, where the text of the atomic query is the value of the element,
// and the name of the table being created is the Presentation of the list element. 
// Parameters:
//	TextOfBatchRequest - String - 	boundary conditions for packet request decomposition:
//			1) The query separator ";" is placed on a separate line.
// 			2) the name of the created table is placed on a separate line along with the key literal "PLACE".
//
// Returns:
// ValueList of String 
// 	*the value is the text of the atomic query, 
// 	*Presentation - the name of the temporary table created by this query
Function SplitBatchRequest(Val TextOfBatchRequest)
	
	PackageText = TrimAll(TextOfBatchRequest);
	ListOfRequests = New ValueList;
	
	CurrQuery = "";
	NameOfNewTT = "";
	
	For AccRows = 1 To StrLineCount(PackageText) Do
		
		CurRow = StrGetLine(PackageText, AccRows);
		ContentRow = TrimAll(CurRow);
		
		If StrStartsWith(ContentRow, ";") Then
			// this is the query separator
			If Not IsBlankString(CurrQuery) Then
				ListOfRequests.Add(CurrQuery, NameOfNewTT);
				CurrQuery = "";
				NameOfNewTT = "";
			EndIf;
			
			Continue;
			
		ElsIf StrStartsWith(Upper(ContentRow), "INTO") Then
			// This is the name of TT
			NameOfNewTT = TrimAll(Mid(ContentRow, 10));
		EndIf;
		CurrQuery = CurrQuery + Chars.LF + CurRow;
	EndDo;
	If Not IsBlankString(CurrQuery) Then
		ListOfRequests.Add(CurrQuery, NameOfNewTT);
	EndIf;
	
	Return ListOfRequests;
EndFunction

#EndRegion

#EndRegion