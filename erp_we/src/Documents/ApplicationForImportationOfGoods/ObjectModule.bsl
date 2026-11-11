#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	If FillingData <> Undefined And FillInDataType <> Type("Structure")
		And Metadata().BasedOn.Contains(FillingData.Metadata()) Then
			
		FillInDocumentOnBasisOf(FillingData, StandardProcessing);
		
	ElsIf FillingData <> Undefined And FillInDataType = Type("Structure")
		And FillingData.Property("DocumentBasis")
		And Metadata().BasedOn.Contains(FillingData.DocumentBasis.Metadata()) Then
		
		FillInDocumentOnBasisOf(FillingData.DocumentBasis, StandardProcessing);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		
		FillInDocumentOnBasisOf(FillingData, StandardProcessing);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ApplicationForImportationOfGoods") Then 
		
 		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ImportApplicationLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	If Not Cancel Then
		ExcisableGoodsAccounting.CreateTaskToRecordAmountOfExciseTax(ThisObject);
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods");
	
	If GetFunctionalOption("LocalizationRFService") Then
	Else
		DocumentAmount = Goods.Total("VATAmount");
	EndIf;
	
	If WriteMode = DocumentWriteMode.UndoPosting Then
		ManualAdjustmentOfTaxInvoiceRegister = False;
	EndIf;
	
	UseExcisableGoods = ExcisableGoodsAccounting.ImportOfExcisableItemsIsUsed(Organization, Date);
	
	Query = New Query;
	Query.Text = ExcisableGoodsAccounting.QueryTextLineNumbersForClearingExciseTaxAmount();
	Query.SetParameter("Goods", Goods.Unload(, "LineNumber, Products, ExciseTaxAmount"));
	Query.SetParameter("Date", Date);
	Query.SetParameter("Country", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods Or UseExcises);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		TableRow = Goods[Selection.LineNumber - 1];
		TableRow.TaxBaseExcises = 0;
		TableRow.FixedExciseDuty = 0;
		TableRow.AdValoremExciseRate = 0;
		TableRow.ExciseTaxAmount = 0;
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	If Not Cancel Then
		DocumentsArray = New Array;
		DocumentsArray.Add(Ref);
		VATAccountingERP.GenerateTasksBasedOnDocuments(DocumentsArray);
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	PaymentConfirmed               = False;
	DateOfPaymentConfirmation          = Undefined;
	DateOfTaxTransferDocument  = Undefined;
	NumberOfTaxTransferDocument = "";
	DateSent                     = Undefined;
	UseExcises               = False;
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods");
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Kilograms = Catalogs.PackagesAndUnitsOfMeasure.FindByCode("166");
	
	For CurIndex__ = 0 To Goods.Count()-1 Do
		
		UnitOfMeasurementOfHSCode = Common.ObjectAttributeValue(Goods[CurIndex__].FEACNCode, "UnitOfMeasure");
		
		If Not ValueIsFilled(Goods[CurIndex__].QuantityByFEACN) And
			UnitOfMeasurementOfHSCode <> Kilograms Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Số lượng theo hàng hóa xuất nhập khẩu"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'Не заполнена колонка ""Количество по ТН ВЭД"" в строке %LineNumber% списка ""Товары""';
							|en = 'The ""Quantity by FEACN"" column is not filled in line %LineNumber% of the ""Goods"" list'; fa = 'The ""Quantity by FEACN"" column is not filled in line %LineNumber% of the ""Goods"" list';
							|it = 'Non è compilata la colonna ""Quantità in base al Classificatore di merci di Attività Economica Estera"" nella stringa %LineNumber% dell''elenco ""Merci""';
							|pl = 'Nie wypełniono kolumny ""Ilość według nomenklatury towarowej zagranicznej działalności gospodarczej"" w wierszu %LineNumber% listy ""Towary""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""GTİP''e göre Miktar"" sütunu eksiktir'");
			ErrorText =  StrReplace(ErrorText, "%LineNumber%", Goods[CurIndex__].LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", Goods[CurIndex__].LineNumber, "QuantityByFEACN"),
				,
				Cancel);
			
		EndIf;
		
		ErrorTextTemplateProduct = NStr("vi = 'Chưa điền cột ""Hàng hóa"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
										|ru = 'Не заполнена колонка ""Товар"" в строке %LineNumber% списка ""Товары""';
										|en = 'The ""Goods"" column in line %LineNumber% of the ""Goods"" list is not filled'; fa = 'The ""Goods"" column in line %LineNumber% of the ""Goods"" list is not filled';
										|it = 'Non è compilata la colonna ""Merci"" nella stringa %LineNumber% dell''elenco ""Merci""';
										|pl = 'Nie wypełniono kolumny ""Towar"" w wierszu %LineNumber% listy ""Towary""';
										|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Ürünler"" sütunu eksik'");
		
		If Not ValueIsFilled(Goods[CurIndex__].Products)
			And Not ValueIsFilled(Goods[CurIndex__].Content) Then
				
			ErrorText =  StrReplace(ErrorTextTemplateProduct, "%LineNumber%", Goods[CurIndex__].LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", Goods[CurIndex__].LineNumber, "OwnGoods"),
				,
				Cancel);	
				
		EndIf;
		
	EndDo;
	
	UseExcisableGoods = ExcisableGoodsAccounting.ImportOfExcisableItemsIsUsed(Organization, Date);
	
	If Not UseExcises And Not UseExcisableGoods Then
		
		ControlParameters = ExcisableGoodsAccounting.ControlParametersForFillingExcisableItems();
		
		ControlParameters.ErrorTextTemplate = NStr("vi = 'Đối với doanh nghiệp ""%Organization%"" đã cấm nhập hàng hóa chịu thuế ""%Products%"" được chỉ định trong dòng %LineNumber% của danh sách ""%TabularSectionPresentation%""';
													|ru = 'Для организации ""%Organization%"" запрещен ввоз подакцизного товара ""%Products%"", указанного в строке %LineNumber% списка ""%TabularSectionPresentation%""';
													|en = 'For the ""%Organization%""company, import of the ""%Products%"" excisable goods specified in the %LineNumber% line of the ""%TabularSectionPresentation%"" list is prohibited'; fa = 'For the ""%Organization%""company, import of the ""%Products%"" excisable goods specified in the %LineNumber% line of the ""%TabularSectionPresentation%"" list is prohibited';
													|it = 'For the ""%Organization%""company, import of the ""%Products%"" excisable goods specified in the %LineNumber% line of the ""%TabularSectionPresentation%"" list is prohibited';
													|pl = 'For the ""%Organization%""company, import of the ""%Products%"" excisable goods specified in the %LineNumber% line of the ""%TabularSectionPresentation%"" list is prohibited';
													|tr = '""%Organization%"" iş yeri için ""%TabularSectionPresentation%"" listesinin %LineNumber% satırında belirtilen, tüketim vergisine tabi ""%Products%"" numaralı ürününün ithalatı yasaktır'");
		ControlParameters.NameOfFieldWithError = "OwnGoods";
		
		ExcisableGoodsAccounting.ControlOfFillingExcisableItems(ThisObject, ControlParameters, Cancel);
		
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);

	For Each String In CachedValues.ProcessedRows Do
		String.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
			String.VATTaxBase,
			VATAccountingERPClientServer.ValueOfVATRate(String.VATRate),
			False);
	EndDo;
	
EndProcedure

Procedure FillInDocumentOnBasisOf(Basis, StandardProcessing)
	
	If TypeOf(Basis) = Type("DocumentRef.VendorInvoice") Then
		
		DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "BusinessOperation");
		
		If Not (DetailsOfFoundation.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
					Or DetailsOfFoundation.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
					Or DetailsOfFoundation.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
					Or DetailsOfFoundation.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal) Then
			Error = NStr("vi = 'Nhập giấy đề nghị nhập hàng từ liên minh kinh tế Á-Âu dựa trên việc tiếp nhận với giao dịch %Operation% không cần thiết.';
						|ru = 'Ввод заявления на ввоз товаров из ЕАЭС на основании поступления с операцией %Operation% не требуется.';
						|en = 'Entering of the application for goods import from EAEU countries on the basis of receipt with operation %Operation% is not required.'; fa = 'Entering of the application for goods import from EAEU countries on the basis of receipt with operation %Operation% is not required.';
						|it = 'Non è richiesto l''inserimento della dichiarazione di importazione merci dall''UEE in base alla ricezione con operazione %Operation%.';
						|pl = 'Wprowadzenie oświadczenia o imporcie towarów z EUG na podstawie przyjęcia z operacją %Operation% nie jest wymagane.';
						|tr = 'AEB''den mal ithalatı için %Operation% işlemli bir makbuz temelinde başvuru yapılmasına gerek yoktur.'");
			Raise StrReplace(Error, "%Operation%", DetailsOfFoundation.BusinessOperation);
		EndIf;
		
		TheseAreServicesOfProcessor = (Common.ObjectAttributeValue(Basis, "Contract.ContractType") = Enums.ContractTypes.SubcontractingToTheEAEUCountries);
		If TheseAreServicesOfProcessor Then 
			FillInDocumentBasedOnPurchaseOfProcessorServices(Basis);
		Else
			FillInDocumentBasedOnPurchaseOfGoodsServices(Basis);
		EndIf;
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.SubcontractorReport2_5") Then
		
		DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "BusinessOperation, ProcessingServices");
		
		If DetailsOfFoundation.BusinessOperation <> Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5 Then
			Error = NStr("vi = 'Nhập giấy đề nghị nhập hàng từ liên minh kinh tế Á-Âu dựa trên việc tiếp nhận với giao dịch %Operation% không cần thiết.';
						|ru = 'Ввод заявления на ввоз товаров из ЕАЭС на основании отчета переработчика с операцией %Operation% не требуется.';
						|en = 'Do not enter the application for goods import from the EAEU based on the received subcontracting services notification with the %Operation% transaction.'; fa = 'Do not enter the application for goods import from the EAEU based on the received subcontracting services notification with the %Operation% transaction.';
						|it = 'Non è richiesto l''inserimento della dichiarazione di importazione merci dall''UEE in base al report del gestore con operazione %Operation%.';
						|pl = 'Wprowadzenie oświadczenia o imporcie towarów z EUG na podstawie raportu przetwórcy z operacją %Operation% nie jest wymagane.';
						|tr = 'Fason üreticinin %Operation% işlemli raporuna dayanarak AEB''den mal ithalatı için bir beyan girilmesine gerek yoktur.'");
			Raise StrReplace(Error, "%Operation%", DetailsOfFoundation.BusinessOperation);
		EndIf;
		
		If DetailsOfFoundation.ProcessingServices <> Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder Then
			Error = NStr("vi = 'Nhập giấy đề nghị nhập hàng từ liên minh kinh tế Á-Âu dựa trên bảng kê dành cho người nhận gia công mà không có dịch vụ gia công là không cần thiết.';
						|ru = 'Ввод заявления на ввоз товаров из ЕАЭС на основании отчета переработчика без услуг переработки не требуется.';
						|en = 'Do not enter the application for goods import from the EAEU based on the received subcontracting services notification without subcontracting services.'; fa = 'Do not enter the application for goods import from the EAEU based on the received subcontracting services notification without subcontracting services.';
						|it = 'Non è richiesto l''inserimento della dichiarazione di importazione merci dall''UEE in base al report del gestore senza servizi di elaborazione.';
						|pl = 'Wprowadzenie oświadczenia o imporcie towarów z EUG na podstawie raportu przetwórcy z bez usług przetwarzania nie jest wymagane.';
						|tr = 'Fason üretici hizmetleri olmaksızın bir fason raporuna dayanarak AEB''den mal ithalatı için başvuruda bulunmaya gerek yoktur.'");
			Raise StrReplace(Error, "%Operation%", DetailsOfFoundation.BusinessOperation);
		EndIf;
		
		FillInDocumentBasedOnReportOfProcessor2_5(Basis);
		
	ElsIf TypeOf(Basis) = Type("CatalogRef.LeaseContract") Then
		
		DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "ContractType, RegisterImportApplications");
		
		If Not (DetailsOfFoundation.ContractType = Enums.TypesOfLeaseContracts.Leasing
				And DetailsOfFoundation.RegisterImportApplications) Then
			Error = NStr("vi = 'Nhập giấy đề nghị nhập hàng từ liên minh kinh tế Á-Âu dựa trên hợp đồng %Contract% không cần thiết.';
						|ru = 'Ввод заявления на ввоз товаров из ЕАЭС на основании договора %Contract% не требуется.';
						|en = 'Do not enter the application for goods import from the EAEU based on the %Contract% contract.'; fa = 'Do not enter the application for goods import from the EAEU based on the %Contract% contract.';
						|it = 'Non è richiesto l''inserimento della dichiarazione di importazione merci dall''UEE in base al contratto %Contract%.';
						|pl = 'Wprowadzenie oświadczenia o imporcie towarów z EUG na podstawie umowy %Contract% nie jest wymagane.';
						|tr = '%Contract% sözleşmesi kapsamında AEB''den mal ithalatı için bir başvuru yapılması gerekli değildir.'");
			Raise StrReplace(Error, "%Contract%", Basis);
		EndIf;
		
		FillInDocumentBasedOnLeaseContract(Basis);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		
		DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "Counterparty");
		
		If ValueIsFilled(DetailsOfFoundation.Counterparty) Then
			
			CounterpartyDetailsValues = Common.ObjectAttributesValues(DetailsOfFoundation.Counterparty, "LegalEntityIndividual,RegistrationCountry.EEUMember");
			If Not (CounterpartyDetailsValues.LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.LegalEntityNonResident")
				And ValueIsFilled(CounterpartyDetailsValues.CountryOfRegistrationMemberOfEEU)
				And CounterpartyDetailsValues.CountryOfRegistrationMemberOfEEU) Then
					
				Error = NStr("vi = 'Nhập giấy đề nghị nhập hàng từ liên minh kinh tế Á-Âu đối với đối tác %Counterparty% không cần thiết';
							|ru = 'Ввод заявления на ввоз товаров из ЕАЭС для контрагента %Counterparty% не требуется';
							|en = 'Do not enter the application for goods import from the EAEU for the %Counterparty% counterparty'; fa = 'Do not enter the application for goods import from the EAEU for the %Counterparty% counterparty';
							|it = 'Non è richiesto l''inserimento della dichiarazione di importazione merci dall''UEE per la controparte %Counterparty%';
							|pl = 'Wprowadzenie oświadczenia o imporcie towarów z EUG dla kontrahenta %Counterparty% nie jest wymagane.';
							|tr = '%Counterparty% isimli cari hesabın AEB''den mal ithalatı için başvuruda bulunmasına gerek yoktur'");
				Raise StrReplace(Error, "%Counterparty%", DetailsOfFoundation.Counterparty);
					
			EndIf;
	
			FillInDocumentBasedOnPurchaseOfServices(Basis);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentBasedOnPurchaseOfGoodsServices(Val VendorInvoice)
	
	Query = New Query(
	"SELECT
	|	VendorInvoice.Posted AS Posted,
	|	VendorInvoice.Date AS Date,
	|	VendorInvoice.Organization AS Organization,
	|	VendorInvoice.Counterparty AS Counterparty,
	|	VendorInvoice.Contract AS Contract,
	|	VendorInvoice.Contract.Number AS ContractNumber,
	|	VendorInvoice.Contract.Date AS ContractDate_,
	|	VendorInvoice.Currency AS Currency,
	|	VendorInvoice.BusinessOperation AS BusinessOperation,
	|	VendorInvoice.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	VendorInvoice.IncomingDocumentDate AS IncomingDocumentDate
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|WHERE
	|	VendorInvoice.Ref = &VendorInvoice");
	Query.SetParameter("VendorInvoice", VendorInvoice);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		VendorInvoice,
		,
		Not Attributes.Posted);
		
	// Filling in the header
	FillPropertyValues(ThisObject, Attributes, "Organization, Counterparty, Contract, ContractNumber, ContractDate_, Currency");
	
	EmployeeResponsible = Users.CurrentUser();
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	// Filling in the tabular part.
	GoodsTable = Documents.ApplicationForImportationOfGoods.TableOfBalancesOfGoodsForProcessingApplicationsForImportOfGoods(VendorInvoice, True);
	
	Goods.Load(GoodsTable);
	
EndProcedure

Procedure FillInDocumentBasedOnPurchaseOfProcessorServices(Val PurchaseOfProcessorServices)
	
	Query = New Query(
	"SELECT
	|	VendorInvoice.Posted AS Posted,
	|	VendorInvoice.Organization AS Organization,
	|	VendorInvoice.Counterparty AS Counterparty,
	|	VendorInvoice.Contract AS Contract,
	|	VendorInvoice.Contract.Number AS ContractNumber,
	|	VendorInvoice.Contract.Date AS ContractDate_,
	|	VendorInvoice.Currency AS Currency,
	|	VendorInvoice.BusinessOperation AS BusinessOperation,
	|	VendorInvoice.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	VendorInvoice.IncomingDocumentDate AS IncomingDocumentDate
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|WHERE
	|	VendorInvoice.Ref = &VendorInvoice");
	Query.SetParameter("VendorInvoice", PurchaseOfProcessorServices);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		PurchaseOfProcessorServices,
		,
		Not Attributes.Posted);
		
	// Filling in the header
	FillPropertyValues(ThisObject, Attributes, "Organization, Counterparty, Contract, ContractNumber, ContractDate_, Currency");
	
	EmployeeResponsible = Users.CurrentUser();
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	Query.SetParameter("AccountingRecordDate", Common.ObjectAttributeValue(PurchaseOfProcessorServices, "Date"));
	Query.SetParameter("USDollar", Catalogs.Currencies.FindByCode("840"));
	Query.SetParameter("TransportKind", Documents.ApplicationForImportationOfGoods.DetermineTypeOfTransportBasedOnStatistics(PurchaseOfProcessorServices));
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
	
	Query.Text = "SELECT
	|	PurchaseOfServicesGoods.Ref                   AS DocumentInflow,
	|	""""							                 AS Content,
	|	CASE           
	|		WHEN PurchaseOfServicesGoods.Count = 0
	|			THEN 1
	|		WHEN PurchaseOfServicesGoods.Price = 0
	|			THEN 0
	|		ELSE
	|			PurchaseOfServicesGoods.Sum / PurchaseOfServicesGoods.Price
	|	END                            AS Count,
	|	PurchaseOfServicesGoods.Sum                     AS TaxInvoicedPrice,
	|	0				                				  AS VATTaxBase,
	|	PurchaseOfServicesGoods.VATRate                 AS VATRate, 
	|	0					                              AS StatValueUSDollars,
	|	0 AS NetWeightKg,
	|	CASE           
	|		WHEN PurchaseOfServicesGoods.Count = 0
	|			THEN 1
	|		WHEN PurchaseOfServicesGoods.Price = 0
	|			THEN 0
	|		ELSE
	|			PurchaseOfServicesGoods.Sum / PurchaseOfServicesGoods.Price
	|	END                            AS QuantityByFEACN,
	|	0				                 AS TaxBaseExcises,
	|	ISNULL(CCDNumbers.OriginCountry, Operation.Counterparty.RegistrationCountry) AS OriginCountry,
	|	ISNULL(CCDNumbers.Ref, VALUE(Catalog.CCDNumbers.EmptyRef))        AS CDNumber,
	|	Operation.Currency                  AS Currency,
	|	Operation.IncomingDocumentNumber AS SupportingDocumentSeriesNumber,
	|	Operation.IncomingDocumentDate  AS SupportingDocumentDate,
	|	Operation.Contract                 AS Contract,
	|	Operation.PurchaseForActivity  AS PurchaseForActivity,
	|	UNDEFINED                     AS PartnerProducts,
	|	UNDEFINED                     AS ItemsLocationAttributes,
	|	UNDEFINED                     AS InventoryOwnerAttribute,
	|	PurchaseOfServicesGoods.RowID      AS RowID,
	|	&AccountingRecordDate AS AccountingRecordDate,
	|	&TransportKind      AS TransportKind
	|FROM
	|	Document.VendorInvoice.Goods AS PurchaseOfServicesGoods
	|
	|		INNER JOIN Document.VendorInvoice AS Operation
	|		ON PurchaseOfServicesGoods.Ref = Operation.Ref
	|
	|		INNER JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS Amounts
	|		ON Operation.Ref = Amounts.Recorder
	|			AND PurchaseOfServicesGoods.RowID = Amounts.RowID
	|
	|		LEFT JOIN Catalog.CCDNumbers AS CCDNumbers
	|		ON PurchaseOfServicesGoods.CCDNumber = CCDNumbers.Ref
	|
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&AccountingRecordDate, Currency = &USDollar AND BaseCurrency = &BaseCurrency) AS CurrencyExchangeRateUSDollar
	|		ON (TRUE)
	|WHERE
	|	Operation.Ref = &VendorInvoice";
	
	Goods.Load(Query.Execute().Unload());
	
	USDollar = Catalogs.Currencies.FindByCode("840"); 
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	For Each RowOfProductsTable In Goods Do
		
		// We will calculate the tax base in rubles based on the invoice value as of the date of registration.
		If Currency <> LocalAccountingCurrency Then
			RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(Currency, RowOfProductsTable.AccountingRecordDate);
			If RateStructure.CourseDenominator = 0 Then
				RateStructure.CourseNumerator = 1;
				RateStructure.CourseDenominator = 1;
			EndIf;
			RowOfProductsTable.VATTaxBase = RowOfProductsTable.TaxInvoicedPrice * (RateStructure.CourseNumerator/RateStructure.CourseDenominator);
		Else
			RowOfProductsTable.VATTaxBase = RowOfProductsTable.TaxInvoicedPrice;
		EndIf;
		
		// We will calculate the amount of VAT according to the tax base and the rate
		If RowOfProductsTable.VATTaxBase <> 0 Then
			RowOfProductsTable.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
				RowOfProductsTable.VATTaxBase,
				VATAccountingERPClientServer.ValueOfVATRate(RowOfProductsTable.VATRate),
				False);
		EndIf;
		
		// We will calculate the statistical value in dollars from the tax base in rubles on the date of registration.
		If USDollar <> Catalogs.Currencies.EmptyRef() Then
			RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(USDollar, RowOfProductsTable.AccountingRecordDate, LocalAccountingCurrency);
			RowOfProductsTable.StatValueUSDollars = RowOfProductsTable.VATTaxBase * (RateStructure.CourseDenominator/RateStructure.CourseNumerator);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInDocumentBasedOnReportOfProcessor2_5(Val SubcontractorReport)
	
	Query = New Query(
	"SELECT
	|	SubcontractorReport2_5.Posted AS Posted,
	|	SubcontractorReport2_5.Organization AS Organization,
	|	SubcontractorReport2_5.Counterparty AS Counterparty,
	|	SubcontractorReport2_5.Contract AS Contract,
	|	SubcontractorReport2_5.Contract.Number AS ContractNumber,
	|	SubcontractorReport2_5.Contract.Date AS ContractDate_,
	|	SubcontractorReport2_5.Currency AS Currency,
	|	SubcontractorReport2_5.BusinessOperation AS BusinessOperation,
	|	SubcontractorReport2_5.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	SubcontractorReport2_5.IncomingDocumentDate AS IncomingDocumentDate
	|FROM
	|	Document.SubcontractorReport2_5 AS SubcontractorReport2_5
	|WHERE
	|	SubcontractorReport2_5.Ref = &SubcontractorReport");
	Query.SetParameter("SubcontractorReport", SubcontractorReport);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		SubcontractorReport,
		,
		Not Attributes.Posted);
		
	// Filling in the header
	FillPropertyValues(ThisObject, Attributes, "Organization, Counterparty, Contract, ContractNumber, ContractDate_, Currency");
	
	EmployeeResponsible = Users.CurrentUser();
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	// Filling in the tabular part.
	GoodsTable = Documents.ApplicationForImportationOfGoods.TableOfBalancesOfGoodsForProcessingApplicationsForImportOfGoods(SubcontractorReport, True);
	
	Goods.Load(GoodsTable);
	
	For Each LineOfATabularSection In Goods Do
		
		If Not UseExcises Then
			LineOfATabularSection.TaxBaseExcises = 0;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInDocumentBasedOnLeaseContract(Val LeaseContracts)
	
	DocumentOfConclusionOfContractOfLease = Catalogs.LeaseContract.DocumentOfConclusionOfContractOfLease(LeaseContracts);
	If Not ValueIsFilled(DocumentOfConclusionOfContractOfLease) Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	SigningOfLeaseContract.Posted AS Posted,
	|	SigningOfLeaseContract.Organization AS Organization,
	|	SigningOfLeaseContract.Counterparty AS Counterparty,
	|	SigningOfLeaseContract.Contract AS Contract,
	|	SigningOfLeaseContract.Contract.Number AS ContractNumber,
	|	SigningOfLeaseContract.Contract.Date AS ContractDate_,
	|	SigningOfLeaseContract.Currency AS Currency,
	|	SigningOfLeaseContract.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	SigningOfLeaseContract.IncomingDocumentDate AS IncomingDocumentDate
	|FROM
	|	Document.SigningOfLeaseContract AS SigningOfLeaseContract
	|WHERE
	|	SigningOfLeaseContract.Ref = &DocumentOfConclusionOfContractOfLease");
	Query.SetParameter("DocumentOfConclusionOfContractOfLease", DocumentOfConclusionOfContractOfLease);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		DocumentOfConclusionOfContractOfLease,
		,
		Not Attributes.Posted);
		
	// Filling in the header
	FillPropertyValues(ThisObject, Attributes, "Organization, Counterparty, Contract, ContractNumber, ContractDate_, Currency");
	
	EmployeeResponsible = Users.CurrentUser();
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	// Filling in the tabular part.
	GoodsTable = Documents.ApplicationForImportationOfGoods.TableOfBalancesOfGoodsForProcessingApplicationsForImportOfGoods(DocumentOfConclusionOfContractOfLease, True, EndOfDay(CurrentSessionDate()));
	
	Goods.Load(GoodsTable);
	
	For Each LineOfATabularSection In Goods Do
		
		If Not UseExcises Then
			LineOfATabularSection.TaxBaseExcises = 0;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInDocumentBasedOnPurchaseOfServices(Val PurchaseOfServices)
	
	Query = New Query(
	"SELECT
	|	PurchaseOfServices.Posted AS Posted,
	|	PurchaseOfServices.Organization AS Organization,
	|	PurchaseOfServices.Counterparty AS Counterparty,
	|	PurchaseOfServices.Contract AS Contract,
	|	PurchaseOfServices.Contract.Number AS ContractNumber,
	|	PurchaseOfServices.Contract.Date AS ContractDate_,
	|	PurchaseOfServices.Currency AS Currency,
	|	PurchaseOfServices.BusinessOperation AS BusinessOperation,
	|	PurchaseOfServices.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	PurchaseOfServices.IncomingDocumentDate AS IncomingDocumentDate
	|FROM
	|	Document.VendorInvoiceServicesAndAssets AS PurchaseOfServices
	|WHERE
	|	PurchaseOfServices.Ref = &PurchaseOfServices");
	Query.SetParameter("PurchaseOfServices", PurchaseOfServices);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		PurchaseOfServices,
		,
		Not Attributes.Posted);
		
	// Filling in the header
	FillPropertyValues(ThisObject, Attributes, "Organization, Counterparty, Contract, ContractNumber, ContractDate_, Currency");
	
	EmployeeResponsible = Users.CurrentUser();
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	Query.SetParameter("DocumentInflow", PurchaseOfServices);
	Query.SetParameter("AccountingRecordDate", Common.ObjectAttributeValue(PurchaseOfServices, "Date"));
	Query.SetParameter("USDollar", Catalogs.Currencies.FindByCode("840"));
	Query.SetParameter("TransportKind", Documents.ApplicationForImportationOfGoods.DetermineTypeOfTransportBasedOnStatistics(PurchaseOfServices));
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
	
	Query.Text = "SELECT
	|	PurchaseOfServicesExpenses.Ref                   AS DocumentInflow,
	|	PurchaseOfServicesExpenses.Content               AS Content,
	|	PurchaseOfServicesExpenses.FEACNCode                 AS FEACNCode,
	|	CASE           
	|		WHEN PurchaseOfServicesExpenses.Count = 0
	|			THEN 1
	|		WHEN PurchaseOfServicesExpenses.Price = 0
	|			THEN 0
	|		ELSE
	|			PurchaseOfServicesExpenses.Sum / PurchaseOfServicesExpenses.Price
	|	END                            AS Count,
	|	PurchaseOfServicesExpenses.Sum                    AS TaxInvoicedPrice,
	|	0												  AS VATTaxBase,
	|	PurchaseOfServicesExpenses.VATRate                AS VATRate,
	|	0					                              AS StatValueUSDollars,
	|	0 AS NetWeightKg,
	|	CASE           
	|		WHEN PurchaseOfServicesExpenses.Count = 0
	|			THEN 1
	|		WHEN PurchaseOfServicesExpenses.Price = 0
	|			THEN 0
	|		ELSE
	|			PurchaseOfServicesExpenses.Sum / PurchaseOfServicesExpenses.Price
	|	END                            AS QuantityByFEACN,
	|	0				                 AS TaxBaseExcises,
	|	ISNULL(CCDNumbers.OriginCountry, Operation.Counterparty.RegistrationCountry) AS OriginCountry,
	|	ISNULL(CCDNumbers.Ref, VALUE(Catalog.CCDNumbers.EmptyRef))        AS CDNumber,
	|	Operation.Currency                  AS Currency,
	|	Operation.IncomingDocumentNumber AS SupportingDocumentSeriesNumber,
	|	Operation.IncomingDocumentDate  AS SupportingDocumentDate,
	|	Operation.Contract                 AS Contract,
	|	Operation.PurchaseForActivity  AS PurchaseForActivity,
	|	UNDEFINED                     AS PartnerProducts,
	|	UNDEFINED                     AS ItemsLocationAttributes,
	|	UNDEFINED                     AS InventoryOwnerAttribute,
	|	PurchaseOfServicesExpenses.RowID      AS RowID,
	|	&AccountingRecordDate AS AccountingRecordDate,
	|	&TransportKind      AS TransportKind
	|FROM
	|	Document.VendorInvoiceServicesAndAssets.Expenses AS PurchaseOfServicesExpenses
	|
	|		INNER JOIN Document.VendorInvoiceServicesAndAssets AS Operation
	|		ON PurchaseOfServicesExpenses.Ref = Operation.Ref
	|
	|		INNER JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS Amounts
	|		ON Operation.Ref = Amounts.Recorder
	|			AND PurchaseOfServicesExpenses.RowID = Amounts.RowID
	|
	|		LEFT JOIN Catalog.CCDNumbers AS CCDNumbers
	|		ON PurchaseOfServicesExpenses.CCDNumber = CCDNumbers.Ref
	|
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&AccountingRecordDate, Currency = &USDollar AND BaseCurrency = &BaseCurrency) AS CurrencyExchangeRateUSDollar
	|		ON (TRUE)
	|WHERE
	|	Operation.Ref = &PurchaseOfServices";
	
	Goods.Load(Query.Execute().Unload());
	
	USDollar = Catalogs.Currencies.FindByCode("840");
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	For Each RowOfProductsTable In Goods Do
		
		// We will calculate the tax base in rubles based on the invoice value as of the date of registration.
		If Currency <> LocalAccountingCurrency Then
			RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(Currency, RowOfProductsTable.AccountingRecordDate);
			If RateStructure.CourseDenominator = 0 Then
				RateStructure.CourseNumerator = 1;
				RateStructure.CourseDenominator = 1;
			EndIf;
			RowOfProductsTable.VATTaxBase = RowOfProductsTable.TaxInvoicedPrice * (RateStructure.CourseNumerator/RateStructure.CourseDenominator);
		Else
			RowOfProductsTable.VATTaxBase = RowOfProductsTable.TaxInvoicedPrice;
		EndIf;
		
		// We will calculate the amount of VAT according to the tax base and the rate
		If RowOfProductsTable.VATTaxBase <> 0 Then
			RowOfProductsTable.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
				RowOfProductsTable.VATTaxBase,
				VATAccountingERPClientServer.ValueOfVATRate(RowOfProductsTable.VATRate),
				False);
		EndIf;
		
		// We will calculate the statistical value in dollars from the tax base in rubles on the date of registration.
		If USDollar <> Catalogs.Currencies.EmptyRef() Then
			RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(USDollar, RowOfProductsTable.AccountingRecordDate, LocalAccountingCurrency);
			RowOfProductsTable.StatValueUSDollars = RowOfProductsTable.VATTaxBase * (RateStructure.CourseDenominator/RateStructure.CourseNumerator);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
