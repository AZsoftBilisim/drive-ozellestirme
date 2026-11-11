
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseAccounting2_4 = NonCurrentAssets.VNAManagementIsUsed_2_4();
							
	SetRequestTextList();
	
	List.Parameters.SetParameterValue("State", Enums.IntangibleAssetsStates.EmptyRef());

	Items.PagesInformation.CurrentPage = Items.PageInformationIAIsNotSelected;
	
	If UseAccounting2_4 Then
		
		ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
		
		If Not ComplianceCAAccountingIsKept Then
			Items.ListUPRStatus.Title = NStr("vi = 'Trạng thái';
											|ru = 'Состояние';
											|en = 'State'; fa = 'وضعیت';
											|it = 'Stato';
											|pl = 'State';
											|tr = 'Durum'");
			Items.ListReglStatus.Visible = False;
			Items.DetailsTableOfAmounts2_4Accounting.Visible = False;
			Items.ListDateOfRegistrationOfTheUpr.Title = NStr("vi = 'Đã nhận vào kế toán';
																|ru = 'Принят к учету';
																|en = 'Recognized'; fa = 'شناسایی‌شده';
																|it = 'Riconoscimento';
																|pl = 'Przyjęty do ewidencji';
																|tr = 'Tanındı'");
			Items.ListDateOfRegistrationOfTheRegl.Visible = False;
		Else
			Items.InformationResidualValue.Visible = False;
			Items.InformationAccumulatedDepreciation.Visible = False;
			Items.InformationReplacementCost.Visible = False;
		EndIf; 
	
	Else
		Items.ListReglStatus.Title = NStr("vi = 'Trạng thái';
											|ru = 'Состояние';
											|en = 'State'; fa = 'وضعیت';
											|it = 'Stato';
											|pl = 'State';
											|tr = 'Durum'");
		Items.ListUPRStatus.Visible = False;
		Items.ListDateOfRegistrationOfTheRegl.Title = NStr("vi = 'Đã nhận vào kế toán';
															|ru = 'Принят к учету';
															|en = 'Recognized'; fa = 'شناسایی‌شده';
															|it = 'Riconoscimento';
															|pl = 'Przyjęty do ewidencji';
															|tr = 'Tanındı'");
		Items.ListDateOfRegistrationOfTheUpr.Visible = False;
	EndIf;
	
	ShowDetails = False;
	FillInPropertiesOfInformationElements();
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.IntangibleAssets);
	Items.ChangeSelectedItems.Visible = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SavedValue = Settings.Get("ShowDetails");
	ShowDetails = ?(ValueIsFilled(SavedValue), SavedValue, True);
	FillInPropertiesOfInformationElements();
	
	SetSelectionByState(ThisForm);
	
	FilterOrganization = Settings.Get("FilterOrganization");
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		FilterOrganization,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(FilterOrganization));
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "WritingDocumentToIAJournal" Then
		AttachIdleHandler("Attachable_FillInInformation", 0.2, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStateOnChange(Item)
	
	SetSelectionByState(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		FilterOrganization,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(FilterOrganization));
	
EndProcedure

&AtClient
Procedure InformationAcceptedForAccountingNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If StrFind(FormattedStringURL, "#Create") <> 0 Then
		StandardProcessing = False;
		FormParameters = New Structure("Basis", Items.List.CurrentRow);
		OpenForm("Document.IntangibleAssetsInitialRecognition2_4.ObjectForm", FormParameters);
	EndIf; 
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);

EndProcedure

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

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure SetRequestTextList()

	QueryText =
	"SELECT
	|	CatalogIntangibleAssets.Ref,
	|	CatalogIntangibleAssets.DeletionMark,
	|	CatalogIntangibleAssets.Parent,
	|	CatalogIntangibleAssets.IsFolder,
	|	CatalogIntangibleAssets.Code,
	|	CatalogIntangibleAssets.Description,
	|	CatalogIntangibleAssets.DescriptionFull,
	|	CatalogIntangibleAssets.IntangibleAssetsKind,
	|	CatalogIntangibleAssets.IntangibleAssetGroup,
	|	CatalogIntangibleAssets.OtherInformation,
	|	CatalogIntangibleAssets.KindOfAccountingObject,
	|	CatalogIntangibleAssets.Predefined,
	|	CatalogIntangibleAssets.PredefinedDataName,
	|
	|	ISNULL(IntangibleAssetsRegistrationPlace.Organization, VALUE(Catalog.Companies.EmptyRef)) AS Organization,
	|	ISNULL(IntangibleAssetsRegistrationPlace.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|
	|	CASE 
	|		WHEN CatalogIntangibleAssets.IsFolder
	|			THEN VALUE(Enum.IntangibleAssetsStates.EmptyRef)
	|
	|		WHEN &State = IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState
	|			THEN IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState
	|
	|		WHEN &State = IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa
	|			THEN IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa
	|
	|		WHEN &State = IntangibleAssetsAccountingProcedureManagementAccounting.State
	|			THEN IntangibleAssetsAccountingProcedureManagementAccounting.State
	|
	|		ELSE VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)
	|
	|	END AS State,
	|
	|	CASE 
	|		WHEN CatalogIntangibleAssets.IsFolder
	|			THEN VALUE(Enum.IntangibleAssetsStates.EmptyRef)
	|		WHEN IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState <> VALUE(Enum.IntangibleAssetsStates.EmptyRef)
	|			THEN IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState
	|		ELSE ISNULL(IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting))
	|	END AS ReglStatus,
	|
	|	CASE 
	|		WHEN CatalogIntangibleAssets.IsFolder
	|			THEN VALUE(Enum.IntangibleAssetsStates.EmptyRef)
	|		ELSE ISNULL(IntangibleAssetsAccountingProcedureManagementAccounting.State, VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)) 
	|	END AS UPRStatus,
	|
	|	CatalogIntangibleAssets.DepreciationGroup,
	|
	|	CASE
	|		WHEN ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionInTaxAccounting, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1)
	|				AND (ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionInTaxAccounting, DATETIME(1, 1, 1)) < ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, DATETIME(1, 1, 1))
	|						OR ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1))
	|			THEN ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionInTaxAccounting, DATETIME(1, 1, 1))
	|	 	ELSE ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionAccounting, DATETIME(1, 1, 1))
	|	END AS DateOfRegistrationOfTheRegl,
	|
	|	ISNULL(InitialIntangibleAssetsInformation.DateOfRecognitionManagementAccounting, DATETIME(1, 1, 1)) AS DateOfRegistrationOfTheUpr,
	|
	|	CASE
	|		WHEN FilesExist.HasFiles IS NULL THEN 0
	|		WHEN FilesExist.HasFiles THEN 1
	|		ELSE 0
	|	END AS HasFiles
	|
	|{SELECT
	|	Organization,
	|	Department,		
	|	State,
	|	ReglStatus,
	|	UPRStatus,
	|	DateOfRegistrationOfTheRegl,
	|	DateOfRegistrationOfTheUpr
	|}
	|
	|FROM
	|	Catalog.IntangibleAssets AS CatalogIntangibleAssets
	|
	|		{LEFT JOIN InformationRegister.FilesExist AS FilesExist
	|		ON CatalogIntangibleAssets.Ref = FilesExist.ObjectWithFiles}
	|
	|		{LEFT JOIN InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast AS IntangibleAssetsRegistrationPlace
	|		ON (IntangibleAssetsRegistrationPlace.IntangibleAsset = CatalogIntangibleAssets.Ref)}
	|
	|		{LEFT JOIN InformationRegister.InitialIntangibleAssetsInformation.SliceLast AS InitialIntangibleAssetsInformation
	|		ON InitialIntangibleAssetsInformation.IntangibleAsset = CatalogIntangibleAssets.Ref
	|			AND InitialIntangibleAssetsInformation.Organization = IntangibleAssetsRegistrationPlace.Organization}
	|
	|		{LEFT JOIN InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast AS IABookkeepingProcedureBookkeepingAndTaxAccounting
	|		ON (IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset)
	|			AND (IABookkeepingProcedureBookkeepingAndTaxAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization)}
	|
	|		{LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast AS IntangibleAssetsAccountingProcedureManagementAccounting
	|		ON (IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset)
	|			AND (IntangibleAssetsAccountingProcedureManagementAccounting.Organization = IntangibleAssetsRegistrationPlace.Organization)}
	|
	|{WHERE
	|
	|	ISNULL(IntangibleAssetsRegistrationPlace.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,		
	|	ISNULL(IntangibleAssetsRegistrationPlace.Organization, VALUE(Catalog.Companies.EmptyRef)) AS Organization,
	|
	|	CASE 
	|		WHEN CatalogIntangibleAssets.IsFolder
	|			THEN VALUE(Enum.IntangibleAssetsStates.EmptyRef)
	|
	|		WHEN &State = IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState
	|			THEN IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState
	|
	|		WHEN &State = IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa
	|			THEN IABookkeepingProcedureBookkeepingAndTaxAccounting.StateTa
	|
	|		WHEN &State = IntangibleAssetsAccountingProcedureManagementAccounting.State
	|			THEN IntangibleAssetsAccountingProcedureManagementAccounting.State
	|
	|		ELSE VALUE(Enum.IntangibleAssetsStates.NotPostedInFinancialAccounting)
	|
	|	END AS State
	|}";
	
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
	ItemField.Field = New DataCompositionField(Items.TableOfAmountsAmountOfBU1.Name);
	
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
	ItemField.Field = New DataCompositionField(Items.TableOfAmountsSumOfWELL1.Name);
	
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
	ItemField.Field = New DataCompositionField(Items.TableAmountsTheAmountOfPR1.Name);
	
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
	ItemField.Field = New DataCompositionField(Items.TableOfAmountsAmountOfBP1.Name);
	
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

&AtClientAtServerNoContext
Procedure SetSelectionByState(Form)

	CommonClientServer.SetDynamicListParameter(
		Form.List,
		"State",
		Form.FilterState);

	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"State",
		Form.FilterState,,, 
		ValueIsFilled(Form.FilterState));

EndProcedure

&AtClient
Procedure Attachable_FillInInformation()

	FillInInformation(ThisForm);

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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
		Items.PagesInformation.CurrentPage = Items.PageInformationIAIsNotSelected;
		Return;
	EndIf;
	
	If CurrentData.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses") Then
		Items.GroupInfo.Title = NStr("vi = 'Thông tin về chi phí Nghiên cứu phát triển';
									|ru = 'Сведения о расходах на НИОКР';
									|en = 'R&D expense information'; fa = 'R&D expense information';
									|it = 'Informazioni sui costi di Ricerca e Sviluppo';
									|pl = 'Informacje o kosztach na R&D';
									|tr = 'Ar-Ge harcamalarına ilişkin bilgiler'");
	Else
		Items.GroupInfo.Title = NStr("vi = 'Thông tin tài sản cố định vô hình';
									|ru = 'Сведения о нематериальном активе';
									|en = 'Intangible asset information'; fa = 'اطلاعات دارایی نامشهود';
									|it = 'Informazioni circa il bene immateriale';
									|pl = 'Informacje o składniku aktywów niematerialnych';
									|tr = 'Maddi olmayan varlıklara ilişkin bilgiler'");
	EndIf;
	
	If Form.UseAccounting2_4 Then
		
		Items.PagesInformation.CurrentPage = Items.DetailsInfoPage2_4;
		
		Form.DetailsTableOfAmounts2_4.Clear();
		PresentationOfInformation = Undefined;
		
		ThereAreSums = False;
		CurrentRow = Form.Items.List.CurrentRow;
		InformationRecords2_4 = Get_Information2_4(CurrentData.Ref);
	
		For Each Ellie In InformationRecords2_4.Amounts Do
			FillPropertyValues(Form.DetailsTableOfAmounts2_4.Add(), Ellie);
			ThereAreSums = Ellie.ReplacementCost <> 0 
							Or Ellie.AccumulatedDepreciation <> 0 
							Or Ellie.NetBookValue <> 0 
							Or ThereAreSums;
		EndDo;
		
		If InformationRecords2_4.CurrencyOfMan = InformationRecords2_4.ComplCurrency Then
			Items.DetailsTableOfAmounts2_4Currency.Visible = False;
		EndIf;
		
		If Not InformationRecords2_4.ComplianceCAAccountingIsKept
			And InformationRecords2_4.CurrencyOfMan = InformationRecords2_4.ComplCurrency Then
			Items.DetailsTableOfAmounts2_4.Visible = False;
		EndIf;
		
		PresentationOfInformation = InformationRecords2_4.PresentationOfInformation;
		If PresentationOfInformation <> Undefined Then
			
			Items.GeneralTeamIntangibleAssetDocuments.Visible = PresentationOfInformation.Period <> '000101010000';
			
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationAcceptedForAccounting1, PresentationOfInformation.InformationAcceptedForAccounting1);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationAcceptedForAccounting3, PresentationOfInformation.InformationAcceptedForAccounting3);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationRegistrationPlaceCompany, PresentationOfInformation.InformationRegistrationPlaceCompany);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationRegistrationPlaceDepartment, PresentationOfInformation.InformationRegistrationPlaceDepartment);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationTermOfUse1, PresentationOfInformation.InformationTermOfUse1);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationTermOfUse3, PresentationOfInformation.InformationTermOfUse3);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationReplacementCost, PresentationOfInformation.InformationReplacementCost);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationAccumulatedDepreciation, PresentationOfInformation.InformationAccumulatedDepreciation);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationImpairment, PresentationOfInformation.InformationImpairment);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationResidualValue, PresentationOfInformation.InformationResidualValue);
			
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationLiquidationValue, PresentationOfInformation.InformationLiquidationValue);
				
			NonCurrentAssetsClientServer.FillInItemDetails_(
				Items.InformationLiquidationValueOfRegl, PresentationOfInformation.InformationLiquidationValueOfRegl);
		Else
			
			Items.GeneralTeamIntangibleAssetDocuments.Visible = False;
			Items.InformationAcceptedForAccounting1.Visible = False;
			Items.InformationAcceptedForAccounting3.Visible = False;
			Items.InformationRegistrationPlaceCompany.Visible = False;
			Items.InformationRegistrationPlaceDepartment.Visible = False;
			Items.InformationTermOfUse1.Visible = False;
			Items.InformationReplacementCost.Visible = False;
			Items.InformationAccumulatedDepreciation.Visible = False;
			Items.InformationImpairment.Visible = False;
			Items.InformationResidualValue.Visible = False;
			Items.InformationLiquidationValue.Visible = False;
			Items.InformationLiquidationValueOfRegl.Visible = False;
			
		EndIf;
		
		Items.InformationAcceptedForAccounting2.Visible = False;
		Items.InformationTermOfUse2.Visible = False;
		Items.InformationDepreciationGroup.Visible = False;
		
		If CurrentData.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses") Then
			Items.DetailsTableOfAmounts2_4ReplacementCost.Title = NStr("vi = 'Nguyên
                                                                                        |giá';
                                                                                        |ru = 'Первоначальная
                                                                                        |стоимость';
                                                                                        |en = 'Initial
                                                                                        |cost'; fa = 'Initial
                                                                                        |cost';
                                                                                        |it = 'Costo
                                                                                        |iniziale';
                                                                                        |pl = 'Initial
                                                                                        |cost';
                                                                                        |tr = 'Başlangıç
                                                                                        |değeri'");
			Items.DetailsTableOfAmounts2_4AccumulatedDepreciation.Title = NStr("vi = 'Giá trị
                                                                                    |thanh lý';
                                                                                    |ru = 'Погашенная
                                                                                    |стоимость';
                                                                                    |en = 'Repaid
                                                                                    |cost'; fa = 'Repaid
                                                                                    |cost';
                                                                                    |it = 'Valore
                                                                                    |estinto';
                                                                                    |pl = 'Repaid
                                                                                    |cost';
                                                                                    |tr = 'İade edilen
                                                                                    |maliyet'");
		Else
			Items.DetailsTableOfAmounts2_4ReplacementCost.Title = NStr("vi = 'Giá
                                                                                        |trị
                                                                                        |khôi phục';
                                                                                        |ru = 'Восстано-
                                                                                        |вительная
                                                                                        |стоимость';
                                                                                        |en = 'Replace-
                                                                                        |ment
                                                                                        |cost'; fa = 'بهای
                                                                                        |جایگزینی
                                                                                        |فعلی';
                                                                                        |it = 'Costi 
                                                                                        |recuperabili
                                                                                        |';
                                                                                        |pl = 'Replace-
                                                                                        |ment
                                                                                        |cost';
                                                                                        |tr = 'Yeni
                                                                                        |leme
                                                                                        | değeri'");
			Items.DetailsTableOfAmounts2_4AccumulatedDepreciation.Title = NStr("vi = 'Khấu hao
                                                                                    |lũy kế';
                                                                                    |ru = 'Накопленная
                                                                                    |амортизация';
                                                                                    |en = 'Accumulated
                                                                                    |depreciation'; fa = 'استهلاک
                                                                                    |انباشته';
                                                                                    |it = 'L''ammortamento
                                                                                    | cumulato';
                                                                                    |pl = 'Accumulated
                                                                                    |depreciation';
                                                                                    |tr = 'Birikmiş
                                                                                    |amortisman'");
		EndIf; 
		
	Else	
		
		Items.PagesInformation.CurrentPage = Items.DetailsInfoPage2_2;
		InformationRecords2_2 = Get_Information2_2(Items.List.CurrentRow);
		
	EndIf;
	
	NonCurrentAssetsClientServerLocalization.FillInInformationInIAListForm(Form, InformationRecords2_4, InformationRecords2_2);
	
EndProcedure

&AtServerNoContext
Function Get_Information2_2(NonCurrentAsset)
	
	InformationRecords2_2 = IntangibleAssetsLocalization.Get_Information2_2(NonCurrentAsset);
	
	Return InformationRecords2_2;
	
EndFunction

&AtServerNoContext
Function Get_Information2_4(Val NonCurrentAsset)

	InformationAboutAccounting = Catalogs.IntangibleAssets.InformationAboutAccounting(NonCurrentAsset);
	CostAndDepreciation = NonCurrentAssets.CostAndDepreciationOfIa(NonCurrentAsset);

	ArrayOfAmounts = New Array;
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	If ValueIsFilled(InformationAboutAccounting) Then
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(InformationAboutAccounting.Organization);
	Else
		ComplCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	InformationRecords2_4 = New Structure;
	
	IntangibleAssetsLocalization.AddInformation2_4(
		NonCurrentAsset, InformationAboutAccounting, CostAndDepreciation, ArrayOfAmounts, InformationRecords2_4);
	
	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	InformationRecords2_4.Insert("ComplianceCAAccountingIsKept", ComplianceCAAccountingIsKept);
	InformationRecords2_4.Insert("CurrencyOfMan", CurrencyOfMan);
	InformationRecords2_4.Insert("ComplCurrency", ComplCurrency);
	
	If Not ComplianceCAAccountingIsKept
		And CurrencyOfMan <> ComplCurrency Then
		
		// ACC
		DataOfAccounting = New Structure;
		DataOfAccounting.Insert("Accounting", "ACC");
		DataOfAccounting.Insert("Currency", ComplCurrency);
		DataOfAccounting.Insert("ReplacementCost", CostAndDepreciation.LocalCost);
		DataOfAccounting.Insert("AccumulatedDepreciation", CostAndDepreciation.DepreciationLocal);
		DataOfAccounting.Insert("NetBookValue", CostAndDepreciation.LocalCost - CostAndDepreciation.DepreciationLocal);
		ArrayOfAmounts.Add(DataOfAccounting);
		
	EndIf; 
		
	// MA
	DataOfAccounting = New Structure;
	DataOfAccounting.Insert("Accounting", "MA");
	DataOfAccounting.Insert("Currency", CurrencyOfMan);
	DataOfAccounting.Insert("ReplacementCost", CostAndDepreciation.Cost);
	DataOfAccounting.Insert("AccumulatedDepreciation", CostAndDepreciation.Depreciation);
	DataOfAccounting.Insert("NetBookValue", CostAndDepreciation.Cost - CostAndDepreciation.Depreciation);
	ArrayOfAmounts.Add(DataOfAccounting);
	
	PresentationOfInformation = Catalogs.IntangibleAssets.PresentationOfAccountingInformation(InformationAboutAccounting, CostAndDepreciation, False);
	
	InformationRecords2_4.Insert("PresentationOfInformation", PresentationOfInformation);
	InformationRecords2_4.Insert("Amounts", ArrayOfAmounts);
	
	Return InformationRecords2_4;
	
EndFunction

#EndRegion