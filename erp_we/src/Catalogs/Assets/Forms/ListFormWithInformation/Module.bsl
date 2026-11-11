
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseAccounting2_4 = NonCurrentAssets.VNAManagementIsUsed_2_4();
							
	SetRequestTextList();
		
	SetFilters(ThisObject);
	
	ConfigureDependentFormElements();
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SavedValue = Settings.Get("ShowDetails");
	ShowDetails = ?(ValueIsFilled(SavedValue), SavedValue, True);
	FillInPropertiesOfInformationElements();
	
	FilterState = Settings.Get("FilterState");
	FilterOrganization = Settings.Get("FilterOrganization");
	FilterDepartment = Settings.Get("FilterDepartment");
	FilterFinanciallyLiablePerson = Settings.Get("FilterFinanciallyLiablePerson");
	FilterDepreciationGroup = Settings.Get("FilterDepreciationGroup");
	FilterOSType = Settings.Get("FilterOSType");

	SetFilters(ThisObject);
	
	FillInInformation(ThisObject);
		
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "WritingDocumentToFALog" Then
		AttachIdleHandler("Attachable_FillInInformation", 0.2, True);
	EndIf;
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStateOnChange(Item)
	
	SetFilters(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	SetFilters(ThisObject);
		
	FillInInformation(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Department",
		FilterDepartment,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(FilterDepartment));
	
EndProcedure

&AtClient
Procedure FilterFinanciallyLiablePersonOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"FINANCIALLYLIABLEPERSON",
		FilterFinanciallyLiablePerson,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(FilterFinanciallyLiablePerson));
	
EndProcedure

&AtClient
Procedure FilterDepreciationGroupOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"DepreciationGroup",
		FilterDepreciationGroup,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(FilterDepreciationGroup));
	
EndProcedure

&AtClient
Procedure FilterOSTypeOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"OSType",
		FilterOSType,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(FilterOSType));

EndProcedure

&AtClient
Procedure InformationAcceptedForAccountingNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If StrFind(FormattedStringURL, "#Create") <> 0 Then
		StandardProcessing = False;
		FormParameters = New Structure("Basis", Items.List.CurrentRow);
		NameOfOpeningForm = GetNameOfRegistrationAcceptanceForm(FormParameters.Basis);
		OpenForm(NameOfOpeningForm, FormParameters);
	EndIf; 
	
EndProcedure

&AtClient
Procedure InformationLocationAddressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ContactsManagerClient.ShowAddressOnMap(FormattedStringURL, "Yandex.Maps");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// Due to the server call, the activation of the string is performed twice.
	If PreviousCurrentLine <> Items.List.CurrentRow Then
		AttachIdleHandler("Attachable_FillInInformation", 0.2, True);
	EndIf;
	
	PreviousCurrentLine = Items.List.CurrentRow;
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfDepreciationComponentSubAssets

&AtClient
Procedure ListOfDepreciationComponentSubAssetsSelection(Item, RowSelected, Field, StandardProcessing)

	CurrentData = Items.ListOfDepreciationComponentSubAssets.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(, CurrentData.SubAssetComponent);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure InformationRecords(Command)
	
	ShowDetails = Not ShowDetails;
	Items.GroupInfo.Visible = ShowDetails;
	
	If ShowDetails Then
		Items.TheDetailsButton.Title = NStr("vi = 'Ẩn thông tin';
											|ru = 'Скрыть сведения';
											|en = 'Hide information'; fa = 'Hide information';
											|it = 'Nascondi i dettagli';
											|pl = 'Ukryj informacje';
											|tr = 'Bilgileri gizle'");
		AttachIdleHandler("Attachable_FillInInformation", 0.2, True);
	Else
		Items.TheDetailsButton.Title = NStr("vi = 'Hiển thị chi tiết';
											|ru = 'Показать сведения';
											|en = 'Show details'; fa = 'نمایش جزئیات';
											|it = 'Mostra i dettagli';
											|pl = 'Pokaż informacje';
											|tr = 'Bilgileri göster'");
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateGroupFA(Command)
	
	NonCurrentAssetsClient.CreateObjectOfOperationByType(PredefinedValue("Enum.FATypes.GroupFA"));

EndProcedure

&AtClient
Procedure CreateOSNode(Command)
	
	NonCurrentAssetsClient.CreateObjectOfOperationByType(PredefinedValue("Enum.FATypes.Node"));

EndProcedure

&AtClient
Procedure CreateDepreciationComponent(Command)
	
	NonCurrentAssetsClient.CreateObjectOfOperationByType(PredefinedValue("Enum.FATypes.DepreciationComponent"));

EndProcedure

&AtClient
Procedure CreateCapitalInvestment(Command)
	
	NonCurrentAssetsClient.CreateObjectOfOperationByType(PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets"));

EndProcedure

#Region StandardSubsystems

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure ConfigureDependentFormElements()
	
	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	Items.PagesInformation.CurrentPage = Items.PageInformationFAIsNotSelected;
	
	If UseAccounting2_4 Then
		
		If Not ComplianceCAAccountingIsKept Then
			Items.ListUPRStatus.Title = NStr("vi = 'Trạng thái';
											|ru = 'Состояние';
											|en = 'State'; fa = 'وضعیت';
											|it = 'Stato';
											|pl = 'State';
											|tr = 'Durum'");
			Items.ListReglStatus.Visible = False;
			Items.InformationFAGroup.Visible = False;
			Items.InformationCodeByRNCFA.Visible = False;
			Items.InformationDepreciationGroup.Visible = False;
			Items.DetailsTableOfAmounts2_4Accounting.Visible = False;
			Items.ListDateOfRegistrationOfTheUpr.Title = NStr("vi = 'Tiếp nhận vào kế toán';
																|ru = 'Принято к учету';
																|en = 'Recognized'; fa = 'شناسایی‌شده';
																|it = 'Riconoscimento';
																|pl = 'Przyjęto do ewidencji';
																|tr = 'Mali tablolara alındı'");
			Items.ListDateOfRegistrationOfTheRegl.Visible = False;
		Else
			Items.InformationResidualValue.Visible = False;
			Items.InformationAccumulatedDepreciation.Visible = False;
			Items.InformationReplacementCost.Visible = False;
		EndIf;
		
		If Not ComplianceCAAccountingIsKept Then
			Items.DetailsTableOfAmounts2_4.Visible = False;
		EndIf;
		
		Title = NStr("vi = 'Tài sản cố định';
					|ru = 'Основные средства';
					|en = 'Fixed assets'; fa = 'دارایی‌های ثابت';
					|it = 'Capitali fissi';
					|pl = 'Środki trwałe';
					|tr = 'Sabit kıymetler'");
	
	Else
		Items.ListReglStatus.Title = NStr("vi = 'Trạng thái';
											|ru = 'Состояние';
											|en = 'State'; fa = 'وضعیت';
											|it = 'Stato';
											|pl = 'State';
											|tr = 'Durum'");
		Items.ListUPRStatus.Visible = False;
		Items.ListDateOfRegistrationOfTheRegl.Title = NStr("vi = 'Tiếp nhận vào kế toán';
															|ru = 'Принято к учету';
															|en = 'Recognized'; fa = 'شناسایی‌شده';
															|it = 'Riconoscimento';
															|pl = 'Przyjęto do ewidencji';
															|tr = 'Mali tablolara alındı'");
		Items.ListDateOfRegistrationOfTheUpr.Visible = False;
		Title = NStr("vi = 'TSCĐ và các đối tượng xây dựng';
					|ru = 'ОС и объекты строительства';
					|en = 'FA and assets under construction'; fa = 'دارایی‌های ثابت و دارایی‌های در جریان ساخت';
					|it = 'Capitali Fissi e oggetti di costruzione';
					|pl = 'Środki trwałe budownictwa';
					|tr = 'Sabit kıymetler ve yapım aşamasındaki varlıklar'");
	EndIf;
	
	NonCurrentAssetsClientServer.SetVisibilityOfSelectionListValue(
		Items.FilterState.ChoiceList,
		ComplianceCAAccountingIsKept,
		Enums.FixedAssetsStates.EnteredInOffBalanceAccounting);
	
	NonCurrentAssetsClientServer.SetVisibilityOfSelectionListValue(
		Items.FilterOSType.ChoiceList,
		ComplianceCAAccountingIsKept,
		Enums.FATypes.CapitalExpenditureInLeasedAssets);
	
	ShowDetails = False;
	FillInPropertiesOfInformationElements();
	
	If Not AccessRight("InteractiveInsert", Metadata.Catalogs.Assets) Then
		Items.CreateFAGroupUnitList.Visible = False;
		Items.CreateOSNode.Visible = False;
		Items.CreateDepreciationComponent.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetRequestTextList()

	QueryText = AssetsLocalization.ListFormRequestText();
	
	If QueryText = Undefined Then
			
		QueryText =
		"SELECT
		|	CatalogAssets.Ref,
		|	CatalogAssets.DeletionMark,
		|	CatalogAssets.Parent,
		|	CatalogAssets.IsFolder,
		|	CatalogAssets.Code,
		|	CatalogAssets.OSType,
		|	CatalogAssets.Description,
		|	CatalogAssets.DescriptionFull,
		|	CatalogAssets.Manufacturer_,
		|	CatalogAssets.ManufaturerNumber,
		|	CatalogAssets.PassportNumber,
		|	CatalogAssets.DateOfProduction,
		|	NULL AS CodeByRNCFA,
		|	NULL AS OSGroup,
		|	NULL AS DepreciationGroup,
		|	NULL AS CodeByUFADR,
		|	CatalogAssets.Comment,
		|	CatalogAssets.Placement,
		|	CatalogAssets.Model,
		|	CatalogAssets.SerialNumber,
		|	CatalogAssets.AssetID,
		|
		|	FALocation.LocationAddress AS LocationAddress,
		|
		|	CASE 
		|		WHEN CatalogAssets.IsFolder
		|			THEN VALUE(Enum.FixedAssetsStates.EmptyRef)
		|
		|		WHEN &FilterByCompany
		|				AND FALocation.Leaseholder = &FilterOrganization
		|				AND NOT AccountingProcedureForOSBU.FixedAsset IS NULL
		|			THEN VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting)
		|
		|		WHEN &State <> VALUE(Enum.FixedAssetsStates.EmptyRef)
		|			THEN
		|				CASE
		|					WHEN &State = AccountingProcedureForOSBU.BUState
		|						THEN AccountingProcedureForOSBU.BUState
		|
		|					WHEN &State = FixedAssetsAccountingProcedureManagementAccounting.State
		|						THEN FixedAssetsAccountingProcedureManagementAccounting.State
		|					ELSE ISNULL(AccountingProcedureForOSBU.BUState, ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)))
		|				END
		|		ELSE VALUE(Enum.FixedAssetsStates.EmptyRef)
		|
		|	END AS State,
		|
		|	CASE 
		|		WHEN CatalogAssets.IsFolder
		|			THEN VALUE(Enum.FixedAssetsStates.EmptyRef)
		|		WHEN &FilterByCompany 
		|				AND FALocation.Leaseholder = &FilterOrganization
		|				AND NOT AccountingProcedureForOSBU.FixedAsset IS NULL
		|			THEN VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting)
		|		WHEN AccountingProcedureForOSBU.BUState <> VALUE(Enum.FixedAssetsStates.EmptyRef)
		|			THEN AccountingProcedureForOSBU.BUState
		|		ELSE ISNULL(AccountingProcedureForOSBU.StateTa, VALUE(Enum.FixedAssetsStates.NotRecognized_))
		|	END AS ReglStatus,
		|
		|	CASE 
		|		WHEN CatalogAssets.IsFolder
		|			THEN VALUE(Enum.FixedAssetsStates.EmptyRef)
		|		WHEN &FilterByCompany 
		|				AND FALocation.Leaseholder = &FilterOrganization
		|				AND NOT FixedAssetsAccountingProcedureManagementAccounting.State IS NULL
		|			THEN VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting)
		|		ELSE ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)) 
		|	END AS UPRStatus,
		|
		|	CASE
		|		WHEN &FilterByCompany AND FALocation.Leaseholder = &FilterOrganization
		|			THEN FALocation.LeaseholderEmployeeInCharge
		|		ELSE ISNULL(FALocation.FinanciallyLiablePerson, VALUE(Catalog.Persons.EmptyRef))
		|	END AS FinanciallyLiablePerson,
		|
		|	CASE
		|		WHEN &FilterByCompany AND FALocation.Leaseholder = &FilterOrganization
		|			THEN FALocation.LeaseholderBusinessUnit
		|		ELSE ISNULL(FALocation.FixedAssetsLocation, VALUE(Catalog.BusinessStructure.EmptyRef))
		|	END AS Department,
		|		
		|	CASE
		|		WHEN &FilterByCompany AND FALocation.Leaseholder = &FilterOrganization
		|			THEN FALocation.Leaseholder
		|		ELSE ISNULL(FALocation.Organization, VALUE(Catalog.Companies.EmptyRef)) 
		|	END AS Organization,
		|
		|	DATETIME(1, 1, 1) AS DateOfRegistrationOfTheRegl,
		|	ISNULL(InitialFixedAssetsInformation.CommissioningDateMA, DATETIME(1, 1, 1)) AS DateOfRegistrationOfTheUpr,
		|
		|	CASE
		|		WHEN FilesExist.HasFiles IS NULL THEN 0
		|		WHEN FilesExist.HasFiles THEN 1
		|		ELSE 0
		|	END AS HasFiles
		|
		|{SELECT
		|	LocationAddress,
		|	FinanciallyLiablePerson,
		|	Department,		
		|	Organization,
		|	State,
		|	ReglStatus,
		|	UPRStatus,
		|	DateOfRegistrationOfTheRegl,
		|	DateOfRegistrationOfTheUpr
		|}
		|
		|FROM
		|	Catalog.Assets AS CatalogAssets
		|
		|		{LEFT JOIN InformationRegister.FilesExist AS FilesExist
		|		ON CatalogAssets.Ref = FilesExist.ObjectWithFiles}
		|
		|		{LEFT JOIN InformationRegister.FALocation.SliceLast AS FALocation
		|		ON (FALocation.FixedAsset = CatalogAssets.Ref)}
		|		
		|		{LEFT JOIN InformationRegister.InitialFixedAssetsInformation.SliceLast AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.FixedAsset = FALocation.FixedAsset
		|			AND InitialFixedAssetsInformation.Organization = FALocation.Organization}
		|
		|		{LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast AS AccountingProcedureForOSBU
		|		ON (AccountingProcedureForOSBU.FixedAsset = FALocation.FixedAsset)
		|			AND (AccountingProcedureForOSBU.Organization = FALocation.Organization)}
		|
		|		{LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast AS FixedAssetsAccountingProcedureManagementAccounting
		|		ON (FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = FALocation.FixedAsset)
		|			AND (FixedAssetsAccountingProcedureManagementAccounting.Organization = FALocation.Organization)}
		|
		|{WHERE
		|	CASE 
		|		WHEN CatalogAssets.IsFolder
		|			THEN VALUE(Enum.FixedAssetsStates.EmptyRef)
		|
		|		WHEN &FilterByCompany
		|				AND FALocation.Leaseholder = &FilterOrganization
		|				AND NOT AccountingProcedureForOSBU.FixedAsset IS NULL
		|			THEN VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting)
		|
		|		WHEN &State <> VALUE(Enum.FixedAssetsStates.EmptyRef)
		|			THEN
		|				CASE
		|					WHEN &State = AccountingProcedureForOSBU.BUState
		|						THEN AccountingProcedureForOSBU.BUState
		|
		|					WHEN &State = FixedAssetsAccountingProcedureManagementAccounting.State
		|						THEN FixedAssetsAccountingProcedureManagementAccounting.State
		|					ELSE ISNULL(AccountingProcedureForOSBU.BUState, ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.FixedAssetsStates.NotRecognized_)))
		|				END
		|		ELSE VALUE(Enum.FixedAssetsStates.EmptyRef)
		|
		|	END AS State,
		|
		|	CASE
		|		WHEN &FilterByCompany AND FALocation.Leaseholder = &FilterOrganization
		|			THEN FALocation.LeaseholderEmployeeInCharge
		|		ELSE ISNULL(FALocation.FinanciallyLiablePerson, VALUE(Catalog.Persons.EmptyRef))
		|	END AS FinanciallyLiablePerson,
		|
		|	CASE
		|		WHEN &FilterByCompany AND FALocation.Leaseholder = &FilterOrganization
		|			THEN FALocation.LeaseholderBusinessUnit
		|		ELSE ISNULL(FALocation.FixedAssetsLocation, VALUE(Catalog.BusinessStructure.EmptyRef))
		|	END AS Department,
		|		
		|	CASE
		|		WHEN &FilterByCompany AND FALocation.Leaseholder = &FilterOrganization
		|			THEN FALocation.Leaseholder
		|		ELSE ISNULL(FALocation.Organization, VALUE(Catalog.Companies.EmptyRef)) 
		|	END AS Organization
		|
		|}";		
			
	EndIf; 
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);

EndProcedure

&AtServer
Procedure FillInPropertiesOfInformationElements()
	
	Items.GroupInfo.Visible = ShowDetails;
	If ShowDetails Then
		Items.TheDetailsButton.Title = NStr("vi = 'Ẩn thông tin';
											|ru = 'Скрыть сведения';
											|en = 'Hide information'; fa = 'Hide information';
											|it = 'Nascondi i dettagli';
											|pl = 'Ukryj informacje';
											|tr = 'Bilgileri gizle'");
	Else
		Items.TheDetailsButton.Title = NStr("vi = 'Hiển thị chi tiết';
											|ru = 'Показать сведения';
											|en = 'Show details'; fa = 'نمایش جزئیات';
											|it = 'Mostra i dettagli';
											|pl = 'Pokaż informacje';
											|tr = 'Bilgileri göster'");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsTableOfAmountsAmountAccounting1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsTableOfAmounts.Presentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'KTDN';
													|ru = 'БУ';
													|en = 'LA'; fa = 'محلی';
													|it = 'Contabilità civilistica';
													|pl = 'EK';
													|tr = 'Genel Muhasebe'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsTableOfAmountsAmountFA1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsTableOfAmounts.Presentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'KTTh';
													|ru = 'НУ';
													|en = 'TA'; fa = 'مالیاتی';
													|it = 'Contabilità fiscale';
													|pl = 'EP';
													|tr = 'Vergi muhasebesi'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsTableOfAmountsAmountPermanentDifferences1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsTableOfAmounts.Presentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'CLVV';
													|ru = 'ПР';
													|en = 'PD'; fa = 'تفاوت دائم';
													|it = 'PR (Differenze permanenti)';
													|pl = 'RT';
													|tr = 'Sabit farklar'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsTableOfAmountsAmountTemporaryDifferences1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsTableOfAmounts.Presentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'CLTT';
													|ru = 'ВР';
													|en = 'TD'; fa = 'تفاوت موقت';
													|it = 'VR (Differenze temporanee)';
													|pl = 'RP';
													|tr = 'Geçici farklar'"));
	
EndProcedure

&AtClient
Procedure Attachable_FillInInformation()

	PerformanceMonitorClient.TimeMeasurement(
		"Catalog.Assets.Form.ListFormWithInformation.Command.InformationRecords");
		
	FillInInformation(ThisObject);

EndProcedure

&AtClientAtServerNoContext
Procedure FillInInformation(Form)
	
	If Not Form.ShowDetails Then
		Return;
	EndIf;
	
	Items = Form.Items;
	
	CurrentRow = Items.List.CurrentRow;
	CurrentData = Undefined;
	If CurrentRow <> Undefined Then
		CurrentData = Items.List.RowData(CurrentRow);
		If CurrentData <> Undefined And CurrentData.IsFolder Then
			CurrentData = Undefined;
		EndIf;
	EndIf;
	
	If CurrentData = Undefined Then
		Items.PagesInformation.CurrentPage = Items.PageInformationFAIsNotSelected;
		Return;
	EndIf;
	
	If Form.UseAccounting2_4 Then
		
		Items.PagesInformation.CurrentPage = Items.DetailsInfoPage2_4;
		
		Form.DetailsTableOfAmounts2_4.Clear();
		PresentationOfInformation = Undefined;
		
		CurrentRow = Form.Items.List.CurrentRow;
		InformationRecords2_4 = Get_Information2_4(CurrentData.Ref, Form.FilterOrganization);
	
		For Each Ellie In InformationRecords2_4.Amounts Do
			FillPropertyValues(Form.DetailsTableOfAmounts2_4.Add(), Ellie);
		EndDo;
		
		Items.ListOfDepreciationComponentSubAssets.Visible = 
			(CurrentData.OSType = PredefinedValue("Enum.FATypes.Asset")
			Or CurrentData.OSType = PredefinedValue("Enum.FATypes.GroupFA"));
		
		Form.ListOfDepreciationComponentSubAssets.Clear();
		For Each ComponentNodeString In InformationRecords2_4.SumsOfComponentNodes Do
			FillPropertyValues(Form.ListOfDepreciationComponentSubAssets.Add(), ComponentNodeString);
		EndDo;
		
		Form.Items.ListOfDepreciationComponentSubAssetsNetBookValueLocal.Visible =
			InformationRecords2_4.HeaderParametersOfComponentNodes.DisplayLocal;
		
		If InformationRecords2_4.HeaderParametersOfComponentNodes.DisplayLocal Then
			
			ComplCurrency = String(InformationRecords2_4.HeaderParametersOfComponentNodes.ComplCurrency);
			Form.Items.ListOfDepreciationComponentSubAssetsNetBookValueLocal.Title =
				StrTemplate(NStr("vi = 'Giá trị còn lại (%1)';
								|ru = 'Остаточная стоимость (%1)';
								|en = 'Net book value (%1)'; fa = 'Net book value (%1)';
								|it = 'Valore residuo (%1)';
								|pl = 'Wartość rezydualna (%1)';
								|tr = 'Net defter değeri (%1)'"), ComplCurrency);
			
		EndIf;
		
		CurrencyOfMan = String(InformationRecords2_4.HeaderParametersOfComponentNodes.CurrencyOfMan);
		Form.Items.ListOfDepreciationComponentSubAssetsNetBookValue.Title =
			StrTemplate(NStr("vi = 'Giá trị còn lại (%1)';
							|ru = 'Остаточная стоимость (%1)';
							|en = 'Net book value (%1)'; fa = 'Net book value (%1)';
							|it = 'Valore residuo (%1)';
							|pl = 'Wartość rezydualna (%1)';
							|tr = 'Net defter değeri (%1)'"), CurrencyOfMan);
		
		PresentationOfInformation = InformationRecords2_4.PresentationOfInformation;
		If PresentationOfInformation <> Undefined Then
			
			Items.GeneralTeamDocumentsOnTheMainTool.Visible = PresentationOfInformation.Period <> '000101010000';
			
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationAcceptedForAccounting1, PresentationOfInformation.InformationAcceptedForAccounting1);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationAcceptedForAccounting3, PresentationOfInformation.InformationAcceptedForAccounting3);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationLocationCompany, PresentationOfInformation.InformationLocationCompany);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationLocationDepartment, PresentationOfInformation.InformationLocationDepartment);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationInventoryCustodianLocation, PresentationOfInformation.InformationInventoryCustodianLocation);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationLocationAddress, PresentationOfInformation.InformationLocationAddress);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationTermOfUse1, PresentationOfInformation.InformationTermOfUse1);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationTermOfUse3, PresentationOfInformation.InformationTermOfUse3);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationContract, PresentationOfInformation.InformationContract);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationReplacementCost, PresentationOfInformation.InformationReplacementCost);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationAccumulatedDepreciation, PresentationOfInformation.InformationAccumulatedDepreciation);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationImpairment, PresentationOfInformation.InformationImpairment);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationResidualValue, PresentationOfInformation.InformationResidualValue);
			
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationLiquidationValueOfRegl, PresentationOfInformation.InformationLiquidationValueOfRegl);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationLiquidationValue, PresentationOfInformation.InformationLiquidationValue);
				
		Else
			
			Items.GeneralTeamDocumentsOnTheMainTool.Visible = False;
			Items.InformationAcceptedForAccounting1.Visible = False;
			Items.InformationAcceptedForAccounting3.Visible = False;
			Items.InformationLocationCompany.Visible = False;
			Items.InformationLocationDepartment.Visible = False;
			Items.InformationInventoryCustodianLocation.Visible = False;
			Items.InformationLocationAddress.Visible = False;
			Items.InformationTermOfUse1.Visible = False;
			Items.InformationTermOfUse2.Visible = False;
			Items.InformationContract.Visible = False;
			Items.InformationReplacementCost.Visible = False;
			Items.InformationAccumulatedDepreciation.Visible = False;
			Items.InformationImpairment.Visible = False;
			Items.InformationResidualValue.Visible = False;
			Items.InformationLiquidationValueOfRegl.Visible = False;
			Items.InformationLiquidationValue.Visible = False;
			
		EndIf; 
		
		Items.InformationAcceptedForAccounting2.Visible = False;
		Items.InformationFAGroup.Visible = False;
		Items.InformationCodeByRNCFA.Visible = False;
		Items.InformationDepreciationGroup.Visible = False;
		Items.InformationTermOfUse2.Visible = False;
		Items.InformationTermOfUse3.Visible = False;
		
	Else
		
		InformationRecords2_2 = Get_Information2_2(Items.List.CurrentRow, Form.FilterOrganization);
		
	EndIf;
	
	NonCurrentAssetsClientServerLocalization.FillInInformationInFAListForm(Form, InformationRecords2_4, InformationRecords2_2);
	
EndProcedure

&AtServerNoContext
Function Get_Information2_2(Val NonCurrentAsset, Val FilterOrganization)
	
	InformationRecords2_2 = AssetsLocalization.Get_Information2_2(NonCurrentAsset, FilterOrganization);
	
	Return InformationRecords2_2;
	
EndFunction

&AtServerNoContext
Function Get_Information2_4(Val NonCurrentAsset, Val FilterOrganization)

	InformationAboutAccounting = Catalogs.Assets.InformationAboutAccounting(NonCurrentAsset, FilterOrganization);
	CostAndDepreciation = NonCurrentAssets.CostAndDepreciationOfFA(NonCurrentAsset);
	CostAndDepreciationOfComponentsComponents = NonCurrentAssets.CostAndDepreciationOfComponentsComponents(NonCurrentAsset);

	ArrayOfAmounts = New Array;
	
	CurrencyOfMan  = Constants.ManagementAccountingCurrency.Get();
	If InformationAboutAccounting = Undefined Then
		ComplCurrency = SettingsValueCached.DefaultBaseCurrency();
	Else
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(InformationAboutAccounting.Organization);
	EndIf;
	
	InformationRecords2_4 = New Structure;
	HeaderParametersOfComponentNodes = New Structure("CurrencyOfMan, ComplCurrency, DisplayLocal",
		CurrencyOfMan, ComplCurrency, CurrencyOfMan <> ComplCurrency);
	
	AssetsLocalization.AddInformation2_4(
		NonCurrentAsset, InformationAboutAccounting, CostAndDepreciation, ArrayOfAmounts, InformationRecords2_4);
		
	If Not NonCurrentAssetsInternal.ComplianceCAAccountingIsKept()
		And CurrencyOfMan <> ComplCurrency Then
	
		// ACC
		DataOfAccounting = New Structure;
		DataOfAccounting.Insert("Accounting", "ACC");
		DataOfAccounting.Insert("Currency", ComplCurrency);
		DataOfAccounting.Insert("ReplacementCost", CostAndDepreciation.LocalCost);
		DataOfAccounting.Insert("AccumulatedDepreciation", CostAndDepreciation.DepreciationLocal);
		DataOfAccounting.Insert("Impairment", CostAndDepreciation.ImpairmentLocalAssets);
		DataOfAccounting.Insert("NetBookValue", CostAndDepreciation.LocalCost - CostAndDepreciation.DepreciationLocal - CostAndDepreciation.ImpairmentLocalAssets);
		ArrayOfAmounts.Add(DataOfAccounting);
		
	EndIf; 
	
	// MA
	If InformationAboutAccounting = Undefined
		Or InformationAboutAccounting.BUState <> Enums.FixedAssetsStates.EnteredInOffBalanceAccounting Then
		DataOfAccounting = New Structure;
		DataOfAccounting.Insert("Accounting", "MA");
		DataOfAccounting.Insert("Currency", CurrencyOfMan);
		DataOfAccounting.Insert("ReplacementCost", CostAndDepreciation.Cost);
		DataOfAccounting.Insert("AccumulatedDepreciation", CostAndDepreciation.Depreciation);
		DataOfAccounting.Insert("Impairment", CostAndDepreciation.ImpairmenMan);
		DataOfAccounting.Insert("NetBookValue", CostAndDepreciation.Cost - CostAndDepreciation.Depreciation - CostAndDepreciation.ImpairmenMan);
		ArrayOfAmounts.Add(DataOfAccounting);
	EndIf; 
	
	PresentationOfInformation = Catalogs.Assets.PresentationOfAccountingInformation(InformationAboutAccounting, CostAndDepreciation, False);
	
	SumsOfComponentNodes = Common.ValueTableToArray(CostAndDepreciationOfComponentsComponents);
	
	InformationRecords2_4.Insert("PresentationOfInformation", PresentationOfInformation);
	InformationRecords2_4.Insert("Amounts", ArrayOfAmounts);
	InformationRecords2_4.Insert("SumsOfComponentNodes", SumsOfComponentNodes);
	InformationRecords2_4.Insert("HeaderParametersOfComponentNodes", HeaderParametersOfComponentNodes);
	
	Return InformationRecords2_4;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetFilters(Form)
	
	List = Form.List;
	
	List.Parameters.SetParameterValue("FilterByCompany", ValueIsFilled(Form.FilterOrganization));
	List.Parameters.SetParameterValue("FilterOrganization", Form.FilterOrganization);
	List.Parameters.SetParameterValue("State", Form.FilterState);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"State",
		Form.FilterState,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterState));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		Form.FilterOrganization,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterOrganization));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Department",
		Form.FilterDepartment,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterDepartment));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"FINANCIALLYLIABLEPERSON",
		Form.FilterFinanciallyLiablePerson,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterFinanciallyLiablePerson));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"OSType",
		Form.FilterOSType,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterOSType));
	
	NonCurrentAssetsClientServerLocalization.SetFiltersInFAListForm(Form);
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Catalog.Assets.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtServerNoContext
Function GetNameOfRegistrationAcceptanceForm(FixedAsset)

	OSType = Common.ObjectAttributeValue(FixedAsset, "OSType");
	If OSType = Enums.FATypes.DepreciationComponent
		Or OSType = Enums.FATypes.Node Then
		
		Return "Document.RecognizeSubAssetsComponentsOfDepreciation.ObjectForm";
	Else
		Return "Document.FixedAssetsInitialRecognition2_4.ObjectForm";
	EndIf;

EndFunction

#EndRegion