
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillInSelectionDocument(FillingData);
		
	ElsIf FillInDataType = Type("CatalogRef.IntangibleAssets") 
		Or FillInDataType = Type("Array")
			And FillingData.Count() <> 0
			And TypeOf(FillingData[0]) = Type("CatalogRef.IntangibleAssets") Then
			
		FillInBasedOnIA(FillingData, Undefined);
		
	ElsIf FillInDataType = Type("DocumentRef.IntangibleAssetsInitialRecognition2_4") Then
		
		FillInDocumentOnBasisOfAcceptanceOfIA(FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.ChangeIntangibleAssetFinancialDetails2_4") Then
		
		FillInDocumentBasedOnChangingIAParameters(FillingData);
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.IntangibleAssetsCostAndAmortizationAdjustment.ItemsAndDimensionsSelectionParameters(ThisObject);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Comment = "";
	DocumentBasis = Undefined;
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "IA");
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "IA", "IntangibleAsset", Cancel);
	
	ItemDetailsParameters = 
		NonCurrentAssetsClientServer.ValuesOfPropertiesOfDependentDetails_AdjustmentOfCostAndDepreciationOfIa(ThisObject, AuxiliaryAttributes());
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckDocument(NotCheckedAttributeArray, Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.IntangibleAssetsCostAndAmortizationAdjustment.ItemsAndDimensionsSelectionParameters(ThisObject);
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
		NonCurrentAssetsInternal.CheckThatIAAreAcceptedForAccounting(ThisObject, Cancel);
		
	EndIf;
	
	FillInBankingDetailsBeforeWrite();
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "IA");
	
	ItemsAndDimensionsSelectionParameters = Documents.IntangibleAssetsCostAndAmortizationAdjustment.ItemsAndDimensionsSelectionParameters(ThisObject);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.IntangibleAssetsCostAndAmortizationAdjustment.AccountingAccountSettings_());
	
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
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("IntangibleAsset") Then
		FillInBasedOnIA(Basis.IntangibleAsset, Basis);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnIA(Basis, FilterValues)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	InitialIA = ?(TypeOf(Basis) = Type("Array"), Basis, CommonClientServer.ValueInArray(Basis));
	ListOfIA = NonCurrentAssets.ReturnIAAcceptedForAccounting(InitialIA, Date);
	
	If ListOfIA.Count() = 0 Then
		
		MessageText = NStr("vi = 'Tài sản cố định vô hình nên được tính đến.';
							|ru = 'Нематериальные активы должны быть приняты к учету';
							|en = 'Intangible assets should be entered in the books.'; fa = 'Intangible assets should be entered in the books.';
							|it = 'Attivi immateriali devono essere registrati in contabilità';
							|pl = 'Aktywa niematerialne należy przyjąć do ewidencji';
							|tr = 'Maddi olmayan varlıklar muhasebe kayıtlarına alınmalıdır'");
		Raise MessageText;
		
	EndIf;
	
	ValuesTypeOfAccountingObjects = Common.ObjectsAttributeValue(ListOfIA, "KindOfAccountingObject");
	For Each KeyAndValue In ValuesTypeOfAccountingObjects Do
	
		If ValueIsFilled(KindOfAccountingObjects) And KindOfAccountingObjects <> KeyAndValue.Value Then
			MessageText = NStr("vi = 'Cần phải chọn các đối tượng thuộc một loại: tài sản cố định vô hình hoặc chi phí Nghiên cứu phát triển';
								|ru = 'Необходимо выбрать объекты одного вида: либо НМА, либо расходы на НИОКР';
								|en = 'You need to select objects of one type: either intangible assets, or R&D expenses'; fa = 'You need to select objects of one type: either intangible assets, or R&D expenses';
								|it = 'È necessario selezionare gli oggetti dello stesso tipo: o beni immateriali o spese di ricerca e sviluppo';
								|pl = 'Należy wybrać obiekty jednego rodzaju: lub ANM, lub wydatki na R&D';
								|tr = 'Aynı türden nesnelerin seçilmesi gerekir: Madddi olmayan varlık veya Ar-Ge harcaması'");
			Raise MessageText;
		EndIf; 
		
		KindOfAccountingObjects = KeyAndValue.Value;
	EndDo; 
	
	InitialInformation = Catalogs.IntangibleAssets.InitialInformation(ListOfIA[0], Date);
	Organization = InitialInformation.Organization;
	Department = InitialInformation.Department;
	
	RecordInManAccounting = ValueIsFilled(InitialInformation.DocumentOfRecognitionManagementAccounting);
	PostInAccounting = ValueIsFilled(InitialInformation.DocumentOfRecognitionAccounting);
	RecordInTA = ValueIsFilled(InitialInformation.RecognitionDocumentTA);
	RecordInLocalAccounting = PostInAccounting Or RecordInTA;
	
	ApplicationOfTargetFinancing = InitialInformation.ApplicationOfTargetFinancing;

	If ApplicationOfTargetFinancing Then
		BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecrease = True;
	EndIf;

	For Each IntangibleAssetBasis In ListOfIA Do
		NewRow = IA.Add();
		NewRow.IntangibleAsset = IntangibleAssetBasis;
	EndDo;
	
	Documents.IntangibleAssetsCostAndAmortizationAdjustment.FillInByAccountingData(ThisObject);
	
EndProcedure

Procedure FillInDocumentOnBasisOfAcceptanceOfIA(Basis)

	QueryText = 
	"SELECT
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA
	|FROM
	|	Document.IntangibleAssetsInitialRecognition2_4 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.IntangibleAsset AS IntangibleAsset,
	|	TabularSection.KindOfAccountingObject AS KindOfAccountingObjects
	|FROM
	|	Document.IntangibleAssetsInitialRecognition2_4 AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Basis";
	
	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	
	QueryResult = Query.ExecuteBatch();
	FillInDocument_(QueryResult)
	
EndProcedure

Procedure FillInDocumentBasedOnChangingIAParameters(Basis)

	QueryText = 
	"SELECT
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Date AS Date,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.PostInAccounting AS PostInAccounting,
	|	DocumentData.RecordInTA AS RecordInTA,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting
	|FROM
	|	Document.ChangeIntangibleAssetFinancialDetails2_4 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.IntangibleAsset AS IntangibleAsset,
	|	TabularSection.IntangibleAsset.KindOfAccountingObject AS KindOfAccountingObjects
	|FROM
	|	Document.ChangeIntangibleAssetFinancialDetails2_4.IA AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Basis
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	
	QueryResult = Query.ExecuteBatch();
	FillInDocument_(QueryResult)
	
EndProcedure

Procedure FillInDocument_(QueryResult)

	If Not QueryResult[0].IsEmpty() Then
		
		Selection = QueryResult[0].Select();
		Selection.Next();
		FillPropertyValues(ThisObject, Selection);
		
		If TypeOf(DocumentBasis) = Type("DocumentRef.IntangibleAssetsInitialRecognition2_4")
			And ValueIsFilled(DocumentBasis) Then
			
			CostAdjustment = False;
			CostIncreaseRecording = False;
			CostDecreaseRecording = False;
			AdjustmentOfInitialCost = False;
			DepreciationAdjustment = True;
			DepreciationIncreaseRecording = True;
			BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease = True;
			IncludesDepreciationOfCurrentMonth = True;
			
		EndIf;
		
	EndIf;
	
	If QueryResult[1].IsEmpty() Then
		Return;
	EndIf;
		
	Selection = QueryResult[1].Select();
	While Selection.Next() Do
		
		If ValueIsFilled(KindOfAccountingObjects) And KindOfAccountingObjects <> Selection.KindOfAccountingObjects Then
			MessageText = NStr("vi = 'Cần phải chọn các đối tượng thuộc một loại: tài sản cố định vô hình hoặc chi phí Nghiên cứu phát triển';
								|ru = 'Необходимо выбрать объекты одного вида: либо НМА, либо расходы на НИОКР';
								|en = 'You need to select objects of one type: either IA, or R&D expenses'; fa = 'You need to select objects of one type: either IA, or R&D expenses';
								|it = 'È necessario selezionare gli oggetti dello stesso tipo: o beni immateriali o spese di ricerca e sviluppo';
								|pl = 'Należy wybrać obiekty jednego rodzaju: lub ANM, lub wydatki na R&D';
								|tr = 'Aynı türden nesnelerin seçilmesi gerekir: Madddi olmayan varlık veya Ar-Ge harcaması'");
			Raise MessageText;
		EndIf; 
		
		KindOfAccountingObjects = Selection.KindOfAccountingObjects;
		
		FillPropertyValues(IA.Add(), Selection);
		
	EndDo;
		
	InitialInformation = Catalogs.IntangibleAssets.InitialInformation(IA[0].IntangibleAsset);
	Organization = InitialInformation.Organization;
	Department = InitialInformation.Department;
	ApplicationOfTargetFinancing = InitialInformation.ApplicationOfTargetFinancing;
	
	If ApplicationOfTargetFinancing Then
		BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecrease = True;
	EndIf;
	
	Documents.IntangibleAssetsCostAndAmortizationAdjustment.FillInByAccountingData(ThisObject);
	
	IntangibleAssetsCostAndAmortizationAdjustmentLocalization.FillInDocument_(ThisObject, QueryResult);
	
EndProcedure
 
#EndRegion

#Region FillChecking

Procedure CheckDocument(NotCheckedAttributeArray, Cancel)

	If Not RecordInLocalAccounting And Not RecordInManAccounting Then
		MessageText = NStr("vi = 'Cần phản ánh chứng từ vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, kayıtlarının birinde yansıtılmalıdır'");
		Common.MessageToUser(MessageText,, "Object.PostInAccounting",, Cancel);
	EndIf;
	
	CheckTablePart(NotCheckedAttributeArray, Cancel);
	
EndProcedure

Procedure CheckTablePart(NotCheckedAttributeArray, Cancel)

	NotCheckedAttributeArray.Add("IA");
	NotCheckedAttributeArray.Add("IA.IntangibleAsset");
	NotCheckedAttributeArray.Add("IA.CostInAccounting");
	
	If IA.Count() = 0 Then
		
		MessageText = ?(KindOfAccountingObjects = Enums.IntangibleAssetsAccountingItemKinds.IntangibleAsset,
							NStr("vi = 'Không có một dòng nào được nhập vào danh sách tài sản cố định vô hình';
								|ru = 'Не введено ни одной строки в список ""Нематериальные активы""';
								|en = 'No line is entered into the ""Intangible assets"" list'; fa = 'No line is entered into the ""Intangible assets"" list';
								|it = 'Non è stata inserita alcuna riga nell''elenco ""Beni immateriali""';
								|pl = 'Nie wprowadzono żadnego wiersza do listy ""Aktywa niematerialne""';
								|tr = '""Maddi Olmayan Varlıklar"" listesine hiçbir satır girilmemiştir'"),
							NStr("vi = 'Không có một dòng nào được nhập vào danh sách ""Chi phí Nghiên cứu phát triển""';
								|ru = 'Не введено ни одной строки в список ""Расходы на НИОКР""';
								|en = 'No line is entered into the ""R&D expenses"" list'; fa = 'No line is entered into the ""R&D expenses"" list';
								|it = 'Non è stata inserita alcuna riga nell''elenco ""Spese di ricerca e sviluppo""';
								|pl = 'Nie wprowadzono żadnego wiersza do listy ""Wydatki na R&D""';
								|tr = '""Ar-Ge harcamaları"" listesine satır girilmemiştir'"));
							
		Common.MessageToUser(MessageText, ThisObject, "IA",, Cancel);
	EndIf; 
	
	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	MessageTemplateCostLocal = NStr("vi = 'Đối với tài sản cố định vô hình ""%1"" cần chỉ ra chi phí trong kế toán tài chính';
									|ru = 'Для НМА ""%1"" необходимо указать стоимость в регламентированном учете';
									|en = 'Specify cost in local accounting for the ""%1"" intangible assets'; fa = 'Specify cost in local accounting for the ""%1"" intangible assets';
									|it = 'Per i beni immateriali ""%1"" è necessario indicare il costo nella contabilità regolamentata';
									|pl = 'Dla ANM ""%1"" należy wskazać wartość w ewidencji reglamentowanej';
									|tr = 'Maddi olmayan varlık ""%1"" için düzenlenmiş muhasebedeki değeri belirtmek gerekir'");
	
	If KindOfAccountingObjects = Enums.IntangibleAssetsAccountingItemKinds.IntangibleAsset Then
		IAMessageTemplate = NStr("vi = 'Cột Tài sản vô hình trong hàng %1 của danh sách Tài sản vô hình không được điền';
								|ru = 'Не заполнена колонка ""Нематериальный актив"" в строке %1 списка ""Нематериальные активы""';
								|en = 'The ""Intangible asset"" column in line %1 of the ""Intangible assets"" list is not filled in'; fa = 'The ""Intangible asset"" column in line %1 of the ""Intangible assets"" list is not filled in';
								|it = 'Non è stata compilata la colonna ""Beni immateriali"" nella riga %1 dell''elenco ""Beni immateriali""';
								|pl = 'Nie wypełniono kolumny ""Aktyw niematerialny"" w wierszu %1 listy ""Aktywa niematerialne""';
								|tr = '""Maddi olmayan varlıklar"" listesinin %1 satırındaki ""Maddi olmayan varlık"" sütunu doldurulmamış'");
	Else
		IAMessageTemplate = NStr("vi = 'Cột ""Chi phí Nghiên cứu phát triển"" không được điền vào dòng %1 của danh sách ""Chi phí Nghiên cứu phát triển""';
								|ru = 'Не заполнена колонка ""Расходы на НИОКР"" в строке %1 списка ""Расходы на НИОКР""';
								|en = 'The ""R&D expenses"" column in line %1 of the ""R&D expenses"" list is not filled in'; fa = 'The ""R&D expenses"" column in line %1 of the ""R&D expenses"" list is not filled in';
								|it = 'Non è stata compilata la colonna ""Spese di ricerca e sviluppo"" nella riga %1 dell''elenco ""Spese di ricerca e sviluppo""';
								|pl = 'Nie wypełniono kolumny ""Wydatki na R&D"" w wierszu %1 listy ""Wydatki na R&D""';
								|tr = '""Ar-Ge harcamaları"" listesinin %1 satırındaki ""Ar-Ge harcamaları"" sütunu doldurulmamış'")
	EndIf; 
	
	For Each RowData In IA Do
		
		LineNumber = Format(RowData.LineNumber, "NG=");
		
		If Not ValueIsFilled(RowData.IntangibleAsset) Then
			
			MessageText = StrTemplate(IAMessageTemplate, LineNumber);
			Field = CommonClientServer.PathToTabularSection("IA", RowData.LineNumber, "IntangibleAsset");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If RowData.CostInAccounting = 0
			And RowData.CostInTaxAccounting = 0
			And RowData.CostTargetFinancing = 0
			And RecordInLocalAccounting
			And CostAdjustment
			And ComplianceCAAccountingIsKept Then
			
			MessageText = StrTemplate(MessageTemplateCostLocal, String(RowData.IntangibleAsset));
			Field = CommonClientServer.PathToTabularSection("IA", RowData.LineNumber, "IntangibleAsset");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
	EndDo; 
	
EndProcedure
 
#EndRegion

#Region Other

Procedure BlockData_()

	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.InitialIntangibleAssetsInformation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = IA;
	LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
	LockItem.SetValue("Organization", Organization);
	
	LockItem = Block.Add("InformationRegister.IntangibleAssetsRegistrationPlace");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = IA;
	LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
	
	Block.Lock(); 
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite()

	ClearUnusedProps();
	
	If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())))
		And Constants.ManagementAccountingCurrency.Get() = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization) Then
		
		For Each RowData In IA Do
			RowData.CostInManagementAccounting = RowData.CostInAccounting;
		EndDo; 
		
	EndIf; 
	
EndProcedure

Procedure ClearUnusedProps()
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.ValuesOfPropertiesOfDependentDetails_AdjustmentOfCostAndDepreciationOfIa(
		ThisObject, AuxiliaryAttributes());
	
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "IA");

EndProcedure

Function AuxiliaryAttributes()
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	AuxiliaryAttributes.Insert("IncomeTaxPayer", False);
	AuxiliaryAttributes.Insert("SupportPBU18", False);
	AuxiliaryAttributes.Insert("CalculationOfPermanentAndTemporaryDifferencesIsKept", False);

	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	AuxiliaryAttributes.Insert("UseFixedAssetAccountingByActivities", 
		GetFunctionalOption("UseFixedAssetAccountingByActivities"));
	
	IntangibleAssetsCostAndAmortizationAdjustmentLocalization.AddAuxiliaryDetails(ThisObject, AuxiliaryAttributes);
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndRegion

#EndIf
