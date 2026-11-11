#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocument(FillingData);
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillInSelectionDocument(FillingData);
		
	ElsIf FillInDataType = Type("Array") Then
		
		If FillingData.Count() <> 0
			And TypeOf(FillingData[0]) = Type("CatalogRef.IntangibleAssets") Then
			FillInBasedOnIntangibleAsset(FillingData);
		EndIf;
		
	ElsIf FillInDataType = Type("CatalogRef.IntangibleAssets") Then
		
		FillInBasedOnIntangibleAsset(FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.IntangibleAssetImprovement") Then
		
		FillInBasedOnImprovementOfIA(FillingData);
		
	EndIf;
	
	IntangibleAssetImprovementLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;

	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentAttributes_IAImprovement(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, AttributesNotToCheck);
	
	CheckHeaderDetails_(Cancel);
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "IA", "IntangibleAsset", Cancel);

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);

	IntangibleAssetImprovementLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemDetailsParameters);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		NonCurrentAssetsInternal.CheckThatIAAreAcceptedForAccounting(ThisObject, Cancel);
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "IA");
	
	FillInBankingDetailsBeforeWrite();
	
	IntangibleAssetImprovementLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	IntangibleAssetImprovementLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentInAnotherAccounting = Undefined;
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "IA");
	
	IntangibleAssetImprovementLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	IntangibleAssetImprovementLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	IntangibleAssetImprovementLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);

	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);

EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("Date") Then
		Date = Basis.Date;
	EndIf;
	
	If Basis.Property("Organization")
		And ValueIsFilled(Basis.Organization) Then
		Organization = Basis.Organization;
	EndIf;

	If Basis.Property("BusinessOperation") Then
		BusinessOperation = Basis.BusinessOperation;
	EndIf; 

	If Basis.Property("IntangibleAsset") Then
		FillInBasedOnIntangibleAsset(Basis.IntangibleAsset);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnIntangibleAsset(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	If TypeOf(Basis) = Type("Array") Then
		IntangibleAsset = Basis[0];
		ListOfIA = Basis;
	Else
		IntangibleAsset = Basis;
		ListOfIA = New Array;
		ListOfIA.Add(Basis);
	EndIf;
	
	DetailsOfFoundation = Common.ObjectAttributesValues(IntangibleAsset, "IsFolder,KindOfAccountingObject");
	
	If DetailsOfFoundation.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể cải thiện trên cơ sở nhóm TSCĐ vô hình.
			|Hãy chọn TSCĐ vô hình. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Улучшение на основании группы НМА невозможна.
			|Выберите НМА. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Improvement based on an intangible asset group is unavailable.
			|Select intangible assets. To expand the group, press Ctrl + Down Arrow.'; fa = 'Improvement based on an intangible asset group is unavailable.
			|Select intangible assets. To expand the group, press Ctrl + Down Arrow.';
			|it = 'Улучшение на основании группы НМА невозможна.
			|Выберите НМА. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|pl = 'Improvement based on an intangible asset group is unavailable.
			|Select intangible assets. To expand the group, press Ctrl + Down Arrow.';
			|tr = 'Maddi olmayan varlık grubuna dayalı iyileştirme mümkün değildir.
			| Maddi olmayan varlık seçin. Grubu genişletmek için Ctrl tuşunu ve aşağı oku kullanın.'");
		Raise(MessageText);
		
	ElsIf DetailsOfFoundation.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
		
		MessageText = NStr("vi = 'Không hỗ trợ cải thiện chi phí nghiên cứu, triển khai.
			|Hãy chọn TSCĐ vô hình.';
			|ru = 'Улучшение расходов на НИОКР не поддерживается.
			|Выберите НМА.';
			|en = 'R&D expense improvement is not supported.
			|Select intangible assets.'; fa = 'R&D expense improvement is not supported.
			|Select intangible assets.';
			|it = 'Улучшение расходов на НИОКР не поддерживается.
			|Выберите НМА.';
			|pl = 'R&D expense improvement is not supported.
			|Select intangible assets.';
			|tr = 'Ar-Ge harcamalarındaki iyileştirmeler desteklenmemektedir. 
			|Maddi olmayan varlıkı seçin.'");
		Raise(MessageText);
	
	EndIf;
	
	InitialInformation = Catalogs.IntangibleAssets.InitialInformation(IntangibleAsset, Date);

	IntangibleAssetsRegistrationPlace = NonCurrentAssets.IntangibleAssetsRegistrationPlace(IntangibleAsset);
	FillPropertyValues(ThisObject, IntangibleAssetsRegistrationPlace);
	
	For Each IntangibleAsset In ListOfIA Do
		LineOfATabularSection = IA.Add();
		LineOfATabularSection.IntangibleAsset = IntangibleAsset;
	EndDo;
	
	RecordInManAccounting = ValueIsFilled(InitialInformation.DateOfRecognitionManagementAccounting);
	PostInAccounting = ValueIsFilled(InitialInformation.DateOfRecognitionAccounting);
	RecordInTA = ValueIsFilled(InitialInformation.DateOfRecognitionInTaxAccounting);
	RecordInLocalAccounting = PostInAccounting Or RecordInTA;
	
	Documents.IntangibleAssetImprovement.FillInCostAmount(ThisObject);
	
EndProcedure

Procedure FillInBasedOnImprovementOfIA(Basis, IntangibleAsset = Undefined)

	BaseObject = Basis.GetObject();
	
	FillPropertyValues(ThisObject, BaseObject,, "Number,Date,DataVersion,EmployeeResponsible,DeletionMark,Posted");
	DocumentInAnotherAccounting = Basis;
	
	If Not ValueIsFilled(IntangibleAsset) Then
		For Each BaseString In BaseObject.IA Do
			LineOfATabularSection = IA.Add();
			LineOfATabularSection.IntangibleAsset = BaseString.IntangibleAsset;
		EndDo; 
		IA.Load(BaseObject.IA.Unload());
	Else
		LineOfATabularSection = IA.Add();
		LineOfATabularSection.IntangibleAsset = IntangibleAsset;
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
	
	Documents.IntangibleAssetImprovement.FillInCostAmount(ThisObject);
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite()

	AuxiliaryAttributes = AuxiliaryAttributes();

	ClearUnusedProps(AuxiliaryAttributes);

	If RecordInManAccounting And RecordInLocalAccounting Then
		DocumentInAnotherAccounting = Undefined;
	EndIf;
	
	If Not AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
		And AuxiliaryAttributes.CurrenciesDoNotMatch Then
		
		For Each RowData In IA Do
			RowData.CostInManagementAccounting = RowData.CostInAccounting;
		EndDo; 
		
	EndIf; 
	
EndProcedure

Procedure ClearUnusedProps(AuxiliaryAttributes)
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentAttributes_IAImprovement(ThisObject, AuxiliaryAttributes);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "IA");

EndProcedure

Procedure CheckHeaderDetails_(Cancel)

	If Not RecordInLocalAccounting And Not RecordInManAccounting Then
		MessageText = NStr("vi = 'Cần phản ánh chứng từ vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, kayıtlarının birinde yansıtılmalıdır'");
		Common.MessageToUser(MessageText,, "Object.PostInAccounting",, Cancel);
	EndIf;

	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	NonCurrentAssets.CheckApplicationOfFSB14(ThisObject, Cancel);
	NonCurrentAssets.CheckIntStandardApplication(ThisObject, Cancel);
	
	NonCurrentAssetsInternal.CheckProcedureForGeneratingIACost(ThisObject, Cancel);
	
EndProcedure

Function AuxiliaryAttributes()

	DateOfParameters = EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()));
	
	AuxiliaryAttributes = New Structure;
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	AuxiliaryAttributes.Insert(
		"ThereIsCostAccounting",
		CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(DateOfParameters));

	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, DateOfParameters));
	
	AuxiliaryAttributes.Insert(
		"AccountPolicySettings", 
		AccountingPoliciesTaxSettingsCached.AccountingSettingsForNonCurrentAssets(Organization, DateOfParameters));
	
	
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndIf
