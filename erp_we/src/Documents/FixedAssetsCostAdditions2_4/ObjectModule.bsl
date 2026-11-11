
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps__FA(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	NonCurrentAssets.CheckArticleInOrderOfAccounting(ThisObject, "ExpenseItemTaxAccounting", AccountingProcedureTA, "TA", Cancel);
	
	CheckHeaderDetails_(CheckedAttributes, Cancel);
	CheckFixedAssets(NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	FixedAssetsCostAdditionsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemDetailsParameters);

EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut(FillingData);
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Assets") Then
		FillInBasedOnObjectOfOperation(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.ConstructionObjects") Then
		FillInBasedOnConstructionObject(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetsCostAdditions2_4") Then
		FillInBasedOnModernization(FillingData);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetsCostAdditions2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);

	FixedAssetsCostAdditionsLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentInAnotherAccounting = Undefined;
	Comment = "";
	
	InitializeDocumentBeforeFillingItOut();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
	FixedAssetsCostAdditionsLocalization.OnCopy(ThisObject, CopiedObject);

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
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
		
	FillInBankingDetailsBeforeWrite();
	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetsCostAdditions2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FixedAssetsCostAdditionsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	FixedAssetsCostAdditionsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	BlockReadableData();
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	FixedAssetsCostAdditionsLocalization.Posting(ThisObject, Cancel, PostingMode);
	FinancialAccountingPostingServer.AbilityToReflect(ThisObject, AdditionalProperties, RegisterRecords, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	FixedAssetsCostAdditionsLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure InitializeDocumentBeforeFillingItOut(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("BusinessOperation") Then
		BusinessOperation = Basis.BusinessOperation;
	EndIf; 

	If Basis.Property("FixedAsset") Then
		FillInBasedOnObjectOfOperation(Basis.FixedAsset);
	ElsIf Basis.Property("ConstructionObject") Then
		FillInBasedOnConstructionObject(Basis.ConstructionObject);
	EndIf; 
	
	If Basis.Property("Organization") Then
		Organization = Basis.Organization;
	EndIf; 

	If Basis.Property("AdjustmentModeFromPreviousDate") Then
		
		AdjustmentModeFromPreviousDate = True;
		
		If Basis.Property("CorrectionDate") Then
			If Basis.CorrectionDate < ?(Date <> '00010101', Date, CurrentSessionDate()) Then
				RenovationDate = Basis.CorrectionDate;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Basis.Property("RecordInManAccounting")
		Or Basis.Property("PostInAccounting")
		Or Basis.Property("RecordInTA") Then
		
		RecordInManAccounting = Basis.RecordInManAccounting;
		PostInAccounting = Basis.PostInAccounting;
		
		
		RecordInLocalAccounting = PostInAccounting Or RecordInTA;
		
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnObjectOfOperation(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	If TypeOf(Basis) = Type("Array") Then
		ListOfFA = Basis;
	Else
		ListOfFA = CommonClientServer.ValueInArray(Basis);
	EndIf;

	NonCurrentAssetsInternal.CheckCreationOfDocumentBasedOnFAGroup(ListOfFA);
	
	For Each Item In ListOfFA Do
		If ValueIsFilled(Item) Then
			LineOfATabularSection = FA.Add();
			LineOfATabularSection.FixedAsset = Item;
		EndIf;
	EndDo;
	
	If FA.Count() = 0 Then
		Return;
	EndIf;
	
	InitialInformation = Catalogs.Assets.InitialInformation(FA[0].FixedAsset, Date);
	
	FALocation = NonCurrentAssets.FALocation(FA[0].FixedAsset);
	FillPropertyValues(ThisObject, FALocation);
	Department = FALocation.FixedAssetsLocation;
	
	LineOfBusiness = InitialInformation.LineOfBusiness;
	
	RecordInManAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentMA);
	PostInAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentAC);
	RecordInTA = ValueIsFilled(InitialInformation.CommissioningDocumentTA);
	RecordInLocalAccounting = PostInAccounting Or RecordInTA;
		
	Documents.FixedAssetsCostAdditions2_4.FillInCostAmount(ThisObject);
	
EndProcedure

Procedure FillInBasedOnConstructionObject(Basis)

	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	If Common.ObjectAttributeValue(Basis, "IsFolder") Then
		
		MessageText = NStr("vi = 'Không thể tạo chứng từ nâng cấp trên cơ sở nhóm đối tượng xây dựng.
			|Hãy chọn đối tượng xây dựng. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống';
			|ru = 'Создание модернизации на основании группы объектов строительства невозможно.
			|Выберите объект строительства. Для раскрытия группы используйте клавиши Ctrl и стрелку внизю';
			|en = 'Cannot create appreciation based on assets under construction group.
			|Select an asset under construction. To expand the group, press Ctrl+Down'; fa = 'Cannot create appreciation based on assets under construction group.
			|Select an asset under construction. To expand the group, press Ctrl+Down';
			|it = 'Non è possibile creare la modernizzazione in base al gruppo degli oggetti in costruzione.
			|Selezionate l''oggetto in costruzione. Per aprire il gruppo utilizzate i tasti Ctrl e freccia giù';
			|pl = 'Utworzenie modernizacji na podstawie grupy obiektów budowy jest niemożliwe.
			|Wybierz obiekt budowy. Aby rozwinąć grupę użyj klawiszy Ctrl oraz strzałkę w dól.';
			|tr = 'Bir yapı nesnesi grubuna dayalı bir modernizasyon oluşturmak mümkün değildir. 
			| Bir yapı nesnesi seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	DimensionKindExpenseCapitalization = Enums.KindsOfExpenseCapitalizationDimension.ConstructionObject;
	ConstructionObject = Basis;
	
EndProcedure

Procedure FillInBasedOnModernization(Basis, FixedAsset = Undefined)

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
			PostInAccounting = False;
			RecordInTA = False;
			RecordInManAccounting  = True;
		Else
			PostInAccounting = True;
			RecordInTA = True;
			RecordInManAccounting  = False;
		EndIf; 
	Else	
		PostInAccounting = True;
		RecordInTA = False;
		RecordInManAccounting  = True;
	EndIf;
	
	RecordInLocalAccounting = PostInAccounting Or RecordInTA;

	Documents.FixedAssetsCostAdditions2_4.FillInCostAmount(ThisObject);
	
EndProcedure

#EndRegion

#Region FillChecking

Procedure CheckHeaderDetails_(CheckedAttributes, Cancel)

	If Not RecordInLocalAccounting And Not RecordInManAccounting Then
		MessageText = NStr("vi = 'Cần phản ánh chứng từ vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, hesaplardan birine yansıtılmalıdır'");
		Common.MessageToUser(MessageText,, "Object.RecordInLocalAccounting",, Cancel);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetsCostAdditions2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	CheckCorrectionModeFromLastDate(Cancel);
	NonCurrentAssetsInternal.CheckFACostGenerationProcedure(ThisObject, Cancel);
	
EndProcedure

Procedure CheckFixedAssets(NotCheckedAttributeArray, Cancel)

	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	NonCurrentAssetsInternal.CheckThatFAHasNotBeenTransferredToFinLease(ThisObject, Cancel);
	NonCurrentAssetsInternal.CheckThatFAHaveBeenSelected(ThisObject, "FA", "FixedAsset", Cancel);
		
EndProcedure

Procedure CheckCorrectionModeFromLastDate(Cancel)
	
	If Not AdjustmentModeFromPreviousDate
		Or Not ValueIsFilled(RenovationDate) Then
		Return
	EndIf;
	
	If RenovationDate >= BegOfMonth(Date)
		And ValueIsFilled(Date) Then
		MessageText = NStr("vi = 'Ngày nâng cấp phải sớm hơn ngày đầu tháng lập chứng từ';
							|ru = 'Дата модернизации должна быть раньше начала месяца, в котором оформлен документ';
							|en = 'The appreciation date must be earlier than the beginning of the month in which the document is created'; fa = 'The appreciation date must be earlier than the beginning of the month in which the document is created';
							|it = 'The appreciation date must be earlier than the beginning of the month in which the document is created';
							|pl = 'The appreciation date must be earlier than the beginning of the month in which the document is created';
							|tr = 'Modernizasyon tarihi, belgenin düzenlendiği ayın başından önce olmalıdır'");
		Common.MessageToUser(MessageText, ThisObject, "RenovationDate",, Cancel);
	ElsIf Not NonCurrentAssets.VNAManagementIsUsed_2_4(RenovationDate) Then
		MessageText = NStr("vi = 'Ngày nâng cấp không được sớm hơn ngày bắt đầu ghi nhận tài sản dài hạn phiên bản 2.4';
							|ru = 'Дата модернизации должна быть не раньше начала учета внеоборотных активов версии 2.4';
							|en = 'The appreciation date must not be earlier than the start of fixed and intangible assets accounting version 2.4'; fa = 'The appreciation date must not be earlier than the start of fixed and intangible assets accounting version 2.4';
							|it = 'The appreciation date must not be earlier than the start of fixed and intangible assets accounting version 2.4';
							|pl = 'The appreciation date must not be earlier than the start of fixed and intangible assets accounting version 2.4';
							|tr = 'Modernizasyon tarihi, duran varlıkların muhasebeleştirilmesi sürüm 2.4 başlangıcından daha erken olmamalıdır'");
		Common.MessageToUser(MessageText, ThisObject, "RenovationDate",, Cancel);
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
		LockItem = Block.Add("InformationRegister.FixedAssetDepreciationParametersManagementAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
	EndIf; 
	
	FixedAssetsCostAdditionsLocalization.AddDataBlockingWhenConducting(ThisObject, Block);
	
	Block.Lock(); 
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite()

	ClearUnusedProps();
	
	If RecordInManAccounting And RecordInLocalAccounting Then
		DocumentInAnotherAccounting = Undefined;
	EndIf;
	
	If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())))
		And Constants.ManagementAccountingCurrency.Get() = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization) Then
		
		For Each RowData In FA Do
		
			RowData.CostInManagementAccounting = RowData.CostInAccounting;
		
		EndDo; 
	
	EndIf;
		
EndProcedure

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps__FA(ThisObject, AuxiliaryAttributes);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "FA,TargetFinancing");

EndProcedure

Function AuxiliaryAttributes()
	
	DateOfParameters = EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()));

	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("UseConstructionObjects", GetFunctionalOption("UseConstructionObjects"));
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	AuxiliaryAttributes.Insert("LineOfBusinessIsMandatory", False);
	AuxiliaryAttributes.Insert("SettingUpReflectionOfTaxExpensesIsRequired", False);
	AuxiliaryAttributes.Insert("PropertyTaxAdvancesArePaid", False);
	AuxiliaryAttributes.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	AuxiliaryAttributes.Insert("ComplCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", AuxiliaryAttributes.CurrencyOfMan = AuxiliaryAttributes.ComplCurrency);
	
	AuxiliaryAttributes.Insert(
		"ThereIsCostAccounting", 
		CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(DateOfParameters, False));
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, DateOfParameters));

	AuxiliaryAttributes.Insert(
		"AccountPolicySettings", 
		AccountingPoliciesTaxSettingsCached.AccountingSettingsForNonCurrentAssets(Organization, DateOfParameters));
		
	FixedAssetsCostAdditionsLocalization.AddAuxiliaryDetails(ThisObject, AuxiliaryAttributes);
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndRegion

#EndIf
