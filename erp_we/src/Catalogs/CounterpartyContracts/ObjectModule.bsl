#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("CatalogRef.Partners") Then
		
		FillInBasedOnPartner(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("CatalogRef.TermsOfSale")
		Or TypeOf(FillingData) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		
		FillInBasedOnAgreement_(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("OrganizationOfSelection") Then
			FillingData.Insert("Organization", FillingData.OrganizationOfSelection);
		EndIf;
		FillInByPicking(FillingData);
		
	EndIf;
	
	InitializeCatalog(FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var Errors;
	
	NotCheckedAttributeArray = New Array;
	
	// The expiration date of the contract must not be less than the date of the contract.
	If ValueIsFilled(Date) And ValueIsFilled(ValidityEndDate) Then	
		
		If BegOfDay(Date) > ValidityEndDate Then
			
			ErrorText = NStr("vi = 'Ngày hết hiệu lực của hợp đồng không được nhỏ hơn ngày hợp đồng';
							|ru = 'Дата окончания действия договора должна быть не меньше даты договора';
							|en = 'Contract expiration date cannot be less than the contract date'; fa = 'Contract expiration date cannot be less than the contract date';
							|it = 'La data di scadenza dell''accordo non può essere antecedente la data dell''accordo';
							|pl = 'Data wygaśnięcia umowy nie może być wcześniejsza od daty umowy';
							|tr = 'Sözleşmenin sona erme tarihi, sözleşme tarihinden daha önce olmamalıdır'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject, 
				"ValidityEndDate",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	// The expiration date of the contract must not be less than the start date.
	If ValueIsFilled(ValidityStartDate) And ValueIsFilled(ValidityEndDate) Then	
		
		If ValidityStartDate > ValidityEndDate Then
			
			ErrorText = NStr("vi = 'Ngày hết hiệu lực của hợp đồng không được nhỏ hơn ngày bắt đầu hiệu lực';
							|ru = 'Дата окончания действия договора должна быть не меньше даты начала действия';
							|en = 'Contract expiration date cannot be less than contract effective date'; fa = 'Contract expiration date cannot be less than contract effective date';
							|it = 'La data di scadenza dell''accordo non può essere antecedente la data di inizio dell''accordo';
							|pl = 'Data wygaśnięcia umowy nie może być wcześniejsza od daty wejścia w życie';
							|tr = 'Sözleşmenin sona erme tarihi, sözleşmenin başlangıç tarihinden daha önce olmamalıdır'");
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject, 
				"ValidityEndDate",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	NotCheckedAttributeArray.Add("Partner");
	
	If Not ValueIsFilled(Partner) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""%1""';
						|ru = 'Поле ""%1"" не заполнено';
						|en = '""%1"" is required'; fa = '""%1"" is required';
						|it = 'Il campo ""%1"" non è compilato';
						|pl = 'Pole ""%1"" nie jest wypełnione';
						|tr = '""%1"" alanı doldurulmamış'");
		TitlePartner = PartnersAndCounterparties.HeaderOfPartnerDetailsDependingOnBusinessOperation(BusinessOperation);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, TitlePartner);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject, 
			"Partner",
			,
			Cancel);
			
	Else

		ProcurementOperations						  = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier);
		ImportOperations						  = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
		OperationsInEAEUCountries 				  = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
		ProductionOperationsAtProcessor2_5 = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ProductionByToller2_5);
		
		PartnerFlags = Common.ObjectAttributesValues(Partner, "Client, Vendor");
		
		If PartnerFlags.Client <> True And PartnerFlags.Vendor <> True Then
			Common.MessageToUser(
				NStr("vi = 'Đối với bạn hàng được chọn, cần thiết lập dấu hiệu ""Khách hàng/Nhà cung cấp""';
					|ru = 'Для выбранного партнера должен быть установлен признак ""Клиент/Поставщик""';
					|en = 'The selected partner must have the ""Customer/Vendor"" checkbox selected'; fa = 'The selected partner must have the ""Customer/Vendor"" checkbox selected';
					|it = 'Для выбранного партнера должен быть установлен признак ""Клиент/Поставщик""';
					|pl = 'The selected partner must have the ""Customer/Vendor"" checkbox selected';
					|tr = 'Seçilen iş ortağı için ""Müşteri/Tedarikçi"" bayrağı yapılandırılmalıdır'"),
				ThisObject, 
				"Partner",
				,
				Cancel);
			
		ElsIf PartnerFlags.Client <> True 
					And (BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
						Or BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
						Or BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
						Or BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
						Or BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal
						Or BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent) Then
			Common.MessageToUser(
				NStr("vi = 'Đối với bạn hàng được chọn, cần thiết lập dấu hiệu ""Khách hàng""';
					|ru = 'Для выбранного партнера должен быть установлен признак ""Клиент""';
					|en = 'The selected partner must have the ""Customer"" checkbox selected'; fa = 'The selected partner must have the ""Customer"" checkbox selected';
					|it = 'Для выбранного партнера должен быть установлен признак ""Клиент""';
					|pl = 'The selected partner must have the ""Customer"" checkbox selected';
					|tr = 'Seçilen iş ortağı için ""Müşteri"" bayrağı yapılandırılmalıdır'"),
				ThisObject, 
				"Partner",
				,
				Cancel);
			
		ElsIf PartnerFlags.Vendor <> True
					And (ProcurementOperations.Find(BusinessOperation) <> Undefined
						Or ImportOperations.Find(BusinessOperation) <> Undefined
						Or OperationsInEAEUCountries.Find(BusinessOperation) <> Undefined
						Or ProductionOperationsAtProcessor2_5.Find(BusinessOperation) <> Undefined
						Or BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
						Or BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
						Or BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale) Then
			Common.MessageToUser(
				NStr("vi = 'Đối với bạn hàng được chọn, cần thiết lập dấu hiệu ""Nhà cung cấp""';
					|ru = 'Для выбранного партнера должен быть установлен признак ""Поставщик""';
					|en = 'The selected partner must have the ""Vendor"" checkbox selected'; fa = 'The selected partner must have the ""Vendor"" checkbox selected';
					|it = 'Для выбранного партнера должен быть установлен признак ""Поставщик""';
					|pl = 'The selected partner must have the ""Vendor"" checkbox selected';
					|tr = 'Seçilen iş ortağı için ""Tedarikçi"" bayrağı yapılandırılmalıdır'"),
				ThisObject, 
				"Partner",
				,
				Cancel);
		EndIf;
		
	EndIf;
	
	If Not CompanyActsAsAVATTaxAgent Then
		NotCheckedAttributeArray.Add("AgencyAgreementKind");
	EndIf;
	
	If Not ContractType = Enums.ContractTypes.SalesViaCommissionAgent Then
		NotCheckedAttributeArray.Add("CommissionAgentPartner");
		NotCheckedAttributeArray.Add("CounterpartyCommissionAgent");
		NotCheckedAttributeArray.Add("ContractWithCommissionAgent");
	EndIf;
	
	UsePurchaseDesign = (ContractType = Enums.ContractTypes.WithVendor
		Or ContractType = Enums.ContractTypes.PurchaseEAEU
		Or ContractType = Enums.ContractTypes.Import);
	
	If Not GetFunctionalOption("UseDeliveryManagement")
		Or DeliveryMethod = Enums.TransportMethods.DeterminedInReference
		Or Not UsePurchaseDesign Then
		NotCheckedAttributeArray.Add("DeliveryMethod");
		NotCheckedAttributeArray.Add("CarrierPartner");
		NotCheckedAttributeArray.Add("DeliveryAddressOfCarrier");
	EndIf;
	
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel);
	
	If VATTaxationIsDeterminedInDocuments 
		Or ContractType = Enums.ContractTypes.Import
		Or ContractType = Enums.ContractTypes.TransferToTolling2_5 
		Or ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries Then
		NotCheckedAttributeArray.Add("VATTaxation");
	EndIf;
	
	If PurchaseForActivityIsDeterminedInDocument
		Or (ContractType <> Enums.ContractTypes.WithVendor
			And ContractType <> Enums.ContractTypes.TransferToTolling2_5
			And ContractType <> Enums.ContractTypes.SubcontractingToTheEAEUCountries
			And ContractType <> Enums.ContractTypes.ReceivingForCustody) Then
		NotCheckedAttributeArray.Add("PurchaseForActivity");
	EndIf;
	
	If ContractType <> Enums.ContractTypes.ReceivingForCustody Then
		NotCheckedAttributeArray.Add("RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage");
		NotCheckedAttributeArray.Add("RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction");
	EndIf;
	If ContractType <> Enums.ContractTypes.ReceiptForTolling
		And ContractType <> Enums.ContractTypes.ReceiptForTolling2_5 Then
		NotCheckedAttributeArray.Add("Department");
	EndIf;
	If ContractType <> Enums.ContractTypes.Sublease Then
		NotCheckedAttributeArray.Add("LeaseContracts");
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(Errors);
	CounterpartyContractsLocalization.FillCheckProcessing(Cancel, CheckedAttributes, NotCheckedAttributeArray, ThisObject);
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If ValueIsFilled(LineOfBusiness) 
		And ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale Then
		DetailsOfDirectionOfActivity = Common.ObjectAttributesValues(LineOfBusiness, "IncomeAccounting, CostAccounting");
		If Not DetailsOfDirectionOfActivity.IncomeAccounting
			Or Not DetailsOfDirectionOfActivity.CostAccounting Then
			ErrorText = NStr("vi = 'Để giao hàng cho người được ủy nhiệm, mảng hoạt động cần tính đến cả thu nhập và chi phí.';
							|ru = 'Для поставки под принципала направление деятельности должно учитывать и доходы и затраты.';
							|en = 'For procurement outsourcing, the line of business must take into account both income and costs.'; fa = 'For procurement outsourcing, the line of business must take into account both income and costs.';
							|it = 'Per le forniture conto mandante il settore dell''attività deve tenere conto sia delle entrate che delle uscite.';
							|pl = 'Dla dostawy dla zleceniodawcy rodzaj działalności należy uwzględniać dochody i rozchody.';
							|tr = 'Anapara kapsamında tedarik yapabilmek için, iş kolunun hem gelirleri hem de giderleri dikkate alması gerekir.'");
			Common.MessageToUser(ErrorText, ThisObject, "LineOfBusiness", , Cancel);
		EndIf;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not ValueIsFilled(NameForPrinting) Then
		NameForPrinting = TrimAll(Description);
	EndIf;
	
	BusinessOperation = Catalogs.CounterpartyContracts.BusinessOperation(ContractType, PurchaseRegistrationOption);
	
	TMCommonUse.ChangeCatalogConsistencyFlag(
		ThisObject,
		Enums.CounterpartyContractStatuses.NotApproved);
	If ValueIsFilled(AllowableAmountPayable) And Not LimitDebtAmount Then
		AllowableAmountPayable = 0;
	EndIf;
	
	If Not CentralizedContract Then
		BranchOffices_.Clear();
	EndIf;
	
	If Not ExecutionScheduleIsSpecified And ValueIsFilled(ContractSchedule) Then
		Try
			LockDataForEdit(ContractSchedule);
			ContractSchedule.GetObject().SetDeletionMark(True);
			ContractSchedule = Undefined;
		Except
			ErrorText = BriefErrorDescription(ErrorInfo());
			CommonClientServer.MessageToUser(
				ErrorText,
				Ref,,,
				Cancel);
		EndTry;
	EndIf;
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());
	
	// Working out the change of marking deletion
	If Not IsNew()
		And DeletionMark <> AdditionalProperties.DeletionMarkBeforeRecording Then
		Documents.ContractSchedule.SetDeletionMark(Ref, DeletionMark);
	EndIf;
	
	AssignmentTemplateFillingIsRequired = False;
	DestinationPattern = Catalogs.CounterpartyContracts.DestinationPattern(ThisObject);

	If ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale
		And Constants.OptionOfGoodsAssignmentInSales.Get() = Enums.OptionsOfGoodsAssignmentInSales.Contract Then
	
		AssignmentTemplateFillingIsRequired = True;
	ElsIf ContractType  = Enums.ContractTypes.TransferToTolling2_5
		Or ContractType  = Enums.ContractTypes.SubcontractingToTheEAEUCountries
		Or ContractType  = Enums.ContractTypes.ReceiptForTolling2_5

		Or False Then
	
		AssignmentTemplateFillingIsRequired = True;
	EndIf;
	
	Catalogs.Assignments.CheckFillBeforeRecording(Purpose, DestinationPattern, ThisObject,
		"LineOfBusiness,Partner,ContractType", Cancel, True, Not AssignmentTemplateFillingIsRequired);
	
	If ContractType = Enums.ContractTypes.Import
		Or ContractType = Enums.ContractTypes.SubcontractingToTheEAEUCountries
		Or ContractType = Enums.ContractTypes.PurchaseEAEU
		Or (ContractType = Enums.ContractTypes.WithVendor
		And ContractWithSelfEmployedPerson) Then
		
		DefaultVATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
		
		If Enums.ContractTypes.ThisIsSalesContract(ContractType) Then
			FillParameters = Catalogs.CounterpartyContracts.ParametersForFillingInSalesVATTaxation(ThisObject);
			VATAccountingERP.FillInSalesVATTaxation(DefaultVATTaxation, FillParameters, Undefined);
		ElsIf Enums.ContractTypes.ThisIsPurchaseContract(ContractType) Then
			FillParameters = Catalogs.CounterpartyContracts.ParametersForFillingInVATTaxationPurchases(ThisObject);
			VATAccountingERP.FillInVATTaxationPurchases(DefaultVATTaxation, FillParameters, Undefined);
		EndIf;
		
		VATAccountingERP.FillInVATRateForPayments_(VATRate, DefaultVATTaxation, Organization, ValidityEndDate);
		
	EndIf;
	
	CounterpartyContractsLocalization.BeforeWrite(Cancel, ThisObject);
	
	// You only need to create a AR/AP object after filling in the Payment ID
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel);
	
	RegularPayments = Enums.OptionsForDeterminingExecutionScheduleInContract.RegularPayments;
	If Not Cancel And Not ValueIsFilled(ContractSchedule)
		And OptionOfDeterminingExecutionScheduleInContract = RegularPayments Then
		ContractSchedule = Documents.ContractSchedule.GetRef();
		ExecutionScheduleIsSpecified = True;
	EndIf;
	
	If OptionOfDeterminingExecutionScheduleInContract <> RegularPayments Then
		DayOfRegularPayment = '00010101';
		RegularPaymentAmount = 0;
		RegularPaymentTimeFence = Undefined;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Approved               = False;
	ValidityStartDate       = '00010101';
	ValidityEndDate    = '00010101';
	ContractSchedule = Undefined;
	Purpose               = Undefined;
	CounterpartyContractsLocalization.OnCopy(CopiedObject, ThisObject);
	RevalueGoodsAndServicesForConsignmentNotification = 
		ContractType = Enums.ContractTypes.WithConsignor
		Or ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale;
	
	InitializeCatalog(, False);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DestinationPattern = Catalogs.CounterpartyContracts.DestinationPattern(ThisObject);
	Catalogs.Assignments.WhenWritingCatalog(Purpose, DestinationPattern, ThisObject, VATTaxation);


	
	TMCommonUse.SyncKeys(ThisObject);	
	
	RegularPayments = Enums.OptionsForDeterminingExecutionScheduleInContract.RegularPayments;
	If Not Cancel And ValueIsFilled(ContractSchedule)
		And OptionOfDeterminingExecutionScheduleInContract = RegularPayments
		And ValueIsFilled(RegularPaymentTimeFence)
		And ValueIsFilled(DayOfRegularPayment) 
		And ValueIsFilled(RegularPaymentAmount) Then
		
		Documents.ContractSchedule.CreateFillInRegularPayments(ContractSchedule, Ref);
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	RemoveServiceLoggers(Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInBasedOnPartner(Val Partner, FillingData)
	
	FillingData = New Structure;
	
	FillingData.Insert("Partner", Partner);
	FillingData.Insert("Counterparty", PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Partner));
	FillingData.Insert("ContactPerson", PartnersAndCounterparties.GetDefaultPartnerContactPerson(Partner));
	FillingData.Insert("BusinessOperation", BusinessTransactionForPartner(Partner));
	FillingData.Insert("ContractType", Catalogs.CounterpartyContracts.ContractType(FillingData.BusinessOperation));
	
	FillInCounterpartySDefaultBankAccount(FillingData);
	
EndProcedure

Procedure FillInBasedOnAgreement_(Val Terms, FillingData)

	FullCatalogName = Terms.Metadata().FullName();
	
	Query = New Query(
	"SELECT
	|	&CurrentDate AS Date,
	|	TheseAgreements.Partner			   AS Partner,
	|	TheseAgreements.Counterparty			   AS Counterparty,
	|	TheseAgreements.Organization		   AS Organization,
	|	TheseAgreements.BusinessOperation AS BusinessOperation,
	|	TheseAgreements.Currency				   AS ARAPCurrency,
	|	TheseAgreements.ForeignCurrencyTransaction		   AS ForeignCurrencyTransaction,
	|	&TextContactPerson,
	|
	|	CASE WHEN TheseAgreements.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|	 OR TheseAgreements.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid) THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS ThereAreErrorsStatus,
	|
	|	NOT TheseAgreements.ContractsAreUsed AS ThereAreErrorsUsingContracts,
	|	TheseAgreements.LineOfBusiness AS LineOfBusiness
	|
	|FROM
	|	&FullCatalogName  AS TheseAgreements
	|WHERE
	|	TheseAgreements.Ref = &Ref
	|");
	
	Query.Text = StrReplace(Query.Text, "&FullCatalogName", FullCatalogName);
	
	If FullCatalogName = "Catalog.TermsOfSale" Then
		Query.Text = StrReplace(Query.Text, "&TextContactPerson,", "TheseAgreements.ContactPerson        AS ContactPerson,");
	Else	
		Query.Text = StrReplace(Query.Text, "&TextContactPerson,", "");
	EndIf;
	
	Query.SetParameter("Ref", Terms);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	QueryResult = Query.Execute();
	
	FillingData = New Structure;
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		CheckPossibilityOfEnteringOnBasisOfAgreement(Selection.ThereAreErrorsUsingContracts, Selection.ThereAreErrorsStatus);
		
		FillPropertyValues(FillingData, Selection);
		If ValueIsFilled(FillingData.Partner) 
			And Not ValueIsFilled(FillingData.Counterparty) 
			And GetFunctionalOption("UsePartnersAsCounterparties") Then
			
			FillingData.Counterparty = PartnersAndCounterparties.GetPartnerSDefaultCounterparty(FillingData.Partner);
			
		EndIf;
		
		FillingData.Insert("ContractType", Catalogs.CounterpartyContracts.ContractType(Selection.BusinessOperation));
		
		FillInOrganizationSDefaultBankAccount(FillingData);
		FillInCounterpartySDefaultBankAccount(FillingData);
		
	EndIf;
	
EndProcedure

Procedure FillInByPicking(Val FillingData)
	
	If FillingData.Property("DefaultPartner") Then
		FillingData.Insert("Partner", FillingData.DefaultPartner);
	ElsIf FillingData.Property("Partner") Then
		
	ElsIf FillingData.Property("Counterparty") Then
		FillingData.Insert("Partner", Common.ObjectAttributeValue(FillingData.Counterparty, "Partner"));
	EndIf;
	
	If FillingData.Property("Partner") Then
		If Not (FillingData.Property("Counterparty") And ValueIsFilled(FillingData.Counterparty)) Then
			FillingData.Insert("Counterparty", PartnersAndCounterparties.GetPartnerSDefaultCounterparty(FillingData.Partner));
		EndIf;
		If Not (FillingData.Property("ContactPerson") And ValueIsFilled(FillingData.ContactPerson)) Then
			FillingData.Insert("ContactPerson", PartnersAndCounterparties.GetDefaultPartnerContactPerson(FillingData.Partner));
		EndIf;
	EndIf;
	
	FillInOrganizationSDefaultBankAccount(FillingData);
	FillInCounterpartySDefaultBankAccount(FillingData);
	
	If FillingData.Property("DefaultBusinessTransaction") Then
		FillingData.Insert("BusinessOperation", FillingData.DefaultBusinessTransaction);
		FillingData.Insert("ContractType", Catalogs.CounterpartyContracts.ContractType(FillingData.BusinessOperation));
	ElsIf FillingData.Property("Partner") And ValueIsFilled(FillingData.Partner)
		And Not FillingData.Property("BusinessOperation") Then
		FillingData.Insert("BusinessOperation", BusinessTransactionForPartner(FillingData.Partner));
		FillingData.Insert("ContractType", Catalogs.CounterpartyContracts.ContractType(FillingData.BusinessOperation));
	ElsIf FillingData.Property("BusinessOperation") And ValueIsFilled(FillingData.BusinessOperation) Then
		If TypeOf(FillingData.BusinessOperation) = Type("Array")
			And FillingData.BusinessOperation.Count() = 1 Then
			FillingData.Insert("ContractType", Catalogs.CounterpartyContracts.ContractType(FillingData.BusinessOperation[0]));
		Else
			FillingData.Insert("ContractType", Catalogs.CounterpartyContracts.ContractType(FillingData.BusinessOperation));
		EndIf;
	EndIf;
	
	If FillingData.Property("ARAPCurrency") And Not FillingData.Property("ForeignCurrencyTransaction") Then
		FillingData.Insert("ForeignCurrencyTransaction",
			ARAPAccountingServer.GetPaidInDefaultCurrency());
	EndIf;
	
EndProcedure

Procedure CheckPossibilityOfEnteringOnBasisOfAgreement(ThereAreErrorsUsingContracts, ThereAreErrorsStatus)
	
	If ThereAreErrorsUsingContracts Then
		
		ErrorText = NStr("vi = 'Theo thỏa thuận không cần chỉ ra hợp đồng. Cấm nhập trên cơ sở.';
						|ru = 'По соглашению не требуется указание договоров. Ввод на основании запрещен.';
						|en = 'Contract specification is not required under the agreement. Generation from base documents is prohibited.'; fa = 'Contract specification is not required under the agreement. Generation from base documents is prohibited.';
						|it = 'Come concordato non è richiesto indicare gli accordi. Immissione in base alla causale non consentita.';
						|pl = 'Porozumienie nie wymaga wskazywania umów. Wprowadzanie na podstawie jest zabronione.';
						|tr = 'Anlaşmaya göre, sözleşmelerin belirtilmesi gerekmemektedir. Bu gerekçeyle giriş yasaktır.'");
	
		Raise ErrorText;
		
	ElsIf ThereAreErrorsStatus Then
		
		ErrorText = NStr("vi = 'Cấm nhập trên cơ sở thỏa thuận không còn hiệu lực.';
						|ru = 'Ввод на основании недействующего соглашения запрещен.';
						|en = 'You cannot generate a document from an invalid agreement.'; fa = 'You cannot generate a document from an invalid agreement.';
						|it = 'L''immissione su base di un accordo non valido non è consentita.';
						|pl = 'Wprowadzanie na podstawie nieaktualnego porozumienia jest zabronione.';
						|tr = 'Geçersiz bir anlaşma kapsamında giriş yasaktır.'");
	
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

Procedure FillInOrganizationSDefaultBankAccount(FillingData)
	
	If FillingData.Property("BankAccount") And ValueIsFilled(FillingData.BankAccount)
	 Or Not (FillingData.Property("Organization") And ValueIsFilled(FillingData.Organization)) Then
		Return;
	EndIf;
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
	ParametersOfAccount.Organization = FillingData.Organization;
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = ComplCurrency;

	FillingData.Insert("BankAccount",
		Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount));
	
EndProcedure

Procedure FillInCounterpartySDefaultBankAccount(FillingData)
	
	If FillingData.Property("CounterpartyBankAccount") And ValueIsFilled(FillingData.CounterpartyBankAccount)
	 Or Not (FillingData.Property("Counterparty") And ValueIsFilled(FillingData.Counterparty)) Then
		Return;
	EndIf;
	
	If FillingData.Property("Organization") And ValueIsFilled(FillingData.Organization) Then
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization);
	Else
		ComplCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	FillingData.Insert("CounterpartyBankAccount");
	FillingData.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
		FillingData.Counterparty, ComplCurrency, , ForeignCurrencyTransaction);
	
EndProcedure

// The procedure fills in the directory details with the "default" values.
//
Procedure InitializeCatalog(FillingData = Undefined, FillInAllDetails = True) Export
	
	Manager = Users.CurrentUser();
	Status = Enums.CounterpartyContractStatuses.Valid;
	
	If FillInAllDetails Then
		
		If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
			Organization = SettingsValueCached.GetDefaultOrganization(Organization);
		EndIf;
		
		If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("ARAPCurrency") Then
			If Not ValueIsFilled(ARAPCurrency) Then
				ARAPCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
			EndIf;
			
		EndIf;
		
		If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("ForeignCurrencyTransaction") Then
			ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
		EndIf;
		
		ContractType = Catalogs.CounterpartyContracts.ContractType(BusinessOperation);
		If Not ValueIsFilled(ContractType) And TypeOf(FillingData) = Type("Structure")
			And FillingData.Property("BusinessOperation") Then
			ContractType = Catalogs.CounterpartyContracts.ContractType(FillingData.BusinessOperation);
		EndIf; 
		
		If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("BankAccount") Then
			ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
			ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
			ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
			BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
				BankAccount);
		EndIf;
		
		If Enums.ContractTypes.ThisIsSalesContract(ContractType) Then
			
			FillParameters = Catalogs.CounterpartyContracts.ParametersForFillingInSalesVATTaxation(ThisObject);
			VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
		
		ElsIf  Enums.ContractTypes.ThisIsPurchaseContract(ContractType) Then
			
			FillParameters = Catalogs.CounterpartyContracts.ParametersForFillingInVATTaxationPurchases(ThisObject);
			VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
			
			FillParameters = Catalogs.CounterpartyContracts.ParametersForFillingInVATActivityType(ThisObject);
			VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
			
		EndIf;
		
		If TypeOf(FillingData) = Type("Structure")
			 And FillingData.Property("ARAPObjectSettings") Then
			FillPropertyValues(ThisObject, FillingData, "ARAPObjectSettings");
		EndIf;
		ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
		
	EndIf;
	
	If (ContractType = Enums.ContractTypes.ReceivingForCustody
			Or ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale)
		And Not ValueIsFilled(RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage) Then
		RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage =
			Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.RegisterBuyback;
	EndIf;
	
	If (ContractType = Enums.ContractTypes.WithConsignor
			Or ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale) Then
		RevalueGoodsAndServicesForConsignmentNotification = True;
	EndIf;
	If ContractType = Enums.ContractTypes.ReceivingForCustody
		And Not ValueIsFilled(RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction) Then
		RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction =
			Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.RegisterBuyback;
	EndIf;
	If ContractType = Enums.ContractTypes.ReceiptForTolling2_5 Then
		
		If Not ValueIsFilled(RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage) Then
			RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage =
				Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.RegisterWriteOff;
		EndIf;
		
		If Not ValueIsFilled(RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction) Then
			RegistrationOfWriteOffOfGoodsAcceptedForStorageToProduction =
				Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.RegisterBuyback;
		EndIf;
		
	EndIf;
	If Not (ContractType = Enums.ContractTypes.WithVendor 
		Or ContractType = Enums.ContractTypes.PurchaseEAEU 
		Or ContractType = Enums.ContractTypes.Import) Then
		GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure RemoveServiceLoggers(Cancel)
	

	Query = New Query(
		"SELECT
		|	Recorders.Ref AS Ref
		|FROM
		|	Document.VendorContractVendorAgreementRecorder AS Recorders
		|WHERE
		|	Recorders.ReferenceOrder = &Ref");
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		DocObject = Selection.Ref.GetObject();
		DocObject.Delete();
	EndDo;
	
EndProcedure

Function BusinessTransactionForPartner(Partner)
	
	PartnerData = Common.ObjectAttributesValues(Partner, "Client, Vendor");
	
	If PartnerData.Client And Not PartnerData.Vendor Then
		Return Enums.BusinessTransactions.SaleToCustomer;
	ElsIf PartnerData.Vendor And Not PartnerData.Client Then
		Return Enums.BusinessTransactions.PurchaseFromSupplier;
	Else
		Return Enums.BusinessTransactions.EmptyRef();
	EndIf;
	
EndFunction


Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryKinds", "DeletionMark");
	Result.Insert("Catalog.DimensionKeysOfAccountingByPartners", "DeletionMark");
	Result.Insert("Catalog.InventoryLocationAttributeKeys", "Partner,Counterparty,Organization,DeletionMark");
	Result.Insert("Document.VendorContractVendorAgreementRecorder", "DeletionMark");
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
