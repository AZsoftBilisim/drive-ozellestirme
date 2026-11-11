
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AttributionOfDeviationsToCostOfFA(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	NonCurrentAssets.CheckArticleInOrderOfAccounting(ThisObject, "ExpenseItemTaxAccounting", AccountingProcedureTA, "TA", Cancel);
	
	CheckHeaderDetails_(CheckedAttributes, Cancel);
	CheckFixedAssets(NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	AllocateVariancesToFixedAssetCostLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemDetailsParameters);

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
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetsInitialRecognition2_4") Then
		FillInBasedOnAcceptanceForAccounting(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.RecognizeSubAssetsComponentsOfDepreciation") Then
		FillInOnBasisOfAcceptanceOfDepreciationComponentNodesForAccounting(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetsCostAdditions2_4") Then
		FillInBasedOnModernization(FillingData);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.AllocateVariancesToFixedAssetCost.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);

	AllocateVariancesToFixedAssetCostLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	Comment = "";
	
	InitializeDocumentBeforeFillingItOut();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
	AllocateVariancesToFixedAssetCostLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not Cancel 
		And WriteMode = DocumentWriteMode.Posting
		And Not WriteOffVariancesAsExpenses Then
		
		NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");

	ItemsAndDimensionsSelectionParameters = Documents.AllocateVariancesToFixedAssetCost.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FillInBankingDetailsBeforeWrite();
	
	AllocateVariancesToFixedAssetCostLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	AllocateVariancesToFixedAssetCostLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	BlockReadableData();
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	AllocateVariancesToFixedAssetCostLocalization.Posting(ThisObject, Cancel, PostingMode);
	FinancialAccountingPostingServer.AbilityToReflect(ThisObject, AdditionalProperties, RegisterRecords, Cancel);
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	AllocateVariancesToFixedAssetCostLocalization.UndoPosting(ThisObject, Cancel);
	
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

	If Basis.Property("FixedAsset") Then
		FillInBasedOnObjectOfOperation(Basis.FixedAsset);
	ElsIf Basis.Property("ConstructionObject") Then
		FillInBasedOnConstructionObject(Basis.ConstructionObject);
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
	
	Documents.AllocateVariancesToFixedAssetCost.FillInCostAmount(ThisObject);
	
EndProcedure

Procedure FillInBasedOnConstructionObject(Basis)

	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	If Common.ObjectAttributeValue(Basis, "IsFolder") Then
		
		MessageText = NStr("vi = 'Không thể tạo chứng từ dựa trên cơ sở nhóm đối tượng xây dựng.
			|Hãy chọn đối tượng xây dựng. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống';
			|ru = 'Создание документа на основании группы объектов строительства невозможно.
			|Выберите объект строительства. Для раскрытия группы используйте клавиши Ctrl и стрелку внизю';
			|en = 'Cannot create the document based on assets under construction group.
			|Select an asset under construction. To expand the group, press Ctrl+Down'; fa = 'Cannot create the document based on assets under construction group.
			|Select an asset under construction. To expand the group, press Ctrl+Down';
			|it = 'Cannot create the document based on assets under construction group.
			|Select an asset under construction. To expand the group, press Ctrl+Down';
			|pl = 'Cannot create the document based on assets under construction group.
			|Select an asset under construction. To expand the group, press Ctrl+Down';
			|tr = 'Yapım aşamasındaki varlık grubuna dayalı belge oluşturulması mümkün değildir. 
			| Bir yapım aşamasındaki varlık seçin. Grubu açmak için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	DimensionKindExpenseCapitalization = Enums.KindsOfExpenseCapitalizationDimension.ConstructionObject;
	ConstructionObject = Basis;
	
EndProcedure

Procedure FillInBasedOnAcceptanceForAccounting(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	SourceDocument = Basis;
	
	Documents.AllocateVariancesToFixedAssetCost.FillInBasedOnPrimaryDocument(ThisObject);
	
EndProcedure

Procedure FillInOnBasisOfAcceptanceOfDepreciationComponentNodesForAccounting(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	SourceDocument = Basis;
	
	Documents.AllocateVariancesToFixedAssetCost.FillInBasedOnPrimaryDocument(ThisObject);
	
EndProcedure

Procedure FillInBasedOnModernization(Basis)

	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	SourceDocument = Basis;

	Documents.AllocateVariancesToFixedAssetCost.FillInBasedOnPrimaryDocument(ThisObject);
	
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
		Common.MessageToUser(MessageText,, "Object.PostInAccounting",, Cancel);
	EndIf;
	
	CheckPrimaryDocument(Cancel);

	ItemsAndDimensionsSelectionParameters = Documents.AllocateVariancesToFixedAssetCost.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure CheckFixedAssets(NotCheckedAttributeArray, Cancel)

	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	NonCurrentAssetsInternal.CheckThatFAHasNotBeenTransferredToFinLease(ThisObject, Cancel);
		
EndProcedure

Procedure CheckPrimaryDocument(Cancel)
	
	If Not ValueIsFilled(SourceDocument) Then
		Return
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Posted AS Posted
	|FROM
	|	Document.FixedAssetsInitialRecognition2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &SourceDocument
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Posted AS Posted
	|FROM
	|	Document.RecognizeSubAssetsComponentsOfDepreciation AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &SourceDocument
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Posted AS Posted
	|FROM
	|	Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &SourceDocument
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("SourceDocument", SourceDocument);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);

	Selection.Next();
	
	If Selection.Date >= BegOfMonth(?(Date <> '00010101', Date, CurrentSessionDate()))
		And ValueIsFilled(Date) Then
			
		MessageText = NStr("vi = 'Ngày chứng từ gốc phải sớm hơn ngày đầu tháng lập chứng từ';
							|ru = 'Дата первичного документа должна быть раньше начала месяца, в котором оформлен документ';
							|en = 'The source document date must be earlier than the beginning of the month in which the document is created'; fa = 'The source document date must be earlier than the beginning of the month in which the document is created';
							|it = 'The source document date must be earlier than the beginning of the month in which the document is created';
							|pl = 'The source document date must be earlier than the beginning of the month in which the document is created';
							|tr = 'Kaynak belgenin tarihi, belgenin düzenlendiği ayın başından önce olmalıdır'");
		Common.MessageToUser(MessageText, ThisObject, "SourceDocument",, Cancel);
	
	ElsIf Not Selection.Posted Then
		
		MessageText = NStr("vi = 'Cần thực hiện văn bản gốc';
							|ru = 'Первичный документ должен быть проведен';
							|en = 'Post the source document'; fa = 'Post the source document';
							|it = 'Post the source document';
							|pl = 'Post the source document';
							|tr = 'Birincil belge kaydedilmiş olmalıdır'");
		Common.MessageToUser(MessageText, ThisObject, "SourceDocument",, Cancel);
		
	EndIf;
	
	If RecordInTA
		And Not WriteOffVariancesAsExpenses 
		And TypeOf(SourceDocument) = Type("DocumentRef.RecognizeSubAssetsComponentsOfDepreciation") Then
			
		MessageText = NStr("vi = 'Không hỗ trợ phản ánh trong kế toán thuế cho chứng từ ""Tiếp nhận vào kế toán các bộ phận và thành phần khấu hao""';
							|ru = 'Не поддерживается отражение в налоговом учете для документа ""Принятие к учету узлов и компонентов амортизации""';
							|en = 'Recording in tax accounting is not supported for the ""Recognize sub-assets and components of depreciation"" document'; fa = 'Recording in tax accounting is not supported for the ""Recognize sub-assets and components of depreciation"" document';
							|it = 'Recording in tax accounting is not supported for the ""Recognize sub-assets and components of depreciation"" document';
							|pl = 'Recording in tax accounting is not supported for the ""Recognize sub-assets and components of depreciation"" document';
							|tr = '""Alt varlık ve amortisman bileşenlerinin muhasebeleştirilmesi"" belgesinin vergi muhasebesinde yansıtılması desteklenmiyor.'");
		Common.MessageToUser(MessageText, ThisObject, "SourceDocument",, Cancel);
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
	
	LockItem = Block.Add("InformationRegister.InitialFixedAssetsInformation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	LockItem.SetValue("Organization", Organization);
	
	If RecordInLocalAccounting Then
		LockItem = Block.Add("InformationRegister.OSBUDepreciationParameters");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
	EndIf; 
	
	Block.Lock(); 
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite()

	ClearUnusedProps();
	
	If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())))
		And Constants.ManagementAccountingCurrency.Get() = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization) Then
		
		For Each RowData In FA Do
			RowData.AmountOfUU = RowData.AmountAccounting;
		EndDo; 
		
	EndIf; 
	
EndProcedure

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AttributionOfDeviationsToCostOfFA(ThisObject, AuxiliaryAttributes);
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
		
	AllocateVariancesToFixedAssetCostLocalization.AddAuxiliaryDetails(ThisObject, AuxiliaryAttributes);
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndRegion

#EndIf
