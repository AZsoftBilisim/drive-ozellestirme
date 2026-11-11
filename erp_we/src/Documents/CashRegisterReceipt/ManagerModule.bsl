
#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" Then
		
		If Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
			
			StandardProcessing = False;
			SelectedForm = "DocumentForm";
			
		Else
			
			StandardProcessing = False;
			SelectedForm = "CWPDocumentForm";
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

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
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("GiftCertificates");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("PricesAndDiscounts");
	CashRegisterReceiptLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of value table elements with data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.CashRegisterReceipt") Then
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
		
		QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers);
		QueryTextTableAcquiringContractARAP(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextGiftCertificates(Query, QueryTexts, Registers);
		QueryTextGiftCardHistory(Query, QueryTexts, Registers);
		QueryTextBonusPoints(Query, QueryTexts, Registers);
		QueryTextTableCashInTransit(Query, QueryTexts, Registers);
		
		CashRegisterReceiptLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ArrangeShipmentAtRetail(Query, QueryTexts, Registers);
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,Status,Date";
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	SeriesSpecificationParameters.FullObjectName = "Document.CashRegisterReceipt";

	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.RetailShipment);

	If WarehousesServer.UseWarerooms(Object.Warehouse) Then
		SeriesSpecificationParameters.LinkFields.Add("Premise");
	EndIf;
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.SelectionPlanning = True;	
	SeriesSpecificationParameters.FactOfSelection = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.DocumentOperation_ = Enums.BusinessTransactions.RetailSaleOfGoods;
	
	SeriesSpecificationParameters.ReadOnly = (Object.Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_);
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the status of the document.
//
// Parameters:
//  Ref - DocumentRef.CashRegisterReceipt - Link to the CMC receipt.
//
// Returns:
//  EnumRef.CashRegisterReceiptStatuses - The status of the KKM receipt.
//
Function DocumentStatus(Ref) Export
	
	Query = New Query;
	Query.Text = "SELECT
	|	CashRegisterReceipt.Status
	|FROM
	|	Document.CashRegisterReceipt AS CashRegisterReceipt
	|WHERE
	|	CashRegisterReceipt.Ref = &Ref";
	
	Query.SetParameter("Ref", Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		Return Selection.Status;
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
	
	ThereArePremises = (SeriesSpecificationParameters.LinkFields.Find("Premise") <> Undefined);
	If ThereArePremises Then
		Return RequestTextForFillingInStatusesForSpecifyingSeriesWithPremises();
	Else
		Return TextOfRequestToFillInStatusesForSpecifyingSeriesWithoutRooms();
	EndIf;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.DiscountsAppliedInDocument.AddReportCommand(ReportsCommands);
	
EndProcedure

#Region Other

#EndRegion

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.CashRegisterReceipt - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Object.Warehouse);
	Organization = SettingsValueCached.GetDefaultOrganization(Object.Organization);
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Warehouse = Warehouse;
	
	FillParameters.Retail_ = True;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for receiving non-returned goods by Cash register receipt.
//
// Returns:
//  Structure:
//   *CashRegisterReceipt - DocumentRef.CashRegisterReceipt
//   *UsedByKKTFZ54 - Boolean
//   *CashRegisterIsUsedWithoutConnectionOfEquipment - Boolean
//   *CashRegisterShift - DocumentRef.CashRegisterShift
//   *CashRegisterReceiptNumber - Number
//   *Products - CatalogRef.Products
//   *LoyaltyCard - CatalogRef.LoyaltyCards
//   *Period - StandardPeriod
//
Function ParametersForReceivingNonReturnedItemsByCashRegisterReceipt() Export
	
	Result = New Structure;
	Result.Insert("CashRegisterReceipt", PredefinedValue("Document.CashRegisterReceipt.EmptyRef"));		
	Result.Insert("UsedByKKTFZ54", False);	
	Result.Insert("CashRegisterIsUsedWithoutConnectionOfEquipment", False);
	Result.Insert("CashRegisterShift", PredefinedValue("Document.CashRegisterShift.EmptyRef"));
	Result.Insert("CashRegisterReceiptNumber", 0);
	Result.Insert("Products", PredefinedValue("Catalog.Products.EmptyRef"));
	Result.Insert("LoyaltyCard", PredefinedValue("Catalog.LoyaltyCards.EmptyRef"));
	Result.Insert("Period", New StandardPeriod);
	Result.Insert("Organization", PredefinedValue("Catalog.Companies.EmptyRef"));
		
	Return Result;
EndFunction

Function TableOfNonReturnedItemsByCashRegisterReceipt(FilterParameters) Export

	Query = New Query(QueryTextForReceivingNonReturnedItemsByCashRegisterReceipt(FilterParameters));
	
	If ValueIsFilled(FilterParameters.CashRegisterReceipt) Then
		Query.Parameters.Insert("CashRegisterReceipt", FilterParameters.CashRegisterReceipt);
	EndIf;
	If ValueIsFilled(FilterParameters.CashRegisterReceiptNumber) Then
		Query.Parameters.Insert("CashRegisterReceiptNumber", FilterParameters.CashRegisterReceiptNumber);
	EndIf;
	If ValueIsFilled(FilterParameters.Products) Then
		Query.Parameters.Insert("Products", FilterParameters.Products);
	EndIf;
	If ValueIsFilled(FilterParameters.LoyaltyCard) Then
		Query.Parameters.Insert("LoyaltyCard", FilterParameters.LoyaltyCard);
	EndIf;
	If FilterParameters.UsedByKKTFZ54 
		Or FilterParameters.CashRegisterIsUsedWithoutConnectionOfEquipment Then
		SelectionParametersPeriod = FilterParameters.Period; // StandardPeriod
		Query.Parameters.Insert("StartDate",     SelectionParametersPeriod.StartDate);
		Query.Parameters.Insert("EndDate",  SelectionParametersPeriod.EndDate);
		Query.Parameters.Insert("NoPeriodEndLimit", Not ValueIsFilled(SelectionParametersPeriod.EndDate));
		Query.Parameters.Insert("CashRegisterShift", FilterParameters.CashRegisterShift);
	ElsIf ValueIsFilled(FilterParameters.CashRegisterShift) Then
		Query.Parameters.Insert("CashRegisterShift", FilterParameters.CashRegisterShift);
	EndIf;
	If ValueIsFilled(FilterParameters.Organization) Then
		Query.Parameters.Insert("Organization", FilterParameters.Organization);
	EndIf;
	
	TableOfGoods 	= Query.Execute().Unload();
	TheStructureOfTheSearch = New Structure("CashRegisterReceipt, Products, Characteristic, ProductsInSet, 
			|ItemVariantOfSet, Series, VATRate");
	
	For Each String In TableOfGoods Do
		
		If String.Count < 0 Then
		
			FillPropertyValues(TheStructureOfTheSearch, String);
			SalesLines = TableOfGoods.FindRows(TheStructureOfTheSearch);
			
			For Each LineOfSale In SalesLines Do
			
				If LineOfSale.Count < 0 Then
					Continue;
				EndIf; 
				
				String.Count 		= -String.Count;
				String.Sum 			= -String.Sum;
				String.VATAmount 		= -String.VATAmount;
				//Line.SummaSNDS 		= -String.SummaSNDS;
				
				If String.Count > LineOfSale.Count Then
					AmountToDeduct 	= LineOfSale.Count;
					AmountToDeduct_ 		= LineOfSale.Sum;
					AmountOfVATDeducted 	= LineOfSale.VATAmount;
					//SummaSNDSNaVeset 	= Sale string.SummaSNDS;
				Else
					AmountToDeduct 	= String.Count;
					AmountToDeduct_ 		= String.Sum;
					AmountOfVATDeducted 	= String.VATAmount;
					//SummaSNDSNaVeset 	= String.SummaSNDS;
				EndIf;
				
				LineOfSale.Count 	= LineOfSale.Count - AmountToDeduct;
				String.Count 			= String.Count - AmountToDeduct;
				
				LineOfSale.Sum 		= LineOfSale.Sum - AmountToDeduct_;
				String.Sum 				= String.Sum - AmountToDeduct_;
				
				LineOfSale.VATAmount 		= LineOfSale.VATAmount - AmountOfVATDeducted;
				String.VATAmount 			= String.VATAmount - AmountOfVATDeducted;
				
				//Sales string.SummaSNDS	= Sale string.SummaSNDS - summasndsnavesets;
				//Line.SummaSNDS			= Line.SummaSNDS - summasndsnavesets;
			
			EndDo; 
		
		EndIf; 
	
	EndDo; 
	
	ArrayOfRowsToDelete_1 = New Array();
	For Each String In TableOfGoods Do 
		If String.Count <= 0 Then
			ArrayOfRowsToDelete_1.Add(String);
		EndIf;
	EndDo;
	For Each String In ArrayOfRowsToDelete_1 Do
		TableOfGoods.Delete(String);
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(TableOfGoods, StructureOfActions);
	
	Return TableOfGoods;
	
EndFunction

// Returns the Query Text for receiving non-returned goods by Cash Register receipt.
//
// Parameters:
//  FilterParameters - See ParametersForReceivingNonReturnedItemsByCashRegisterReceipt
// Returns:
//  String - 
//
Function QueryTextForReceivingNonReturnedItemsByCashRegisterReceipt(FilterParameters) Export
	
	TextOfCashRegisterReceiptCondition					   = "AND T.Ref = &CashRegisterReceipt";
	TextOfConditionReceiptCashRegisterRefund			   = "AND T.CashRegisterReceipt = &CashRegisterReceipt";
	TextOfConditionFilterByDate				   = "AND T.Date >= &StartDate AND (T.Date <= &EndDate OR &NoPeriodEndLimit)";
	TextOfConditionFilterByDateReturn		   = "AND T.Date >= &StartDate";
	TextOfConditionFilterByCashShift	   = "AND T.CashRegisterShift = &CashRegisterShift";
	ConditionTextReceiptNumber                  = "AND ISNULL(FiscalTransactions.CashRegisterReceiptNumber, 0) = &CashRegisterReceiptNumber";
	TextOfLoyaltyCardTermsAndConditions            = "AND T.LoyaltyCard = &LoyaltyCard";
	TextOfCompanyCondition                = "";
	TextOfCompanyConditionOnLink        = "";
	If ValueIsFilled(FilterParameters.Organization) Then
		TextOfCompanyCondition            = "AND T.Organization = &Organization";
		TextOfCompanyConditionOnLink    = "AND T.Ref.Organization = &Organization";
	EndIf;
	
	// More than one parameter to the left of "IN", replaces IN with EXISTS.
	If FilterParameters.UsedByKKTFZ54 
		Or FilterParameters.CashRegisterIsUsedWithoutConnectionOfEquipment Then
		TextOfProductItemCondition =
		"AND (T.Ref, TRUE) IN (
		|	SELECT 
		|		T.Ref,
		|		TRUE
		|FROM
		|	Document.CashRegisterReceipt.Goods AS T
		|WHERE
		|	T.Ref.Date >= &StartDate
		|	" + ?(ValueIsFilled(FilterParameters.CashRegisterReceipt),    TextOfCashRegisterReceiptCondition, TextOfCompanyConditionOnLink) + "
		|	AND T.Products = &Products 
		|	AND (T.Ref.Date <= &EndDate OR &NoPeriodEndLimit))
		|";
		
	Else
		TextOfProductItemCondition =
		"AND (T.Ref, TRUE) IN (
		|	SELECT 
		|		T.Ref, 
		|		TRUE
		|FROM
		|	Document.CashRegisterReceipt.Goods AS T
		|WHERE
		|	T.Ref.CashRegisterShift = &CashRegisterShift
		|	" + ?(ValueIsFilled(FilterParameters.CashRegisterReceipt),    TextOfCashRegisterReceiptCondition,        "") + "			
		|	AND T.Products = &Products)
		|";
	EndIf;
	
	QueryText =
	"SELECT ALLOWED
	|	T.Ref AS Ref,
	|	T.Ref AS CashRegisterReceipt,
	|	T.Date AS Date,
	|	T.LoyaltyCard AS LoyaltyCard,
	|	T.Partner AS Partner,
	|	ISNULL(FiscalTransactions.CashRegisterReceiptNumber, 0) AS CashRegisterReceiptNumber
	|INTO CashRegisterReceipts
	|FROM
	|	Document.CashRegisterReceipt AS T
	|	LEFT JOIN InformationRegister.FiscalTransactions AS FiscalTransactions
	|		ON T.Ref = FiscalTransactions.DocumentBasis
	|WHERE
	|	T.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND NOT (T.Ref, TRUE) IN
	|			(SELECT
	|				ReceiptOfCashRegisterAdjustment.CashRegisterReceipt, TRUE
	|			FROM
	|				Document.ReceiptOfCashRegisterAdjustment AS ReceiptOfCashRegisterAdjustment
	|			WHERE 
	|				ReceiptOfCashRegisterAdjustment.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|				AND ReceiptOfCashRegisterAdjustment.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors))
	|	" + ?(ValueIsFilled(FilterParameters.CashRegisterReceipt),          TextOfCashRegisterReceiptCondition, TextOfCompanyCondition) + "
	|	" + ?(FilterParameters.UsedByKKTFZ54 
				Or FilterParameters.CashRegisterIsUsedWithoutConnectionOfEquipment, TextOfConditionFilterByDate, TextOfConditionFilterByCashShift) + "
	|	" + ?(ValueIsFilled(FilterParameters.CashRegisterReceiptNumber),    ConditionTextReceiptNumber,           "") + "
	|	" + ?(ValueIsFilled(FilterParameters.LoyaltyCard), TextOfLoyaltyCardTermsAndConditions,     "") + "
	|	" + ?(ValueIsFilled(FilterParameters.Products),    TextOfProductItemCondition,        "") + "
	|
	|INDEX BY Ref
	|;
	|
	|SELECT ALLOWED
	|	T.Ref AS Ref,
	|	T.CashRegisterReceipt AS CashRegisterReceipt,
	|	T.CashRegisterReceipt.Date AS DATE,
	|	T.CashRegisterReceipt.LoyaltyCard AS LoyaltyCard,
	|	T.CashRegisterReceipt.Partner AS Partner,	
	|	0 AS CashRegisterReceiptNumber
	|INTO CashRegisterReceiptsRefund	
	|FROM
	|	Document.CashRegisterReceiptReturn AS T
	|WHERE
	|	T.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND NOT T.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
	|	" + ?(ValueIsFilled(FilterParameters.CashRegisterReceipt),          TextOfConditionReceiptCashRegisterRefund, TextOfCompanyCondition) + "
	|	" + ?(FilterParameters.UsedByKKTFZ54 
				Or FilterParameters.CashRegisterIsUsedWithoutConnectionOfEquipment, TextOfConditionFilterByDateReturn, TextOfConditionFilterByCashShift) + "
	|
	|INDEX BY Ref
	|;
	|
	|SELECT DISTINCT
	|	T.CashRegisterReceipt AS CashRegisterReceipt
	|INTO CashRegisterReceiptsForWhichReturnsHaveBeenMade	
	|FROM
	|	CashRegisterReceiptsRefund AS T
	|
	|INDEX BY CashRegisterReceipt
	|;
	|
	|///////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ISNULL(T.Ref, VALUE(Document.CashRegisterReceiptReturn.EmptyRef))) AS Ref,
	|	CashRegisterReceipts.CashRegisterReceipt AS CashRegisterReceipt
	|INTO DeferredReceiptsCashRegisterRefund	
	|FROM
	|	CashRegisterReceipts AS CashRegisterReceipts
	|LEFT JOIN Document.CashRegisterReceiptReturn AS T
	|	ON T.CashRegisterReceipt = CashRegisterReceipts.Ref
	|WHERE
	|	T.Status <> VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|GROUP BY
	|	CashRegisterReceipts.CashRegisterReceipt
	|INDEX BY CashRegisterReceipt
	|;
	|
	|///////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = QueryText +
	"SELECT DISTINCT
	|	CashRegisterReceipts.Ref AS Ref,
	|	TRUE AS PaidByCard
	|INTO CashRegisterReceiptsPaidByCards
	|FROM
	|	CashRegisterReceipts AS CashRegisterReceipts
	|		INNER JOIN Document.CashRegisterReceipt.PaymentWithPaymentCards AS PaymentWithPaymentCards
	|		ON CashRegisterReceipts.Ref = PaymentWithPaymentCards.Ref
	|
	|INDEX BY Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS CashRegisterReceipt,
	|	CashRegisterReceipts.Date AS Date,
	|	CashRegisterReceipts.LoyaltyCard AS LoyaltyCard,
	|	CashRegisterReceipts.Partner AS Partner,
	|	CashRegisterReceipts.CashRegisterReceiptNumber AS CashRegisterReceiptNumber,
	|	Goods.USAISProducts AS USAISProducts,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Package AS Package,
	|	SUM(Goods.NumberOfPackages) AS NumberOfPackages,
	|	SUM(Goods.Count) AS Count,
	|	CAST(CASE
	|			WHEN Goods.ManualDiscount + Goods.DiscountMarkupAmount + Goods.AmountOfBonusPointsToDeductionInCurrency = 0
	|					OR Goods.NumberOfPackages = 0
	|				THEN Goods.Price
	|			ELSE Goods.Sum / Goods.NumberOfPackages
	|		END AS NUMBER(31, 2)) AS Price,
	|	SUM(Goods.Sum) AS Sum,
	|	Goods.VATRate AS VATRate,
	|	SUM(Goods.VATAmount) AS VATAmount,
	|	Goods.Premise AS Premise,
	|	Goods.Seller AS Seller,
	|	Goods.Consignor AS Consignor
	|INTO SoldPositions
	|FROM
	|	CashRegisterReceipts AS CashRegisterReceipts
	|		INNER JOIN Document.CashRegisterReceipt.Goods AS Goods
	|		ON CashRegisterReceipts.Ref = Goods.Ref
	|
	|GROUP BY
	|	Goods.Ref,
	|	CashRegisterReceipts.Date,
	|	CashRegisterReceipts.LoyaltyCard,
	|	CashRegisterReceipts.Partner,	
	|	CashRegisterReceipts.CashRegisterReceiptNumber,
	|	Goods.USAISProducts,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	Goods.BatchesIndicationStatus,
	|	Goods.Package,
	|	CAST(CASE
	|			WHEN Goods.ManualDiscount + Goods.DiscountMarkupAmount + Goods.AmountOfBonusPointsToDeductionInCurrency = 0
	|					OR Goods.NumberOfPackages = 0
	|				THEN Goods.Price
	|			ELSE Goods.Sum / Goods.NumberOfPackages
	|		END AS NUMBER(31, 2)),
	|	Goods.VATRate,
	|	Goods.Premise,
	|	Goods.Seller,
	|	Goods.Consignor
	|;
	|
	|SELECT
	|	CashRegisterReceipts.CashRegisterReceipt AS CashRegisterReceipt,
	|	CashRegisterReceipts.Date AS Date,
	|	CashRegisterReceipts.LoyaltyCard AS LoyaltyCard,
	|	CashRegisterReceipts.Partner AS Partner,
	|	CashRegisterReceipts.CashRegisterReceiptNumber AS CashRegisterReceiptNumber,
	|	Goods.USAISProducts AS USAISProducts,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Package AS Package,
	|	SUM(Goods.NumberOfPackages) AS NumberOfPackages,
	|	SUM(Goods.Count) AS Count,
	|	Goods.Price AS Price,
	|	SUM(Goods.Sum) AS Sum,
	|	Goods.VATRate AS VATRate,
	|	SUM(Goods.VATAmount) AS VATAmount,
	|	Goods.Premise AS Premise,
	|	Goods.Seller AS Seller,
	|	Goods.Consignor AS Consignor
	|INTO ReturnedPositions
	|FROM
	|	CashRegisterReceiptsRefund AS CashRegisterReceipts
	|		INNER JOIN Document.CashRegisterReceiptReturn.Goods AS Goods
	|		ON CashRegisterReceipts.Ref = Goods.Ref
	|WHERE
	|	Goods.NumberOfPackages <> 0
	|
 	|GROUP BY
	|	CashRegisterReceipts.CashRegisterReceipt,
	|	CashRegisterReceipts.Date,
	|	CashRegisterReceipts.LoyaltyCard,
	|	CashRegisterReceipts.Partner,	
	|	CashRegisterReceipts.CashRegisterReceiptNumber,
	|	Goods.USAISProducts,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	Goods.BatchesIndicationStatus,
	|	Goods.Package,
	|	Goods.Price,
	|	Goods.VATRate,
	|	Goods.Premise,
	|	Goods.Seller,
	|	Goods.Consignor
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SoldPositions.CashRegisterReceipt, ReturnedPositions.CashRegisterReceipt) AS CashRegisterReceipt,
	|	ISNULL(SoldPositions.Date, ReturnedPositions.Date) AS Date,
	|	ISNULL(SoldPositions.LoyaltyCard, ReturnedPositions.LoyaltyCard) AS LoyaltyCard,
	|	ISNULL(SoldPositions.Partner, ReturnedPositions.Partner) AS Partner,
	|	ISNULL(SoldPositions.CashRegisterReceiptNumber, ReturnedPositions.CashRegisterReceiptNumber) AS CashRegisterReceiptNumber,
	|	ISNULL(SoldPositions.USAISProducts, ReturnedPositions.USAISProducts) AS USAISProducts,
	|	ISNULL(SoldPositions.BatchesIndicationStatus, ReturnedPositions.BatchesIndicationStatus) AS BatchesIndicationStatus,
	|	ISNULL(SoldPositions.Price, ReturnedPositions.Price) AS Price,
	|	ISNULL(SoldPositions.Premise, ReturnedPositions.Premise) AS Premise,
	|	ISNULL(SoldPositions.Seller, ReturnedPositions.Seller) AS Seller,
	|	ISNULL(SoldPositions.Consignor, ReturnedPositions.Consignor) AS Consignor,
	|	ISNULL(SoldPositions.ProductsInSet, ReturnedPositions.ProductsInSet) AS ProductsInSet,
	|	ISNULL(SoldPositions.ItemVariantOfSet, ReturnedPositions.ItemVariantOfSet) AS ItemVariantOfSet,
	|	ISNULL(SoldPositions.Products, ReturnedPositions.Products) AS Products,
	|	ISNULL(SoldPositions.Characteristic, ReturnedPositions.Characteristic) AS Characteristic,
	|	ISNULL(SoldPositions.Series, ReturnedPositions.Series) AS Series,
	|	ISNULL(SoldPositions.Count, 0) - ISNULL(ReturnedPositions.Count, 0) AS Count,
	|	0 AS NumberOfPackages,
	|	ISNULL(SoldPositions.Package, ReturnedPositions.Package) AS Package,
	|	ISNULL(SoldPositions.VATRate, ReturnedPositions.VATRate) AS VATRate,
	|	ISNULL(SoldPositions.Sum, 0) - ISNULL(ReturnedPositions.Sum, 0) AS Sum,
	|	ISNULL(SoldPositions.VATAmount, 0) - ISNULL(ReturnedPositions.VATAmount, 0) AS VATAmount
	|INTO Result
	|FROM
	|	SoldPositions AS SoldPositions
	|		FULL JOIN ReturnedPositions AS ReturnedPositions
	|		ON SoldPositions.Products = ReturnedPositions.Products
	|			AND SoldPositions.Characteristic = ReturnedPositions.Characteristic
	|			AND SoldPositions.ProductsInSet = ReturnedPositions.ProductsInSet
	|			AND SoldPositions.ItemVariantOfSet = ReturnedPositions.ItemVariantOfSet
	|			AND SoldPositions.Series = ReturnedPositions.Series
	|			AND SoldPositions.Package = ReturnedPositions.Package
	|			AND SoldPositions.VATRate = ReturnedPositions.VATRate
	|			AND SoldPositions.CashRegisterReceipt = ReturnedPositions.CashRegisterReceipt
	|			AND SoldPositions.Price = ReturnedPositions.Price
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	Table.ProductsInSet, 
	|	Table.ItemVariantOfSet,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption
	|INTO SetTableWithOptionForCalculatingSetPrice
	|FROM (SELECT DISTINCT
	|			Table.ProductsInSet, 
	|			Table.ItemVariantOfSet
	|		FROM Result AS Table
	|		WHERE Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)	
	|	) AS Table
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|	ON (ProductKitConfigurations.Owner = Table.ProductsInSet)
	|		AND (ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet)
	|		AND (ProductKitConfigurations.Main)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.CashRegisterReceipt AS CashRegisterReceipt,
	|	Table.CashRegisterReceiptNumber AS CashRegisterReceiptNumber,	
	|	Table.LoyaltyCard AS LoyaltyCard,
	|	Table.Partner AS Client,
	|	ISNULL(CashRegisterReceiptsPaidByCards.PaidByCard, FALSE) AS PaidByCard,
	|	CASE
	|		WHEN Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|			THEN 1
	|		ELSE 0
	|	END AS SetIndex,
	|	ISNULL(ProductKitConfigurations.SetPricingOption, UNDEFINED) AS SetPricingOption,
	|	Table.USAISProducts AS USAISProducts,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.Products AS Products,
	|	CatalogProducts.ItemsType AS ItemsType,
	|	Table.Characteristic AS Characteristic,
	|	Table.Series AS Series,
	|	Table.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Table.Package AS Package,
	|	Table.VATRate AS VATRate,
	|	Table.Price AS Price,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.Count AS Count,
	|	Table.Sum AS Sum,
	|	Table.VATAmount AS VATAmount,
	|	Table.Premise AS Premise,
	|	Table.Seller AS Seller,
	|	Table.Consignor AS Consignor,
	|	ISNULL(DeferredReceiptsCashRegisterRefund.Ref, VALUE(Document.CashRegisterReceiptReturn.EmptyRef)) AS DeferredReceiptCashRegistersRefund,
	|	CASE WHEN ISNULL(CashRegisterReceiptsForWhichReturnsHaveBeenMade.CashRegisterReceipt, VALUE(Document.CashRegisterReceipt.EmptyRef)) = VALUE(Document.CashRegisterReceipt.EmptyRef) 
	|		THEN FALSE 
	|		ELSE TRUE 
	|	END AS PartialReturnHasBeenFormalized,
	|	CASE WHEN CashRegisterReceipts.CashRegisterShift <> &CashRegisterShift 
	|				AND NOT CashRegisterReceiptCashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.Closed_)
	|		THEN TRUE 
	|		ELSE FALSE 
	|	END AS CashRegisterReceiptCashShiftIsOpen
	|
	|FROM
	|	Result AS Table
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = Table.Products
	|		LEFT JOIN CashRegisterReceiptsPaidByCards AS CashRegisterReceiptsPaidByCards
	|		ON Table.CashRegisterReceipt = CashRegisterReceiptsPaidByCards.Ref
	|		LEFT JOIN SetTableWithOptionForCalculatingSetPrice AS ProductKitConfigurations
	|		ON (ProductKitConfigurations.ProductsInSet = Table.ProductsInSet)
	|			AND (ProductKitConfigurations.ItemVariantOfSet = Table.ItemVariantOfSet)
	|		LEFT JOIN DeferredReceiptsCashRegisterRefund AS DeferredReceiptsCashRegisterRefund
	|		ON DeferredReceiptsCashRegisterRefund.CashRegisterReceipt = Table.CashRegisterReceipt
	|		LEFT JOIN CashRegisterReceiptsForWhichReturnsHaveBeenMade AS CashRegisterReceiptsForWhichReturnsHaveBeenMade
	|		ON CashRegisterReceiptsForWhichReturnsHaveBeenMade.CashRegisterReceipt = Table.CashRegisterReceipt
	|		LEFT JOIN Document.CashRegisterReceipt AS CashRegisterReceipts
	|		ON CashRegisterReceipts.Ref = Table.CashRegisterReceipt
	|		LEFT JOIN Document.CashRegisterShift AS CashRegisterReceiptCashRegisterShift
	|		ON CashRegisterReceiptCashRegisterShift.Ref = CashRegisterReceipts.CashRegisterShift
	|
	|ORDER BY
	|	Table.Date DESC,
	|	Table.CashRegisterReceiptNumber DESC,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Series,
	|	Table.Package,
	|	Table.Consignor
	|";
	
	Return QueryText;
EndFunction

// Returns the Query Text for receiving undelivered payments of a certain type by Cash Register receipt.
//
// Parameters:
//  UseSelectionByPaymentType - Boolean - Indicates that the request will use a selection based on the type of payment and you need to specify the value of the corresponding parameter.
//  AllTypesOfPaymentsExceptThoseSpecified - Boolean - Indicates that all payment types that are not included in the passed Payment type parameter will be selected.
// Returns:
//  String - 
//
Function QueryTextForReceivingUndeliveredPaymentsByCashRegisterReceipt(UseSelectionByPaymentType, AllTypesOfPaymentsExceptThoseSpecified = False) Export
	
	QueryText = "SELECT DISTINCT
	|	PaymentCards_.PaymentKind_ AS PaymentKind_,
	|	PaymentCards_.POSTerminal AS POSTerminal,
	|	PaymentCards_.AuthorizationCode AS AuthorizationCode,
	|	PaymentCards_.PaymentCardNumber AS PaymentCardNumber,
	|	PaymentCards_.Sum AS Sum,
	|	PaymentCards_.PaymentIsCanceled AS PaymentIsCanceled
	|INTO RefundOfPaymentByPaymentCardsByReceipt
	|FROM
	|	Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
	|		INNER JOIN Document.CashRegisterReceiptReturn.PaymentWithPaymentCards AS PaymentCards_
	|		ON PaymentCards_.Ref = CashRegisterReceiptReturn.Ref
	|WHERE
	|	CashRegisterReceiptReturn.CashRegisterReceipt = &Ref
	|	AND CashRegisterReceiptReturn.Posted
	|	AND CashRegisterReceiptReturn.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND PaymentCards_.PaymentKind_ IN (&TypesOfPayments)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PaymentCards_.PaymentKind_ AS PaymentKind_,
	|	PaymentCards_.POSTerminal AS POSTerminal,
	|	PaymentCards_.AuthorizationCode AS AuthorizationCode,
	|	PaymentCards_.PaymentCardNumber AS PaymentCardNumber,
	|	PaymentCards_.Sum AS Sum,
	|	PaymentCards_.CartID AS CartID,
	|	PaymentCards_.ReferenceNumber AS ReferenceNumber,
	|	PaymentCards_.ConnectionContract AS ConnectionContract,
	|	PaymentCards_.PaymentSystemId AS PaymentSystemId,
	|	PaymentCards_.POSTerminalReceiptNumber AS POSTerminalReceiptNumber
	|FROM
	|	Document.CashRegisterReceipt.PaymentWithPaymentCards AS PaymentCards_
	|WHERE
	|	PaymentCards_.Ref = &Ref
	|	AND &TextOfConditionByTypeOfPayment
	|	AND PaymentCards_.PaymentKind_ <> VALUE(Enum.TypesOfCashRegisterPaymentSystem.InstantPayments)
	|	AND NOT (PaymentCards_.PaymentKind_, PaymentCards_.POSTerminal,
	|		PaymentCards_.AuthorizationCode, PaymentCards_.PaymentCardNumber, PaymentCards_.Sum,
	|		TRUE) IN
	|		(SELECT
	|			RefundOfPaymentByPaymentCardsByReceipt.PaymentKind_,
	|			RefundOfPaymentByPaymentCardsByReceipt.POSTerminal,
	|			RefundOfPaymentByPaymentCardsByReceipt.AuthorizationCode,
	|			RefundOfPaymentByPaymentCardsByReceipt.PaymentCardNumber,
	|			RefundOfPaymentByPaymentCardsByReceipt.Sum,
	|			RefundOfPaymentByPaymentCardsByReceipt.PaymentIsCanceled
	|		FROM
	|			RefundOfPaymentByPaymentCardsByReceipt AS RefundOfPaymentByPaymentCardsByReceipt)
	|
	|UNION ALL
	|
	|SELECT
	|	NonCancelledPaymentsByKKMSBPReceipt.PaymentKind_,
	|	NonCancelledPaymentsByKKMSBPReceipt.POSTerminal,
	|	NonCancelledPaymentsByKKMSBPReceipt.AuthorizationCode,
	|	NonCancelledPaymentsByKKMSBPReceipt.PaymentCardNumber,
	|	SUM(NonCancelledPaymentsByKKMSBPReceipt.Sum),
	|	NonCancelledPaymentsByKKMSBPReceipt.CartID,
	|	NonCancelledPaymentsByKKMSBPReceipt.ReferenceNumber,
	|	NonCancelledPaymentsByKKMSBPReceipt.ConnectionContract,
	|	NonCancelledPaymentsByKKMSBPReceipt.PaymentSystemId,
	|	NonCancelledPaymentsByKKMSBPReceipt.POSTerminalReceiptNumber
	|FROM
	|	(SELECT
	|		PaymentCards_.PaymentKind_ AS PaymentKind_,
	|		PaymentCards_.POSTerminal AS POSTerminal,
	|		PaymentCards_.AuthorizationCode AS AuthorizationCode,
	|		PaymentCards_.PaymentCardNumber AS PaymentCardNumber,
	|		-PaymentCards_.Sum AS Sum,
	|		PaymentCards_.ReferenceNumber AS ReferenceNumber,
	|		PaymentCards_.CartID AS CartID,
	|		PaymentCards_.ConnectionContract AS ConnectionContract,
	|		PaymentCards_.PaymentSystemId AS PaymentSystemId,
	|		PaymentCards_.POSTerminalReceiptNumber AS POSTerminalReceiptNumber
	|	FROM
	|		Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
	|			INNER JOIN Document.CashRegisterReceiptReturn.PaymentWithPaymentCards AS PaymentCards_
	|			ON PaymentCards_.Ref = CashRegisterReceiptReturn.Ref
	|	WHERE
	|		CashRegisterReceiptReturn.CashRegisterReceipt = &Ref
	|		AND CashRegisterReceiptReturn.Posted
	|		AND CashRegisterReceiptReturn.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|		AND PaymentCards_.PaymentKind_ = VALUE(Enum.TypesOfCashRegisterPaymentSystem.InstantPayments)
	|		AND &TextOfConditionByTypeOfPayment
	|		AND PaymentCards_.PaymentIsCanceled
	|
	|	UNION ALL
	|
	|	SELECT
	|		PaymentCards_.PaymentKind_,
	|		PaymentCards_.POSTerminal,
	|		PaymentCards_.AuthorizationCode,
	|		PaymentCards_.PaymentCardNumber,
	|		PaymentCards_.Sum,
	|		PaymentCards_.ReferenceNumber,
	|		PaymentCards_.CartID,
	|		PaymentCards_.ConnectionContract,
	|		PaymentCards_.PaymentSystemId,
	|		PaymentCards_.POSTerminalReceiptNumber
	|	FROM
	|		Document.CashRegisterReceipt.PaymentWithPaymentCards AS PaymentCards_
	|			LEFT JOIN Document.CashRegisterReceipt AS CashRegisterReceipt
	|			ON PaymentCards_.Ref = CashRegisterReceipt.Ref
	|	WHERE
	|		CashRegisterReceipt.Posted
	|		AND CashRegisterReceipt.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|		AND CashRegisterReceipt.Ref = &Ref
	|		AND PaymentCards_.PaymentKind_ = VALUE(Enum.TypesOfCashRegisterPaymentSystem.InstantPayments)
	|		AND &TextOfConditionByTypeOfPayment) AS NonCancelledPaymentsByKKMSBPReceipt
	|GROUP BY
	|	NonCancelledPaymentsByKKMSBPReceipt.PaymentKind_,
	|	NonCancelledPaymentsByKKMSBPReceipt.POSTerminal,
	|	NonCancelledPaymentsByKKMSBPReceipt.AuthorizationCode,
	|	NonCancelledPaymentsByKKMSBPReceipt.PaymentCardNumber,
	|	NonCancelledPaymentsByKKMSBPReceipt.CartID,
	|	NonCancelledPaymentsByKKMSBPReceipt.ReferenceNumber,
	|	NonCancelledPaymentsByKKMSBPReceipt.ConnectionContract,
	|	NonCancelledPaymentsByKKMSBPReceipt.PaymentSystemId,
	|	NonCancelledPaymentsByKKMSBPReceipt.POSTerminalReceiptNumber
	|HAVING
	|	SUM(NonCancelledPaymentsByKKMSBPReceipt.Sum) <> 0
	|
	|ORDER BY
	|	PaymentKind_,
	|	POSTerminal,
	|	PaymentCardNumber,
	|	AuthorizationCode,
	|	CartID,
	|	ConnectionContract,
	|	POSTerminalReceiptNumber";
	
	TextOfConditionByTypeOfPayment = "TRUE";
	If UseSelectionByPaymentType Then
		If AllTypesOfPaymentsExceptThoseSpecified Then
			TextOfConditionByTypeOfPayment = "NOT PaymentCards_.PaymentKind_ IN (&TypesOfPayments)";
		Else
			TextOfConditionByTypeOfPayment = "PaymentCards_.PaymentKind_ IN (&TypesOfPayments)";
		EndIf;
	EndIf;
	QueryText = StrReplace(QueryText,"&TextOfConditionByTypeOfPayment" , TextOfConditionByTypeOfPayment);
	
	Return QueryText;
EndFunction

// Returns the text of the request for receiving non-returned series by Cash Register receipt.
// The room for returning goods from the client is calculated from the Cash Register receipt data.
// The request uses parameters: 
//  Link - Document link.CHECKKM - link to the sales document
//  The current return of the client's goods is uncertain, the document is a link.Return of Customer goods - a reference to the current return
//  for which the composition of the series is calculated.
//
// Returns:
//  String - 
//
Function QueryTextForReceivingNonReturnedSeriesByCashRegisterReceipt() Export
	
	QueryText = "SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Series AS Series,
	|	SetOfSeries.Premise AS Premise,
	|	SetOfSeries.Count AS Count
	|INTO TDSeries
	|FROM
	|	Document.CashRegisterReceipt.SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Series,
	|	SetOfSeries.Premise,
	|	-SetOfSeries.Count
	|FROM
	|	Document.CashRegisterReceiptReturn.SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Ref.CashRegisterReceipt = &Ref
	|	AND SetOfSeries.Ref.Posted
	|
	|UNION ALL
	|	
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Series,
	|	MAX(CashRegisterReceiptSetOfSeries.Premise),
	|	-SUM(SetOfSeries.Count)
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.SetOfSeries AS SetOfSeries
	|	LEFT JOIN Document.CashRegisterReceipt.SetOfSeries AS CashRegisterReceiptSetOfSeries
	|		ON CashRegisterReceiptSetOfSeries.Ref = &Ref
	|			AND CashRegisterReceiptSetOfSeries.Products = SetOfSeries.Products
	|			AND CashRegisterReceiptSetOfSeries.Characteristic = SetOfSeries.Characteristic
	|			AND CashRegisterReceiptSetOfSeries.Series = SetOfSeries.Series	
	|WHERE
	|	SetOfSeries.Ref.CashRegisterReceipt = &Ref
	|	AND SetOfSeries.Ref.Posted
	|	AND (SetOfSeries.Ref <> &CurrentReturnOfGoodsFromCustomer)
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Series AS Series,
	|	SetOfSeries.Premise AS Premise,
	|	SUM(SetOfSeries.Count) AS Count
	|FROM
	|	TDSeries AS SetOfSeries
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Series,
	|	SetOfSeries.Premise
	|HAVING
	|	SUM(SetOfSeries.Count) > 0
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Premise";
		
	Return QueryText;
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(CashRegister)
	|	AND ValueAllowed(Warehouse)";

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

// Description of additional data sources for movements.
// Parameters:
//  RegisterName - String 
// 
// Returns:
//  Map of KeyAndValue
//
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef) Export
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Archived                                        AS Archived,
	|	DocumentData.Ref                                          AS Ref,
	|	DocumentData.CashRegister.Owner                               AS Organization,
	|	DocumentData.Partner                                         AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef)                   AS Counterparty,
	|	DocumentData.Date                                            AS Period,
	|	DocumentData.Currency                                          AS Currency,
	|	DocumentData.Warehouse                                           AS Warehouse,
	|	DocumentData.PriceIncludesVAT                                 AS PriceIncludesVAT,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.RetailSaleOfGoods) AS BusinessTransactionSetting,
	|	VALUE(Catalog.CashFlowReportItems.CashReceiptFromCustomer) AS CashFlowItem,
	|	DocumentData.Status                                                        AS Status,
	|	DocumentData.CompanyUSAIS                                     AS CompanyUSAIS,
	|	DocumentData.LoyaltyCard.Owner.LoyaltyProgram AS LoyaltyProgram
	|FROM
	|	Document.CashRegisterReceipt AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Archived",                                 Attributes.Archived);
	Query.SetParameter("Ref",                                   DocumentRef);
	Query.SetParameter("Warehouse",                                    Attributes.Warehouse);
	Query.SetParameter("Period",                                   Attributes.Period);
	Query.SetParameter("Currency",                                   Attributes.Currency);
	Query.SetParameter("Organization",                              Attributes.Organization);
	Query.SetParameter("PriceIncludesVAT",                          ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("BusinessOperation",                    Attributes.BusinessOperation);
	Query.SetParameter("BusinessTransactionSetting",	          Attributes.BusinessTransactionSetting);
	Query.SetParameter("CashFlowItem",            Attributes.CashFlowItem);
	Query.SetParameter("ReceiptCompleted",                                Attributes.Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_);
	Query.SetParameter("GoodsIsReserved",                      Attributes.Status = Enums.CashRegisterReceiptStatuses.DeferredWithReservation);
	Query.SetParameter("Partner",                                  Attributes.Partner);
	Query.SetParameter("LoyaltyProgram",              Attributes.LoyaltyProgram);
	Query.SetParameter("CompanyUSAIS",                         Attributes.CompanyUSAIS);
	Query.SetParameter("CurrentDate",                              CurrentUniversalDate());
	Query.SetParameter("StartDateOfBonusPointsMechanism_2_5", Constants.StartDateOfBonusPointsMechanism_2_5.Get());
	
	Query.SetParameter("ManagementAccountingCurrency",               Constants.ManagementAccountingCurrency.Get());
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization);
	Query.SetParameter("LocalAccountingCurrency", CurrencyOfComplianceAccounting);
	
EndProcedure

Function QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers)
	
	RegisterName = "CashInCashRegistersCR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAmountByPaymentCards", QueryTexts) Then
		QueryTextTTAmountByPaymentCards(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAmountOfGiftCertificates", QueryTexts) Then
		QueryTextTTAmountOfGiftCertificates(Query, QueryTexts);
	EndIf; 
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = 
	"SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.CashRegister.Owner AS Organization,
	|	DocumentData.CashRegister AS CashRegister,
	|	DocumentData.DocumentAmount - ISNULL(TableAmountByPaymentCards.Sum, 0) - ISNULL(TableWithGiftCertificates.Sum, 0) AS Sum,
	|	CAST((DocumentData.DocumentAmount - ISNULL(TableAmountByPaymentCards.Sum, 0) - ISNULL(TableWithGiftCertificates.Sum, 0)) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST((DocumentData.DocumentAmount - ISNULL(TableAmountByPaymentCards.Sum, 0) - ISNULL(TableWithGiftCertificates.Sum, 0)) * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	&CashFlowItem AS CashFlowItem,
	|	DocumentData.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromCustomer) AS BusinessTransactionSetting
	|FROM
	|	Document.CashRegisterReceipt AS DocumentData
	|		LEFT JOIN TTAmountByPaymentCards AS TableAmountByPaymentCards
	|		ON (TRUE)
	|		LEFT JOIN TTAmountOfGiftCertificates AS TableWithGiftCertificates
	|		ON (TRUE)
	|WHERE
	|	DocumentData.DocumentAmount - ISNULL(TableAmountByPaymentCards.Sum, 0) - ISNULL(TableWithGiftCertificates.Sum, 0) <> 0
	|	AND DocumentData.Ref = &Ref
	|	AND &ReceiptCompleted
	|	AND (NOT &Archived)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableAcquiringContractARAP(Query, QueryTexts, Registers)
	
	RegisterName = "AcquiringContractARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCashFlowArticles", QueryTexts) Then
		QueryTextTTCashFlowArticles(QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	PaymentTable_3.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt)         AS RecordType,
	|	VALUE(Enum.AcquiringCashTypes.CashRecieptByAcquiringTransactions) AS CashType,
	|	&Organization                                   AS Organization,
	|	&Currency                                        AS Currency,
	|	PaymentTable_3.POSTerminal          AS POSTerminal,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract
	|		ELSE PaymentTable_3.POSTerminal.Owner
	|	END AS Contract,
	|	PaymentTable_3.PaymentCardNumber            AS PaymentCardNumber,
	|	PaymentTable_3.AuthorizationCode                 AS AuthorizationCode,
	|	VALUE(Enum.BusinessTransactions.CashRecieptFromCustomerByAcquiringTransactions) AS BusinessOperation,
	|	CFItems.CashFlowItem        AS CashFlowItem,
	|	&Period                                        AS PaymentDate,
	|	PaymentTable_3.Sum                          AS Sum
	|FROM
	|	Document.CashRegisterReceipt.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN TTCashFlowArticles AS CFItems
	|		ON PaymentTable_3.LineNumber = CFItems.LineNumber
	|WHERE
	|	PaymentTable_3.Ref = &Ref
	|	AND (NOT &Archived)
	|	AND CASE
	|		WHEN PaymentTable_3.ConnectionContract <> VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract.DetailedTransactionReconciliation
	|		ELSE ISNULL(PaymentTable_3.POSTerminal.Owner.DetailedTransactionReconciliation, TRUE)
	|	END
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInTransit(Query, QueryTexts, Registers)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCashFlowArticles", QueryTexts) Then
		QueryTextTTCashFlowArticles(QueryTexts);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = "
	|SELECT
	|	PaymentTable_3.LineNumber                                                          AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)                                               AS RecordType,
	|	&Period                                                                              AS Period,
	|	&Organization                                                                         AS Organization,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract.BankAccount
	|		ELSE PaymentTable_3.POSTerminal.Owner.BankAccount
	|	END                                                                                AS Recipient,
	|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)   AS CashTransferKind,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract.Counterparty
	|		ELSE PaymentTable_3.POSTerminal.Owner.Counterparty
	|	END                                                                                AS Counterparty,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract
	|		ELSE PaymentTable_3.POSTerminal.Owner
	|	END                                                                                AS Contract,
	|	UNDEFINED                                                                         AS PaymentDocument,
	|	&Currency                                                                              AS Currency,
	|	PaymentTable_3.Sum                                                                AS Sum,
	|	CAST(PaymentTable_3.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))    AS SumMan,
	|	CAST(PaymentTable_3.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))   AS SumCompl,
	|	VALUE(Enum.BusinessTransactions.CashRecieptFromCustomerByAcquiringTransactions) AS BusinessOperation,
	|	CFItems.CashFlowItem                                              AS CashFlowItem,
	|	PaymentTable_3.RowID                                                  AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CashRecieptFromCustomerByAcquiringTransactions) AS BusinessTransactionSetting
	|FROM
	|	Document.CashRegisterReceipt.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN TTCashFlowArticles AS CFItems
	|		ON PaymentTable_3.LineNumber = CFItems.LineNumber
	|WHERE
	|	PaymentTable_3.Ref = &Ref
	|	AND (NOT &Archived)
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTCashFlowArticles(QueryTexts)
	
	RegisterName = "TTCashFlowArticles";
	
	QueryText = 
	"SELECT
	|	PaymentTable_3.LineNumber AS LineNumber,
	|	CASE
	|		WHEN NOT ISNULL(InformationAboutContract.CashFlowItemCashReceipt, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|			THEN InformationAboutContract.CashFlowItemCashReceipt
	|		WHEN NOT ISNULL(InformationAboutContractForTerminal.CashFlowItemCashReceipt, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|			THEN InformationAboutContractForTerminal.CashFlowItemCashReceipt
	|		ELSE &CashFlowItem
	|	END AS CashFlowItem
	|INTO TTCashFlowArticles
	|FROM
	|	Document.CashRegisterReceipt.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN Catalog.AcquiringContracts AS InformationAboutContract
	|		ON PaymentTable_3.ConnectionContract = InformationAboutContract.Ref
	|		LEFT JOIN Catalog.AcquiringContracts AS InformationAboutContractForTerminal
	|		ON PaymentTable_3.POSTerminal.Owner = InformationAboutContractForTerminal.Ref
	|WHERE
	|	PaymentTable_3.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryTexts;
	
EndFunction

Procedure ArrangeShipmentAtRetail(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	DocumentGoods.Ref.Date			AS Period,
	|	DocumentGoods.Ref.Warehouse		AS Warehouse,
	|	DocumentGoods.Premise			AS Premise,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS GoodsReturn
	|FROM
	|	Document.CashRegisterReceipt.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0
	|	AND NOT DocumentGoods.Ref.Archived
	|	AND (DocumentGoods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|		OR DocumentGoods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.DeferredWithReservation)
	|		OR DocumentGoods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.AmountDue))";
	
	MetadataObject	= Metadata.Documents.CashRegisterReceipt;
	
	MethodParameters = WarehousesServer.ParametersOfModularHolding();
	MethodParameters.TSSeriesName = "SetOfSeries";
	MethodParameters.SynonymForDocumentTable = "DocumentGoods";
	
	WarehousesServer.ArrangeShipmentAtRetail(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										MetadataObject,
										MethodParameters);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	&Warehouse AS Sender,
	|	&Partner AS Partner,
	|	VALUE(Enum.WarehouseTransactions.RetailShipment) AS WarehouseOperation,
	|	SeriesTable.Premise AS WareroomOfSender,
	|	&Period AS Period,
	|	&Ref AS Document,
	|	&Ref AS Recorder,
	|	SeriesTable.LineNumber AS LineNumber,
	|	TRUE AS ThisIsWarehouseRecord
	|FROM
	|	Document.CashRegisterReceipt.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND &ReceiptCompleted
	|	AND NOT &Archived
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Count,
	|	&Warehouse,
	|	&Partner,
	|	VALUE(Enum.WarehouseTransactions.RetailShipment),
	|	GoodsTable.Premise,
	|	&Period,
	|	&Ref,
	|	&Ref,
	|	GoodsTable.LineNumber,
	|	TRUE
	|FROM
	|	Document.CashRegisterReceipt.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Count <> 0
	|	AND &ReceiptCompleted
	|	AND NOT &Archived
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextGiftCardHistory(Query, QueryTexts, Registers)
	
	RegisterName = "GiftCardHistory";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	&Period                             AS Period,
	|	TabularSection.GiftCertificate AS GiftCertificate,
	|
	|	CASE WHEN TabularSection.GiftCertificate.Owner.PartialPayment THEN
	|		VALUE(Enum.GiftCertificateStatuses.PartiallyRepaid)
	|	ELSE
	|		VALUE(Enum.GiftCertificateStatuses.FullyRepaid)
	|	END AS Status
	|FROM
	|	Document.CashRegisterReceipt.GiftCertificates AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.GiftCertificate.Owner.GiftCardAccounting25 = FALSE	
	|	AND &ReceiptCompleted
	|	AND (NOT &Archived)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextGiftCertificates(Query, QueryTexts, Registers)
	
	RegisterName = "GiftCertificates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = 
	"SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TabularSection.GiftCertificate    AS GiftCertificate,
	|	TabularSection.AmountInCertificateCurrency                  AS Sum,
	|	TabularSection.Sum * &FactorOfConversionToCurrencyOfRegul AS SumCompl,
	|	TabularSection.RowID						AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GiftCertificateSale) AS BusinessTransactionSetting
	|FROM
	|	Document.CashRegisterReceipt.GiftCertificates AS TabularSection
	|	INNER JOIN Catalog.GiftCertificates AS GiftCertificates
	|		INNER JOIN Catalog.GiftCertificateKinds AS GiftCertificateKinds
	|		ON GiftCertificates.Owner = GiftCertificateKinds.Ref
	|			AND GiftCardAccounting25 = FALSE
	|	ON TabularSection.GiftCertificate = GiftCertificates.Ref
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &ReceiptCompleted
	|	AND (NOT &Archived)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextBonusPoints(Query, QueryTexts, Registers)
	
	RegisterName = "BonusPoints";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBonusPoints", QueryTexts) Then
		QueryTextTTBonusPoints(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	BonusPoints.Period                      AS Period,
	|	BonusPoints.ValidityStartDate          AS ValidityStartDate,
	|	BonusPoints.DateToProcess              AS DateToProcess,
	|	BonusPoints.RecordType                 AS RecordType,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner                     AS Partner,
	|	SUM(BonusPoints.Accrued)            AS Accrued,
	|	SUM(BonusPoints.ToWriteOff)            AS ToWriteOff
	|FROM
	|	TTBonusPoints AS BonusPoints
	|
	|GROUP BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.DateToProcess,
	|	BonusPoints.Period,
	|	BonusPoints.RecordType
	|HAVING
	|	SUM(BonusPoints.Accrued) <> 0 OR 
	|	SUM(BonusPoints.ToWriteOff) <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CashRegisterReceipt.GiftCertificates AS Table
		|		LEFT JOIN Document.CashRegisterReceipt AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Sale
	
	TextSale = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS ARAPObject,
		|	Table.Ref.Date                                                      AS PaymentDate,
		|	UNDEFINED                                                             AS SalesOrder_,
		|	FALSE                                                                     AS InvoiceForOrders,
		|
		|	Table.Sum                                                            AS AmountARAP,
		|	0                                                                        AS AmountARAPByPackage,
		|	Table.Sum                                                            AS Sum,
		|	
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	
		|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods)          AS BusinessOperation,
		|	&BusinessTransactionSetting                                          AS BusinessTransactionSetting,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned) AS PaymentOption,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|FROM
		|	Document.CashRegisterReceipt.GiftCertificates AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND &ReceiptCompleted
		|	AND (NOT &Archived)";
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS ARAPObject,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	
		|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods)          AS BusinessOperation,
		|	&BusinessTransactionSetting                                          AS BusinessTransactionSetting,
		|	Table.Ref.PaymentMethod                                               AS PaymentMethod,
		|	
		|	Table.Ref.Date                                                      AS PaymentDate,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned) AS PaymentOption,
		|	Table.Sum                                                            AS AmountDue,
		|	
		|	TRUE                                                                   AS ExcludeDuringControl,
		|	FALSE                                                                     AS InvoiceForOrders,
		|	VALUE(Document.SalesOrder.EmptyRef)                             AS SalesOrder_,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|	
		|FROM
		|	Document.CashRegisterReceipt.GiftCertificates AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND &ReceiptCompleted
		|	AND (NOT &Archived)";
	
	#EndRegion
	
	#Region ApplyingPrepayment
	
	TextAdvancePaymentOffset = "";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset);
	
EndProcedure

Function QueryTextTTAmountByPaymentCards(Query, QueryTexts)
	
	RegisterName = "TTAmountByPaymentCards";
	
	QueryText = 
	"SELECT
	|	SUM(TabularSection.Sum) AS Sum
	|INTO TTAmountByPaymentCards
	|FROM
	|	Document.CashRegisterReceipt.PaymentWithPaymentCards AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAmountOfGiftCertificates(Query, QueryTexts)
	
	RegisterName = "TTAmountOfGiftCertificates";
	
	QueryText = 
	"SELECT
	|	SUM(TabularSection.Sum) AS Sum
	|INTO TTAmountOfGiftCertificates
	|FROM
	|	Document.CashRegisterReceipt.GiftCertificates AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBonusPoints(Query, QueryTexts)
	
	RegisterName = "TTBonusPoints";
	
	QueryText = 
	"SELECT
	|	TabularSection.AccrualDate AS Period,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.DateOfDeduction,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN TabularSection.AccrualDate
	|		ELSE DATETIME(1, 1, 1)
	|	END AS ValidityStartDate,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.DateOfDeduction,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END AS DateToProcess,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
	|	&Partner AS Partner,
	|	TabularSection.AmountOfBonusPoints AS Accrued,
	|	0 AS ToWriteOff
	|INTO TTBonusPoints
	|FROM
	|	Document.CashRegisterReceipt.BonusPoints AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND NOT &Partner = VALUE(Catalog.Partners.RetailCustomer)
	|	AND &ReceiptCompleted
	|	AND NOT &Archived
	|	AND TabularSection.AccrualDate <> DATETIME(1, 1, 1)
	|
	|UNION ALL
	|
	|SELECT
	|	TabularSection.DateOfDeduction AS Period,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.DateOfDeduction,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN TabularSection.AccrualDate
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.DateOfDeduction,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
	|	&Partner AS Partner,
	|	0 AS Accrued,
	|	TabularSection.AmountOfBonusPoints AS ToWriteOff
	|FROM
	|	Document.CashRegisterReceipt.BonusPoints AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND NOT &Partner = VALUE(Catalog.Partners.RetailCustomer)
	|	AND &ReceiptCompleted
	|	AND NOT &Archived
	|	AND TabularSection.DateOfDeduction <> DATETIME(1, 1, 1)
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(&Period, DAY),
	|	DATETIME(1, 1, 1),
	|	CASE
	|		WHEN BEGINOFPERIOD(&Period, DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	VALUE(AccumulationRecordType.Expense),
	|	&LoyaltyProgram,
	|	&Partner,
	|	TabularSection.AmountOfBonusPointsToDeduction,
	|	CASE
	|		WHEN BEGINOFPERIOD(&Period, DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN 0
	|		ELSE TabularSection.AmountOfBonusPointsToDeduction
	|	END
	|FROM
	|	Document.CashRegisterReceipt.Goods AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND NOT &Partner = VALUE(Catalog.Partners.RetailCustomer)
	|	AND &ReceiptCompleted
	|	AND NOT &Archived
	|	AND TabularSection.AmountOfBonusPointsToDeduction <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
																			Query.Parameters.Currency,
																			Query.Parameters.Period,
																			Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
		|				TabPart.Ref.Department
		|			ELSE
		|				TabPart.Ref.Warehouse
		|		END                                    AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.CashRegisterReceipt.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.Status IN(
		|			VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_),
		|			VALUE(Enum.CashRegisterReceiptStatuses.DeferredWithReservation),
		|			VALUE(Enum.CashRegisterReceiptStatuses.AmountDue))
		|	AND NOT TabPart.Ref.Archived";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// Commodity check
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintSalesReceipt";
	PrintCommand.Id = "ProductReceipt_";
	PrintCommand.Presentation = NStr("vi = 'Phiếu tính tiền';
									|ru = 'Товарный чек';
									|en = 'Sales receipt'; fa = 'رسید فروش';
									|it = 'Ricevuta di vendita';
									|pl = 'Paragon towarowy';
									|tr = 'Satış makbuzu'");
	PrintCommand.CheckPostingBeforePrint = True;
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - a reference to the object
//                                            view - the name of the area in which the object was output (output parameter).
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	Return;
EndProcedure

// The function receives data for generating the printed form of the Product receipt.
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array of DocumentRef - An array of references to documents, which is necessary to obtain the data.
//
// Returns:
// 	Structure:
// 		* HeaderResults - QueryResult
// 		* ResultForTabularPart - QueryResult
// 		* DocumentTitle - String
//
Function GetDataForPrintedFormProductReceipt(PrintParameters, ObjectsArray) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	DocReceipt.Number AS Number,
	|	DocReceipt.Date AS Date,
	|	DocReceipt.Ref AS Ref,
	|	DocReceipt.CashRegister AS CashRegister,
	|	DocReceipt.Currency AS Currency,
	|	DocReceipt.PriceIncludesVAT AS PriceIncludesVAT,
	|	DocReceipt.CashRegister.Presentation AS Customer,
	|	DocReceipt.Cashier.Individual AS EmployeeResponsible,
	|	DocReceipt.Organization AS Organization,
	|	DocReceipt.Organization.Prefix AS Prefix,
	|	DocReceipt.Organization.Presentation AS Vendor,
	|	DocReceipt.DocumentAmount AS DocumentAmount,
	|	DocReceipt.CashRegister.Department AS Department
	|FROM
	|	Document.CashRegisterReceipt AS DocReceipt
	|WHERE
	|	DocReceipt.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	DocReceipt.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.Package AS Package,
	|	Table.Price AS Price,
	|	Table.ManualDiscount + Table.DiscountMarkupAmount AS DiscountAmount,
	|	Table.Sum - Table.ManualDiscount - Table.DiscountMarkupAmount AS AmountWithoutADiscount,
	|	Table.Sum AS Sum,
	|	Table.VATAmount AS VATAmount,
	|	Table.Premise AS Premise
	|INTO Goods
	|FROM
	|	Document.CashRegisterReceipt.Goods AS Table
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON (ProductKitConfigurations.Owner = Table.ProductsInSet)
	|			AND (ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet)
	|			AND (ProductKitConfigurations.Main)
	|WHERE
	|	Table.Ref IN(&DocumentsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	MIN(Table.LineNumber) AS LineNumber,
	|	SUM(Table.Sum) + SUM(Table.DiscountAmount) AS Price,
	|	SUM(Table.Sum) AS Sum,
	|	SUM(Table.VATAmount) AS VATAmount,
	|	SUM(Table.DiscountAmount) AS DiscountAmount,
	|	SUM(Table.Sum - Table.DiscountAmount) AS AmountWithoutADiscount
	|INTO KitsPreparation
	|FROM
	|	Goods AS Table
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Components.Ref AS ItemKitConfiguration,
	|	Components.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Components.Ref.SetPricingOption AS SetPricingOption,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	SUM(CASE
	|			WHEN ISNULL(Components.Count, 0) <> 0
	|				THEN Goods.Count / Components.Count
	|			ELSE 1
	|		END) AS Count
	|INTO TableOptional
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ProductKitConfigurations.Goods AS Components
	|		ON (Components.Ref = Goods.ItemKitConfiguration)
	|			AND (Components.Ref.ProductsOfMainComponent = Goods.Products)
	|			AND (Components.Ref.MainComponentCharacteristic = Goods.Characteristic)
	|			AND (Components.Products = Goods.Products)
	|			AND (Components.Characteristic = Goods.Characteristic)
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	AND NOT Components.Count IS NULL
	|
	|GROUP BY
	|	Goods.Ref,
	|	Components.Ref,
	|	Components.Ref.PresentationOptionInPrintForms,
	|	Components.Ref.SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOptional.ItemKitConfiguration AS ItemKitConfiguration,
	|	TableOptional.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	TableOptional.SetPricingOption AS SetPricingOption,
	|	Table.Ref AS Ref,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.LineNumber AS LineNumber,
	|	ISNULL(TableOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TableOptional.Count, 1) AS Count,
	|	Table.Price / ISNULL(TableOptional.Count, 1) AS Price,
	|	Table.Sum AS Sum,
	|	Table.VATAmount AS VATAmount,
	|	Table.DiscountAmount AS DiscountAmount,
	|	Table.AmountWithoutADiscount AS AmountWithoutADiscount
	|INTO Kits
	|FROM
	|	KitsPreparation AS Table
	|		LEFT JOIN TableOptional AS TableOptional
	|		ON Table.ProductsInSet = TableOptional.ProductsInSet
	|			AND Table.ItemVariantOfSet = TableOptional.ItemVariantOfSet
	|			AND Table.Ref = TableOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Table.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.TheseAreComponents AS TheseAreComponents,
	|	Table.IsRecordsSet AS IsRecordsSet,
	|	Table.LineNumber AS LineNumber,
	|	Table.Products.DescriptionFull AS FullNameOfProduct_,
	|	Table.Products.Code AS Code,
	|	Table.Products.SKU AS SKU,
	|	Table.Characteristic.DescriptionFull AS FullNameOfCharacteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Table.Package.Description
	|	END AS PackageName,
	|	Table.NumberOfPackages AS Count,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(Table.Products.UnitOfMeasure)
	|		ELSE PRESENTATION(Table.Package)
	|	END AS UnitOfMeasure,
	|	Table.Package AS Package,
	|	Table.Price AS Price,
	|	Table.DiscountAmount AS DiscountAmount,
	|	Table.Sum AS Sum,
	|	Table.VATAmount AS VATAmount,
	|	Table.Premise AS Premise
	|FROM
	|	(SELECT
	|		Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|		Table.SetPricingOption AS SetPricingOption,
	|		Table.Ref AS Ref,
	|		Table.ProductsInSet AS ProductsInSet,
	|		Table.ItemVariantOfSet AS ItemVariantOfSet,
	|		CASE
	|			WHEN ISNULL(Kits.LineNumber, 0) <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE
	|			WHEN ISNULL(Kits.LineNumber, 0) <> 0
	|				THEN Kits.LineNumber
	|			ELSE Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products AS Products,
	|		Table.Count AS Count,
	|		Table.NumberOfPackages AS NumberOfPackages,
	|		Table.Price AS Price,
	|		Table.Sum AS Sum,
	|		Table.VATAmount AS VATAmount,
	|		Table.Characteristic AS Characteristic,
	|		Table.Package AS Package,
	|		Table.DiscountAmount AS DiscountAmount,
	|		Table.AmountWithoutADiscount AS AmountWithoutADiscount,
	|		Table.Premise AS Premise
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN Kits AS Kits
	|			ON (Kits.ProductsInSet = Table.ProductsInSet)
	|				AND (Kits.ItemVariantOfSet = Table.ItemVariantOfSet)
	|	WHERE
	|		(Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|				OR Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|					AND Table.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents), VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Kits.PresentationOptionInPrintForms,
	|		Kits.SetPricingOption,
	|		Kits.Ref,
	|		Kits.ProductsInSet,
	|		Kits.ItemVariantOfSet,
	|		FALSE,
	|		TRUE,
	|		Kits.LineNumber,
	|		Kits.ProductsInSet,
	|		Kits.Count,
	|		Kits.NumberOfPackages,
	|		Kits.Price,
	|		Kits.Sum,
	|		Kits.VATAmount,
	|		Kits.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	|		Kits.DiscountAmount,
	|		Kits.AmountWithoutADiscount,
	|		UNDEFINED
	|	FROM
	|		Kits AS Kits
	|	WHERE
	|		Kits.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet), VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))) AS Table
	|
	|ORDER BY
	|	Table.LineNumber,
	|	IsRecordsSet DESC");
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure(
		"HeaderResults, ResultForTabularPart, DocumentTitle",
		RequestResultsPackage[0],
		RequestResultsPackage[5],
		NStr("vi = 'Phiếu tính tiền';
			|ru = 'Товарный чек';
			|en = 'Sales receipt'; fa = 'رسید فروش';
			|it = 'Ricevuta di vendita';
			|pl = 'Paragon towarowy';
			|tr = 'Satış makbuzu'"));
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return DataStructureForPrinting;
	
EndFunction

#EndRegion

// Returns the text of the query to calculate the status of the guidance series (With premises)
//	Returns:
//		String - query text.
//
Function RequestTextForFillingInStatusesForSpecifyingSeriesWithPremises()
	
	QueryText = 
	"SELECT
	|	Goods.Premise,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Premise,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Premise,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Premise,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Premise,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Premise,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|		BatchAccountingPolicies.Ref AS Ref,
	|		BatchAccountingPolicies.BatchAccountingPolicy AS BatchAccountingPolicy,
	|		BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches AS UseCostAccountingByBatches,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment AS SpecifyWhenPlanningShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking AS SpecifyWhenPlanningPicking,
	|		BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO AS BatchesAccountingByFEFO,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult AS SpecifyByPickingResult,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnRetailShipment AS SpecifyOnRetailShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries AS AccountForRemainingSeries
	|INTO SeriesAccountingPoliciesForRequest
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|	INNER JOIN ProductsToRequest AS ProductsToRequest
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|WHERE 
	|	(BatchAccountingPolicies.Warehouse = &Warehouse)	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN &SeriesOnlyForCostPrice
	|			THEN 0
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.SpecifyOnRetailShipment
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Premise = ProductsToRequest.Premise
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON Goods.Products = SeriesToRequest.Products
	|			AND Goods.Characteristic = SeriesToRequest.Characteristic
	|			AND Goods.Premise = SeriesToRequest.Premise
	|		LEFT JOIN SeriesAccountingPoliciesForRequest AS BatchAccountingPolicies
	|			ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

// Returns the text of the query to calculate the status of the guidance series (Without spaces)
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeriesWithoutRooms()
	
	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|		BatchAccountingPolicies.Ref AS Ref,
	|		BatchAccountingPolicies.BatchAccountingPolicy AS BatchAccountingPolicy,
	|		BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches AS UseCostAccountingByBatches,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment AS SpecifyWhenPlanningShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking AS SpecifyWhenPlanningPicking,
	|		BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO AS BatchesAccountingByFEFO,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult AS SpecifyByPickingResult,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnRetailShipment AS SpecifyOnRetailShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries AS AccountForRemainingSeries
	|INTO SeriesAccountingPoliciesForRequest
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|	INNER JOIN ProductsToRequest AS ProductsToRequest
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|WHERE 
	|	(BatchAccountingPolicies.Warehouse = &Warehouse)	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN &SeriesOnlyForCostPrice
	|			THEN 0
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.SpecifyOnRetailShipment
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			ON Goods.Products = ProductsToRequest.Products
	|				AND Goods.Characteristic = ProductsToRequest.Characteristic
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON Goods.Products = SeriesToRequest.Products
	|				AND Goods.Characteristic = SeriesToRequest.Characteristic
	|		LEFT JOIN SeriesAccountingPoliciesForRequest AS BatchAccountingPolicies
	|			ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
