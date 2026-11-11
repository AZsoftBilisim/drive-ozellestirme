#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.IntercompanyGoodsReturn - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode) Export
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillParameters = ParametersForFillingInventoryTypes("CompanyRecipient");
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		FillParameters = New Array;
		FillParameters.Add(ParametersForFillingInventoryTypes("Organization"));
		FillParameters.Add(ParametersForFillingInventoryTypes("CompanyRecipient"));
	EndIf;
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
//
Procedure FillInProductTrackingForm() Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.IntercompanyGoodsReturn.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	If DocumentTables <> Undefined Then
		FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables);
		AdditionalProperties.Insert("TablesOfFillingOfTypesOfStocksAtExchange", DocumentTables);
	EndIf;
	
	FillStockTypes(Cancel);
	AdditionalProperties.Delete("TablesOfFillingOfTypesOfStocksAtExchange");
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CheckOrganizations(Cancel);
	
	If ValueIsFilled(Organization)
		And ValueIsFilled(CompanyRecipient) Then
	
		CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Organization, CompanyRecipient);
		
		If Not CheckStructure.CurrenciesDoNotMatch Then
			ErrorText = NStr("vi = 'Tiền tệ kế toán tài chính của người gửi %1 và người nhận %2 phải trùng nhau.';
							|ru = 'Валюты регламентированного учета отправителя %1 и получателя %2 должны совпадать.';
							|en = 'Local accounting currencies of the %1 sender and the %2 recipient must match.'; fa = 'Local accounting currencies of the %1 sender and the %2 recipient must match.';
							|it = 'Le valute della contabilità regolatoria del mittente %1 del destinatario %2 devono coincidere.';
							|pl = 'Waluty ewidencji reglamentowanej nadawcy %1 i odbiorcy %2 powinny być jednakowe.';
							|tr = 'Gönderici %1 ve alıcı %2''nin yerel muhasebesinin para birimleri eşleşmelidir.'");
			ErrorText = StrTemplate(ErrorText, Organization, CompanyRecipient);
			Common.MessageToUser(ErrorText, ThisObject, "Organization",, Cancel);
		EndIf;
		
		If Not CheckStructure.CountriesMatch Then
			ErrorText = NStr("vi = 'Quốc gia đăng ký của người gửi %1 và người nhận %2 phải trùng nhau.';
							|ru = 'Страны регистрации отправителя %1 и получателя %2 должны совпадать.';
							|en = 'Countries of residence of sender %1 and recipient %2 must be the same.'; fa = 'Countries of residence of sender %1 and recipient %2 must be the same.';
							|it = 'I paesi di registrazione del mittente %1 e del destinatario %2 devono corrispondere.';
							|pl = 'Kraje rejestracji nadawcy %1 i odbiorcy %2 powinny być zgodne.';
							|tr = 'Gönderici %1 ve alıcı %2''nin kayıtlı olduğu ülkeler eşleşmelidir.'");
			ErrorText = StrTemplate(ErrorText, Organization, CompanyRecipient);
			Common.MessageToUser(ErrorText, ThisObject, "Organization",, Cancel);
		EndIf;
		
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If Not ARAPAccountingViaSeparateCounterparty Then
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("Counterparty");
	EndIf;

	If BusinessOperation=Enums.BusinessTransactions.IntercompanyCommissionReturn Then
		NotCheckedAttributeArray.Add("VATTaxation");
		
		NotCheckedAttributeArray.Add("Goods.VATRate");
		
		NotCheckedAttributeArray.Add("ARAPDetails.Sum");
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.IntercompanyGoodsReturn),
												Cancel,
												NotCheckedAttributeArray);
	ProductsServer.CheckQuantityFilling(ThisObject,CheckedAttributes,Cancel);
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date);
	
	If ThisIsTraceableDocument
		Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers") Then
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel);
		
	EndIf;
	
	If ThisIsTraceableDocument Then
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject, Goods, Date);
	EndIf;
	
	CheckAmountFilling(Cancel);
	
	NotCheckedAttributeArray.Add("Goods.DocumentTransfers_");
	For Each RowOfTables In Goods Do
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'в строке %LineNumber% списка ""Товары""';
									|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'w wierszu %LineNumber% listy ""Towary""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress =  StrReplace(ErrorAddress, "%LineNumber%", RowOfTables.LineNumber);
		SalesDocumentField = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "DocumentTransfers_");
		
		If RowOfTables.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromTransferDocument 
			And Not ValueIsFilled(RowOfTables.DocumentTransfers_) Then
			
				ErrorText = NStr("vi = 'Chưa điền cột ""Chứng từ chuyển giao""';
								|ru = 'Не заполнена колонка ""Документ передачи""';
								|en = 'Column ""Transfer document"" is not filled in.'; fa = 'Column ""Transfer document"" is not filled in.';
								|it = 'La colonna ""Documento di trasferimento"" non è stata compilata';
								|pl = 'Nie wypełniono kolumny ""Dokument sprzedaży""';
								|tr = '""Transfer belgesi"" sütunu doldurulmadı'");
				Common.MessageToUser(ErrorText + ErrorAddress, ThisObject, SalesDocumentField,, Cancel);
				
		EndIf;
	EndDo;
	If Not SubjectToExcise Then
		NotCheckedAttributeArray.Add("BusinessUnitProduction");
	EndIf;
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	IntercompanyGoodsReturnLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
														ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.IntercompanyGoodsReturn));
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Goods,PriceIncludesVAT);
	
	TransferDocumentHasBeenCompleted = False;
	For Each RowOfTables In Goods Do
		If RowOfTables.CostDefiningMethod <> Enums.WaysToCalculateReturnCost.FromTransferDocument Then
			RowOfTables.DocumentTransfers_ = Undefined;
		EndIf;
		If ValueIsFilled(RowOfTables.DocumentTransfers_) Then
			TransferDocumentHasBeenCompleted = True;
		EndIf;
	EndDo;
	
	If TransferDocumentHasBeenCompleted Then
		RecordInProfitLossOfPreviousYears = False;
	EndIf;
	
	If Not ARAPAccountingViaSeparateCounterparty Then
		Partner = Undefined;
		Counterparty = Undefined;
		CounterpartyBankAccount = Undefined;
		IncomingDocumentDate = Undefined;
		IncomingDocumentNumber = "";
	EndIf;
	
	If WriteMode=DocumentWriteMode.Posting Then
		
		InventoryOwnerAttributesAreSpecifiedManually = InventoryOwnerAttributesAreSpecifiedManually
									And ChangesInStockTypesAreAllowed();
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	
	RegistrationParameters = Documents.IntercompanyGoodsReturn.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	RegistrationParameters = Documents.IntercompanyGoodsReturn.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	IntercompanyGoodsReturnLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	IntercompanyGoodsReturnLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.Posting);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	IntercompanyGoodsReturnLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	RegistrationParameters = Documents.IntercompanyGoodsReturn.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	
	RegistrationParameters = Documents.IntercompanyGoodsReturn.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	If Not Cancel Then
		ExcisableGoodsAccounting.CreateTaskToRecordAmountOfExciseTax(ThisObject);
	EndIf;
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.UndoPosting);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	IntercompanyGoodsReturnLocalization.UndoPosting(ThisObject, Cancel);
	
	RegistrationParameters = Documents.IntercompanyGoodsReturn.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
	RegistrationParameters = Documents.IntercompanyGoodsReturn.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	CompleteTaxation = True;
	
	FillDefaultAttributes();
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("ThisIsTransferReturn21")
		And FillingData.ThisIsTransferReturn21 Then
		
		CompleteTaxation = False;
		
		FieldsToFillIn = "Organization, CompanyRecipient, Warehouse, BusinessOperation";
		FillPropertyValues(ThisObject, FillingData, FieldsToFillIn);
		
		If FillingData.Property("Contract")
			And ValueIsFilled(FillingData.Contract) Then
			
			Contract = FillingData.Contract;
			
			FieldsNames = "LineOfBusiness, NameForPrinting, Number, Date, ARAPCurrency";
			ContractDetails_ = Common.ObjectAttributesValues(Contract, FieldsNames);
			
			Currency                  = ContractDetails_.ARAPCurrency;
			LineOfBusiness = ContractDetails_.LineOfBusiness;
			Basis               = ContractDetails_.NameForPrinting;
			BaseDocumentNumber          = ContractDetails_.Number;
			ReferenceDocumentDateForPrintForms           = ContractDetails_.Date;
			
		EndIf;
		
		If FillingData.Property("PriceKind") Then
			PriceKind = FillingData.PriceKind;
		EndIf;
		
		If FillingData.Property("Currency")
			And FillingData.Currency Then
			
			Currency = FillingData.Currency;
			
		EndIf;
		
		If Not ValueIsFilled(Date)
			And ValueIsFilled(FillingData.EndOfPeriod)
			And FillingData.EndOfPeriod < CurrentSessionDate() Then
			
			Date = FillingData.EndOfPeriod;
			
		EndIf;
		
		FillInItemsOnBalancesForReturn(FillingData.BeginOfPeriod, FillingData.EndOfPeriod);
		FillInTaxAndDefaultPrices();
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CustomerInvoiceIntercompany") Then	
		
		InstructionsForTransferOfGoods(FillingData);
		
	EndIf;
	
	FillOutBankAccounts();
	
	CompleteVATTaxation(CompleteTaxation);
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
			
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	Department = SettingsValueCached.UserDivision(Manager, Department);
	
	If ValueIsFilled(CompanyRecipient) And Not ValueIsFilled(DeliveryAddress) Then
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(
			CompanyRecipient,
			"Actual",
			CurrentSessionDate());
	EndIf;
	
	ProcessTabularPart();
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	IntercompanyGoodsReturnLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	
	InventoryKinds.Clear();
	
	ProcessTabularPart();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "InventoryKinds");
	
	CompleteVATTaxation();
	
	RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(ThisObject);
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	
	IntercompanyGoodsReturnLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InstructionsForTransferOfGoods(Val DocumentBasis)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Date								AS TransferDate,
	|	DocumentData.CompanyRecipient				AS Organization,
	|	DocumentData.Organization							AS CompanyRecipient,
	|	DocumentData.Warehouse								AS Warehouse,
	|	DocumentData.Currency								AS Currency,
	|	DocumentData.Contract								AS Contract,
	|	DocumentData.SalesContract						AS SalesContract,
	|	DocumentData.PurchasingContract						AS PurchasingContract,
	|	DocumentData.PriceKind								AS PriceKind,
	|	DocumentData.PriceIncludesVAT						AS PriceIncludesVAT,
	|	DocumentData.RecipientCompanyBankAccount	AS CompanyBankAccount,
	|	DocumentData.CompanyBankAccount			AS RecipientCompanyBankAccount,
	|	DocumentData.Department						AS Department,
	|	DocumentData.ARAPAccountingViaSeparateCounterparty	AS ARAPAccountingViaSeparateCounterparty,
	|	DocumentData.Partner								AS Partner,
	|	DocumentData.Counterparty							AS Counterparty,
	|	DocumentData.CounterpartyBankAccount			AS CounterpartyBankAccount,
	|	DocumentData.Ref								AS DocumentTransfers_,
	|	(CASE DocumentData.BusinessOperation
	|		WHEN VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|			THEN VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn)
	|		ELSE VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn)
	|	END)												AS BusinessOperation,
	|	DocumentData.FinancialAccountingGroup				AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness				AS LineOfBusiness,
	|	DocumentData.Basis							AS Basis,
	|	DocumentData.ReferenceDocumentDateForPrintForms						AS ReferenceDocumentDateForPrintForms,
	|	DocumentData.BaseDocumentNumber						AS BaseDocumentNumber
	|INTO ProductTransferData
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentTransfers_
	|
	|INDEX BY
	|	Organization,
	|	CompanyRecipient,
	|	Warehouse,
	|	Contract
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Currency				AS Currency,
	|	Dimension.Products				AS Products,
	|	Dimension.Characteristic			AS Characteristic,
	|	Dimension.Purpose				AS Purpose,
	|	Dimension.Series						AS Series,
	|	TransferGoods.Package				AS Package,
	|	SUM(TransferGoods.Count)	AS Count,
	|	SUM(TransferGoods.AmountIncludingVAT)		AS Sum,
	|	TransferGoods.VATRate			AS VATRate,
	|	SUM(TransferGoods.VATAmount)		AS VATAmount,
	|	SUM(TransferGoods.AmountIncludingVAT)		AS AmountIncludingVAT
	|INTO TransferGoods
	|FROM
	|	Document.CustomerInvoiceIntercompany.InventoryKinds AS TransferGoods
	|		INNER JOIN Document.CustomerInvoiceIntercompany AS DocumentData
	|		ON TransferGoods.Ref = DocumentData.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TransferGoods.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.Products AS ProductData_9
	|		ON Dimension.Products = ProductData_9.Ref
	|
	|WHERE
	|	TransferGoods.Ref = &DocumentTransfers_
	|	AND ISNULL(ProductData_9.ItemsType, UNDEFINED) IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|																VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	DocumentData.Currency,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Purpose,
	|	Dimension.Series,
	|	TransferGoods.Package,
	|	TransferGoods.VATRate
	|
	|INDEX BY
	|	Currency,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Package
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Currency				AS Currency,
	|	Dimension.Products				AS Products,
	|	Dimension.Characteristic			AS Characteristic,
	|	Dimension.Purpose				AS Purpose,
	|	Dimension.Series						AS Series,
	|	ReturnItems.Package				AS Package,
	|	SUM(ReturnItems.Count)	AS Count,
	|	SUM(ReturnItems.AmountIncludingVAT)		AS Sum,
	|	ReturnItems.VATRate			AS VATRate,
	|	SUM(ReturnItems.VATAmount)		AS VATAmount,
	|	SUM(ReturnItems.AmountIncludingVAT)		AS AmountIncludingVAT
	|INTO ReturnItems
	|FROM
	|	Document.IntercompanyGoodsReturn.InventoryKinds AS ReturnItems
	|		INNER JOIN Document.IntercompanyGoodsReturn AS DocumentData
	|		ON ReturnItems.Ref = DocumentData.Ref
	|		
	|		INNER JOIN ProductTransferData AS ProductTransferData
	|		ON DocumentData.Organization = ProductTransferData.Organization
	|			AND DocumentData.CompanyRecipient = DocumentData.CompanyRecipient
	|			AND DocumentData.Warehouse = ProductTransferData.Warehouse
	|			AND DocumentData.Contract = ProductTransferData.Contract
	|			AND DocumentData.Date >= BEGINOFPERIOD(ProductTransferData.TransferDate, MONTH)
	|			AND DocumentData.Posted
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON ReturnItems.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.Products AS ProductData_9
	|		ON Dimension.Products = ProductData_9.Ref
	|
	|WHERE
	|	ReturnItems.DocumentTransfers_ = &DocumentTransfers_
	|	AND ISNULL(ProductData_9.ItemsType, UNDEFINED) IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|																VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	DocumentData.Currency,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Purpose,
	|	Dimension.Series,
	|	ReturnItems.Package,
	|	ReturnItems.VATRate
	|
	|INDEX BY
	|	Currency,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Package
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&DocumentTransfers_														AS DocumentTransfers_,
	|	ISNULL(TransferGoods.Products, ReturnItems.Products)		AS Products,
	|	ISNULL(TransferGoods.Characteristic, ReturnItems.Characteristic)	AS Characteristic,
	|	ISNULL(TransferGoods.Purpose, ReturnItems.Purpose)			AS Purpose,
	|	ISNULL(TransferGoods.Series, ReturnItems.Series)					AS Series,
	|	ISNULL(TransferGoods.Package, ReturnItems.Package)				AS Package,
	|	ISNULL(TransferGoods.Count, 0)
	|		- ISNULL(ReturnItems.Count, 0)							AS Count,
	|	ISNULL(TransferGoods.Sum, 0)
	|		- ISNULL(ReturnItems.Sum, 0)									AS Sum,
	|	ISNULL(TransferGoods.VATRate, ReturnItems.VATRate)			AS VATRate,
	|	ISNULL(TransferGoods.VATAmount, 0)
	|		- ISNULL(ReturnItems.VATAmount, 0)								AS VATAmount,
	|	ISNULL(TransferGoods.AmountIncludingVAT, 0)
	|		- ISNULL(ReturnItems.AmountIncludingVAT, 0)								AS AmountIncludingVAT,
	|	VALUE(Enum.WaysToCalculateReturnCost.FromTransferDocument) AS CostDefiningMethod
	|FROM
	|	TransferGoods AS TransferGoods
	|		FULL JOIN ReturnItems AS ReturnItems
	|		ON TransferGoods.Products = ReturnItems.Products
	|			AND TransferGoods.Characteristic = ReturnItems.Characteristic
	|			AND TransferGoods.Purpose = ReturnItems.Purpose
	|			AND TransferGoods.Series = ReturnItems.Series
	|			AND TransferGoods.Package = ReturnItems.Package";
	
	Query.SetParameter("DocumentTransfers_", DocumentBasis);
	
	QueryResult = Query.ExecuteBatchWithIntermediateData();
	
	If Not QueryResult[0].IsEmpty() Then
		HeaderData_ = QueryResult[0].Select();
		HeaderData_.Next();
		
		FillPropertyValues(ThisObject, HeaderData_);
	EndIf;
	
	ColumnsNames = "Products,Characteristic,Purpose,Series,VATRate";
	
	GoodsTable = QueryResult[QueryResult.UBound()].Unload();
	GoodsTable.Indexes.Add(ColumnsNames);
	
	For Each RowOfGoods In GoodsTable Do
		
		If RowOfGoods.Count < 0 Then
			
			RowFilter = New Structure(ColumnsNames);
			FillPropertyValues(RowFilter, RowOfGoods);
			
			TransferLines = GoodsTable.FindRows(RowFilter);
			
			For Each TransferString In TransferLines Do
			
				If TransferString.Count < 0 Then
					Continue;
				EndIf;
				
				RowOfGoods.Count	= -RowOfGoods.Count;
				RowOfGoods.Sum			= -RowOfGoods.Sum;
				RowOfGoods.VATAmount		= -RowOfGoods.VATAmount;
				RowOfGoods.AmountIncludingVAT		= -RowOfGoods.AmountIncludingVAT;;
				
				If RowOfGoods.Count > TransferString.Count Then
					AmountToDeduct	= TransferString.Count;
					AmountToDeduct_		= TransferString.Sum;
					AmountOfVATDeducted		= TransferString.VATAmount;
					AmountWithVATDeductible	= TransferString.AmountIncludingVAT;
				Else
					AmountToDeduct	= RowOfGoods.Count;
					AmountToDeduct_		= RowOfGoods.Sum;
					AmountOfVATDeducted		= RowOfGoods.VATAmount;
					AmountWithVATDeductible	= RowOfGoods.AmountIncludingVAT;
				EndIf;
				
				RowOfGoods.Count	= RowOfGoods.Count - AmountToDeduct;
				RowOfGoods.Sum			= RowOfGoods.Sum - AmountToDeduct_;
				RowOfGoods.VATAmount		= RowOfGoods.VATAmount - AmountOfVATDeducted;
				TransferLines.AmountIncludingVAT	= TransferLines.AmountIncludingVAT - AmountWithVATDeductible;
				
				TransferLines.Count	= TransferLines.Count - AmountToDeduct;
				TransferLines.Sum		= TransferLines.Sum - AmountToDeduct_;
				TransferLines.VATAmount		= TransferLines.VATAmount - AmountOfVATDeducted;
				RowOfGoods.AmountIncludingVAT		= RowOfGoods.AmountIncludingVAT - AmountWithVATDeductible;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	LinesToDelete = New Array;
	
	For Each RowOfGoods In GoodsTable Do
		If RowOfGoods.Count <= 0 Then
			LinesToDelete.Add(RowOfGoods);
		EndIf;
	EndDo;
	
	For Each RowOfGoods In LinesToDelete Do
		GoodsTable.Delete(RowOfGoods);
	EndDo;
	
	GoodsTable.Sort(ColumnsNames);
	
	ActionsWithString = New Structure("RecalculateNumberOfPackages");
	RowsToProcess = New Array;
	
	For Each RowOfGoods In GoodsTable Do
		NewRow = Goods.Add();
		FillPropertyValues(NewRow, RowOfGoods);
		RowsToProcess.Add(NewRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		ActionsWithString,
		Goods);
		
	For Each RowOfGoods In RowsToProcess Do
		PriceManagementSystem.RecalculateAmountsInRowWithVAT(RowOfGoods, PriceIncludesVAT, False, False, True);
	EndDo;
	
	FillInCCDNumbersOnOrders();
	
	RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(ThisObject);
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	
EndProcedure

Procedure FillInItemsOnBalancesForReturn(BeginOfPeriod = Undefined, EndOfPeriod = Undefined)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ForThePeriod.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	InventoryKinds.Ref						AS InventoryOwnerAttribute,
	|	ForThePeriod.CCDNumber						AS CCDNumber,
	|	ForThePeriod.ReturnedTurnover				AS ReturnedOnDate,
	|	ISNULL(ForNow.ReturnedBalance,0)	AS ReturnedToNow
	|INTO ForReturn
	|FROM
	|	AccumulationRegister.CompanyGoodsForTransfer.BalanceAndTurnovers(&InitialBorder, &ConBorder, Period, ,
	|		CompanyOwner = &CompanyRecipient
	|		AND ItemsLocationAttributes.StorageLocation = &Warehouse) AS ForThePeriod
	|
	|	INNER JOIN
	|		Catalog.InventoryKinds AS InventoryKinds
	|	ON
	|		ForThePeriod.SellerInventoryOwnerAttribute = InventoryKinds.Ref
	|
	|	LEFT JOIN
	|		AccumulationRegister.CompanyGoodsForTransfer.Balance(,
	|			CompanyOwner = &CompanyRecipient
	|			AND ItemsLocationAttributes.StorageLocation = &Warehouse) AS ForNow
	|	ON
	|		ForThePeriod.ItemsLocationAttributes = ForNow.ItemsLocationAttributes
	|		AND ForThePeriod.CCDNumber = ForNow.CCDNumber
	|		AND ForThePeriod.SellerInventoryOwnerAttribute = ForNow.SellerInventoryOwnerAttribute
	|WHERE
	|	InventoryKinds.Organization = &Organization
	|	AND InventoryKinds.SaleOfAnotherCompanyInventory
	|	AND ForThePeriod.ReturnedTurnover > 0
	|	AND ISNULL(ForNow.ReturnedBalance,0) > 0
	|	AND InventoryKinds.InventoryType = &InventoryType
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE WHEN ForReturn.ReturnedToNow < ForReturn.ReturnedOnDate THEN
	|		ForReturn.ReturnedToNow
	|	ELSE
	|		ForReturn.ReturnedOnDate
	|	END									AS Count,
	|	ForReturn.ItemsLocationAttributes.Products AS Products,
	|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
	|		VALUE(Catalog.VATRates.EmptyRef))) AS VATRate,
	|	ForReturn.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	ForReturn.ItemsLocationAttributes.Series AS Series,
	|	ForReturn.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	ForReturn.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	ForReturn.CCDNumber						AS CCDNumber,
	|	ForReturn.ItemsLocationAttributes.Purpose AS Purpose,
	|	TRUE									AS ByUninvoicedGoods
	|FROM
	|	ForReturn
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&EndDate,
	|				Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
	|			ON ForReturn.ItemsLocationAttributes.Products = ProductsVATRates.Products
	|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&EndDate, Country = &RegistrationCountry) AS BasicVATRates
	|			ON (TRUE)
	|
	|ORDER BY
	|	ForReturn.ItemsLocationAttributes.Products,
	|	ForReturn.ItemsLocationAttributes.Characteristic,
	|	ForReturn.ItemsLocationAttributes.Series,
	|	ForReturn.InventoryOwnerAttribute,
	|	ForReturn.CCDNumber";
	
	Query.SetParameter("CompanyRecipient", CompanyRecipient);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("InventoryType", TypeOfOperationInventory());
	
	StartDate = ?(ValueIsFilled(BeginOfPeriod), BeginOfPeriod, '00010101');
	EndDate = ?(ValueIsFilled(EndOfPeriod), EndOfPeriod, Date);
	Query.SetParameter("InitialBorder", New Boundary(StartDate, BoundaryType.Including));
	Query.SetParameter("ConBorder", New Boundary(EndDate, BoundaryType.Including));
	
	Query.SetParameter("EndDate", EndDate);
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
		
	Goods.Clear();
	GoodsTable = Goods.Unload();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewRow = InventoryKinds.Add();
		FillPropertyValues(NewRow, Selection);
		
		NewProductRow = GoodsTable.Add();
		FillPropertyValues(NewProductRow, Selection);
		NewProductRow.NumberOfPackages = NewProductRow.Count;
	EndDo;
	
	GoodsTable.GroupBy("Products, Characteristic, Series, ItemsLocationAttributes, VATRate, Purpose, ByUninvoicedGoods",
							"Count, NumberOfPackages");
	
	Goods.Load(GoodsTable);
	
	RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(ThisObject);
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	
EndProcedure

Procedure FillInTaxAndDefaultPrices()
	
	CompleteVATTaxation();
	
	CachedValues = Undefined;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	ParametersFillInVATRate.Organization = CompanyRecipient;
	If ValueIsFilled(DocumentTransfers_) Then
		ParametersFillInVATRate.Date = Common.ObjectAttributeValue(DocumentTransfers_, "Date");
	EndIf;
	Actions = New Structure("FillInVATRate", ParametersFillInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, Actions, CachedValues);
	
	FillInDefaultPriceView();
	If ValueIsFilled(PriceKind) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		
		FillParameters = New Structure();
		FillParameters.Insert("Date", Date);
		FillParameters.Insert("Organization", Organization);
		FillParameters.Insert("Currency", Currency);
		FillParameters.Insert("PriceKind", PriceKind);
		FillParameters.Insert("PopulationFields", "Price, PriceKind");
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		
		EnterprisePricesFillingServer.FillInPrices(Goods, , FillParameters, StructureOfActions);
	EndIf;
	
EndProcedure

Procedure FillInDefaultPriceView()
	
	If Not ValueIsFilled(PriceKind) Then
		SelectionOfPriceType = New Structure("UseForIntercompanySales", True);
		PriceKind       = Catalogs.TypesOfPrices.DefaultPriceType(PriceKind, SelectionOfPriceType);
	EndIf;
	
	If ValueIsFilled(PriceKind) Then
		Attributes = Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind);
		
		Currency          = Attributes.PriceCurrency;
		PriceIncludesVAT = Attributes.PriceIncludesVAT;
	EndIf;
	
EndProcedure

Procedure FillDefaultAttributes()
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse       = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Author       = Users.CurrentUser();
	
	FillInDefaultPriceView();
	
	Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
	
EndProcedure

Function TypeOfOperationInventory()
	Return ?(BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn,
			Enums.InventoryTypes.ConsignedGoods,
			Enums.InventoryTypes.OwnGoods);
EndFunction

Procedure CompleteVATTaxation(Fill = True)
	
	If Not Fill Then
		Return;
	EndIf;
	
	FillParameters = Documents.IntercompanyGoodsReturn.ParametersForFillingInVATTaxation_(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure

Procedure ProcessTabularPart()
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;
	StructureOfFillingInVATRate.Organization = CompanyRecipient;
	If ValueIsFilled(DocumentTransfers_) Then
		StructureOfFillingInVATRate.Date = Common.ObjectAttributeValue(DocumentTransfers_, "Date");
	EndIf;
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		Undefined);
	
EndProcedure

Procedure FillOutBankAccounts()
	
	If ValueIsFilled(CompanyBankAccount) And ValueIsFilled(RecipientCompanyBankAccount) Then
		Return;
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Contract,
		?(ValueIsFilled(RecipientCompanyBankAccount), Undefined, RecipientCompanyBankAccount),
		?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount));
	
	If ValueIsFilled(Organization) And Not ValueIsFilled(CompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(CompanyRecipient) And Not ValueIsFilled(RecipientCompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(CompanyRecipient);
		RecipientCompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
			ParametersOfAccount);
	EndIf;
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	ProductLinesForRegistration = Goods.FindRows(New Structure("ByUninvoicedGoods", True));
	ThereAreOnGoodsForRegistration = ProductLinesForRegistration.Count() > 0;
	ThereAreReserves           = ProductLinesForRegistration.Count() <> Goods.Count();
	InventoryTypesAreOverfilled = False;
	
	If ThereAreReserves Then
		
		TempTablesManager		= TemporaryDocumentDataTables(False);
		RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
		
		If Not Posted
			Or RefillInventoryKinds
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckChangesInGoodsByQuantityAndAmount(TempTablesManager) Then
			
			CheckCorrectnessOfReturnedProducts(Cancel);
			
			If Cancel Then
				Return;
			EndIf;
			
			InventoryTypesAreOverfilled = True;
			
			If ThereAreOnGoodsForRegistration Then
				TypesOfInventoryForRegistration = InventoryKinds.Unload(New Structure("ByUninvoicedGoods", True));
				
				InventoryKinds.Clear();
			EndIf;
			
			FillParameters = ParametersForFillingInventoryTypes("Organization");
			FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
			FillParameters.NameOfRemainderTable = "GoodsTransferredBetweenOrganizations";
			
			InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																	TempTablesManager,
																	Cancel,
																	FillParameters);
			
			FillInAdditionalStockTypes(False);
			
			For Each String In InventoryKinds Do
				If ValueIsFilled(String.InventoryOwnerAttributeShipment) Then
					String.RecipientInventoryOwnerAttribute	= String.InventoryOwnerAttributeShipment;
				EndIf;
			EndDo;
			
			If ThereAreOnGoodsForRegistration Then
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfInventoryForRegistration);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ThereAreOnGoodsForRegistration Then
		
		TempTablesManager		= TemporaryDocumentDataTables(True);
		RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
		
		If Not Posted
			Or RefillInventoryKinds
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckChangesInGoodsByQuantityAndAmount(TempTablesManager) Then
			
			InventoryTypesAreOverfilled = True;
			
			FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
			FillParameters.AvailableTypesOfStocksHaveAlreadyBeenFormed = True;
			FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
			FillParameters.NameOfRemainderTable = "ProductsFromOrganizationsToBeReturned";
			
			TTAvailableInventoryTypesForGoodsToTransfer(TempTablesManager);
			
			If ThereAreReserves Then
				TypesOfStocksNotRelatedToRegistration = InventoryKinds.Unload(New Structure("ByUninvoicedGoods", False));
				
				InventoryKinds.Clear();
			EndIf;
			
			InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																	TempTablesManager,
																	Cancel,
																	FillParameters);
			
			For Each RowOfTables In InventoryKinds Do
				RowOfTables.ByUninvoicedGoods = True;
			EndDo;
			
			FillInAdditionalStockTypes(True);
			
			If ThereAreReserves Then
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStocksNotRelatedToRegistration);
			EndIf;
			
		EndIf;
		
	EndIf;
	If InventoryTypesAreOverfilled
		And GetFunctionalOption("UseExcisableGoods")
		And BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn Then
		
		FillParameters = ParametersForFillingInventoryTypes("CompanyRecipient");
		FillParameters.CalculateAmountOfExciseTax = True;
		NameOfColumnInventoryOwnerAttribute = "RecipientInventoryOwnerAttribute";
		ExcisableGoodsAccounting.CalculateAmountOfExciseTax(ThisObject, FillParameters, NameOfColumnInventoryOwnerAttribute, Cancel);
		AdditionalProperties.Insert("WriteDownAmountOfExciseTax", True)
		
	EndIf;
	If Not InventoryTypesAreOverfilled
		And InventoryKinds.Find(Catalogs.InventoryKinds.EmptyRef(), "RecipientInventoryOwnerAttribute") <> Undefined Then
		
		ExceptionText = "vi = 'Chưa điền cột bổ sung trong phần bảng ""Dạng vật tư"".';
						|ru = 'Не заполнены дополнительные колонки в табличной части ""Виды запасов"".';
						|en = 'Additional columns in the ""Inventory owner attributes"" table are not filled in.';
						|it = 'Le colonne aggiuntive nella tabella ""Tipi di scorte"" non sono compilate.';
						|pl = 'Nie wypełniono dodatkowych kolumn w sekcji tabelarycznej ""Rodzaje zapasów"".';
						|tr = '""Stok türleri"" tablo bölümündeki ek sütunlar doldurulmadı.'";
		
		Raise ExceptionText;
		
	EndIf;
	
EndProcedure

Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus = 14
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfGoods.Warehouse,
	|
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.Users.EmptyRef) AS Manager,
	|	TableOfGoods.SalesOpportunity AS SalesOpportunity,
	|	TableOfGoods.Purpose AS Purpose,
	|
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&VATTaxation AS VATTaxation,
	|
	|	TableOfGoods.Count AS Count
	|	
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|
	|	LEFT JOIN
	|		DocumentDataTable AS DocumentDataTable
	|	ON
	|		TRUE
	|WHERE
	|	TableOfGoods.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|");
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

// Generates temporary tables, the data of which is used in the report leftovers of organizations.
//
// Parameters:
//	ByUninvoicedGoods - Boolean - indicates that product balances are being used for processing returns between
//									organizations.
//
// Returns:
//	TempTablesManager - tables containing information about the document.
//
Function TemporaryDocumentDataTables(ByUninvoicedGoods = False) Export
	
	Query = New Query;
	Query.Text =
	// Document Data table - Details of the object
	"SELECT
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Warehouse AS Warehouse,
	|	&VATTaxation AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|	&BusinessOperation AS BusinessReturnOperation,
	|	&EconomicTransferOperation AS EconomicTransferOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	&CompanyRecipient AS CompanyRecipient,
	|	&ARAPAccountingViaSeparateCounterparty AS ARAPAccountingViaSeparateCounterparty,
	|	&Partner AS Partner,
	|	&DocumentTransfers_ AS DocumentTransfers_,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	&Counterparty AS Counterparty,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	&SubjectToExcise AS SubjectToExcise,
	|	&BusinessUnitProduction AS BusinessUnitProduction,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|/////////////////////////////////////////////////////
	// Types of supplies - Tab Part of types of supplies
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment AS ItemsLocationAttributesShipment,
	|	TableTypesOfStocks_.DocumentTransfers_ AS DocumentTransfers_,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TableTypesOfStocks_.ExciseTaxAmount AS ExciseTaxAmount,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	&Warehouse AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.CostDefiningMethod AS CostDefiningMethod
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|//////////////////////////////////////////////////////
	// Table of Types of Reserves - Tab Part of types of reserves
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment AS ItemsLocationAttributesShipment,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	TableTypesOfStocks_.DocumentTransfers_ AS DocumentTransfers_,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.CommissionAmount AS CommissionAmount,
	|	TableTypesOfStocks_.AmountVATRemuneration AS AmountVATRemuneration,
	|	TableTypesOfStocks_.ExciseTaxAmount AS ExciseTaxAmount,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.CostDefiningMethod AS CostDefiningMethod
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|/////////////////////////////////////////////////////
	// Table of Goods - Tab Part of Goods
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	&Warehouse AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.DocumentTransfers_ AS DocumentTransfers_,
	|	TableOfGoods.CostDefiningMethod AS CostDefiningMethod
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.ByUninvoicedGoods = &ByUninvoicedGoods
	|;
	|/////////////////////////////////////////////////////
	|";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("CompanyRecipient", CompanyRecipient);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("ARAPAccountingViaSeparateCounterparty", ARAPAccountingViaSeparateCounterparty);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	If BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn Then
		Query.SetParameter("EconomicTransferOperation", Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany);
	Else
		Query.SetParameter("EconomicTransferOperation", Enums.BusinessTransactions.GoodsSaleToAnotherCompany);
	EndIf;
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds.Unload(New Structure("ByUninvoicedGoods", ByUninvoicedGoods)));
	Query.SetParameter("DocumentTransfers_", DocumentTransfers_);
	Query.SetParameter("ByUninvoicedGoods", ByUninvoicedGoods);
	Query.SetParameter("SubjectToExcise", ?(Not ByUninvoicedGoods, SubjectToExcise, False));
	Query.SetParameter("BusinessUnitProduction",
								?(Not ByUninvoicedGoods,
								BusinessUnitProduction,
								Catalogs.BusinessStructure.EmptyRef()));
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Procedure FillInAdditionalStockTypes(ByUninvoicedGoods)
	
	TMCommonUse.CollapseTablePart(ThisObject, "InventoryKinds");
	
	For Each Inventory In InventoryKinds Do
		
		If ValueIsFilled(Inventory.RecipientInventoryOwnerAttribute)
			And Not Inventory.ByUninvoicedGoods Then
			
			Inventory.RecipientInventoryOwnerAttribute = Undefined;
			
		EndIf;
		
	EndDo;
	
	If InventoryKinds.Find(Catalogs.InventoryKinds.EmptyRef(), "RecipientInventoryOwnerAttribute") <> Undefined Then
		QueryTexts = New Array;
		
		PartOfTheRequestText =
		"SELECT
		|	TableTypesOfStocks_.LineNumber AS LineNumber,
		|	TableTypesOfStocks_.DocumentTransfers_ AS DocumentTransfers_,
		|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes
		|INTO TableOfInventoryOwnerAttributesForRequest
		|FROM
		|	&InventoryKinds AS TableTypesOfStocks_
		|WHERE
		|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableTypesOfStocks_.LineNumber AS LineNumber,
		|	ISNULL(TheseGrounds.Date, &Date) AS Date,
		|	InventoryLocationAttributeKeys.Products AS Products
		|INTO TTOriginalProductTable
		|FROM
		|	TableOfInventoryOwnerAttributesForRequest AS TableTypesOfStocks_
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|		ON TableTypesOfStocks_.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
		|		LEFT JOIN Document.CustomerInvoiceIntercompany AS TheseGrounds
		|		ON TableTypesOfStocks_.DocumentTransfers_ = TheseGrounds.Ref
		|
		|INDEX BY
		|	Products,
		|	Date
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TableOfInventoryOwnerAttributesForRequest";
		QueryTexts.Add(PartOfTheRequestText);
		RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
		RequestTextParameters.SelectingCategoriesByDate = False;
		RequestTextParameters.ProductTableName_ = "TTOriginalProductTable";
		RequestTextParameters.FieldNamePeriod = "Date";
		
		QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(, RequestTextParameters));
		PartOfTheRequestText =
		"SELECT
		|	TableOfGoods.LineNumber AS LineNumber,
		|	TableOfGoods.Products AS Products,
		|	UNDEFINED AS CurViewOfStocks,
		|	FALSE AS ThisIsReusablePackage,
		|	&CompanyRecipient AS Organization,
		|	&BusinessOperation AS BusinessOperation,
		|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
		|	UNDEFINED AS GoodsOwner,
		|	UNDEFINED AS Terms,
		|	UNDEFINED AS Counterparty,
		|	UNDEFINED AS Contract,
		|	UNDEFINED AS Currency,
		|	UNDEFINED AS VATTaxation,
		|	UNDEFINED AS TaxationOfOrganization,
		|	CASE
		|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
		|			THEN &SubjectToExcise
		|		ELSE FALSE
		|	END AS SubjectToExcise,
		|	CASE
		|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
		|			THEN &BusinessUnitProduction
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS BusinessUnitProduction,
		|	UNDEFINED AS PriceKind
		|INTO OriginalProductTable
		|FROM
		|	TTOriginalProductTable AS TableOfGoods
		|		LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
		|		ON TableOfGoods.Products = Category_Data.Products
		|			AND TableOfGoods.Date = Category_Data.Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTExciseCategoriesOfItems
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTOriginalProductTable";
		QueryTexts.Add(PartOfTheRequestText);
		
		TempTablesManager = New TempTablesManager;
		
		NamesOfColumnsToUpload = "LineNumber, RecipientInventoryOwnerAttribute, ItemsLocationAttributes";
		NamesOfColumnsToUpload = NamesOfColumnsToUpload + ", DocumentTransfers_";
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		Query.SetParameter("CompanyRecipient", CompanyRecipient);
		Query.SetParameter("BusinessOperation", BusinessOperation);
		Query.SetParameter("InventoryKinds", InventoryKinds.Unload(, NamesOfColumnsToUpload));
		RegistrationCountry				= SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
		UseExcisableGoods	= GetFunctionalOption("UseExcisableGoods");
		
		Query.SetParameter("Date",				Date);
		Query.SetParameter("Country",				RegistrationCountry);
		Query.SetParameter("SubjectToExcise",	?(Not ByUninvoicedGoods, SubjectToExcise, False));
		Query.SetParameter("BusinessUnitProduction",
									?(Not ByUninvoicedGoods,
									BusinessUnitProduction,
									Catalogs.BusinessStructure.EmptyRef()));
		Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
		InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
		
		Query.Execute();
		
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, InventoryKinds, , "RecipientInventoryOwnerAttribute");
	EndIf;
	
	FoundProductLines = Goods.FindRows(New Structure("ByUninvoicedGoods", ByUninvoicedGoods));
	
	For Each RowOfGoods In FoundProductLines Do
		
		NumberOfProductsPerLine = RowOfGoods.Count;
		NumberOfPackagesPerLine = RowOfGoods.NumberOfPackages;
		SumOfSNDSInLine = RowOfGoods.AmountIncludingVAT;
		AmountOfNDSVLine = RowOfGoods.VATAmount;
		CostPerLine = RowOfGoods.Cost_;
		CostPriceWithoutNDSVLine = RowOfGoods.CostExcludingVAT_;
		LocalCostInLine = RowOfGoods.CostLocal;
		CostOfPRVLine = RowOfGoods.CDCost;
		CostOfVRVLine = RowOfGoods.TDCost;
		
		TheStructureOfTheSearch = ?(ValueIsFilled(RowOfGoods.DocumentTransfers_),
							New Structure("ItemsLocationAttributes, DocumentTransfers_"),
							New Structure("ItemsLocationAttributes"));
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(NumberOfProductsPerLine, InventoryLine.Count);
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.CostDefiningMethod = RowOfGoods.CostDefiningMethod;
			NewRow.Package = RowOfGoods.Package;
			NewRow.Count = Count;
			NewRow.QuantityByGBRN = Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			NewRow.NumberOfPackages = ?(Count = NumberOfProductsPerLine, NumberOfPackagesPerLine,
				Count * NumberOfPackagesPerLine / NumberOfProductsPerLine);
			NewRow.AmountIncludingVAT = ?(Count = NumberOfProductsPerLine, SumOfSNDSInLine,
				Count * SumOfSNDSInLine / NumberOfProductsPerLine);
			NewRow.VATAmount = ?(Count = NumberOfProductsPerLine, AmountOfNDSVLine,
				Count * AmountOfNDSVLine / NumberOfProductsPerLine);
			NewRow.Cost_ = ?(Count = NumberOfProductsPerLine, CostPerLine,
				Count * CostPerLine / NumberOfProductsPerLine);
			NewRow.CostExcludingVAT_ = ?(Count = NumberOfProductsPerLine, CostPriceWithoutNDSVLine,
				Count * CostPriceWithoutNDSVLine / NumberOfProductsPerLine);
			NewRow.CostLocal = ?(Count = NumberOfProductsPerLine, LocalCostInLine,
				Count * LocalCostInLine / NumberOfProductsPerLine);
			NewRow.CDCost = ?(Count = NumberOfProductsPerLine, CostOfPRVLine,
				Count * CostOfPRVLine / NumberOfProductsPerLine);
			NewRow.TDCost = ?(Count = NumberOfProductsPerLine, CostOfVRVLine,
				Count * CostOfVRVLine / NumberOfProductsPerLine);
			NewRow.ExciseTaxAmount = Count * InventoryLine.ExciseTaxAmount / InventoryLine.Count;
			InventoryLine.Count = InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN = InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.NumberOfPackages = InventoryLine.NumberOfPackages - NewRow.NumberOfPackages;
			InventoryLine.AmountIncludingVAT = InventoryLine.AmountIncludingVAT- NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount = InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.Cost_ = InventoryLine.Cost_ - NewRow.Cost_;
			InventoryLine.CostExcludingVAT_ = InventoryLine.CostExcludingVAT_ - NewRow.CostExcludingVAT_;
			InventoryLine.CostLocal = InventoryLine.CostLocal - NewRow.CostLocal;
			InventoryLine.CDCost = InventoryLine.CDCost - NewRow.CDCost;
			InventoryLine.TDCost = InventoryLine.TDCost - NewRow.TDCost;
			InventoryLine.ExciseTaxAmount = InventoryLine.ExciseTaxAmount - NewRow.ExciseTaxAmount;
			NumberOfProductsPerLine = NumberOfProductsPerLine - NewRow.Count;
			NumberOfPackagesPerLine = NumberOfPackagesPerLine - NewRow.NumberOfPackages;
			SumOfSNDSInLine = SumOfSNDSInLine - NewRow.AmountIncludingVAT;
			AmountOfNDSVLine = AmountOfNDSVLine - NewRow.VATAmount;
			CostPerLine = CostPerLine - NewRow.Cost_;
			CostPriceWithoutNDSVLine = CostPriceWithoutNDSVLine - NewRow.CostExcludingVAT_;
			LocalCostInLine = LocalCostInLine - NewRow.CostLocal;
			CostOfPRVLine = CostOfPRVLine - NewRow.CDCost;
			CostOfVRVLine = CostOfVRVLine - NewRow.TDCost;
			
			If NumberOfProductsPerLine = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure TTAvailableInventoryTypesForGoodsToTransfer(TempTablesManager)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Sender AS ForCompany,
	|	PossibleTypesOfStocks.Ref AS InventoryOwnerAttribute,
	|	FALSE AS SelectionAccordingToCommitteeSVATRate,
	|	UNDEFINED AS CommitteeSVATRate
	|INTO AvailableTypesOfStocks
	|FROM
	|	Catalog.InventoryKinds AS PossibleTypesOfStocks
	|WHERE
	|	PossibleTypesOfStocks.SaleOfAnotherCompanyInventory
	|	AND PossibleTypesOfStocks.Organization = &Sender
	|	AND PossibleTypesOfStocks.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization = &Recipient
	|
	|INDEX BY
	|	InventoryOwnerAttribute";
	
	Query.SetParameter("Recipient", CompanyRecipient);	
	Query.SetParameter("Sender", Organization);
	
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure CheckCorrectnessOfReturnedProducts(Cancel)
	
	// For PM Items lines, check that refunds do not exceed transfers.
	// Features:
	//	- it is not allowed that the return has a different purpose than the transfer,
	//		because it has no practical meaning
	//	- restriction - if the return is made to a warehouse other than the transfer,
	//		then the item must have the same batch accounting setting at cost -
	//		either on or off at both warehouses, i.e. it cannot be transferred with a batch, but
	//		returned without (and vice versa). If this needs to be done, then as a bypass - return without 
	//		specifying the transfer document.

	If Goods.Count() = 0 Then
		Return;
	EndIf;
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	InspectedGoods.Products AS Products,
	|	InspectedGoods.Characteristic AS Characteristic,
	|	InspectedGoods.Series AS Series,
	|	InspectedGoods.Purpose AS Purpose,
	|	InspectedGoods.Count AS Count,
	|	InspectedGoods.DocumentTransfers_ AS DocumentTransfers_
	|INTO InspectedGoods
	|FROM
	|	&TableOfCheckedProducts AS InspectedGoods
	|WHERE
	|	InspectedGoods.DocumentTransfers_ <> VALUE(Document.CustomerInvoiceIntercompany.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InspectedGoods.Products AS Products,
	|	InspectedGoods.Products.UnitOfMeasure AS UnitOfMeasure,
	|	InspectedGoods.Characteristic AS Characteristic,
	|	InspectedGoods.Series AS Series,
	|	InspectedGoods.Purpose AS Purpose,
	|	SUM(InspectedGoods.Count) AS Count,
	|	InspectedGoods.DocumentTransfers_ AS DocumentTransfers_,
	|	InspectedGoods.DocumentTransfers_.Number AS SalesNumber
	|FROM
	|	(SELECT
	|		CustomerInvoiceIntercompany.Products AS Products,
	|		CustomerInvoiceIntercompany.Characteristic AS Characteristic,
	|		CustomerInvoiceIntercompany.Series AS Series,
	|		CustomerInvoiceIntercompany.Purpose AS Purpose,
	|		CustomerInvoiceIntercompany.Count AS Count,
	|		CustomerInvoiceIntercompany.Ref AS DocumentTransfers_
	|	FROM
	|		Document.CustomerInvoiceIntercompany.Goods AS CustomerInvoiceIntercompany
	|			INNER JOIN InspectedGoods AS InspectedGoods
	|			ON CustomerInvoiceIntercompany.Ref = InspectedGoods.DocumentTransfers_
	|				AND (InspectedGoods.Products = CustomerInvoiceIntercompany.Products)
	|				AND (InspectedGoods.Characteristic = CustomerInvoiceIntercompany.Characteristic)
	|				AND (InspectedGoods.Series = CustomerInvoiceIntercompany.Series)
	|				AND (InspectedGoods.Purpose = CustomerInvoiceIntercompany.Purpose)
	|			LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStorno
	|			ON CustomerInvoiceIntercompany.Ref = RegisterOfDocumentsStorno.ReversedDocument
	|				AND RegisterOfDocumentsStorno.Posted
	|				AND NOT RegisterOfDocumentsStorno.AdditionalRecord
	|	WHERE
	|		CustomerInvoiceIntercompany.Ref.Posted
	|		AND RegisterOfDocumentsStorno.Ref IS NULL
	|
	|	UNION ALL
	|	
	|	SELECT
	|		IntercompanyGoodsReturn.Products,
	|		IntercompanyGoodsReturn.Characteristic,
	|		IntercompanyGoodsReturn.Series,
	|		IntercompanyGoodsReturn.Purpose,
	|		-IntercompanyGoodsReturn.Count,
	|		IntercompanyGoodsReturn.DocumentTransfers_
	|	FROM
	|		InspectedGoods AS InspectedGoods
	|			INNER JOIN Document.IntercompanyGoodsReturn.Goods AS IntercompanyGoodsReturn
	|			ON InspectedGoods.DocumentTransfers_ = IntercompanyGoodsReturn.DocumentTransfers_
	|				AND InspectedGoods.Products = IntercompanyGoodsReturn.Products
	|				AND InspectedGoods.Characteristic = IntercompanyGoodsReturn.Characteristic
	|				AND InspectedGoods.Series = IntercompanyGoodsReturn.Series
	|				AND InspectedGoods.Purpose = IntercompanyGoodsReturn.Purpose
	|			LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStorno
	|			ON IntercompanyGoodsReturn.Ref = RegisterOfDocumentsStorno.ReversedDocument
	|				AND RegisterOfDocumentsStorno.Posted
	|				AND NOT RegisterOfDocumentsStorno.AdditionalRecord
	|	WHERE
	|		IntercompanyGoodsReturn.Ref.Posted
	|		AND RegisterOfDocumentsStorno.Ref IS NULL
	|		AND IntercompanyGoodsReturn.Ref <> &ThisReturnLink
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InspectedGoods.Products,
	|		InspectedGoods.Characteristic,
	|		InspectedGoods.Series,
	|		InspectedGoods.Purpose,
	|		-InspectedGoods.Count,
	|		InspectedGoods.DocumentTransfers_
	|	FROM
	|		InspectedGoods AS InspectedGoods) AS InspectedGoods
	|
	|GROUP BY
	|	InspectedGoods.Series,
	|	InspectedGoods.DocumentTransfers_,
	|	InspectedGoods.Purpose,
	|	InspectedGoods.Characteristic,
	|	InspectedGoods.Products,
	|	InspectedGoods.Products.UnitOfMeasure,
	|	InspectedGoods.DocumentTransfers_.Number
	|
	|HAVING
	|	SUM(InspectedGoods.Count) < 0";
	
	Query.SetParameter("TableOfCheckedProducts", Goods);
	Query.SetParameter("ThisReturnLink", Ref);
	
	SetPrivilegedMode(True);
	ErrorsTable = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	If ErrorsTable.Count() > 0 Then
		Cancel = True;
		
		For Each ErrorString In ErrorsTable Do
			ErrorMessage = NStr("vi = 'Trả lại theo mặt hàng %GoodsPresentation% vượt quá số lượng hàng hóa được bán theo chứng từ bán hàng%SalesNumber% với%Count% %UnitOfMeasure%';
								|ru = 'Возврат по номенклатуре %GoodsPresentation% превышает количество реализованных товаров по документу продажи %SalesNumber% на %Count% %UnitOfMeasure%';
								|en = 'Return of products %GoodsPresentation% exceeds the quantity of purchased goods against sales document %SalesNumber% at %Count% %UnitOfMeasure%'; fa = 'Return of products %GoodsPresentation% exceeds the quantity of purchased goods against sales document %SalesNumber% at %Count% %UnitOfMeasure%';
								|it = 'Il reso secondo gli articoli %GoodsPresentation% supera la quantità di prodotti venduti secondo il documento di vendita %SalesNumber% per %Count% %UnitOfMeasure%';
								|pl = 'Zwrot wg nomenklatury %GoodsPresentation% przekracza ilość towarów sprzedanych w dokumencie sprzedaży %SalesNumber% o %Count% %UnitOfMeasure%';
								|tr = '%GoodsPresentation% öğeye göre iade, %SalesNumber% satış belgesinde satılan ürünlerin sayısını %Count% %UnitOfMeasure% tutarında aşıyor'");
			
			GoodsPresentation = ProductsClientServer.ProductPresentation(
				ErrorString.Products,
				ErrorString.Characteristic,
				ErrorString.Series,
				,
				ErrorString.Purpose);
			
			ErrorMessage = StrReplace(ErrorMessage, "%GoodsPresentation%",  GoodsPresentation);
			ErrorMessage = StrReplace(ErrorMessage, "%Count%",          -ErrorString.Count);
			ErrorMessage = StrReplace(ErrorMessage, "%UnitOfMeasure%",     ErrorString.UnitOfMeasure);
			ErrorMessage = StrReplace(ErrorMessage, "%SalesNumber%",      ErrorString.SalesNumber);
			
			CommonClientServer.MessageToUser(ErrorMessage);
		EndDo; 
	EndIf; 
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.IntercompanyGoodsReturn.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.IntercompanyGoodsReturn.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Warehouse,
																		Department,
																		Partner);
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting);
	
EndProcedure

#EndRegion

#Region Other

Function ChangesInStockTypesAreAllowed()
	// The duplication of the method with the method of the form is conscious
	Return BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn;
EndFunction

Procedure CheckOrganizations(Cancel)
	
	If ValueIsFilled(Organization)
		And ValueIsFilled(CompanyRecipient) Then
		
		If Organization = CompanyRecipient Then
			
			Text = NStr("vi = 'Một doanh nghiệp không thể đồng thời là nơi gửi và nơi nhận';
						|ru = 'Одна и та же организация не может являться отправителем и получателем одновременно';
						|en = 'Same company cannot be both a sender and a recipient'; fa = 'Same company cannot be both a sender and a recipient';
						|it = 'La stessa società non può essere mittente e destinatario contemporaneamente';
						|pl = 'Jedna i ta sama firma nie może jednocześnie być nadawcą i odbiorcą';
						|tr = 'Aynı iş yeri aynı anda hem gönderici hem de alıcı olamaz'");
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"Organization",
				,
				Cancel);
			
		ElsIf GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets")
			And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Organization, CompanyRecipient) Then
			
			Text = NStr("vi = 'Doanh nghiệp nhận hàng không được phép có quan hệ với doanh nghiệp gửi hàng về mặt cơ cấu tổ chức.';
						|ru = 'Организация-получатель не должна быть взаимосвязана с организацией-отправителем по организационной структуре.';
						|en = 'Receiving company should not be interrelated to the shipping company by the organizational structure.'; fa = 'Receiving company should not be interrelated to the shipping company by the organizational structure.';
						|it = 'La società-destinatario non deve essere interconnessa con la società-mittente per la struttura organizzativa.';
						|pl = 'Firma odbiorca nie powinna być wzajemnie powiązana z firmą nadawcą według struktury organizacyjnej.';
						|tr = 'Alıcı iş yeri, iş yeri yapısı bakımından gönderen iş yeri ile bağlantılı olmamalıdır.'");
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"CompanyRecipient",
				,
				Cancel);
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure CheckAmountFilling(Cancel)
	
	Query = New Query("
	|SELECT
	|	ObjectProducts.LineNumber,
	|	ObjectProducts.Products,
	|	ObjectProducts.Price,
	|	ObjectProducts.Sum,
	|	ObjectProducts.AmountIncludingVAT
	|INTO Goods
	|FROM
	|	&ObjectProducts AS ObjectProducts
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber,
	|	Goods.Products,
	|
	|	CASE WHEN Goods.Price = 0 
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS PriceNotFilledIn,
	|
	|	CASE WHEN Goods.Sum = 0 
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS AmountNotFilledIn,
	|
	|	CASE WHEN Goods.AmountIncludingVAT = 0 
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS AmountNotFilledWithVAT
	|FROM
	|	Goods
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatalogProducts
	|	ON
	|		Goods.Products = CatalogProducts.Ref
	|WHERE
	|	CatalogProducts.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND (Goods.Price = 0 OR Goods.Sum = 0 OR Goods.AmountIncludingVAT = 0)
	|");
	
	Query.SetParameter("ObjectProducts", Goods.Unload(,"LineNumber, Products, Price, Sum, AmountIncludingVAT"));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ErrorTextTemplate = NStr("vi = 'Chưa điền ""%ColumnName%"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнена ""%ColumnName%"" в строке %LineNumber% списка ""Товары""';
								|en = '""%ColumnName%"" is required in line %LineNumber% of the Item list'; fa = '""%ColumnName%"" is required in line %LineNumber% of the Item list';
								|it = 'Non è compilata %ColumnName% nella riga %LineNumber% dell''elenco ""Merci""';
								|pl = 'Niewypełnione ""%ColumnName%"" w wierszu %LineNumber% na liście ""Wiersze pozycji""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""%ColumnName%"" eksik'");
		ErrorTextTemplate = StrReplace(ErrorTextTemplate, "%LineNumber%",  Selection.LineNumber);
		
		If Selection.PriceNotFilledIn Then
			ReportErrorFillingInAmounts(ErrorTextTemplate, Selection.LineNumber, "Price", "Price", Cancel);
		EndIf;
		If Selection.AmountNotFilledIn Then
			ReportErrorFillingInAmounts(ErrorTextTemplate, Selection.LineNumber, "Sum", "Sum", Cancel);
		EndIf;
		If Selection.AmountNotFilledWithVAT Then
			ReportErrorFillingInAmounts(ErrorTextTemplate, Selection.LineNumber, "AmountIncludingVAT", NStr("vi = 'Số tiền gồm thuế GTGT';
																											|ru = 'Сумма с НДС';
																											|en = 'Amount including VAT'; fa = 'مبلغ با احتساب مالیات بر ارزش افزوده';
																											|it = 'Importo IVA inclusa';
																											|pl = 'Wartość z VAT';
																											|tr = 'KDV dahil tutar'"), Cancel);
		EndIf;
	EndDo;
EndProcedure

Procedure ReportErrorFillingInAmounts(ErrorTextTemplate, LineNumber, FieldName, FieldTitle, Cancel)
	ErrorText = StrReplace(ErrorTextTemplate, "%ColumnName%", FieldTitle);
	CommonClientServer.MessageToUser(
		ErrorText, ThisObject,
		CommonClientServer.PathToTabularSection("Goods", LineNumber, FieldName), , Cancel);
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames =
	"Organization, BusinessOperation, Warehouse, VATTaxation, DocumentTransfers_, InventoryOwnerAttributesAreSpecifiedManually,
	|Partner, CompanyRecipient,
	|SubjectToExcise, BusinessUnitProduction,
	|Counterparty";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function ParametersForFillingInventoryTypes(CompanyFieldName1)
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.CompanyFieldName1 = CompanyFieldName1;
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	
	If CompanyFieldName1 = "Organization" Then
		FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
		
		If BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn Then
			
			FillParameters.SelectTypesOfStocksForIntercampany = False;
			FillParameters.SelectionOfStockTypes_.InventoryType = Enums.InventoryTypes.ConsignedGoods;
			FillParameters.SelectionOfStockTypes_.Organization = Organization;
			FillParameters.SelectionOfStockTypes_.GoodsOwner = CompanyRecipient;
			If ValueIsFilled(Contract) Then
				FillParameters.SelectionOfStockTypes_.Contract = Contract;
			Else
				FillParameters.SelectionOfStockTypes_.Contract = New Array;
				FillParameters.SelectionOfStockTypes_.Contract.Add(Undefined);
				FillParameters.SelectionOfStockTypes_.Contract.Add(Catalogs.IntercompanyContracts.EmptyRef());
			EndIf;
			FillParameters.SelectionOfStockTypes_.Currency = Currency;
			
		Else
			FillParameters.SelectionOfStockTypes_.InventoryType = Enums.InventoryTypes.OwnGoods;
			FillParameters.SelectionOfStockTypes_.VATTaxation = VATTaxation;
			
			VATAccountingERP.ParametersForFillingTypesOfStocksForTaxation(FillParameters.SelectionOfStockTypes_,
																		Organization,
																		Date,
																		VATTaxation);
			VATAccountingERP.SetParametersForFillingInventoryTypesForCommissionSales(FillParameters);
		EndIf;
	Else
		FillParameters.SelectTypesOfStocksForIntercampany = True;
		FillParameters.WhenSelectingByIntercampanyExcludeOrganizations = CompanyRecipient;
		If Documents.IntercompanyGoodsReturn.ExcisableGoodsAreUsed(ThisObject) Then
			FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
		EndIf;
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Checks changes in the Items table.
//
// Parameters:
//	TempTablesManager - TempTablesManager - manager of temporary document tables.
//
// Returns:
//	Boolean - indicates whether there have been changes in the Items table.
//
Function CheckChangesInGoodsByQuantityAndAmount(TempTablesManager) Export
	
	Query = New Query(
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.DocumentTransfers_ AS DocumentTransfers_,
	|	TableOfGoods.CostDefiningMethod AS CostDefiningMethod
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate AS VATRate,
	|		TableOfGoods.CCDNumber AS CCDNumber,
	|		TableOfGoods.DocumentTransfers_ AS DocumentTransfers_,
	|		TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|		FALSE AS ItIsNecessaryToFillInShipmentAnalysis,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.CommissionAmount AS CommissionAmount,
	|		TableOfGoods.AmountVATRemuneration AS AmountVATRemuneration
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate,
	|		TableTypesOfStocks_.CCDNumber,
	|		TableTypesOfStocks_.DocumentTransfers_,
	|		TableTypesOfStocks_.CostDefiningMethod,
	|		TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromTransferDocument)
	|			AND TableTypesOfStocks_.ItemsLocationAttributesShipment = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef),
	|		-TableTypesOfStocks_.Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount,
	|		-TableTypesOfStocks_.CommissionAmount,
	|		-TableTypesOfStocks_.AmountVATRemuneration
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.CCDNumber,
	|	TableOfGoods.DocumentTransfers_,
	|	TableOfGoods.CostDefiningMethod
	|
	|HAVING
	|	(SUM(TableOfGoods.Count) <> 0
	|		OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|		OR SUM(TableOfGoods.VATAmount) <> 0
	|		OR SUM(TableOfGoods.CommissionAmount) <> 0
	|		OR SUM(TableOfGoods.AmountVATRemuneration) <> 0)
	|		OR MAX(TableOfGoods.ItIsNecessaryToFillInShipmentAnalysis)");
	
	Query.TempTablesManager = TempTablesManager;
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure FillInCCDNumbersOnOrders()
	
	ParametersForRecalculatingAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	ActionsWithString = New Structure;
	ActionsWithString.Insert("RecalculateAmount");
	ActionsWithString.Insert("RecalculateVATAmount",	ParametersForRecalculatingAmount);
	ActionsWithString.Insert("RecalculateAmountWithVAT",	ParametersForRecalculatingAmount);
	
	FillParameters = PurchasesServer.ParametersForFillingInCCDNumbersBasedOnCredentials();
	FillParameters.ActionsWithString	= ActionsWithString;
	FillParameters.NameOfOrderField	= "DocumentTransfers_";
	
	QueryOptions = FillParameters.QueryOptions;
	QueryOptions.Ref = Ref;
	
	PurchasesServer.FillInCCDNumbersAccordingToCredentials(Goods, "ByReferences", FillParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
