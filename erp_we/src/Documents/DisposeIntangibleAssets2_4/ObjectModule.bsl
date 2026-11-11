#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocument();
	
	FillInDataType = TypeOf(FillingData);
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.IntangibleAssets") Then
		FillInBasedOnIntangibleAsset(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.DisposeIntangibleAssets2_4") Then
		FillInBasedOnWriteOff(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.IntangibleAssetsPhysicalCount") Then
		FillInBasedOnInventory( FillingData);
	EndIf;
	
	DisposeIntangibleAssetsLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	NotCheckedAttributeArray = New Array;
	
	If DimensionCorrespondsToIAToWriteOff Then
		CommonClientServer.DeleteValueFromArray(CheckedAttributes, "DimensionOfExpenses");
		CommonClientServer.DeleteValueFromArray(CheckedAttributes, "AssetsLiabilitiesDimension");
	EndIf;

	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesForDependentDetails_WriteOffIA(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	ItemsAndDimensionsSelectionParameters = Documents.DisposeIntangibleAssets2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
		
	CheckDocument(Cancel);
	CheckIA(NotCheckedAttributeArray, Cancel);
		
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	DisposeIntangibleAssetsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

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
	
	GLAccountSettingsServer.BeforeWrite(ThisObject, Documents.DisposeIntangibleAssets2_4.AccountingAccountSettings_());
	
	ItemsAndDimensionsSelectionParameters = Documents.DisposeIntangibleAssets2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DisposeIntangibleAssetsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DisposeIntangibleAssetsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentInAnotherAccounting   = Undefined;
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "IA");
	
	DisposeIntangibleAssetsLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	BlockReadableData();
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	DisposeIntangibleAssetsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	DisposeIntangibleAssetsLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = True;
	
	ItemsAndDimensionsSelectionParameters = Documents.DisposeIntangibleAssets2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure BlockReadableData()
	
	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.InitialIntangibleAssetsInformation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = IA;
	LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
	LockItem.SetValue("Organization", Organization);
	
	LockItem = Block.Add("InformationRegister.IntangibleAssetsAccountingProcedure");
	LockItem.Mode = DataLockMode.Shared;
	LockItem.DataSource = IA;
	LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
	LockItem.SetValue("Organization", Organization);
	
	LockItem = Block.Add("InformationRegister.IntangibleAssetsRegistrationPlace");
	LockItem.Mode = DataLockMode.Shared;
	LockItem.DataSource = IA;
	LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");

	If RecordInLocalAccounting Then
		LockItem = Block.Add("InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = IA;
		LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
		LockItem.SetValue("Organization", Organization);
	EndIf;
	
	If RecordInManAccounting Then
		LockItem = Block.Add("InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = IA;
		LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
		LockItem.SetValue("Organization", Organization);
		
		LockItem = Block.Add("InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting");
		LockItem.Mode = DataLockMode.Shared;
		LockItem.DataSource = IA;
		LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
		LockItem.SetValue("Organization", Organization);
	EndIf;
	
	Block.Lock(); 
	
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
	
	DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "IsFolder");
	
	If DetailsOfFoundation.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể ghi giảm trên cơ sở nhóm TSCĐ vô hình.
			|Hãy chọn TSCĐ vô hình. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Списание на основании группы НМА невозможно.
			|Выберите НМА. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot write off based on intangible assets group. 
			|Select intangible assets. To expand the group, press Ctrl+Down.'; fa = 'Cannot write off based on intangible assets group. 
			|Select intangible assets. To expand the group, press Ctrl+Down.';
			|it = 'Cancellazione contabile in base al gruppo Beni Immateriali non è possibile.
			|Selezionate il bene immateriale. Per aprire il gruppo utilizzate i tasti Ctrl e la freccia giù.';
			|pl = 'Przyjecie do ewidencji wartości niematerialnych na podstawie grupy wartości niematerialnych jest niemożliwe.
			|Wybierz wartości niematerialne. Aby rozwinąć grupę użyj klawiszy Ctrl oraz strzałkę w dól.';
			|tr = 'Maddi olmayan varlık grubuna dayalı bir modernizasyon oluşturmak mümkün değildir. 
			| Maddi olmayan varlık seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	InitialInformation = Catalogs.IntangibleAssets.InitialInformation(Basis, Date);

	RecordInManAccounting = ValueIsFilled(InitialInformation.DocumentOfRecognitionManagementAccounting);
	PostInAccounting = ValueIsFilled(InitialInformation.DocumentOfRecognitionAccounting);
	RecordInTA = ValueIsFilled(InitialInformation.RecognitionDocumentTA);
	RecordInLocalAccounting = PostInAccounting Or RecordInTA;
	
	IntangibleAssetsRegistrationPlace = NonCurrentAssets.IntangibleAssetsRegistrationPlace(Basis);
	FillPropertyValues(ThisObject, IntangibleAssetsRegistrationPlace);
	
	LineOfATabularSection = IA.Add();
	LineOfATabularSection.IntangibleAsset = Basis;
	
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

Procedure FillInBasedOnWriteOff(Basis, IntangibleAsset = Undefined)

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
		PostInAccounting = Not BaseObject.PostInAccounting;
		RecordInTA = Not BaseObject.RecordInTA;
		RecordInManAccounting = Not BaseObject.RecordInManAccounting;
	Else	
		RecordInManAccounting = True;
		PostInAccounting = True;
		RecordInTA = False;
	EndIf;
	
	RecordInLocalAccounting = PostInAccounting Or RecordInTA;
	
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
	
	Documents.DisposeIntangibleAssets2_4.FillInBasedOnInventory(ThisObject, ReportErrors, ArrayOfLineNumbers);
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite()

	ClearUnusedProps();
	
	If RecordInManAccounting And RecordInLocalAccounting Then
		DocumentInAnotherAccounting = Undefined;
	EndIf;
	
	If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())))
		And Constants.ManagementAccountingCurrency.Get() = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization) Then
		
		For Each RowData In IA Do
			RowData.AmountManagementAccounting = RowData.ChargeAmountAccounting;
			RowData.ResidualValueMan = RowData.ResidualValueLocal;
		EndDo; 
		
	EndIf; 
	
EndProcedure

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	PropertyValuesOfDependentProps = NonCurrentAssetsClientServer.PropertyValuesForDependentDetails_WriteOffIA(ThisObject, AuxiliaryAttributes);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, PropertyValuesOfDependentProps, "IA");
	
EndProcedure

Procedure CheckDocument(Cancel)
	
	If DimensionCorrespondsToIAToWriteOff
		And ValueIsFilled(ExpenseItem) Then
		
		TypeOfAnalytics = Common.ObjectAttributeValue(ExpenseItem, "ValueType");
		
		If Not TypeOfAnalytics.ContainsType(Type("CatalogRef.IntangibleAssets")) Then
			MessageText = NStr("vi = 'Chỉ số không thể tương ứng với tài sản cố định vô hình, bởi vì kiểu chỉ số dạng không phải là TSCĐ vô hình.
								  |Cần chọn dạng khác hoặc tắt sử dụng hộp kiểm ""Chỉ số tương ứng với TSCĐ vô hình được ghi giảm"".';
								  |ru = 'Аналитика не может соответствовать списываемому нематериальному активу, т.к. тип аналитики статьи не является НМА.
								  |Необходимо либо выбрать другую статью, либо отключить флаг ""Аналитика соответствует списываемому НМА"".';
								  |en = 'The dimension cannot correspond to the intangible asset to write-off as the item dimension type is not an IA.
								  |Select another item or clear the ""Dimension corresponds to IA to write-off"" checkbox.'; fa = 'The dimension cannot correspond to the intangible asset to write-off as the item dimension type is not an IA.
								  |Select another item or clear the ""Dimension corresponds to IA to write-off"" checkbox.';
								  |it = 'Аналитика не может соответствовать списываемому нематериальному активу, т.к. тип аналитики статьи не является НМА.
								  |Необходимо либо выбрать другую статью, либо отключить флаг ""Аналитика соответствует списываемому НМА"".';
								  |pl = 'The dimension cannot correspond to the intangible asset to write-off as the item dimension type is not an IA.
								  |Select another item or clear the ""Dimension corresponds to IA to write-off"" checkbox.';
								  |tr = 'Boyut, kayıttan düşülen maddi olmayan varlığa karşılık gelemez çünkü kalemin boyut türü maddi olmayan varlık değildir.
								  |Ya başka bir kalem seçmeniz ya da ""Boyut, kayıttan düşülen maddi olmayan varlığa karşılık gelmektedir"" işaretini devre dışı bırakmanız gerekmektedir.'");
			Common.MessageToUser(MessageText, ThisObject, "DimensionCorrespondsToIAToWriteOff",, Cancel);
		EndIf;

	EndIf;
	
EndProcedure

Procedure CheckIA(NotCheckedAttributeArray, Cancel)

	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "IA", "IntangibleAsset", Cancel);
	
	
EndProcedure

Function AuxiliaryAttributes()
	
	DateOfParameters = EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()));

	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, DateOfParameters));
	
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndIf
