
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData, StandardProcessing);
	ElsIf FillInDataType = Type("CatalogRef.LeaseContract") Then
		FillInBasedOnLeaseAgreement(FillingData);
	EndIf;
	
	InitializeDocument();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Comment = "";
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");

	InitializeDocument();

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	FillInBankingDetailsBeforeWrite(WriteMode);
	
	If Not Cancel And WriteMode = DocumentWriteMode.Posting Then
		NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
		Documents.LeaseTermAdjustment.CheckRelevanceOfLeaseContract(Ref, Contract, NewContract, Date, Cancel);
	EndIf;

	CreatedForTransition = LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Date, Organization);

	ItemsAndDimensionsSelectionParameters = Documents.LeaseTermAdjustment.ItemsAndDimensionsSelectionParameters(CreatedForTransition);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	GLAccountSettingsServer.BeforeWrite(ThisObject, Documents.LeaseTermAdjustment.AccountingAccountSettings_());
		
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("FA.CostInAccounting");
	NotCheckedAttributeArray.Add("FA.CostInManagementAccounting");
	NotCheckedAttributeArray.Add("FA.CostInTaxAccounting");
	NotCheckedAttributeArray.Add("FA.UsefulLifeManagementAccounting");
	NotCheckedAttributeArray.Add("FA.Department");
	NotCheckedAttributeArray.Add("FA.ExpenseItem");
	NotCheckedAttributeArray.Add("FA.FairValue");
	NotCheckedAttributeArray.Add("FA.BuyoutValue");
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	LeasedAssetAccounting.CheckReturnFromSublease(ThisObject, Cancel, True);
	
	ItemDetailsParameters = 
		LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_ChangesInTermsOfLeaseAgreement(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckFixedAssets(AuxiliaryAttributes, Cancel);
	
	CreatedForTransition = LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Date, Organization);
	
	ItemsAndDimensionsSelectionParameters = Documents.LeaseTermAdjustment.ItemsAndDimensionsSelectionParameters(CreatedForTransition);
	
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	LeasedAssetAccounting.CheckLeaseDocument(ThisObject, AuxiliaryAttributes, NotCheckedAttributeArray, Cancel);
	
	LeaseTermAdjustmentLocalization.FillCheckProcessing(ThisObject, AuxiliaryAttributes, NotCheckedAttributeArray, Cancel);
	
	CheckContractChange(NotCheckedAttributeArray);
	
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

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.ProcessTSString(ThisObject, StructureOfActions, CachedValues);
	
	If CachedValues.ProcessedRows.Count() Then
		LeasedAssetAccountingClientServer.RecalculateAmountOfRentalDocument(ThisObject);
		LeasedAssetAccountingClientServer.RecalculateAmountOfNDSInLeaseDocument(ThisObject);
	EndIf;
	
	CreatedForTransition = LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Date, Organization);
	
	ItemsAndDimensionsSelectionParameters = Documents.LeaseTermAdjustment.ItemsAndDimensionsSelectionParameters(CreatedForTransition);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
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
	
	Organization = ContractDetails_.Organization;
	Partner = ContractDetails_.Partner;
	Counterparty = ContractDetails_.Counterparty;
	Contract = FillingData;
	
	Documents.LeaseTermAdjustment.FillInBasedOnLeaseAgreement(ThisObject);
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInBankingDetailsBeforeWrite(WriteMode)

	AuxiliaryAttributes = AuxiliaryAttributes();

	ClearUnusedProps(AuxiliaryAttributes);

	DocumentAmount = AmountIncludingVAT;
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		Documents.LeaseTermAdjustment.CalculateRateCostInterest(
			ThisObject, AuxiliaryAttributes.ContractDetails_);
		CalculateCostOfFA(AuxiliaryAttributes.ContractDetails_);
		
	EndIf;
	
	LeaseItemsCost
		= LeasedAssetAccountingClientServer.LeaseItemsCost(ThisObject, AuxiliaryAttributes.ContractDetails_, "FA");
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
EndProcedure

Procedure ClearUnusedProps(AuxiliaryAttributes)
	
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_ChangesInTermsOfLeaseAgreement(
		ThisObject, AuxiliaryAttributes);
	
	TMCommonUseClientServer.ClearUnusedProps(
		ThisObject, 
		ItemDetailsParameters, 
		"FA,ServicePaymentSchedule,ServiceAccrualSchedule,InterestAccrualSchedule");

EndProcedure

Function AuxiliaryAttributes()

	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("VNAManagementIsUsed_2_4", NonCurrentAssets.VNAManagementIsUsed_2_4(Date));
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Organization, Date, True));
	AuxiliaryAttributes.Insert("StartOfLeaseAccountingUnderFSB25_2018", LeasedAssetAccounting.StartOfLeaseAccountingUnderFSB25_2018(Organization));
	AuxiliaryAttributes.Insert("InsignificantVATRate", VATAccountingERP.InsignificantRate(VATRate));
	AuxiliaryAttributes.Insert("RecordInOperationalAccounting", True);
	AuxiliaryAttributes.Insert("DocumentVersion24", False);
	AuxiliaryAttributes.Insert("NameOfFATablePart", "FA");
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	AuxiliaryAttributes.Insert("CurrencyOfMan", CurrencyOfMan);
	AuxiliaryAttributes.Insert("ComplCurrency", ComplCurrency);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);

	AuxiliaryAttributes.Insert("ContractDetails_", LeasedAssetAccounting.DetailsOfLeaseAgreement(Contract));

	Return AuxiliaryAttributes;
	
EndFunction

Procedure CheckFixedAssets(AuxiliaryAttributes, Cancel)
	
	OnlyTerminationOfFALease = True;
	OnlyPurchaseOfVendorInvoiceLeasedAssets = True;

	ListOfFA = New Array;
	For Each RowData In FA Do
		
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
			
			If RowData.ActionWithRentalObject <> Enums.ActionsWithRentalObjects.RentalTermination
				And RowData.ActionWithRentalObject <> Enums.ActionsWithRentalObjects.EarlyRedemption Then
				OnlyTerminationOfFALease = False;
			EndIf;
			If RowData.ActionWithRentalObject <> Enums.ActionsWithRentalObjects.EarlyRedemption Then
				OnlyPurchaseOfVendorInvoiceLeasedAssets = False;
			EndIf;
			
		EndIf;

	EndDo;
	
	If ListOfFA.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = LeaseTermAdjustmentLocalization.RequestTextForCheckingFixedAssets();
	
	If QueryText = Undefined Then
		QueryText = 
		"SELECT
		|	FATable.LineNumber AS LineNumber,
		|	FATable.FixedAsset AS FixedAsset,
		|	FATable.ActionWithRentalObject AS ActionWithRentalObject,
		|	FATable.Department AS Department,
		|	FATable.ExpenseItem AS ExpenseItem,
		|	FATable.FairValue AS FairValue,
		|	FATable.UsefulLifeAccounting AS UsefulLifeAccounting,
		|	FATable.UsefulLifeManagementAccounting AS UsefulLifeManagementAccounting,
		|	FATable.Sublease AS Sublease
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
		|	CheckResult.LineNumber AS LineNumber,
		|	CheckResult.FixedAsset AS FixedAsset,
		|	CheckResult.DivisionNotFilledIn AS DivisionNotFilledIn,
		|	CheckResult.ExpenseItemIsNotFilledIn AS ExpenseItemIsNotFilledIn,
		|	CheckResult.FairCostIsNotFilledIn AS FairCostIsNotFilledIn,
		|	CheckResult.TermOfUseOfBUIsNotFilledIn AS TermOfUseOfBUIsNotFilledIn,
		|	CheckResult.MaUsagePeriodNotCompleted AS MaUsagePeriodNotCompleted
		|FROM
		|	(SELECT
		|		FATable.LineNumber AS LineNumber,
		|		FATable.FixedAsset AS FixedAsset,
		|		(FATable.ActionWithRentalObject = VALUE(Enum.ActionsWithRentalObjects.Rent)
		|			OR (FATable.Sublease AND &ContractType = VALUE(Enum.TypesOfLeaseContracts.Lease)))
		|			AND FATable.Department = VALUE(Catalog.BusinessStructure.EmptyRef) AS DivisionNotFilledIn,
		|		(FATable.ActionWithRentalObject = VALUE(Enum.ActionsWithRentalObjects.Rent)
		|			OR (FATable.Sublease AND &ContractType = VALUE(Enum.TypesOfLeaseContracts.Lease)))
		|			AND FATable.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemIsNotFilledIn,
		|		FATable.ActionWithRentalObject IN (
		|			VALUE(Enum.ActionsWithRentalObjects.RentalTermsAdjustment),
		|			VALUE(Enum.ActionsWithRentalObjects.RentalTermination))
		|			AND &ContractType = VALUE(Enum.TypesOfLeaseContracts.Lease)
		|			AND FATable.FairValue = 0 AS FairCostIsNotFilledIn,
		|
		|		ISNULL(AccountingProcedureForOSBU.BUState, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_)
		|			AND FATable.UsefulLifeAccounting = 0 AS TermOfUseOfBUIsNotFilledIn,
		|
		|		ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_)
		|			AND FATable.UsefulLifeManagementAccounting = 0 AS MaUsagePeriodNotCompleted
		|	FROM
		|		FATable AS FATable
		|
		|			LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
		|				&Date, 
		|				CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN
		|						(SELECT
		|							FixedAsset
		|						FROM
		|							FATable)) AS AccountingProcedureForOSBU
		|				ON AccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
		|
		|			LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
		|				&Date,
		|				CorrectionDate = DATETIME(1,1,1) 
		|					AND Organization = &Organization
		|					AND FixedAsset IN
		|						(SELECT
		|							FixedAsset
		|						FROM
		|							FATable)) AS FixedAssetsAccountingProcedureManagementAccounting
		|			ON FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = FATable.FixedAsset
		|
		|	) AS CheckResult
		|
		|WHERE
		|	(CheckResult.TermOfUseOfBUIsNotFilledIn
		|		OR CheckResult.MaUsagePeriodNotCompleted
		|		OR CheckResult.DivisionNotFilledIn
		|		OR CheckResult.ExpenseItemIsNotFilledIn
		|		OR CheckResult.FairCostIsNotFilledIn)
		|
		|ORDER BY
		|	LineNumber";
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("FATable", FA.Unload());
	Query.SetParameter("LeaseAccountingAccordingToFSB25_2018IsUsed", AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed);
	Query.SetParameter("CurrenciesDoNotMatch", AuxiliaryAttributes.CurrenciesDoNotMatch);
	Query.SetParameter("ContractType", AuxiliaryAttributes.ContractDetails_.ContractType);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	TemplateOfMessageIsTermOfUseOfBU = NStr("vi = 'Chưa điền cột ""Thời hạn sử dụng (kế toán doanh nghiệp)"" tại dòng %1 trong danh sách ""Đối tượng thuê""';
											|ru = 'Не заполнена колонка ""Срок использования (бухгалтерский учет)"" в строке %1 списка ""Предметы аренды""';
											|en = '""Useful life (local accounting)"" column in line %1 of the ""Rental objects"" list is not filled'; fa = '""Useful life (local accounting)"" column in line %1 of the ""Rental objects"" list is not filled';
											|it = 'Non è compilata la colonna ""Periodo di utilizzo (contabilità)"" nella riga %1 dell''elenco ""Elementi di affitto""';
											|pl = 'Nie wypełniono kolumny ""Okres używania (ewidencja księgowa)"" w wierszu %1 listy ""Przedmioty dzierżawy""';
											|tr = '""Kira kalemleri"" listesinin %1 satırındaki ""Kullanım süresi (genel muhasebe)"" sütunu doldurulmamış'");
	MessageTemplateMaUsagePeriod = NStr("vi = 'Chưa điền cột ""Thời hạn sử dụng (kế toán quản trị) tại dòng %1 của danh sách ""Đối tượng thuê""';
										|ru = 'Не заполнена колонка ""Срок использования (управленческий учет)"" в строке %1 списка ""Предметы аренды""';
										|en = 'The ""Term of use (management accounting)"" column in line %1 of the list ""Rental objects"" is not filled in'; fa = 'The ""Term of use (management accounting)"" column in line %1 of the list ""Rental objects"" is not filled in';
										|it = 'Colonna ""Periodo di utilizzo (Contabilità gestionale)"" non compilata nella riga %1 dell''elenco ""Elementi di affitto""';
										|pl = 'Nie wypełniono kolumny ""Okres używania (ewidencja zarządcza)"" w wierszu %1 listy ""Przedmioty dzierżawy""';
										|tr = '""Kira kalemleri"" listesinin %1 satırındaki ""Kullanım süresi (yönetim muhasebesi)"" sütunu doldurulmamış'");
	DivisionMessageTemplate = NStr("vi = 'Chưa điền cột ""Bộ phận"" tại dòng %1 của danh sách ""Đối tượng thuê""';
									|ru = 'Не заполнена колонка ""Подразделение"" в строке %1 списка ""Предметы аренды""';
									|en = 'The Business unit column is not filled in line %1 of the Rental objects list'; fa = 'The Business unit column is not filled in line %1 of the Rental objects list';
									|it = 'Не заполнена колонка ""Подразделение"" в строке %1 списка ""Предметы аренды""';
									|pl = 'The Business unit column is not filled in line %1 of the Rental objects list';
									|tr = '""Kiralanan varlıklar"" listesinin %1 satırındaki ""Departman"" sütunu doldurulmadı'");
	MessageTemplateExpenseItem = NStr("vi = 'Chưa điền cột ""Dạng chi phí"" tại dòng %1 của danh sách ""Đối tượng thuê""';
										|ru = 'Не заполнена колонка ""Статья расходов"" в строке %1 списка ""Предметы аренды""';
										|en = 'The Expense item column is not filled in line %1 of the Rental objects list'; fa = 'The Expense item column is not filled in line %1 of the Rental objects list';
										|it = 'Не заполнена колонка ""Статья расходов"" в строке %1 списка ""Предметы аренды""';
										|pl = 'The Expense item column is not filled in line %1 of the Rental objects list';
										|tr = '""Kiralanan varlıklar"" listesinin %1 satırındaki ""Gider kalemi"" sütunu doldurulmadı'");
	MessageTemplateFairCost = NStr("vi = 'Chưa điền cột ""Giá trị hợp lý"" tại dòng %1 của danh sách ""Đối tượng thuê""';
									|ru = 'Не заполнена колонка ""Справедливая стоимость"" в строке %1 списка ""Предметы аренды""';
									|en = 'The Fair value column is not filled in line %1 of the Rental objects list'; fa = 'The Fair value column is not filled in line %1 of the Rental objects list';
									|it = 'Не заполнена колонка ""Справедливая стоимость"" в строке %1 списка ""Предметы аренды""';
									|pl = 'The Fair value column is not filled in line %1 of the Rental objects list';
									|tr = '""Kiralanan varlıklar"" listesinin %1 satırındaki ""Makul değer"" sütunu doldurulmadı'");
	
	If OnlyTerminationOfFALease And Not OnlyPurchaseOfVendorInvoiceLeasedAssets Then
		MessageText = NStr("vi = 'Không thể có hợp đồng thuê nếu không có các đối tượng thuê. Nghiệp vụ như vậy được lập bởi chứng từ “Chấm dứt hợp đồng thuê”';
							|ru = 'Не может быть договора аренды без предметов аренды. Такая операция оформляется документом ""Прекращение договора аренды""';
							|en = 'A rental contract must contain at least one rental object. Such operation is registered with the Rental termination document'; fa = 'A rental contract must contain at least one rental object. Such operation is registered with the Rental termination document';
							|it = 'Не может быть договора аренды без предметов аренды. Такая операция оформляется документом ""Прекращение договора аренды""';
							|pl = 'A rental contract must contain at least one rental object. Such operation is registered with the Rental termination document';
							|tr = 'Kiralanan varlıklar olmadan kira sözleşmesi yapılamaz. Böyle bir işlem ""Kira feshi"" belgesi ile resmileştirilir.'");
		Common.MessageToUser(MessageText, ThisObject, "FA", "", Cancel);
	EndIf;
	
	If OnlyPurchaseOfVendorInvoiceLeasedAssets Then
		MessageText = NStr("vi = 'Để mua lại đầy đủ đối tượng thuê, cần sử dụng chứng từ ""Mua lại TSCĐ hữu hình đã thuê""';
							|ru = 'Для полного выкупа преметов аренды необходимо использовать документ ""Выкуп арендованных ОС""';
							|en = 'For the full redemption of rental objects, use the Vendor invoice — Leased assets document'; fa = 'For the full redemption of rental objects, use the Vendor invoice — Leased assets document';
							|it = 'Для полного выкупа преметов аренды необходимо использовать документ ""Выкуп арендованных ОС""';
							|pl = 'For the full redemption of rental objects, use the Vendor invoice — Leased assets document';
							|tr = 'Kiralanan varlıkların tam itfası için ""Satıcı faturası - Kiralanan varlıklar"" belgesinin kullanılması gerekmektedir.'");
		Common.MessageToUser(MessageText, ThisObject, "FA", "", Cancel);
	EndIf;
	
	While Selection.Next() Do
	
		If Selection.TermOfUseOfBUIsNotFilledIn Then
			MessageText = StrTemplate(TemplateOfMessageIsTermOfUseOfBU, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "UsefulLifeAccounting");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
	
		If Selection.MaUsagePeriodNotCompleted Then
			MessageText = StrTemplate(MessageTemplateMaUsagePeriod, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "UsefulLifeManagementAccounting");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
		
		If Selection.DivisionNotFilledIn Then
			MessageText = StrTemplate(DivisionMessageTemplate, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "Department");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
		
		If Selection.ExpenseItemIsNotFilledIn Then
			MessageText = StrTemplate(MessageTemplateExpenseItem, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "ExpenseItem");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
		
		If Selection.FairCostIsNotFilledIn Then
			MessageText = StrTemplate(MessageTemplateFairCost, Selection.LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "FairValue");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
		
		LeaseTermAdjustmentLocalization.ReportInspectionOfFixedAssets(Selection, ThisObject, Cancel);
		
	EndDo;
	
EndProcedure

Procedure CheckContractChange(NotCheckedAttributeArray)
	
	ArrayOfControlledDetails = New Array;
	ArrayOfControlledDetails.Add("NewContract");
	ArrayOfControlledDetails.Add("NewCounterparty");
	ArrayOfControlledDetails.Add("NewPartner");
	
	ItIsNecessaryToCheck = False;
	For Each AttributeToControl In ArrayOfControlledDetails Do
		If ValueIsFilled(ThisObject[AttributeToControl]) Then
			ItIsNecessaryToCheck = True;
		EndIf;
	EndDo;
	
	If Not ItIsNecessaryToCheck Then
		For Each AttributeToControl In ArrayOfControlledDetails Do
			NotCheckedAttributeArray.Add(AttributeToControl);
		EndDo;
	EndIf;
	
EndProcedure

Procedure CalculateCostOfFA(ContractDetails_) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("FATable", FA.Unload(
		, "FixedAsset, ActionWithRentalObject, Cost, FairValue, NonGuaranteedFinalCost"));
	Query.SetParameter("ThisIsLeasing", ContractDetails_.ContractType
		= Enums.TypesOfLeaseContracts.Leasing);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Period", Date);
	Query.SetParameter("PeriodLimit", New Boundary(PointInTime(), BoundaryType.Excluding));
	Query.SetParameter("Organization", Organization);

	Query.Text =
	"SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.ActionWithRentalObject AS ActionWithRentalObject,
	|	CASE
	|		WHEN &ThisIsLeasing
	|			THEN FATable.Cost
	|		ELSE FATable.FairValue
	|	END AS Cost
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
	|	FACostBalance.FixedAsset AS FixedAsset,
	|	FACostBalance.CostBalance AS CostInManagementAccounting,
	|	FACostBalance.LocalCostBalance + FACostBalance.CostTargetFinancingBalance AS CostInAccounting,
	|	FACostBalance.CostInTaxAccountingBalance AS CostInTaxAccounting
	|INTO FACost
	|FROM
	|	AccumulationRegister.FACost.Balance(
	|			&PeriodLimit,
	|			Organization = &Organization
	|				AND FixedAsset IN
	|					(SELECT
	|						FATable.FixedAsset
	|					FROM
	|						FATable AS FATable)) AS FACostBalance
	|
	|INDEX BY
	|	FixedAsset";
	Query.Execute();
	
	If ContractDetails_.MethodForDeterminingCostOfAssets =
		Enums.MethodsOfDeterminingLeasedAssetCost.Manually Then
		
		Query.Text =
		"SELECT
		|	FATable.FixedAsset AS FixedAsset,
		|	ISNULL(FACost.CostInManagementAccounting, 0) AS CostInManagementAccounting,
		|	ISNULL(FACost.CostInAccounting, 0) AS CostInAccounting,
		|	ISNULL(FACost.CostInTaxAccounting, 0) AS CostInTaxAccounting
		|FROM
		|	FATable AS FATable
		|		LEFT JOIN FACost AS FACost
		|		ON FATable.FixedAsset = FACost.FixedAsset";
		
	Else
		
		ArrayOfContracts = LeasedAssetAccounting.RelatedLeaseContracts(Contract);
		Query.SetParameter("ArrayOfContracts", ArrayOfContracts);
		
		FATable = CostChangeTable(Query);
		
		Query.SetParameter("FATable", FATable);
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Currency, ARAPCurrency, Date, Organization);
		Query.SetParameter("ConversionRateToManCurrency", Coefficients.ConversionRateToManCurrency);
		Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
		
		LeaseAccountingAccordingToFSB25_2018IsUsed =
		LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Organization, Date, True);
		AccountingParametersForRentalItems = LeasedAssetAccountingClientServer.AccountingParametersForRentalItems(
			LeaseAccountingAccordingToFSB25_2018IsUsed, ContractDetails_);
		
		Query.SetParameter("ThereIsMaAccount", AccountingParametersForRentalItems.ThereIsMaAccount);
		Query.SetParameter("ThereIsACAccounting", AccountingParametersForRentalItems.ThereIsACAccounting);
		Query.SetParameter("ThereIsAccountingTa", AccountingParametersForRentalItems.ThereIsAccountingTa);
		
		Query.SetParameter(
			"RoundingThreshold", Documents.LeaseTermAdjustment.ThresholdForRoundingChangesInPresentValue());
		
		Query.Text = 
		"SELECT
		|	TTChangeInFACost.FixedAsset AS FixedAsset,
		|	CASE
		|		WHEN TTChangeInFACost.Sum > 0
		|					AND TTChangeInFACost.Sum >= &RoundingThreshold
		|				OR TTChangeInFACost.Sum < 0
		|					AND TTChangeInFACost.Sum <= -&RoundingThreshold
		|			THEN TTChangeInFACost.Sum
		|		ELSE 0
		|	END AS Sum
		|INTO TTChangeInCostOfFAPreliminary
		|FROM
		|	&FATable AS TTChangeInFACost
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ChangeInCostOfFA.FixedAsset AS FixedAsset,
		|	CASE
		|		WHEN &ThereIsMaAccount
		|			THEN ChangeInCostOfFA.Sum * &ConversionRateToManCurrency
		|		ELSE 0
		|	END AS AmountOfUU,
		|	CASE
		|		WHEN &ThereIsACAccounting
		|			THEN ChangeInCostOfFA.Sum * &FactorOfConversionToCurrencyOfRegul
		|		ELSE 0
		|	END AS AmountAccounting,
		|	CASE
		|		WHEN &ThereIsAccountingTa
		|			THEN ChangeInCostOfFA.Sum * &FactorOfConversionToCurrencyOfRegul
		|		ELSE 0
		|	END AS AmountFA
		|INTO TTChangeInFACost
		|FROM
		|	TTChangeInCostOfFAPreliminary AS ChangeInCostOfFA
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|SELECT TOP 1
		|	TermsOfLeaseContracts.Recorder AS Ref,
		|	TermsOfLeaseContracts.Period AS Period
		|INTO TTPreviousDocumentChanges
		|FROM
		|	InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseContracts
		|WHERE
		|	TermsOfLeaseContracts.Period BETWEEN BEGINOFPERIOD(&Period, MONTH) AND &Period
		|	AND TermsOfLeaseContracts.Recorder REFS Document.LeaseTermAdjustment
		|	AND TermsOfLeaseContracts.Recorder <> &Ref
		|	AND TermsOfLeaseContracts.State = VALUE(Enum.CounterpartyContractStates.Valid)
		|	AND TermsOfLeaseContracts.Active
		|	AND TermsOfLeaseContracts.Contract IN(&ArrayOfContracts)
		|
		|ORDER BY
		|	Period DESC
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PreviousFATable.FixedAsset AS FixedAsset,
		|	PreviousFATable.CostInAccounting AS CostInAccounting,
		|	PreviousFATable.CostInTaxAccounting AS CostInTaxAccounting,
		|	PreviousFATable.CostInManagementAccounting AS CostInManagementAccounting
		|INTO PreviousFATable
		|FROM
		|	Document.LeaseTermAdjustment.FA AS PreviousFATable
		|WHERE
		|	PreviousFATable.Ref IN
		|			(SELECT
		|				TTPreviousDocumentChanges.Ref AS Ref
		|			FROM
		|				TTPreviousDocumentChanges AS TTPreviousDocumentChanges)
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FATable.FixedAsset AS FixedAsset,
		|	CASE
		|		WHEN ISNULL(PreviousFATable.CostInManagementAccounting, ISNULL(FACost.CostInManagementAccounting, 0)) + ChangeInCostOfFA.AmountOfUU > 0
		|			THEN ISNULL(PreviousFATable.CostInManagementAccounting, ISNULL(FACost.CostInManagementAccounting, 0)) + ChangeInCostOfFA.AmountOfUU
		|		ELSE 0
		|	END AS CostInManagementAccounting,
		|	CASE
		|		WHEN ISNULL(PreviousFATable.CostInAccounting, ISNULL(FACost.CostInAccounting, 0)) + ChangeInCostOfFA.AmountAccounting > 0
		|			THEN ISNULL(PreviousFATable.CostInAccounting, ISNULL(FACost.CostInAccounting, 0)) + ChangeInCostOfFA.AmountAccounting
		|		ELSE 0
		|	END AS CostInAccounting,
		|	CASE
		|		WHEN ISNULL(PreviousFATable.CostInTaxAccounting, ISNULL(FACost.CostInTaxAccounting, 0)) + ChangeInCostOfFA.AmountFA > 0
		|			THEN ISNULL(PreviousFATable.CostInTaxAccounting, ISNULL(FACost.CostInTaxAccounting, 0)) + ChangeInCostOfFA.AmountFA
		|		ELSE 0
		|	END AS CostInTaxAccounting
		|FROM
		|	FATable AS FATable
		|		LEFT JOIN TTChangeInFACost AS ChangeInCostOfFA
		|		ON FATable.FixedAsset = ChangeInCostOfFA.FixedAsset
		|		LEFT JOIN PreviousFATable AS PreviousFATable
		|		ON FATable.FixedAsset = PreviousFATable.FixedAsset
		|		LEFT JOIN FACost AS FACost
		|		ON FATable.FixedAsset = FACost.FixedAsset";
		
	EndIf;
	
	Selection = Query.Execute().Select();

	While Selection.Next() Do
		FAString = FA.Find(Selection.FixedAsset, "FixedAsset");
		FillPropertyValues(FAString, Selection, "CostInManagementAccounting, CostInAccounting, CostInTaxAccounting");
	EndDo;
	
EndProcedure

Function CostChangeTable(Query)
	
	Query.Text = 
	"SELECT TOP 1
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TermsOfLeaseContracts.LeaseStartDate AS LeaseStartDate,
	|	TermsOfLeaseContracts.InterestRate AS InterestRate,
	|	TermsOfLeaseContracts.Period AS Period
	|INTO TTPreviousConditions
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceLast(
	|			&Period,
	|			Recorder <> &Ref
	|				AND Contract IN (&ArrayOfContracts)
	|				AND State = VALUE(Enum.CounterpartyContractStates.Valid)) AS TermsOfLeaseContracts
	|ORDER BY
	|	Period DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(LeaseServicesPaymentSchedule.RentalService
	|		- LeaseServicesPaymentSchedule.RentalServiceVAT
	|		+ LeaseServicesPaymentSchedule.DepositPayment
	|		- LeaseServicesPaymentSchedule.SecurityPaymentVATAmount
	|		+ LeaseServicesPaymentSchedule.BuyoutValue
	|		+ LeaseServicesPaymentSchedule.BuyoutValuePrepayment
	|		- LeaseServicesPaymentSchedule.BuyoutValueVAT) AS Sum
	|INTO PaymentBalancesTT
	|FROM
	|	TTPreviousConditions AS TTPreviousConditions
	|		INNER JOIN InformationRegister.LeaseServicesPaymentSchedule AS LeaseServicesPaymentSchedule
	|		ON TTPreviousConditions.EffectiveContractTerms = LeaseServicesPaymentSchedule.EffectiveContractTerms
	|			AND (LeaseServicesPaymentSchedule.Date >= BEGINOFPERIOD(&Period, DAY))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM( LeaseServicesAccrualSchedule.DepositPayment
	|		- LeaseServicesAccrualSchedule.SecurityPaymentVATAmount) AS DepositPayment
	|INTO AccrualBalancesTT
	|FROM
	|	TTPreviousConditions AS TTPreviousConditions
	|		INNER JOIN InformationRegister.LeaseServicesAccrualSchedule AS LeaseServicesAccrualSchedule
	|		ON TTPreviousConditions.EffectiveContractTerms = LeaseServicesAccrualSchedule.EffectiveContractTerms
	|			AND (LeaseServicesAccrualSchedule.Date >= BEGINOFPERIOD(&Period, DAY))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InterestGraph.Interests AS Interests
	|INTO InterestGraph
	|FROM
	|	&InterestGraph AS InterestGraph
	|WHERE
	|	InterestGraph.Date >= DATEADD(BEGINOFPERIOD(&Period, DAY), DAY, -1)
	|		AND InterestGraph.Date < BEGINOFPERIOD(&Period, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(InterestGraph.InterestAmount) AS Sum
	|INTO TTInterestBalances
	|FROM
	|	(SELECT
	|		-ISNULL(InterestGraph.Interests, 0) AS InterestAmount
	|	FROM
	|		InterestGraph AS InterestGraph
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ISNULL(LeaseInterestAccrualSchedule.Interests, 0)
	|	FROM
	|		TTPreviousConditions AS TTPreviousConditions
	|			LEFT JOIN InformationRegister.LeaseInterestAccrualSchedule AS LeaseInterestAccrualSchedule
	|			ON TTPreviousConditions.EffectiveContractTerms = LeaseInterestAccrualSchedule.EffectiveContractTerms
	|				AND (LeaseInterestAccrualSchedule.Date >= DATEADD(BEGINOFPERIOD(&Period, DAY), DAY, -1))) AS InterestGraph
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(PaymentBalancesTT.Sum, 0)
	|		+ ISNULL(AccrualBalancesTT.DepositPayment, 0)
	|		- ISNULL(TTInterestBalances.Sum, 0) AS CostBalance,
	|	&PresentValue
	|		+ ISNULL(AccrualBalancesTT.DepositPayment, 0) AS Cost
	|FROM
	|	TTPreviousConditions AS TTPreviousConditions
	|		LEFT JOIN PaymentBalancesTT AS PaymentBalancesTT
	|		ON (TRUE)
	|		LEFT JOIN AccrualBalancesTT AS AccrualBalancesTT
	|		ON (TRUE)
	|		LEFT JOIN TTInterestBalances AS TTInterestBalances
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	0 AS Sum,
	|	CASE
	|		WHEN FATable.ActionWithRentalObject <> VALUE(Enum.ActionsWithRentalObjects.Rent)
	|			THEN FATable.Cost
	|		ELSE 0
	|	END AS BalanceDistributionCoefficient,
	|	CASE
	|		WHEN FATable.ActionWithRentalObject <> VALUE(Enum.ActionsWithRentalObjects.RentalTermination)
	|				AND FATable.ActionWithRentalObject <> VALUE(Enum.ActionsWithRentalObjects.EarlyRedemption)
	|			THEN FATable.Cost
	|		ELSE 0
	|	END AS CostSharingRatio
	|FROM
	|	FATable AS FATable";
	
	Query.SetParameter("InterestGraph", InterestAccrualSchedule.Unload());
	Query.SetParameter("PresentValue", PresentValue);
	
	Results = Query.ExecuteBatch();
	
	FATable = Results[Results.UBound()].Unload();
	
	Selection = Results[Results.UBound()-1].Select();
	Selection.Next();
	
	Coefficients = FATable.UnloadColumn("BalanceDistributionCoefficient");

	DistributionOfCostBalances = Common.DistributeAmountInProportionToCoefficients(
		Selection.CostBalance, Coefficients);

	Coefficients = FATable.UnloadColumn("CostSharingRatio");

	Allocation_Cost = Common.DistributeAmountInProportionToCoefficients(
		Selection.Cost, Coefficients);

	For RowIndex = 0 To FATable.Count()-1 Do
		
		RowData = FATable.Get(RowIndex);
		
		If Allocation_Cost <> Undefined Or DistributionOfCostBalances <> Undefined Then
			BalanceOfCostOfFA = ?(DistributionOfCostBalances <> Undefined, DistributionOfCostBalances[RowIndex], 0);
			FACost = ?(Allocation_Cost <> Undefined, Allocation_Cost[RowIndex], 0);
			RowData.Sum = FACost - BalanceOfCostOfFA;
		EndIf;
		
	EndDo;

	Return FATable;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
