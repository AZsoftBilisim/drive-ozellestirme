
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	AccountingMechanismsFillingProcessing(FillingData);
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillInSelectionDocument(FillingData, StandardProcessing);
		
	ElsIf FillInDataType = Type("CatalogRef.LeaseContract") Then
		
		FillInBasedOnLeaseAgreement(FillingData);
	
	ElsIf FillInDataType = Type("DocumentRef.LeaseTermAdjustment") Then

		FillInOnBasisOfRentalTermsADJUSTMENTChanges(FillingData);

	EndIf;
	
	InitializeDocument();

EndProcedure

Procedure OnCopy(CopiedObject)
	
	IncomingDocumentDate = '000101010000';
	IncomingDocumentNumber	= "";
	Comment = "";

	TMCommonUse.ClearDocumentIDs(ThisObject, "FA,PrepaymentsSettlement");

	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("PrepaymentsSettlement.ARAPDocument");
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	LeasedAssetAccounting.CheckReturnFromSublease(ThisObject, Cancel);
	
	ItemDetailsParameters = 
		LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_RedemptionOfLeasedFA(ThisObject, AuxiliaryAttributes());
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckPossibilityOfRedemption(Cancel);
	CheckOffsettingAdvances(Cancel);
	
	AccountingMechanismsHandlingFillVerification(Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);  
	
	VendorInvoiceLeasedAssetsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not Cancel And WriteMode = DocumentWriteMode.Posting Then
		NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
	EndIf;
	
	ClearUnusedProps();
	
	AccountingMechanismsBeforeWrite(Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);

	VendorInvoiceLeasedAssetsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.ClearDocumentRegisteredRecords(ThisObject, "GoodsForRegistrationOfImportDocuments");
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	AccountingMechanismsForConducting();
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);

	AccountingMechanismsForDataDeletion();
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization); 
	
	If Not ValueIsFilled(Currency) Then
		Currency = LocalAccountingCurrency;
	EndIf;
	
	If Not ValueIsFilled(ARAPCurrency) Then
		ARAPCurrency = ARAPCurrency;
	EndIf;
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization);

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(FA, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		FA,
		Undefined);
	
EndProcedure

Procedure FillInSelectionDocument(FillingData, StandardProcessing)

	If FillingData.Property("Contract")
	 	And TypeOf(FillingData.Contract) = Type("CatalogRef.LeaseContract") Then
	 		
		FillInBasedOnLeaseAgreement(FillingData.Contract);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnLeaseAgreement(FillingData)

	If Not ValueIsFilled(FillingData) Then
		Return;
	EndIf;

	ContractDetails_ = LeasedAssetAccountingInternal.CheckDetailsOfLeaseAgreement(FillingData);
	
	If ContractDetails_ = Undefined Then
		Return;
	EndIf;
	
	If Not ContractDetails_.ThereIsBuyoutOfLeasedAssets Then
		ErrorText = NStr("vi = 'Hợp đồng không xem xét mua lại TSCĐ đã thuê, không thể tạo chứng từ.';
						|ru = 'Договором не предусмотрен выкуп арендованных ОС, создание документа недоступно.';
						|en = 'The contract does not provide for the purchase of leased assets; document creation is not available.'; fa = 'The contract does not provide for the purchase of leased assets; document creation is not available.';
						|it = 'In base all''accordo non è previsto il rimborso delle immobilizzazioni in affitto, impossibile creare il documento.';
						|pl = 'W umowie nie jest przewidziany wykup wynajmowanych środków trwałych, utworzenie dokumentu jest niedostępne.';
						|tr = 'Sözleşme, kiralanan işletim sistemlerinin itfa edilmesini sağlamaz, bir belgenin oluşturulması mevcut değildir.'");
		Raise ErrorText
	EndIf;
	
	Organization = ContractDetails_.Organization;
	Partner = ContractDetails_.Partner;
	Counterparty = ContractDetails_.Counterparty;
	VATTaxation = ContractDetails_.VATTaxation;
	Contract = FillingData;
	
	Documents.VendorInvoiceLeasedAssets.FillInBasedOnLeaseAgreement(ThisObject);
	
EndProcedure

Procedure FillInOnBasisOfRentalTermsADJUSTMENTChanges(Basis)

	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;

	ErrorText = Documents.VendorInvoiceLeasedAssets.FillInOnBasisOfRentalTermsADJUSTMENTChanges(ThisObject, Basis);
	
	If ErrorText <> Undefined Then
		Raise ErrorText;
	EndIf;
	
EndProcedure

#EndRegion

#Region AccountingMechanisms

Procedure AccountingMechanismsBeforeWrite(Cancel, WriteMode, PostingMode)
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(FA, PriceIncludesVAT);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA,PrepaymentsSettlement");
	
	// ARAPAccounting
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	// S/f
	RegistrationParameters = Documents.VendorInvoiceLeasedAssets.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	// Expense items
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoiceLeasedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure AccountingMechanismsFillingProcessing(FillingData)
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoiceLeasedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FillParameters = Documents.VendorInvoiceLeasedAssets.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	FillParameters = Documents.VendorInvoiceLeasedAssets.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization);
	
EndProcedure

Procedure AccountingMechanismsHandlingFillVerification(Cancel, CheckedAttributes)

	CheckParameters = Documents.VendorInvoiceLeasedAssets.VerificationParametersFillingInDocumentOnVATTaxationPurchases(ThisObject);
	VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation(ThisObject, VATTaxation, CheckParameters, Cancel);
	
	CheckParameters = Documents.VendorInvoiceLeasedAssets.ParametersForCheckingDocumentFillingByTypeOfActivity(ThisObject);
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(ThisObject, PurchaseForActivity, CheckParameters, Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoiceLeasedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure AccountingMechanismsForConducting()
	
	RegistrationParameters = Documents.VendorInvoiceLeasedAssets.ParametersForRegisteringInvoicesReceived(ThisObject); 
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
	// We will restore VAT based on the results of the offset of the security payment
	ChangesTable = VATAccountingERP.NewCalculationChangeTable();
	ChangesRow = ChangesTable.Add();
	ChangesRow.Document = Ref;
	ChangesRow.Period = Date;
	Documents.ReceivedTaxInvoicePrepayment.CreateTasksForGeneratingVATRegisteredRecords(ChangesTable);
	
EndProcedure

Procedure AccountingMechanismsForDataDeletion()
	
	RegistrationParameters = Documents.VendorInvoiceLeasedAssets.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
	// We will restore VAT based on the results of the offset of the security payment
	ChangesTable = VATAccountingERP.NewCalculationChangeTable();
	ChangesRow = ChangesTable.Add();
	ChangesRow.Document = Ref;
	ChangesRow.Period = Date;
	Documents.ReceivedTaxInvoicePrepayment.CreateTasksForGeneratingVATRegisteredRecords(ChangesTable);
	
EndProcedure

#EndRegion

#Region Other

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_RedemptionOfLeasedFA(ThisObject, AuxiliaryAttributes);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "FA,PrepaymentsSettlement");

EndProcedure

Function AuxiliaryAttributes()
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", True);
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	AuxiliaryAttributes.Insert("ThereIsReflectionOfExpensesTA", True);
	
	If ValueIsFilled(Contract) Then
		ContractDetails_ = Common.ObjectAttributesValues(Contract, "AssetHolder");
	Else
		ContractDetails_ = New Structure("AssetHolder", Undefined);
	EndIf;
	AuxiliaryAttributes.Insert("AssetHolder", ContractDetails_.AssetHolder);
	
	VendorInvoiceLeasedAssetsLocalization.AddAuxiliaryDetails(AuxiliaryAttributes, ThisObject);
	
	Return AuxiliaryAttributes;

EndFunction

Procedure CheckPossibilityOfRedemption(Cancel) Export
	
	If Not ValueIsFilled(Organization)
		Or Not ValueIsFilled(Contract) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	FATable.LineNumber,
	|	FATable.FixedAsset AS FixedAsset
	|INTO FATable
	|FROM
	|	&FATable AS FATable
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|WHERE
	|	LeaseContract.Ref = &Contract
	|	AND NOT LeaseContract.ThereIsBuyoutOfLeasedAssets
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FATable.LineNumber,
	|	OrganizationSCat.Presentation AS OrganizationPresentation,
	|	FATable.FixedAsset.Presentation AS FixedAssetPresentation
	|FROM
	|	FATable AS FATable
	|
	|		LEFT JOIN Catalog.LeaseContract AS LeaseContract
	|		ON LeaseContract.Ref = &Contract
	| 
	|		LEFT JOIN Catalog.Companies AS OrganizationSCat
	|		ON OrganizationSCat.Ref = &Organization
	| 
	|		LEFT JOIN InformationRegister.LeasedAsset.SliceLast(
	|			&Date, 
	|			Recorder <> &Ref
	|			AND FixedAsset IN
	|				(SELECT
	|					FATable.FixedAsset
	|				FROM
	|					FATable AS FATable)) AS LeasedAsset
	|		ON LeasedAsset.FixedAsset = FATable.FixedAsset
	|			AND LeasedAsset.State = VALUE(Enum.FixedAssetsStates.InLease)
	|WHERE
	|	LeaseContract.ThereIsBuyoutOfLeasedAssets
	|	AND LeasedAsset.FixedAsset IS NULL";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("FATable", FA.Unload());
	
	Result = Query.ExecuteBatch();

	Selection = Result[Result.UBound()-1].Select();
	If Selection.Next() Then
		MessageText = StrTemplate(NStr("vi = 'Theo hợp đồng ""%1"" không cho phép mua lại TSCĐ đã thuê';
										|ru = 'По договору ""%1"" не предусмотрен выкуп арендованных ОС';
										|en = 'The contract ""%1"" does not provide for the purchase of leased assets'; fa = 'The contract ""%1"" does not provide for the purchase of leased assets';
										|it = 'Non è previsto il rimborso delle immobilizzazioni per l''accordo ""%1""';
										|pl = 'Dla umowy ""%1"" nie jest przewidziany wykup wynajmowanych środków trwałych';
										|tr = '""%1"" anlaşması kiralanan maddi duran varlıkların geri alınmasını öngörmemektedir'"), String(Contract));
		Common.MessageToUser(MessageText, ThisObject, "Contract",, Cancel);
	EndIf;
	
	MessageTemplate = NStr("vi = 'Theo tài sản cố định ""%1"" không thể lập chứng từ mua lại, bởi vì tài sản này chưa được tiếp nhận vào kế toán trong doanh nghiệp %2';
							|ru = 'По основному средству ""%1"" не может быть оформлен выкуп, т.к. оно не было принято к учету в организации %2';
							|en = 'Redemption of fixed asset ""%1"" cannot be registered because it has not been recognized by the company %2'; fa = 'Redemption of fixed asset ""%1"" cannot be registered because it has not been recognized by the company %2';
							|it = 'Il rimborso non può essere effettuato per l''immobilizzazione ""%1"", poiché non è stata ricevuta in contabilità nell''organizzazione %2';
							|pl = 'Dla środka trwałego ""%1"" nie może być utworzony wykup, ponieważ on nie był przyjęty do ewidencji w firmie %2';
							|tr = '""%1"" sabit kıymeti, %2 iş yerinde muhasebeleştirilmediği için itfa edilemez.'");
	Selection = Result[Result.UBound()].Select();
	While Selection.Next() Do
		MessageText = StrTemplate(MessageTemplate, Selection.FixedAssetPresentation, Selection.OrganizationPresentation);
		Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "FixedAsset");
		Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
	EndDo;
	
EndProcedure

Procedure CheckOffsettingAdvances(Cancel)
	
	MessageTemplate = NStr("vi = 'Chưa điền cột ""Chứng từ hạch toán"" tại dòng %1 của danh sách ""Khấu trừ ứng trước""';
							|ru = 'Не заполнена колонка ""Расчетный документ"" в строке %1 списка ""Зачет авансов""';
							|en = 'The ""AR/AP document"" column in line %1 of the ""Applying prepayments"" list is not filled in'; fa = 'The ""AR/AP document"" column in line %1 of the ""Applying prepayments"" list is not filled in';
							|it = 'Colonna ""Documento di calcolo"" non compilata nella riga %1 dell''elenco ""Compensazione degli anticipi""';
							|pl = 'Nie wypełniono kolumny ""Dokument rozliczeniowy"" w wierszu %1 listy ""Rozliczenia z partnerami""';
							|tr = '""Avans mahsubu"" listesinin %1 satırındaki ""Mahsup belgesi"" sütunu doldurulmamış'");
	
	For Each RowData In PrepaymentsSettlement Do
		
		If Not ValueIsFilled(RowData.ARAPDocument)
			And (RowData.PaymentType = Enums.TypesOfLeasePayments.DepositPayment
				Or RowData.PaymentType = Enums.TypesOfLeasePayments.BuyoutValuePrepayment) Then
					
			MessageText = StrTemplate(MessageTemplate, String(RowData.LineNumber));
			Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure
#EndRegion

#EndRegion

#EndIf
