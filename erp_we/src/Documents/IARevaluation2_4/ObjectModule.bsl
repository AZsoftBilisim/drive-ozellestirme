#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocument(FillingData);
	
	FillInDataType = TypeOf(FillingData);
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.IntangibleAssets") Then
		FillInBasedOnIntangibleAsset(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.IARevaluation2_4") Then
		FillInBasedOnRevaluation(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.IntangibleAssetsPhysicalCount") Then
		FillInBasedOnInventory(FillingData);
	EndIf;
	
	IARevaluationLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

	ItemsAndDimensionsSelectionParameters = Documents.IARevaluation2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "IA", "IntangibleAsset", Cancel);
		
	AttributesNotToCheck = New Array;
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_RevaluationOfIa(
									ThisObject, AuxiliaryAttributes());
									
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, AttributesNotToCheck);
	
	ItemsAndDimensionsSelectionParameters = Documents.IARevaluation2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
		
	CheckDocument(Cancel);

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	IARevaluationLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

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
	
	IARevaluationLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	ItemsAndDimensionsSelectionParameters = Documents.IARevaluation2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	NonCurrentAssets.IdentifyDocumentChanges(ThisObject, WriteMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	IARevaluationLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentInAnotherAccounting = Undefined;
	
	InitializeDocument(Undefined);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "IA");
	
	IARevaluationLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	NonCurrentAssets.GenerateTasksONChangingDocument(ThisObject, IA.UnloadColumn("IntangibleAsset"));
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	IARevaluationLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	IARevaluationLocalization.UndoPosting(ThisObject, Cancel);
	
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

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("IntangibleAsset") Then
		
		FillInBasedOnIntangibleAsset(Basis.IntangibleAsset);
	
	ElsIf Basis.Property("DocumentBasis")
		And TypeOf(Basis.DocumentBasis) = Type("DocumentRef.IntangibleAssetsPhysicalCount") Then
			
		FillInBasedOnInventory(Basis);
		
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnIntangibleAsset(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "IsFolder,KindOfAccountingObject");
	
	If DetailsOfFoundation.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể đánh giá lại trên cơ sở nhóm TSCĐ vô hình.
			|Hãy chọn TSCĐ vô hình. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Переоценка на основании группы НМА невозможна.
			|Выберите НМА. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot revaluate based on intangible assets group. 
			|Select intangible assets. To expand the group, press Ctrl + down arrow.'; fa = 'Cannot revaluate based on intangible assets group. 
			|Select intangible assets. To expand the group, press Ctrl + down arrow.';
			|it = 'La rivalutazione in base al gruppo Beni Immateriali non è possibile.
			|Selezionate il bene immateriale. Per aprire il gruppo utilizzate i tasti Ctrl e la freccia giù.';
			|pl = 'Przeszacowanie oparte na grupie WNM nie jest możliwe.
			| Wybierz WNM. Aby rozwinąć grupę, użyj klawisza Ctrl i strzałki w dół.';
			|tr = 'Maddi olmayan varlık grubuna dayalı yeniden değerleme mümkün değildir.
			| Maddi olmayan varlık seçin. Grubu genişletmek için Ctrl tuşunu ve aşağı oku kullanın.'");
		Raise(MessageText);
		
	ElsIf DetailsOfFoundation.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
		
		MessageText = NStr("vi = 'Không thể đánh giá lại chi phí nghiên cứu phát triển.
			|Hãy chọn TSCĐ vô hình.';
			|ru = 'Переоценка расходов на НИОКР невозможна.
			|Выберите НМА.';
			|en = 'Cannot revaluate based on R&D expenses. 
			|Select intangible assets.'; fa = 'Cannot revaluate based on R&D expenses. 
			|Select intangible assets.';
			|it = 'La rivalutazione delle spese per R&S non è possibile.
			|Selezionate il bene immateriale.';
			|pl = 'Przeszacowanie kosztów prac badawczo-rozwojowych nie jest możliwe.
			| Wybierz WNM.';
			|tr = 'Ar-Ge harcamaları yeniden değerlendirilemez.
			| Maddi olmayan varlık seçin.'");
		Raise(MessageText);
	
	EndIf;
	
	InitialInformation = Catalogs.IntangibleAssets.InitialInformation(Basis, Date);

	IntangibleAssetsRegistrationPlace = NonCurrentAssets.IntangibleAssetsRegistrationPlace(Basis);
	FillPropertyValues(ThisObject, IntangibleAssetsRegistrationPlace);
	
	LineOfATabularSection = IA.Add();
	LineOfATabularSection.IntangibleAsset = Basis;
	
	RecordInManAccounting = ValueIsFilled(InitialInformation.DocumentOfRecognitionManagementAccounting);
	RecordInLocalAccounting = 
		ValueIsFilled(InitialInformation.DocumentOfRecognitionAccounting)
		Or ValueIsFilled(InitialInformation.RecognitionDocumentTA);
	
	ExpensesPostingMethod = NonCurrentAssetsInternal.WayToReflectIAExpenses(
		ThisObject,
		LineOfATabularSection.IntangibleAsset);
	
	If ValueIsFilled(ExpensesPostingMethod) Then
		
		NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
			ExpensesPostingMethod, 
			ExpenseItem, 
			DimensionOfExpenses, 
			ExpensesBusinessUnit, 
			ExpenseLineOfBusiness, 
			BusinessUnitAndLineOfBusinessMatchAccountingData);
			
	EndIf;
	
EndProcedure

Procedure FillInBasedOnRevaluation(Basis, IntangibleAsset = Undefined)

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
	
	Organization = Catalogs.Companies.EmptyRef();
	Department = Catalogs.BusinessStructure.EmptyRef();
	
	ArrayOfLineNumbers = Undefined;
	ReportErrors = True;
	
	If TypeOf(FillingData) = Type("Structure") Then
		DocumentBasis = FillingData.DocumentBasis;
		ArrayOfLineNumbers = FillingData.ArrayOfLineNumbers;
		ReportErrors = FillingData.ReportErrors;
	Else
		DocumentBasis = FillingData;
	EndIf;
	
	Documents.IARevaluation2_4.FillInBasedOnInventory(ThisObject, ReportErrors, ArrayOfLineNumbers);
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite()

	ClearUnusedProps();
	
	If RecordInManAccounting And RecordInLocalAccounting Then
		DocumentInAnotherAccounting = Undefined;
	EndIf;
	
EndProcedure

Procedure ClearUnusedProps()
	
	PropertyValuesOfDependentProps = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_RevaluationOfIa(
												ThisObject, AuxiliaryAttributes());
												
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, PropertyValuesOfDependentProps, "IA");

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
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndIf
