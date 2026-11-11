
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocument();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Assets") Then
		FillInBasedOnObjectOfOperation(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.DisposeFixedAssets2_4") Then
		FillInBasedOnWriteOff(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.LeaseTermAdjustment") Then
		FillInOnBasisOfRentalTermsADJUSTMENTChanges(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		FillInBasedOnInventory(FillingData);
	EndIf;
	
	DisposeFixedAssetsLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If DimensionCorrespondsToFAToWriteOff Then
		CommonClientServer.DeleteValueFromArray(CheckedAttributes, "DimensionOfExpenses");
		CommonClientServer.DeleteValueFromArray(CheckedAttributes, "AssetsLiabilitiesDimension");
	EndIf;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	CheckCorrectionModeFromLastDate(Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.DisposeFixedAssets2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesForDependentBankDetails_FADebiting(
									ThisObject, AuxiliaryAttributes());
									
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckDocument(Cancel);
	CheckFixedAssets(NotCheckedAttributeArray, Cancel);
	CheckIncomingMC(Cancel);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "RecordedAsReceivedTangibleAssets";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	DisposeFixedAssetsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

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
	
	ItemsAndDimensionsSelectionParameters = Documents.DisposeFixedAssets2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	GLAccountSettingsServer.BeforeWrite(ThisObject, Documents.DisposeFixedAssets2_4.AccountingAccountSettings_());
	
	FillInBankingDetailsBeforeWrite();
	
	DisposeFixedAssetsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);  

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DisposeFixedAssetsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentBasis = Undefined;
	DocumentInAnotherAccounting = Undefined;
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
	DisposeFixedAssetsLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	BlockReadableData();
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	DisposeFixedAssetsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	DisposeFixedAssetsLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	Date = BegOfDay(CurrentSessionDate());
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	ItemsAndDimensionsSelectionParameters = Documents.DisposeFixedAssets2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure BlockReadableData()

	// It is necessary to block the data that is used when recording movements.
	// For example, data registers of information that are used to fill in missing resources.
	
	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.InitialFixedAssetsInformation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	LockItem.SetValue("Organization", Organization);
	
	LockItem = Block.Add("InformationRegister.FixedAssetsAccountingProcedure");
	LockItem.Mode = DataLockMode.Shared;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	LockItem = Block.Add("InformationRegister.FALocation");
	LockItem.Mode = DataLockMode.Shared;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	If RecordInManAccounting Then
		
		LockItem = Block.Add("InformationRegister.FixedAssetsAccountingProcedureManagementAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
		
		LockItem = Block.Add("InformationRegister.FixedAssetDepreciationParametersManagementAccounting");
		LockItem.Mode = DataLockMode.Shared;
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
		
	EndIf;
	
	DisposeFixedAssetsLocalization.AddDataBlockingWhenConducting(ThisObject, Block);
	
	Block.Lock(); 
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("FixedAsset") Then
		
		FillInBasedOnObjectOfOperation(Basis.FixedAsset);
		
	ElsIf Basis.Property("Basis1")
		And Basis.Basis1.Count() <> 0
		And (TypeOf(Basis.Basis1[0]) = Type("DocumentRef.Decomissioning")
			Or TypeOf(Basis.Basis1[0]) = Type("DocumentRef.OtherGoodsRecordingAsReceived")) Then
			
		FillInOnBasisOfDisposalOfGoodsAndMaterials(Basis);
		
	ElsIf Basis.Property("DocumentBasis")
		And TypeOf(Basis.DocumentBasis) = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		
		FillInBasedOnInventory(Basis);
		
	ElsIf Basis.Property("BusinessOperation") Then
		
		If Basis.BusinessOperation = Enums.BusinessTransactions.WriteOffSubAssetsComponentsOfDepreciation
			And RecordInTA Then
			RecordInTA = False;
		EndIf;
		
	EndIf; 
	
	If Basis.Property("AdjustmentModeFromPreviousDate") Then
		AdjustmentModeFromPreviousDate = True;
	EndIf;
	
EndProcedure

Procedure FillInBasedOnObjectOfOperation(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	FAAttributes = Common.ObjectAttributesValues(Basis, "IsFolder,OSType");
	
	If FAAttributes.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể ghi giảm nhóm TSCĐ.
			|Hãy chọn TSCĐ. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Списание группы ОС невозможно.
			|Выберите ОС. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot write off fixed assets group.
			|Select fixed assets. To expand the group, press Ctrl+Down.'; fa = 'Cannot write off fixed assets group.
			|Select fixed assets. To expand the group, press Ctrl+Down.';
			|it = 'Non è possibile effettuare la cancellazione contabile del gruppo di Capitale Fisso.
			|Selezionate il capitale fisso. Per aprire il gruppo utilizzate i tasti Ctrl e la freccia giù.';
			|pl = 'Wyksięgowania środków trwałych jest niemożliwe.
			|Wybierz środki trwałe. Aby rozwinąć grupę użyj klawiszy Ctrl oraz strzałkę w dól.';
			|tr = 'Sabit kıymet gruplarını iptal edemezsiniz. 
			|Sabit kıymet seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	InitialInformation = Catalogs.Assets.InitialInformation(Basis, Date);
	
	If InitialInformation.BUState = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting
		Or InitialInformation.StateOfTheUU = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting Then	
		MessageText = NStr("vi = 'Tài sản cố định ""%1"" đã được tiếp nhận vào thuê. 
                                        |Cần sử dụng chứng từ ""Trả lại TSCĐ cho người cho thuê"".';
                                        |ru = 'Основное средство ""%1"" поступило в аренду. 
                                        |Необходимо использовать документ ""Возврат ОС арендатору"".';
                                        |en = 'The ""%1"" fixed asset was leased.
                                        |Use the ""Fixed assets return to lessee"" document.'; fa = 'The ""%1"" fixed asset was leased.
                                        |Use the ""Fixed assets return to lessee"" document.';
                                        |it = 'L''oggetto di capitale fisso ""%1"" è stato preso in affitto. 
                                        |Bisogna utilizzare il documento ""Restituzione del capitale fisso al proprietario concedente"".';
                                        |pl = 'Środek trwały ""%1"" wpłynęło do dzierżawy.
                                        |n Należy wykorzystać dokument ""Zwrot środków trwałych do dzierżawcy"".';
                                        |tr = 'Sabit kıymet ""%1"" kiralanmıştır. 
                                        |""Sabit Kıymetlerin Kiracıya İadesi"" belgesinin kullanılması gerekmektedir.'");
		MessageText = StrTemplate(MessageText, String(Basis));
		Raise MessageText;
	EndIf; 
	
	If FAAttributes.OSType = Enums.FATypes.Node
		Or FAAttributes.OSType = Enums.FATypes.DepreciationComponent Then
		BusinessOperation = Enums.BusinessTransactions.WriteOffSubAssetsComponentsOfDepreciation;
	EndIf;
	
	LineOfATabularSection = FA.Add();
	LineOfATabularSection.FixedAsset = Basis;

	If BusinessOperation = Enums.BusinessTransactions.PartialFixedAssetsDisposal Then
		LineOfATabularSection.ResidualValueMan = InitialInformation.ResidualValueMan;
		LineOfATabularSection.ResidualValueLocal = InitialInformation.ResidualValueLocal;
	EndIf;
	
	RecordInManAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentMA);
	PostInAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentAC);
	RecordInTA = ValueIsFilled(InitialInformation.CommissioningDocumentTA);
	RecordInLocalAccounting = PostInAccounting Or RecordInTA;
	
	Organization = InitialInformation.Organization;
	Department = InitialInformation.FixedAssetsLocation;
	
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
	
	Documents.DisposeFixedAssets2_4.FillInAmountOfWriteOffBasedOnDisposalOfGoodsAndMaterials(ThisObject);
	Documents.DisposeFixedAssets2_4.FillInExpenseItemRetirement(Organization, Date, FA, RetirementItem);
	
EndProcedure

Procedure FillInBasedOnWriteOff(Basis, FixedAsset = Undefined)

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

Procedure FillInOnBasisOfDisposalOfGoodsAndMaterials(Basis)
	
	Date = Basis.Date;
	Organization = Basis.Organization;
	
	QueryText = 
	"SELECT
	|	LotsOfGoodsAndMaterials.Ref AS Ref,
	|	LotsOfGoodsAndMaterials.FixedAsset AS FixedAsset
	|
	|INTO LotsOfGoodsAndMaterials
	|
	|FROM
	|	Catalog.LotsOfInventoryInOperation AS LotsOfGoodsAndMaterials
	|WHERE
	|	LotsOfGoodsAndMaterials.Ref IN (&ListOfParties)
	|	AND LotsOfGoodsAndMaterials.OperationCategory.AccountAsGroupFA
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TRUE
	|FROM
	|	AccumulationRegister.InventoryInOperation.Balance(
	|		&Date,
	|		Lot IN
	|			(SELECT
	|				LotsOfGoodsAndMaterials.Ref
	|			FROM
	|				LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials)) AS InventoryInOperation
	|
	|WHERE
	|	InventoryInOperation.CountBalance > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LotsOfGoodsAndMaterials.FixedAsset AS FixedAsset,
	|	FALocation.FixedAssetsLocation AS FixedAssetsLocation,
	|
	|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan, 0) AS ResidualValueMan,
	|	ISNULL(OSBUDepreciationParameters.ResidualValueMan, 0) AS ResidualValueLocal,
	|
	|	CASE
	|		WHEN NOT FixedAssetsAccountingProcedureManagementAccounting.FixedAsset IS NULL
	|			THEN FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.Recognized_)
	|		WHEN AccountingProcedureForOSBU.BUState IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS RecordInManAccounting,
	|
	|	CASE
	|		WHEN NOT AccountingProcedureForOSBU.FixedAsset IS NULL
	|			THEN AccountingProcedureForOSBU.BUState = VALUE(Enum.FixedAssetsStates.Recognized_)
	|					OR AccountingProcedureForOSBU.StateTa = VALUE(Enum.FixedAssetsStates.Recognized_)
	|		WHEN FixedAssetsAccountingProcedureManagementAccounting.State IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS RecordInLocalAccounting
	|
	|FROM
	|	LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials
	|
	|		LEFT JOIN InformationRegister.FALocation.SliceLast(
	|			&Date, 
	|			FixedAsset IN (
	|				SELECT
	|					LotsOfGoodsAndMaterials.FixedAsset
	|				FROM
	|					LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials)) AS FALocation
	|		ON FALocation.FixedAsset = LotsOfGoodsAndMaterials.FixedAsset
	|
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&Date, 
	|			Organization = &Organization 
	|			AND FixedAsset IN (
	|				SELECT
	|					LotsOfGoodsAndMaterials.FixedAsset
	|				FROM
	|					LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials)) AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = LotsOfGoodsAndMaterials.FixedAsset
	|
	|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|			&Date, 
	|			Organization = &Organization 
	|			AND FixedAsset IN (
	|				SELECT
	|					LotsOfGoodsAndMaterials.FixedAsset
	|				FROM
	|					LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials)) AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.FixedAsset = LotsOfGoodsAndMaterials.FixedAsset
	|
	|		LEFT JOIN InformationRegister.OSBUDepreciationParameters.SliceLast(
	|			&Date, 
	|			Organization = &Organization 
	|			AND FixedAsset IN (
	|				SELECT
	|					LotsOfGoodsAndMaterials.FixedAsset
	|				FROM
	|					LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials)) AS OSBUDepreciationParameters
	|		ON OSBUDepreciationParameters.FixedAsset = LotsOfGoodsAndMaterials.FixedAsset
	|
	|		LEFT JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
	|			&Date, 
	|			Organization = &Organization 
	|			AND FixedAsset IN (
	|				SELECT
	|					LotsOfGoodsAndMaterials.FixedAsset
	|				FROM
	|					LotsOfGoodsAndMaterials AS LotsOfGoodsAndMaterials)) AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FixedAssetDepreciationParametersManagementAccounting.FixedAsset = LotsOfGoodsAndMaterials.FixedAsset";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Basis.Organization);
	Query.SetParameter("ListOfParties", Basis.ListOfParties);
	
	Result = Query.ExecuteBatch();
	
	If Result[Result.UBound()-1].IsEmpty() Then
		BusinessOperation = Enums.BusinessTransactions.DisposeFixedAssets;
	Else
		BusinessOperation = Enums.BusinessTransactions.PartialFixedAssetsDisposal;
	EndIf;
	
	Selection = Result[Result.UBound()].Select();
	While Selection.Next() Do
	
		RowData = FA.Add();
		RowData.FixedAsset = Selection.FixedAsset;
		
		Department = Selection.FixedAssetsLocation;
		RecordInManAccounting = Selection.RecordInManAccounting;
		RecordInLocalAccounting = Selection.RecordInLocalAccounting;
		
		RowData.ResidualValueMan = Selection.ResidualValueMan;
		RowData.ResidualValueLocal = Selection.ResidualValueLocal;
			
	EndDo;
	
	If Basis.Basis1.Count() = 1 Then
		
		DocumentBasis = Basis.Basis1[0];
		
	ElsIf Basis.Basis1.Count() > 1 Then
		
		For Each DocumentBasis In Basis.Basis1 Do
			
			RowData = Basis1.Add();
			RowData.DocumentBasis = DocumentBasis;
			
		EndDo;
		
	EndIf;

	Documents.DisposeFixedAssets2_4.FillInAmountOfWriteOffBasedOnDisposalOfGoodsAndMaterials(ThisObject);
	Documents.DisposeFixedAssets2_4.FillInExpenseItemRetirement(Organization, Date, FA, RetirementItem);
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite()

	ClearUnusedProps();
	
	If RecordInManAccounting And RecordInLocalAccounting Then
		DocumentInAnotherAccounting = Undefined;
	EndIf;
	
	If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())))
		And Constants.ManagementAccountingCurrency.Get() = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization) Then
		
		For Each RowData In FA Do
			RowData.AmountManagementAccounting = RowData.ChargeAmountAccounting;
			RowData.ResidualValueMan = RowData.ResidualValueLocal;
		EndDo; 
		
	EndIf; 
	
	If FA.Count() = 1 Then
		For Each RowData In RecordedAsReceivedTangibleAssets Do
			RowData.FixedAsset = FA[0].FixedAsset;
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInOnBasisOfRentalTermsADJUSTMENTChanges(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;

	ErrorText = Documents.DisposeFixedAssets2_4.FillInOnBasisOfRentalTermsADJUSTMENTChanges(ThisObject, Basis);
	
	If ErrorText <> Undefined Then
		Raise ErrorText;
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
	
	Documents.DisposeFixedAssets2_4.FillInBasedOnInventory(ThisObject, ReportErrors, ArrayOfLineNumbers);
	
EndProcedure

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesForDependentBankDetails_FADebiting(ThisObject, AuxiliaryAttributes);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "FA,RecordedAsReceivedTangibleAssets,Basis1");
	
EndProcedure

Procedure CheckDocument(Cancel)
	
	If DimensionCorrespondsToFAToWriteOff
		And ValueIsFilled(ExpenseItem) Then
		
		TypeOfAnalytics = Common.ObjectAttributeValue(ExpenseItem, "ValueType");
		
		If Not TypeOfAnalytics.ContainsType(Type("CatalogRef.Assets")) Then
			MessageText = NStr("vi = 'Chỉ số không thể tương ứng với tài sản cố định hữu hình, bởi vì kiểu chỉ số dạng không phải là đối tượng sử dụng.
								  |Cần chọn dạng khác hoặc tắt sử dụng hộp kiểm ""Chỉ số tương ứng với TSCĐ hữu hình được ghi giảm"".';
								  |ru = 'Аналитика не может соответствовать списываемому основному средству, т.к. тип аналитики статьи не является объектом эксплуатации.
								  |Необходимо либо выбрать другую статью, либо отключить флаг ""Аналитика соответствует списываемому ОС"".';
								  |en = 'The dimension cannot correspond to the fixed asset to write-off as the item dimension type is not an asset.
								  |Select another item or clear the ""Dimension corresponds to FA to write-off"" checkbox.'; fa = 'The dimension cannot correspond to the fixed asset to write-off as the item dimension type is not an asset.
								  |Select another item or clear the ""Dimension corresponds to FA to write-off"" checkbox.';
								  |it = 'Аналитика не может соответствовать списываемому основному средству, т.к. тип аналитики статьи не является объектом эксплуатации.
								  |Необходимо либо выбрать другую статью, либо отключить флаг ""Аналитика соответствует списываемому ОС"".';
								  |pl = 'The dimension cannot correspond to the fixed asset to write-off as the item dimension type is not an asset.
								  |Select another item or clear the ""Dimension corresponds to FA to write-off"" checkbox.';
								  |tr = 'Boyut, kayıttan düşülen sabit kıymete karşılık gelemez çünkü kalemin boyut türü bir varlık değildir.
								  |Ya başka bir kalem seçmeniz ya da ""Boyut, kayıttan düşülen sabit kıymete karşılık gelmektedir"" işaretini devre dışı bırakmanız gerekmektedir.'");
			Common.MessageToUser(MessageText, ThisObject, "DimensionCorrespondsToFAToWriteOff",, Cancel);
		EndIf;

	EndIf;
		
EndProcedure

Procedure CheckFixedAssets(NotCheckedAttributeArray, Cancel)

	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	NonCurrentAssetsInternal.CheckThatFAHasNotBeenTransferredToFinLease(ThisObject, Cancel);

	If BusinessOperation = Enums.BusinessTransactions.DisposeFixedAssets
		Or BusinessOperation = Enums.BusinessTransactions.PartialFixedAssetsDisposal Then
		NonCurrentAssetsInternal.CheckThatFAHaveBeenSelected(ThisObject, "FA", "FixedAsset", Cancel);
	ElsIf BusinessOperation = Enums.BusinessTransactions.WriteOffSubAssetsComponentsOfDepreciation Then
		NonCurrentAssetsInternal.CheckThatComponentNodesAreSelected(ThisObject, "FA", "FixedAsset", Cancel);
	EndIf;

		
EndProcedure

Procedure CheckIncomingMC(Cancel)
	
	If RecordedAsReceivedTangibleAssets.Count() = 0
		Or FA.Count() < 2 Then
		Return;
	EndIf;
	
	ListOfFA = New Array;
	For Each RowData In FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
	EndDo;
	
	MessageTemplate = NStr("vi = 'Cần chọn tài sản cố định từ danh sách trong dòng %1 của danh sách ""Nguyên vật liệu""';
							|ru = 'Необходимо выбрать основное средство из списка в строке %1 списка ""Материалы""';
							|en = 'Select a fixed asset from the list in the %1 line of the ""Materials"" list'; fa = 'Select a fixed asset from the list in the %1 line of the ""Materials"" list';
							|it = 'È necessario selezionare l''immobilizzazione dall''elenco nella riga %1 dell''elenco ""Materiali""';
							|pl = 'Należy wybrać środek trwały z listy w wierszu %1 listy ""Materiały""';
							|tr = '""Malzemeler"" listesinin %1 satırındaki listeden bir sabit kıymet seçmek gereklidir'");
	For Each RowData In RecordedAsReceivedTangibleAssets Do
		
		If ValueIsFilled(RowData.FixedAsset)
			And ListOfFA.Find(RowData.FixedAsset) = Undefined Then
			MessageText = StrTemplate(MessageTemplate, RowData.LineNumber);
			Field = CommonClientServer.PathToTabularSection("RecordedAsReceivedTangibleAssets", RowData.LineNumber, "FixedAsset");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf;
	
	EndDo;
	
EndProcedure

Procedure CheckCorrectionModeFromLastDate(Cancel)
	
	If Not AdjustmentModeFromPreviousDate
		Or Not ValueIsFilled(DateOfDeduction) Then
		Return
	EndIf;
	
	If DateOfDeduction >= BegOfMonth(Date)
		And ValueIsFilled(Date) Then
		MessageText = NStr("vi = 'Ngày ghi giảm phải sớm hơn ngày đầu tháng lập chứng từ';
							|ru = 'Дата списания должна быть раньше начала месяца, в котором оформлен документ';
							|en = 'The write-off date must be earlier than the beginning of the month in which the document is created'; fa = 'The write-off date must be earlier than the beginning of the month in which the document is created';
							|it = 'La data di storno non può essere precedente all''inizio del mese nel quale è stato registrato il documento';
							|pl = 'Data rozchodu powinna być wcześniejsza niż początek miesiąca, w którym jest utworzony dokument';
							|tr = 'Mahsup tarihi, belgenin düzenlendiği ayın başından önce olmalıdır'");
		Common.MessageToUser(MessageText, ThisObject, "DateOfDeduction",, Cancel);
	ElsIf Not NonCurrentAssets.VNAManagementIsUsed_2_4(DateOfDeduction) Then
		MessageText = NStr("vi = 'Ngày ghi giảm không được sớm hơn ngày bắt đầu ghi nhận tài sản dài hạn phiên bản 2.4';
							|ru = 'Дата списания должна быть не раньше начала учета внеоборотных активов версии 2.4';
							|en = 'The write-off date must not be earlier than the start of fixed and intangible assets accounting version 2.4'; fa = 'The write-off date must not be earlier than the start of fixed and intangible assets accounting version 2.4';
							|it = 'La data di storno non deve essere precedente all''inizio della contabilità degli attivi non correnti della versione 2.4';
							|pl = 'Data rozchodu powinna być nie wcześniej początku ewidencji aktywów pozaobrotowych wersji 2.4';
							|tr = 'Mahsup tarihi, duran varlıkların muhasebeleştirilmeye başlandığı tarihten önce olmamalıdır versiyon 2.4'");
		Common.MessageToUser(MessageText, ThisObject, "DateOfDeduction",, Cancel);
	EndIf;
	
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
