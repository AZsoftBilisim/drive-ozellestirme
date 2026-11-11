#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf; 
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	RegistrationParameters = Documents.ReceivingLeaseServices.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	If WriteMode <> DocumentWriteMode.Write Then
		PrepareDataForTasksByEndOfMonthBeforeRecording();
	EndIf;
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.ReceivingLeaseServices.AccountingAccountSettings_(Contract));
	
	ItemsAndDimensionsSelectionParameters = Documents.ReceivingLeaseServices.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FillInBankingDetailsBeforeWrite(WriteMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ReceivingLeaseServicesLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	FillParameters = Documents.ReceivingLeaseServices.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	FillParameters = Documents.ReceivingLeaseServices.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	BatchProcessingOfTablePartServer.TreatTS(Accruals, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Accruals,
		CachedValues);
	
	InitializeDocument();
	
	IncomingDocumentDate  = Date(1,1,1);
	IncomingDocumentNumber = "";
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Accruals");
	
	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	FillInDataType = TypeOf(FillingData);

	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData, StandardProcessing);
	ElsIf FillInDataType = Type("CatalogRef.LeaseContract") Then
		FillInBasedOnLeaseAgreement(FillingData);
	EndIf;

	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("Accruals.ARAPDocument");
	
	If VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT  Then
		NotCheckedAttributeArray.Add("Accruals.VATRate");
	EndIf;
	
	ItemDetailsParameters = 
		LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_ReceiptOfRentalServices(ThisObject, AuxiliaryAttributes());
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckCompletionOfTSAccrual(Cancel);
		
	ItemsAndDimensionsSelectionParameters = Documents.ReceivingLeaseServices.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	CheckParameters = Documents.ReceivingLeaseServices.VerificationParametersFillingInDocumentOnVATTaxationPurchases(ThisObject);
	VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation(ThisObject, VATTaxation, CheckParameters, Cancel);
	
	CheckParameters = Documents.ReceivingLeaseServices.ParametersForCheckingDocumentFillingByTypeOfActivity(ThisObject);
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(ThisObject, PurchaseForActivity, CheckParameters, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RegistrationParameters = Documents.ReceivingLeaseServices.ParametersForRegisteringInvoicesReceived(ThisObject); 
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
	// We will perform VAT recovery based on the results of the offset of the security payment
	ChangesTable = VATAccountingERP.NewCalculationChangeTable();
	ChangesRow = ChangesTable.Add();
	ChangesRow.Document = Ref;
	ChangesRow.Period = Date;
	Documents.ReceivedTaxInvoicePrepayment.CreateTasksForGeneratingVATRegisteredRecords(ChangesTable);
	
	CreateTasksForEndOfMonthWhenRecording();
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RegistrationParameters = Documents.ReceivingLeaseServices.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
	// We will perform VAT recovery based on the results of the offset of the security payment
	ChangesTable = VATAccountingERP.NewCalculationChangeTable();
	ChangesRow = ChangesTable.Add();
	ChangesRow.Document = Ref;
	ChangesRow.Period = Date;
	Documents.ReceivedTaxInvoicePrepayment.CreateTasksForGeneratingVATRegisteredRecords(ChangesTable);
	
	CreateTasksForEndOfMonthWhenRecording();
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure FillInSelectionDocument(FillingData, StandardProcessing)
	
	If FillingData.Property("Contract") Then
		FillInBasedOnLeaseAgreement(FillingData.Contract);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnLeaseAgreement(FillingData)
	
	If Not ValueIsFilled(FillingData) Then
		Return;
	EndIf;
	
	ContractDetails_ = Common.ObjectAttributesValues(
		FillingData, "Organization,Partner,Counterparty,ARAPCurrency,DeletionMark,Status,VATTaxation");
	
	If ContractDetails_.DeletionMark Then
		ErrorText = NStr("vi = 'Hợp đồng đã bị đặt dấu xóa, không thể tạo chứng từ';
						|ru = 'Договор помечен на удаление, создание документа недоступно';
						|en = 'The contract is marked for deletion, document creation is not available'; fa = 'The contract is marked for deletion, document creation is not available';
						|it = 'Accordo contrassegnato per la cancellazione, creazione del documento non disponibile';
						|pl = 'Umowa jest zaznaczona do usunięcia, utworzenie dokumentu jest niedostępne';
						|tr = 'Sözleşme silinmek üzere işaretlendi, belgenin oluşturulması mevcut değil'");
		Raise ErrorText
	ElsIf ContractDetails_.Status <> Enums.CounterpartyContractStatuses.Valid Then
		ErrorText = NStr("vi = 'Hợp đồng không có hiệu lực, không thể tạo chứng từ';
						|ru = 'Договор не действует, создание документа недоступно';
						|en = 'The contract is not valid, document creation is not available'; fa = 'The contract is not valid, document creation is not available';
						|it = 'Accordo inattivo, creazione del documento non disponibile';
						|pl = 'Umowa nie jest ważna, utworzenie dokumentu jest niedostępne';
						|tr = 'Sözleşme geçerli değil, belgenin oluşturulması mevcut değil'");
		Raise ErrorText
	EndIf;

	Organization = ContractDetails_.Organization;
	Partner = ContractDetails_.Partner;
	Counterparty = ContractDetails_.Counterparty;
	Contract = FillingData;
	ARAPCurrency = ContractDetails_.ARAPCurrency;
	Currency = ContractDetails_.ARAPCurrency;
	VATTaxation = ContractDetails_.VATTaxation;
	
	DocumentOfConclusionOfContractOfLease = Catalogs.LeaseContract.DocumentOfConclusionOfContractOfLease(FillingData);
	If ValueIsFilled(DocumentOfConclusionOfContractOfLease) Then 
		PurchaseForActivity = Common.ObjectAttributeValue(DocumentOfConclusionOfContractOfLease, "PurchaseForActivity");
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;

	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization); 
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Currency") Then
		If Not ValueIsFilled(Currency) Then
			Currency = LocalAccountingCurrency;
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("ARAPCurrency") Then
		If Not ValueIsFilled(ARAPCurrency) Then
			ARAPCurrency = LocalAccountingCurrency;
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Department") Then
		Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	EndIf;
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization);
	
	FillParameters = Documents.ReceivingLeaseServices.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	FillParameters = Documents.ReceivingLeaseServices.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
	ItemsAndDimensionsSelectionParameters = Documents.ReceivingLeaseServices.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckCompletionOfTSAccrual(Cancel)
	
	// Auxiliary details for checking VAT accounting
	ByItsUse = (PurchaseForActivity = Enums.VATTaxationTypes.ByActualUsage);
	FromDocument = Enums.SeparateVATAccountingOptions.FromDocument;
	ToLinesOfBusiness = Enums.CostAllocationOptions.ToLinesOfBusiness;
	ToCurrentPeriodExpensesDirectly  = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	ToProductionCosts = Enums.CostAllocationOptions.ToProductionCosts;
	BatchAccountingIsEnabled = CalculationOfCostCached.BatchAccountingIsEnabled(BegOfMonth(Date));
	
	AvailableTypesOfCharges = Catalogs.LeaseContract.TypesOfPaymentsUnderAgreement(Contract);
	
	For CurIndex__ = 0 To Accruals.Count()-1 Do
		
		RowData = Accruals[CurIndex__];
		
		// The item of expenditure should not refer to taxation in the procurement document
		// if the organization has included taxation by fact. use.
		If BatchAccountingIsEnabled
			And ByItsUse
			And ValueIsFilled(RowData.ExpenseItem) Then
			
			Attributes = Common.ObjectAttributesValues(
							RowData.ExpenseItem,
							"SeparateVATAccountingOption, CostAllocationOptionLocal");
			
			If (Attributes.CostAllocationOptionLocal = ToLinesOfBusiness
					Or Attributes.CostAllocationOptionLocal = ToCurrentPeriodExpensesDirectly			
					Or Attributes.CostAllocationOptionLocal = ToProductionCosts)
				 And Attributes.SeparateVATAccountingOption = FromDocument Then
				
				ErrorText = NStr("vi = 'Khi sử dụng kế toán thuế GTGT theo thực tế sử dụng, trong dạng chi phí cần chọn kế toán riêng biệt thuế GTGT theo chi phí: ""Thuế GTGT được phân bổ theo dạng thuế tương ứng với doanh thu"" trong dòng %1 của danh sách ""Tính toán""';
								|ru = 'При использовании учета НДС по фактическому использованию, у статьи расходов должен быть выбран раздельный учет НДС по расходам: ""НДС распределяется по видам налогообложения пропорционально выручке"" в строке %1 списка ""Начисления""';
								|en = 'When using VAT accounting by actual usage, separate VAT accounting is to be selected for the expense item: ""VAT is allocated by taxation kinds in proportion to revenue"" in line %1 of the Accruals list'; fa = 'When using VAT accounting by actual usage, separate VAT accounting is to be selected for the expense item: ""VAT is allocated by taxation kinds in proportion to revenue"" in line %1 of the Accruals list';
								|it = 'Quando viene effettuato il calcolo dell''IVA per l''uso effettivo, per la voce di spesa deve essere selezionata il calcolo dell''IVA separato per le spese: ""IVA distribuita per tipi della tassazione in proporzione ai ricavi"" nella riga %1 dell''elenco ""Maturazioni""';
								|pl = 'W przypadku używania ewidencji VAT wg faktycznego wykorzystania, dla pozycji rozchodów należy wybrać oddzielną ewidencję VAT wg rozchodów: ""VAT jest przydzielany wg rodzajów opodatkowania proporcjonalnie do wpływów"" w wierszu %1 listy ""Naliczania""';
								|tr = 'Fiili kullanıma göre KDV muhasebesi kullanılırken, harcama kaleminin seçilen harcama için ayrı bir KDV muhasebesine sahip olması gerekir: ""Tahakkuklar"" listesinin %1 satırında ""KDV, vergilendirme türüne gelirle orantılı olarak tahsis edilir""'");
				CommonClientServer.MessageToUser(
					StrTemplate(ErrorText, RowData.LineNumber),
					ThisObject,
					CommonClientServer.PathToTabularSection("Accruals", RowData.LineNumber, "ExpenseItem"),,
					Cancel);
				
			EndIf;
			
		EndIf;
		
		If AvailableTypesOfCharges.Find(RowData.AccrualType) = Undefined Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không xem xét kiểu tính ""%1"" trong khuôn khổ hợp đồng này';
					|ru = 'Тип начисления ""%1"" не предусмотрен в рамках данного договора';
					|en = 'Accrual type ""%1"" is not available under this contract'; fa = 'Accrual type ""%1"" is not available under this contract';
					|it = 'Tipo di maturazione ""%1"" non previsto ai sensi del presente accordo';
					|pl = 'Typ naliczania ""%1"" nie jest przewidziany w ramach niniejszej umowy';
					|tr = '""%1"" tahakkuk türü bu sözleşme kapsamında öngörülmemiştir'"),
				RowData.AccrualType);
				
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Accruals", RowData.LineNumber, "AccrualType"),,
				Cancel);
				
		EndIf;
		
		If RowData.AccrualType = Enums.TypesOfLeasePayments.DepositPayment 
			And Not ValueIsFilled(RowData.ARAPDocument) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Chứng từ hạch toán"" tại dòng %1 của danh sách ""Tính toán""';
							|ru = 'Не заполнено поле ""Расчетный документ"" в строке %1 списка ""Начисления""';
							|en = '""AR/AP document"" field in line %1 of the ""Accruals"" list is not filled in'; fa = '""AR/AP document"" field in line %1 of the ""Accruals"" list is not filled in';
							|it = 'Campo ""Documento di calcolo"" non completato nella riga %1 dell''elenco ""Maturazioni""';
							|pl = 'Nie wypełniono kolumny ""Dokument rozliczeniowy"" w wierszu %1 listy ""Naliczenia""';
							|tr = '""Tahakkuklar"" listesinin %1 satırındaki ""Mutabakat belgesi"" alanı doldurulmamış'");
			CommonClientServer.MessageToUser(
				StrTemplate(ErrorText, RowData.LineNumber),
				ThisObject,
				CommonClientServer.PathToTabularSection("Accruals", RowData.LineNumber, "ARAPDocument"),,
				Cancel);
			
		EndIf;
	EndDo;

EndProcedure

Procedure PrepareDataForTasksByEndOfMonthBeforeRecording()
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	AdditionalProperties.Insert("TablesData",
		New Structure("TempTablesManager", New TempTablesManager));
	
	QueryText = 
	"SELECT
	|	TableBeforeWrite.Date             AS Date,
	|	TableBeforeWrite.Organization      AS Organization,
	|	TableBeforeWrite.Counterparty       AS Counterparty,
	|	TableBeforeWrite.Contract          AS Contract,
	|	TableBeforeWrite.DocumentAmount   AS DocumentAmount
	|INTO ReceivingLeaseServicesBeforeWrite
	|FROM
	|	Document.ReceivingLeaseServices AS TableBeforeWrite
	|WHERE
	|	TableBeforeWrite.Ref = &Ref
	|	AND TableBeforeWrite.Posted";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TablesData.TempTablesManager;
	Query.SetParameter("Ref", Ref);
	Query.Execute();
	
EndProcedure

Procedure CreateTasksForEndOfMonthWhenRecording()
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	Table.Period           AS Period,
	|	Table.Organization      AS Organization,
	|	Table.FixedAsset AS FixedAsset,
	|	&Ref                  AS Document
	|INTO ReceivingLeaseServicesUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Date              AS Period,
	|		TableBeforeWrite.Organization       AS Organization,
	|		UNDEFINED                          AS FixedAsset
	|	FROM
	|		ReceivingLeaseServicesBeforeWrite AS TableBeforeWrite
	|			LEFT JOIN Document.ReceivingLeaseServices AS TableWhenWriting
	|			ON TableWhenWriting.Ref = &Ref
	|				AND TableWhenWriting.Posted
	|		WHERE
	|			(BEGINOFPERIOD(TableWhenWriting.Date, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.Date, MONTH)
	|				OR TableWhenWriting.Organization <> TableBeforeWrite.Organization
	|				OR TableWhenWriting.Counterparty <> TableBeforeWrite.Counterparty
	|				OR TableWhenWriting.Contract <> TableBeforeWrite.Contract
	|				OR TableWhenWriting.DocumentAmount <> TableBeforeWrite.DocumentAmount
	|				OR TableWhenWriting.Date IS NULL)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Date,
	|		TableWhenWriting.Organization,
	|		UNDEFINED
	|	FROM
	|		Document.ReceivingLeaseServices AS TableWhenWriting
	|			LEFT JOIN ReceivingLeaseServicesBeforeWrite AS TableBeforeWrite
	|			ON TRUE
	|		WHERE
	|			(BEGINOFPERIOD(TableWhenWriting.Date, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.Date, MONTH)
	|				OR TableWhenWriting.Organization <> TableBeforeWrite.Organization
	|				OR TableWhenWriting.Counterparty <> TableBeforeWrite.Counterparty
	|				OR TableWhenWriting.Contract <> TableBeforeWrite.Contract
	|				OR TableWhenWriting.DocumentAmount <> TableBeforeWrite.DocumentAmount
	|				OR NOT TableWhenWriting.Posted
	|				OR TableBeforeWrite.Date IS NULL)
	|			AND TableWhenWriting.Ref = &Ref
	|	
	|	) AS Table
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ReceivingLeaseServicesBeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TablesData.TempTablesManager;
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.ExecuteBatch();
	Selection = QueryResult[0].Select();
	Selection.Next();
	
	AdditionalProperties.TablesData.Insert("ReceivingLeaseServicesUpdate", Selection.Count > 0);
	
	NonCurrentAssets.GenerateTaskRegisterEntries(ThisObject, AdditionalProperties.TablesData);
	
EndProcedure
 
 Procedure FillInBankingDetailsBeforeWrite(WriteMode)

	AuxiliaryAttributes = AuxiliaryAttributes();

	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Accruals, PriceIncludesVAT);

	For Each String In Accruals Do
		If String.AccrualType <> Enums.TypesOfLeasePayments.DepositPayment
			And String.AccrualType <> Enums.TypesOfLeasePayments.RentalServicePrepayment Then
			String.ARAPDocument = Undefined;
		EndIf;
	EndDo;
	
	ClearUnusedProps(AuxiliaryAttributes);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Accruals");
	
EndProcedure

Procedure ClearUnusedProps(AuxiliaryAttributes)
	
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_ReceiptOfRentalServices(
		ThisObject, AuxiliaryAttributes);
		
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "Accruals");

EndProcedure

Function AuxiliaryAttributes()

	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Organization, Date));
	
	AttributesList = "AssetHolder,RecognizeLeasedItemsInLocalAccounting,RecognizeLeasedAssetsInManagementAccounting,VATTaxation";
	
	If ValueIsFilled(Contract) Then
		ContractDetails_ = Common.ObjectAttributesValues(Contract, AttributesList);
	Else
		ContractDetails_ = New Structure(AttributesList);
	EndIf;
	AuxiliaryAttributes.Insert("ContractDetails_", ContractDetails_);

	Return AuxiliaryAttributes;
	
EndFunction
 
#EndRegion

#EndRegion

#EndIf
