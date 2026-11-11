#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties	
	
	ThereIsTheRightToEdit = AccessRight("Edit", Metadata.Catalogs.ItemsCharacteristics);
	
	If Parameters.Property("ChoiceMode")
		And Parameters.ChoiceMode Then
		ForSelection = True;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		
		ThisForm.ReadOnly = Not ThereIsTheRightToEdit;
		
		UpdateCacheOfProductTypeDetails();
		UpdateYourBankingDetailsSettings();
		CustomizeForm();
		
	Else	
		
		StructureCreationParameters = New Structure;
		StructureCreationParameters.Insert("Description", "");
		StructureCreationParameters.Insert("DescriptionFull", "");
		StructureCreationParameters.Insert("CopySource", Catalogs.ItemsCharacteristics.EmptyRef());
		StructureCreationParameters.Insert("ProductKind", Catalogs.ItemKinds.EmptyRef());
		StructureCreationParameters.Insert("Owner", Undefined);
		
		FillPropertyValues(StructureCreationParameters, Parameters);

		AdditionalParametersPassed = Undefined;
		If Parameters.Property("AdditionalParameters", AdditionalParametersPassed) And AdditionalParametersPassed <> Undefined Then
			CommonClientServer.SupplementStructure(StructureCreationParameters, AdditionalParametersPassed, True);
		EndIf;
			
		If Parameters.Property("FillingText")
			And Not IsBlankString(Parameters.FillingText) Then
			
			StructureCreationParameters.Description = Parameters.FillingText;
			
		EndIf;
		
		CreationParameters = New FixedStructure(StructureCreationParameters);
				
		FillInByCreationParameters();
		CustomizeForm();
		
	EndIf;
	
	FormInitialized      = True;
	ProductsKindBeforeChange = Object.ProductKind;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
		
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	OnCreateAtServerLocalization();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	StructureCreationParameters = New Structure();
	StructureCreationParameters.Insert("Description", Object.Description);
	StructureCreationParameters.Insert("DescriptionFull", Object.DescriptionFull);
	
	CreationParameters = New FixedStructure(StructureCreationParameters);
	
	ItemKitConfiguration = SetsServerCall.DefaultProductConfigurationOption(
		Object.Owner,
		Object.Ref);
	
	If FormInitialized Then
		UpdateCacheOfProductTypeDetails();
		UpdateYourBankingDetailsSettings();
		CustomizeForm();
		ProductsKindBeforeChange = Object.ProductKind;
	EndIf;

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ItemKinds" Then
		
		WhenWritingTypeOfProductItem();
		
	ElsIf EventName = "Write_ProductKitConfigurations" Then
		
		If ProductKindAttributes.ItemsType = PredefinedValue("Enum.ItemsTypes.Set")
			And ProductKindAttributes.UseVariants = PredefinedValue("Enum.ItemVariantsUsageOptions.SpecialForItems")
			And Parameter.Main
			And Parameter.KitOwner = Object.Owner
			And Parameter.Characteristic = Object.Ref Then
			
			ItemKitConfiguration = Parameter.Kit;
			
			CustomizeForm();
		EndIf;
		
	EndIf;
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateYourBankingDetailsSettings();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
EndProcedure
 
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	PrepareDataForInteractivityBeforeRecording(Cancel);
	
	If ValueIsFilled(AddressTemporaryStorageTableFound) Then
		Cancel = True;
		FormParameters = New Structure("AddressTemporaryStorageTableFound, ThisIsARecord",
			AddressTemporaryStorageTableFound,True);
		OpenForm("Catalog.Products.Form.CheckUnique",
			FormParameters,ThisForm,
			,
			,
			,
			New CallbackDescription("CheckForUniquenessCompletion",ThisForm),
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	WriteParameters.Insert("ThisIsNewCharacteristic", Not ValueIsFilled(Object.Ref));
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("WorkingNameTemplateCharacteristics");
	AttributesStructure1.Insert("ProhibitEditingWorkingTitleOfItemVariants");
	AttributesStructure1.Insert("NameTemplateForPrintingCharacteristics");
	AttributesStructure1.Insert("DisableNameChangeToPrintItemVariant");
	
	ObjectAttributes = Common.ObjectAttributesValues(Object.ProductKind, AttributesStructure1);
	
	CurrentObject.AdditionalProperties.Insert("PrintNameGenerated");
	CurrentObject.AdditionalProperties.Insert("WorkingNameFormed");
	CurrentObject.AdditionalProperties.Insert("WorkingNameVerified", True);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If ValueIsFilled(Object.ItemsCharacteristicForPricing) Then
		NotifyChanged(Object.ItemsCharacteristicForPricing);
	EndIf;

	Notify("Write_ItemsCharacteristics", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region HandlersForHeaderElements

&AtClient
Procedure OwnerOnChange(Item)
	OwnerWhenChangedOnServer();
EndProcedure

&AtClient
Procedure PrincipalOnChange(Item)
	PrincipalWhenChangingOnServer();
EndProcedure

&AtServer
Procedure PrincipalWhenChangingOnServer()
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Principal, Object.Counterparty);
EndProcedure

&AtClient
Procedure HyperlinkGoNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	HyperlinkGoToFormParametersAndQuestion(Item.Name, FormattedStringURL);
	
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CheckForUniqueness(Command)
	
	ClearMessages();
	
	StandardProcessing = False;
	
	Cancel = False;
	AddressTemporaryStorageTableFound = CheckForUniquenessServer(Cancel); 
	
	If Not Cancel Then
		If ValueIsFilled(AddressTemporaryStorageTableFound) Then
			FormParameters = New Structure("AddressTemporaryStorageTableFound, Record", AddressTemporaryStorageTableFound, False);
			OpenForm("Catalog.Products.Form.CheckUnique",
				FormParameters,ThisForm,
				,
				,
				FormWindowOpeningMode.LockOwnerWindow,
				New CallbackDescription("CheckForUniquenessCompletion",
					ThisForm),
				FormWindowOpeningMode.LockOwnerWindow);
		Else
				ShowMessageBox(Undefined,NStr("vi = 'Đặc tính mặt hàng duy nhất';
												|ru = 'Характеристика номенклатуры уникальна';
												|en = 'Item variant is unique'; fa = 'Item variant is unique';
												|it = 'Caratteristica dell''articolo è unica';
												|pl = 'Cecha nomenklatury jest unikalna';
												|tr = 'Ürün varyantları benzersiz'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure FillInAPrintNameFromTemplate(Command)
	FillInANameFromTemplateServer("ForPrint");
EndProcedure

&AtClient
Procedure FillInAWorkNameFromTemplate(Command)
	FillInANameFromTemplateServer("Working");
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#Region Other

// Parameters:
// 	Result - See ProductsClient.NewCompletionProcessingResult
// 	AdditionalParameters - Undefined - 
&AtClient
Procedure CheckForUniquenessCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Action = "SelectAnExisting" Then
		
		NotificationParameters = New Structure("ThisIsNewCharacteristic", False);
		Notify("Write_ItemsCharacteristics",NotificationParameters,Result.Ref);
		
		If ForSelection Then
			NotifyChoice(Result.Ref);
		Else
			Modified = False;
			Close();
		EndIf;
		
	ElsIf Result.Action = "ContinueWrite" Then
		
		UniquenessControlBeforeWritingIsCompleted = True;
		
		Try
			ItemRecorded = Write();
		Except
			UniquenessControlBeforeWritingIsCompleted = False;
			Return;
		EndTry;
		
		If Not ItemRecorded Then
			UniquenessControlBeforeWritingIsCompleted = False;
			Return;
		EndIf;
		
		If ForSelection Then
			NotifyChoice(Object.Ref);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function CheckForUniquenessServer(Cancel)
	
	CheckRequiredBankingDetails(Cancel);
	
	If Not Cancel Then
		AddressTemporaryStorageTableFound = CheckUniquenessOfGivenName(False);
	Else
		AddressTemporaryStorageTableFound = "";
	EndIf;
	
	Return AddressTemporaryStorageTableFound;
	
EndFunction

&AtServer
Function CheckUniquenessOfGivenName(ThisIsARecord, Cancel = False)
	
	If Cancel Then
		Return Undefined
	EndIf;
	
	TableFound.Clear();
	
	If Constants.ControlItemUniquenessByCombinationValuesAttributes.Get()
		And Not ValueIsFilled(Object.Ref)
		And Not UniquenessControlBeforeWritingIsCompleted Then
		
		Catalogs.Products.CheckUniquenessOfElementByItsDetails(ThisObject);
		
	EndIf;	
	
	If ThisIsARecord Then
		If GenerateWorkName
			And GeneratePrintName Then
			FillInANameFromTemplateServer("Both");
		ElsIf GenerateWorkName Then
			FillInANameFromTemplateServer("Working");
		ElsIf GeneratePrintName Then
			FillInANameFromTemplateServer("ForPrint");
		EndIf;
	EndIf;
		
	If ValueIsFilled(Object.Description)
		And Constants.ControlUniquenessOfWorkingNamesOfProductsAndItemVariants.Get() Then
		CheckUniquenessByWorkingName();
	ElsIf Not ValueIsFilled(Object.Description) And ThisIsARecord Then
		MessageText = NStr("vi = 'Chưa điền trường ""Tên gọi làm việc""';
							|ru = 'Поле ""Рабочее наименование"" не заполнено';
							|en = '""Working title"" is required'; fa = '""Working title"" is required';
							|it = 'Il campo ""Titolo lavorativo"" non è compilato';
							|pl = 'Nie wypełniono pola ""Nazwa robocza""';
							|tr = '""Çalışma tanımı"" alanı doldurulmadı'");
		Common.MessageToUser(MessageText, Undefined, "Description", "Object");
		Cancel = True;
	EndIf;
	
	TableFound.Sort("Ref");
	If TableFound.Count()>0 Then
		Cancel = True;
		Return PutToTempStorage(TableFound.Unload(),UUID);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtServer
Procedure CheckUniquenessByWorkingName()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ItemsCharacteristics.Ref AS Ref
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|WHERE
	|	ItemsCharacteristics.Ref <> &Ref
	|	AND ItemsCharacteristics.Owner = &Owner
	|	AND ItemsCharacteristics.Description = &Description";
	
	Query.SetParameter("Ref",       Object.Ref);
	Query.SetParameter("Owner",     Object.Owner);
	Query.SetParameter("Description", Object.Description);
	
	Selection = Query.Execute().Select();
	
	Filter = New Structure("Ref");
	
	While Selection.Next() Do
		
		Filter.Ref = Selection.Ref;
		
		FoundRows = TableFound.FindRows(Filter);
		
		If FoundRows.Count() = 0 Then
			
			NewRow = TableFound.Add();
			
			NewRow.Ref                = Selection.Ref;
			NewRow.FoundByName = True;
			
		Else
			
			FoundRows[0].FoundByName = True;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	If Object.Owner = Undefined Then
		Items.Owner.Title = NStr("vi = 'Mặt hàng hoặc dạng mặt hàng';
								|ru = 'Номенклатура или вид номенклатуры';
								|en = 'Items or their kind'; fa = 'اقلام یا نوع آن‌ها';
								|it = 'Articolo o tipo di articolo';
								|pl = 'Produkt lub rodzaj produktów';
								|tr = 'Öğe veya ürün türü'");
	ElsIf TypeOf(Object.Owner) = Type("CatalogRef.Products") Then
		Items.Owner.Title = NStr("vi = 'Mặt hàng';
								|ru = 'Номенклатура';
								|en = 'Items'; fa = 'اقلام';
								|it = 'Articolo';
								|pl = 'Pozycja';
								|tr = 'Öğe'");
	ElsIf TypeOf(Object.Owner) = Type("CatalogRef.ItemKinds") Then
		Items.Owner.Title = NStr("vi = 'Dạng mặt hàng';
								|ru = 'Вид номенклатуры';
								|en = 'Item kind'; fa = 'نوع قلم';
								|it = 'Tipo di articolo';
								|pl = 'Rodzaj pozycji';
								|tr = 'Ürün türü'");
	EndIf;
	
	Items.WarningDecoration.Visible =  (TypeOf(Object.Owner) = Type("CatalogRef.ItemKinds"));
	
	Items.FillInAPrintNameFromTemplate.Enabled = ValueIsFilled(ProductKindAttributes().NameTemplateForPrintingCharacteristics);
	Items.FillInAWorkNameFromTemplate.Enabled   = ValueIsFilled(ProductKindAttributes().WorkingNameTemplateCharacteristics);
	
	Items.Description.ReadOnly       = ProductKindAttributes().ProhibitEditingWorkingTitleOfItemVariants;
	Items.DescriptionFull.ReadOnly = ProductKindAttributes().DisableNameChangeToPrintItemVariant;
	
	VisibilityAndHeaderSettings = Catalogs.ItemsCharacteristics.VisibilityAndHeaderSettings(Object, ProductKindAttributes());
	
	VisibilityOfElements = VisibilityAndHeaderSettings.VisibilityOfElements;
	ItemsTitles = VisibilityAndHeaderSettings.ItemsTitles;
	
	For Each VisibilityItem In VisibilityOfElements Do
		If Items.Find(VisibilityItem.Key) <> Undefined Then
			Items[VisibilityItem.Key].Visible = VisibilityItem.Value;
		EndIf;
	EndDo;
	
	For Each ItemHeader In ItemsTitles Do
		
		TagName = ItemHeader.Key;
		
		ItemTitle = Catalogs.Products.HyperlinkHeader(ItemHeader);
		
		Control = Items.Find(TagName);
		
		If Control <> Undefined
			And TypeOf(Control) <> Type("FormGroup") Then
			
			Control.Title = ItemTitle;
			
		EndIf;
		
	EndDo;
	
	BankingDetailsWithRedefinedMandatoryFields = 
		Catalogs.ItemsCharacteristics.BankingDetailsWithRedefinedMandatoryFields(ProductKindAttributes(), Object);
		
	For Each KeyValue In BankingDetailsWithRedefinedMandatoryFields Do
		
		TagName = StrReplace(KeyValue.Key, ".", "");
		Items[TagName].AutoMarkIncomplete = KeyValue.Value;
		
	EndDo;
	
	If ProductKindAttributes().AccountingFeature = Enums.ItemAccountingFeatures.PerformedByCompanyOnAgencyBasis Then
		CompanyLinkType = New TypeDescription("CatalogRef.Companies");
		Items.Principal.TypeRestriction = CompanyLinkType;
	EndIf;
	
	If ProductKindAttributes().AccountingFeature = Enums.ItemAccountingFeatures.PerformedByPartner Then
		CounterpartiesLinkType = New TypeDescription("CatalogRef.Counterparties");
		LinkTypePartners    = New TypeDescription("CatalogRef.Partners");
		
		Items.Principal.TypeRestriction  = LinkTypePartners;
		Items.Counterparty.TypeRestriction = CounterpartiesLinkType;
	EndIf;

EndProcedure

&AtServer
Procedure UpdateYourBankingDetailsSettings()
	
	UpdateAdditionalAttributesItems();
	
	For Each Item In Items.GroupAdditionalAttributes.ChildItems Do
		
		If Item.Type = FormFieldType.InputField Then
			
			If Item.MultiLine <> True Then
				
				Item.HorizontalStretch = False;
				
			Else
				
				Item.TitleLocation       = FormItemTitleLocation.Left;
				Item.VerticalStretch   = False;
				Item.HorizontalStretch = True;
				
			EndIf;
			
		ElsIf Item.Type = FormFieldType.CheckBoxField Then
			
			Item.TitleLocation = FormItemTitleLocation.Right;
			
		EndIf;
		
	EndDo;
	
	AttributesTable = Catalogs.Products.AttributeSettingTable(ProductKindAttributes().Ref,
																			ProductKindAttributes().ItemsType,
																			ProductKindAttributes().AccountingFeature,
																			Undefined,
																			Undefined,
																			"ItemsCharacteristics");
	
	AttributeSettingTable.Load(AttributesTable);
	
	Catalogs.Products.ConfigureFormUsingSettingsTable(ThisForm);
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject,,False);

EndProcedure

&AtServer
Procedure FillInByCreationParameters()
	
	If Not ValueIsFilled(Object.Owner)
		And ValueIsFilled(CreationParameters().ProductKind) Then
		
		DetailsOfOwner = Common.ObjectAttributesValues(CreationParameters().ProductKind,
		"UseVariants,ItemVariantsOwner");
		
		If DetailsOfOwner.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind Then
			Object.Owner = CreationParameters().ProductKind;
		ElsIf DetailsOfOwner.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
			Object.Owner = DetailsOfOwner.ItemVariantsOwner;
		Else
			Object.Owner = CreationParameters().Owner;
		EndIf;
		
		Object.ProductKind = CreationParameters().ProductKind;
		
		TMCommonUseClientServer.FillInValuesOfEmptyProperties(Object, CreationParameters());
	EndIf;
	
	ProductTypeWhenChangedOnServer();
		
	If ValueIsFilled(Object.ProductKind) Then
		
		If CreationParameters().Property("AddressOfParameterTable")
			And ValueIsFilled(CreationParameters().AddressOfParameterTable)
			And IsTempStorageURL(CreationParameters().AddressOfParameterTable) Then
			
			AddlAttributesTable = New ValueTable;
			AddlAttributesTable.Columns.Add("AttributeName", New TypeDescription("String",,,New StringQualifiers(255)));
			
			TableOfPropsValues = GetFromTempStorage(CreationParameters().AddressOfParameterTable);
			AttributesArray = TableOfPropsValues.FindRows(New Structure("IsAddlAttribute", False));
			
			For Each ArrayElement In AttributesArray Do
				If Not ValueIsFilled(Object[ArrayElement.AttributeName]) Then
					Object[ArrayElement.AttributeName] = ArrayElement.FilterValue;
				EndIf;
			EndDo;
			
			AddlAttributesArray = TableOfPropsValues.FindRows(New Structure("IsAddlAttribute", True));
			
			If GetFunctionalOption("UseAdditionalAttributesAndInfo") 
				And AddlAttributesArray.Count() > 0 Then
				
				For Each ArrayElement In AddlAttributesArray Do
					
					NewRow = AddlAttributesTable.Add();
					NewRow.AttributeName = ArrayElement.AttributeName;
					
				EndDo;
				
				Query = New Query;
				Query.Text =
				"SELECT
				|	AddlAttributesTable.AttributeName
				|INTO PropertyNameTable
				|FROM
				|	&AddlAttributesTable AS AddlAttributesTable
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	PropertyNameTable.AttributeName AS AttributeName,
				|	AdditionalAttributeSets.Property AS Property
				|FROM
				|	PropertyNameTable AS PropertyNameTable
				|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AdditionalAttributeSets
				|		ON PropertyNameTable.AttributeName = AdditionalAttributeSets.Property.Description
				|WHERE
				|	AdditionalAttributeSets.Ref = &AttributesSet";
				
				Query.SetParameter("AddlAttributesTable", AddlAttributesTable);
				Query.SetParameter("AttributesSet",      ProductKindAttributes().CharacteristicsPropertySet);
				
				PropertiesTable = Query.Execute().Unload();
				TheStructureOfTheSearch = New Structure("AttributeName");
				
				For Each TableRow In PropertiesTable Do
					
					ValueSearchStructure_ = New Structure("Property", TableRow.Property);
					RowsArray = ThisForm.PropertiesAdditionalAttributeDetails.FindRows(ValueSearchStructure_);
					PropertyDetails = RowsArray[0];
					DataPath = PropertyDetails.ValueAttributeName;
					
					TheStructureOfTheSearch.AttributeName = TableRow.AttributeName;
					ArrayOfStringsValue = TableOfPropsValues.FindRows(TheStructureOfTheSearch);
					AttributeValue = ArrayOfStringsValue[0].FilterValue;
					If Not ValueIsFilled(ThisForm[DataPath]) Then
						ThisForm[DataPath] = AttributeValue;
					EndIf;
					
				EndDo;
				
			EndIf;
		EndIf;
	EndIf;	
	
EndProcedure

&AtServer
Procedure ProductTypeWhenChangedOnServer()
	
	UpdateCacheOfProductTypeDetails();
	
	If ProductsKindBeforeChange = Object.ProductKind Then
		Return;
	Else
		ProductsKindBeforeChange = Object.ProductKind;
	EndIf;
	
	If ValueIsFilled(Object.ProductKind) Then
		
		If ValueIsFilled(ProductKindAttributes().WorkingNameTemplateCharacteristics) Then
			Object.Description = "";
			GenerateWorkName = True;
		ElsIf ValueIsFilled(CreationParameters().Description) Then
			// After switching back to the item type without a template, we return the original name.
			Object.Description = CreationParameters().Description;
		EndIf;
		
		If ValueIsFilled(ProductKindAttributes().NameTemplateForPrintingCharacteristics) Then
			Object.DescriptionFull = "";
			GeneratePrintName = True;
		ElsIf ValueIsFilled(CreationParameters().DescriptionFull) Then 	
			// After switching back to the item type without a template, we return the original name.
			Object.DescriptionFull = CreationParameters().DescriptionFull;
		EndIf;
		
	EndIf;
	
	UpdateYourBankingDetailsSettings();
	
EndProcedure

&AtServer
Procedure WhenWritingTypeOfProductItem()

	UpdateCacheOfProductTypeDetails();
	CustomizeForm();

EndProcedure

&AtServer
Procedure PrepareDataForInteractivityBeforeRecording(Cancel)
	
	CheckRequiredBankingDetails(Cancel);
	
	// We always call the uniqueness control, because it is necessary to check the uniqueness of the working name.
	AddressTemporaryStorageTableFound = CheckUniquenessOfGivenName(True, Cancel);
	
EndProcedure

&AtServer
Procedure CheckRequiredBankingDetails(Cancel)
	
	ErrorText = NStr("vi = 'Trường ""%AttributeName%"" chưa điền';
					|ru = 'Поле ""%AttributeName%"" не заполнено';
					|en = '""%AttributeName%"" is required'; fa = '""%AttributeName%"" is required';
					|it = 'Il campo ""%AttributeName%"" non è compilato';
					|pl = 'Nie wypełniono pola ""%AttributeName%""';
					|tr = '""%AttributeName%"" alanı doldurulmadı'");
	
	If Not ValueIsFilled(Object.ProductKind) Then
		
		Cancel = True; 
		MessageText = StrReplace(ErrorText, "%AttributeName%", NStr("vi = 'Dạng mặt hàng';
																	|ru = 'Вид номенклатуры';
																	|en = 'Item kind'; fa = 'نوع قلم';
																	|it = 'Tipo di articolo';
																	|pl = 'Rodzaj pozycji';
																	|tr = 'Ürün türü'"));
		Common.MessageToUser(MessageText, Undefined,"Object.ProductKind", "", Cancel);
		Return;
		
	EndIf;
	
	AttributesNotToCheck = Catalogs.ItemsCharacteristics.AttributesNotToCheck(Object);
	
	For Each TableRow In AttributeSettingTable Do
		
		If TableRow.IsAddlAttribute Then
			Continue;
		EndIf;
		
		If Not TableRow.RequiredToFill
			Or AttributesNotToCheck.Find(TableRow.AttributeName) <> Undefined Then
			
			Continue;
			
		EndIf;
		
		AttributeValue = Object[TableRow.AttributeName];
		AttributePath1 = TableRow.DataPath;
		
		If Not ValueIsFilled(AttributeValue) Then
			
			MessageText = StrReplace(ErrorText, "%AttributeName%", TableRow.Presentation);
												
			Common.MessageToUser(MessageText,
													Undefined,
													"Object." + TableRow.AttributeName,
													"",
													Cancel);
			
		EndIf;
	
	EndDo;
	
	CheckedAttributes = New Array;
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
			
	If Cancel Then
		CustomizeForm();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInANameFromTemplateServer(FormationOption)
	
	PropertyManager.BeforeWriteAtServer(ThisForm, Object);
	
	CatalogObject = FormAttributeToValue("Object");
	
	If FormationOption = "Working" Or FormationOption = "Both" Then
		Object.Description = ProductsServer.NameByTemplate(ProductKindAttributes().WorkingNameTemplateCharacteristics,
			CatalogObject);
		CatalogObject.Description = Object.Description;
	EndIf;
	If FormationOption = "ForPrint" Or FormationOption = "Both" Then
		Object.DescriptionFull = ProductsServer.NameByTemplate(ProductKindAttributes().NameTemplateForPrintingCharacteristics,
			CatalogObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure OwnerWhenChangedOnServer()
	
	ProductTypeWhenChangedOnServer();
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure UpdateCacheOfProductTypeDetails()
	
	If ValueIsFilled(Object.Owner) Then
		If TypeOf(Object.Owner) = Type("CatalogRef.Products") Then
			Object.ProductKind = Common.ObjectAttributeValue(Object.Owner, "ProductKind");
		ElsIf TypeOf(Object.Owner) = Type("CatalogRef.ItemKinds") Then
			Object.ProductKind = Object.Owner;
		EndIf;
	Else
		Object.ProductKind = Catalogs.ItemKinds.EmptyRef();
	EndIf;
	
	ProductKindAttributes = Catalogs.ItemsCharacteristics.NewStructureOfNewTypeOfProduct(Object.ProductKind);
	
	RecalculateNeedForFormationOfNames(ThisObject);
	
EndProcedure

// Returns:
// 	See Catalogs.ItemsCharacteristics.NewStructureOfNewTypeOfProduct
// 
&AtServer
Function ProductKindAttributes()
	
	Return ProductKindAttributes;
	
EndFunction

&AtClientAtServerNoContext
Procedure RecalculateNeedForFormationOfNames(Form)
	
	Form.GenerateWorkName =
		Form.ProductKindAttributes.ProhibitEditingWorkingTitleOfItemVariants
		Or (Not ValueIsFilled(Form.Object.Description)
		And ValueIsFilled(Form.ProductKindAttributes.WorkingNameTemplateCharacteristics));
		
	Form.GeneratePrintName =
		Form.ProductKindAttributes.DisableNameChangeToPrintItemVariant
		Or (Not ValueIsFilled(Form.Object.DescriptionFull)
		And ValueIsFilled(Form.ProductKindAttributes.NameTemplateForPrintingCharacteristics));

EndProcedure

&AtClient
Function HyperlinkClickParameters(TagName, Hyperlink)
	
	HyperlinkClickParameters = New Structure("TagName,Hyperlink,FormName,URL,GroupName,FormParameters,FormWindowOpeningMode");
	HyperlinkClickParameters.TagName = TagName;
	HyperlinkClickParameters.Hyperlink = Hyperlink;
	
	If TagName = "HyperlinkGoSetComposition" Then
		
		FormParameters = New Structure("Products", Object.Ref);
		
		If ValueIsFilled(ItemKitConfiguration) Then
			FormParameters = New Structure("Key", ItemKitConfiguration);
			
			HyperlinkClickParameters.FormName       = "Catalog.ProductKitConfigurations.Form.SetComposition";
			HyperlinkClickParameters.FormParameters = FormParameters;
		Else
			Filter = New Structure;
			Filter.Insert("Owner", Object.Owner);
			Filter.Insert("Characteristic", Object.Ref);
			FormParameters = New Structure("Filter", Filter);
			
			HyperlinkClickParameters.FormName       =  "Catalog.ProductKitConfigurations.Form.SetComposition";
			HyperlinkClickParameters.FormParameters = FormParameters;
		EndIf;
		
	EndIf;
	
	If HyperlinkClickParameters.FormWindowOpeningMode = Undefined Then
		HyperlinkClickParameters.FormWindowOpeningMode = FormWindowOpeningMode.Independent;
	EndIf;	
	
	Return HyperlinkClickParameters;
EndFunction

&AtClient
Procedure HyperlinkGoToFormParametersAndQuestion(TagName, Hyperlink)
	
	ClearMessages();
	HyperlinkClickParameters = HyperlinkClickParameters(TagName, Hyperlink);
	
	If Not ValueIsFilled(Object.Ref)
		Or Modified Then
		
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể chuyển đến thông tin bổ sung sau khi ghi lại phần tử.
		|Ghi lại phần tử?';
		|ru = 'Данные еще не записаны.
		|Переход к дополнительной информации возможен только после записи элемента.
		|Записать элемент?';
		|en = 'The data is not saved yet.
		|You can go to additional information only after the item is saved.
		|Save it?'; fa = 'The data is not saved yet.
		|You can go to additional information only after the item is saved.
		|Save it?';
		|it = 'I dati non sono ancora stati registrati.
		|Il passaggio all''informazione aggiuntiva è possibile solo dopo la registrazione dell''elemento.
		|Registrare l''elemento?';
		|pl = 'Dane nie zostały jeszcze zapisane.
		|Przejście do informacji dodatkowej jest możliwe tylko po zapisaniu elementu.
		|Zapisać element?';
		|tr = 'Veriler henüz kaydedilmedi.
		|Ek bilgilere geçiş sadece öğenin kaydından sonra mümkündür.
		|Öğe kaydedilsin mi?'");
		
		ShowQueryBox(New CallbackDescription("HyperlinkGoQuestionCompletion", ThisObject, HyperlinkClickParameters), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	GoHyperlink(HyperlinkClickParameters);
	
EndProcedure

&AtClient
Procedure HyperlinkGoQuestionCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Try
		ItemRecorded = Write();
	Except
		Return;
	EndTry;
	
	If Not ItemRecorded Then
		Return;
	EndIf;
	
	HyperlinkClickParameters = HyperlinkClickParameters(AdditionalParameters.TagName,
																		AdditionalParameters.Hyperlink);
	GoHyperlink(HyperlinkClickParameters);
	
EndProcedure

&AtClient
Procedure GoHyperlink(HyperlinkClickParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Catalog.ItemsCharacteristics.Form.ItemForm.Command." + HyperlinkClickParameters.TagName,
		,
		True);
	
	If HyperlinkClickParameters.FormName <> Undefined Then		
		OpenForm(HyperlinkClickParameters.FormName,
			HyperlinkClickParameters.FormParameters, , ThisForm.UUID, , , ,
			HyperlinkClickParameters.FormWindowOpeningMode);
	ElsIf HyperlinkClickParameters.URL <> Undefined Then
		FileSystemClient.OpenURL(HyperlinkClickParameters.URL);
	Else
		ExceptionText = NStr("vi = 'Không có hành động siêu liên kết được xác định.';
							|ru = 'Не определено действие по гиперссылке.';
							|en = 'Hyperlink action is not identified.'; fa = 'Hyperlink action is not identified.';
							|it = 'Azione ipertestuale non definita.';
							|pl = 'Nie określono działania hiperłącza.';
							|tr = 'Köprü eylemi tanımlanmadı.'");
		Raise ExceptionText;
	EndIf;
	
EndProcedure

// Returns:
// 	FixedStructure:
// 		* AddressOfParameterTable - String
// 		* ProductKind - CatalogRef.ItemKinds
// 		* Owner - CatalogRef.ItemKinds, CatalogRef.Products - 
// 		* Description - String
// 		* DescriptionFull - String
//
&AtServer
Function CreationParameters()
	
	Return CreationParameters;

EndFunction

#EndRegion

#EndRegion

#Region Localization

&AtServer
Procedure OnCreateAtServerLocalization()
	

	Return;
	
EndProcedure

#EndRegion