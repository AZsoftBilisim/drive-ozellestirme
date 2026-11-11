#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the terms of sales in the customer's order
//
// Parameters:
//	SalesTermsAndConditions - Structure - Structure to fill in.
//
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	Currency = SalesTermsAndConditions.ARAPCurrency;
	BusinessOperation = SalesTermsAndConditions.BusinessOperation;
	
	If ValueIsFilled(SalesTermsAndConditions.PaymentSchedule) Then
		PaymentSchedule = SalesTermsAndConditions.PaymentSchedule;
	EndIf;
	
	LineOfBusiness 	   = SalesTermsAndConditions.LineOfBusiness;
	
	OrganizationChanged = ValueIsFilled(SalesTermsAndConditions.Organization) And SalesTermsAndConditions.Organization <> Organization;
	PaymentFormChanged = ValueIsFilled(SalesTermsAndConditions.PaymentMethod) And SalesTermsAndConditions.PaymentMethod <> PaymentMethod;
	
	PaymentMethod = SalesTermsAndConditions.PaymentMethod;
	
	If OrganizationChanged Then
		Organization = SalesTermsAndConditions.Organization;
		BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	If OrganizationChanged Or PaymentFormChanged Then
		
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization             = Organization;
		ParametersStructure.LineOfBusiness = LineOfBusiness;
		ParametersStructure.PaymentMethod             = PaymentMethod;

		CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
		
	EndIf;
	
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.Counterparty) Then
			Counterparty = SalesTermsAndConditions.Counterparty;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.ContactPerson) 
			And Not ValueIsFilled(ContactPerson) Then
			ContactPerson = SalesTermsAndConditions.ContactPerson;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
	If SalesTermsAndConditions.ContractsAreUsed <> Undefined And SalesTermsAndConditions.ContractsAreUsed Then

		Contract = SalesServer.GetDefaultContract(ThisObject, BusinessOperation, Currency);
		
		If ValueIsFilled(Contract) Then
			PaymentInCurrencyUnderContract = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
			If ForeignCurrencyTransaction <> PaymentInCurrencyUnderContract Then
				ForeignCurrencyTransaction = PaymentInCurrencyUnderContract;
				BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
		EndIf;
		
		SalesServer.FillInBankAccountsUnderAgreement(Contract, BankAccount);
		
		If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
	Else
		
		If ForeignCurrencyTransaction <> SalesTermsAndConditions.ForeignCurrencyTransaction Then
			ForeignCurrencyTransaction = SalesTermsAndConditions.ForeignCurrencyTransaction;
			BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
	EndIf;
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, BankAccount);
	
	If ValueIsFilled(SalesTermsAndConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = SalesTermsAndConditions.FinancialAccountingGroup;
	EndIf;
	
EndProcedure

// Fills in the terms of sales under the agreement in the customer's order
//
Procedure FillInTermsOfSalesUnderAgreement() Export
	
	StandardProcessing = True;
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True);
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
	FillParameters = Documents.PurchasingReportToConsignorPrincipal.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.PurchasingReportToConsignorPrincipal - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	If TypeOf(DocumentObject) = Type("DocumentObject.ReversingEntry") Then
		If WriteMode = DocumentWriteMode.UndoPosting Then
			FillParameters.IgnoreTraceableWorkPurchasesUnderPrincipal = True;
		EndIf;
	Else
		If WriteMode = DocumentWriteMode.Posting Then
			FillParameters.IgnoreTraceableWorkPurchasesUnderPrincipal = True;
		EndIf;
	EndIf;
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	DocumentObject.AdditionalProperties.Insert("DisableProductControlForIssuingReportsToPurchasingCommittee", True);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.PurchasingReportToConsignorPrincipal.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables = Undefined) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	FillStockTypes(Cancel);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	CurrentRow = New Structure("VATRate", Catalogs.VATRates.EmptyRef());

	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	VATRateOfRemuneration = CurrentRow.VATRate;

	AmountVATRemuneration = VATAccountingERPClientServer.CalculateVATAmount(CommissionAmount,
		VATAccountingERPClientServer.ValueOfVATRate(VATRateOfRemuneration));
	
	For Each RowOfProduct In ThisObject.Goods Do
		RowOfProduct.AmountARAP = RowOfProduct.AmountIncludingVAT + RowOfProduct.CommissionAmount;
	EndDo;
		
	ARAPDetailsWithCustomer.Clear();
	
	FillParameters = Documents.PurchasingReportToConsignorPrincipal.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);
	
	ConsignmentSalesServer.FillInLBRateOfJointCommissionRemuneration(ThisObject);
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	PurchasingReportToConsignorPrincipalLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.PurchasingReportToConsignorPrincipal.ObjectModule.Filling");

	Author = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("FillInAccordingToDataForRegistration") Then
		
		Terms = FillingData.HeaderAttributes.Terms;
		If ValueIsFilled(Terms) Then
			FillInTermsOfSalesUnderAgreement();
		EndIf;
		
		FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
		
		If Not ValueIsFilled(Counterparty) Then
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		EndIf;
		If Not ValueIsFilled(Contract) Then
			
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = Currency;
			AddlParameters.Taxation = VATTaxation;
			Contract = PurchasesServer.GetDefaultContract(
				ThisObject,
				Enums.BusinessTransactions.DeliveryForPrincipal,
				AddlParameters);
				
		EndIf;
		
		If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness")
			And Not ValueIsFilled(LineOfBusiness) Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
		PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
		
		FillParameters = Documents.PurchasingReportToConsignorPrincipal.ParametersForFillingInSalesVATTaxation(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
		
		Documents.PurchasingReportToConsignorPrincipal.RequirementsForGoodsAndServicesForMakingReportsToPurchasingCommittee(
			ThisObject, 
			FillingData.AssignmentsArray, FillingData.ArrayOfPurchaseDocuments);
		
	EndIf;
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	If Not ValueIsFilled(BankAccount) Then
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, BankAccount);
	EndIf;
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, BankAccount,
		PaymentMethod);
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	CurrentRow = New Structure("VATRate", Catalogs.VATRates.EmptyRef());

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	VATRateOfRemuneration = CurrentRow.VATRate;

	ConsignmentSalesServer.CalculateRewardAmount(ThisObject, "AmountIncludingVAT", True);
	
	For Each RowOfProduct In ThisObject.Goods Do
		RowOfProduct.AmountARAP = RowOfProduct.AmountIncludingVAT + RowOfProduct.CommissionAmount;
	EndDo;
	
	OptionOfAssignment = Constants.OptionOfGoodsAssignmentInSales.Get();
	
	If Not ValueIsFilled(Terms)
		And OptionOfAssignment = Enums.OptionsOfGoodsAssignmentInSales.Contract Then
		
		StructureOfAdditionalSelection = New Structure;
		OperationArray = New Array();
		OperationArray.Add(PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal"));
		StructureOfAdditionalSelection.Insert("BusinessTransactions", OperationArray);
		
		SalesTermsAndConditions = SalesServer.GetDefaultSalesTerms(
			Partner,
			StructureOfAdditionalSelection);
		If ValueIsFilled(SalesTermsAndConditions) Then
			Terms = SalesTermsAndConditions.Terms;
		EndIf;
		
	EndIf;
	
	InitializeDocument(FillingData);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	If Not ValueIsFilled(FinancialAccountingGroup) And ValueIsFilled(Contract)
		And (ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice And Not ValueIsFilled(SalesOrder)
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments) Then
		
		FinancialAccountingGroup = Common.ObjectAttributeValue(Contract,"FinancialAccountingGroup");
		
	EndIf;
	
	ConsignmentReportToVendorLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
	"Document.PurchasingReportToConsignorPrincipal.ObjectModule.FillCheckProcessing");
	
	Documents.PurchasingReportToConsignorPrincipal.FillInNamesOfDetailsAccordingToMethodOfCalculatingRemuneration(
		CommissionFeeCalculationMethod, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;
	
	If Not ValueIsFilled(Terms) Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	If GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers") Then
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel);
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
		
	ObjectMetadata = ThisObject.Metadata();
	DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
	PresentationOfTS = ObjectMetadata.TabularSections.Goods.Synonym;
	PresentationOfPropsNumberOfPackages = ObjectMetadata.TabularSections.Goods.Attributes.NumberOfPackages.Synonym;
	TemplateQuantityError = NStr("vi = 'Chưa điền cột ""%ColumnPresentation%"" trong dòng %LineNumber% danh sách ""%PresentationOfTS%""';
								|ru = 'Не заполнена колонка ""%ColumnPresentation%"" в строке %LineNumber% списка ""%PresentationOfTS%""';
								|en = 'Column ""%ColumnPresentation%"" in line %LineNumber% of the ""%PresentationOfTS%"" list is not filled in'; fa = 'Column ""%ColumnPresentation%"" in line %LineNumber% of the ""%PresentationOfTS%"" list is not filled in';
								|it = 'Non è compilata la colonna ""%ColumnPresentation%"" nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
								|pl = 'Nie wypełniono kolumny ""%ColumnPresentation%"" w wierszu %LineNumber% listy ""%PresentationOfTS%""';
								|tr = '""%PresentationOfTS%"" listesinin %LineNumber%satırında ""%ColumnPresentation%"" sütunu doldurulmadı'");
	TemplateQuantityError = StrReplace(TemplateQuantityError, "%PresentationOfTS%", PresentationOfTS);
	
	PresentationOfPropsPurpose = ObjectMetadata.TabularSections.Goods.Attributes.Purpose.Synonym;
	TemplateAssignmentFillingError = NStr("vi = 'Đã chỉ định sai mục đích trong cột ""%ColumnPresentation%"" tại dòng %LineNumber% danh sách ""%PresentationOfTS%"".
	|Cần chọn mục đích có kiểu ""Giao hàng ủy thác""';
	|ru = 'Неверно указано назначение в колонке ""%ColumnPresentation%"" в строке %LineNumber% списка ""%PresentationOfTS%"".
	|Необходимо выбрать назначение с типом ""Поставка под принципала""';
	|en = 'The assignment is incorrectly specified in the ""%ColumnPresentation%"" column in line %LineNumber% of the ""%PresentationOfTS%"" list.
	|Select the assignment with the ""Procurement outsourcing"" type'; fa = 'The assignment is incorrectly specified in the ""%ColumnPresentation%"" column in line %LineNumber% of the ""%PresentationOfTS%"" list.
	|Select the assignment with the ""Procurement outsourcing"" type';
	|it = 'The assignment is incorrectly specified in the ""%ColumnPresentation%"" column in line %LineNumber% of the ""%PresentationOfTS%"" list.
	|Select the assignment with the ""Procurement outsourcing"" type';
	|pl = 'The assignment is incorrectly specified in the ""%ColumnPresentation%"" column in line %LineNumber% of the ""%PresentationOfTS%"" list.
	|Select the assignment with the ""Procurement outsourcing"" type';
	|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırındaki ""%ColumnPresentation%"" sütununda yer alan atama yanlıştır.
	|Tipi ""Tedarik dış kaynak kullanımı"" olan atama seçilmelidir'");
	TemplateAssignmentFillingError = StrReplace(TemplateAssignmentFillingError, "%PresentationOfTS%", PresentationOfTS);
	TemplateErrorFillingInLineOfBusiness = NStr("vi = 'Lĩnh vực hoạt động trong mục đích tại dòng %1 danh sách ""%2"" khác với lĩnh vực hoạt động trong báo cáo.';
												|ru = 'Направление деятельности в назначении в строке %1 списка ""%2"" отличается от направления деятельности в отчете.';
												|en = 'The line of business in the assignment in line %1 of the ""%2"" list differs from the line of business in the report.'; fa = 'The line of business in the assignment in line %1 of the ""%2"" list differs from the line of business in the report.';
												|it = 'The line of business in the assignment in line %1 of the ""%2"" list differs from the line of business in the report.';
												|pl = 'The line of business in the assignment in line %1 of the ""%2"" list differs from the line of business in the report.';
												|tr = '""%2"" listesinin %1 satırındaki atamadaki iş kolu, rapordaki iş kolundan farklıdır.'");
	
	For Each TabRow In Goods Do
		
		If TabRow.NumberOfPackages = 0 And Not TypeOf(TabRow.DocumentAcquisitions) = Type("DocumentRef.PurchaseAdjustment") Then
			MessageText = StrReplace(TemplateQuantityError, "%LineNumber%", String(TabRow.LineNumber));
			MessageText = StrReplace(MessageText, "%ColumnPresentation%", PresentationOfPropsNumberOfPackages);
			
			Field = CommonClientServer.PathToTabularSection("Goods", TabRow.LineNumber, "NumberOfPackages");
			
			Common.MessageToUser(MessageText, DataKey, Field, "Object", Cancel);
		EndIf;
		
		If ValueIsFilled(TabRow.Purpose) Then
			AssignmentType = Common.ObjectAttributeValue(TabRow.Purpose, "AssignmentType");
			If AssignmentType <> Enums.AssignmentTypes.DeliveryForPrincipal Then
				MessageText = StrReplace(TemplateAssignmentFillingError, "%LineNumber%", String(TabRow.LineNumber));
				MessageText = StrReplace(MessageText, "%ColumnPresentation%", PresentationOfPropsPurpose);
				
				Field = CommonClientServer.PathToTabularSection("Goods", TabRow.LineNumber, "Purpose");
				
				Common.MessageToUser(MessageText, DataKey, Field, "Object", Cancel);
			Else
				
				DestinationLineOfBusiness = Common.ObjectAttributeValue(TabRow.Purpose, "LineOfBusiness");
			
				If LineOfBusiness <>  DestinationLineOfBusiness Then
					
					MessageText = StrTemplate(TemplateErrorFillingInLineOfBusiness, String(TabRow.LineNumber), PresentationOfTS);
					Field = CommonClientServer.PathToTabularSection("Goods", TabRow.LineNumber, "Purpose");
				
					Common.MessageToUser(MessageText, DataKey, Field, "Object", Cancel);
				
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	If CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating Then
		If Not ValueIsFilled(ThisObject.OperationService) Then
			ErrorText = NStr("vi = 'Cần chỉ định một dịch vụ để phản ánh mức hoa hồng';
							|ru = 'Необходимо указать услугу для отражения суммы вознаграждения';
							|en = 'You should specify the service to reflect the amount of remuneration'; fa = 'You should specify the service to reflect the amount of remuneration';
							|it = 'È necessario indicare il servizio per inserire l''importo del compenso';
							|pl = 'Należy wskazać usługę do odzwieciedlenia kwoty wynagrodzenia';
							|tr = 'Ücret miktarını yansıtmak için bir hizmet belirtilmelidir'");
			Common.MessageToUser(ErrorText, ThisObject, "OperationService", , Cancel);
		Else
			ConsignmentSalesServer.CheckCommissionService(ThisObject, Cancel);
		EndIf;
	EndIf;

	PurchasingReportToConsignorPrincipalLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

	CheckConformityOfProductContract(Cancel);
	
	VerificationOfComplianceWithDetailsInPurchaseDocuments(Cancel);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	
	Cancel = Documents.PurchasingReportToConsignorPrincipal.CheckForAcquisitionsAndCorrectiveAdjustmentsInSameReport(ThisObject) Or Cancel;
	
EndProcedure

Procedure VerificationOfComplianceWithDetailsInPurchaseDocuments(Cancel)
	
	TSName = "Goods";
	PresentationOfTS = "Goods";
	
	For Each LineProducts_ In Goods Do
		
		If ValueIsFilled(LineProducts_.DocumentAcquisitions) Then
			
			DetailsOfPurchaseDocument = Common.ObjectAttributesValues(LineProducts_.DocumentAcquisitions, "PriceIncludesVAT, Organization, Currency");
			
			For Each DocumentAttribute In DetailsOfPurchaseDocument Do
				If ThisObject[DocumentAttribute.Key] <> DocumentAttribute.Value Then
					
					Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Giá trị cần thiết ""%1""của báo cáo này và сhứng từ ""%2""được chỉ định trong dòng %3 không khớp.';
						|ru = 'Не соответствует значение реквизита ""%1"" данного отчета и документа "" %2 "", указанного в строке %3.';
						|en = 'Attribute value ""%1"" of this report does not match to the document "" %2 "", specified in the line %3.'; fa = 'Attribute value ""%1"" of this report does not match to the document "" %2 "", specified in the line %3.';
						|it = 'Il valore del requisito ""%1"" di questo report e del documento ""%2"", indicato nella riga %3, non corrisponde.';
						|pl = 'Nie odpowiada wartość atrybutu ""%1"" danego raportu i dokumentu "" %2 "", podanego w wierszu %3.';
						|tr = 'Bu raporun ""%1"" özniteliği ile %3 satırındaki ""%2"" belgesinin değeri eşleşmiyor.'"),
					Metadata.Documents.PurchasingReportToConsignorPrincipal.Attributes[DocumentAttribute.Key],
					LineProducts_.DocumentAcquisitions,
					Goods.IndexOf(LineProducts_)+1,
					PresentationOfTS);
					
					Common.MessageToUser(
					Text,
					ThisObject,
					TSName + "[" + Goods.IndexOf(LineProducts_) + "].DocumentAcquisitions",
					,
					Cancel);
					
				EndIf;
			EndDo;
		EndIf;
			
	EndDo;
		
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)

	If DataExchange.Load Then
		Return;
	EndIf;

	For Each RowOfProduct In Goods Do
		RowOfProduct.AmountARAP = RowOfProduct.AmountIncludingVAT + RowOfProduct.CommissionAmount;
	EndDo;
	
	AdditionalProperties.Insert("DisableProductControlForIssuingReportsToPurchasingCommittee", True);
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);

	AdditionalProperties.Insert("IsNew", IsNew());
	AdditionalProperties.Insert("WriteMode", WriteMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	CalculationDocumentAmount = Goods.Total("AmountIncludingVAT");
	If DocumentAmount <> CalculationDocumentAmount Then
		DocumentAmount = CalculationDocumentAmount;
	EndIf;
	
	CalculationOfRemunerationAmount = Goods.Total("CommissionAmount");
	If CommissionAmount <> CalculationOfRemunerationAmount Then
		CommissionAmount = CalculationOfRemunerationAmount;
		
	EndIf;
	
	AccountingForTraceableGoodsLocalization.ClearGTDUNumbersOfTraceableWorks(ThisObject);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
		
		TMCommonUse.FillInDocumentIDs(ThisObject, 
			Metadata.Documents.PurchasingReportToConsignorPrincipal.TabularSections.Goods.Name);
		
		Uniqueness = New Map;
		For Each TableRow In Goods Do
			If Not ValueIsFilled(TableRow.RowIDRemuneration)
				Or Undefined <> Uniqueness.Get(TableRow.RowIDRemuneration) Then
				// The ID in the row is not filled in OR the ID has been encountered before
				TableRow.RowIDRemuneration = String(New UUID);
			EndIf;
			Uniqueness.Insert(TableRow.RowIDRemuneration, TableRow.RowIDRemuneration);
		EndDo;
		
	EndIf;
	
	RegistrationParameters = Documents.PurchasingReportToConsignorPrincipal.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	// We will clear the details of the document that are not used for the method of calculating remuneration.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.PurchasingReportToConsignorPrincipal.FillInNamesOfDetailsAccordingToMethodOfCalculatingRemuneration(
		CommissionFeeCalculationMethod,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
		
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;

	PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);

	FillCustomerOrdersFromAppointments();
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	PurchasingReportToConsignorPrincipalLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)

	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ArrayOfReports = New Array();
	ArrayOfReports.Add(Ref);
	
	PurchasingReportToConsignorPrincipalLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)

	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	PurchasingReportToConsignorPrincipalLocalization.UndoPosting(ThisObject, Cancel);
	
	ArrayOfReports = New Array();
	ArrayOfReports.Add(Ref);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	If Not Cancel Then
		
	EndIf;
	
	PurchasingReportToConsignorPrincipalLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization		= SettingsValueCached.GetDefaultOrganization(Organization);
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, BankAccount,
		PaymentMethod);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization    	= Organization;
	ParametersStructure.PaymentMethod		= PaymentMethod;
	ParametersStructure.CashAccount 			= CashAccount;
	CashAccount			= SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	Currency			= IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
	
	FillParameters = Documents.PurchasingReportToConsignorPrincipal.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	TempTablesManager = TemporaryDocumentDataTables();
	RefillInventoryKinds = InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager) Then
		
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, Goods);
		
	EndIf;

EndProcedure

Function TemporaryDocumentDataTables()
	
	Query = New Query("
	|SELECT
	|	&Date			AS Date,
	|	&Organization	AS Organization,
	|	&Partner		AS Partner,
	|	&Counterparty		AS Counterparty,
	|	&Terms		AS Terms,
	|	&Contract		AS Contract,
	|	&Currency			AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)	AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor)	AS BusinessOperation,
	|	FALSE			AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.ConsignedGoods)		AS InventoryType
	|INTO DocumentDataTable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	TableOfGoods.TaxInvoiceDate						AS TaxInvoiceDate,
	|	TableOfGoods.VendorInvoiceReceived				AS VendorInvoiceReceived,
	|	TableOfGoods.Vendor							AS Vendor,
	|	TableOfGoods.Count							AS Count,
	|	CAST(TableOfGoods.VATRate AS Catalog.VATRates) AS VATRate,
	|	TableOfGoods.AmountIncludingVAT							AS AmountIncludingVAT,
	|	TableOfGoods.CommissionAmount					AS CommissionAmount,
	|	TableOfGoods.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	0													AS AmountVATRemuneration,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|	TRUE												AS SelectTypesOfStocks
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	0 AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.TaxInvoiceDate				AS TaxInvoiceDate,
	|	TableOfGoods.VendorInvoiceReceived		AS VendorInvoiceReceived,
	|	TableOfGoods.Vendor					AS Vendor,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.CommissionAmount			AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration		AS AmountVATRemuneration,
	|	TableOfGoods.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableOfGoods.Warehouse						AS Warehouse,
	|	TableOfGoods.SalesOpportunity						AS SalesOpportunity,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.SelectTypesOfStocks			AS SelectTypesOfStocks,
	|	TableOfGoods.AmountIncludingVAT					AS AmountIncludingVAT,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)	AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|	SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	TableOfGoods.Products	AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END						AS CurViewOfStocks,
	|	FALSE						AS ThisIsReusablePackage,
	|	&Organization				AS Organization,
	|	VALUE(Enum.BusinessTransactions.PurchasingReportToThePrincipal)AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)AS InventoryType,
	|	&Partner					AS GoodsOwner,
	|	&Terms					AS Terms,
	|	&Counterparty					AS Counterparty,
	|	&Contract					AS Contract,
	|	&Currency						AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	CatalogProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.Work_5) AS InventoryType,
	|	UNDEFINED AS GoodsOwner,
	|	UNDEFINED AS Terms,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	&Currency AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
	|");
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Posted",					Posted);
	Query.SetParameter("Ref",						Ref);
	Query.SetParameter("Date",						Date);
	Query.SetParameter("Organization",				Organization);
	Query.SetParameter("Partner",					Partner);
	Query.SetParameter("Counterparty",					Counterparty);
	Query.SetParameter("Terms",					Terms);
	Query.SetParameter("Contract",					Contract);
	Query.SetParameter("Currency",						Currency);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually",	InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("TableOfGoods",				Goods);
	Query.SetParameter("TaxationOfOrganization",
		VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.PurchasingReportToConsignorPrincipal.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.PurchasingReportToConsignorPrincipal.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.DeliveryForPrincipal,
					Undefined,
					Department,
					Counterparty,
					Contract);
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.BatchesIndicationStatus = "";
	FieldsNames.Purpose = "Purpose"; //"New Structure("TEXT Field", "EXPRESS(EXPRESS(Collection.Analyticaccountenclature AS A Reference.Keyanalytic Accounting Nomenclature).Purpose AS A Reference.Appointments)");
	
	// Analytics for some reason is not selected and is not created (there are not enough key values to search for)
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other


Procedure FillCustomerOrdersFromAppointments()
	
	Assignments = Goods.Unload(, "Purpose");
	Assignments.GroupBy("Purpose", "");
	
	StringWithEmptyAssignment = Assignments.Find(Catalogs.Assignments.EmptyRef());
	If Not StringWithEmptyAssignment = Undefined Then
		Assignments.Delete(StringWithEmptyAssignment);
	EndIf;
	
	CustomerAppointmentsAndOrders = Common.ObjectsAttributeValue(Assignments.UnloadColumn("Purpose"), "OrderDocument");
	
	For Each RowGoods In Goods Do
		If ValueIsFilled(RowGoods.Purpose) Then
			RowGoods.SalesOrder = CustomerAppointmentsAndOrders[RowGoods.Purpose];
		EndIf;
	EndDo;
	
EndProcedure	

Procedure CheckConformityOfProductContract(Cancel)
	
	TSName = "Goods";
	PresentationOfTS = "Goods";
	
	For Each LineProducts_ In Goods Do
		
		If ValueIsFilled(LineProducts_.Purpose) Then
			ContractOfGoods = Common.ObjectAttributeValue(LineProducts_.Purpose, "Contract");
			If Contract <> ContractOfGoods Then
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Hợp đồng chỉ định trong dòng %1 của danh sách ""%2"" không khớp với hợp đồng báo cáo.';
						|ru = 'Договор назначения в строке %1 списка ""%2"" не совпадает с договором отчета.';
						|en = 'Assignment contract in the %1 line of the ""%2"" list does not match with the report contract.'; fa = 'Assignment contract in the %1 line of the ""%2"" list does not match with the report contract.';
						|it = 'Il contratto di destinazione nella riga %1 dell''elenco ""%2"" non corrisponde al contratto del report.';
						|pl = 'Umowa przeznaczenia w wierszu %1 listy ""%2"" nie odpowiada umowie raportu.';
						|tr = '""%2"" listesinin %1 satırındaki hedef sözleşme, sözleşme raporuyla eşleşmiyor.'"),
					Goods.IndexOf(LineProducts_) + 1,
					PresentationOfTS);
					
				Common.MessageToUser(
					Text,
					ThisObject,
					TSName + "[" + Goods.IndexOf(LineProducts_) + "].Purpose",
					,
					Cancel);
			EndIf;
			
		EndIf;
			
	EndDo;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Partner, Terms, Currency";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function OrganizationSDefaultAccountParameters()
	
	If ValueIsFilled(Organization) Then
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	Else
		ComplCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersOfAccount.LineOfBusiness = LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = ComplCurrency;
	
	Return ParametersOfAccount;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
