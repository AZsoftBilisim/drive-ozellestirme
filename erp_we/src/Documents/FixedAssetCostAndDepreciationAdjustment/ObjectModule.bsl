
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillInSelectionDocument(FillingData);
		
	ElsIf FillInDataType = Type("CatalogRef.Assets") 
		Or FillInDataType = Type("Array")
			And FillingData.Count() <> 0
			And TypeOf(FillingData[0]) = Type("CatalogRef.Assets") Then
			
		FillOnBasisOfObjectsOfOperation(FillingData, Undefined);
		
	Else
		
		Documents.FixedAssetCostAndDepreciationAdjustment.FillInBasedOnDocument(ThisObject, FillingData);
		
	EndIf;
	
	FixedAssetCostAndDepreciationAdjustmentLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);
	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetCostAndDepreciationAdjustment.ItemsAndDimensionsSelectionParameters(ThisObject);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Comment = "";
	GeneratedDocument = False;
	DocumentBasis = Undefined;
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	
	AuxiliaryAttributes = Documents.FixedAssetCostAndDepreciationAdjustment.AuxiliaryAttributes(ThisObject);
	ItemDetailsParameters = NonCurrentAssetsClientServer.ValuesOfPropertiesOfDependentProps_AdjustmentOfCostAndDepreciationOfFA(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckDocument(NotCheckedAttributeArray, Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetCostAndDepreciationAdjustment.ItemsAndDimensionsSelectionParameters(ThisObject);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not Cancel And WriteMode = DocumentWriteMode.Posting Then
		
		BlockData_();
		
		If FixedAssetKind = Enums.PropertyKinds.Leased Then
			NonCurrentAssetsInternal.CheckThatFAIsLeasedForBalance(ThisObject, Cancel);
		Else
			NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
		EndIf;
		
	EndIf;
	
	FillInBankingDetailsBeforeWrite();
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetCostAndDepreciationAdjustment.ItemsAndDimensionsSelectionParameters(ThisObject);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.FixedAssetCostAndDepreciationAdjustment.AccountingAccountSettings_());
	
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

#Region FillType

Procedure InitializeDocumentBeforeFillingItOut()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	CostAdjustment = True;
	CostIncreaseRecording = True;
	BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease = True;
	
	AdjustmentOfInitialCost = True;
	
	DepreciationAdjustment = True;
	DepreciationIncreaseRecording = True;
	BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease = True;
	
	IncludesDepreciationOfCurrentMonth = False;
	AdjustmentOfDepreciationCalculationParameters = False;
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("FixedAsset") Then
		FillOnBasisOfObjectsOfOperation(Basis.FixedAsset, Basis);
	EndIf; 
	
	If Basis.Property("AdjustmentModeFromPreviousDate") Then
		
		AdjustmentModeFromPreviousDate = True;
		
		If Basis.Property("CorrectionPeriod_") Then
			CorrectionPeriod_ = Basis.CorrectionPeriod_; // StandardPeriod
			If CorrectionPeriod_.StartDate < BegOfMonth(CurrentSessionDate()) Then
				BeginOfPeriod = CorrectionPeriod_.StartDate;
			EndIf;
		EndIf;
		
		If BeginOfPeriod = '00010101' Then
			BeginOfPeriod = BegOfMonth(AddMonth(CurrentSessionDate(), -1));
		EndIf;
		
		ParametersForCalculation = Documents.FixedAssetCostAndDepreciationAdjustment.DepreciationCalculationParameters(Documents.FixedAssetCostAndDepreciationAdjustment.CalculationParameters(ThisObject));
		Documents.FixedAssetCostAndDepreciationAdjustment.ProcessDepreciationCalculationParameters(ThisObject, ParametersForCalculation);
		
	EndIf;
	
EndProcedure

Procedure FillOnBasisOfObjectsOfOperation(Basis, FilterValues)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	SourceFA = ?(TypeOf(Basis) = Type("Array"), Basis, CommonClientServer.ValueInArray(Basis));
	
	StateAccepted = New Array;
	StateAccepted.Add(Enums.FixedAssetsStates.Recognized_);
	StateAccepted.Add(Enums.FixedAssetsStates.EnteredInOffBalanceAccounting);
	ListOfFA = NonCurrentAssets.ReturnFAAcceptedForAccounting(SourceFA, Date, StateAccepted);
	
	If ListOfFA.Count() = 0 Then
		
		MessageText = NStr("vi = 'Tài sản cố định nên được đưa vào tài khoản';
							|ru = 'Основные средства должны быть приняты к учету';
							|en = 'Fixed assets must be recognized'; fa = 'Fixed assets must be recognized';
							|it = 'Capitali fissi devono essere registrati in contabilità';
							|pl = 'Środki trwałe należy przyjąć do ewidencji';
							|tr = 'Sabit kıymetler muhasebeleştirilmelidir'");
		Raise MessageText;
		
	EndIf;
	
	InitialInformation = Catalogs.Assets.InitialInformation(ListOfFA[0], Date);
	Organization = InitialInformation.Organization;
	Department = InitialInformation.FixedAssetsLocation;
	
	RecordInManAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentMA);
	PostInAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentAC);
	RecordInTA = ValueIsFilled(InitialInformation.CommissioningDocumentTA);
	RecordInLocalAccounting = PostInAccounting Or RecordInTA;
	
	FixedAssetKind =
		?(InitialInformation.BUState = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting,
			Enums.PropertyKinds.Leased,
			Enums.PropertyKinds.Own);
	
	ApplicationOfTargetFinancing = InitialInformation.ApplicationOfTargetFinancing;
	If ApplicationOfTargetFinancing Then
		BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecrease = True;
	EndIf;
	
	For Each MainMeansBase In ListOfFA Do
		NewRow = FA.Add();
		NewRow.FixedAsset = MainMeansBase;
	EndDo;
	
	Documents.FixedAssetCostAndDepreciationAdjustment.FillInByAccountingData(ThisObject);
	
EndProcedure
 
#EndRegion

#Region FillChecking

Procedure CheckDocument(NotCheckedAttributeArray, Cancel)
	
	CheckCorrectionFromLastDate(Cancel);
	
	If Not RecordInLocalAccounting And Not RecordInManAccounting Then
		MessageText = NStr("vi = 'Cần phản ánh chứng từ vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, kayıtlarının birinde yansıtılmalıdır'");
		Common.MessageToUser(MessageText,, "Object.PostInAccounting",, Cancel);
	EndIf;
	
	If FixedAssetKind <> Enums.PropertyKinds.Leased
		And Not CostAdjustment
		And Not AdjustmentOfInitialCost
		And Not DepreciationAdjustment
		And Not AdjustmentOfDepreciationCalculationParameters
		And Not BonusDepreciationAdjustment
		And Not AdjustTAExpenseAmountOfInvestmentTaxDeduction Then
		
		MessageText = NStr("vi = 'Cần chọn ít nhất một tham số điều chỉnh được soạn';
							|ru = 'Необходимо выбрать хотя бы один редактируемый параметр корректировки';
							|en = 'Select at least one editable adjustment parameter'; fa = 'Select at least one editable adjustment parameter';
							|it = 'Необходимо выбрать хотя бы один редактируемый параметр корректировки';
							|pl = 'Select at least one editable adjustment parameter';
							|tr = 'En az bir düzenlenebilir düzeltme parametresi seçilmelidir'");
		Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		
	EndIf;
	
EndProcedure

Procedure CheckCorrectionFromLastDate(Cancel)
	
	If Not AdjustmentModeFromPreviousDate
		Or Not ValueIsFilled(BeginOfPeriod) Then
		Return
	EndIf;
	
	If BeginOfPeriod >= BegOfMonth(Date)
		And ValueIsFilled(Date) Then
		MessageText = NStr("vi = 'Thời gian bắt đầu điều chỉnh phải sớm hơn đầu tháng lập chứng từ';
							|ru = 'Начало корректировки должно быть раньше начала месяца, в котором оформлен документ';
							|en = 'Start of the adjustment must be earlier than the beginning of the month in which the document is created'; fa = 'Start of the adjustment must be earlier than the beginning of the month in which the document is created';
							|it = 'L''inizio dell''aggiustamente deve essere precedente all''inizio del mese nel quale è stato registrato il documento';
							|pl = 'Początek korekty powinien być wcześniej niż początek miesiąca, w którym jest utworzony dokument';
							|tr = 'Düzeltmenin başlangıcı, belgenin düzenlendiği ayın başlangıcından daha önce olmalıdır'");
		Common.MessageToUser(MessageText, ThisObject, "BeginOfPeriod",, Cancel);
	ElsIf Not NonCurrentAssets.VNAManagementIsUsed_2_4(BeginOfPeriod) Then
		MessageText = NStr("vi = 'Thời gian bắt đầu điều chỉnh không được sớm hơn khi bắt đầu ghi nhận tài sản dài hạn phiên bản 2.4';
							|ru = 'Начало корректировки должно быть не раньше начала учета внеоборотных активов версии 2.4';
							|en = 'The adjustment start must not be earlier than the start of fixed and intangible assets accounting version 2.4'; fa = 'The adjustment start must not be earlier than the start of fixed and intangible assets accounting version 2.4';
							|it = 'L''inizio dell''aggiustamento non deve essere precedente all''inizio della contabilità degli attivi non correnti della versione 2.4';
							|pl = 'Początek korekty powinien być nie wcześniej niż początek ewidencji aktywów nieobrotowych wersji 2.4';
							|tr = 'Düzeltmenin başlangıcı, duran varlıkların muhasebeleştirilmesinin başlangıcından daha erken olmamalıdır sürüm 2.4'");
		Common.MessageToUser(MessageText, ThisObject, "BeginOfPeriod",, Cancel);
	EndIf;
	
	QueryText =
	"SELECT DISTINCT
	|	FATable.FixedAsset.Presentation AS FixedAssetPresentation
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
	|
	|		INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Ref <> &Ref
	|	AND FATable.FixedAsset IN (&ListOfFA)
	|	AND DocumentData.Posted
	|
	|	AND (&PostInAccounting AND DocumentData.PostInAccounting
	|		OR &RecordInTA AND DocumentData.RecordInTA 
	|		OR &RecordInManAccounting AND DocumentData.RecordInManAccounting)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("BeginOfPeriod", BegOfDay(Date));
	Query.SetParameter("EndOfPeriod", EndOfDay(Date));
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("PostInAccounting", PostInAccounting);
	Query.SetParameter("RecordInTA", RecordInTA);
	Query.SetParameter("RecordInManAccounting", RecordInManAccounting);
	Query.SetParameter("ListOfFA", FA.UnloadColumn("FixedAsset"));
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		MessageText = NStr("vi = 'Đối với tài sản cố định %1 đã lập điều chỉnh vào %2.
							  |Không hỗ trợ lập nhiều điều chỉnh trong một ngày.';
							  |ru = 'Для основного средства %1 уже оформлена корректировка на %2.
							  |Не поддерживается оформление нескольких корректировок в один день.';
							  |en = 'For the %1 fixed asset, an adjustment dated %2 is already registered.
							  |Cannot create several adjustments in one day.'; fa = 'For the %1 fixed asset, an adjustment dated %2 is already registered.
							  |Cannot create several adjustments in one day.';
							  |it = 'Для основного средства %1 уже оформлена корректировка на %2.
							  |Не поддерживается оформление нескольких корректировок в один день.';
							  |pl = 'For the %1 fixed asset, an adjustment dated %2 is already registered.
							  |Cannot create several adjustments in one day.';
							  |tr = '%1 sabit kıymeti için %2 üzerine düzeltme zaten yapılmıştır.
							  |Aynı gün içinde birden fazla düzeltme yapılması desteklenmemektedir.'");
		MessageText = StrTemplate(MessageText, Selection.FixedAssetPresentation, Format(Date, "DLF=D;"));
		Common.MessageToUser(MessageText, ThisObject, "Date",, Cancel);
	EndDo;
	
EndProcedure 

#EndRegion

#Region Other

Procedure BlockData_()

	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.InitialFixedAssetsInformation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	LockItem.SetValue("Organization", Organization);
	
	LockItem = Block.Add("InformationRegister.FALocation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	Block.Lock(); 
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite()

	ClearUnusedProps();
	
	If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())))
		And Constants.ManagementAccountingCurrency.Get() = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization) Then
		
		For Each RowData In FA Do
			RowData.CostInManagementAccounting = RowData.CostInAccounting;
			RowData.DepreciationManagementAccounting = RowData.DepreciationInAccounting;
			RowData.InitialCostMA = RowData.InitialCostLocalAccounting;
		EndDo; 
		
	EndIf; 
	
	If RecordInManAccounting And Not RecordInLocalAccounting And Not ValueIsFilled(FixedAssetKind) Then
		FixedAssetKind = Enums.PropertyKinds.Own;
	EndIf;
	
EndProcedure

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = Documents.FixedAssetCostAndDepreciationAdjustment.AuxiliaryAttributes(ThisObject);
	ItemDetailsParameters = NonCurrentAssetsClientServer.ValuesOfPropertiesOfDependentProps_AdjustmentOfCostAndDepreciationOfFA(ThisObject, AuxiliaryAttributes);
	
	TMCommonUseClientServer.ClearUnusedProps(
		ThisObject, ItemDetailsParameters, "FA,FinancialDetailsForThePeriod,FinancialDetailsForThePeriodAC,FinancialDetailsForThePeriodTA");

EndProcedure

#EndRegion

#EndRegion

#EndIf
