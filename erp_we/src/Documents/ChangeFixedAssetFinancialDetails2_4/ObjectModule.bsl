
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		TypeOfParameterChangeOperation = Undefined;
		
		If FillingData.Property("OperationKind",TypeOfParameterChangeOperation) Then
			If TypeOfParameterChangeOperation = "ChangingCGU" Then
				FillInCGUChange(FillingData);
			EndIf;
		Else
			FillInSelectionDocument(FillingData);
		EndIf;
	ElsIf FillInDataType = Type("CatalogRef.Assets") Then
		FillInBasedOnObjectOfOperation(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetsInitialRecognition2_4") Then
		FillInBasedOnAcceptanceForAccounting(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FATransfer2_4") Then
		FillBasedOnMovement(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetsCostAdditions2_4") Then
		FillInBasedOnModernization(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4") Then
		FillBasedOnEnteringBalances(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.ChangeFixedAssetFinancialDetails2_4") Then
		FillBasedOnParameterChanges(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.SplitFixedAssets") Then
		FillInBasedOnFADisassembly(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.MergeOfFixedAssets") Then
		FillInBasedOnFAPooling(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetCostAndDepreciationAdjustment") Then
		FillInBasedOnCostAdjustmentAndFADepreciation(FillingData);
	EndIf;
	
	ChangeFixedAssetFinancialDetailsLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

	ItemsAndDimensionsSelectionParameters = Documents.ChangeFixedAssetFinancialDetails2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Comment = "";
	DocumentBasis = Undefined;
	
	InitializeDocumentBeforeFillingItOut();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
	ChangeFixedAssetFinancialDetailsLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_ChangeFAParameters(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	NonCurrentAssetsInternal.CheckStartOfParameters(ThisObject, Cancel);
	
	CheckReflectionInAccounting(Cancel);
	CheckParametersFilling(Cancel);
	CheckTSDepreciation(NotCheckedAttributeArray, Cancel);
	CheckCorrectionModeFromLastDate(Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.ChangeFixedAssetFinancialDetails2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	ChangeFixedAssetFinancialDetailsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);

	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_ChangeFAParameters(ThisObject, AuxiliaryAttributes);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "Depreciation,DepreciationAllowance");	

	If Not Cancel And WriteMode = DocumentWriteMode.Posting Then
		NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
		
	ItemsAndDimensionsSelectionParameters = Documents.ChangeFixedAssetFinancialDetails2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);

	If Depreciation.Count() = 1
		And Depreciation[0].ZoomRatio = 0 Then
		Depreciation[0].ZoomRatio = 1;
	EndIf;

	CalculateServiceDetailsToCalculateDepreciation();
	
	ChangeFixedAssetFinancialDetailsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ChangeFixedAssetFinancialDetailsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	BlockReadableData();
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ChangeFixedAssetFinancialDetailsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ChangeFixedAssetFinancialDetailsLocalization.UndoPosting(ThisObject, Cancel);
	
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
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("FixedAsset") Then
		FillInBasedOnObjectOfOperation(Basis.FixedAsset);
	EndIf; 
	
	If Basis.Property("AdjustmentModeFromPreviousDate") Then
		
		AdjustmentModeFromPreviousDate = True;
		
		If Basis.Property("CorrectionPeriod_") Then
			CorrectionPeriod_ = Basis.CorrectionPeriod_; // StandardPeriod
			If CorrectionPeriod_.StartDate < BegOfMonth(CurrentSessionDate()) Then
				ValidOnDate = CorrectionPeriod_.StartDate;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInBasedOnObjectOfOperation(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "IsFolder");
	
	If DetailsOfFoundation.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể thay đổi tham số nhóm TSCĐ.
			|Hãy chọn TSCĐ. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Изменение параметров группы ОС невозможно.
			|Выберите ОС. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot change FA group parameters.
			|Select FA. To expand the group, press Ctrl+Down.'; fa = 'Cannot change FA group parameters.
			|Select FA. To expand the group, press Ctrl+Down.';
			|it = 'La modifica dei parametri del gruppo dei capitali fissi non è possibile.
			|Selezionare i capitali fissi. Per aprire il gruppo premere Ctrl e freccia verso il basso.';
			|pl = 'Zmiana parametrów grupy środków trwałych jest niemożliwa. 
			|Wybierz środki trwałe. Aby rozwinąć grupę użyj klawiszy Ctrl oraz strzałkę w dól.';
			|tr = 'Sabit kıymet grupları ayarlarını değiştiremezsiniz. 
			|Sabit kıymet seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	InitialInformation = Catalogs.Assets.InitialInformation(Basis, Date);
	
	Organization = InitialInformation.Organization;
	
	LineOfATabularSection = FA.Add();
	LineOfATabularSection.FixedAsset = Basis;
	
	RecordInManAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentMA);
		
	PostInAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentAC);
	RecordInTA = ValueIsFilled(InitialInformation.CommissioningDocumentTA);
	RecordInLocalAccounting = PostInAccounting Or RecordInTA;
	
EndProcedure

Procedure FillInBasedOnAcceptanceForAccounting(Basis)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.FixedAsset AS FixedAsset
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4.FA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Query.SetParameter("Ref", Basis);
	Package = Query.ExecuteBatch();
	
	If Not Package[0].IsEmpty() Then
		Selection = Package[0].Select();
		Selection.Next();
		FillPropertyValues(ThisObject, Selection);
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		Table = Package[1].Unload();
		FA.Load(Table);
	EndIf;
	
EndProcedure

Procedure FillBasedOnMovement(Basis)
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN DocumentData.CompanyRecipient
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|FROM
	|	Document.FATransfer2_4 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.FixedAsset AS FixedAsset
	|FROM
	|	Document.FATransfer2_4.FA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Basis);
	Package = Query.ExecuteBatch();
	
	If Not Package[0].IsEmpty() Then
		Selection = Package[0].Select();
		Selection.Next();
		FillPropertyValues(ThisObject, Selection);
		PostInAccounting = RecordInLocalAccounting;
		RecordInTA = RecordInLocalAccounting And NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		FA.Load(Package[1].Unload());
	EndIf;
	
EndProcedure

Procedure FillInBasedOnModernization(Basis)
	
	QueryText =
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|FROM
	|	Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.FixedAsset AS FixedAsset
	|FROM
	|	Document.FixedAssetsCostAdditions2_4.FA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Basis);
	Package = Query.ExecuteBatch();
	
	If Not Package[0].IsEmpty() Then
		Selection = Package[0].Select();
		Selection.Next();
		FillPropertyValues(ThisObject, Selection);
		PostInAccounting = RecordInLocalAccounting;
		RecordInTA = RecordInLocalAccounting And NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		FA.Load(Package[1].Unload());
	EndIf;
	
EndProcedure

Procedure FillBasedOnParameterChanges(Basis, FixedAsset = Undefined)

	BaseObject = Basis.GetObject();
	
	FillPropertyValues(ThisObject, BaseObject,, "Number,Date,DataVersion,EmployeeResponsible,DeletionMark,Posted");
	DocumentInAnotherAccounting = Basis;
	
	If Not ValueIsFilled(FixedAsset) Then
		For Each BaseString In BaseObject.FA Do
			LineOfATabularSection = FA.Add();
			LineOfATabularSection.FixedAsset = BaseString.FixedAsset;
		EndDo; 
		FA.Load(BaseObject.FA.Unload());
	Else
		LineOfATabularSection = FA.Add();
		LineOfATabularSection.FixedAsset = FixedAsset;
	EndIf; 
	
	If NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		If BaseObject.RecordInLocalAccounting Then
			RecordInLocalAccounting = False;
			RecordInManAccounting  = True;
		Else
			RecordInLocalAccounting = True;
			RecordInManAccounting  = False;
		EndIf; 
	Else	
		RecordInLocalAccounting = True;
		RecordInManAccounting  = True;
	EndIf;
	
	PostInAccounting = RecordInLocalAccounting;
	RecordInTA = RecordInLocalAccounting And NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
EndProcedure

Procedure FillBasedOnEnteringBalances(Basis)
	
	Query = New Query(
		"SELECT
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Ref AS DocumentBasis,
		|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting AS RecordInManAccounting
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4 AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TabularSection.FixedAsset AS FixedAsset
		|FROM
		|	Document.EntryOfCapitalAssetsBalance2_4.FA AS TabularSection
		|WHERE
		|	TabularSection.Ref = &Ref
		|
		|ORDER BY
		|	TabularSection.LineNumber");
	
	Query.SetParameter("Ref", Basis);
	Package = Query.ExecuteBatch();
	
	If Not Package[0].IsEmpty() Then
		Selection = Package[0].Select();
		Selection.Next();
		FillPropertyValues(ThisObject, Selection);
		PostInAccounting = RecordInLocalAccounting;
		RecordInTA = RecordInLocalAccounting And NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		FA.Load(Package[1].Unload());
	EndIf;
	
EndProcedure

Procedure FillInBasedOnFADisassembly(Basis)

	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|FROM
	|	Document.SplitFixedAssets AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.FixedAsset AS FixedAsset
	|FROM
	|	Document.SplitFixedAssets.FA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Query.SetParameter("Ref", Basis);
	Package = Query.ExecuteBatch();
	
	If Not Package[0].IsEmpty() Then
		Selection = Package[0].Select();
		Selection.Next();
		FillPropertyValues(ThisObject, Selection);
		PostInAccounting = RecordInLocalAccounting;
		RecordInTA = RecordInLocalAccounting And NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		Table = Package[1].Unload();
		FA.Load(Table);
	EndIf;
	
EndProcedure

Procedure FillInBasedOnFAPooling(Basis)

	DocumentBasis = Basis;
	
	QueryText = 
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.FixedAsset AS FixedAsset
	|FROM
	|	Document.MergeOfFixedAssets AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Basis);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
		NewRow = FA.Add();
		NewRow.FixedAsset = Selection.FixedAsset;
	EndIf;
	
EndProcedure

Procedure FillInBasedOnCostAdjustmentAndFADepreciation(Basis)
	
	QueryText =
	"SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.FixedAsset AS FixedAsset
	|FROM
	|	Document.FixedAssetCostAndDepreciationAdjustment.FA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Basis);
	Package = Query.ExecuteBatch();
	
	If Not Package[0].IsEmpty() Then
		Selection = Package[0].Select();
		Selection.Next();
		FillPropertyValues(ThisObject, Selection);
	EndIf;
	
	If Not Package[1].IsEmpty() Then
		FA.Load(Package[1].Unload());
	EndIf;
	
EndProcedure

Procedure FillInCGUChange(FillingData)
	
	FillPropertyValues(ThisObject, FillingData);
	RecordInLocalAccounting = True;
	PostInAccounting = RecordInLocalAccounting;
	
	For Each FAString In FillingData.FA Do
		DocumentFAString  = FA.Add();
		DocumentFAString.FixedAsset = FAString.FixedAsset;
	EndDo;	
		
EndProcedure
	
#EndRegion

#Region FillChecking

Procedure CheckParametersFilling(Cancel)

	If Not AccelerationFactorManagementAccountingFlag 
		And Not UsefulLifeManagementAccountingFlag 
		And Not LineOfBusinessFlag 
		And Not DepreciationAccrualMethodManagementAccountingFlag 
		And Not DepreciationAccrualManagementAccountingFlag 
		And Not EstimatedRunningTimeFlag
		And Not ResidualValueManFlag 
		And Not ResidualValueLocalFlag 
		And Not RunningTimeValueFlag 
		And Not FinancialAccountingGroupFlag 
		And Not DepreciationExpenseRecordingIsChanged
		And Not AccelerationFactorAccountingFlag
		And Not DepreciationMethodAccountingFlag
		And Not AnnualDepreciationRateFlag 
		And Not UsefulLifeAccountingFlag 
		And Not DepreciationAccrualAccountingFlag
		And Not CGUFlag 
		And Not ChangeFixedAssetFinancialDetailsLocalization.ParametersSelected(ThisObject) Then
			
		MessageText = NStr("vi = 'Bạn phải chọn tham số biến';
							|ru = 'Необходимо выбрать изменяемые параметры';
							|en = 'Select changing parameters'; fa = 'Select changing parameters';
							|it = 'È necessario selezionare i parametri modificabili';
							|pl = 'Należy wybrać zmieniane parametry';
							|tr = 'Değiştirmek istediğiniz parametreleri seçmeniz gerekir'");
		Common.MessageToUser(MessageText, Ref,,, Cancel);
		Return; 
	EndIf; 
	
	CheckThatChangeableParametersAreUsed(Cancel);
	CheckCorrectionModeFromLastDate(Cancel);
	
EndProcedure

Procedure CheckReflectionInAccounting(Cancel)

	If Not RecordInLocalAccounting And Not RecordInManAccounting Then
		MessageText = NStr("vi = 'Cần phản ánh chứng từ vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, kayıtlarının birinde yansıtılmalıdır'");
		Common.MessageToUser(MessageText,, "Object.PostInAccounting",, Cancel);
	EndIf;
	
	If FinancialAccountingGroupFlag 
		And (Not RecordInLocalAccounting Or Not RecordInManAccounting) Then
		
		QueryText = 
		"SELECT TOP 1
		|	1
		|FROM
		|	Catalog.Assets AS Assets
		|
		|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
		|				&Date,
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS AccountingProcedureAC
		|
		|		ON (AccountingProcedureAC.FixedAsset = Assets.Ref)
		|
		|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
		|				&Date,
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS AccountingProcedureMA
		|		ON (AccountingProcedureMA.FixedAsset = Assets.Ref)
		|WHERE
		|	Assets.Ref IN(&ListOfFA)
		|	AND (AccountingProcedureAC.BUState IN(&StatesAccepted)
		|			AND NOT &PostInAccounting
		|		OR AccountingProcedureAC.StateTa IN(&StatesAccepted)
		|			AND NOT &RecordInTA
		|		OR AccountingProcedureMA.State IN(&StatesAccepted)
		|			AND NOT &RecordInManAccounting)
		|";
		
		Query = New Query(QueryText);
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("Date", Date);
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("PostInAccounting", PostInAccounting);
		Query.SetParameter("RecordInTA", RecordInTA);
		Query.SetParameter("RecordInManAccounting", RecordInManAccounting);
		Query.SetParameter("ListOfFA", FA.UnloadColumn("FixedAsset"));
		
		StatesAccepted = New Array;
		StatesAccepted.Add(Enums.FixedAssetsStates.Recognized_);
		StatesAccepted.Add(Enums.FixedAssetsStates.EnteredInOffBalanceAccounting);
		Query.SetParameter("StatesAccepted", StatesAccepted);
		
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
			MessageText = NStr("vi = 'Để thay đổi nhóm kế toán tài chính, cần phản ánh chứng từ trong tất cả các hệ thống kế toán nơi tài sản hữu hình đã được ghi nhận';
								|ru = 'Для изменения группы финансового учета необходимо отразить документ во всех учетах, в которых приняты основные средства';
								|en = 'To change the financial accounting group, record the document in all types of accounting where fixed assets are accepted'; fa = 'To change the financial accounting group, record the document in all types of accounting where fixed assets are accepted';
								|it = 'To change the financial accounting group, record the document in all types of accounting where fixed assets are accepted';
								|pl = 'To change the financial accounting group, record the document in all types of accounting where fixed assets are accepted';
								|tr = 'Finansal muhasebe grubunu değiştirmek için belgenin, sabit kıymetlerin kabul edildiği tüm muhasebe türlerinde yansıtılması gerekir'");
			Common.MessageToUser(MessageText,, "Object.PostInAccounting");
		EndIf; 
		
	EndIf; 
	
EndProcedure

Procedure CheckThatChangeableParametersAreUsed(Cancel)
	
	If FA.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = ChangeFixedAssetFinancialDetailsLocalization.QueryTextCheckThatChangeableParametersAreUsed();
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	MAX(CheckResult.ItIsNotAllowedToChangeAccelerationCoefficientOfBU) AS ItIsNotAllowedToChangeAccelerationCoefficientOfBU,
		|	MAX(CheckResult.AccrualMethodForOperatingTimeIsNotUsed) AS AccrualMethodForOperatingTimeIsNotUsed,
		|	MAX(CheckResult.ItIsNotAllowedToChangeAccelerationCoefficientOfMa) AS ItIsNotAllowedToChangeAccelerationCoefficientOfMa
		|FROM
		|	(SELECT
				// ItIsNotAllowedToChangeAccelerationCoefficientOfBU
		|		&AccelerationFactorAccountingFlag
		|		AND (NOT &DepreciationMethodAccountingFlag
		|					AND InitialFixedAssetsInformation.DepreciationMethodAccounting <> VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
		|			OR &DepreciationMethodAccountingFlag
		|					AND &DepreciationMethodAccounting <> VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)) AS ItIsNotAllowedToChangeAccelerationCoefficientOfBU,
		|
				// AccrualMethodForOperatingTimeIsNotUsed
		|		(&EstimatedRunningTimeFlag OR &RunningTimeValueFlag)
		|		AND NOT (NOT &DepreciationAccrualMethodManagementAccountingFlag
		|					AND FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod IN (&MethodsForOperatingTime)
		|				OR &DepreciationAccrualMethodManagementAccountingFlag
		|					AND &DepreciationAccrualMethodManagementAccounting IN (&MethodsForOperatingTime)
		|				OR NOT &DepreciationMethodAccountingFlag
		|					AND InitialFixedAssetsInformation.DepreciationMethodAccounting IN (&MethodsForOperatingTime)
		|				OR &DepreciationMethodAccountingFlag
		|					AND &DepreciationMethodAccounting IN (&MethodsForOperatingTime)) AS AccrualMethodForOperatingTimeIsNotUsed,
		|
				// ItIsNotAllowedToChangeAccelerationCoefficientOfMa
		|		&AccelerationFactorManagementAccountingFlag
		|		AND (NOT &DepreciationAccrualMethodManagementAccountingFlag
		|					AND FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod <> VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)
		|			OR &DepreciationAccrualMethodManagementAccountingFlag
		|					AND &DepreciationAccrualMethodManagementAccounting <> VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance)) AS ItIsNotAllowedToChangeAccelerationCoefficientOfMa
		|	FROM
		|		Catalog.Assets AS Assets
		|
		|		LEFT JOIN InformationRegister.InitialFixedAssetsInformation.SliceLast(
		|				&Date, 
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.FixedAsset = Assets.Ref
		|			AND InitialFixedAssetsInformation.Organization = &Organization
		|
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
		|				&Date,
		|				Recorder <> &Ref
		|					AND CorrectionDate = DATETIME(1,1,1)
		|					AND Organization = &Organization
		|					AND FixedAsset IN (&ListOfFA)) AS FixedAssetDepreciationParametersManagementAccounting
		|		ON FixedAssetDepreciationParametersManagementAccounting.FixedAsset = Assets.Ref
		|			AND FixedAssetDepreciationParametersManagementAccounting.Organization = &Organization
		|	WHERE
		|		Assets.Ref IN (&ListOfFA)
		|
		|	) AS CheckResult
		|
		|HAVING
		|	MAX(CheckResult.ItIsNotAllowedToChangeAccelerationCoefficientOfBU) = TRUE
		|		OR MAX(CheckResult.AccrualMethodForOperatingTimeIsNotUsed) = TRUE
		|		OR MAX(CheckResult.ItIsNotAllowedToChangeAccelerationCoefficientOfMa) = TRUE";
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ListOfFA", FA.UnloadColumn("FixedAsset"));
	
	// ACC
	Query.SetParameter("AnnualDepreciationRateFlag", AnnualDepreciationRateFlag);
	Query.SetParameter("AccelerationFactorAccountingFlag", AccelerationFactorAccountingFlag);
	Query.SetParameter("DepreciationMethodAccountingFlag", DepreciationMethodAccountingFlag);
	Query.SetParameter("DepreciationMethodAccounting", DepreciationMethodAccounting);
	
	// MA
	Query.SetParameter("DepreciationAccrualMethodManagementAccountingFlag", DepreciationAccrualMethodManagementAccountingFlag);
	Query.SetParameter("DepreciationAccrualMethodManagementAccounting", DepreciationAccrualMethodManagementAccounting);
	Query.SetParameter("AccelerationFactorManagementAccountingFlag", AccelerationFactorManagementAccountingFlag);
	Query.SetParameter("RunningTimeValueFlag", RunningTimeValueFlag);
	Query.SetParameter("EstimatedRunningTimeFlag", EstimatedRunningTimeFlag);

	MethodsForOperatingTime = New Array;
	MethodsForOperatingTime.Add(Enums.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction);
	Query.SetParameter("MethodsForOperatingTime", MethodsForOperatingTime);
	
	ChangeFixedAssetFinancialDetailsLocalization.SetRequestParametersToVerifyThatParametersBeingChangedAreUsed(ThisObject, Query);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();

	If Selection.ItIsNotAllowedToChangeAccelerationCoefficientOfBU Then
		MessageText = NStr("vi = 'Để thay đổi tham số ""Hệ số khấu hao nhanh (kế toán doanh nghiệp)"" đối với tài sản cố định, cần đặt phương pháp tính khấu hao ""Số dư giảm dần"".';
							|ru = 'Для изменения параметра ""Коэффициент ускорения (бухгалтерский учет)"" у основных средств должен быть метод начисления амортизации ""Уменьшаемого остатка"".';
							|en = 'Fixed assets must have the ""Declining balance"" depreciation charge method to change the ""Acceleration factor (local accounting)"" parameter.'; fa = 'Fixed assets must have the ""Declining balance"" depreciation charge method to change the ""Acceleration factor (local accounting)"" parameter.';
							|it = 'Per modificare il parametro ""Coefficiente di accelerazione (contabilità)"", l''ammortamento del Capitale fisso deve essere calcolato con il metodo ""A saldo decrescente"".';
							|pl = 'Aby zmienić parametr ""Współczynnik przyspieszenia (ewidencja księgowa)"" środki trwałe powinny mieć metodę naliczenia amortyzacji ""Zmniejszanego stanu"".';
							|tr = '""Hızlandırma faktörü (muhasebe)"" parametresini değiştirmek için, sabit kıymetlerin ""Azalan bakiye"" amortisman yöntemine sahip olması gerekir.'");
		Common.MessageToUser(MessageText, ThisObject, "AccelerationFactorAccountingFlag",, Cancel);
	EndIf;

	If Selection.ItIsNotAllowedToChangeAccelerationCoefficientOfMa Then
		MessageText = NStr("vi = 'Để thay đổi tham số ""Hệ số tăng tốc (kế toán quản trị)"", tài sản cố định phải có phương pháp khấu hao ""Số dư giảm"".';
							|ru = 'Для изменения параметра ""Коэффициент ускорения (управленческий учет)"" у основных средств должен быть метод начисления амортизации ""Уменьшаемого остатка"".';
							|en = 'Fixed asset must have ""Declining balance"" method of depreciation charge to change the ""Acceleration factor (management accounting)"" parameter.'; fa = 'Fixed asset must have ""Declining balance"" method of depreciation charge to change the ""Acceleration factor (management accounting)"" parameter.';
							|it = 'Per modificare il parametro ""Coefficiente di accelerazione (contabilità gestionale)"", l''ammortamento del Capitale fisso deve essere calcolato con il metodo di ""Saldo decrescente"".';
							|pl = 'Aby zmienić parametr ""Współczynnik przyspieszenia (ewidencja zarządcza)"" środki trwałe powinny mieć metodę naliczenia amortyzacji ""Zmniejszanego stanu"".';
							|tr = '""Hızlandırma faktörü (yönetim muhasebesi)"" parametresini değiştirmek için, sabit kıymetlerin ""Azalan bakiye"" amortisman yöntemine sahip olması gerekir.'");
		Common.MessageToUser(MessageText, ThisObject, "AccelerationFactorManagementAccountingFlag",, Cancel);
	EndIf;

	If Selection.AccrualMethodForOperatingTimeIsNotUsed 
		And RunningTimeValueFlag
		And Not NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		MessageText = NStr("vi = 'Để thay đổi tham số ""Giờ hoạt động"", tài sản cố định phải có phương pháp khấu hao ""Tỷ lệ thuận với khối lượng sản xuất"".';
							|ru = 'Для изменения параметра ""Показатель наработки"" у основных средств должен быть метод начисления амортизации ""Пропорционально объему"".';
							|en = 'Fixed asset must have ""Units-of-activity"" method of depreciation charge to change the ""Asset activity measure"" parameter.'; fa = 'Fixed asset must have ""Units-of-activity"" method of depreciation charge to change the ""Asset activity measure"" parameter.';
							|it = 'Per modificare il parametro ""Indicatore di produzione"" del Capitale fisso, l''ammortamento di questo Capitale fisso deve essere calcolato con il metodo ""Proporzionale al volume"".';
							|pl = 'Aby zmienić parametr ""Wskaźnik czasu pracy"" środki trwałe powinny mieć metodę naliczenia amortyzacji ""Proporcjonalnie do objętości"".';
							|tr = '""Varlık faaliyet ölçümü"" parametresini değiştirmek için, sabit kıymetlerin ""Hacimle orantılı"" bir amortisman yöntemine sahip olması gerekir.'");
		Common.MessageToUser(MessageText, ThisObject, "RunningTimeValueFlag",, Cancel);
	EndIf;
	
	If Selection.AccrualMethodForOperatingTimeIsNotUsed 
		And EstimatedRunningTimeFlag
		And Not NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		MessageText = NStr("vi = 'Để thay đổi tham số ""Thời gian hoạt động ước tính"", tài sản cố định phải có phương pháp khấu hao ""Tỷ lệ thuận với khối lượng sản xuất"".';
							|ru = 'Для изменения параметра ""Предполагаемый объем наработки"" у основных средств должен быть метод начисления амортизации ""Пропорционально объему"".';
							|en = 'Fixed asset must have ""Units-of-activity"" method of depreciation charge to change the ""Estimated asset activity value"" parameter.'; fa = 'Fixed asset must have ""Units-of-activity"" method of depreciation charge to change the ""Estimated asset activity value"" parameter.';
							|it = 'Per modificare il parametro ""Volume di produzione stimato"" del Capitale fisso, l''ammortamento di questo Capitale fisso deve essere calcolato con il metodo ""Proporzionale al volume"".';
							|pl = 'Aby zmienić parametr ""Przewidywana objętość czasu pracy"" środki trwałe powinny mieć metodę naliczenia amortyzacji ""Proporcjonalnie do objętości"".';
							|tr = '""Tahmini çalışma hacmi"" parametresini değiştirmek için, sabit kıymetlerin ""Hacimle orantılı"" bir amortisman yöntemine sahip olması gerekir.'");
		Common.MessageToUser(MessageText, ThisObject, "EstimatedRunningTimeFlag",, Cancel);
	EndIf;
	
	ChangeFixedAssetFinancialDetailsLocalization.ProcessResultOfCheckingUseOfVariableParameters(Selection, ThisObject, Cancel);
	
EndProcedure

Procedure CheckCorrectionModeFromLastDate(Cancel)
	
	If Not AdjustmentModeFromPreviousDate Then
		Return;
	EndIf;
	
	// Checking the start date of the action
	If ValidOnDate >= BegOfMonth(Date)
		And ValueIsFilled(Date)
		And ValueIsFilled(ValidOnDate) Then
		
		MessageText = NStr("vi = 'Ngày hiệu lực của các tham số phải sớm hơn đầu tháng lập chứng từ';
							|ru = 'Дата действия параметров должна быть раньше начала месяца, в котором оформлен документ';
							|en = 'The effective parameter date must be earlier than the beginning of the month in which the document is created'; fa = 'The effective parameter date must be earlier than the beginning of the month in which the document is created';
							|it = 'The effective parameter date must be earlier than the beginning of the month in which the document is created';
							|pl = 'The effective parameter date must be earlier than the beginning of the month in which the document is created';
							|tr = 'Parametrelerin işlem tarihi, belgenin oluşturulduğu ayın başlangıcından önce olmalıdır'");
		Common.MessageToUser(MessageText, ThisObject, "ValidOnDate",, Cancel);
		
	ElsIf ValueIsFilled(ValidOnDate)
		And Not NonCurrentAssets.VNAManagementIsUsed_2_4(ValidOnDate) Then
			
		MessageText = NStr("vi = 'Ngày hiệu lực của các tham số phải không sớm hơn ngày bắt đầu kế toán tài sản dài hạn phiên bản 2.4';
							|ru = 'Дата действия параметров должна быть не раньше начала учета внеоборотных активов версии 2.4';
							|en = 'The effective parameter date must not be earlier than the start of fixed and intangible assets accounting version 2.4'; fa = 'The effective parameter date must not be earlier than the start of fixed and intangible assets accounting version 2.4';
							|it = 'The effective parameter date must not be earlier than the start of fixed and intangible assets accounting version 2.4';
							|pl = 'The effective parameter date must not be earlier than the start of fixed and intangible assets accounting version 2.4';
							|tr = 'Parametrelerin işlem tarihi, 2.4 sürümü duran varlıklar muhasebesinin başlangıcından önce olmamalıdır'");
		Common.MessageToUser(MessageText, ThisObject, "ValidOnDate",, Cancel);
	EndIf;
	
	// Checking parameters
	ParametersList = New ValueList();
	ParametersList.Add("LineOfBusinessFlag", NStr("vi = 'Lĩnh vực hoạt động';
													|ru = 'Направление деятельности';
													|en = 'Line of business'; fa = 'خط کسب‌وکار';
													|it = 'Settore di attività';
													|pl = 'Rodzaj działalności';
													|tr = 'İş kolu'"));
	ParametersList.Add("FinancialAccountingGroupFlag", NStr("vi = 'Nhóm kế toán tài chính';
															|ru = 'Группа финансового учета';
															|en = 'Financial accounting group'; fa = 'گروه حسابداری مالی';
															|it = 'Gruppo di contabilità finanziaria';
															|pl = 'Grupa ewidencji finansowej';
															|tr = 'Finansal muhasebe grubu'"));
	
	For Each Item In ParametersList Do
		
		If ThisObject[Item.Value] Then
			
			MessageText = StrTemplate(
				NStr("vi = 'Không hỗ trợ thay đổi tham số ""%1"", nếu các tham số vẫn còn hiệu lực từ ngày trước đó.';
					|ru = 'Не поддерживается изменение параметра ""%1"", если параметры действуют с прошлой даты.';
					|en = 'Cannot change the ""%1"" parameter if the parameters are valid from the previous date.'; fa = 'Cannot change the ""%1"" parameter if the parameters are valid from the previous date.';
					|it = 'Cannot change the ""%1"" parameter if the parameters are valid from the previous date.';
					|pl = 'Cannot change the ""%1"" parameter if the parameters are valid from the previous date.';
					|tr = 'Parametreler geçmiş bir tarihten itibaren geçerliyse, ""%1"" parametresinin değiştirilmesi desteklenmiyor.'"),
				Item.Presentation);
				
			Common.MessageToUser(MessageText, ThisObject, Item.Value,, Cancel);
			
		EndIf;
	
	EndDo;
	
EndProcedure

Procedure CheckTSDepreciation(NotCheckedAttributeArray, Cancel)

	NotCheckedAttributeArray.Add("Depreciation.CompanyRecipientOfExpenses");
	
	RecipientTemplate = NStr("vi = 'Trường ""Người nhận"" tại dòng ""%1"" trong phần bảng ""Khấu hao"" chưa được điền.';
							|ru = 'Не заполнено поле ""Получатель"" в строке ""%1"" табличной части ""Амортизация"".';
							|en = 'The ""Recipient"" field is blank in line ""%1"" of the ""Depreciation"" tabular section.'; fa = 'The ""Recipient"" field is blank in line ""%1"" of the ""Depreciation"" tabular section.';
							|it = 'The ""Recipient"" field is blank in line ""%1"" of the ""Depreciation"" tabular section.';
							|pl = 'The ""Recipient"" field is blank in line ""%1"" of the ""Depreciation"" tabular section.';
							|tr = '""Amortisman"" tablo bölümündeki ""%1"" satırında ""Alıcı"" alanı doldurulmamış.'");
	
	For Each RowData In Depreciation Do
		
		If RowData.TransferExpensesToAnotherCompany
			And Not ValueIsFilled(RowData.CompanyRecipientOfExpenses) Then
			
			Path = CommonClientServer.PathToTabularSection("Depreciation", RowData.LineNumber, "CompanyRecipientOfExpenses");
			MessageText = StrTemplate(RecipientTemplate, RowData.LineNumber);
			Common.MessageToUser(MessageText, ThisObject, Path,, Cancel);
		EndIf;
		
	EndDo;
	
	If Depreciation.Count() < 2 Then
		NotCheckedAttributeArray.Add("Depreciation.ZoomRatio");
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure BlockReadableData()

	// It is necessary to block the data that is used when recording movements.
	// For example, data registers of information that are used to fill in missing resources.
	
	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.FixedAssetsAccountingProcedure");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	If RecordInManAccounting Then
		
		LockItem = Block.Add("InformationRegister.FixedAssetsAccountingProcedureManagementAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
		
		LockItem = Block.Add("InformationRegister.FixedAssetDepreciationParametersManagementAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
		
	EndIf; 
	
	If RecordInLocalAccounting Then
		
		LockItem = Block.Add("InformationRegister.AccountingProcedureForOSBU");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
		
		LockItem = Block.Add("InformationRegister.OSBUDepreciationParameters");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
		
	EndIf;
	
	Block.Lock(); 
	
EndProcedure

Procedure CalculateServiceDetailsToCalculateDepreciation()

	DepreciationFactorAmount = Depreciation.Total("ZoomRatio");
	
	AmountOfPreviousRowsFactors = 0;
	For Each RowData In Depreciation Do
		RowData.AmountOfPreviousRowsFactors = AmountOfPreviousRowsFactors;
		AmountOfPreviousRowsFactors = AmountOfPreviousRowsFactors + RowData.ZoomRatio;
	EndDo; 
	
EndProcedure

Function AuxiliaryAttributes()
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	AuxiliaryAttributes.Insert("UseLocal", LocalAccntingServer.ReglRecordsAreMaintained(Date));
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()))));
		
	ChangeFixedAssetFinancialDetailsLocalization.AddAuxiliaryDetails(ThisObject, AuxiliaryAttributes);
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndRegion

#EndIf
