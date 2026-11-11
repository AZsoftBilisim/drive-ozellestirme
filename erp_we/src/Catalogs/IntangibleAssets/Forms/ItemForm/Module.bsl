#Region Variables

&AtClient
Var AttributesValuesBeforeChange; // See SaveDetailsValuesBeforeChanging 

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	UnavailableTextColor = StyleColors.OutdatedListTextColor;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	SetVisibilityOfInputCommandsBasedOn_();
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttributesValuesBeforeChange = SaveDetailsValuesBeforeChanging();
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "Write_IntangibleAssetsInitialRecognition2_4"
		Or EventName = "Write_DisposeIntangibleAssets2_4"
		Or EventName = "Write_ChangeFixedAssetFinancialDetails2_4"
		Or EventName = "Write_IATransfer2_4" Then
		WhenChangingIADocuments();
	EndIf;
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	
	Items.DescriptionFull.ChoiceList.Clear();
	Items.DescriptionFull.ChoiceList.Add(Object.Description);
	
	GenerateFullNameAutomatically();
	
	AttributesValuesBeforeChange = SaveDetailsValuesBeforeChanging();
	
EndProcedure

&AtClient
Procedure DescriptionFullOnChange(Item)
	
	AttributesValuesBeforeChange = SaveDetailsValuesBeforeChanging();
	
EndProcedure

&AtClient
Procedure KindOfAccountingObjectOnChange(Item)
	
	ConfigureDependentFormElements("KindOfAccountingObject");
	
	AttachableCommandsClient.StartCommandUpdate(ThisForm);
	
EndProcedure

&AtClient
Procedure InformationAcceptedForAccountingNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If StrFind(FormattedStringURL, "#Create") <> 0 Then
		StandardProcessing = False;
		FormParameters = New Structure("Basis", Object.Ref);
		OpenForm("Document.IntangibleAssetsInitialRecognition2_4.ObjectForm", FormParameters);
	EndIf; 
	
EndProcedure

&AtClient
Procedure BusinessActivityClassifierCode2OnChange(Item)
	
	ConfigureDependentFormElements("BusinessActivityClassifierCode2");
	
EndProcedure

&AtClient
Procedure BusinessActivityClassifierCode2StartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure BusinessActivityClassifierCode2AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure RegistrationDocumentLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("RegistrationDocumentDescription", Object.RegistrationDocumentDescription);
	FormParameters.Insert("RegistrationDocumentDate", Object.RegistrationDocumentDate);
	FormParameters.Insert("RegistrationDocumentNumber", Object.RegistrationDocumentNumber);
	
	CallbackDescription = New CallbackDescription("EnteringInformationAboutRegistrationDocumentEnding", ThisObject);
	OpenForm("Catalog.IntangibleAssets.Form.DocumentRegistrations", FormParameters,,,,,CallbackDescription);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure BusinessAreaHistory(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("IntangibleAsset", Object.Ref);
	FormParameters.Insert("AttributeName", "LineOfBusiness");
	OpenForm("Catalog.IntangibleAssets.Form.ChangeHistory", FormParameters, ThisForm);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

#Region StandardSubsystems

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()

	Items.DescriptionFull.ChoiceList.Clear();
	Items.DescriptionFull.ChoiceList.Add(Object.Description);
	
	ReadPeriodicDetails();
	
	IntangibleAssetsLocalization.OnReadCreateAtServer(ThisForm);
	
	ConfigureDependentFormElementsOnServer();
	CreateCaptionRegistrationDocument(ThisForm);
	FillInAccountingInformation();
	
EndProcedure
 
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure GenerateFullNameAutomatically()
	
	If TrimAll(AttributesValuesBeforeChange.Description) = TrimAll(AttributesValuesBeforeChange.DescriptionFull)
		Or IsBlankString(Object.DescriptionFull) Then
		Object.DescriptionFull = Object.Description;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisForm, FormAttributeToValue("Object"));

EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedBankingDetails = "")
	
	If RequiresServerCallToConfigureFormElements(ChangedBankingDetails) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisForm, ChangedBankingDetails);
	EndIf; 
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;

	If UpdateAll Then
		UseFixedAssetImpairment = GetFunctionalOption("UseFixedAssetImpairment");
		Items.GroupImpairment.Visible = UseFixedAssetImpairment;
	EndIf;
	
	IntangibleAssetsLocalization.ConfigureDependentFormElements(ThisForm, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisForm, ChangedBankingDetails);

EndProcedure
 
&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, Val ChangedBankingDetails = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("KindOfAccountingObject")
		Or UpdateAll Then
		
		ThisIsIA = Object.KindOfAccountingObject = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset");
		
		If ThisIsIA Then
			Items.DetailsInfoPage.Title = NStr("vi = 'Thông tin về tài sản cố định vô hình';
												|ru = 'Сведения о НМА';
												|en = 'Information about intangible assets'; fa = 'اطلاعات دارایی‌های نامشهود';
												|it = 'Informazioni sul bene immateriale';
												|pl = 'Informacje o AT';
												|tr = 'Maddi olmayan varlık bilgileri'");
		Else
			Items.DetailsInfoPage.Title = NStr("vi = 'Thông tin về chi phí Nghiên cứu phát triển';
												|ru = 'Сведения о расходах на НИОКР';
												|en = 'R&D expense information'; fa = 'R&D expense information';
												|it = 'Informazioni sui costi di Ricerca e Sviluppo';
												|pl = 'Informacje o kosztach na R&D';
												|tr = 'Ar-Ge harcamalarına ilişkin bilgiler'");
		EndIf; 
		
		Items.RegistrationDocumentLabel.Visible = ThisIsIA;
		
	EndIf;
	
	If UpdateAll Then
		Items.InformationAcceptedForAccounting2.Visible = False;
		Items.InformationTermOfUse2.Visible = False;
		Items.InformationTermOfUse3.Visible = False;
		Items.GroupNetBookValueCFHeading.Visible = False;
		Items.GroupAccumulatedDepreciationHeadingCF.Visible = False;
		Items.GroupCurrentValueCFHeader.Visible = False;
	EndIf; 
	
	NonCurrentAssetsClientServerLocalization.ConfigureDependentFormElements_IntangibleAssets(
		Form, StructureOfChangedProps);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(ChangedBankingDetails)

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("BusinessActivityClassifierCode2") Then
		Return True;
	EndIf; 
	
	Return False;

EndFunction

&AtServer
Procedure SetVisibilityOfInputCommandsBasedOn_()

	SettingsAddress = ThisForm.AttachableCommandsParameters.CommandsTableAddress;
	CommandsTable = GetFromTempStorage(SettingsAddress);
	
	If GetFunctionalOption("UseNonCurrentAssets2_4") Then
		
		If ValueIsFilled(Object.Ref) Then
			InitialInformation = Catalogs.IntangibleAssets.InitialInformation(Object.Ref);
			CanBeTakenIntoAccount = InitialInformation.DateOfRecognitionAccounting = '000101010000'
								Or InitialInformation.DateOfRecognitionManagementAccounting = '000101010000';
			PostedInFinancialAccounting = InitialInformation.DateOfRecognitionAccounting <> '000101010000'
								Or InitialInformation.DateOfRecognitionManagementAccounting <> '000101010000';
		Else
			CanBeTakenIntoAccount = False;
			PostedInFinancialAccounting = False;
		EndIf;
		
		If AccessRight("Insert", Metadata.Documents.IntangibleAssetsInitialRecognition2_4) Then
			SetVisibilityOfInputCommandBasedOn("IntangibleAssetsInitialRecognition2_4", CommandsTable, CanBeTakenIntoAccount);
		EndIf; 
		If AccessRight("Insert", Metadata.Documents.ChangeIntangibleAssetFinancialDetails2_4) Then
			SetVisibilityOfInputCommandBasedOn("ChangeIntangibleAssetFinancialDetails2_4", CommandsTable, PostedInFinancialAccounting);
		EndIf; 
		If AccessRight("Insert", Metadata.Documents.IATransfer2_4) Then
			SetVisibilityOfInputCommandBasedOn("IATransfer2_4", CommandsTable, PostedInFinancialAccounting);
		EndIf; 
		If AccessRight("Insert", Metadata.Documents.DisposeIntangibleAssets2_4) Then
			SetVisibilityOfInputCommandBasedOn("DisposeIntangibleAssets2_4", CommandsTable, PostedInFinancialAccounting);
		EndIf; 
		If AccessRight("Insert", Metadata.Documents.IARevaluation2_4) Then
			SetVisibilityOfInputCommandBasedOn("IARevaluation2_4", CommandsTable, PostedInFinancialAccounting);
		EndIf; 
		If AccessRight("Insert", Metadata.Documents.PreparingForIntangibleAssetSale2_4) Then
			SetVisibilityOfInputCommandBasedOn("PreparingForIntangibleAssetSale2_4", CommandsTable, PostedInFinancialAccounting);
		EndIf; 
		If AccessRight("Insert", Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment) Then
			SetVisibilityOfInputCommandBasedOn("IntangibleAssetsCostAndAmortizationAdjustment", CommandsTable, PostedInFinancialAccounting);
		EndIf; 
		
	EndIf; 
	
	IntangibleAssetsLocalization.SetVisibilityOfInputCommandsBasedOn_(ThisForm, CommandsTable);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfInputCommandBasedOn(DocumentName, CommandsTable, CommandVisibility)

	CurRow = CommandsTable.Find("Document." + DocumentName, "Manager");
	If CurRow <> Undefined Then
		Items[CurRow.NameOnForm].Visible = CommandVisibility;
	EndIf;

EndProcedure

&AtServer
Procedure FillInAccountingInformation()

	If Not Catalogs.IntangibleAssets.ThereAreRightsToReadInformation() Then
		Items.DetailsInfoPage.Visible = False;
		Return;
	EndIf;
	
	InformationAboutAccounting = Catalogs.IntangibleAssets.InformationAboutAccounting(Object.Ref);
	If InformationAboutAccounting = Undefined Then
		Items.PagesIAInformation.CurrentPage = Items.PageInfoOnNotRecognized;
		Return;
	EndIf;
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(InformationAboutAccounting.Organization);
	
	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	If CurrencyOfMan <> ComplCurrency Then
		If ComplianceCAAccountingIsKept Then
			Items.DecorationTitleUU.Title = StrTemplate(NStr("vi = 'KTQT (%1):';
															|ru = 'УУ (%1):';
															|en = 'MA (%1):'; fa = 'MA (%1):';
															|it = 'Contabilità Gestionale (%1):';
															|pl = 'EZ (%1):';
															|tr = 'Yönetim Muhasebesi(%1):'"), String(CurrencyOfMan));
			Items.DecorationTitleBOO.Title = StrTemplate(NStr("vi = 'KTDN (%1):';
																|ru = 'БУ (%1):';
																|en = 'LA (%1):'; fa = 'LA (%1):';
																|it = 'Contabilità (%1):';
																|pl = 'EK (%1):';
																|tr = 'Genel Muhasebe (%1):'"), String(ComplCurrency));
		Else
			Items.DecorationTitleUU.Title = StrTemplate(NStr("vi = 'Quản trị (%1):';
															|ru = 'Упр. (%1):';
															|en = 'Mgmt (%1):'; fa = 'Mgmt (%1):';
															|it = 'Gest. (%1):';
															|pl = 'Zarz. (%1):';
															|tr = 'Yönetim (%1):'"), String(CurrencyOfMan));
			Items.DecorationTitleBOO.Title = StrTemplate(NStr("vi = 'Tài chính (%1):';
																|ru = 'Регл. (%1):';
																|en = 'Local (%1):'; fa = 'Local (%1):';
																|it = 'Regol. (%1):';
																|pl = 'Reg. (%1):';
																|tr = 'Yerel (%1):'"), String(ComplCurrency));
		EndIf; 
	EndIf; 
	
	If Not GetFunctionalOption("UseLocal") Then
		Items.DecorationTitleWELL.Visible = False;
		Items.DecorationTitlePR.Visible = False;
		Items.DecorationTitleVR.Visible = False;
	EndIf; 
	
	If Not ComplianceCAAccountingIsKept
		And CurrencyOfMan = ComplCurrency Then
		
		Items.DecorationTitleBOO.Visible = False;
		Items.DecorationTitleUU.Visible = False;
		
		Items.GroupResidualValueHeading.Visible    = False;
		Items.GroupAccumulatedDepreciationHeading.Visible = False;
		Items.GroupCurrentValueHeading.Visible       = False;
		Items.GroupImpairmentHeading.Visible            = False;
		
		Items.ReplacementACCost.Visible = False;
		Items.AccumulatedDepreciationAccounting.Visible     = False;
		Items.ACResidualValue.Visible        = False;
		Items.ImpairmentAC.Visible                = False;
		
		Items.ReplacementCostOfTheUU.Visible = False;
		Items.AccumulatedDepreciationManagementAccounting.Visible     = False;
		Items.NetBookValueMan.Visible        = False;
		Items.ImpairmentMA.Visible                = False;
		
	EndIf; 
	
	CostAndDepreciation = NonCurrentAssets.CostAndDepreciationOfIa(Object.Ref);
	
	Items.PagesIAInformation.CurrentPage = Items.PageInfoOnRecognized;
	
	PresentationOfInformation = Catalogs.IntangibleAssets.PresentationOfAccountingInformation(InformationAboutAccounting, CostAndDepreciation);
	
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationAcceptedForAccounting1, PresentationOfInformation.InformationAcceptedForAccounting1);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationAcceptedForAccounting3, PresentationOfInformation.InformationAcceptedForAccounting3);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationTermOfUse1, PresentationOfInformation.InformationTermOfUse1);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationTermOfUse3, PresentationOfInformation.InformationTermOfUse3);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationLiquidationValue, PresentationOfInformation.InformationLiquidationValue);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationLiquidationValueOfRegl, PresentationOfInformation.InformationLiquidationValueOfRegl);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationRemovedFromTheRegister, PresentationOfInformation.InformationRemovedFromTheRegister1);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.HFCInformation, PresentationOfInformation.HFCInformation);
	
	If InformationAboutAccounting <> Undefined Then
		
		HeaderInformation_ = StrTemplate(NStr("vi = 'Nơi kế toán (thông tin từ%1)';
												|ru = 'Место учета (сведения от %1)';
												|en = 'Registration place (information from %1)'; fa = 'Registration place (information from %1)';
												|it = 'Luogo di registrazione (informazioni dal %1)';
												|pl = 'Miejsce ewidencji (informacje o %1)';
												|tr = 'Muhasebe yeri (%1 üzerindeki bilgiler)'"), Format(InformationAboutAccounting.PeriodOfInformationAboutPlaceOfRegistration, "DLF=D"));
		Items.GroupLocation.Title = HeaderInformation_;
		
	EndIf; 
	
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationRegistrationPlaceCompany, PresentationOfInformation.InformationRegistrationPlaceCompany);
		
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationRegistrationPlaceDepartment, PresentationOfInformation.InformationRegistrationPlaceDepartment);

	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationReplacementCost, PresentationOfInformation.InformationReplacementCost);
		
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationAccumulatedDepreciation, PresentationOfInformation.InformationAccumulatedDepreciation);
		
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationResidualValue, PresentationOfInformation.InformationResidualValue);
		
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationImpairment, PresentationOfInformation.InformationImpairment);
		
	#Region Amounts

	ReplacementACCost = CostAndDepreciation.LocalCost;
	ReplacementCostOfTheUU = CostAndDepreciation.Cost;
	AccumulatedDepreciationAccounting = CostAndDepreciation.DepreciationLocal;
	AccumulatedDepreciationManagementAccounting = CostAndDepreciation.Depreciation;
	
	ACResidualValue = CostAndDepreciation.LocalCost
								- CostAndDepreciation.DepreciationLocal
								- CostAndDepreciation.ImpairmentLocalAssets;
	
	NetBookValueMan = CostAndDepreciation.Cost
								- CostAndDepreciation.Depreciation
								- CostAndDepreciation.ImpairmenMan;
	
	ImpairmentAC = CostAndDepreciation.ImpairmentLocalAssets;
	ImpairmentMA = CostAndDepreciation.ImpairmenMan;
	
	If Object.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
		Items.GroupCurrentValueHeading.Title       = NStr("vi = 'Nguyên giá:';
															|ru = 'Первоначальная стоимость:';
															|en = 'Initial cost:'; fa = 'Initial cost:';
															|it = 'Costo iniziale:';
															|pl = 'Wartość początkowa:';
															|tr = 'Başlangıç değeri:'");
		Items.GroupAccumulatedDepreciationHeading.Title = NStr("vi = 'Giá trị quy đổi:';
																|ru = 'Погашенная стоимость:';
																|en = 'Repaid cost:'; fa = 'Repaid cost:';
																|it = 'Valore estinto:';
																|pl = 'Wartość spłacona:';
																|tr = 'İade edilen maliyet:'");
		Items.GroupResidualValueHeading.Title    = NStr("vi = 'Giá trị còn lại:';
														|ru = 'Остаточная стоимость:';
														|en = 'Net book value:'; fa = 'Net book value:';
														|it = 'Valore residuo:';
														|pl = 'Wartość rezydualna:';
														|tr = 'Net defter değeri:'");
	Else
		Items.GroupCurrentValueHeading.Title       = NStr("vi = 'Chi phí thay thế:';
															|ru = 'Восстановительная стоимость:';
															|en = 'Replacement cost:'; fa = 'Replacement cost:';
															|it = 'Costi recuperabili:';
															|pl = 'Koszt odtworzenia:';
															|tr = 'Yenileme değeri:'");
		Items.GroupAccumulatedDepreciationHeading.Title = NStr("vi = 'Khấu hao lũy kế:';
																|ru = 'Накопленная амортизация:';
																|en = 'Accumulated depreciation:'; fa = 'Accumulated depreciation:';
																|it = 'Ammortamenti accumulati:';
																|pl = 'Skumulowana amortyzacja:';
																|tr = 'Birikmiş amortisman:'");
		Items.GroupResidualValueHeading.Title    = NStr("vi = 'Giá trị còn lại:';
														|ru = 'Остаточная стоимость:';
														|en = 'Net book value:'; fa = 'Net book value:';
														|it = 'Valore residuo:';
														|pl = 'Wartość rezydualna:';
														|tr = 'Net defter değeri:'");
	EndIf; 
	
	Items.GroupImpairmentHeading.Title = NStr("vi = 'Giảm giá trị:';
												|ru = 'Обесценение:';
												|en = 'Impairment:'; fa = 'Impairment:';
												|it = 'Svalutazione:';
												|pl = 'Utrata wartości:';
												|tr = 'Değer kaybı:'");
		
	Items.CurrentValueGroup.ShowTitle        = False;
	Items.GroupAccumulatedDepreciation.ShowTitle  = False;
	Items.GroupImpairment.ShowTitle  = False;
	Items.GroupResidualValue_2.ShowTitle     = False;
	
	Items.GroupImpairment.ShowTitle             = False;
	
	#EndRegion
	
	IntangibleAssetsLocalization.FillInAccountingInformation(ThisObject, InformationAboutAccounting, PresentationOfInformation);
	IntangibleAssetsLocalization.FillInCostAndDepreciation(ThisObject, CostAndDepreciation);
	
EndProcedure

&AtClient
Procedure EnteringInformationAboutRegistrationDocumentEnding(ClosingResult, AdditionalParameters) Export

	If TypeOf(ClosingResult) = Type("Structure") Then
		Object.RegistrationDocumentDescription = ClosingResult.RegistrationDocumentDescription;
		Object.RegistrationDocumentDate = ClosingResult.RegistrationDocumentDate;
		Object.RegistrationDocumentNumber = ClosingResult.RegistrationDocumentNumber;
		Modified = True;
		CreateCaptionRegistrationDocument(ThisForm);
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure CreateCaptionRegistrationDocument(Form)

	Object = Form.Object;
	
	If ValueIsFilled(Object.RegistrationDocumentDescription)
		Or ValueIsFilled(Object.RegistrationDocumentDate) 
		Or ValueIsFilled(Object.RegistrationDocumentNumber) Then
		
		If Not Form.ReadOnly Then
			StringWithTags = NStr("vi = '%1 №%2 ngày %3 <a href = ""#Изменить"">thay đổi</a>';
									|ru = '%1 №%2 от %3 <a href = ""#Изменить"">изменить</a>';
									|en = '%1 No.%2 dated %3 <a href = ""#Изменить"">change</a>'; fa = '%1 No.%2 dated %3 <a href = ""#Изменить"">change</a>';
									|it = '%1 №%2 от %3 <a href = ""#Изменить"">изменить</a>';
									|pl = '%1 No.%2 dated %3 <a href = ""#Изменить"">change</a>';
									|tr = '%1 %2 sayılı %3 tarihli değiştir'");
		Else
			StringWithTags = NStr("vi = '%1 Số%2 ngày %3';
									|ru = '%1 №%2 от %3';
									|en = '%1 No%2 dated %3'; fa = '%1 No%2 dated %3';
									|it = '%1 №%2 del %3';
									|pl = '%1 nr %2 z dnia %3.';
									|tr = '%1 sayılı %2 tarihli %3'");
		EndIf;
		
		StringWithTags = StrTemplate(
							StringWithTags, 
							Object.RegistrationDocumentDescription,
							Object.RegistrationDocumentNumber,
							Format(Object.RegistrationDocumentDate, "DLF=D"));
							
		LabelText = NonCurrentAssetsClientServer.FormattedString(StringWithTags);
							
	Else
		
		RowsArray = New Array;
		RowsArray.Add(New FormattedString(NStr("vi = 'chưa điền';
												|ru = 'не заполнен';
												|en = 'not filled in'; fa = 'not filled in';
												|it = 'non compilato';
												|pl = 'nie wypełniony';
												|tr = 'doldurulmadı'"),, Form.UnavailableTextColor));
		
		If Not Form.ReadOnly Then
			RowsArray.Add(" ");
			RowsArray.Add(New FormattedString(NStr("vi = 'thay đổi';
													|ru = 'изменить';
													|en = 'change'; fa = 'change';
													|it = 'modificare';
													|pl = 'change';
													|tr = 'değiştir'"),,,, "#Change"));
		EndIf;
		
		LabelText = New FormattedString(RowsArray);
		
	EndIf;
	
	Form.RegistrationDocumentLabel = LabelText;

EndProcedure

// Returns:
// 	Structure - LongDesc:
//          * DescriptionFull - String -
//          * Description - String -
&AtClient
Function SaveDetailsValuesBeforeChanging()

	NewPropsValuesBeforeChanges = New Structure;
	NewPropsValuesBeforeChanges.Insert("Description", Object.Description);
	NewPropsValuesBeforeChanges.Insert("DescriptionFull", Object.DescriptionFull);
	
	Return NewPropsValuesBeforeChanges;

EndFunction

&AtServer
Procedure WhenChangingIADocuments()

	FillInAccountingInformation();
	ReadPeriodicDetails();

EndProcedure
 
&AtServer
Procedure ReadPeriodicDetails()

	If Not GetFunctionalOption("UseFixedAssetAccountingByActivities")
		Or Not NonCurrentAssets.VNAManagementIsUsed() Then
		
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		Items.BusinessAreaHistory.Visible = False;
	EndIf;
	
	QueryText = 
	"SELECT
	|	IntangibleAssetsAccountingProcedure.LineOfBusiness AS LineOfBusiness
	|FROM
	|	InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast(, IntangibleAsset = &IntangibleAsset) AS IntangibleAssetsRegistrationPlace
	|		INNER JOIN InformationRegister.IntangibleAssetsAccountingProcedure.SliceLast(, IntangibleAsset = &IntangibleAsset) AS IntangibleAssetsAccountingProcedure
	|		ON (IntangibleAssetsAccountingProcedure.IntangibleAsset = IntangibleAssetsRegistrationPlace.IntangibleAsset)
	|			AND (IntangibleAssetsAccountingProcedure.Organization = IntangibleAssetsRegistrationPlace.Organization)";
	
	Query = New Query(QueryText);
	Query.SetParameter("IntangibleAsset", Object.Ref);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Selection = Result.Select();
	
	If Selection.Next() Then
		
		LineOfBusiness = Selection.LineOfBusiness;
		ChangeHistory = Catalogs.IntangibleAssets.HistoryOfChangingProps(Object.Ref, "LineOfBusiness");
		Items.BusinessAreaHistory.Visible = (ChangeHistory.Count() <> 0);
		
	Else
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		Items.BusinessAreaHistory.Visible = False;
	EndIf;
		
EndProcedure


#EndRegion
