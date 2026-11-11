
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If FillingData <> Undefined Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
	InitializeDocumentBeforeFillingItOut();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	If Not RecordInOperationalAccounting And Not PostInFinancialAndTaxAccounting And Not RecordInMA Then
		MessageText = NStr("vi = 'Chứng từ phải được phản ánh vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, hesaplardan birine yansıtılmalıdır'");
		Common.MessageToUser(MessageText, , 
			"Object.RecordInOperationalAccounting", , Cancel);
	EndIf;

	AuxiliaryAttributes = AuxiliaryAttributes();

	ItemDetailsParameters = 
		LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_EnteringLeaseSettlementBalances(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);

	LeasedAssetAccounting.CheckLeaseDocument(ThisObject, AuxiliaryAttributes, NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Comment = "";

	InitializeDocumentBeforeFillingItOut();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "PrepaymentsUnderLeaseContracts");

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);

	FillInBankingDetailsBeforeWrite(WriteMode);
		
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
		
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
		
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocumentBeforeFillingItOut()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);

	FillParameters = Documents.OBEntryOfLeaseSettlements.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	FillParameters = Documents.OBEntryOfLeaseSettlements.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);

	If VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT
		Or VATTaxation = Enums.VATTaxationTypes.VATTaxAgent Then
		VATRate = Catalogs.VATRates.EXCLUDINGVAT;
	Else
		VATRate = VATAccountingERP.DefaultVATRate(Organization, Date,, VATTaxation);
	EndIf;

	RecordInOperationalAccounting = True;
	
	If GetFunctionalOption("KeepManagementAccountingOnSelfFinancingChartOfAccounts") Then
		RecordInMA = True;
	EndIf;
	
	OBEntryOfLeaseSettlementsLocalization.InitializeDocumentBeforeFillingItOut(ThisObject);
	
EndProcedure

Function AuxiliaryAttributes()

	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("VNAManagementIsUsed_2_4", NonCurrentAssets.VNAManagementIsUsed_2_4(Date));
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Organization, Date));
	AuxiliaryAttributes.Insert("StartOfLeaseAccountingUnderFSB25_2018", LeasedAssetAccounting.StartOfLeaseAccountingUnderFSB25_2018(Organization));
	AuxiliaryAttributes.Insert("InsignificantVATRate", VATAccountingERP.InsignificantRate(VATRate));
	AuxiliaryAttributes.Insert("RecordInMA", RecordInMA);
	AuxiliaryAttributes.Insert("PostInFinancialAndTaxAccounting", PostInFinancialAndTaxAccounting);
	AuxiliaryAttributes.Insert("RecordInOperationalAccounting", RecordInOperationalAccounting);
	AuxiliaryAttributes.Insert("DocumentVersion24", False);
	AuxiliaryAttributes.Insert("NameOfFATablePart", "");
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
									"VATAccountingSettings", Organization, ?(Date <> '000101010000', EndOfMonth(Date), '000101010000'));
	AuxiliaryAttributes.Insert("SeparateFAAccountingByVATTaxation", AccountingPolicyParameters <> Undefined And AccountingPolicyParameters.SeparateFAAccountingByVATTaxation);
	
	AuxiliaryAttributes.Insert("ContractDetails_", LeasedAssetAccounting.DetailsOfLeaseAgreement(Contract));
	
	AuxiliaryAttributes.Insert("UseLocal", GetFunctionalOption("UseLocal"));
	AuxiliaryAttributes.Insert("KeepManagementAccountingOnSelfFinancingChartOfAccounts", GetFunctionalOption("KeepManagementAccountingOnSelfFinancingChartOfAccounts"));

	Return AuxiliaryAttributes;
	
EndFunction

Procedure FillInBankingDetailsBeforeWrite(WriteMode)

	AuxiliaryAttributes = AuxiliaryAttributes();

	ClearUnusedProps(AuxiliaryAttributes);

	DocumentAmount = AmountIncludingVAT;
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		If RecordInOperationalAccounting Then
			Documents.OBEntryOfLeaseSettlements.CalculateRateCostInterest(
				ThisObject, AuxiliaryAttributes.ContractDetails_);
		EndIf;
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "PrepaymentsUnderLeaseContracts");
	
EndProcedure

Procedure ClearUnusedProps(AuxiliaryAttributes)
	
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_EnteringLeaseSettlementBalances(
		ThisObject, AuxiliaryAttributes);
		
	TMCommonUseClientServer.ClearUnusedProps(
		ThisObject, 
		ItemDetailsParameters, 
		"ServicePaymentSchedule,ServiceAccrualSchedule,InterestAccrualSchedule");

EndProcedure

#EndRegion

#EndIf
