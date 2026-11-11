#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.CCDImport - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	
	OperationsGoodsInTransit = New Array();
	OperationsGoodsInTransit.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	OperationsGoodsInTransit.Add(Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit);
	OperationsGoodsInTransit.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	OperationsGoodsInTransit.Add(Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit);
	
	If TypeOf(DocumentObject) = Type("DocumentObject.ReversingEntry") Then
		DocumentSource = DocumentObject.ReversedDocument;
		AttributeName = "Goods.BusinessOperation";
		TableWithOperations = Common.ObjectAttributeValue(DocumentSource, AttributeName);
		BusinessTransactions = TableWithOperations.Unload().UnloadColumn("BusinessOperation");
	Else
		BusinessTransactions = DocumentObject.Goods.UnloadColumn("BusinessOperation");
	EndIf;
	
	BusinessOperationsOfDocument = CommonClientServer.CollapseArray(BusinessTransactions);
	For Each Operation In BusinessOperationsOfDocument Do
		If OperationsGoodsInTransit.Find(Operation) <> Undefined Then
			ParametersForFillingInventoryTypes.UseSeparateProcurement = True;
			Break;
		EndIf;
	EndDo;
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	AttributesNotToCheck = New Array;
	// checking the details of the Object
	If Enums.BusinessTransactions.RegisterCCDUnassisted = RegistrationOption Then
		AttributesNotToCheck.Add("Terms");
	EndIf;
	If Not ValueIsFilled(Terms) Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		AttributesNotToCheck.Add("Contract");
	EndIf;
	If CustomsPenalty > 0 Then
		CheckedAttributes.Add("ExpenseItemPenalty");
	EndIf;
	If CustomsFee > 0 Then
		CheckedAttributes.Add("ExpenseItemFee");
	EndIf;
	
	// Checking the "Counterparty" Attribute
	Template = NStr("vi = 'Chưa điền trường ""%FieldSynonym%""';
					|ru = 'Поле ""%FieldSynonym%"" не заполнено';
					|en = 'The %FieldSynonym% field is required'; fa = 'The %FieldSynonym% field is required';
					|it = 'Поле ""%FieldSynonym%"" не заполнено';
					|pl = 'The %FieldSynonym% field is required';
					|tr = '""%FieldSynonym%"" alanı doldurulmamış'");
	FieldSynonym = ?(RegistrationOption = Enums.BusinessTransactions.RegisterCCDUnassisted, 
		NStr("vi = 'Đối tác hải quan';
			|ru = 'Контрагент таможни';
			|en = 'Customs counterparty'; fa = 'Customs counterparty';
			|it = 'Contraente doganale';
			|pl = 'Kontrahent urzędu celnego';
			|tr = 'Gümrük cari hesabı'"), 
		NStr("vi = 'Đối tác môi giới';
			|ru = 'Контрагент брокера';
			|en = 'Broker counterparty'; fa = 'Broker counterparty';
			|it = 'Contraente  del broker';
			|pl = 'Kontrahent brokera';
			|tr = 'Aracı cari hesabı'")
	);
	
	CheckAndReportError(Not ValueIsFilled(Counterparty), Cancel, Template, "Counterparty", FieldSynonym,,);
	AttributesNotToCheck.Add( "Counterparty" );
	
	// checking the tabparts Sections
	If UseSections Then
		Template = NStr("vi = '""%FieldSynonym%"" trong dòng %LineNumber% của danh sách ""%TabSectionName%"" cần điền.';
						|ru = '""%FieldSynonym%"" в строке %LineNumber% списка ""%TabSectionName%"" необходимо заполнить.';
						|en = 'Fill out ""%FieldSynonym%"" in row %LineNumber% of the ""%TabSectionName%"" list.'; fa = 'Fill out ""%FieldSynonym%"" in row %LineNumber% of the ""%TabSectionName%"" list.';
						|it = '""%FieldSynonym%"" nella riga %LineNumber% dell'' elenco ""%TabSectionName%"" è necessario completare.';
						|pl = '""%FieldSynonym%"" w wierszu %LineNumber% listy ""%TabSectionName%"" należy wypelnić.';
						|tr = '""%TabSectionName%"" listesinin %LineNumber% satırındaki ""%FieldSynonym%"" doldurulmalıdır.'");
		For Each Section In Sections Do
			CheckAndReportError(Section.DutyRate<>0. And Section.DutyAmount=0.,
					Cancel, Template, "DutyAmount", NStr("vi = 'Tiền thuế';
														|ru = 'Сумма пошлины';
														|en = 'Duty amount'; fa = 'مبلغ حقوق گمرکی';
														|it = 'L''importo del dazio';
														|pl = 'Wartość podatku';
														|tr = 'Harç tutarı'"), NStr("vi = 'Phân hệ';
																					|ru = 'Разделы';
																					|en = 'Sections'; fa = 'بخش‌ها';
																					|it = 'Разделы';
																					|pl = 'Sections';
																					|tr = 'Bölümler'"), Section.LineNumber);
			FillInVAT = ValueIsFilled(Section.VATRate)
						And Section.VATRate <> Catalogs.VATRates.EXCLUDINGVAT
						And Common.ObjectAttributeValue(Section.VATRate, "Rate1") > 0;
			CheckAndReportError(FillInVAT And Section.VATAmount=0.,
					Cancel, Template, "VATAmount", NStr("vi = 'Thuế GTGT';
														|ru = 'Сумма НДС';
														|en = 'VAT amount'; fa = 'مبلغ مالیات بر ارزش افزوده';
														|it = 'Importo IVA';
														|pl = 'Wartość VAT';
														|tr = 'KDV tutarı'"), NStr("vi = 'Phân hệ';
																					|ru = 'Разделы';
																					|en = 'Sections'; fa = 'بخش‌ها';
																					|it = 'Разделы';
																					|pl = 'Sections';
																					|tr = 'Bölümler'"), Section.LineNumber);
		EndDo;
	Else
		AttributesNotToCheck.Add("Sections");
		AttributesNotToCheck.Add("Goods.SectionNumber");
	EndIf;
		
	// checks and exceptions depending on the status of the declaration
	If Enums.CustomsDeclarationStatus.CustomsClearance = Status Then
		AttributesNotToCheck.Add("Goods");
		AttributesNotToCheck.Add("Goods.Warehouse");
		AttributesNotToCheck.Add("Goods.SectionNumber");
		AttributesNotToCheck.Add("Goods.CustomsValue");
		AttributesNotToCheck.Add("Goods.DeclarationNoForInvoice");
	ElsIf Enums.CustomsDeclarationStatus.ReleasedFromCustoms = Status Then
		
		// checking the conformity of products and sections
		PartitionCache = New Map;
		For Each Section In Sections Do
			
			Value = NewParameterStructure();
			Value.Section = Section;
			
			PartitionCache.Insert(Section.SectionNumber, Value);
		EndDo;
		For Each OwnGoods In Goods Do
			CacheElement = PartitionCache[OwnGoods.SectionNumber];
			If Undefined <> CacheElement Then
				CacheElement.CustomsValue = CacheElement.CustomsValue + OwnGoods.CustomsValue;
				CacheElement.DutyAmount = CacheElement.DutyAmount + OwnGoods.DutyAmount;
				CacheElement.VATAmount = CacheElement.VATAmount + OwnGoods.VATAmount;
			EndIf;
		EndDo;
		Template = NStr("vi = '""%FieldSynonym%"" trong dòng %LineNumber% của danh sách ""%TabSectionName%"" không tương ứng với tổng số theo mặt hàng trong mục.';
						|ru = '""%FieldSynonym%"" в строке %LineNumber% списка ""%TabSectionName%"" не соответствует итогу по товарам раздела.';
						|en = '""%FieldSynonym%"" in line %LineNumber% of ""%TabSectionName%"" list does not match the total number of goods of the section.'; fa = '""%FieldSynonym%"" in line %LineNumber% of ""%TabSectionName%"" list does not match the total number of goods of the section.';
						|it = '""%FieldSynonym%"" nella riga %LineNumber% dell''elenco ""%TabSectionName%"" il totale dei prodotti della sezione non corrisponde.';
						|pl = '""%FieldSynonym%"" w wierszu %LineNumber% listy ""%TabSectionName%"" nie odpowiada sumie dla towarów sekcji.';
						|tr = '""%TabSectionName%"" listesinin %LineNumber% satırındaki ""%FieldSynonym%"" bölümün mallarının toplamına karşılık gelmemektedir.'");
		For Each CacheElement In PartitionCache Do
			Value = CacheElement.Value; // See NewParameterStructure
			CheckAndReportError(Value.Section.CustomsValue<>Value.CustomsValue,
					Cancel, Template, "CustomsValue", NStr("vi = 'Giá trị trên tờ khai';
															|ru = 'Таможенная стоимость';
															|en = 'Customs value'; fa = 'ارزش گمرکی';
															|it = 'Valore doganale';
															|pl = 'Wartość celna';
															|tr = 'Gümrük değeri'"), NStr("vi = 'Phân hệ';
																						|ru = 'Разделы';
																						|en = 'Sections'; fa = 'بخش‌ها';
																						|it = 'Разделы';
																						|pl = 'Sections';
																						|tr = 'Bölümler'"), Value.Section.LineNumber);
			CheckAndReportError(Value.Section.DutyAmount<>Value.DutyAmount,
					Cancel, Template, "DutyAmount", NStr("vi = 'Tiền thuế';
														|ru = 'Сумма пошлины';
														|en = 'Duty amount'; fa = 'مبلغ حقوق گمرکی';
														|it = 'L''importo del dazio';
														|pl = 'Wartość podatku';
														|tr = 'Harç tutarı'"), NStr("vi = 'Phân hệ';
																					|ru = 'Разделы';
																					|en = 'Sections'; fa = 'بخش‌ها';
																					|it = 'Разделы';
																					|pl = 'Sections';
																					|tr = 'Bölümler'"), Value.Section.LineNumber);
			CheckAndReportError(Value.Section.VATAmount<>Value.VATAmount,
					Cancel, Template, "VATAmount", NStr("vi = 'Thuế GTGT';
														|ru = 'Сумма НДС';
														|en = 'VAT amount'; fa = 'مبلغ مالیات بر ارزش افزوده';
														|it = 'Importo IVA';
														|pl = 'Wartość VAT';
														|tr = 'KDV tutarı'"), NStr("vi = 'Phân hệ';
																					|ru = 'Разделы';
																					|en = 'Sections'; fa = 'بخش‌ها';
																					|it = 'Разделы';
																					|pl = 'Sections';
																					|tr = 'Bölümler'"), Value.Section.LineNumber);
		EndDo;
	EndIf;
	// additional checks
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, AttributesNotToCheck, Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CCDImport),
												Cancel,
												AttributesNotToCheck);
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	AttributesNotToCheck.Add("Goods.QuantityByGBRN");
	
	ArticleAvailabilityParameters = New Structure("CustomsFee, CustomsPenalty, FillCheckProcessing", CustomsFee, CustomsPenalty, True);
	ItemsAndDimensionsSelectionParameters = Documents.CCDImport.ItemsAndDimensionsSelectionParameters(ArticleAvailabilityParameters);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject, Goods, Date);
	CCDImportLocalization.CheckCorrectnessOfCCDProductSettings(ThisObject, Goods, Date);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	UseExcisableGoods = ExcisableGoodsAccounting.ImportOfExcisableItemsIsUsed(Organization, Date);
	If Not UseExcisableGoods Then
		ControlParameters = ExcisableGoodsAccounting.ControlParametersForFillingExcisableItems();
		ControlParameters.ErrorTextTemplate =
			NStr("vi = 'Đối với doanh nghiệp ""%Organization%"" đã cấm nhập hàng hóa chịu thuế TTĐB ""%Products%"" được chỉ định trong dòng %LineNumber% của danh sách ""%TabularSectionPresentation%""';
				|ru = 'Для организации ""%Organization%"" запрещен импорт подакцизного товара ""%Products%"", указанного в строке %LineNumber% списка ""%TabularSectionPresentation%""';
				|en = 'For the ""%Organization%"" company, importing the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list is prohibited'; fa = 'For the ""%Organization%"" company, importing the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list is prohibited';
				|it = 'For the ""%Organization%"" company, importing the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list is prohibited';
				|pl = 'For the ""%Organization%"" company, importing the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list is prohibited';
				|tr = '""%Organization%"" iş yeri için ""%TabularSectionPresentation%"" listesinin %LineNumber% satırında belirtilen, tüketim vergisine tabi ""%Products%"" numaralı ürününün ithalatı yasaktır'");
		ExcisableGoodsAccounting.ControlOfFillingExcisableItems(ThisObject, ControlParameters, Cancel);
	EndIf;
	
	CCDImportLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	UseExcisableGoods = ExcisableGoodsAccounting.ImportOfExcisableItemsIsUsed(Organization, Date);
	
	Query = New Query;
	Query.Text = ExcisableGoodsAccounting.QueryTextLineNumbersForClearingExciseTaxAmount();
	Query.SetParameter("Goods", Goods.Unload(, "LineNumber, Products, ExciseTaxAmount"));
	Query.SetParameter("Date", Date);
	Query.SetParameter("Country", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		String = Goods[Selection.LineNumber - 1];
		String.ExciseTaxAmount = 0;
		String.VATAmount = PriceManagementSystemClientServer.CalculateVATAmount(
			String.CustomsValue + String.DutyAmount + String.ExciseTaxAmount,
			String.VATRate,
			False);
	EndDo;
	
	// adjustment of the division number
	PartitionCache = New Map;
	For Each Section In Sections Do
		PartitionCache.Insert(Section.SectionNumber, Section);
		Section.ExciseTaxAmount = 0;
	EndDo;
	For Each OwnGoods In Goods Do
		If PartitionCache[OwnGoods.SectionNumber] = Undefined Then
			OwnGoods.SectionNumber = 0;
		Else
			Section = PartitionCache[OwnGoods.SectionNumber];
			Section.ExciseTaxAmount = Section.ExciseTaxAmount + OwnGoods.ExciseTaxAmount;
		EndIf;
		If Not ValueIsFilled(OwnGoods.PurchaseForActivity) Then
			OwnGoods.PurchaseForActivity = Enums.VATTaxationTypes.SaleIsSubjectToVAT;
		EndIf;
		If Not ValueIsFilled(OwnGoods.BusinessOperation) Then
			OwnGoods.BusinessOperation = Enums.BusinessTransactions.PurchaseByImport;
		EndIf;
	EndDo;
	
	If Enums.BusinessTransactions.RegisterCCDUnassisted = RegistrationOption Then
		Terms = Undefined;
	EndIf;
	
	If Not GetFunctionalOption("UseAccountingOfOtherIncomeExpenses") Then
		If Not CustomsFee = 0 Then
			CustomsFee = 0;
		EndIf;
		If Not CustomsPenalty = 0 Then
			CustomsPenalty = 0;
		EndIf;
	EndIf;
	
	ArticleAvailabilityParameters = New Structure("CustomsFee, CustomsPenalty", CustomsFee, CustomsPenalty);
	ItemsAndDimensionsSelectionParameters = Documents.CCDImport.ItemsAndDimensionsSelectionParameters(ArticleAvailabilityParameters);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);

	DocumentAmount = Documents.CCDImport.DocumentAmount(ThisObject);
	
	If WriteMode=DocumentWriteMode.Posting Then
		If (Status = Enums.CustomsDeclarationStatus.ReleasedFromCustoms) Then
			FillInTheWarehouse();
			
			FinalTS = Goods.UnloadColumns();
			
			FilterFields = "BusinessOperation, DocumentInflow";
			DataToFillInAnalytics = Goods.Unload(, FilterFields);
			DataToFillInAnalytics.GroupBy(FilterFields);
			
			For Each ProductGroupFields In DataToFillInAnalytics Do
				
				FilterParameters = New Structure(FilterFields,
					ProductGroupFields.BusinessOperation,
					ProductGroupFields.DocumentInflow);
					
				FoundRows = Goods.FindRows(FilterParameters);
				TableForProcessing = Goods.Unload(FoundRows);
				
				TableForProcessing.Columns.Add("Partner", New TypeDescription("CatalogRef.Partners"));
				TableForProcessing.FillValues(Vendor, "Partner");
				
				SupplierAgreement = Common.ObjectAttributeValue(ProductGroupFields.DocumentInflow, "Contract");
				TableForProcessing.Columns.Add("Contract", New TypeDescription("CatalogRef.CounterpartyContracts"));
				TableForProcessing.FillValues(SupplierAgreement, "Contract");
				
				// The Fill In Collection method uses line numbers as indexes, preparing line numbers.
				For LineNumber = 1 To TableForProcessing.Count() Do
					ProcessedString = TableForProcessing[LineNumber - 1];
					ProcessedString.LineNumber = LineNumber;
				EndDo;
				
				AnalyticsManager = InformationRegisters.ItemsLocationAttributes;
				PlacesOfAccounting = AnalyticsManager.PlacesOfAccounting(RegistrationOption,
					Undefined,
					Department,
					Undefined,
					Undefined);
				
				CalculatingFieldNames = AnalyticsManager.PlacesOfAccounting(ProductGroupFields.BusinessOperation,
					"Warehouse",
					Department,
					"Partner",
					"Contract");
				
				FieldsNames = AnalyticsManager.DefaultCollectionFieldNames();
				FieldsNames.Arbitrary = CalculatingFieldNames.Arbitrary;
				
				AnalyticsManager.FillInCollection(TableForProcessing, PlacesOfAccounting, FieldsNames);
				
				CommonClientServer.SupplementTable(TableForProcessing, FinalTS);
				
			EndDo;
			
			Goods.Load(FinalTS);
			
			TemporaryTable = TemporaryTable();
			InventoriesServer.FillStockTypesByDefault(TemporaryTable, Goods);
			TMCommonUse.FillInDocumentIDs(ThisObject, "Goods");
			If Not ValueIsFilled(RowIDFee) Then
				RowIDFee = String(New UUID);
			EndIf;
			If Not ValueIsFilled(RowIDFine) Then
				RowIDFine = String(New UUID);
			EndIf;		
			
		EndIf;
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		For Each OwnGoods In Goods Do
			OwnGoods.InventoryOwnerAttribute = Undefined;
		EndDo;
	EndIf;
	
	ProductsServer.ClearUnusedSeries(
		ThisObject, ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CCDImport));
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
 	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	CCDImportLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	RowIDFee = "";
	RowIDFine = "";
	For Each TableRow In Goods Do
		TableRow.RowID = "";
	EndDo;
	
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;

	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	For Each String In CachedValues.ProcessedRows Do
		String.VATAmount =
			PriceManagementSystemClientServer.CalculateVATAmount(
				String.CustomsValue + String.DutyAmount + String.ExciseTaxAmount,
				String.VATRate,
				False);
	EndDo;
	
	RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
							ThisObject,
							"Warehouse",
							True);
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	
	CCDImportLocalization.OnCopy(ThisObject, CopiedObject);
	Author = Users.CurrentUser();
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	CCDImportLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	If Not Cancel Then
		ExcisableGoodsAccounting.CreateTaskToRecordAmountOfExciseTax(ThisObject);
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	CCDImportLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	CCDImportLocalization.OnWrite(ThisObject, Cancel);
		
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Query = New Query();
	Attributes = Documents.CCDImport.FillingStructure();
	DataType = TypeOf(FillingData);
	If DataType = Type("DocumentRef.VendorInvoice") Then
		Query.Text = "
		|SELECT
		|	BusinessOperation AS RegistrationOption,
		|	Currency AS CurrencyOfReceipt,
		|	Date AS DateOfReceipt,
		|	PriceIncludesVAT AS PriceIncludesVAT,
		|	Organization AS Organization,
		|	CompanyBankAccount AS CompanyBankAccount,
		|	Partner AS Vendor,
		|	Posted AS Posted,
		|	Counterparty AS VendorSCounterparty,
		|	LineOfBusiness AS LineOfBusiness
		|FROM
		|	Document.VendorInvoice
		|WHERE
		|	Ref = &Ref
		|";
		Query.SetParameter("Ref", FillingData);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			TMCommonUse.CheckPossibilityOfEnteringBasedOn(FillingData, , Not Selection.Posted);
			
			EconomicImportOperations = PurchasesServer.BusinessOperationsOnMain(
				Enums.BusinessTransactions.PurchaseByImport);

			If EconomicImportOperations.Find(Selection.RegistrationOption) = Undefined Then
				Error = NStr("vi = 'Không cần nhập tờ khai hải quan trên cơ sở tiếp nhận với giao dịch %Operation%.';
							|ru = 'Ввод таможенной декларации на основании поступления с операцией %Operation% не требуется.';
							|en = 'It is not required to generate a customs declaration based on the receipt with operation %Operation%.'; fa = 'It is not required to generate a customs declaration based on the receipt with operation %Operation%.';
							|it = 'Non è richiesto l''inserimento di una dichiarazione doganale in base alla ricevuta dell''operazione %Operation%.';
							|pl = 'Wprowadzenie deklaracji celnej na podstawie wpływu z operacja %Operation% nie jest potrzebne.';
							|tr = '%Operation% işlemi ile makbuza dayalı bir gümrük beyannamesi girilmesine gerek yoktur.'");
				Raise StrReplace(Error, "%Operation%", Selection.RegistrationOption);
			EndIf;

			Query.Text = "
			|SELECT
			|	Rows.Products,
			|	Rows.Characteristic,
			|	Rows.Warehouse,
			|	Rows.Purpose,
			|	Rows.InventoryOwnerAttribute,
			|	SUM(Rows.Count) AS Count
			|
			|INTO Import
			|FROM
			|	Document.CCDImport AS Import
			|
			|	INNER JOIN
			|		Document.CCDImport.Goods AS Rows
			|	ON
			|		Rows.Ref = Import.Ref
			|WHERE
			|	Import.Posted
			|	AND Rows.DocumentInflow = &Ref
			|
			|GROUP BY
			|	Rows.Products,
			|	Rows.Characteristic,
			|	Rows.Warehouse,
			|	Rows.Purpose,
			|	Rows.InventoryOwnerAttribute
			|;
			|///////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.Ref.Date AS DocumentDate,
			|	Goods.Products,
			|	Goods.Characteristic,
			|	Goods.Purpose,
			|	Goods.Series,
			|	Goods.Purpose,
			|	Goods.VATRate,
			|	UNDEFINED AS Package,
			|	0 AS Price,
			|	Goods.Count - ISNULL(Import.Count, 0) AS NumberOfPackages,
			|	Goods.Count - ISNULL(Import.Count, 0) AS Count,
			|	Goods.Sum * (Goods.Count - ISNULL(Import.Count, 0)) / Goods.Count AS Sum,
			|	Goods.VATAmount * (Goods.Count - ISNULL(Import.Count, 0)) / Goods.Count AS VATAmount,
			|	Goods.AmountIncludingVAT * (Goods.Count - ISNULL(Import.Count, 0)) / Goods.Count AS AmountIncludingVAT,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Ref AS DocumentInflow,
			|	CASE 
			|		WHEN ISNULL(Goods.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
			|			THEN Goods.Purpose.VATActivityType
			|		ELSE Goods.Ref.PurchaseForActivity
			|	END AS PurchaseForActivity,
			|	Goods.Ref.BusinessOperation AS BusinessOperation,
			|	Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute
			|FROM
			|	Document.VendorInvoice.Goods AS Goods
			|
			|	INNER JOIN
			|		Catalog.Products AS CatProducts_
			|	ON
			|		CatProducts_.Ref = Goods.Products
			|
			|	LEFT JOIN
			|		Import AS Import
			|	ON
			|		Import.Products = Goods.Products
			|		AND Import.Characteristic = Goods.Characteristic
			|		AND Import.Warehouse = Goods.Warehouse
			|		AND Import.Purpose = Goods.Purpose
			|		AND Import.InventoryOwnerAttribute = Goods.InventoryOwnerAttribute
			|WHERE
			|	Goods.Ref = &Ref
			|	AND Goods.Count <> 0.
			|	AND CatProducts_.ItemsType IN
			|		(VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
			|";
			
			FillPropertyValues(Attributes, Selection);
			Attributes.Goods = Query.Execute().Unload();
			Documents.CCDImport.FillInAccordingToData(ThisObject, Attributes);
		EndIf;
		
	ElsIf DataType = Type("Structure") Then
		FillPropertyValues(Attributes, FillingData);
		If FillingData.Property("RequestProducts") Then
			Query.Text = FillingData.RequestProducts;
			For Each Property In FillingData Do
				Query.SetParameter(Property.Key, Property.Value);
			EndDo;
			Attributes.Goods = Query.Execute().Unload();
		ElsIf FillingData.Property("Goods") Then
			Attributes.Goods = FillingData.Goods;
		EndIf;
		Documents.CCDImport.FillInAccordingToData(ThisObject, Attributes);
	Else
		Documents.CCDImport.FillByDefault(ThisObject);
	EndIf;
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	FillOutBankAccounts();
	
	ArticleAvailabilityParameters = New Structure("CustomsFee, CustomsPenalty", CustomsFee, CustomsPenalty);
	ItemsAndDimensionsSelectionParameters = Documents.CCDImport.ItemsAndDimensionsSelectionParameters(ArticleAvailabilityParameters);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	UseSections = GetFunctionalOption("UseSectionsOfCustomsDeclarationImport");
	
	RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
							ThisObject,
							"Warehouse",
							True);
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	
	CCDImportLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

#EndRegion

#Region Private

#Region ProceduresForFillingInAutoSubstitutionValuesTypesOfStocksCCDNumbers

Function TemporaryTable()
	TemporaryTable = New TempTablesManager;
	Query = New Query("
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CAST(Goods.Products AS Catalog.Products) AS Products,
	|	FALSE AS ThisIsReusablePackage,
	|	&Organization AS Organization,
	|	&Terms AS Terms,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Catalog.Currencies.EmptyRef) AS TaxationOfOrganization,
	|	VALUE(Catalog.GroupsOfFinancialAccountingOfCash.EmptyRef) AS FinancialAccountingGroup,
	|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
	|	VALUE(Catalog.TypesOfPrices.EmptyRef) AS PriceKind,
	|	CAST(Goods.InventoryOwnerAttribute AS Catalog.InventoryKinds) AS InventoryOwnerAttribute,
	|	Goods.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN Goods.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|			 VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|			 VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit))
	|			THEN VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|		WHEN Goods.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|			 VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
	|			THEN VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|		WHEN Goods.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.ConsignmentProcurement))
	|			THEN VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END AS InventoryType
	|
	|INTO TableOfGoods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	TableOfGoods.Organization AS Organization,
	|	TableOfGoods.BusinessOperation AS BusinessOperation,
	|	TableOfGoods.InventoryType AS InventoryType,
	|	TableOfGoods.Terms AS Terms,
	|	TableOfGoods.Currency AS Currency,
	|	TableOfGoods.VATTaxation AS VATTaxation,
	|	TableOfGoods.TaxationOfOrganization AS TaxationOfOrganization,
	|	UNDEFINED AS GoodsOwner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryTypeDetails
	|		ON TableOfGoods.InventoryOwnerAttribute = InventoryTypeDetails.Ref
	|WHERE
	|	TableOfGoods.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|	AND (TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|			OR
	|			(TableOfGoods.BusinessOperation IN
	|				(VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|				 VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit)
	|				)
	|			AND TableOfGoods.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.OwnGoodsInTransit))
	|			OR
	|			(TableOfGoods.BusinessOperation IN
	|				(VALUE(Enum.BusinessTransactions.PurchaseByImport)
	|				)
	|			AND TableOfGoods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsInTransit))
	|		)");
	
	Query.TempTablesManager = TemporaryTable;
	Query.SetParameter("Goods", Goods.Unload(, "LineNumber, ItemsLocationAttributes, Products, InventoryOwnerAttribute, BusinessOperation"));
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Terms", Terms);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("Posted", Posted);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	Query.Execute();
	Return TemporaryTable;
EndFunction

#EndRegion

#Region Other

Procedure CheckAndReportError(ErrorCondition, Cancel, Val Template, Val FieldName, Val FieldSynonym, Val TabSectionName = Undefined, Val LineNumber = Undefined)
	If ErrorCondition Then
		Message = StrReplace(Template, "%FieldSynonym%", FieldSynonym);
		Message = StrReplace(Message, "%LineNumber%", LineNumber);
		Message = StrReplace(Message, "%TabSectionName%", TabSectionName);
		If ValueIsFilled(TabSectionName) And LineNumber > 0 Then
			FieldName = CommonClientServer.PathToTabularSection(TabSectionName, LineNumber, FieldName);
		EndIf;
		CommonClientServer.MessageToUser(Message, , FieldName, "Object", Cancel);
	EndIf;
EndProcedure

Procedure FillInTheWarehouse()
	For Each String In Goods Do
		String.Warehouse = SettingsValueCached.GetDefaultWarehouse(String.Warehouse, False, True);
	EndDo;
EndProcedure

// Section parameter constructor function
// 
// Returns:
// 	Structure - LongDesc:
// * VATAmount - Number -
// * DutyAmount - Number -
// * CustomsValue - Number -
// * Section - LineOfATabularSection - 
Function NewParameterStructure()
	
	Result = New Structure;
	Result.Insert("Section");
	Result.Insert("CustomsValue", 0.);
	Result.Insert("DutyAmount", 0.);
	Result.Insert("VATAmount", 0.);
	
	Return Result;
	
EndFunction

Procedure FillOutBankAccounts()
	
	If ValueIsFilled(CompanyBankAccount) And ValueIsFilled(CounterpartyBankAccount) Then
		Return;
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract,
		?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
		?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
	
	If ValueIsFilled(Organization) And Not ValueIsFilled(CompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersOfAccount.LineOfBusiness = LineOfBusiness;
		ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(Counterparty) And Not ValueIsFilled(CounterpartyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
