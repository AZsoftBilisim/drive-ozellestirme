
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);

	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData, StandardProcessing);
	ElsIf FillInDataType = Type("CatalogRef.LeaseContract") Then
		FillInBasedOnLeaseAgreement(FillingData);
	EndIf;
	
	InitializeDocument();
	
	ItemsAndDimensionsSelectionParameters = Documents.SigningOfLeaseContract.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	IncomingDocumentDate = '000101010000';
	IncomingDocumentNumber	= "";
	Comment = "";
	DocumentVersion24 = False;
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");

	InitializeDocument();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not Cancel And WriteMode = DocumentWriteMode.Posting Then
		If Not LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Date, Organization) Then
			NonCurrentAssetsInternal.CheckThatFAIsNotReceivedForRentOnBalance(ThisObject, Cancel);
			CheckThatContractHasNotBeenConcluded(Cancel);
		EndIf;
		CheckDateOfConclusionOfAgreement(Cancel);
	EndIf;

	FillInBankingDetailsBeforeWrite(WriteMode);
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWrite(ThisObject, Documents.SigningOfLeaseContract.AccountingAccountSettings_());
		
	ItemsAndDimensionsSelectionParameters = Documents.SigningOfLeaseContract.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	
	ItemDetailsParameters = 
		LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_ConclusionOfLeaseAgreement(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckParameters = Documents.SigningOfLeaseContract.VerificationParametersFillingInDocumentOnVATTaxationPurchases(ThisObject);
	VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation(ThisObject, VATTaxation, CheckParameters, Cancel);
	
	CheckParameters = Documents.SigningOfLeaseContract.ParametersForCheckingDocumentFillingByTypeOfActivity(ThisObject);
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(ThisObject, PurchaseForActivity, CheckParameters, Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.SigningOfLeaseContract.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	LeasedAssetAccounting.CheckLeaseDocument(ThisObject, AuxiliaryAttributes, NotCheckedAttributeArray, Cancel);
	
	CheckDocument(AuxiliaryAttributes, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
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
	
	PaymentFrequency = Enums.ScheduleTimeFence.Month;
	AccrualFrequency = Enums.ScheduleTimeFence.Month;
	VATTaxation = ContractDetails_.VATTaxation;
	
EndProcedure

#EndRegion

#Region FillChecking

Procedure CheckDocument(AuxiliaryAttributes, Cancel)
	
	If EndOfDay(Date) + 1 = AuxiliaryAttributes.StartOfLeaseAccountingUnderFSB25_2018 
		And ValueIsFilled(Contract) Then
			
		ContractDetails_ = Common.ObjectAttributesValues(Contract, "AssetHolder,ContractType");
		If ContractDetails_.ContractType = Enums.TypesOfLeaseContracts.Leasing
			And ContractDetails_.AssetHolder = Enums.LeasedAssetHolder.Leaseholder Then
				
			MessageText = NStr("vi = 'Để chuyển sang kế toán Việt Nam, không cần lập chứng từ theo hợp đồng thuê, trong đó người có tài sản là người thuê';
								|ru = 'Для перехода на учет по ФСБУ 25/2018 не требуется оформление документа по договору лизинга, где балансодержатель арендатор';
								|en = 'The transfer to the accounting based on the Russian GAAP (FSBU 25/2018) does not require the processing of the documents based on financial lease contract, where lessee acts as balance holder'; fa = 'The transfer to the accounting based on the Russian GAAP (FSBU 25/2018) does not require the processing of the documents based on financial lease contract, where lessee acts as balance holder';
								|it = 'Per il passaggio alla contabilità conforme agli Standard Federali di Contabilità 25/2018 non è richiesta alcuna documentazione per contratti di leasing dove l''intestatario delle utenze è l''affittuario sono la stessa persona';
								|pl = 'Aby przejść na ewidencję zgodnie z federalnym standardem ewidencji księgowej 25/2018 nie jest wymagane sporządzenie dokumentu z tytułu umowy leasingu, gdzie posiadaczem bilansu jest najemca';
								|tr = 'FSBU 25/2018 kapsamında kayda geçmek için, bakiye sahibinin kiracı olduğu bir kiralama sözleşmesi kapsamında bir belge hazırlamak gerekli değildir'");
			Common.MessageToUser(MessageText, ThisObject, "Contract",, Cancel); 
		EndIf;
		
	EndIf;
	
EndProcedure


#EndRegion

#Region Other

Procedure InitializeDocument()
	
	Date = BegOfDay(CurrentSessionDate());
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	FillParameters = Documents.SigningOfLeaseContract.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	FillParameters = Documents.SigningOfLeaseContract.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);

	If VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT
		Or VATTaxation = Enums.VATTaxationTypes.VATTaxAgent Then
		VATRate = Catalogs.VATRates.EXCLUDINGVAT;
	Else
		VATRate = VATAccountingERP.DefaultVATRate(Organization, Date,, VATTaxation);
	EndIf;
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization);
	
	ItemsAndDimensionsSelectionParameters = Documents.SigningOfLeaseContract.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure CheckDateOfConclusionOfAgreement(Cancel)
	
	// Documents created by the end of the year are used to switch to FSB 25 and should fall into the inter-reporting period.
	If Not AccountingPoliciesTaxSettingsLocalization.FSB25IsApplied(Organization, Date) 
		 And AccountingPoliciesTaxSettingsLocalization.FSB25IsApplied(Organization, Date + 1) Then
		Return;
	EndIf;
	
	// In other cases, the date of conclusion of the Contract must be earlier than the date of acceptance for accounting.
	
	QueryText = 
	"SELECT
	|	MAX(CAST(InitialFixedAssetsInformation.Recorder AS Document.FixedAssetsInitialRecognition2_4).Date) AS Date
	|FROM
	|	InformationRegister.InitialFixedAssetsInformation AS InitialFixedAssetsInformation
	|WHERE
	|	InitialFixedAssetsInformation.FixedAsset IN(&ListOfFA)
	|	AND InitialFixedAssetsInformation.Organization = &Organization
	|	AND InitialFixedAssetsInformation.Recorder REFS Document.FixedAssetsInitialRecognition2_4
	|	AND InitialFixedAssetsInformation.CorrectionDate = DATETIME(1,1,1)
	|	AND InitialFixedAssetsInformation.Active
	|
	|HAVING
	|	MAX(CAST(InitialFixedAssetsInformation.Recorder AS Document.FixedAssetsInitialRecognition2_4).Date) < &Date";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Date", Date);
	Query.SetParameter("ListOfFA", FA.UnloadColumn("FixedAsset"));
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		MessageText = NStr("vi = 'Ngày ký hợp đồng (%1) không được sớm hơn ngày tiếp nhận vào kế toán (%2)';
							|ru = 'Дата заключения договора (%1) должна быть раньше даты принятия к учету (%2)';
							|en = 'The date of the contract (%1) signing must be earlier than the recognition date (%2)'; fa = 'The date of the contract (%1) signing must be earlier than the recognition date (%2)';
							|it = 'La data di stipula del contratto (%1) deve essere precedente alla data di registrazione in contabilità (%2)';
							|pl = 'Data zawarcia umowy (%1) powinna być wcześniejsza niż data przyjęcia do ewidencji (%2)';
							|tr = 'Sözleşme başlangıç tarihi (%1) muhasebe tarihinden (%2) önce olmalıdır'");
		MessageText = StrTemplate(MessageText, Date, Selection.Date);
		Common.MessageToUser(MessageText, ThisObject, "Date",, Cancel);
	EndIf;
	
EndProcedure

Procedure CheckThatContractHasNotBeenConcluded(Cancel)
	
	If Not AccountingPoliciesTaxSettingsLocalization.FSB25IsApplied(Organization, Date) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PRESENTATION(TermsOfLeaseContracts.Recorder) AS PresentationOfDocument,
	|	TermsOfLeaseContracts.Recorder AS DocumentReference
	|FROM
	|	InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseContracts
	|WHERE
	|	TermsOfLeaseContracts.Recorder REFS Document.SigningOfLeaseContract
	|	AND TermsOfLeaseContracts.Contract = &Contract
	|	AND TermsOfLeaseContracts.Recorder <> &Ref
	|ORDER BY
	|	TermsOfLeaseContracts.Period";
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		MessageText = NStr("vi = 'Theo một hợp đồng thuê, không thể tạo một số chứng từ ""Ký hợp đồng thuê"". Sẽ không được phép kết chuyển chứng từ.';
							|ru = 'По одному договору аренды не может быть оформлено несколько документов ""Заключение договора аренды"". Проведение документа будет недоступно.';
							|en = 'Cannot create several ""Rental term commitment"" documents for one rental contract. You will not be able to post the document.'; fa = 'Cannot create several ""Rental term commitment"" documents for one rental contract. You will not be able to post the document.';
							|it = 'По одному договору аренды не может быть оформлено несколько документов ""Заключение договора аренды"". Проведение документа будет недоступно.';
							|pl = 'Cannot create several ""Rental term commitment"" documents for one rental contract. You will not be able to post the document.';
							|tr = 'Bir kira sözleşmesi için birden fazla ""Kira sözleşmesinin imzalanması"" belgesi düzenlenemez. Belgenin yürütülmesi mümkün olmayacaktır.'");
		Selection = QueryResult.Select();
		Selection.Next();
		MessageText = MessageText + Chars.LF + StrTemplate(NStr("vi = 'Xem chứng từ: %1';
																|ru = 'См. документ: %1';
																|en = 'See the document: %1'; fa = 'See the document: %1';
																|it = 'См. документ: %1';
																|pl = 'See the document: %1';
																|tr = 'Bk. belge: %1'"), Selection.PresentationOfDocument);
		Common.MessageToUser(MessageText, Selection.DocumentReference, "Object.Date",, Cancel);
	EndIf;
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite(WriteMode)

	AuxiliaryAttributes = AuxiliaryAttributes();

	ClearUnusedProps(AuxiliaryAttributes);

	DocumentAmount = AmountIncludingVAT;
	LeaseItemsCost = FA.Total("Cost");
	
	CompleteTaxationBeforeWrite();
	FillOutPurchaseForActivityBeforeWrite();
	
	If WriteMode = DocumentWriteMode.Posting Then
	
		FillInAttributesOfTablePartBeforeWrite(AuxiliaryAttributes);
		
		Documents.SigningOfLeaseContract.CalculateRateCostInterest(
			ThisObject, AuxiliaryAttributes.ContractDetails_);
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
EndProcedure

Procedure CompleteTaxationBeforeWrite() Export
	
	// we take vat taxation from the lease Contract, if specified in the Contract, 
	// or from the document, if explicitly stated in it.
	// Otherwise, fill in the VAT rate from the document.
	
	If VATTaxation <> PredefinedValue("Enum.VATTaxationTypes.EmptyRef") Then
		Return;
	EndIf;
	
	ContractDetails_ = Common.ObjectAttributesValues(Contract, "AssetHolder, VATTaxation");
	LeaseAccountingAccordingToFSB25_2018IsUsed = LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Organization, Date, True);
	
	AccountingForBalanceSheet = ContractDetails_.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor")
															And Not LeaseAccountingAccordingToFSB25_2018IsUsed;

	UseVATAccounting = GetFunctionalOption("UseVATAccounting");

	If Not AccountingForBalanceSheet Then
		
		If ContractDetails_.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.EmptyRef") Then

			If Not UseVATAccounting Then
				VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsNotSubjectToVAT");
			Else
				
				If VATRate <> PredefinedValue("Catalog.VATRates.EXCLUDINGVAT") Then
					VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
				Else
					VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsNotSubjectToVAT");
				EndIf;
				
			EndIf;

		Else

			VATTaxation = ContractDetails_.VATTaxation;

		EndIf;

	EndIf;

EndProcedure

Procedure FillOutPurchaseForActivityBeforeWrite()
	
	If PurchaseForActivity <> PredefinedValue("Enum.VATTaxationTypes.EmptyRef") Then
		Return;
	EndIf;
	
	FillParameters = Documents.SigningOfLeaseContract.ParametersForFillingInVATActivityType(ThisObject);
	
	VATAccountingERP.FillInTypeOfActivityVAT(
		PurchaseForActivity,
		FillParameters);

EndProcedure

Procedure ClearUnusedProps(AuxiliaryAttributes)
	
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_ConclusionOfLeaseAgreement(
		ThisObject, AuxiliaryAttributes);
		
	TMCommonUseClientServer.ClearUnusedProps(
		ThisObject, 
		ItemDetailsParameters, 
		"ServicePaymentSchedule,ServiceAccrualSchedule,InterestAccrualSchedule");

EndProcedure

Function AuxiliaryAttributes()

	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("VNAManagementIsUsed_2_4", NonCurrentAssets.VNAManagementIsUsed_2_4(Date));
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Organization, Date, True));
	AuxiliaryAttributes.Insert("StartOfLeaseAccountingUnderFSB25_2018", LeasedAssetAccounting.StartOfLeaseAccountingUnderFSB25_2018(Organization));
	AuxiliaryAttributes.Insert("InsignificantVATRate", VATAccountingERP.InsignificantRate(VATRate));
	AuxiliaryAttributes.Insert("DocumentVersion24", DocumentVersion24);
	AuxiliaryAttributes.Insert("RecordInOperationalAccounting", True);
	AuxiliaryAttributes.Insert("NameOfFATablePart", "FA");
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
						"VATAccountingSettings", Organization, ?(Date <> '000101010000', EndOfMonth(Date), '000101010000'));
	
	AuxiliaryAttributes.Insert("SeparateFAAccountingByVATTaxation", AccountingPolicyParameters <> Undefined And AccountingPolicyParameters.SeparateFAAccountingByVATTaxation);
	
	AuxiliaryAttributes.Insert("ContractDetails_", LeasedAssetAccounting.DetailsOfLeaseAgreement(Contract));

	Return AuxiliaryAttributes;
	
EndFunction

Procedure FillInAttributesOfTablePartBeforeWrite(AuxiliaryAttributes)
	
	If FA.Count() = 0 Then
		Return;
	EndIf;
	
	ContractDetails_ = AuxiliaryAttributes.ContractDetails_;
	
	ArrayOfCoefficients = New Array;
	For Each RowData In FA Do
		
		RowData.AmountAccounting = 0;
		RowData.AmountFA = 0;
		RowData.VATAmount = 0;
		RowData.VATRate = Catalogs.VATRates.EmptyRef();
		
		// For lease Contracts with discounting, we distribute in proportion to the nominal value (from the fair value column).
		If ContractDetails_.ContractType = Enums.TypesOfLeaseContracts.Lease 
			 And ContractDetails_.MethodForDeterminingCostOfAssets = Enums.MethodsOfDeterminingLeasedAssetCost.Discounting Then
			 	
			 	If RowData.FairValue <> 0 Then
			 		ArrayOfCoefficients.Add(RowData.FairValue);
			 	Else
			 		ArrayOfCoefficients.Add(1);
			 	EndIf;
			 		
		Else
		// In other cases, we distribute it proportionally to the cost.
			 	ArrayOfCoefficients.Add(RowData.Cost);
		EndIf;
		
	EndDo;
	
	ResultOfVATDistribution = Common.DistributeAmountInProportionToCoefficients(
									VATAmount, ArrayOfCoefficients);
	
	DistributionResultAmountWithoutVAT = Common.DistributeAmountInProportionToCoefficients(
									Sum - VATAmount, ArrayOfCoefficients);
	
	CreatedForTransition = (EndOfDay(Date) + 1 = AuxiliaryAttributes.StartOfLeaseAccountingUnderFSB25_2018);
	
	For Each RowData In FA Do
		
		If CreatedForTransition Then
			
			RowData.AmountAccounting = RowData.NetBookValue;
			
		ElsIf AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed Then

			// The amount of capital investments without VAT according to accounting data in the currency of the contract.
			RowData.AmountAccounting = RowData.Cost;
			
		ElsIf ContractDetails_.AssetHolder = Enums.LeasedAssetHolder.Lessor Then

			RowData.AmountAccounting = RowData.Cost;
			
		Else
			
			// The amount of capital investments without VAT according to accounting data in the currency of the contract.
			If DistributionResultAmountWithoutVAT <> Undefined Then
				RowData.AmountAccounting = DistributionResultAmountWithoutVAT[RowData.LineNumber - 1];
			EndIf;
				
		EndIf;
		
		RowData.VATRate = VATRate;
		
		If ResultOfVATDistribution <> Undefined Then
			RowData.VATAmount = ResultOfVATDistribution[RowData.LineNumber - 1];
		EndIf;
		
	EndDo;
	
	SigningOfLeaseContractLocalization.FillInAttributesOfTablePartBeforeWrite(ThisObject, AuxiliaryAttributes);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
