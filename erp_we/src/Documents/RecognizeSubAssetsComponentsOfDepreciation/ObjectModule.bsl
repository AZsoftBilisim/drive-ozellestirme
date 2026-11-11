
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut(FillingData);
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Assets") Then
		FillInBasedOnObjectOfOperation(FillingData);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.RecognizeSubAssetsComponentsOfDepreciation.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Comment = "";
	DocumentInAnotherAccounting = Undefined;
	
	InitializeDocumentBeforeFillingItOut();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "DepreciationComponents");
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = 
		NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceOfDepreciationComponentNodesForAccounting(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckHeaderDetails_(Cancel);
	CheckDepreciationComponents(NotCheckedAttributeArray, Cancel);
	CheckFixedAssets(Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.RecognizeSubAssetsComponentsOfDepreciation.ItemsAndDimensionsSelectionParameters();
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
		NonCurrentAssetsInternal.CheckPossibilityOfTakingIntoAccountFA(ThisObject, Cancel);
	EndIf;
	
	FillInBankingDetailsBeforeWrite();
	
	ItemsAndDimensionsSelectionParameters = Documents.RecognizeSubAssetsComponentsOfDepreciation.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "DepreciationComponents");
	
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

Procedure InitializeDocumentBeforeFillingItOut(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If Not ValueIsFilled(FinancialAccountingGroup) Then
		FinancialAccountingGroup = Catalogs.NonCurrentAssetsAccountingGroups.DefaultValue(Enums.KindsOfNonCurrentAssets.FixedAsset);
	EndIf; 
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	NonCurrentAssetsClientServer.WhenChangingDetails_AcceptanceOfDepreciationComponentsForAccountingUnits(
		ThisObject, 
		AuxiliaryAttributes(), 
		"Organization,RecordInManAccounting,RecordInLocalAccounting");
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("RecordInManAccounting")
		Or Basis.Property("PostInAccounting") Then
		
		RecordInManAccounting = Basis.RecordInManAccounting;
		RecordInLocalAccounting = Basis.PostInAccounting;
		
	EndIf; 
	
	If Basis.Property("Date") Then
		Date = Basis.Date;
	EndIf;
	
	If Basis.Property("Organization") Then
		Organization = Basis.Organization;
	EndIf;

	If Basis.Property("FixedAsset") Then
		FillInBasedOnObjectOfOperation(Basis.FixedAsset);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnObjectOfOperation(FixedAsset)
	
	If Not ValueIsFilled(FixedAsset) Then
		Return;
	EndIf;
	
	If TypeOf(FixedAsset) = Type("Array") Then
		ListOfFA = FixedAsset;
	Else
		ListOfFA = CommonClientServer.ValueInArray(FixedAsset);
	EndIf;
	
	NonCurrentAssetsInternal.CheckCreationOfDocumentBasedOnFAGroup(ListOfFA);
	
	DetailsOfBases = Common.ObjectsAttributesValues(ListOfFA, "IsFolder,OSType");
	
	For Each ArrayElement In ListOfFA Do
		
		LineOfATabularSection = DepreciationComponents.Add();

		FAAttributes = DetailsOfBases.Get(ArrayElement);
		
		If FAAttributes.OSType <> Enums.FATypes.Node
			And FAAttributes.OSType <> Enums.FATypes.DepreciationComponent
			And FAAttributes.OSType <> Enums.FATypes.Asset Then
			
			MessageText = NStr("vi = 'Việc tạo chứng từ chỉ khả dụng đối với các kiểu tài sản cố định ""Tài sản đang vận hành"", ""Thành phần khấu hao"" và ""Bộ phận"".';
								|ru = 'Оформление документа доступно только для типов ОС ""Объект эксплуатации"", ""Компонент амортизации"", ""Узел"".';
								|en = 'You can register the document only for the ""Asset"", ""Depreciation component"", ""Sub-asset"" fixed asset types.'; fa = 'You can register the document only for the ""Asset"", ""Depreciation component"", ""Sub-asset"" fixed asset types.';
								|it = 'You can register the document only for the ""Asset"", ""Depreciation component"", ""Sub-asset"" fixed asset types.';
								|pl = 'You can register the document only for the ""Asset"", ""Depreciation component"", ""Sub-asset"" fixed asset types.';
								|tr = 'Belge düzenleme işlemi sadece ""İşlem nesnesi"", ""Amortisman bileşeni"" ve ""Alt varlık"" sabit kıymet türleri için kullanılabilir.'");
			Raise(MessageText);
			
		EndIf;
		
		If FAAttributes.OSType = Enums.FATypes.Node
			Or FAAttributes.OSType = Enums.FATypes.DepreciationComponent Then
			
			LineOfATabularSection.DepreciationComponent = ArrayElement;
		Else
			LineOfATabularSection.FixedAsset = ArrayElement;
		EndIf;
		
	EndDo;
	
	Documents.RecognizeSubAssetsComponentsOfDepreciation.FillInCost(ThisObject);
	
EndProcedure

#EndRegion

#Region FillChecking

Procedure CheckHeaderDetails_(Cancel)

	If Not RecordInLocalAccounting And Not RecordInManAccounting Then
		MessageText = NStr("vi = 'Cần phản ánh chứng từ vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, kayıtlarının birinde yansıtılmalıdır'");
		Common.MessageToUser(MessageText,, "Object.RecordInLocalAccounting",, Cancel);
	EndIf;

	NonCurrentAssetsInternal.CheckFACostGenerationProcedure(ThisObject, Cancel);
	
EndProcedure

Procedure CheckDepreciationComponents(NotCheckedAttributeArray, Cancel)

	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "DepreciationComponents", "DepreciationComponent", Cancel);
	NonCurrentAssetsInternal.CheckThatComponentNodesAreSelected(ThisObject, "DepreciationComponents", "DepreciationComponent", Cancel);
	
	If ComplianceCAAccountingIsKept Then
		MessageTemplateResidualValueAC = NStr("vi = 'Giá trị thanh lý trong dòng %1 phải nhỏ hơn giá trị theo kế toán doanh nghiệp';
												|ru = 'Ликвидационная стоимость в строке %1 должна быть меньше стоимости по бух. учету';
												|en = 'Residual value in line %1 must be less than the cost in local accounting'; fa = 'Residual value in line %1 must be less than the cost in local accounting';
												|it = 'Residual value in line %1 must be less than the cost in local accounting';
												|pl = 'Residual value in line %1 must be less than the cost in local accounting';
												|tr = '%1 satırındaki artık değer muhasebe değerinden küçük olmalıdır.'");
		MessageTemplateResidualValueMA = NStr("vi = 'Giá trị thanh lý trong dòng %1 phải nhỏ hơn giá trị cho ex. kế toán';
												|ru = 'Ликвидационная стоимость в строке %1 должна быть меньше стоимости по упр. учету';
												|en = 'Residual value in line %1 must be less than the cost in mgmt accounting'; fa = 'Residual value in line %1 must be less than the cost in mgmt accounting';
												|it = 'Il costo di liquidazione nella riga %1 deve essere minore del costo secondo la contabilità gestionale';
												|pl = 'Wartość likwidacyjna w wierszu %1 powinna być mniejsza niż wartość według ewidencji administracyjnej';
												|tr = '%1 satırındaki artık değer yönetim muhasebesi değerinden küçük olmalıdır.'");
	Else
		MessageTemplateResidualValueAC = NStr("vi = 'Giá trị thanh lý trong dòng %1 phải nhỏ hơn giá trị theo tiền tệ kế toán tài chính';
												|ru = 'Ликвидационная стоимость в строке %1 должна быть меньше стоимости в валюте регл. учета';
												|en = 'Residual value in line %1 must be less than the cost in the local accounting currency'; fa = 'Residual value in line %1 must be less than the cost in the local accounting currency';
												|it = 'Residual value in line %1 must be less than the cost in the local accounting currency';
												|pl = 'Residual value in line %1 must be less than the cost in the local accounting currency';
												|tr = '%1 satırındaki tasfiye değeri yasal muhasebesi para biriminden küçük olmalıdır.'");
		MessageTemplateResidualValueMA = NStr("vi = 'Giá trị thanh lýtrong dòng %1 phải nhỏ hơn giá trị trong loại tiền kiểm soát. kế toán';
												|ru = 'Ликвидационная стоимость в строке %1 должна быть меньше стоимости в валюте упр. учета';
												|en = 'Residual value in line %1 must be less than the cost in the currency of mgmt accounting'; fa = 'Residual value in line %1 must be less than the cost in the currency of mgmt accounting';
												|it = 'Il costo di liquidazione nella riga %1 deve essere minore del costo in valuta della contabilità gestionale';
												|pl = 'Wartość likwidacyjna w wierszu %1 musi być mniejsza niż wartość w walucie zarz. ewidencji';
												|tr = '%1 satırındaki artık değer yönetim muhasebesi para biriminden küçük olmalıdır.'");
	EndIf; 
		
	Query = New Query;
	Query.Text =
	"SELECT
	|	DepreciationComponents.LineNumber AS LineNumber,
	|	CAST(DepreciationComponents.DepreciationComponent AS Catalog.Assets) AS DepreciationComponent,
	|	DepreciationComponents.CostInAccounting AS CostInAccounting,
	|	DepreciationComponents.CostInManagementAccounting AS CostInManagementAccounting,
	|	DepreciationComponents.ResidualValueMan AS ResidualValueMan,
	|	DepreciationComponents.ResidualValueLocal AS ResidualValueLocal
	|INTO DepreciationComponents
	|FROM
	|	&DepreciationComponents AS DepreciationComponents
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DepreciationComponents.LineNumber AS LineNumber,
	|	PRESENTATION(DepreciationComponents.DepreciationComponent) AS DepreciationComponent,
	|	CASE
	|		WHEN DepreciationComponents.DepreciationComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsTypeOfDepreciationComponent,
	|	DepreciationComponents.CostInAccounting AS CostInAccounting,
	|	DepreciationComponents.CostInManagementAccounting AS CostInManagementAccounting,
	|	DepreciationComponents.ResidualValueMan AS ResidualValueMan,
	|	DepreciationComponents.ResidualValueLocal AS ResidualValueLocal
	|FROM
	|	DepreciationComponents AS DepreciationComponents";
	Query.SetParameter("DepreciationComponents", DepreciationComponents.Unload());
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		LineNumber = Format(Selection.LineNumber, "NG=");
		
		If Selection.ThisIsTypeOfDepreciationComponent
			And (DepreciationMethodAccounting = Enums.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction
				Or DepreciationAccrualMethodManagementAccounting = Enums.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction) Then
			
			MessageText = StrTemplate(NStr("vi = 'Đối với cấu phần khấu hao %1 không nên chỉ ra phương thức tính toán %2';
											|ru = 'Для компонента амортизации %1 нельзя указывать метод начисления %2';
											|en = 'Cannot specify the %2 depreciation method for the %1 depreciation component'; fa = 'Cannot specify the %2 depreciation method for the %1 depreciation component';
											|it = 'Per la componente di ammortamento %1 non bisogna indicare il metodo di enumerazione %2';
											|pl = 'Dla komponentu amortyzacji %1 nie można podawać metody naliczania %2';
											|tr = 'Amortisman bileşeni %1 için %2 tahakkuk yöntemi belirleyemezsiniz'"),
				Selection.DepreciationComponent, Enums.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction);
			Field = CommonClientServer.PathToTabularSection("DepreciationComponents", Selection.LineNumber, "DepreciationComponent");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
				
		If Selection.ResidualValueLocal >= Selection.CostInAccounting 
			And Selection.CostInAccounting <> 0
			And RecordInLocalAccounting Then
			
			MessageText = StrTemplate(MessageTemplateResidualValueAC, LineNumber);
			Field = CommonClientServer.PathToTabularSection("DepreciationComponents", Selection.LineNumber, "ResidualValueLocal");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If Selection.ResidualValueMan >= Selection.CostInManagementAccounting 
			And Selection.CostInManagementAccounting <> 0
			And RecordInManAccounting Then
			
			MessageText = StrTemplate(MessageTemplateResidualValueMA, LineNumber);
			Field = CommonClientServer.PathToTabularSection("DepreciationComponents", Selection.LineNumber, "ResidualValueMan");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
	EndDo; 
	
EndProcedure

Procedure CheckFixedAssets(Cancel)

	NonCurrentAssetsInternal.CheckThatFAHaveBeenSelected(ThisObject, "DepreciationComponents", "FixedAsset", Cancel);

	QueryText =
	"SELECT
	|	Assets.Ref AS FixedAsset,
	|	Assets.Description AS FixedAssetPresentation,
	|	ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) AS StateOfTheUU,
	|	ISNULL(AccountingProcedureForOSBU.BUState, VALUE(Enum.FixedAssetsStates.NotRecognized_)) AS BUState
	|FROM
	|	Catalog.Assets AS Assets
	|
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&Period, 
	|			&RecordInManAccounting
	|				AND Organization = &Organization
	|				AND FixedAsset IN (&FAArray)) AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = Assets.Ref
	|
	|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|			&Period, 
	|			&RecordInLocalAccounting
	|				AND Organization = &Organization
	|				AND FixedAsset IN (&FAArray)) AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.FixedAsset = Assets.Ref
	|
	|WHERE
	|	Assets.Ref IN (&FAArray)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("RecordInLocalAccounting", RecordInLocalAccounting);
	Query.SetParameter("RecordInManAccounting", RecordInManAccounting);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("FAArray", DepreciationComponents.UnloadColumn("FixedAsset"));
	Query.SetParameter("Period",   Date - 1); // For the correct closing of the month, it is necessary that the FA owners be installed before the depreciation nodes and components
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		RowData = DepreciationComponents.Find(Selection.FixedAsset, "FixedAsset");
		Field = CommonClientServer.PathToTabularSection("DepreciationComponents", RowData.LineNumber, "FixedAsset");
		
		If RecordInManAccounting
			And Selection.StateOfTheUU = Enums.FixedAssetsStates.NotRecognized_ Then
			
			MessageText = StrTemplate(NStr("vi = 'Tài sản cố định ""%1"" không được chấp nhận để hạch toán trong kế toán quản trị.';
											|ru = 'Основное средство ""%1"" не принято к учету в управленческом учете.';
											|en = 'The ""%1"" fixed asset is not recognized in management accounting.'; fa = 'The ""%1"" fixed asset is not recognized in management accounting.';
											|it = 'Il cespite ""%1"" non è registrato in contabilità gestionale.';
											|pl = 'Środek trwały ""%1"" nie jest przyjęty do ewidencji w ewidencji zarządczej.';
											|tr = 'Sabit kıymetler ""%1"" yönetim hesaplarında muhasebeleştirilmemiştir.'"), Selection.FixedAssetPresentation);
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);

		ElsIf RecordInManAccounting
			And Selection.StateOfTheUU = Enums.FixedAssetsStates.TakenOffBooks Then
			
			MessageText = StrTemplate(NStr("vi = 'Tài sản cố định ""%1"" đã bỏ hạch toán trong kế toán quản trị.';
											|ru = 'Основное средство ""%1"" снято с учета в управленческом учете.';
											|en = 'The ""%1"" fixed asset is derecognized in management accounting.'; fa = 'The ""%1"" fixed asset is derecognized in management accounting.';
											|it = 'Il cespite ""%1"" è stato rimosso dalla contabilità gestionale.';
											|pl = 'Środek trwały ""%1"" jest wykreślony z ewidencji w ewidencji zarządczej.';
											|tr = 'Sabit kıymetler ""%1"" yönetim muhasebesinden çıkarılmıştır.'"), Selection.FixedAssetPresentation);
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);

		EndIf;
		
		If RecordInLocalAccounting
			And Selection.BUState = Enums.FixedAssetsStates.NotRecognized_ Then
			
			MessageText = StrTemplate(NStr("vi = 'Tài sản cố định ""%1"" không được chấp nhận để hạch toán trong kế toán tài chính.';
											|ru = 'Основное средство ""%1"" не принято к учету в бухгалтерском учете.';
											|en = 'The ""%1"" fixed asset is not recognized in local accounting.'; fa = 'The ""%1"" fixed asset is not recognized in local accounting.';
											|it = 'The ""%1"" fixed asset is not recognized in local accounting.';
											|pl = 'The ""%1"" fixed asset is not recognized in local accounting.';
											|tr = '""%1"" sabit kıymeti muhasebede dikkate alınmaz.'"), Selection.FixedAssetPresentation);
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);

		ElsIf RecordInLocalAccounting
			And Selection.BUState = Enums.FixedAssetsStates.TakenOffBooks Then
			
			MessageText = StrTemplate(NStr("vi = 'Tài sản cố định ""%1"" đã bỏ hạch toán trong kế toán quản trị.';
											|ru = 'Основное средство ""%1"" снято с учета в бухгалтерском учете.';
											|en = 'The ""%1"" fixed asset is derecognized in local accounting.'; fa = 'The ""%1"" fixed asset is derecognized in local accounting.';
											|it = 'The ""%1"" fixed asset is derecognized in local accounting.';
											|pl = 'The ""%1"" fixed asset is derecognized in local accounting.';
											|tr = '""%1"" sabit kıymetinin muhasebe kaydı silindi.'"), Selection.FixedAssetPresentation);
			
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf; 
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInBankingDetailsBeforeWrite()

	ClearUnusedProps();
	
	If RecordInManAccounting And RecordInLocalAccounting Then
		DocumentInAnotherAccounting = Undefined;
	EndIf;
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	FALocalAccountingIsConductedIndependently = AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(
		Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())));
		
	For Each RowData In DepreciationComponents Do
		
		If Not FALocalAccountingIsConductedIndependently
			And CurrencyOfMan = ComplCurrency Then
				
			RowData.CostInManagementAccounting = RowData.CostInAccounting;
			RowData.ResidualValueMan = RowData.ResidualValueLocal;
		EndIf;
		
	EndDo; 
	
EndProcedure

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceOfDepreciationComponentNodesForAccounting(
					ThisObject, AuxiliaryAttributes);
					
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "DepreciationComponents");

EndProcedure

Function AuxiliaryAttributes()
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("UseLocal", LocalAccntingServer.ReglRecordsAreMaintained(Date));
	AuxiliaryAttributes.Insert("UseConstructionObjects", GetFunctionalOption("UseConstructionObjects"));
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInManAccounting", RecordInManAccounting);
	AuxiliaryAttributes.Insert("PostInAccounting", RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	AuxiliaryAttributes.Insert(
		"ThereIsCostAccounting", 
		CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(Date, False));
		
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()))));
	
	RecognizeSubAssetsComponentsOfDepreciationLocalization.AddAuxiliaryDetails(ThisObject, AuxiliaryAttributes);
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndRegion

#EndIf
