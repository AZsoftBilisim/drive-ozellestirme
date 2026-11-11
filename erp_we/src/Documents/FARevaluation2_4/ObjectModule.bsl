
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocument(FillingData);
	
	FillInDataType = TypeOf(FillingData);
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Assets") Then
		FillInBasedOnObjectOfOperation(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FARevaluation2_4") Then
		FillInBasedOnRevaluation(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		FillInBasedOnInventory(FillingData);
	EndIf;
	
	FARevaluationLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

	ItemsAndDimensionsSelectionParameters = Documents.FARevaluation2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	NonCurrentAssetsInternal.CheckThatFAHaveBeenSelected(ThisObject, "FA", "FixedAsset", Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.FARevaluation2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_RevaluationOfFA(
									ThisObject, AuxiliaryAttributes());
									
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, AttributesNotToCheck);
	
	CheckDocument(Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	FARevaluationLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not Cancel And WriteMode = DocumentWriteMode.Posting Then
		NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
	EndIf;
	
	FillInBankingDetailsBeforeWrite();
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
	FARevaluationLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	ItemsAndDimensionsSelectionParameters = Documents.FARevaluation2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	NonCurrentAssets.IdentifyDocumentChanges(ThisObject, WriteMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	FARevaluationLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentInAnotherAccounting = Undefined;
	
	InitializeDocument(Undefined);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
	FARevaluationLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	BlockReadableData();
	
	NonCurrentAssets.GenerateTasksONChangingDocument(ThisObject, FA.UnloadColumn("FixedAsset"));
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	FARevaluationLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	FARevaluationLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData)
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	RevaluateAtFairValue = True;

	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

Procedure BlockReadableData()

	// It is necessary to block the data that is used when recording movements.
	// For example, data registers of information that are used to fill in missing resources.
	
	Block = New DataLock;
	
	If RecordInManAccounting Then
		
		LockItem = Block.Add("InformationRegister.FixedAssetDepreciationParametersManagementAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
		
	EndIf; 
	
	If RecordInLocalAccounting Then
		
		LockItem = Block.Add("InformationRegister.OSBUDepreciationParameters");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
		
	EndIf;
	
	Block.Lock(); 
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("FixedAsset") Then
		FillInBasedOnObjectOfOperation(Basis.FixedAsset);
	ElsIf Basis.Property("DocumentBasis")
		And TypeOf(Basis.DocumentBasis) = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		FillInBasedOnInventory(Basis);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnObjectOfOperation(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "IsFolder");
	
	If DetailsOfFoundation.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể đánh giá lại trên cơ sở nhóm TSCĐ.
			|Hãy chọn TSCĐ. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Переоценка на основании группы ОС невозможно.
			|Выберите ОС. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot revaluate based on fixed assets group. select fixed assets.
			|To expand the group, press Ctrl+Down.'; fa = 'Cannot revaluate based on fixed assets group. select fixed assets.
			|To expand the group, press Ctrl+Down.';
			|it = 'La rivalutazione in base al gruppo Capitali fissi non è possibile.
			|Selezionate il capitale fisso. Per aprire il gruppo utilizzate i tasti Ctrl e la freccia giù.';
			|pl = 'Przeszacowanie oparte na grupie ST nie jest możliwe.
			| Wybierz ST. Aby rozwinąć grupę, użyj klawisza Ctrl i strzałki w dół.';
			|tr = 'Sabit kıymet gruplarına dayalı bir yeniden değerleme mümkün değildir. 
			|Sabit kıymet seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	InitialInformation = Catalogs.Assets.InitialInformation(Basis, Date);

	FALocation = NonCurrentAssets.FALocation(Basis);
	FillPropertyValues(ThisObject, FALocation);
	Department = FALocation.FixedAssetsLocation;
	
	LineOfATabularSection = FA.Add();
	LineOfATabularSection.FixedAsset = Basis;
	
	ExpensesPostingMethod = NonCurrentAssetsInternal.WayToReflectFAExpenses(
		ThisObject,
		LineOfATabularSection.FixedAsset);
	
	If ValueIsFilled(ExpensesPostingMethod) Then
		
		NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
			ExpensesPostingMethod, 
			ExpenseItem, 
			DimensionOfExpenses, 
			ExpensesBusinessUnit, 
			ExpenseLineOfBusiness, 
			BusinessUnitAndLineOfBusinessMatchAccountingData);
			
	EndIf;
	
	RecordInManAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentMA);
	RecordInLocalAccounting = 
		ValueIsFilled(InitialInformation.CommissioningDocumentAC)
		Or ValueIsFilled(InitialInformation.CommissioningDocumentTA);
	
EndProcedure

Procedure FillInBasedOnRevaluation(Basis, FixedAsset = Undefined)

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
	
	If BaseObject.RecordInLocalAccounting Then
		RecordInLocalAccounting = False;
		RecordInManAccounting  = True;
	Else
		RecordInLocalAccounting = True;
		RecordInManAccounting  = False;
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnInventory(FillingData)
	
	GeneratedDocument = True;
	
	ArrayOfLineNumbers = Undefined;
	ReportErrors = True;
	
	If TypeOf(FillingData) = Type("Structure") Then
		DocumentBasis = FillingData.DocumentBasis;
		ArrayOfLineNumbers = FillingData.ArrayOfLineNumbers;
		ReportErrors = FillingData.ReportErrors;
	Else
		DocumentBasis = FillingData;
	EndIf;
	
	Documents.FARevaluation2_4.FillInBasedOnInventory(ThisObject, ReportErrors, ArrayOfLineNumbers);
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite()

	ClearUnusedProps();
	
	If RecordInManAccounting And RecordInLocalAccounting Then
		DocumentInAnotherAccounting = Undefined;
	EndIf;
	
EndProcedure

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_RevaluationOfFA(ThisObject, AuxiliaryAttributes);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "FA");

EndProcedure

Procedure CheckDocument(Cancel)

	If Not RecordInLocalAccounting And Not RecordInManAccounting Then
		MessageText = NStr("vi = 'Cần phản ánh chứng từ vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, kayıtlarının birinde yansıtılmalıdır'");
		Common.MessageToUser(MessageText,, "Object.RecordInLocalAccounting",, Cancel);
	EndIf;
	
EndProcedure

Function AuxiliaryAttributes()
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("UseConstructionObjects", GetFunctionalOption("UseConstructionObjects"));
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndIf
