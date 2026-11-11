#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If FormOpeningFailure Then
		Cancel = True;
		Return;
	EndIf;

	FormTextColor = StyleColors.FormTextColor;
	
	SetConditionalAppearance();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		GeneralOnly = False;
		
		If Parameters.Property("CopyingValue") Then
		
			FillInListOfPropertiesAndDetailsOfTable(
				TableOfAdditionalAttributesOfProducts,
				Parameters.CopyingValue.PropertiesSet,
				SetOfCommonProperties,
				"Attributes",
				GeneralOnly);
			
			FillInListOfPropertiesAndDetailsOfTable(
				TableOfAdditionalCharacteristicsAttributes,
				SetOfCommonPropertiesCharacteristics,
				"Attributes",
				GeneralOnly);
			
			FillInListOfPropertiesAndDetailsOfTable(
				TableOfAdditionalSeriesAttributes,
				Parameters.CopyingValue.BatchPropertySet,
				SetOfCommonSeriesProperties,
				"Attributes",
				GeneralOnly);
			
			FillInListOfPropertiesAndDetailsOfTable(
				TableOfAdditionalInformationOfTheItem,
				Parameters.CopyingValue.PropertiesSet,
				SetOfCommonProperties,
				"InformationRecords",
				GeneralOnly);
			
			FillInListOfPropertiesAndDetailsOfTable(
				TableOfAdditionalCharacteristicsInformation,
				Parameters.CopyingValue.CharacteristicsPropertySet,
				SetOfCommonPropertiesCharacteristics,
				"InformationRecords",
				GeneralOnly);
			
			FillInListOfPropertiesAndDetailsOfTable(
				TableOfAdditionalInformationOfTheSeries,
				Parameters.CopyingValue.BatchPropertySet,
				SetOfCommonSeriesProperties,
				"InformationRecords",
				GeneralOnly);
			
			// Fill in additional details for control.
			CollectionOfPropsForControl = Catalogs.ItemKinds.CollectionOfPropsForControl(Object, "Products");
			TypesNotUsedForFillingAndSelectionControl = Catalogs.Products.TypesNotUsedForFillingAndSelectionControl();
			
			AdditionalAttributes = Common.ObjectAttributeValue(Parameters.CopyingValue.PropertiesSet, "AdditionalAttributes"); // QueryResult
			If AdditionalAttributes <> Undefined Then
				SelectionAdditionalDetails = AdditionalAttributes.Select(); // QueryResultSelection
				While SelectionAdditionalDetails.Next() Do
					
					PropertyToAdd = SelectionAdditionalDetails.Property;
					AttributesPropertyBeingAdded = Common.ObjectAttributesValues(PropertyToAdd, 
						"ValueType, RequiredToFill");
					ValueType = AttributesPropertyBeingAdded.ValueType;
					NewRow = CollectionOfPropsForControl.Add();
					
					NewRow.AttributeName = PropertyToAdd;
					NewRow.AttributeRepresentation = String(PropertyToAdd);
					NewRow.Property = PropertyToAdd;
					NewRow.IsAddlAttribute = True;
					NewRow.RequiredToFill = AttributesPropertyBeingAdded.RequiredToFill;
					NewRow.DisplayWhenCreated = AttributesPropertyBeingAdded.RequiredToFill;
					
					AvailabilityConditions = AvailabilityConditions();
					AvailabilityConditions.ThisIsUnusedTypeForControl = (TypesNotUsedForFillingAndSelectionControl.Find(ValueType) <> Undefined);
					AvailabilityConditions.TypeOfPropsBoolean = (ValueType =  New TypeDescription("Boolean"));
					AvailabilityConditions.RequiredToFill = AttributesPropertyBeingAdded.RequiredToFill;
					
					SetAccessibilitySettingsOfPropsFieldsForControl(NewRow, AvailabilityConditions);
					
				EndDo;
			EndIf;
			
		EndIf;
	Else
		
		ConfigureFormVisibility = "CollapseAll";
		CollapseExpandAllGroups(ThisObject);
		
	EndIf;
	
	RelationshipsOfPolicySelectionParametersInHeader = New Array;
	AssociationsOfWHPolicySelectionParameters = New Array;
	
	For Each PolicySelectionParameter In ProductsClientServer.SelectionParametersForSeriesAccountingPolicies() Do
		
		If PolicySelectionParameter.Key = "ProductKind" Then
			RelationshipsOfPolicySelectionParametersInHeader.Add(New ChoiceParameterLink("ProductKind",
				"Object.Ref", LinkedValueChangeMode.DontChange));
		ElsIf PolicySelectionParameter.Key = "Warehouse" Then
			AssociationsOfWHPolicySelectionParameters.Add(New ChoiceParameterLink("Warehouse",
				"Items.BatchAccountingPolicies.CurrentData.Warehouse", LinkedValueChangeMode.Clear));
		Else
			RelationshipsOfPolicySelectionParametersInHeader.Add(New ChoiceParameterLink(PolicySelectionParameter.Key,
				"Object." + PolicySelectionParameter.Key, LinkedValueChangeMode.DontChange));
			AssociationsOfWHPolicySelectionParameters.Add(New ChoiceParameterLink(PolicySelectionParameter.Key,
				"Object." + PolicySelectionParameter.Key, LinkedValueChangeMode.DontChange));
		EndIf;
		
	EndDo;
	
	WarehouseSelectionParameter           = CommonClientServer.ValueInArray(New ChoiceParameter("Warehouse", Undefined));
	ProductTypeSelectionParameter = CommonClientServer.ValueInArray(New ChoiceParameter("ProductKind", Undefined));
	
	Items.BatchAccountingPolicy.ChoiceParameterLinks  = New FixedArray(RelationshipsOfPolicySelectionParametersInHeader);
	Items.BatchAccountingPolicy.ChoiceParameters        = New FixedArray(WarehouseSelectionParameter);
	
	Items.BatchAccountingPolicy2.ChoiceParameterLinks = New FixedArray(RelationshipsOfPolicySelectionParametersInHeader);
	Items.BatchAccountingPolicy2.ChoiceParameters       = New FixedArray(WarehouseSelectionParameter);
	
	Items.BatchAccountingPoliciesBatchAccountingPolicy.ChoiceParameterLinks = New FixedArray(AssociationsOfWHPolicySelectionParameters);
	Items.BatchAccountingPoliciesBatchAccountingPolicy.ChoiceParameters       = New FixedArray(ProductTypeSelectionParameter);
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	AccessManagement.OnCreateAccessValueForm(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
		
	OnCreateAtServerLocalization();
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		FormOpeningFailure = True;
		Return;
	EndIf;
	
	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If UseIndividualName = "UseIndividualName" Then
		Object.UseCustomNameForPrinting = True;
	Else
		Object.UseCustomNameForPrinting = False;
	EndIf;

	If UsePriceManagementSystem25 
		And Not ValueIsFilled(Object.SettingsOfPriceKeyByItemVariant)
		And Not Items.SettingsOfPriceKeyByItemVariant.Enabled Then
		Object.SettingsOfPriceKeyByItemVariant = PredefinedValue("Enum.FilterOptionForPriceKey.DontUse");
	EndIf;
	
	ClearMessages();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ItemKinds",,ThisObject);
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Cancel Then
		Return;
	EndIf;
	
	RecordAdditionalSetDetails(Cancel, CurrentObject, "AdditionalAttribute5", "Products");
	RecordAdditionalSetDetails(Cancel, CurrentObject, "AdditionalAttribute5", "ItemsCharacteristics");
	RecordAdditionalSetDetails(Cancel, CurrentObject, "AdditionalAttribute5", "ItemsBatches");
	
	RecordAdditionalSetDetails(Cancel, CurrentObject, "AdditionalInfoItem1", "Products");
	RecordAdditionalSetDetails(Cancel, CurrentObject, "AdditionalInfoItem1", "ItemsCharacteristics");
	RecordAdditionalSetDetails(Cancel, CurrentObject, "AdditionalInfoItem1", "ItemsBatches");
	
	If ValueIsFilled(Object.Ref) Then
		UpdateSettingsOfAdditionalAttributesForRecordingControl(CurrentObject, "Products");
		UpdateSettingsOfAdditionalAttributesForRecordingControl(CurrentObject, "ItemsCharacteristics");
		UpdateSettingsOfAdditionalAttributesForRecordingControl(CurrentObject, "ItemsBatches");
		
		RecordPropertiesOfAdditionalBankingDetails("Products", Cancel);
		RecordPropertiesOfAdditionalBankingDetails("ItemsCharacteristics", Cancel);
		RecordPropertiesOfAdditionalBankingDetails("ItemsBatches", Cancel);
	EndIf;
	
	OnWriteAtServerLocalization(Cancel, CurrentObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SelectionOfDetailsInSelectionTable" Then
		
		// When selecting an item in the table of the details of the selection of the nomenclature or characteristics.
		Filter = New Structure("AttributeName, IsAddlAttribute, Property");
		
		If TheCurrentTypeOfItemSetOwner = "Products" Then
			
			TsOfSelectionDetails = Object.AttributesOfQuickFilterOfProducts;
			
		ElsIf TheCurrentTypeOfItemSetOwner = "ItemsCharacteristics" Then
			
			TsOfSelectionDetails = Object.AttributesOfItemVariantQuickFilter;
			
		EndIf;
		
		For Each RowParameters In Parameter.ArrayOfItemsToAdd Do
			
			FillPropertyValues(Filter, RowParameters);
			
			AttributeNotFound = (TsOfSelectionDetails.FindRows(Filter).Count() = 0);
			
			If AttributeNotFound Then
				
				NewRow = TsOfSelectionDetails.Add();
				FillPropertyValues(NewRow, RowParameters);
				
			EndIf;
			
		EndDo;
		
		Modified = True;
		
	ElsIf EventName = "SelectionOfDetailsInPriceKeyTable" Then
		
		// When selecting an item in the table of the details of the selection of the nomenclature or characteristics.
		Filter = New Structure("AttributeName, IsAddlAttribute, Property");
		
		If TheCurrentTypeOfItemSetOwner = "ItemsCharacteristics" Then
			
			TSKeyDetailsPrices = Object.ItemVariantsAttributesForPriceKey;
			
		ElsIf TheCurrentTypeOfItemSetOwner = "ItemsBatches" Then
			
			TSKeyDetailsPrices = Object.BatchAttributesForPriceKey;
			
		EndIf;
		
		For Each RowParameters In Parameter.ArrayOfItemsToAdd Do
			
			FillPropertyValues(Filter, RowParameters);
			
			FoundRows = TSKeyDetailsPrices.FindRows(Filter);
			
			If FoundRows.Count() = 0 And RowParameters.Used Then
				
				NewRow = TSKeyDetailsPrices.Add();
				FillPropertyValues(NewRow, RowParameters);
			
			ElsIf Not RowParameters.Used Then 
				
				For Each String In FoundRows Do
					
					TSKeyDetailsPrices.Delete(String);
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
		TSKeyDetailsPrices.Sort("IsAddlAttribute, AttributeRepresentation");
		
		If TheCurrentTypeOfItemSetOwner = "ItemsCharacteristics" Then
			
			CreatePricingSectionLabel("Characteristics");
			
		ElsIf TheCurrentTypeOfItemSetOwner = "ItemsBatches" Then
			
			CreatePricingSectionLabel("SetOfSeries");
			
		EndIf;
		
		UpdatePricingSections();
		
		Modified = True;
		
	ElsIf EventName = "Write_AdditionalAttributesAndInfoSets"
		Or EventName = "Write_AdditionalAttributesAndInfo" Then
		
		// When recording a set of extras .details (information), for example: 
		// opened the general add-on editing form.details (information) and recorded it.
		WhenRecordingSetOfAdditionalDetailsAndInformationOnServer();
		
	ElsIf EventName = "PropertiesAttributeDependencySet" Then
		
		If ValueIsFilled(EditablePropertySettingsKind) Then
			RecordPropertySettings(Parameter);
		EndIf;
		
	ElsIf EventName = "Write_ItemKinds" Then
		
		If Not Source.UUID = UUID Then
			Read();
		EndIf;
		
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	FillInFormDetailsUsingItemDetails();
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	TextOfMessageIsNotFilledInPolicy = NStr("vi = 'Chưa điền cột ""Chính sách kế toán sê-ri"" đối với kho bãi ""%1"" trên danh sách ""Chính sách kế toán sê-ri"".';
											|ru = 'Не заполнена колонка ""Политика учета серий"" для склада ""%1"" списка ""Политики учета серий"".';
											|en = 'Column ""Batch accounting policy"" of the ""Batch accounting policies"" is not filled in for warehouse ""%1"".'; fa = 'Column ""Batch accounting policy"" of the ""Batch accounting policies"" is not filled in for warehouse ""%1"".';
											|it = 'La colonna ""Criteri di contabilità delle serie"" per il magazzino ""%1"" dell''elenco ""Criteri di contabilità delle serie"" non è compilata.';
											|pl = 'Dla magazynu ""%1"" listy ""Polityka ewidencji serii"" nie wypełniono kolumny ""Polityky ewidencji serii""';
											|tr = '""Toplu Muhasebe Politikaları"" listesinin ""%1"" ambarı için ""Toplu Muhasebe Politikası"" sütunu doldurulmadı.'");
	MessageTextIsNotFilledIn = NStr("vi = 'Chưa điền cột ""Kho bãi"" trong danh sách ""Chính sách kế toán sê-ri"".';
									|ru = 'Не заполнена колонка ""Склад"" в списке ""Политики учета серий"".';
									|en = 'Column ""Warehouse"" in the ""Batch accounting policies"" list is not filled in.'; fa = 'Column ""Warehouse"" in the ""Batch accounting policies"" list is not filled in.';
									|it = 'La colonna ""Magazzino"" nell''elenco ""Criteri di contabilità delle serie"" non è compilata.';
									|pl = 'Nie wypełniono kolumny ""Magazyn"" na liście ""Polityka ewidencji serii"".';
									|tr = '""Toplu Muhasebe Politikaları"" listesinde ""Ambar"" sütunu doldurulmadı.'");
	MessageTextNameTemplate = NStr("vi = 'Trong khuôn mẫu đối với %1 không thể sử dụng trường ""%2"", cần sửa khuôn in.';
									|ru = 'В шаблоне для %1 нельзя использовать поле ""%2"", необходимо исправить шаблон.';
									|en = 'Field ""%2"" cannot be used in a template for %1. Please correct the template.'; fa = 'Field ""%2"" cannot be used in a template for %1. Please correct the template.';
									|it = 'Nel modello per %1 non è possibile usare il campo ""%2"", è necessario modificare il modello.';
									|pl = 'W szablonie dla %1 nie można używać pola ""%2"", należy poprawić szablon.';
									|tr = 'Şablonda %1 için ""%2"" alanı kullanılamaz, şablonun düzeltilmesi gerekmektedir.'");
	
	FillingErrors = Undefined;
	For RowIndex = 0 To Object.BatchAccountingPolicies.Count() - 1 Do
		
		String = Object.BatchAccountingPolicies[RowIndex];
		
		If Not String.CorrespondsToThePolicyByDefault
			And Not ValueIsFilled(String.Warehouse) Then
			MessageText = MessageTextIsNotFilledIn;
			CommonClientServer.AddUserError(FillingErrors,
				"Object.BatchAccountingPolicies[%1].Warehouse",
				MessageText,
				,
				,
				,
				RowIndex);
		ElsIf Not String.CorrespondsToThePolicyByDefault
			And Not ValueIsFilled(String.BatchAccountingPolicy) Then
			MessageText = StrTemplate(TextOfMessageIsNotFilledInPolicy, String.Warehouse);
			CommonClientServer.AddUserError(FillingErrors,
				"Object.BatchAccountingPolicies[%1].BatchAccountingPolicy",
				MessageText,
				,
				,
				,
				RowIndex);
		EndIf;
		
	EndDo;

	DescriptionToCheck = "Description";
	If StrFind(Object.WorkingNameTemplateOfProductItem, "["+DescriptionToCheck+"]") > 0
		And Object.ProhibitEditingWorkingTitleOfItems Then
		MessageText = StrTemplate(MessageTextNameTemplate, 
			"worker descriptions ofproductitem", DescriptionToCheck);
		CommonClientServer.AddUserError(FillingErrors,
			"Object.WorkingNameTemplateOfProductItem",
			MessageText);
	EndIf;
	
	DescriptionToCheck = "DescriptionFull";
	If StrFind(Object.NameTemplateForPrintingOfProductItem, "["+DescriptionToCheck+"]") > 0
		And Object.RestrictNameChangeToPrintItems Then
		MessageText = StrTemplate(MessageTextNameTemplate, 
			"descriptions for seals ofproductitem", DescriptionToCheck);
		CommonClientServer.AddUserError(FillingErrors,
			"Object.NameTemplateForPrintingOfProductItem",
			MessageText);
	EndIf;
	
	DescriptionToCheck = "Description";
	If StrFind(Object.WorkingNameTemplateCharacteristics, "["+DescriptionToCheck+"]") > 0
		And Object.ProhibitEditingWorkingTitleOfItemVariants Then
		MessageText = StrTemplate(MessageTextNameTemplate, 
			"worker descriptions characteristics", DescriptionToCheck);
		CommonClientServer.AddUserError(FillingErrors,
			"Object.WorkingNameTemplateCharacteristics",
			MessageText);
	EndIf;
	
	DescriptionToCheck = "DescriptionFull";
	If StrFind(Object.NameTemplateForPrintingCharacteristics, "["+DescriptionToCheck+"]") > 0
		And Object.DisableNameChangeToPrintItemVariant Then
		MessageText = StrTemplate(MessageTextNameTemplate, 
			"descriptions for seals characteristics", DescriptionToCheck);
		CommonClientServer.AddUserError(FillingErrors,
			"Object.NameTemplateForPrintingCharacteristics",
			MessageText);
	EndIf;
	
	If UsePriceManagementSystem25 
		And Not ValueIsFilled(Object.SettingsOfPriceKeyByItemVariant) Then
		MessageText = NStr("vi = 'Chưa chọn phương án tùy chỉnh quản lý đơn giá theo đặc tính.';
							|ru = 'Не выбран вариант настройки разрезов ведения цен по характеристикам.';
							|en = 'An option of the setup of breakdowns to keep prices by item variants is not selected.'; fa = 'An option of the setup of breakdowns to keep prices by item variants is not selected.';
							|it = 'Non è selezionata la variante di impostazione dei tagli di mantenimento dei prezzi in base alle caratteristiche.';
							|pl = 'Nie wybrano wariantu ustawienia przekrojów cen według charakterystyk.';
							|tr = 'Varyantlara göre fiyat referans kesitlerinin ayar seçeneği seçilmedi.'");
		CommonClientServer.AddUserError(FillingErrors,
			"Object.SettingsOfPriceKeyByItemVariant",
			MessageText);
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(FillingErrors, Cancel);
	
	FillCheckProcessingAtServerLocalization(Cancel, CheckedAttributes);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CustomizeFormClient(Item)
	
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure ItemsTypeOnChange(Item) Export
	
	ItemsTypeOnChangeServer();
	
EndProcedure

&AtClient
Procedure AccountingFeatureOnChange(Item)
	
	ItemsTypeOnChangeServer();

EndProcedure

#Region ConfiguringSFGISIntegration

&AtClient
Procedure TypeOfGISMTProductsOnChange(Item)
	
	
EndProcedure

&AtClient
Procedure FGISFlagOnChange(Item)
	
	
EndProcedure

&AtClient
Procedure TypeOfFGISProductsOnChange(Item)
	
	
EndProcedure

&AtClient
Procedure TypesOfFGISProductsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	
EndProcedure

#EndRegion

&AtClient
Procedure UseCharacteristicsOnChange(Item)
	
	UseCharacteristicsWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure UseVariantsOnChange(Item)
	
	If Object.UseVariants = PredefinedValue("Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind") Then
		SelectViewOwner("Features");
	Else
		Object.ItemVariantsOwner = Undefined;
		SetPricingDetails();
	EndIf;	
	
EndProcedure

&AtClient
Procedure ConfigureProductCategoriesOnChange(Item)
	Object.ProductCategoriesCommonWithAnotherKindOfItems = 
		ConfigureProductCategories = "CommonWithOtherItemKind";
	
	If Object.ProductCategoriesCommonWithAnotherKindOfItems Then
		SelectViewOwner("OfProductCategories");
	Else
		Object.ProductCategoryOwner = Undefined;
		CustomizeForm();
	EndIf;	
EndProcedure

&AtClient
Procedure KeepAccountingByBatchOnChange(Item)
	
	UseSeriesWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOnChange(Item)
	UnitOfMeasureOnChangeServer();
EndProcedure

&AtClient
Procedure UsePackagesOnChange(Item)
	
	If Not Object.UsePackages Then
		Object.PackagingGroup = Undefined;
		PackagingUsage = "";
	Else
		Object.SuppliedInReusablePackage  = False;
		Object.ReusablePackageItems   = Undefined;
		Object.ReusablePackageVariant = Undefined;
		PackagingUsage = "SharedSet";
	EndIf;
	
	UsePackagesWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure PackagingGroupOnChange(Item)
	
	SetOfPackagesWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure SuppliedInReusablePackageOnChange(Item)
	
	If Not Object.SuppliedInReusablePackage Then
		Object.ReusablePackageItems   = Undefined;
		Object.ReusablePackageVariant = Undefined;
	EndIf;
	
	CustomizeForm();
EndProcedure

&AtServer
Procedure WhenRecordingSetOfAdditionalDetailsAndInformationOnServer()
	
	If Not Modified Then
		Read();
	Else
		If TheCurrentTypeOfItemSetOwner = "Products"
			Or TheCurrentTypeOfItemSetOwner = "ItemsCharacteristics"
			Or TheCurrentTypeOfItemSetOwner = "ItemsBatches" Then
			
			// If the composition of the set of general additional information
			// is being edited, then you do not need to change the composition of the details for control and selection.
			If CurrentItemType <> "AdditionalInfoItem1" Then
				Catalogs.ItemKinds.FillInAdditionalDetailsForControlAndSelection(Object, TheCurrentTypeOfItemSetOwner);
			EndIf;
			
		EndIf;
		
		FillInListsOfAdditionalInformationDetails();
	EndIf;
	
EndProcedure

&AtClient
Procedure OptionOfSeriesSettingsOnChange(Item)
	Object.BatchSettingsAreTakenFromOtherItemsKind 
		= OptionOfSeriesSettings = "AreUsedAlsoAsInOtherKindOfProductList";
	If Object.BatchSettingsAreTakenFromOtherItemsKind Then
		SelectViewOwner("Series_");
		Object.BatchAccountingPolicies.Clear();
	Else
		Object.BatchOwner = Undefined;
		SetPricingDetails();
	EndIf;
EndProcedure

&AtClient
Procedure ItemVariantsOwnerURLProcessing(Item, Var_URL, StandardProcessing)
	ProcessingNavigationLinkOfLabelByType(Var_URL, "Features", StandardProcessing);
EndProcedure

&AtClient
Procedure BatchOwnerURLProcessing(Item, Var_URL, StandardProcessing)
	ProcessingNavigationLinkOfLabelByType(Var_URL, "Series_", StandardProcessing);
EndProcedure

&AtClient
Procedure ProductCategoryOwnerURLProcessing(Item, Var_URL, StandardProcessing)
	ProcessingNavigationLinkOfLabelByType(Var_URL, "OfProductCategories", StandardProcessing);
EndProcedure

&AtClient
Procedure TheUseOfPackagesWhenChanging(Item)
	If PackagingUsage = "Individual_Set" Then
		Object.PackagingGroup = PredefinedValue("Catalog.PackagingGroups.SpecialForItem");
	Else
		Object.PackagingGroup = PredefinedValue("Catalog.PackagingGroups.EmptyRef");
	EndIf;
	
	CustomizeForm();
EndProcedure

&AtClient
Procedure BatchAccountingPolicyOnChange(Item)
	
	If Not ThereAreIndividualSettingsOfSeriesAccountingPolicy Then
		SetDefaultSeriesAccountingPolicy();
	EndIf;
	
	ActionWhenChangingSeriesAccountingPolicies();
	
EndProcedure

&AtClient
Procedure ThereAreIndividualSettingsOfSeriesAccountingPolicyOnChange(Item)
	
	If ThereAreIndividualSettingsOfSeriesAccountingPolicy
		And Not ValueIsFilled(Object.BatchAccountingPolicy) Then
		Object.BatchAccountingPolicy = PredefinedValue("Catalog.BatchAccountingPolicies.SeriesAreNotUsed");
	EndIf;
	
	If Object.BatchAccountingPolicies.Count() > 0
		And Not ThereAreIndividualSettingsOfSeriesAccountingPolicy Then
		
		InTSIndicateWarehousesAndDivisions = UseSeveralWarehouses And UseProduction;
	
		If InTSIndicateWarehousesAndDivisions Then 
			QueryText = NStr("vi = 'Đối với tất cả các kho và bộ phận sản xuất sẽ thiết lập một chính sách kế toán sê-ri chung.';
							|ru = 'Для всех складов и производственных подразделений будет установлена общая политика учета серий.';
							|en = 'Common batch accounting policy will be set for all warehouses and production business units.'; fa = 'Common batch accounting policy will be set for all warehouses and production business units.';
							|it = 'Per tutti i magazzini e i reparti produttivi verrà stabilito un criterio comune per la contabilità delle serie.';
							|pl = 'Dla wszystkich magazynów i działów produkcyjnych zostanie ustawiona wspólna polityka ewidencji serii.';
							|tr = 'Tüm ambarlar ve üretim departmanları için genel bir toplu muhasebe politikası oluşturulacaktır.'");
		ElsIf UseSeveralWarehouses Then
			QueryText = NStr("vi = 'Đối với tất cả các kho sẽ thiết lập một chính sách kế toán sê-ri chung.';
							|ru = 'Для всех складов будет установлена общая политика учета серий.';
							|en = 'Common batch accounting policy will be set for all warehouses.'; fa = 'Common batch accounting policy will be set for all warehouses.';
							|it = 'Per tutti i magazzini verrà stabilito un criterio comune per la contabilità delle serie.';
							|pl = 'Dla wszystkich magazynów zostanie ustawiona wspólna polityka ewidencji serii.';
							|tr = 'Tüm ambarlar için genel bir toplu muhasebe politikası oluşturulacaktır.'");
		Else
			QueryText = NStr("vi = 'Đối với tất cả các bộ phận sản xuất sẽ thiết lập một chính sách kế toán sê-ri chung.';
							|ru = 'Для всех производственных подразделений будет установлена общая политика учета серий.';
							|en = 'Common batch accounting policy will be set for all production business units.'; fa = 'Common batch accounting policy will be set for all production business units.';
							|it = 'Per tutti i reparti produttivi verrà stabilito un criterio comune per la contabilità delle serie.';
							|pl = 'Dla działów produkcyjnych zostanie ustawiona wspólna polityka ewidencji serii.';
							|tr = 'Tüm üretim departmanları için genel bir toplu muhasebe politikası oluşturulacaktır.'");
		EndIf;
		
		ShowQueryBox(
			New CallbackDescription("ThereAreIndividualSettingsOfSeriesAccountingPolicyOnChangeCompletion", ThisObject),
			QueryText,
			QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	CustomizeForm();
	UpdateAlertOnWarehouseClient();
	
EndProcedure

&AtClient
Procedure BatchUsageSettingsOnChange(Item)
	
	If Object.BatchAccountingPolicies.Count() > 0 Then
		
		ParametersAffectingSelectionAndIndicationOfSteelSeries = ProductsClientServer.SelectionParametersForSeriesAccountingPolicies();
		FillPropertyValues(ParametersAffectingSelectionAndIndicationOfSteelSeries, Object);
		
		If Not TMCommonUseClientServer.StructuresAreEqual(ParametersAffectingTheSelectionOfPoliciesSpecifyingTheSeriesBeforeChange,
				ParametersAffectingSelectionAndIndicationOfSteelSeries) Then
			QueryText = NStr("vi = 'Đã thay đổi các tham số ảnh hưởng đến khả năng chọn chính sách chỉ ra sê-ri.
										|Các chính sách không đáp ứng tham số mới sẽ bị xóa. Tiếp tục?';
										|ru = 'Изменились параметры, влияющие на возможность выбора политик указания серий.
										|Политики, которые не удовлетворяют новым параметрам будут удалены. Продолжить?';
										|en = 'The parameters affecting the choice of batch specification policies have changed.
										|Policies that do not satisfy the new parameters will be deleted. Continue?'; fa = 'The parameters affecting the choice of batch specification policies have changed.
										|Policies that do not satisfy the new parameters will be deleted. Continue?';
										|it = 'I parametri che interferiscono con la possibilità di scelta delle politiche di indicazione della serie.
										| Le politiche che non soddisferanno i nuovi parametri saranno eliminate. Continuare?';
										|pl = 'Zmieniły się parametry, które wpływają na możliwość wyboru zasad wskazania serii.
										|Polityki, które nie spełniają wymagań nowych parametrów zostaną usunięte. Kontynuować?';
										|tr = 'Parti belirtme politikalarını seçme olanağını etkileyen parametreler değişti.
										|Yeni parametreleri karşılamayan politikalar silinecektir. Devam edilsin mi?'");
			ShowQueryBox(New CallbackDescription("BatchUsageSettingsOnChangeCompletion", ThisObject),
							QueryText,
							QuestionDialogMode.YesNo,
							,
							DialogReturnCode.Yes);
        	Return;
		EndIf;
		
	EndIf;
	
	ConfiguringUseOfSeriesWhenChangingFragment(True);
EndProcedure

&AtClient
Procedure BatchUsageSettingsOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
	ConfiguringUseOfSeriesWhenChangingFragment(Response = DialogReturnCode.Yes);

EndProcedure

&AtServer
Procedure ConfiguringUseOfSeriesWhenChangingFragment(ApplyTheChanges)
	
	If Not ApplyTheChanges Then
		FillPropertyValues(Object, ParametersAffectingTheSelectionOfPoliciesSpecifyingTheSeriesBeforeChange);
	EndIf;
	
	ObjectToFillIn = Object;
	ProductsLocalization.AddFormObject(ThisObject, ObjectToFillIn);
	Catalogs.ItemKinds.WorkOutLogicOfConnectionDetails(ObjectToFillIn);
	ProductsLocalization.RestoreFormObject(ThisObject, ObjectToFillIn);
	
	FillInFormDetailsUsingItemDetails();
	CustomizeForm();

EndProcedure

&AtClient
Procedure FEACNCodeOnChange(Item)
	
	If ValueIsFilled(Object.FEACNCode) Then
		FEACNCodeOnChangeServer();
	Else
		ConfigureClassifierFieldHint(Items.FEACNCode.Name, Object.FEACNCode);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureFormVisibilityOnChange(Item)
	
	CollapseExpandAllGroups(ThisObject);
	
EndProcedure

&AtClient
Procedure BusinessActivityClassifierCodeOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure BusinessActivityClassifierCode2OnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure BusinessActivityClassifierCode2StartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure BusinessActivityClassifierCode2AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure RNCPCodeOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure RNCTEAPS2CodeOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ControlQualityOfReceivedGoodsOnChange(Item)
	
	CustomizeForm();
	If Not Object.ControlQualityOfReceivedGoods Then
		Object.TermOfQualityControl = 0;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBatchAccountingPolicies

&AtClient
Procedure BatchAccountingPoliciesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.BatchAccountingPolicies.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "BatchAccountingPoliciesWarehouse" 
		And (Items.BatchAccountingPolicies.ReadOnly
			Or ReadOnly) Then
			
		StandardProcessing = False;
		ShowValue(, CurrentData.Warehouse);
		
	ElsIf Field.Name = "BatchAccountingPoliciesBatchAccountingPolicy" 
		And (Items.BatchAccountingPolicies.ReadOnly
			Or ReadOnly) Then
			
		StandardProcessing = False;
		ShowValue(, CurrentData.BatchAccountingPolicy);
	EndIf; 
	
EndProcedure

&AtClient
Procedure BatchAccountingPoliciesOnActivateRow(Item)
	If Items.BatchAccountingPolicies.CurrentData <> Undefined
		And ValueIsFilled(Items.BatchAccountingPolicies.CurrentData.Warehouse) Then 
		AttachIdleHandler("UpdateAlertOnWarehouseClient", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure BatchAccountingPoliciesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BatchAccountingPoliciesWarehouseOnChange(Item)
	
	CurrentData = Items.BatchAccountingPolicies.CurrentData;
	
	If ValueIsFilled(CurrentData.Warehouse) Then
		CurrentData.ThisIsAWarehousePolicy = Not ValueIsFilled(CurrentData.Warehouse)
											 Or TypeOf(CurrentData.Warehouse) = Type("CatalogRef.Warehouses");
		
		AfterAddingNewUnitWarehouseToBatchAccountingPolicies(CurrentData.Warehouse, CurrentData.BatchAccountingPolicy);
	EndIf;
	UpdateAlertOnWarehouseClient();
	
EndProcedure

&AtClient
Procedure BatchAccountingPoliciesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	SeriesAccountingPoliciesBeforeDeletionOnServer();
	
EndProcedure

&AtServer
Procedure SeriesAccountingPoliciesBeforeDeletionOnServer()
	
	IdsOfSelectedRows = Items.BatchAccountingPolicies.SelectedRows;
	
	If IdsOfSelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	For Each LineID In IdsOfSelectedRows Do
		String = Object.BatchAccountingPolicies.FindByID(LineID);
		If ValueIsFilled(String.Warehouse) Then
			FilterStructure1 = New Structure();
			FilterStructure1.Insert("Warehouse", String.Warehouse);
			
			FoundRows = Object.BatchAccountingPolicies.FindRows(FilterStructure1);
			
			If FoundRows.Count() > 1 Then
				// Delete a line if there are several lines for the current warehouse
				Object.BatchAccountingPolicies.Delete(String);
			Else
				// Hide a line if it is the only line in the warehouse
				String.BatchAccountingPolicy = Object.BatchAccountingPolicy;
			EndIf;
		Else
			Object.BatchAccountingPolicies.Delete(String);
		EndIf;
	EndDo;
	
	ActionWhenChangingSeriesAccountingPolicies();
	
EndProcedure

&AtClient
Procedure BatchAccountingPoliciesBatchAccountingPolicyOnChange(Item)
	
	CurrentData = Items.BatchAccountingPolicies.CurrentData;
	
	If ValueIsFilled(CurrentData.Warehouse) Then
		AfterAddingNewUnitWarehouseToBatchAccountingPolicies(CurrentData.Warehouse, CurrentData.BatchAccountingPolicy)
	EndIf;
	
EndProcedure

&AtClient
Procedure BatchAccountingPoliciesOnEditEnd(Item, NewRow, CancelEdit)
	DeleteEmptyRowsOfSeriesAccountingPolicies();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableOfAdditionalAttributesOfProducts

&AtClient
Procedure TableOfAdditionalAttributesOfProductsOnChange(Item)
	
	SetAvailabilityOfEditingCommandsAndInformationDetails("AdditionalAttribute5", "Products");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalAttributesOfProductsOnActivateRow(Item)
	
	SetAvailabilityOfEditingCommandsAndInformationDetails("AdditionalAttribute5", "Products");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalAttributesOfProductsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "Products");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalAttributesOfProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	WhenSelectingRowInTableOfAdditionalDetails("AdditionalAttribute5", "Products", Item.CurrentData);
	
EndProcedure

&AtClient
Procedure TableOfAdditionalAttributesOfProductsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	ProcessingSelectionOfAdditionalDetailsInformation(ValueSelected, "AdditionalAttribute5", "Products");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalAttributesOfProductsDragStart(Item, DragParameters, Perform)
	
	SetBanOnDraggingElementsOfAdditionalInformationDetails(Perform, "AdditionalAttribute5", "Products");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableOfAdditionalCharacteristicsAttributes

&AtClient
Procedure TableOfAdditionalCharacteristicsAttributesOnChange(Item)
	
	SetAvailabilityOfEditingCommandsAndInformationDetails("AdditionalAttribute5", "ItemsCharacteristics");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalCharacteristicsAttributesOnActivateRow(Item)
	
	SetAvailabilityOfEditingCommandsAndInformationDetails("AdditionalAttribute5", "ItemsCharacteristics");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalCharacteristicsAttributesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "ItemsCharacteristics");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalCharacteristicsAttributesSelection(Item, RowSelected, Field, StandardProcessing)
	
	WhenSelectingRowInTableOfAdditionalDetails("AdditionalAttribute5", "ItemsCharacteristics", Item.CurrentData);
	
EndProcedure

&AtClient
Procedure TableOfAdditionalCharacteristicsAttributesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	ProcessingSelectionOfAdditionalDetailsInformation(ValueSelected, "AdditionalAttribute5", "ItemsCharacteristics");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalCharacteristicsAttributesDragStart(Item, DragParameters, Perform)
	
	SetBanOnDraggingElementsOfAdditionalInformationDetails(Perform, "AdditionalAttribute5", "ItemsCharacteristics");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableOfAdditionalSeriesAttributes

&AtClient
Procedure TableOfAdditionalSeriesAttributesOnChange(Item)
	
	SetAvailabilityOfEditingCommandsAndInformationDetails("AdditionalAttribute5", "ItemsBatches");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalSeriesAttributesOnActivateRow(Item)
	
	SetAvailabilityOfEditingCommandsAndInformationDetails("AdditionalAttribute5", "ItemsBatches");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalSeriesAttributesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "ItemsBatches");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalSeriesAttributesSelection(Item, RowSelected, Field, StandardProcessing)
	
	WhenSelectingRowInTableOfAdditionalDetails("AdditionalAttribute5", "ItemsBatches", Item.CurrentData);
	
EndProcedure

&AtClient
Procedure TableOfAdditionalSeriesAttributesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	ProcessingSelectionOfAdditionalDetailsInformation(ValueSelected, "AdditionalAttribute5", "ItemsBatches");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalSeriesAttributesDragStart(Item, DragParameters, Perform)
	
	SetBanOnDraggingElementsOfAdditionalInformationDetails(Perform, "AdditionalAttribute5", "ItemsBatches");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableOfAdditionalInformationOfTheItem

&AtClient
Procedure TableOfAdditionalInformationOfTheItemOnChange(Item)
	
	SetAvailabilityOfEditingCommandsAndInformationDetails("AdditionalInfoItem1", "Products");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalInformationOfTheItemOnActivateRow(Item)
	
	SetAvailabilityOfEditingCommandsAndInformationDetails("AdditionalInfoItem1", "Products");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalInformationOfTheItemBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	AddAdditionalDetailsInformation("AdditionalInfoItem1", "Products");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalInformationOfTheItemSelection(Item, RowSelected, Field, StandardProcessing)
	
	WhenSelectingRowInTableOfAdditionalDetails("AdditionalInfoItem1", "Products", Item.CurrentData);
	
EndProcedure

&AtClient
Procedure TableOfAdditionalInformationOfTheItemChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	ProcessingSelectionOfAdditionalDetailsInformation(ValueSelected, "AdditionalInfoItem1", "Products");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalInformationOfTheItemDragStart(Item, DragParameters, Perform)
	
	SetBanOnDraggingElementsOfAdditionalInformationDetails(Perform, "AdditionalInfoItem1", "Products");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableOfAdditionalCharacteristicsInformation

&AtClient
Procedure TableOfAdditionalCharacteristicsInformationOnChange(Item)
	
	SetAvailabilityOfEditingCommandsAndInformationDetails("AdditionalInfoItem1", "ItemsCharacteristics");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalCharacteristicsInformationOnActivateRow(Item)
	
	SetAvailabilityOfEditingCommandsAndInformationDetails("AdditionalInfoItem1", "ItemsCharacteristics");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalCharacteristicsInformationBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	AddAdditionalDetailsInformation("AdditionalInfoItem1", "ItemsCharacteristics");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalCharacteristicsInformationSelection(Item, RowSelected, Field, StandardProcessing)
	
	WhenSelectingRowInTableOfAdditionalDetails("AdditionalInfoItem1", "ItemsCharacteristics", Item.CurrentData);
	
EndProcedure

&AtClient
Procedure TableOfAdditionalCharacteristicsInformationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	ProcessingSelectionOfAdditionalDetailsInformation(ValueSelected, "AdditionalInfoItem1", "ItemsCharacteristics");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalCharacteristicsInformationDragStart(Item, DragParameters, Perform)
	
	SetBanOnDraggingElementsOfAdditionalInformationDetails(Perform, "AdditionalInfoItem1", "ItemsCharacteristics");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableOfAdditionalInformationOfTheSeries

&AtClient
Procedure TableOfAdditionalInformationOfTheSeriesOnChange(Item)
	
	SetAvailabilityOfEditingCommandsAndInformationDetails("AdditionalInfoItem1", "ItemsBatches");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalInformationOfTheSeriesOnActivateRow(Item)
	
	SetAvailabilityOfEditingCommandsAndInformationDetails("AdditionalInfoItem1", "ItemsBatches");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalInformationOfTheSeriesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	AddAdditionalDetailsInformation("AdditionalInfoItem1", "ItemsBatches");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalInformationOfTheSeriesSelection(Item, RowSelected, Field, StandardProcessing)
	
	WhenSelectingRowInTableOfAdditionalDetails("AdditionalInfoItem1", "ItemsBatches", Item.CurrentData);
	
EndProcedure

&AtClient
Procedure TableOfAdditionalInformationOfTheSeriesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	ProcessingSelectionOfAdditionalDetailsInformation(ValueSelected, "AdditionalInfoItem1", "ItemsBatches");
	
EndProcedure

&AtClient
Procedure TableOfAdditionalInformationOfTheSeriesDragStart(Item, DragParameters, Perform)
	
	SetBanOnDraggingElementsOfAdditionalInformationDetails(Perform, "AdditionalInfoItem1", "ItemsBatches");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttributesForProductsControl

&AtClient
Procedure AttributesForProductsControlUniquenessOnChange(Item)
	
	CurrentData = Items.AttributesForProductsControl.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.IsAddlAttribute And Modified Then
		Write();
	EndIf;
	
	TableRowID_ = CurrentData.GetID();
	
	WhenChangingFlagIsUnique("Products", TableRowID_);
	
EndProcedure

&AtServer
Procedure WhenChangingFlagIsUnique(AttributesOwner, TableRowID_)
	
	CollectionOfPropsForControl = Catalogs.ItemKinds.CollectionOfPropsForControl(Object, AttributesOwner);
	CurrentData = CollectionOfPropsForControl.FindByID(TableRowID_);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ObjectToFillIn = Object;
	ProductsLocalization.AddFormObject(ThisObject, ObjectToFillIn);
	Catalogs.ItemKinds.WhenChangingFlagIsUnique(ObjectToFillIn, AttributesOwner, CurrentData);
	
EndProcedure

&AtClient
Procedure AttributesForProductsControlRequiredToFillOnChange(Item)
	
	CurrentData = Items.AttributesForProductsControl.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.DisplayAvailabilityOnCreation = Not CurrentData.RequiredToFill;
	
	If CurrentData.RequiredToFill Then
		CurrentData.DisplayWhenCreated = True;
	EndIf;
	
	TableRowID_ = CurrentData.GetID();
	
	WhenChangingFlagItIsMandatoryToFillIn("Products", TableRowID_);
	
EndProcedure

&AtClient
Procedure AttributesForProductsControlSelection(Item, RowSelected, Field, StandardProcessing)
	
	DetailsForControlSelection("OfProductItem", Field, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttributesForItemVariantsControl

&AtClient
Procedure AttributesForItemVariantsControlUniquenessOnChange(Item)
	
	CurrentData = Items.AttributesForItemVariantsControl.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	TableRowID_ = CurrentData.GetID();
	
	WhenChangingFlagIsUnique("ItemsCharacteristics", TableRowID_);
	
EndProcedure

&AtClient
Procedure AttributesForItemVariantsControlRequiredToFillOnChange(Item)
	
	CurrentData = Items.AttributesForItemVariantsControl.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.DisplayAvailabilityOnCreation = Not CurrentData.RequiredToFill;
	
	If CurrentData.RequiredToFill Then
		CurrentData.DisplayWhenCreated = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AttributesForItemVariantsControlSelection(Item, RowSelected, Field, StandardProcessing)
	
	DetailsForControlSelection("Features", Field, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttributesForBatchControl

&AtClient
Procedure AttributesForBatchControlSelection(Item, RowSelected, Field, StandardProcessing)
	
	DetailsForControlSelection("Series_", Field, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttributesOfQuickFilterOfProducts

&AtClient
Procedure AttributesOfQuickFilterOfProductsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	If Modified Then
		NoteBeforeChangingProductQuickSelectionPanel()
	Else
		ChangeQuickSelectionPanelForProducts();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttributesOfItemVariantQuickFilter

&AtClient
Procedure AttributesOfItemVariantQuickFilterBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	If Modified
		Or Not ValueIsFilled(Object.CharacteristicsPropertySet) Then
		SaveCharacteristicsBeforeChangingQuickSelectionPanel()
	Else
		ChangeQuickFeatureSelectionPanel();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure 

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure 

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure EnableFillInVerificationForBankDetails(Command)
	
	ClearMessages();
	EnableFillInVerificationForBankingDetailsOnServer();	
	
EndProcedure

&AtClient
Procedure EditWorkNamingTemplateOfProducts(Command)
	ChangeInTemplateEditor("WorkingNameTemplateOfProductItem");
EndProcedure

&AtClient
Procedure EditWorkNamingTemplateOfTheSeries(Command)
	
	ChangeInTemplateEditor("WorkingNameTemplateSetOfSeries");
	
EndProcedure

&AtClient
Procedure EditNamingTemplateToPrintProducts(Command)
	
	ChangeInTemplateEditor("NameTemplateForPrintingOfProductItem");
	
EndProcedure

&AtClient
Procedure EditWorkNamingTemplateOfTheCharacteristic(Command)
	
	ChangeInTemplateEditor("WorkingNameTemplateCharacteristics");
	
EndProcedure

&AtClient
Procedure EditNamingTemplateToPrintCharacteristic(Command)
	
	ChangeInTemplateEditor("NameTemplateForPrintingCharacteristics");
	
EndProcedure

&AtClient
Procedure AddTheWarehouseToTheSeriesAccountingPolicies(Command)
	
	CallbackDescription = New CallbackDescription("AddTheWarehouseToTheSeriesAccountingPoliciesCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
	OpenForm("Catalog.Warehouses.ChoiceForm", FormParameters, Items.BatchAccountingPoliciesWarehouse,,,,CallbackDescription);
	
EndProcedure

&AtClient
Procedure AddTheDepartmentToTheSeriesAccountingPolicies(Command)
	
	CallbackDescription = New CallbackDescription("AddTheDepartmentToTheSeriesAccountingPoliciesCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	
	FilterParameters = New Structure("ProductionBusinessUnit", True);
	FormParameters.Insert("Filter", FilterParameters);
	
	OpenForm("Catalog.BusinessStructure.ChoiceForm", FormParameters, Items.BatchAccountingPoliciesWarehouse,,,,CallbackDescription);
	
EndProcedure

#Region CommandsForAdditionalDetailsAndInformation

&AtClient
Procedure CreateANewItemDetail(Command)
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "Products");
	
EndProcedure

&AtClient
Procedure CreateAGeneralItemDetail(Command)
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "Products", "Common");
		
EndProcedure

&AtClient
Procedure CreateItemDetailsBasedOnTheSample(Command)
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "Products", "FromMaster");
	
EndProcedure

&AtClient
Procedure CreateANewPropertyDescription(Command)
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "ItemsCharacteristics");
	
EndProcedure

&AtClient
Procedure CreateAGeneralPropertyDescription(Command)
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "ItemsCharacteristics", "Common");
		
EndProcedure

&AtClient
Procedure CreateASampleOfTheDetailsOfTheCharacteristics(Command)
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "ItemsCharacteristics", "FromMaster");
	
EndProcedure

&AtClient
Procedure CreateANewSeriesItem(Command)
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "ItemsBatches");
	
EndProcedure

&AtClient
Procedure CreateASharedSeriesItem(Command)
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "ItemsBatches", "Common");
		
EndProcedure

&AtClient
Procedure CreateASeriesOfPropsBasedOnTheSample(Command)
	
	AddAdditionalDetailsInformation("AdditionalAttribute5", "ItemsBatches", "FromMaster");
	
EndProcedure

&AtClient
Procedure CreateANewItemSummary(Command)
	
	AddAdditionalDetailsInformation("AdditionalInfoItem1", "Products");
	
EndProcedure

&AtClient
Procedure ToCreateACommonInformationItem(Command)
	
	AddAdditionalDetailsInformation("AdditionalInfoItem1", "Products", "Common");
		
EndProcedure

&AtClient
Procedure CreateAnItemSummaryBasedOnTheSample(Command)
	
	AddAdditionalDetailsInformation("AdditionalInfoItem1", "Products", "FromMaster");
	
EndProcedure

&AtClient
Procedure CreateANewFeatureSummary(Command)
	
	AddAdditionalDetailsInformation("AdditionalInfoItem1", "ItemsCharacteristics");
	
EndProcedure

&AtClient
Procedure CreateAGeneralSummaryOfACharacteristic(Command)
	
	AddAdditionalDetailsInformation("AdditionalInfoItem1", "ItemsCharacteristics", "Common");
		
EndProcedure

&AtClient
Procedure CreateASampleOfTheCharacteristicSummary(Command)
	
	AddAdditionalDetailsInformation("AdditionalInfoItem1", "ItemsCharacteristics", "FromMaster");
	
EndProcedure

&AtClient
Procedure CreateANewSeriesMix(Command)
	
	AddAdditionalDetailsInformation("AdditionalInfoItem1", "ItemsBatches");
	
EndProcedure

&AtClient
Procedure CreateASeriesSummary(Command)
	
	AddAdditionalDetailsInformation("AdditionalInfoItem1", "ItemsBatches", "Common");
		
EndProcedure

&AtClient
Procedure CreateASeriesMixBasedOnTheSample(Command)
	
	AddAdditionalDetailsInformation("AdditionalInfoItem1", "ItemsBatches", "FromMaster");
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#Region ProceduresAndFunctionsForEditingTablesAndDetails

&AtClient
Function CommandsForEditingAdditionalInformationDetails(ElementType, TypeOfElementSetOwner)
	
	TeamStructure = New Structure;
	TeamStructure.Insert("Delete");
	TeamStructure.Insert("MoveUp");
	TeamStructure.Insert("MoveDown");
	
	TeamStructure.Insert("ContextMenuDelete");
	TeamStructure.Insert("ContextMenuMoveUp");
	TeamStructure.Insert("ContextMenuMoveDown");
	
	NameOfTableForAdditionalInformationDetails = NameOfTableForAdditionalInformationDetails(ElementType, TypeOfElementSetOwner);
	
	TeamStructure.Delete                         = NameOfTableForAdditionalInformationDetails + "Delete";
	TeamStructure.MoveUp                = NameOfTableForAdditionalInformationDetails + "MoveUp";
	TeamStructure.MoveDown                 = NameOfTableForAdditionalInformationDetails + "MoveDown";
	
	TeamStructure.ContextMenuDelete          = NameOfTableForAdditionalInformationDetails + "ContextMenuDelete";
	TeamStructure.ContextMenuMoveUp = NameOfTableForAdditionalInformationDetails + "ContextMenuMoveUp";
	TeamStructure.ContextMenuMoveDown  = NameOfTableForAdditionalInformationDetails + "ContextMenuMoveDown";
	
	Return TeamStructure;
	
EndFunction

&AtClient
Function FormTableForAdditionalInformationDetails(ElementType, TypeOfElementSetOwner)
	
	If ElementType = "AdditionalAttribute5" Then
		If TypeOfElementSetOwner = "Products" Then
			Return Items.TableOfAdditionalAttributesOfProducts;
		ElsIf TypeOfElementSetOwner = "ItemsCharacteristics" Then
			Return Items.TableOfAdditionalCharacteristicsAttributes;
		ElsIf TypeOfElementSetOwner = "ItemsBatches" Then
			Return Items.TableOfAdditionalSeriesAttributes;
		EndIf;
	ElsIf ElementType = "AdditionalInfoItem1" Then
		If TypeOfElementSetOwner = "Products" Then
			Return Items.TableOfAdditionalInformationOfTheItem;
		ElsIf TypeOfElementSetOwner = "ItemsCharacteristics" Then
			Return Items.TableOfAdditionalCharacteristicsInformation;
		ElsIf TypeOfElementSetOwner = "ItemsBatches" Then
			Return Items.TableOfAdditionalInformationOfTheSeries;
		EndIf;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function AddlAttributesTable(Form, ElementType, TypeOfElementSetOwner)
	
	If ElementType = "AdditionalAttribute5" Then
		
		If TypeOfElementSetOwner = "Products" Then
			Return Form.TableOfAdditionalAttributesOfProducts;
		ElsIf TypeOfElementSetOwner = "ItemsCharacteristics" Then
			Return Form.TableOfAdditionalCharacteristicsAttributes;
		ElsIf TypeOfElementSetOwner = "ItemsBatches" Then
			Return Form.TableOfAdditionalSeriesAttributes;
		EndIf;
		
	ElsIf ElementType = "AdditionalInfoItem1" Then
		
		If TypeOfElementSetOwner = "Products" Then
			Return Form.TableOfAdditionalInformationOfTheItem;
		ElsIf TypeOfElementSetOwner = "ItemsCharacteristics" Then
			Return Form.TableOfAdditionalCharacteristicsInformation;
		ElsIf TypeOfElementSetOwner = "ItemsBatches" Then
			Return Form.TableOfAdditionalInformationOfTheSeries;
		EndIf;
		
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function NameOfTableForAdditionalInformationDetails(ElementType, TypeOfElementSetOwner)
	
	If ElementType = "AdditionalAttribute5" Then
		
		If TypeOfElementSetOwner = "Products" Then
			Return "TableOfAdditionalAttributesOfProducts";
		ElsIf TypeOfElementSetOwner = "ItemsCharacteristics" Then
			Return "TableOfAdditionalCharacteristicsAttributes";
		ElsIf TypeOfElementSetOwner = "ItemsBatches" Then
			Return "TableOfAdditionalSeriesAttributes";
		EndIf;
		
	ElsIf ElementType = "AdditionalInfoItem1" Then
		
		If TypeOfElementSetOwner = "Products" Then
			Return "TableOfAdditionalInformationOfTheItem";
		ElsIf TypeOfElementSetOwner = "ItemsCharacteristics" Then
			Return "TableOfAdditionalCharacteristicsInformation";
		ElsIf TypeOfElementSetOwner = "ItemsBatches" Then
			Return "TableOfAdditionalInformationOfTheSeries";
		EndIf;
		
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function SetOfAdditionalItemDetails_(Object, TypeOfElementSetOwner)
	
	If TypeOfElementSetOwner = "Products" Then
		Return Object.PropertiesSet;
	ElsIf TypeOfElementSetOwner = "ItemsCharacteristics" Then
		Return Object.CharacteristicsPropertySet;
	ElsIf TypeOfElementSetOwner = "ItemsBatches" Then
		Return Object.BatchPropertySet;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServerNoContext
Function SetOfAdditionalDetailsInformationGeneral(TypeOfElementSetOwner)
	
	If TypeOfElementSetOwner = "Products" Then
		SetOfAdditionalInformationDetails = PropertyManager.PropertiesSetByName("Catalog_Products_Overall");
	ElsIf TypeOfElementSetOwner = "ItemsCharacteristics" Then
		SetOfAdditionalInformationDetails = PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall");
	ElsIf TypeOfElementSetOwner = "ItemsBatches" Then
		SetOfAdditionalInformationDetails = PropertyManager.PropertiesSetByName("Catalog_ItemsBatches_Overall");
	Else
		SetOfAdditionalInformationDetails = Undefined;
	EndIf;
	
	Return SetOfAdditionalInformationDetails;
	
EndFunction

&AtClient
Procedure AddAdditionalDetailsInformation(ElementType, TypeOfElementSetOwner, Kind = "")
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể thêm thuộc tính bổ sung sau khi ghi lại phần tử.
		|Ghi lại phần tử?';
		|ru = 'Данные еще не записаны.
		|Добавление дополнительных свойств возможно только после записи элемента.
		|Записать элемент?';
		|en = 'Data is not saved yet.
		|You can add additional properties only after the item is saved.
		|Do you want to save the item?'; fa = 'Data is not saved yet.
		|You can add additional properties only after the item is saved.
		|Do you want to save the item?';
		|it = 'I dati non sono ancora stati registrati.
		|L''aggiunta di proprietà aggiuntive è possibile solo dopo la scrittura dell''elemento.
		|Scrivere l''elemento?';
		|pl = 'Dane nie zostały jeszcze zapisane/
		|Dodanie dodatkowych właściwości jest możliwe tylko po zapisaniu elementu.
		|Zapisać element?';
		|tr = 'Veriler kaydedilmedi.
		|Ek özellikler eklemek ancak öğe kaydedildikten sonra mümkündür.
		|Öğeyi kaydet?'");
		
		ShowQueryBox(New CallbackDescription("AddAdditionalDetailsInformationCompletion", ThisObject, New Structure("Kind, TypeOfElementSetOwner, ElementType", Kind, TypeOfElementSetOwner, ElementType)), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	AddAdditionalPropsSummaryFragment(Kind, TypeOfElementSetOwner, ElementType);
EndProcedure

&AtClient
Procedure AddAdditionalPropsSummaryFragment(Val Kind, Val TypeOfElementSetOwner, Val ElementType)
    
    Var SetOfAdditionalInformationDetails, FormParameters;
    
    TheCurrentTypeOfItemSetOwner = TypeOfElementSetOwner;
    CurrentItemType = ElementType;
    
    SetOfAdditionalInformationDetails = SetOfAdditionalItemDetails_(Object, TypeOfElementSetOwner);
    If Not ValueIsFilled(SetOfAdditionalInformationDetails) Then
        Return;
	EndIf;
	
	DataVersionOfTheCurrentSet = GetSetDataVersion(SetOfAdditionalInformationDetails);
	
	FormParameters = New Structure;
	
	If Kind = "Common" Then
		SetOfAdditionalInformationDetails = SetOfAdditionalDetailsInformationGeneral(TypeOfElementSetOwner);
	ElsIf Kind = "FromMaster" Then
		If ElementType = "AdditionalAttribute5" Then 
			FormParameters.Insert("SelectAdditionalValuesOwner", True);
		Else
			FormParameters.Insert("SelectSharedProperty", True);
		EndIf;
	EndIf;
	
	FormParameters.Insert("PropertiesSet", SetOfAdditionalInformationDetails);
	FormParameters.Insert("CurrentPropertiesSet", SetOfAdditionalInformationDetails);
	FormParameters.Insert("IsAdditionalInfo", ElementType <> "AdditionalAttribute5");
	FormParameters.Insert("PropertyKind1", ?(FormParameters.IsAdditionalInfo, 
												PredefinedValue("Enum.PropertiesKinds.AdditionalInfo"),
												PredefinedValue("Enum.PropertiesKinds.AdditionalAttributes")));
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
					FormParameters,
					FormTableForAdditionalInformationDetails(ElementType, TypeOfElementSetOwner),
					,
					,
					,
					,
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// The handler of the alert.
// Parameters:
// 	QuestionResult - DialogReturnCode - the selected option.
// 	AdditionalParameters - Structure - advanced setting:
// 		* Kind - String - view.
// 		* ElementType - String - element type.
// 		* TypeOfElementSetOwner - String - type of the owner of the set of elements.
// 		
&AtClient
Procedure AddAdditionalDetailsInformationCompletion(QuestionResult, AdditionalParameters) Export
	
	Kind = AdditionalParameters.Kind;
	TypeOfElementSetOwner = AdditionalParameters.TypeOfElementSetOwner;
	ElementType = AdditionalParameters.ElementType;
	
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
	
	AddAdditionalPropsSummaryFragment(Kind, TypeOfElementSetOwner, ElementType);
	
EndProcedure

&AtClient
Procedure ProcessingSelectionOfAdditionalDetailsInformation(ValueSelected, ElementType, TypeOfElementSetOwner)
	
	SetOfAdditionalInformationDetails = SetOfAdditionalItemDetails_(Object, TypeOfElementSetOwner);
	If Not ValueIsFilled(SetOfAdditionalInformationDetails) Then
		Return;
	EndIf;
	
	IsAdditionalInfoSets = (ElementType <> "AdditionalAttribute5");
	
	If TypeOf(ValueSelected) = Type("Structure")
		And ValueSelected.Property("AdditionalValuesOwner") Then
		
		FormParameters = New Structure;
		FormParameters.Insert("IsAdditionalInfo",      IsAdditionalInfoSets);
		FormParameters.Insert("CurrentPropertiesSet",            SetOfAdditionalInformationDetails);
		FormParameters.Insert("AdditionalValuesOwner", ValueSelected.AdditionalValuesOwner);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
			FormParameters, FormTableForAdditionalInformationDetails(ElementType, TypeOfElementSetOwner));
			
	ElsIf ValueSelected.Property("CommonProperty") Then		
		
		RecordCommonPropertyOnServer(ValueSelected, SetOfAdditionalInformationDetails, IsAdditionalInfoSets);
		
	EndIf;

EndProcedure

&AtClient
Procedure SetAvailabilityOfEditingCommandsAndInformationDetails(ElementType, TypeOfElementSetOwner)
	
	TableOfAdditionalInformationDetails = FormTableForAdditionalInformationDetails(ElementType, TypeOfElementSetOwner);
	
	CurrentData = TableOfAdditionalInformationDetails.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AddlAttributesTable = AddlAttributesTable(ThisObject, ElementType, TypeOfElementSetOwner);
	EditingCommands = CommandsForEditingAdditionalInformationDetails(ElementType, TypeOfElementSetOwner);
	
	// If the active line is a line of general additional details (information), then make the add, delete, move buttons unavailable.
	TMCommonUseClientServer.SetFormItemProperty(
		Items, 
		EditingCommands.Delete, 
		"Enabled", 
		Not CurrentData.CommonProperty);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items, 
		EditingCommands.MoveUp, 
		"Enabled", 
		Not CurrentData.CommonProperty);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items, 
		EditingCommands.MoveDown, 
		"Enabled", 
		Not CurrentData.CommonProperty);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items, 
		EditingCommands.ContextMenuDelete, 
		"Enabled", 
		Not CurrentData.CommonProperty);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items, 
		EditingCommands.ContextMenuMoveUp, 
		"Enabled", 
		Not CurrentData.CommonProperty);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items, 
		EditingCommands.ContextMenuMoveDown,
		"Enabled",
		Not CurrentData.CommonProperty);
	
	// If the active row is the first or last in the list, then make the up or down shift buttons unavailable.
	If Not CurrentData.CommonProperty Then
		
		RowIndex = AddlAttributesTable.IndexOf(CurrentData);
		
		If RowIndex = 0 Then
			
			TMCommonUseClientServer.SetFormItemProperty(
				Items, 
				EditingCommands.MoveUp, 
				"Enabled", 
				False);
			
			TMCommonUseClientServer.SetFormItemProperty(
				Items, 
				EditingCommands.ContextMenuMoveUp, 
				"Enabled", 
				False);
			
		EndIf;
		
		If RowIndex = AddlAttributesTable.Count() - 1 Then
			
			TMCommonUseClientServer.SetFormItemProperty(
				Items, 
				EditingCommands.MoveDown, 
				"Enabled", 
				False);
			
			TMCommonUseClientServer.SetFormItemProperty(
				Items, 
				EditingCommands.ContextMenuMoveDown, 
				"Enabled", 
				False);
			
		EndIf;
		
		If RowIndex <> 0 Then
			
			PreviousString = AddlAttributesTable[RowIndex - 1];
			
			If PreviousString.CommonProperty Then
				
				// If the previous row is a row of general props, then make the up shift button unavailable.
				TMCommonUseClientServer.SetFormItemProperty(
					Items, 
					EditingCommands.MoveUp, 
					"Enabled", 
					False);
				
				TMCommonUseClientServer.SetFormItemProperty(
					Items, 
					EditingCommands.ContextMenuMoveUp, 
					"Enabled", 
					False);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RecordAdditionalSetDetails(Cancel, CurrentObject, ElementType, TypeOfElementSetOwner)
	
	SetOfPropertiesAndInformationDetails = SetOfAdditionalItemDetails_(CurrentObject, TypeOfElementSetOwner);
	If Not ValueIsFilled(SetOfPropertiesAndInformationDetails) Then
		Return;
	EndIf;
	
	ObjectPropertySet = SetOfPropertiesAndInformationDetails.GetObject();
	
	If ElementType = "AdditionalAttribute5" Then
		TSAdditionalAttributesInfo = ObjectPropertySet.AdditionalAttributes;
	ElsIf ElementType = "AdditionalInfoItem1" Then
		TSAdditionalAttributesInfo = ObjectPropertySet.AdditionalInfo;
	EndIf;
	
	AddlAttributesTable = AddlAttributesTable(ThisObject, ElementType, TypeOfElementSetOwner);
	TSAdditionalAttributesInfo.Clear();
	
	For Each RowElement In AddlAttributesTable Do
		If Not RowElement.CommonProperty Then
			NwRw = TSAdditionalAttributesInfo.Add();
			NwRw.Property = RowElement.Property;
			NwRw.DeletionMark = Common.ObjectAttributeValue(RowElement.Property, "DeletionMark");
		EndIf;
	EndDo;
	
	Try
		
		ObjectPropertySet.Write();
		
	Except
		
		// Set the sign of record failure.
		Cancel = True;
		
		// Add an entry to the log.
		EventName = NStr("vi = 'Bổ sung %1 %2. Không thể cập nhật thành phần bổ sung %3 trong bộ.';
						|ru = 'Дополнительные %1 %2. Не удалось обновить состав дополнительных %3 набора.';
						|en = 'Additional %1 %2. Cannot update the list of additional %3 in the set.'; fa = 'Additional %1 %2. Cannot update the list of additional %3 in the set.';
						|it = 'Aggiuntive %1 %2. Non è stato possibile aggiornare la composizione delle aggiunte dell''insieme %3.';
						|pl = 'Dodatkowe %1 %2. Aktualizacja składu zestawu dodatkowych %3 zestawu nie powiodła się.';
						|tr = 'Ek %1 %2. Ek %3 kümesinin içeriği güncellenemedi.'");
		
		TypeOfInformation = ?(ElementType = "AdditionalAttribute5", "attributes", "informationrecords");
		ObjectType  = ?(TypeOfElementSetOwner = "Products", "ofproductitem", ?(TypeOfElementSetOwner = "ItemsCharacteristics", "features", "series_"));
		TypeOfComposition  = ?(ElementType = "AdditionalAttribute5", "bankingdetails_", "ofinformation");
		
		EventName = StringFunctionsClientServer.SubstituteParametersToString(
			EventName, 
			TypeOfInformation, 
			ObjectType, 
			TypeOfComposition);
		
		JournalComment  = NStr("vi = 'Khi cập nhật phần bảng các mục tin bổ sung trong tập hợp thuộc tính ""%1"" đã xảy ra lỗi: ""%2""';
								|ru = 'При обновлении табличной части дополнительных реквизитов набора свойств ""%1"" произошла ошибка: ""%2""';
								|en = 'An error occurred when updating the table of the additional attributes of property set ""%1"": ""%2""'; fa = 'An error occurred when updating the table of the additional attributes of property set ""%1"": ""%2""';
								|it = 'Durante l''aggiornamento della tabella delle proprietà aggiuntive dell''insieme delle proprietà ""%1"" si è verificato un errore: ""%2""';
								|pl = 'Podczas aktualizacji sekcji tabelarycznej atrybutów dodatkowych zestawu właściwości ""%1"" zaistniał błąd: ""%2""';
								|tr = '""%1"" özellik kümesinin ek özniteliklerinin tablo bölümü güncellenirken hata oluştu: ""%2""'");
		ErrorPresentation = DetailErrorDescription(ErrorInfo());
		
		JournalComment  = StringFunctionsClientServer.SubstituteParametersToString(
			JournalComment, 
			SetOfPropertiesAndInformationDetails, 
			ErrorPresentation);
		
		WriteLogEvent(
			EventName, 
			EventLogLevel.Error, 
			, 
			SetOfPropertiesAndInformationDetails, 
			JournalComment, 
			EventLogEntryTransactionMode.Transactional);
		
		// Raise an exception.
		ExceptionExpression = NStr("vi = 'Khi ghi lại %1 %2 bổ sung, đã xảy ra lỗi (xem nhật ký sự kiện).';
									|ru = 'При записи дополнительных %1 %2 произошла ошибка (см. журнал регистрации).';
									|en = 'An error occurred when saving additional %1 %2 (see event log).'; fa = 'An error occurred when saving additional %1 %2 (see event log).';
									|it = 'Si è verificato un errore durante la registrazione delle aggiuntive %1 %2 (vedi registro di registrazione).';
									|pl = 'Podczas zapisu dodatkowych %1 %2 zaistniał błąd (zob. dziennik rejestracji).';
									|tr = 'Ek %1 %2 kaydedilirken hata oluştu (olay günlüğüne bakın).'");
		
		TypeOfInformation = ?(ElementType = "AdditionalAttribute5", "bankingdetails_", "ofinformation");
		ObjectType = ?(TypeOfElementSetOwner = "Products", "ofproductitem", ?(TypeOfElementSetOwner = "ItemsCharacteristics", "features", "series_"));
		
		ExceptionExpression = StringFunctionsClientServer.SubstituteParametersToString(
			ExceptionExpression, 
			TypeOfInformation, 
			ObjectType, 
			TypeOfComposition);
		
		Raise(ExceptionExpression);
		
	EndTry;
	
EndProcedure

&AtClient
Procedure WhenSelectingRowInTableOfAdditionalDetails(ElementType, TypeOfElementSetOwner, CurrentRow)
	
	If Not ThereIsTheRightToEdit Then
		Return;
	ElsIf CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CurrentItemType = ElementType;
	TheCurrentTypeOfItemSetOwner = TypeOfElementSetOwner;
	
	PropertiesSet = ?(CurrentRow.CommonProperty,
					SetOfCommonProperties,
					Object.PropertiesSet);
	
	If TypeOfElementSetOwner = "ItemsCharacteristics" Then
		PropertiesSet = ?(CurrentRow.CommonProperty,
						SetOfCommonPropertiesCharacteristics,
						Object.CharacteristicsPropertySet);
	ElsIf TypeOfElementSetOwner = "ItemsBatches" Then
		PropertiesSet = ?(CurrentRow.CommonProperty,
						SetOfCommonSeriesProperties,
						Object.BatchPropertySet);
	EndIf;
	
	FormParameters = New Structure("Key, CurrentPropertiesSet", CurrentRow.Property, PropertiesSet);
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.ItemForm",
				FormParameters,
				ThisObject);
	
EndProcedure

&AtClient
Procedure SetBanOnDraggingElementsOfAdditionalInformationDetails(Perform, ElementType, TypeOfElementSetOwner)
	
	TableOfAdditionalInformationDetails	= FormTableForAdditionalInformationDetails(ElementType, TypeOfElementSetOwner);
	CurrentData					= TableOfAdditionalInformationDetails.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	Else
		Perform = Not CurrentData.CommonProperty;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// This procedure is called when you start selecting a template for the item name or characteristics.
// Checks whether the element is modified and opens the template editing form.
//
// Parameters:
//	Name template (String) - name template,
//	Name template element ( field Form) - template element,
//	Template name (String) - name of the name template,
//	Ban flag (String) - name of the ban flag.
//
&AtClient
Procedure ChangeInTemplateEditor(NameOfNameTemplate)
	
	ClearMessages();
	
	QuestionParameters = New Structure;
	QuestionParameters.Insert("NameOfNameTemplate", NameOfNameTemplate);
	
	If Modified Then
		
		QueryText = NStr("vi = 'Thay đổi khuôn mẫu tên gọi thông qua bộ soạn công thức 
		                          |sau khi ghi lại phần tử, ghi lại phần tử?';
		                          |ru = 'Изменение шаблона наименования с помощью редактора 
		                          |формул возможно только после записи элемента, записать элемент?';
		                          |en = 'You can change the name template using the formula
		                          |editor only after saving the item. Do you want to save the item?'; fa = 'You can change the name template using the formula
		                          |editor only after saving the item. Do you want to save the item?';
		                          |it = 'Изменение шаблона наименования с помощью редактора 
		                          |формул возможно только после записи элемента, записать элемент?';
		                          |pl = 'You can change the name template using the formula
		                          |editor only after saving the item. Do you want to save the item?';
		                          |tr = 'Formül düzenleyiciyi kullanarak tanım şablonunu değiştirmek 
		                          |sadece öğenin kaydından sonra mümkündür, öğe kaydedilsin mi?'");
		

		ShowQueryBox(New CallbackDescription("ChangeInTemplateEditorQuestionAboutRecordCompletion", ThisObject, QuestionParameters),
			QueryText, QuestionDialogMode.OKCancel,,,NStr("vi = 'Chỉnh sửa mẫu';
															|ru = 'Редактирование шаблона';
															|en = 'Edit template'; fa = 'ویرایش الگو';
															|it = 'Modifica del modello';
															|pl = 'Edycja szablonu';
															|tr = 'Şablon düzenleme'"));
			
		Return;	
	EndIf;
	
	ChangeInQuestionSnippetTemplateEditor(QuestionParameters);
	
EndProcedure

&AtClient
Procedure ChangeInQuestionSnippetTemplateEditor(AdditionalParameters)
	
	TemplateName = AdditionalParameters.NameOfNameTemplate;
	OperandTreeAddress = PrepareTreeOfOperands(TemplateName);
	
	TemplateEditingOptions = New Structure("Formula, OperandsTitle, Operators, StringFormula, OperandsTree");
	
	TemplateEditingOptions.Formula           = Object[TemplateName];
	TemplateEditingOptions.OperandsTitle = NStr("vi = 'Mục tin khả dụng';
												|ru = 'Доступные реквизиты';
												|en = 'Available attributes'; fa = 'ویژگی‌های در دسترس';
												|it = 'Requisiti disponibili';
												|pl = 'Dostępne atrybuty';
												|tr = 'Kullanılabilir öznitelikler'");
	TemplateEditingOptions.Operators         = OperatorsTreeStorageAddress;
	
	TemplateEditingOptions.OperandsTree  = OperandTreeAddress;
	TemplateEditingOptions.Insert("ResultType", New TypeDescription("String"));
	
	CallbackDescription = New CallbackDescription("ChangeInTemplateEditorCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"CommonForm.FormulasConstructor",
		TemplateEditingOptions,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtServer
Function PrepareTreeOfOperands(TemplateName)
	
	PropertiesSets = New Structure("PropertiesSet, BatchPropertySet, CharacteristicsPropertySet");
	FillPropertyValues(PropertiesSets, Object);
	
	OperandsTree = Catalogs.ItemKinds.PrepareTreeOfOperands(PropertiesSets, TemplateName);
	
	StorageAddress = PutToTempStorage(OperandsTree, UUID);
	
	Return StorageAddress;
	
EndFunction

&AtClient
Procedure ChangeInTemplateEditorQuestionAboutRecordCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.OK Then
		If Write() Then
			
			ChangeInQuestionSnippetTemplateEditor(AdditionalParameters);
								
		EndIf;	
	EndIf;	
	
EndProcedure

&AtClient
Procedure ChangeInTemplateEditorCompletion(Result, AdditionalParameters) Export
		
	Template = Result;
	TemplateName = AdditionalParameters.NameOfNameTemplate;
	
	If Template <> Undefined 
		And Object[TemplateName] <> Template Then
		Modified = True;
		Object[TemplateName] = Template;
		
		If Not MultilingualismIsEnabled Then
			BankingDetailsNameNoNameEditing = BankingDetailsNameNoNameEditing(TemplateName);
			If BankingDetailsNameNoNameEditing <> "" Then
				Object[BankingDetailsNameNoNameEditing] = ValueIsFilled(Object[TemplateName]);
			EndIf;
		EndIf;
		
		ConfigureByNameTemplate(AdditionalParameters.NameOfNameTemplate);
	EndIf;
	
EndProcedure

&AtServer
Procedure BuildTreeOfOperators()
	
	Tree = ProcessingOfFormulas.GetEmptyOperatorsTree();
	
	PresentationOfOperatorGroup = NStr("vi = 'Ký tự tách';
										|ru = 'Разделители';
										|en = 'Separators'; fa = 'Separators';
										|it = 'Divisori';
										|pl = 'Separatory';
										|tr = 'Ayırıcılar'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "Separators", PresentationOfOperatorGroup);
	
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "/", " + ""/"" + ", "/");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "\", " + ""\"" + ", "\");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "|", " + ""|"" + ", "|");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "_", " + ""_"" + ", "_");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, ",", " + "", "" + ", ",");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, ".", " + "". "" + ", ".");
	
	OperatorPresentation = NStr("vi = 'Dấu cách';
								|ru = 'Пробел';
								|en = 'Whitespace'; fa = 'فاصله خالی';
								|it = 'Spazio';
								|pl = 'Spacja';
								|tr = 'Boşluk'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "Whitespace", " + "" "" + ", OperatorPresentation);
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "(", " + "" ("" + ", "(");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, ")", " + "") "" + ", ")");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, """", " + """""""" + ", """");
	
	PresentationOfOperatorGroup = NStr("vi = 'Toán tử';
										|ru = 'Операторы';
										|en = 'Operators'; fa = 'عملگرها';
										|it = 'Operatori';
										|pl = 'Operatory';
										|tr = 'Operatörler'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "Operators", PresentationOfOperatorGroup);
	
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "+", " + ", "+");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "-", " - ", "-");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "*", " * ", "*");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "/", " / ", "/");
	
	PresentationOfOperatorGroup = NStr("vi = 'Toán tử lo-gic và hằng';
										|ru = 'Логические операторы и константы';
										|en = 'Logical operators and constants'; fa = 'Logical operators and constants';
										|it = 'Operatori logici e costanti';
										|pl = 'Operatory logiczne i konstanty';
										|tr = 'Mantıksal operatörler ve sabitler'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "LogicalOperatorsAndConstants", PresentationOfOperatorGroup);
	
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "<", " < ", "<");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, ">", " > ", ">");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "<=", " <= ", "<=");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, ">=", " >= ", ">=");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "=", " = ", "=");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "<>", " <> ", "<>");
	
	Id = "And";
	StructureToInsert = " " + "And" + " ";
	Presentation = NStr("vi = 'VÀ';
						|ru = 'И';
						|en = 'AND'; fa = 'و';
						|it = 'E';
						|pl = 'ORAZ';
						|tr = 'AND'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "Or";
	StructureToInsert = " " + "Or" + " ";
	Presentation = NStr("vi = 'HOẶC';
						|ru = 'Или';
						|en = 'OR'; fa = 'یا';
						|it = 'Oppure';
						|pl = 'Lub';
						|tr = 'OR'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "Not";
	StructureToInsert = " " + "Not" + " ";
	Presentation = NStr("vi = 'KHÔNG';
						|ru = 'Не';
						|en = 'Not'; fa = 'Not';
						|it = 'Non';
						|pl = 'Nie';
						|tr = 'NOT'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "TRUE";
	StructureToInsert = " " + "TRUE" + " ";
	Presentation = NStr("vi = 'TRUE';
						|ru = 'ИСТИНА';
						|en = 'TRUE'; fa = 'TRUE';
						|it = 'VERO';
						|pl = 'PRAWDA';
						|tr = 'TRUE'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "FALSE";
	StructureToInsert = " " + "FALSE" + " ";
	Presentation = NStr("vi = 'FALSE';
						|ru = 'ЛОЖЬ';
						|en = 'FALSE'; fa = 'FALSE';
						|it = 'FALSO';
						|pl = 'FAŁSZ';
						|tr = 'FALSE'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	PresentationOfOperatorGroup = NStr("vi = 'Hàm số';
										|ru = 'Числовые функции';
										|en = 'Numeric functions'; fa = 'Numeric functions';
										|it = 'Funzioni numeriche';
										|pl = 'Funkcje liczbowe';
										|tr = 'Sayısal fonksiyonlar'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "NumericFunction", PresentationOfOperatorGroup);
	
	Id = "Max";
	StructureToInsert = "Max(,)";
	Presentation = NStr("vi = 'Tối đa';
						|ru = 'Максимум';
						|en = 'Max'; fa = 'حداکثر';
						|it = 'Massimo';
						|pl = 'Maksimum';
						|tr = 'Maksimum'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,,
	                                  2);
	
	Id = "Min";
	StructureToInsert = "Min(,)";
	Presentation = NStr("vi = 'Tối thiểu';
						|ru = 'Минимум';
						|en = 'Min'; fa = 'حداقل';
						|it = 'Minimo';
						|pl = 'Minimum';
						|tr = 'Minimum'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,,
	                                  2);
	
	Id = "Round";
	TextRoundedValue      = NStr("vi = '<Giá trị làm tròn>';
								|ru = '<Округляемое значение>';
								|en = '<Round value>'; fa = '<Round value>';
								|it = '<Valore da arrotondare>';
								|pl = '<Wartość zaokrąglana>';
								|tr = '<Yuvarlanmış değer>'");
	TextNumberOfCharacters         = NStr("vi = '<Ký tự sau dấu phẩy>';
											|ru = '<Знаков после запятой>';
											|en = '<Decimal places>'; fa = '<Decimal places>';
											|it = '<Caratteri dopo la virgola>';
											|pl = '<Znaków po przecinku>';
											|tr = '<Ondalık basamak>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Round(%1, %2)",
		TextRoundedValue,
		TextNumberOfCharacters);
	Presentation = NStr("vi = 'Làm tròn';
						|ru = 'Округление';
						|en = 'Rounding'; fa = 'Rounding';
						|it = 'Arrotondamento';
						|pl = 'Zaokrąglenie';
						|tr = 'Yuvarlama'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,,
	                                  2);
	
	Id = "Int";
	StructureToInsert = "Int()";
	Presentation = NStr("vi = 'Phần nguyên';
						|ru = 'Целая часть';
						|en = 'Integral part'; fa = 'بخش صحیح';
						|it = 'Parte intera';
						|pl = 'Cała część';
						|tr = 'Tam sayı kısmı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,,
	                                  1);
	
	PresentationOfOperatorGroup = NStr("vi = 'Chức năng theo xâu ký tự';
										|ru = 'Строковые функции';
										|en = 'String functions'; fa = 'توابع رشته‌ای';
										|it = 'Funzioni di stringa';
										|pl = 'Funkcje wierszy';
										|tr = 'Satır fonksiyonları'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "StringFunctions", PresentationOfOperatorGroup);
	
	Id = "String";
	StructureToInsert = "String()";
	Presentation = NStr("vi = 'Xâu ký tự';
						|ru = 'Строка';
						|en = 'Row'; fa = 'Row';
						|it = 'Riga';
						|pl = 'Wiersz';
						|tr = 'Satır'");
	ExplanationOfOperator = NStr("vi = 'Chuyển đổi giá trị thành xâu ký tự';
								|ru = 'Преобразовывает значение в строку';
								|en = 'Converts a value to a string'; fa = 'Converts a value to a string';
								|it = 'Trasforma il valore in riga';
								|pl = 'Przekształca wartość w wiersz';
								|tr = 'Değeri bir satıra dönüştürür'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "Upper";
	StructureToInsert = "Upper()";
	Presentation = NStr("vi = 'Biểu ghi phía trên';
						|ru = 'Верхний регистр';
						|en = 'Uppercase'; fa = 'Uppercase';
						|it = 'Maiuscolo';
						|pl = 'Rejestr górny';
						|tr = 'Büyük harf'");
	ExplanationOfOperator = NStr("vi = 'Nhập xâu ký tự vào biểu ghi phía trên';
								|ru = 'Приводит строку в верхний регистр';
								|en = 'Converts a string to an uppercase'; fa = 'Converts a string to an uppercase';
								|it = 'Trasforma la riga in maiuscolo';
								|pl = 'Przekształca wiersz w rejestr górny';
								|tr = 'Satırı büyük harfe çevirir'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "Left";
	TextSourceString = NStr("vi = '<Xâu ký tự gốc>';
							|ru = '<Исходная строка>';
							|en = '<Source string>'; fa = '<Source string>';
							|it = '<Riga originale>';
							|pl = '<Wiersz wyjściowy>';
							|tr = '<Kaynak satır>'");
	TextNumberOfCharacters_ = NStr("vi = '<Số lượng ký tự>';
									|ru = '<Количество символов>';
									|en = '<number of characters>'; fa = '<number of characters>';
									|it = '<Numero di caratteri>';
									|pl = '<Liczba znaków>';
									|tr = '<Karakter sayısı>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Left(%1, %2)",
		TextSourceString,
		TextNumberOfCharacters_);
	Presentation = NStr("vi = 'Phần trái của xâu ký tự';
						|ru = 'Левая часть строки';
						|en = 'Left part of the string'; fa = 'Left part of the string';
						|it = 'Parte sinistra della riga';
						|pl = 'Lewa strona wiersza';
						|tr = 'Satırın sol kısmı'");
	ExplanationOfOperator = NStr("vi = 'Nhận số ký tự được chỉ định từ bên trái xâu ký tự';
								|ru = 'Получает указанное количество символов слева строки';
								|en = 'Gets the specified number of characters to the left of the string'; fa = 'Gets the specified number of characters to the left of the string';
								|it = 'Riceve il numero indicato di caratteri a sinistra della riga';
								|pl = 'Pobiera podaną liczbę znaków z lewej strony wiersza';
								|tr = 'Satırın solundaki belirtilen karakter sayısını alır'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "Lower";
	StructureToInsert = "Lower()";
	Presentation = NStr("vi = 'Biểu ghi phía dưới';
						|ru = 'Нижний регистр';
						|en = 'Lowercase'; fa = 'Lowercase';
						|it = 'Minuscolo';
						|pl = 'Rejestr dolny';
						|tr = 'Küçük harf'");
	ExplanationOfOperator = NStr("vi = 'Nhập xâu ký tự vào biểu ghi phía dưới';
								|ru = 'Приводит строку к нижнему регистру';
								|en = 'Converts a string to an lowercase'; fa = 'Converts a string to an lowercase';
								|it = 'Trasforma la riga in minuscolo';
								|pl = 'Przekształca wiersz w rejestr dolny';
								|tr = 'Satırı küçük harfe çevirir'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "Right";
	TextSourceString = NStr("vi = '<Xâu ký tự gốc>';
							|ru = '<Исходная строка>';
							|en = '<Source string>'; fa = '<Source string>';
							|it = '<Riga originale>';
							|pl = '<Wiersz wyjściowy>';
							|tr = '<Kaynak satır>'");
	TextNumberOfCharacters_ = NStr("vi = '<Số lượng ký tự>';
									|ru = '<Количество символов>';
									|en = '<number of characters>'; fa = '<number of characters>';
									|it = '<Numero di caratteri>';
									|pl = '<Liczba znaków>';
									|tr = '<Karakter sayısı>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Right(%1, %2)",
		TextSourceString,
		TextNumberOfCharacters_);
	Presentation = NStr("vi = 'Phần bên phải của xâu ký tự';
						|ru = 'Правая часть строки';
						|en = 'Right part of the string'; fa = 'Right part of the string';
						|it = 'Parte destra della riga';
						|pl = 'Prawa strona wiersza';
						|tr = 'Satırın sağ kısmı'");
	ExplanationOfOperator = NStr("vi = 'Nhận số ký tự được chỉ định từ bên phải của xâu ký tự';
								|ru = 'Получает указанное количество символов справа строки';
								|en = 'Gets the specified number of characters to the right of the string'; fa = 'Gets the specified number of characters to the right of the string';
								|it = 'Riceve il numero indicato di caratteri a sinistra della riga';
								|pl = 'Pobiera podaną liczbę znaków z prawej strony wiersza';
								|tr = 'Satırın sağındaki belirtilen karakter sayısını alır'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "TrimL";
	StructureToInsert = "TrimL()";
	Presentation = NStr("vi = 'Xóa ký tự thừa bên trái';
						|ru = 'Удаление лишних символов слева';
						|en = 'Removing extra characters on the left'; fa = 'Removing extra characters on the left';
						|it = 'Eliminazione di caratteri in eccesso a sinistra';
						|pl = 'Usunięcie zbędnych znaków z lewej strony';
						|tr = 'Soldaki fazla karakterlerin silinmesi'");
	ExplanationOfOperator = NStr("vi = 'Cắt bỏ các ký tự không có nghĩa ở bên trái ký tự có nghĩa đầu tiên trong một xâu ký tự';
								|ru = 'Отсекает незначащие символы, стоящие слева от первого значащего символа в строке';
								|en = 'Truncates insignificant characters to the left of the first significant character in the string'; fa = 'Truncates insignificant characters to the left of the first significant character in the string';
								|it = 'Taglia caratteri senza valore posizionati alla sinistra del primo carattere avente valore nella riga';
								|pl = 'Odcina nieistotne znaki, znajdujące się z lewej strony od pierwszego istotnego znaku w wiersz';
								|tr = 'Satırdaki ilk önemli karakterin solundaki önemsiz karakterleri keser'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "TrimAll";
	StructureToInsert = "TrimAll()";
	Presentation = NStr("vi = 'Xóa ký tự thừa bên trái và bên phải';
						|ru = 'Удаление лишних символов слева и справа';
						|en = 'Removing extra characters on the left and on the right'; fa = 'Removing extra characters on the left and on the right';
						|it = 'Eliminazione di caratteri in eccesso a sinistra e a destra';
						|pl = 'Usunięcie zbędnych znaków z lewej i prawej strony';
						|tr = 'Soldaki ve sağdaki fazla karakterlerin silinmesi'");
	ExplanationOfOperator = NStr("vi = 'Cắt bỏ các ký tự không có nghĩa ở bên trái ký tự có nghĩa đầu tiên trong một xâu ký tự và các khoảng trắng ở bên phải ký tự có nghĩa cuối cùng trong một xâu ký tự';
								|ru = 'Отсекает незначащие символы, стоящие слева от первого значащего символа в строке, и пробелы, стоящие справа от последнего значащего символа в строке';
								|en = 'Truncates insignificant characters to the left of the first significant character in the string and spaces to the right of the last significant character in the string'; fa = 'Truncates insignificant characters to the left of the first significant character in the string and spaces to the right of the last significant character in the string';
								|it = 'Taglia caratteri senza valore posizionati alla sinistra del primo carattere avente valore nella riga, e spazi posizionati a destra dell''ultimo carattere avente valore nella riga';
								|pl = 'Odcina nieistotne znaki, znajdujące się z lewej strony od pierwszego istotnego znaku w wierszu, i spacje, znajdujące się z prawej strony od ostatniego istotnego znaku w wierszu';
								|tr = 'Satırdaki ilk önemli karakterin solundaki önemsiz karakterleri ve satırdaki son önemli karakterin sağındaki boşlukları keser'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "TrimR";
	StructureToInsert = "TrimR()";
	Presentation = NStr("vi = 'Xóa ký tự thừa bên phải';
						|ru = 'Удаление лишних символов справа';
						|en = 'Removing extra characters on the right'; fa = 'Removing extra characters on the right';
						|it = 'Eliminazione di caratteri in eccesso a destra';
						|pl = 'Usunięcie zbędnych symboli z prawej strony';
						|tr = 'Sağdaki fazla karakterlerin silinmesi'");
	ExplanationOfOperator = NStr("vi = 'Cắt bỏ các ký tự không có nghĩa ở bên phải của ký tự có nghĩa cuối cùng trong một xâu ký tự';
								|ru = 'Отсекает незначащие символы, стоящие справа от последнего значащего символа в строке';
								|en = 'Truncates insignificant characters to the right of the last significant character in the string'; fa = 'Truncates insignificant characters to the right of the last significant character in the string';
								|it = 'Taglia caratteri senza valore posizionati alla destra dell''ultimo carattere avente valore nella riga';
								|pl = 'Odcina nieistotne znaki, znajdujące się z prawej strony od ostatniego istotnego znaku w wierszu';
								|tr = 'Satırdaki ilk önemli karakterin sağındaki önemsiz karakterleri keser'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "Title";
	StructureToInsert = "Title()";
	Presentation = NStr("vi = 'Biểu ghi tiêu đề';
						|ru = 'Титульный регистр';
						|en = 'Title register'; fa = 'Title register';
						|it = 'Titolo';
						|pl = 'Rejestr tytułowy';
						|tr = 'Başlık kaydı'");
	ExplanationOfOperator = NStr("vi = 'Chuyển dòng bằng cách sau: trong mỗi từ của dòng, ký tự đầu tiên được chuyển đến biểu ghi phía trên. Tất cả ký tự còn lại được chuyển đến biểu ghi phía dưới';
								|ru = 'Преобразует строку следующим образом: у каждого слова строки первый символ преобразуется к верхнему регистру. Все остальные символы преобразуются к нижнему регистру';
								|en = 'Converts a string as follows: for each word in a string, the first character is converted to uppercase. All other characters are converted to lowercase'; fa = 'Converts a string as follows: for each word in a string, the first character is converted to uppercase. All other characters are converted to lowercase';
								|it = 'Trasforma la riga in seguente modo: il primo carattere di ogni parola della riga viene trasformato in maiuscolo. Tutti gli altri caratteri in minuscoli.';
								|pl = 'Przekształca wiersz w następny sposób: pierwszy znak każdego słowa jest przekształcany do rejestru górnego. Wszystkie pozostałe znaki są przekształcane do rejestru dolnego';
								|tr = 'Satırı şu şekle dönüştürür: Satırdaki her kelimenin ilk karakteri büyük harfe dönüştürülür. Diğer tüm karakterler küçük harfe dönüştürülür'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "StrReplace";
	TextSourceString = NStr("vi = '<Xâu ký tự gốc>';
							|ru = '<Исходная строка>';
							|en = '<Source string>'; fa = '<Source string>';
							|it = '<Riga originale>';
							|pl = '<Wiersz wyjściowy>';
							|tr = '<Kaynak satır>'");
	TextStringWhatToReplace_ = NStr("vi = '<Xâu ký tự được thay thế>';
									|ru = '<Строка которую заменить>';
									|en = '<String to replace>'; fa = '<String to replace>';
									|it = '<Riga da sostituire>';
									|pl = '<Wiersz, który należy zastąpić>';
									|tr = '<Değiştirilecek satır>'");
	TextStringWhatToReplace = NStr("vi = '<Xâu ký tự thay thế>';
									|ru = '<Строка на которую заменить>';
									|en = '<String to replace with>'; fa = '<String to replace with>';
									|it = '<Riga con cui sostituire>';
									|pl = '<Wiersz, na który należy zastąpić>';
									|tr = '<Değiştirilmek üzere satır>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"StrReplace(%1, %2, %3)",
		TextSourceString,
		TextStringWhatToReplace_,
		TextStringWhatToReplace);
	Presentation = NStr("vi = 'Thay thế trong xâu ký tự';
						|ru = 'Замена в строке';
						|en = 'Replacement in string'; fa = 'Replacement in string';
						|it = 'Sostituzione nella riga';
						|pl = 'Zastępowanie w wierszu';
						|tr = 'Satırda değiştirme'");
	ExplanationOfOperator = NStr("vi = 'Đang tìm tất cả các lần xuất hiện của chuỗi con tìm kiếm trong chuỗi gốc và thay thế nó bằng chuỗi con thay thế';
								|ru = 'Находит в исходной строке все вхождения подстроки поиска и заменяет ее на подстроку замены';
								|en = 'Finds all occurrences of the search substring in the source string and replaces it with the replacement substring'; fa = 'Finds all occurrences of the search substring in the source string and replaces it with the replacement substring';
								|it = 'Trova nella riga originale tutte le occorrenze di sottostringa di ricerca e le sostituisce con la sottostringa di sostituzione';
								|pl = 'Znajduje w wierszu wyjściowym wszystkie występowania podwierszu wyszukiwania i zastępuje ją na podwiersz zastępowania';
								|tr = 'Kaynak satırında arama alt satırının tüm oluşumlarını bulur ve onu değiştirme alt satırı ile değiştirir'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "StrLen";
	StructureToInsert = "StrLen()";
	Presentation = NStr("vi = 'Độ dài xâu ký tự';
						|ru = 'Длина строки';
						|en = 'String length'; fa = 'طول رشته';
						|it = 'Lunghezza della riga';
						|pl = 'Długość wiersza';
						|tr = 'Satır uzunluğu'");
	ExplanationOfOperator = NStr("vi = 'Trả lại số lượng ký tự của chuỗi';
								|ru = 'Возвращает количество символов строки';
								|en = 'Returns the number of characters in a string'; fa = 'Returns the number of characters in a string';
								|it = 'Riporta il numero dei caratteri della riga';
								|pl = 'Zwraca liczbę znaków wierszu';
								|tr = 'Satırdaki karakter sayısını geri döndürür'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	PresentationOfOperatorGroup = NStr("vi = 'Chức năng khác';
										|ru = 'Прочие функции';
										|en = 'Other functions'; fa = 'Other functions';
										|it = 'Altre funzioni';
										|pl = 'Inne funkcje';
										|tr = 'Diğer fonksiyonlar'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "OtherFunctions", PresentationOfOperatorGroup);
	
	Id = "?";
	TextCondition = NStr("vi = '<Điều kiện>';
						|ru = '<Условие>';
						|en = '<Condition>'; fa = '<Condition>';
						|it = '<Condizione>';
						|pl = '<Warunek>';
						|tr = '<Koşul>'");
	TextMeaningTrue = NStr("vi = '<Giá trị nếu đúng>';
							|ru = '<Значение если истина>';
							|en = '<Value if true>'; fa = '<Value if true>';
							|it = '<Valore se vero>';
							|pl = '<Wartość jeśli prawda>';
							|tr = '<Doğru ise değer>'");
	TextMeaningFalse = NStr("vi = '<Giá trị nếu sai>';
							|ru = '<Значение если ложь>';
							|en = '<Value if false>'; fa = '<Value if false>';
							|it = '<Valore se falso>';
							|pl = '<Wartość jeśli fałsz>';
							|tr = '<Yanlış ise değer>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"?(%1, %2, %3)",
		TextCondition,
		TextMeaningTrue,
		TextMeaningFalse);
	Presentation = NStr("vi = 'Điều kiện';
						|ru = 'Условие';
						|en = 'Condition'; fa = 'شرط';
						|it = 'Condizione';
						|pl = 'Warunek';
						|tr = 'Şart'");
	ExplanationOfOperator = NStr("vi = 'Tính toán giá trị phụ thuộc vào giá trị điều kiện';
								|ru = 'Вычисляет значение в зависимости от значения условия';
								|en = 'Calculates a value based on a condition value'; fa = 'Calculates a value based on a condition value';
								|it = 'Calcola il valore in relazione al valore della condizione';
								|pl = 'Oblicza wartość w zależności od wartości warunku';
								|tr = 'Şartın değerine bağlı olarak değeri hesaplar'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "PredefinedValue";
	StructureToInsert = "PredefinedValue()";
	Presentation = NStr("vi = 'Giá trị định trước';
						|ru = 'Предопределенное значение';
						|en = 'Predefined value'; fa = 'Predefined value';
						|it = 'Valore predefinito';
						|pl = 'Wartość predefiniowana';
						|tr = 'Önceden tanımlanmış değer'");
	ExplanationOfOperator = NStr("vi = 'Tham chiếu đến phần tử định trước theo tên của nó';
								|ru = 'Обращение к предопределенному элементу по его имени';
								|en = 'Accesses a predefined item by its name'; fa = 'Accesses a predefined item by its name';
								|it = 'Accesso all''elemento predefinito per nome';
								|pl = 'Odwołanie do predefiniowanego elementu wg jego nazwy';
								|tr = 'Önceden tanımlanmış bir öğeye adıyla başvurma'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "ValueIsFilled";
	StructureToInsert = "ValueIsFilled()";
	Presentation = NStr("vi = 'Giá trị đã điền';
						|ru = 'Значение заполнено';
						|en = 'Value filled'; fa = 'Value filled';
						|it = 'Valore compilato';
						|pl = 'Wartość wypełniona';
						|tr = 'Değer dolduruldu'");
	ExplanationOfOperator = NStr("vi = 'Kiểm tra điền giá trị';
								|ru = 'Проверка заполненности значения';
								|en = 'Checking whether the value is filled'; fa = 'Checking whether the value is filled';
								|it = 'Controllo della compilazione del valore';
								|pl = 'Sprawdzenie wypełnienia wartości';
								|tr = 'Değerin doluluk kontrolü'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	Id = "Format";
	TextValue = NStr("vi = '<Giá trị >';
					|ru = '<Значение>';
					|en = '<Value>'; fa = '<Value>';
					|it = '<Valore>';
					|pl = '<Wartość>';
					|tr = '<Değer>'");
	TextFormatString = NStr("vi = '<Dòng định dạng>';
							|ru = '<Форматная строка>';
							|en = '<Format string>'; fa = '<Format string>';
							|it = '<Stringa di formato>';
							|pl = '<Formatowy wiersz>';
							|tr = '<Format satırı>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Format(%1, %2)",
		TextValue,
		TextFormatString);
	Presentation = NStr("vi = 'Định dạng';
						|ru = 'Формат';
						|en = 'Format'; fa = 'قالب';
						|it = 'Formato';
						|pl = 'Format';
						|tr = 'Format'");
	ExplanationOfOperator = NStr("vi = 'Đang định dạng giá trị theo dòng định dạng';
								|ru = 'Выполняет форматирование значения в соответствии с форматной строкой';
								|en = 'Formats the value according to the format string'; fa = 'Formats the value according to the format string';
								|it = 'Esegue la formattazione del valore in base alla stringa di formato';
								|pl = 'Wykonuje formatowanie wartości zgodnie z formatowym wierszem';
								|tr = 'Format satırına göre değerin biçimlendirmesini gerçekleştirir'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation,
	                                  ExplanationOfOperator);
	
	OperatorsTreeStorageAddress = PutToTempStorage(Tree, UUID);
	
EndProcedure

&AtServer
Procedure WhenChangingFlagItIsMandatoryToFillIn(OwnerOfProps, TableRowID_)
	
	CollectionOfPropsForControl = Catalogs.ItemKinds.CollectionOfPropsForControl(Object, OwnerOfProps);
	
	CurrentData = CollectionOfPropsForControl.FindByID(TableRowID_);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.RequiredToFill Then
		CurrentData.DisplayWhenCreated = True;
	EndIf;
	
	If CurrentData.IsAddlAttribute Then
		CurrentData.DisplayAvailabilityOnCreation = Not CurrentData.RequiredToFill;
	Else
		CurrentData.DisplayAvailabilityOnCreation = Catalogs.ItemKinds.YouCanChangeSettingsForDisplayingProps(Object,
																																	CurrentData,
																																	OwnerOfProps);
	EndIf;
	
EndProcedure

// The procedure fills in the required table of additional details (information).
//
// Parameters:
//	Table - FormDataCollection - Add-on tableof the details (information).
//	
//	SetOfPropertiesAndProps - CatalogRef.AdditionalAttributesAndInfoSets - Link to the owner element 
//	of the add set.of the details (information).
//	
//	SetOfCommonPropertiesAndProps - CatalogRef.AdditionalAttributesAndInfoSets - Link to the owner element 
//	of a set of shared add-ons.of the details (information).
//	
//	DataType - String - Type of data to be filled in. 
//	Accepts the values: "Details", "Information".
//	
//	OnlyCommonProperties -Boolean - If the parameter is set to True, then not the entire table is pre-cleared,
//	but only the list of General add-ons.of the details (information). This is done in order to avoid 
//	losing the entered data about non-shared add-ons.details (information) in the form.
//	Default: Lie.
&AtServer
Procedure FillInListOfPropertiesAndDetailsOfTable(Table, SetOfPropertiesAndProps, SetOfCommonPropertiesAndProps, 
	DataType, OnlyCommonProperties = False)
	
	// If you need to re-fill the properties, then check that a reference to a set of properties has been passed.
	If Not OnlyCommonProperties Then
		If Not ValueIsFilled(SetOfPropertiesAndProps) Then
			Return;
		EndIf;
	Else
		// If you need to re-fill only COMMON properties, then check that a reference to a set of COMMON properties has been passed.
		If Not ValueIsFilled(SetOfCommonPropertiesAndProps) Then
			Return;
		EndIf;
	EndIf;
	
	If OnlyCommonProperties Then
		
		// Delete only the rows of common properties from the table.
		UBound = Table.Count() - 1;
		
		For OBRIndex = 0 To UBound Do
			
			TableRow = Table[UBound - OBRIndex];
			
			If TableRow.CommonProperty Then
				Table.Delete(TableRow);
			EndIf;
			
		EndDo;
		
	Else
		
		Table.Clear();
		
	EndIf;
	
	If DataType = "Attributes" Then
		TSName = "AdditionalAttributes";
	ElsIf DataType = "InformationRecords" Then
		TSName = "AdditionalInfo";
	EndIf;
	
	// Get a list of additional details from a set of properties, and additional details from a set of general properties.
	Query = New Query;
	
	Query.SetParameter("SetOfCommonProperties", SetOfCommonPropertiesAndProps);
	
	If OnlyCommonProperties Then
	
		Query.Text = 
		"SELECT
		|	GeneralAdditionalInformation.Property AS Property,
		|	GeneralAdditionalInformation.Property.Title AS AttributeRepresentation,
		|	TRUE AS CommonProperty,
		|	GeneralAdditionalInformation.LineNumber AS RowNumberToSort,
		|	CASE WHEN GeneralAdditionalInformation.DeletionMark THEN 4 ELSE 1 END AS PictureIndex
		|FROM
		|	&TabPart AS GeneralAdditionalInformation
		|WHERE
		|	GeneralAdditionalInformation.Ref = &SetOfCommonProperties";
		
	Else
		
		Query.SetParameter("PropertiesSet", SetOfPropertiesAndProps);
		
		Query.Text = 
		"SELECT
		|	AdditionalInformation_.Property AS Property,
		|	AdditionalInformation_.Property.Title AS AttributeRepresentation,
		|	FALSE AS CommonProperty,
		|	AdditionalInformation_.LineNumber AS RowNumberToSort,
		|	CASE WHEN AdditionalInformation_.DeletionMark THEN 4 ELSE 1 END AS PictureIndex
		|FROM
		|	&TabPart AS AdditionalInformation_
		|WHERE
		|	AdditionalInformation_.Ref = &PropertiesSet
		|
		|UNION ALL
		|
		|SELECT
		|	GeneralAdditionalInformation.Property,
		|	GeneralAdditionalInformation.Property.Title,
		|	TRUE,
		|	GeneralAdditionalInformation.LineNumber,
		|	CASE WHEN GeneralAdditionalInformation.DeletionMark THEN 4 ELSE 1 END
		|FROM
		|	&TabPart AS GeneralAdditionalInformation
		|WHERE
		|	GeneralAdditionalInformation.Ref = &SetOfCommonProperties";
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&TabPart", "Catalog.AdditionalAttributesAndInfoSets." + TSName); 
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	TableOfAdditionalInformationDetails = QueryResult.Unload();
	
	If OnlyCommonProperties Then
		
		TableOfAdditionalInformationDetails.Sort("RowNumberToSort Asc");
		
		TableOfAllAdditionalInformationDetails = Table.Unload();
		TableOfAllAdditionalInformationDetails.Clear();
		
		CommonClientServer.SupplementTable(TableOfAdditionalInformationDetails, TableOfAllAdditionalInformationDetails);
		CommonClientServer.SupplementTable(Table, TableOfAllAdditionalInformationDetails);
		
		Table.Load(TableOfAllAdditionalInformationDetails);
		
	Else
		
		TableOfAdditionalInformationDetails.Sort("CommonProperty Desc, RowNumberToSort Asc");
		
		Table.Load(TableOfAdditionalInformationDetails);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInListsOfAdditionalInformationDetails()
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	SetOfCommonProperties				= PropertyManager.PropertiesSetByName("Catalog_Products_Overall");
	SetOfCommonPropertiesCharacteristics	= PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall");
	SetOfCommonSeriesProperties			= PropertyManager.PropertiesSetByName("Catalog_ItemsBatches_Overall");
	
	FillInListOfPropertiesAndDetailsOfTable(
		TableOfAdditionalAttributesOfProducts,
		Object.PropertiesSet,
		SetOfCommonProperties,
		"Attributes",
		EditingCommonAttributesOfInformation);
	
	FillInListOfPropertiesAndDetailsOfTable(
		TableOfAdditionalCharacteristicsAttributes,
		Object.CharacteristicsPropertySet,
		SetOfCommonPropertiesCharacteristics,
		"Attributes",
		EditingCommonAttributesOfInformation);
	
	FillInListOfPropertiesAndDetailsOfTable(
		TableOfAdditionalSeriesAttributes,
		Object.BatchPropertySet,
		SetOfCommonSeriesProperties,
		"Attributes",
		EditingCommonAttributesOfInformation);
	
	FillInListOfPropertiesAndDetailsOfTable(
		TableOfAdditionalInformationOfTheItem,
		Object.PropertiesSet,
		SetOfCommonProperties,
		"InformationRecords",
		EditingCommonAttributesOfInformation);
	
	FillInListOfPropertiesAndDetailsOfTable(
		TableOfAdditionalCharacteristicsInformation,
		Object.CharacteristicsPropertySet,
		SetOfCommonPropertiesCharacteristics,
		"InformationRecords",
		EditingCommonAttributesOfInformation);
	
	FillInListOfPropertiesAndDetailsOfTable(
		TableOfAdditionalInformationOfTheSeries,
		Object.BatchPropertySet,
		SetOfCommonSeriesProperties,
		"InformationRecords",
		EditingCommonAttributesOfInformation);
	
EndProcedure

&AtServer
Procedure SetAccessibilitySettingsOfPropsFieldsForControl(StringOfPropsForControl, AvailabilityConditions)
	
	StringOfPropsForControl.MandatoryFillingOfAvailability = (Not AvailabilityConditions.TypeOfPropsBoolean
																		And Not AvailabilityConditions.RequiredToFill);
	
	If AvailabilityConditions.OnlyBeSureToFill Then
		Return;
	EndIf;
	
	StringOfPropsForControl.AvailabilityUnique = (Not AvailabilityConditions.ThisIsUnusedTypeForControl);
	StringOfPropsForControl.DisplayAvailabilityOnCreation = (Not StringOfPropsForControl.RequiredToFill
																		And Not AvailabilityConditions.RequiredToFill);
	
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	ReadOnly = Not ThereIsTheRightToEdit;
	
	ObjectToFillIn = Object;
	ProductsLocalization.AddFormObject(ThisObject, ObjectToFillIn);
	VisibilityOfElements = Catalogs.Products.UsingElements(ObjectToFillIn, False, False);
	ProductsLocalization.RestoreFormObject(ThisObject, ObjectToFillIn);
	
	For Each VisibilityItem In VisibilityOfElements Do
		
		If Items.Find(VisibilityItem.Key) <> Undefined Then
			Items[VisibilityItem.Key].Visible = VisibilityItem.Value;
		EndIf;
		
	EndDo;

	AttributesValues = Catalogs.ItemKinds.ValuesOfDetailsAreStrictlyFilledInBySpecificsOfAccounting(KeyTypesOfProductsBeforeChange);
	If AttributesValues <> Undefined Then
		For Each KeyValue In AttributesValues Do
			If Items.Find(KeyValue.Key) <> Undefined Then
				Items[KeyValue.Key].Enabled = True;
			EndIf;
		EndDo
	EndIf;
	
	#Region FOValues
	
	If Not UseSeveralWarehouses Then
		
		For Each RowData In Object.BatchAccountingPolicies Do
			If TypeOf(RowData.Warehouse) = Type("CatalogRef.Warehouses") Then
				Warehouse = RowData.Warehouse;
				BatchAccountingPolicy = RowData.BatchAccountingPolicy;
				Break;
			EndIf; 
		EndDo;
		
		Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	EndIf;
	
	UseAdditionalAttributesAndInfo = GetFunctionalOption("UseAdditionalAttributesAndInfo");
	UseWarehouseManagemantSystemForGoodsSurplusesShortages = GetFunctionalOption(
		"UseWarehouseManagemantSystemForGoodsSurplusesShortages", New Structure("Warehouse", Warehouse));
	UseAgentServiceSale            = GetFunctionalOption("UseAgentServiceSale");
	UseProductCategories                = GetFunctionalOption("UseProductCategories"); 
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemsBatch          = GetFunctionalOption("UseItemsBatch");
	ControlUniqueness             = GetFunctionalOption("ControlItemUniquenessByCombinationValuesAttributes");
	UseWarehouseManagementSystem             = GetFunctionalOption("UseWarehouseManagementSystem");
	BaseVersion                          = GetFunctionalOption("BaseVersion");
	
	#EndRegion
	
	#Region SeveralSpecies
	SeveralKindsOfProducts = GetFunctionalOption("UseMultipleKindsOfProducts");
	
	Items.QuickSelectionPanelSettingsPage.Visible 	= SeveralKindsOfProducts;
	Items.Parent.Visible 								= SeveralKindsOfProducts;
	Items.LongDesc.Visible 								= SeveralKindsOfProducts;
	Items.ItemsType.Visible 							= SeveralKindsOfProducts;
	Items.SubmenuGoTo.Visible							= SeveralKindsOfProducts;
	Items.IndentDecoration.Visible							= SeveralKindsOfProducts;
	Items.AccountingFeature.Visible 						= SeveralKindsOfProducts 
		And Enums.ItemAccountingFeatures.OneOfFeaturesIsIncluded(); // Availability of a choice at least in one type
		
	#EndRegion
	
	#Region ItemsType
	ThisIsAProduct = (Object.ItemsType = Enums.ItemsTypes.OwnGoods);
	ThisIsMultiTurnContainer = (Object.ItemsType = Enums.ItemsTypes.ReusablePackage);
	ThisIsWork = (Object.ItemsType = Enums.ItemsTypes.Work_5);
	IsService = (Object.ItemsType = Enums.ItemsTypes.OperationService);
	IsRecordsSet = (Object.ItemsType = Enums.ItemsTypes.Set);
	
	Items.ItemsType.ToolTip = Enums.ItemsTypes.ProductTypeHint(Object.ItemsType);
	OneOfFeaturesIsIncluded = Enums.ItemAccountingFeatures.OneOfFeaturesIsIncluded(Object.ItemsType);
	If Not ValueIsFilled(Object.ItemsType) Then
		HintAccountingFeatures = NStr("vi = 'Được điền sau khi chọn dạng mặt hàng';
										|ru = 'Заполняется после выбора типа номенклатуры';
										|en = 'Populated after the item type is selected'; fa = 'Populated after the item type is selected';
										|it = 'Заполняется после выбора типа номенклатуры';
										|pl = 'Populated after the item type is selected';
										|tr = 'Öğe tipi seçildikten sonra doldurulur'");
	ElsIf Not OneOfFeaturesIsIncluded And Not IsService Then
		HintAccountingFeatures = NStr("vi = 'Không có đối với dạng này';
										|ru = 'Отсутствуют для заданного типа';
										|en = 'Not available for the specified type'; fa = 'Not available for the specified type';
										|it = 'Отсутствуют для заданного типа';
										|pl = 'Not available for the specified type';
										|tr = 'Belirtilen tür bulunmamaktadır'");
	ElsIf Object.AccountingFeature = Enums.ItemAccountingFeatures.WithoutAccountingFeatures Then
		HintAccountingFeatures = NStr("vi = 'Không có tính năng kế toán';
										|ru = 'Без особенности учета';
										|en = 'Without accounting feature'; fa = 'Without accounting feature';
										|it = 'Без особенности учета';
										|pl = 'Without accounting feature';
										|tr = 'Muhasebe özelliği olmadan'");
	Else
		HintAccountingFeatures = Enums.ItemAccountingFeatures.HintOnAccountingForProducts(Object.AccountingFeature);
	EndIf;
	Items.AccountingFeature.ToolTip = HintAccountingFeatures;
	
	Items.AccountingFeature.Enabled = OneOfFeaturesIsIncluded;
	
	UseCharacteristicsFromAnotherView = (Object.UseVariants
										= PredefinedValue("Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind"));
										
	#EndRegion
		
	#Region RegistrationOfServices
	Items.SaleRegistrationOption.Visible = (ThisIsAProduct
														And GetFunctionalOption("UseDeedsOfTransfer")
														And (Object.AccountingFeature = Enums.ItemAccountingFeatures.WithoutAccountingFeatures
															Or Not ValueIsFilled(Object.AccountingFeature)))
													Or IsService
													Or ThisIsWork;
	
	Items.DecorationSaleIsBeingMadeOut.Visible = Items.SaleRegistrationOption.Visible;
	Items.DecorationSellingIsPerformedThePlug.Visible = Items.SaleRegistrationOption.Visible;
	
	ListOfDesignChoices = Items.SaleRegistrationOption.ChoiceList;
	ListOfDesignChoices.Clear();
	
	ListOfDesignChoices.Add(Enums.SalesRegistrationOptions.CustomerInvoice);
	If IsService Or ThisIsWork Then
		ListOfDesignChoices.Add(Enums.SalesRegistrationOptions.CustomerInvoiceServices);
	EndIf;
	
	If GetFunctionalOption("UseDeedsOfTransfer")
		And Not ThisIsMultiTurnContainer Then
		ListOfDesignChoices.Add(Enums.SalesRegistrationOptions.DeedOfTransfer);
	EndIf;
	#EndRegion
	
	#Region Set
	Items.SetPricingOption.Visible = IsRecordsSet;
	Items.PresentationOptionInPrintForms.Visible = IsRecordsSet;
	#EndRegion
	
	#Region ProductCategories
	Items.DecorationProductCategories.Visible = UseProductCategories;
	Items.ConfigureProductCategories.Visible = UseProductCategories;
	Items.ProductCategoryOwner.Visible = UseProductCategories;
	FormInscriptionByTypeOfOwner("OfProductCategories");
	#EndRegion
	
	#Region Characteristics
	Items.UseCharacteristics.Visible = UseItemVariants;
	Items.UseVariants.Visible = UseItemVariants;
	
	Items.UseVariants.Enabled = Object.UseCharacteristics;
	
	Items.AttributesOfItemVariantQuickFilter.Visible = UseItemVariants
													And Object.UseCharacteristics
													And Not UseCharacteristicsFromAnotherView;
	Items.TableOfAdditionalCharacteristicsAttributes.Visible = UseItemVariants
													And Object.UseCharacteristics
													And Not UseCharacteristicsFromAnotherView;
	Items.TableOfAdditionalCharacteristicsInformation.Visible = UseItemVariants
													And Object.UseCharacteristics
													And Not UseCharacteristicsFromAnotherView;
	Items.TableOfAdditionalCharacteristicsInformation.Visible = UseItemVariants
													And Object.UseCharacteristics
													And Not UseCharacteristicsFromAnotherView;
	Items.GroupDetailsForMonitoringCharacteristics.Visible = UseItemVariants
													And Object.UseCharacteristics
													And Not UseCharacteristicsFromAnotherView;
	Items.GroupCharacteristicNameTemplates.Visible = UseItemVariants
													And Object.UseCharacteristics
													And Not UseCharacteristicsFromAnotherView;
	
	Items.DecorationIndentTemplatesForFeatureNames.Visible = Items.GroupCharacteristicNameTemplates.Visible;												
	Items.ItemVariantsOwner.Visible = UseItemVariants;
	
	Items.ShowTheDetailsForMonitoringTheCharacteristics.Visible = UseItemVariants
													And Object.UseCharacteristics
													And Not UseCharacteristicsFromAnotherView;
	FormInscriptionByTypeOfOwner("Features");
	#EndRegion
	
	#Region SetOfSeries
	
	SelectionParametersForSeriesAccountingPolicies = ProductsClientServer.SelectionParametersForSeriesAccountingPolicies();
	FillPropertyValues(SelectionParametersForSeriesAccountingPolicies, Object);
	SelectionOfSeriesAccountingPolicies = ProductsServer.SelectionOfSeriesAccountingPoliciesByParameters(SelectionParametersForSeriesAccountingPolicies);
	AccountingOfBalancesBySeriesIsMandatory = SelectionOfSeriesAccountingPolicies.Property("AccountForRemainingSeries")
										And SelectionOfSeriesAccountingPolicies.AccountForRemainingSeries;
										
	PossibleSeriesAccountingPolicies = Undefined;
	PolicySelection = Undefined;
	If SelectionOfSeriesAccountingPolicies.Property("PolicyType", PossibleSeriesAccountingPolicies) Then
		
		If TypeOf(PossibleSeriesAccountingPolicies) = Type("Array")
			Or TypeOf(PossibleSeriesAccountingPolicies) = Type("FixedArray") Then
			
			If PossibleSeriesAccountingPolicies.Count() = 1 Then
				If ValueIsFilled(PossibleSeriesAccountingPolicies[0]) Then
					PolicySelection = PossibleSeriesAccountingPolicies[0];
				EndIf;
			ElsIf PossibleSeriesAccountingPolicies.Count() = 2 Then
				If ValueIsFilled(PossibleSeriesAccountingPolicies[0])
					And ValueIsFilled(PossibleSeriesAccountingPolicies[1]) Then
					PolicySelection = Undefined;
				ElsIf ValueIsFilled(PossibleSeriesAccountingPolicies[0]) Then
					PolicySelection = PossibleSeriesAccountingPolicies[0];
				ElsIf ValueIsFilled(PossibleSeriesAccountingPolicies[1]) Then
					PolicySelection = PossibleSeriesAccountingPolicies[1];
				EndIf;
			EndIf;
			
		ElsIf TypeOf(PossibleSeriesAccountingPolicies) = Type("EnumRef.TypesOfBatchSpecificationPolicies") Then
			PolicySelection = PossibleSeriesAccountingPolicies;
		EndIf;
		
	EndIf;
		
	AllowedToUseSeries = (ThisIsAProduct Or ThisIsMultiTurnContainer)
									And UseItemsBatch
									And (AccountingOfBalancesBySeriesIsMandatory
												 And (UseWarehouseManagementSystem
												 	And UseSeveralWarehouses
													Or UseWarehouseManagemantSystemForGoodsSurplusesShortages)
										Or Not AccountingOfBalancesBySeriesIsMandatory);
	
	Items.KeepAccountingByBatch.Visible = AllowedToUseSeries;
													
	Items.OptionOfSeriesSettings.Visible = AllowedToUseSeries;
	Items.OptionOfSeriesSettings.Enabled = Object.KeepAccountingByBatch;
	
	Items.LabelConfiguringTheUseOfSeries.Visible = AllowedToUseSeries
													And Object.KeepAccountingByBatch
													And Not Object.BatchSettingsAreTakenFromOtherItemsKind;
	
	Items.BatchOwner.Visible = (ThisIsAProduct Or ThisIsMultiTurnContainer) And UseItemsBatch;
	
	VisibilityOfSeriesAccountingPolicyWarehousesDivisions = Object.KeepAccountingByBatch
													And AllowedToUseSeries
													And Not Object.BatchSettingsAreTakenFromOtherItemsKind
													And (UseSeveralWarehouses
														Or UseProduction);
	VisibilityOfOneWarehouseSeriesAccountingPolicy           = Object.KeepAccountingByBatch
													And AllowedToUseSeries
													And Not Object.BatchSettingsAreTakenFromOtherItemsKind
													And Not (UseSeveralWarehouses
															Or UseProduction);
	
	Items.LabelBatchAccountingPolicy2.Visible          = VisibilityOfSeriesAccountingPolicyWarehousesDivisions;
	Items.BatchAccountingPolicy2.Visible                 = VisibilityOfSeriesAccountingPolicyWarehousesDivisions;
	Items.BatchAccountingPolicy2.AutoMarkIncomplete = VisibilityOfSeriesAccountingPolicyWarehousesDivisions;
	
	Items.ThereAreIndividualSettingsOfSeriesAccountingPolicy.Visible = VisibilityOfSeriesAccountingPolicyWarehousesDivisions;
	
	Items.GroupLabelSeriesAccountingPolicy.Visible    = VisibilityOfOneWarehouseSeriesAccountingPolicy;
	Items.BatchAccountingPolicy.AutoMarkIncomplete = VisibilityOfOneWarehouseSeriesAccountingPolicy;
	
	UseTransferForStorage = GetFunctionalOption(
		"UseTransferToCustodyWithRightOfSale");
	UseUninvoicedDeliveries = GetFunctionalOption("UseUninvoicedDeliveries");
	UseGoodsInTransitFromVendors  = GetFunctionalOption("UseGoodsInTransitFromVendors");
	UseProductionByThirdParty2_5  = GetFunctionalOption("UseProductionByThirdParty2_5");
	If ValueIsFilled(PolicySelection) Then
		// Formation of a warning text on the use of reference series
		ThereIsSelectionByPolicyType = New Array;
		If ValueIsFilled(Object.AccountingFeature)
			And Object.AccountingFeature <> Enums.ItemAccountingFeatures.WithoutAccountingFeatures Then
			
			SelectionByAccountingFeaturesDescription = New FormattedString(NStr("vi = 'Đối với dạng mặt hàng có đặc điểm kế toán ""%AccountingFeature%"", có thể sử dụng';
																				|ru = 'Для вида номенклатуры с особенностью учета ""%AccountingFeature%"" возможно использование';
																				|en = 'For the item kind with the accounting feature ""%AccountingFeature%"", you can use'; fa = 'For the item kind with the accounting feature ""%AccountingFeature%"", you can use';
																				|it = 'Per il tipo di articolo con la caratteristica della contabilità ""%AccountingFeature%"" è possibile l''utilizzo';
																				|pl = 'Dla rodzaju nomenklatury z cechą ewidencji ""%AccountingFeature%"" możliwe jest korzystanie z';
																				|tr = '""%AccountingFeature%"" muhasebe özelliğine sahip bir tanım türü için kullanılabilir'") + Chars.NBSp,
											,
											StyleColors.NoteText);
			SelectionByAccountingFeaturesDescription = StrReplace(SelectionByAccountingFeaturesDescription, "%AccountingFeature%", Object.AccountingFeature);
			ThereIsSelectionByPolicyType.Add(SelectionByAccountingFeaturesDescription);
		ElsIf Object.BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
			ThereIsSelectionByPolicyType.Add(New FormattedString(
											NStr("vi = 'Đối với sê-ri xác định một phiên bản sản phẩm, có thể sử dụng';
												|ru = 'Для серий, идентифицирующих экземпляр товара, возможно использование';
												|en = 'For the batch identifying a product unit, you can use'; fa = 'For the batch identifying a product unit, you can use';
												|it = 'Per le serie che identificano l''esemplare della merce è possibile l''utilizzo';
												|pl = 'Dla serii identyfikujących egzemplarz towaru, możliwe jest korzystanie z';
												|tr = 'Ürün örneğini tanımlayan partiler için kullanılabilir'") + Chars.NBSp,
											,
											StyleColors.NoteText));
		Else
			ThereIsSelectionByPolicyType.Add(New FormattedString(
											NStr("vi = 'Đối với dạng mặt hàng này, có thể sử dụng';
												|ru = 'Для этого вида номенклатуры возможно использование';
												|en = 'For this item kind, you can use'; fa = 'For this item kind, you can use';
												|it = 'Per questo tipo di articolo l''utilizzo è possibile l''utilizzo';
												|pl = 'Dla tego rodzaju nomenklatury możliwe jest korzystanie z';
												|tr = 'Bu türdeki öğe için kullanılabilir'") + Chars.NBSp,
											,
											StyleColors.NoteText));
		EndIf;
		
		ThereIsSelectionByPolicyType.Add(New FormattedString(
										NStr("vi = 'chỉ';
											|ru = 'только';
											|en = 'only'; fa = 'only';
											|it = 'solo';
											|pl = 'only';
											|tr = 'sadece'") + Chars.NBSp,
										New Font(, , True),
										StyleColors.ErrorNoteText));
		SelectionByPolicyTypeDescription     = NStr("vi = 'chính sách kế toán sê-ri có kiểu ""%TypeOfSeriesAccountingPolicy%""';
													|ru = 'политики учета серий с типом ""%TypeOfSeriesAccountingPolicy%""';
													|en = 'batch accounting policies with type ""%TypeOfSeriesAccountingPolicy%""'; fa = 'batch accounting policies with type ""%TypeOfSeriesAccountingPolicy%""';
													|it = 'della politica di registrazione delle serie con il tipo ""%TypeOfSeriesAccountingPolicy%""';
													|pl = 'polityki ewidencji serii o typie ""%TypeOfSeriesAccountingPolicy%""';
													|tr = '""%TypeOfSeriesAccountingPolicy%"" tipindeki toplu muhasebe politikaları'");
		SelectionByPolicyTypeDescription     = StrReplace(SelectionByPolicyTypeDescription, "%TypeOfSeriesAccountingPolicy%", String(PolicySelection));
		ThereIsSelectionByPolicyType.Add(New FormattedString(
										SelectionByPolicyTypeDescription,
										,
										StyleColors.NoteText));
		
		OperationDescriptions = New Array;
		
		If UseTransferForStorage Then
			OperationDescriptions.Add(NStr("vi = '""Ghi nhận sê-ri trong hàng hóa đã chuyển sang cất giữ""';
											|ru = '""Учет серий в переданных на хранение товарах""';
											|en = '""Batch accounting in deposited goods""'; fa = '""Batch accounting in deposited goods""';
											|it = '""Contabilità delle serie delle merci trasferite in deposito""';
											|pl = '„Serie księgowe w zdeponowanych towarach”';
											|tr = '""Depolama için transfer edilen ürünlerde parti muhasebesi""'"));
		EndIf;
		If UseProductionByThirdParty2_5 Then
			OperationDescriptions.Add(NStr("vi = '""Ghi nhận sê-ri hàng hóa đã chuyển giao cho bên nhận gia công""';
											|ru = '""Учет серий переданных переработчику товаров""';
											|en = '""Accounting of transferred to subcontractor goods batches""'; fa = '""Accounting of transferred to subcontractor goods batches""';
											|it = '""Contabilità serie articoli trasferiti all''elaboratore""';
											|pl = '""Ewidencja serii przekazanych przetwórcy towarów""';
											|tr = '""Fason üreticiye transfer edilen ürünlerin parti muhasebesi""'"));
		EndIf;
		If UseGoodsInTransitFromVendors Then
			OperationDescriptions.Add(NStr("vi = '""Ghi nhận hàng đi đường từ nhà cung cấp theo sê-ri""';
											|ru = '""Учет товаров в пути от поставщика по сериям""';
											|en = '""Batch accounting of goods in transit from vendor""'; fa = '""Batch accounting of goods in transit from vendor""';
											|it = '""Contabilità delle merci in transito dal fornitore per le serie""';
											|pl = '„Rachunkowość towarów w tranzycie od dostawcy według serii”';
											|tr = '""Parti bazında tedarikçiden taşınan ürünlerin muhasebesi""'"));
		EndIf;
		
		If UseUninvoicedDeliveries Then
			OperationDescriptions.Add(NStr("vi = '""Ghi nhận sê-ri khi giao hàng không có hóa đơn""';
											|ru = '""Учет серий в неотфактурованных поставках товаров""';
											|en = '""Batch accounting for goods received not invoiced""'; fa = '""Batch accounting for goods received not invoiced""';
											|it = '""Contabilità delle serie nelle forniture delle merci non fatturate""';
											|pl = '„Rachunkowość dla serii w dostawach towarów niezafakturowanych”';
											|tr = '""Faturasız ürün teslimatlarında parti muhasebesi""'"));
		EndIf;
		
		TextOfEnabledOptions = ?(OperationDescriptions.Count() = 0, "",
								?(OperationDescriptions.Count() > 1, NStr("vi = 'với hộp kiểm không đặt dấu';
																			|ru = 'со снятыми флагами';
																			|en = 'with cleared check boxes'; fa = 'with cleared check boxes';
																			|it = 'con i flag deselezionati';
																			|pl = 'z usuniętymi flagami';
																			|tr = 'bayrakları kaldırılmış halde'"),
								NStr("vi = 'với hộp kiểm không đặt dấu';
									|ru = 'со снятым флагом';
									|en = 'with cleared check box'; fa = 'with cleared check box';
									|it = 'con il flag deselezionato';
									|pl = 'z usuniętą flagą';
									|tr = 'bayrağı kaldırılmış halde'")));
		TextOfEnabledOptions = ?(ValueIsFilled(TextOfEnabledOptions),
								TextOfEnabledOptions + Chars.NBSp + StrConcat(OperationDescriptions, "," + Chars.NBSp) + ".",
								"");
		
		ThereIsSelectionByPolicyType.Add(New FormattedString(
										?(ValueIsFilled(TextOfEnabledOptions), Chars.NBSp + TextOfEnabledOptions, "."),
										,
										StyleColors.NoteText));
		
		Items.TheLabelHasASelectionByPolicyType.Title = New FormattedString(ThereIsSelectionByPolicyType);
		
		Items.TheLabelHasASelectionByPolicyType.Visible = 
				ValueIsFilled(PolicySelection)
				And Object.KeepAccountingByBatch
				And AllowedToUseSeries
				And Not Object.BatchSettingsAreTakenFromOtherItemsKind;
	Else
		Items.TheLabelHasASelectionByPolicyType.Visible = False;
	EndIf;
	
	ThereIsSelectionPolicyForAccountingBalancesBySeries = UseItemsBatch
												And AccountingOfBalancesBySeriesIsMandatory
												And (Object.KeepAccountingByBatch
													Or Not UseWarehouseManagementSystem)
												And Not Object.BatchSettingsAreTakenFromOtherItemsKind;
	
	Items.LabelSelectionOfAPolicyForAccountingForBalancesBySeriesOneWarehouseWithoutOrder.Visible = ThereIsSelectionPolicyForAccountingBalancesBySeries
																			And Not UseSeveralWarehouses
																			And Not UseWarehouseManagemantSystemForGoodsSurplusesShortages
																			And Not BaseVersion;
	Items.TheInscriptionThereIsASelectionPolicyForAccountingForBalancesBySeriesThereAreNoOrderWarehouses.Visible = ThereIsSelectionPolicyForAccountingBalancesBySeries
			 																And UseSeveralWarehouses
																			And Not UseWarehouseManagementSystem
																			And Not BaseVersion;
	Items.TheLabelHasASelectionPolicyForAccountingForBalancesBySeriesThereAreOrderWarehouses.Visible = ThereIsSelectionPolicyForAccountingBalancesBySeries
																			And Not Items.LabelSelectionOfAPolicyForAccountingForBalancesBySeriesOneWarehouseWithoutOrder.Visible
																			And Not Items.TheInscriptionThereIsASelectionPolicyForAccountingForBalancesBySeriesThereAreNoOrderWarehouses.Visible;
			
	Items.LabelUsingTheBatchAccountingPolicyWhenTheExpirationDateIsDisabled.Visible = 
			Not Object.UseShelfLifeOnBatchRegistration
			And Object.KeepAccountingByBatch
			And AllowedToUseSeries
			And Not Object.BatchSettingsAreTakenFromOtherItemsKind
			And Object.BatchUsageSettings = Enums.ItemsBatchUsageSettings.GoodsLot;
			
	Items.LabelAccountingPolicyHintOrderWarehousesDisabled.Visible = AllowedToUseSeries
																	And Object.KeepAccountingByBatch
																	And UseSeveralWarehouses
																	And Not UseWarehouseManagementSystem
																	And Not Object.BatchSettingsAreTakenFromOtherItemsKind
																	And Not AccountingOfBalancesBySeriesIsMandatory
																	And Not BaseVersion;
	
	Items.LabelHintOfTheAccountingPolicyOfTheSeriesOneWarehouse.Visible = AllowedToUseSeries
																	And Object.KeepAccountingByBatch
																	And Not UseSeveralWarehouses
																	And Not UseWarehouseManagemantSystemForGoodsSurplusesShortages
																	And Not Object.BatchSettingsAreTakenFromOtherItemsKind
																	And Not AccountingOfBalancesBySeriesIsMandatory
																	And Not BaseVersion;
	
	Items.GroupSeriesAccountingPolicies.Visible = AllowedToUseSeries
											And Object.KeepAccountingByBatch
											And (UseSeveralWarehouses
												Or UseProduction)
											And Not Object.BatchSettingsAreTakenFromOtherItemsKind
											And ThereAreIndividualSettingsOfSeriesAccountingPolicy;
	
	InTSIndicateWarehousesAndDivisions =  UseSeveralWarehouses And UseProduction;
	
	Items.BatchAccountingPoliciesAddTheWarehouseToTheSeriesAccountingPolicies.Visible = InTSIndicateWarehousesAndDivisions;
	Items.BatchAccountingPoliciesAddTheDepartmentToTheSeriesAccountingPolicies.Visible = InTSIndicateWarehousesAndDivisions;
	
	Items.BatchAccountingPoliciesAdd.Visible = Not InTSIndicateWarehousesAndDivisions;
	
	If InTSIndicateWarehousesAndDivisions Then
		WarehouseSeriesAccountingPolicies       = NStr("vi = 'Kho bãi hoặc bộ phận';
														|ru = 'Склад или подразделение';
														|en = 'Warehouse or business unit'; fa = 'انبار یا واحد تجاری';
														|it = 'Magazzino o reparto';
														|pl = 'Magazyn lub dział';
														|tr = 'Ambar veya departman'");
		BatchAccountingPoliciesWarehouseHint       = NStr("vi = 'Kho bãi hoặc bộ phận hạch toán theo sê-ri';
															|ru = 'Склад или подразделение, в котором ведется учет по сериям';
															|en = 'Warehouse or business unit where accounting is performed by batch'; fa = 'انبار یا واحد تجاری که حسابداری در آن بر اساس بچ انجام می‌شود';
															|it = 'Magazzino o reparto, in cui viene tenuta la contabilità per serie';
															|pl = 'Magazyn lub dział, w którym jest prowadzona ewidencja serii';
															|tr = 'Parti muhasebenin tutulduğu ambar veya departman'");
		SelectionOfTSRowsSeriesAccountingPolicy         = New FixedStructure("CorrespondsToThePolicyByDefault", False);
		AccountingPoliciesForWarehouseTypeSeries = New TypeDescription("CatalogRef.Warehouses,CatalogRef.BusinessStructure");
		SeriesAccountingPolicyHint
			= NStr("vi = 'Được sử dụng như một chính sách chung cho tất cả các kho và bộ phận sản xuất: sẽ đặt mặc định cho các kho bãi và bộ phận sản xuất mới.';
					|ru = 'Будет использована как общая политика для всех складов и производственных подразделений: будет устанавливаться по умолчанию для новых складов и производственных подразделений.';
					|en = 'It will be set as a common policy for all warehouses and production business units; it will be enabled by default for new warehouses and production business units.'; fa = 'It will be set as a common policy for all warehouses and production business units; it will be enabled by default for new warehouses and production business units.';
					|it = 'Verrà utilizzata, come politica comune per tutti i magazzini e i reparti produttivi: verrà stabilita come impostazione predefinita per i nuovi magazzini e reparti produttivi.';
					|pl = 'Będzie wykorzystana jako wspólna polityka dla wszystkich magazynów i działów produkcyjnych; będzie ustawiana domyślnie dla nowych magazynów i działów produkcyjnych.';
					|tr = 'Tüm ambarlar ve üretim departmanları için genel politika olarak kullanılacaktır: Yeni ambarlar ve üretim departmanları için varsayılan olarak ayarlanacaktır.'");
	ElsIf UseSeveralWarehouses Then
		WarehouseSeriesAccountingPolicies       = NStr("vi = 'Kho bãi';
														|ru = 'Склад';
														|en = 'Warehouse'; fa = 'Warehouse';
														|it = 'Magazzino';
														|pl = 'Magazyn';
														|tr = 'Ambar'");
		BatchAccountingPoliciesWarehouseHint       = NStr("vi = 'Kho bãi hạch toán theo sê-ri';
															|ru = 'Склад, в котором ведется учет по сериям';
															|en = 'Warehouse where accounting is performed by batch'; fa = 'Warehouse where accounting is performed by batch';
															|it = 'Magazzino in cui viene tenuta una contabilità per serie';
															|pl = 'Magazyn, w którym jest prowadzona ewidencja serii';
															|tr = 'Parti muhasebenin tutulduğu ambar'");
		AccountingPoliciesForWarehouseTypeSeries = New TypeDescription("CatalogRef.Warehouses");
		SelectionOfTSRowsSeriesAccountingPolicy         = New FixedStructure("CorrespondsToThePolicyByDefault, ThisIsAWarehousePolicy", False, True);
		SeriesAccountingPolicyHint
			= NStr("vi = 'Được sử dụng như một chính sách chung cho tất cả các kho; sẽ đặt mặc định cho các kho mới.';
					|ru = 'Будет использована как общая политика для всех складов; будет устанавливаться по умолчанию для новых складов.';
					|en = 'It will be set as a common policy for all warehouses; it will be enabled by default for new warehouses.'; fa = 'It will be set as a common policy for all warehouses; it will be enabled by default for new warehouses.';
					|it = 'Verrà utilizzata, come politica comune per tutti i magazzini; verrà usata come impostazione predefinita per tutti i nuovi magazzini.';
					|pl = 'Będzie wykorzystywana jako wspólna polityka dla wszystkich magazynów; będzie ustawiana domyślnie dla nowych magazynów.';
					|tr = 'Tüm ambarlar için genel politika olarak kullanılacaktır: Yeni ambarlar için varsayılan olarak ayarlanacaktır.'");
	Else
		WarehouseSeriesAccountingPolicies       = NStr("vi = 'Bộ phận';
														|ru = 'Подразделение';
														|en = 'Business unit'; fa = 'Business unit';
														|it = 'Reparto';
														|pl = 'Dział';
														|tr = 'Departman'");
		BatchAccountingPoliciesWarehouseHint       = NStr("vi = 'Bộ phận hạch toán theo sê-ri';
															|ru = 'Подразделение, в котором ведется учет по сериям';
															|en = 'Business unit where accounting is performed by batch'; fa = 'Business unit where accounting is performed by batch';
															|it = 'Reparto in cui viene tenuta la contabilità per serie';
															|pl = 'Dział, w którym jest prowadzona ewidencja serii';
															|tr = 'Parti muhasebenin tutulduğu departman'");
		AccountingPoliciesForWarehouseTypeSeries = New TypeDescription("CatalogRef.BusinessStructure");
		SelectionOfTSRowsSeriesAccountingPolicy         = New FixedStructure("CorrespondsToThePolicyByDefault, ThisIsAWarehousePolicy", False, False);
		SeriesAccountingPolicyHint
			= NStr("vi = 'Được sử dụng như một chính sách chung cho tất cả các bộ phận sản xuất; sẽ được thiết lập mặc định cho các bộ phận sản xuất mới.';
					|ru = 'Будет использована как общая политика для всех производственных подразделений; будет устанавливаться по умолчанию для новых производственных подразделений.';
					|en = 'It will be set as a common policy for all production business units; it will be enabled by default for new production business units.'; fa = 'It will be set as a common policy for all production business units; it will be enabled by default for new production business units.';
					|it = 'Verrà utilizzata come politica comune per tutti i reparti produttivi; verrà usata come impostazione predefinita per nuovi reparti produttivi.';
					|pl = 'Będzie wykorzystywana jako wspólna polityka dla wszystkich działów produkcyjnych; będzie ustawiana domyślnie dla nowych działów produkcyjnych.';
					|tr = 'Tüm üretim departmanları için genel politika olarak kullanılacaktır: Yeni üretim departmanları için varsayılan olarak ayarlanacaktır.'");
	EndIf;
	Items.BatchAccountingPoliciesWarehouse.Title       = WarehouseSeriesAccountingPolicies;
	Items.BatchAccountingPoliciesWarehouse.ToolTip       = BatchAccountingPoliciesWarehouseHint;
	Items.BatchAccountingPoliciesWarehouse.TypeRestriction = AccountingPoliciesForWarehouseTypeSeries;
	Items.BatchAccountingPolicies.RowFilter           = SelectionOfTSRowsSeriesAccountingPolicy;
	Items.LabelBatchAccountingPolicy2.ToolTip    = SeriesAccountingPolicyHint;
	
	Items.GroupDetailsForSeriesControl.Visible = AllowedToUseSeries
													And Object.KeepAccountingByBatch
													And Not Object.BatchSettingsAreTakenFromOtherItemsKind;
	
	Items.GroupTemplatesForSeriesNames.Visible = AllowedToUseSeries
													And Object.KeepAccountingByBatch
													And Not Object.BatchSettingsAreTakenFromOtherItemsKind;
	
	Items.DecorationAndTemplatesForSeriesTitles.Visible = Items.GroupTemplatesForSeriesNames.Visible;
	
	Items.TableOfAdditionalSeriesAttributes.Visible = AllowedToUseSeries
													And Object.KeepAccountingByBatch
													And Not Object.BatchSettingsAreTakenFromOtherItemsKind;
	
	Items.TableOfAdditionalInformationOfTheSeries.Visible = AllowedToUseSeries
													And Object.KeepAccountingByBatch
													And Not Object.BatchSettingsAreTakenFromOtherItemsKind;
	
	Items.LabelTemplateBatches.Visible = AllowedToUseSeries
													And Object.KeepAccountingByBatch;
	
	Items.ShowDetailsForSeriesControl.Visible = AllowedToUseSeries
													And Object.KeepAccountingByBatch
													And Not Object.BatchSettingsAreTakenFromOtherItemsKind;
	
	Items.ShowAttributesForProductsControl.Visible = (AllowedToUseSeries
																		And Object.KeepAccountingByBatch
																		And Not Object.BatchSettingsAreTakenFromOtherItemsKind)
																	Or (UseItemVariants
																			And Object.UseCharacteristics
																			And Not UseCharacteristicsFromAnotherView);
																			
	FormInscriptionByTypeOfOwner("Series_");
	
	#Region LabelConfiguringTheUseOfSeries
	
	If Items.LabelConfiguringTheUseOfSeries.Visible Then
		
		YouNeedToConfigureBankingDetails = Not Items.KeepAccountingByBatch.ReadOnly;
		
		Items.CollapsibleGroupForConfiguringTheCompositionOfSeriesDetails.Visible = YouNeedToConfigureBankingDetails;
		
		ArrayOfTexts = New Array;
		
		ArrayOfTexts.Add(NStr("vi = 'Sê-ri xác định:';
								|ru = 'Серия идентифицирует:';
								|en = 'Specify batch for:'; fa = 'Specify batch for:';
								|it = 'Serie identifica:';
								|pl = 'Seria identyfikuje:';
								|tr = 'Partinin tanımladığı:'"));
		ArrayOfTexts.Add(Chars.NBSp);
		ArrayOfTexts.Add(New FormattedString(String(Object.BatchUsageSettings),
								New Font(,,True)));
		
		ArrayOfTexts.Add(" (");
		
		ArrayOfDetailsDescriptions = New Array;
		
		SeriesUseSettings = Catalogs.ItemKinds.SeriesUseSettings(Object);
		For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
			If LongDesc.SettingName = "UseRFIDTags" Then
				
				If LongDesc.AttributeName = "RFIDTID"
					And LongDesc.Use Then
					ArrayOfDetailsDescriptions.Add(NStr("vi = 'nhãn RFID';
														|ru = 'RFID-метка';
														|en = 'RFID tag'; fa = 'برچسب RFID';
														|it = 'Contrassegno-RIFD';
														|pl = 'RFID tag';
														|tr = 'RFID etiketi'"));
				EndIf;
				
			ElsIf LongDesc.Use Then
				
				If Not IsBlankString(LongDesc.PresentationOfFormatStringInHeader) Then
					
					AttributeRepresentation = NStr("vi = '%AttributeRepresentation% (%AccuracyOfIndication%)';
													|ru = '%AttributeRepresentation% (%AccuracyOfIndication%)';
													|en = '%AttributeRepresentation% (%AccuracyOfIndication%)'; fa = '%AttributeRepresentation% (%AccuracyOfIndication%)';
													|it = '%AttributeRepresentation% (%AccuracyOfIndication%)';
													|pl = '%AttributeRepresentation% (%AccuracyOfIndication%)';
													|tr = '%AttributeRepresentation% (%AccuracyOfIndication%)'");
					AttributeRepresentation = StrReplace(AttributeRepresentation, "%AttributeRepresentation%", LongDesc.AttributeRepresentation);
					AttributeRepresentation = StrReplace(AttributeRepresentation, "%AccuracyOfIndication%", LongDesc.PresentationOfFormatStringInHeader);
					
				Else
					AttributeRepresentation = LongDesc.AttributeRepresentation;
					
				EndIf;
				ArrayOfDetailsDescriptions.Add(AttributeRepresentation);
				
			EndIf;
			
			If YouNeedToConfigureBankingDetails
				And Not IsBlankString(LongDesc.AccountingFeatures) Then
				
				FeatureNames = StrSplit(LongDesc.AccountingFeatures, ",");
				
				VisibilityOfSeriesPropsSettings = False;
				
				For Each FeatureName In FeatureNames Do
					
					If Object.AccountingFeature = PredefinedValue("Enum.ItemAccountingFeatures." + FeatureName) Then
						VisibilityOfSeriesPropsSettings = True;
						Break;
					EndIf;
					
				EndDo;
				Items[LongDesc.SettingName].Visible = VisibilityOfSeriesPropsSettings;
			Else
				Items[LongDesc.SettingName].Visible = True;
			EndIf;
				
		EndDo;
				
		ArrayOfTexts.Add(StrConcat(ArrayOfDetailsDescriptions, ", "));
		ArrayOfTexts.Add(") ");
		
		If SeriesUseSettings.GenerateBatchAutomatically Then
			ArrayOfTexts.Add(", ");
			ArrayOfTexts.Add(NStr("vi = 'Có thể tự khởi tạo';
									|ru = 'Возможна автогенерация';
									|en = 'Autogeneration is possible'; fa = 'Autogeneration is possible';
									|it = 'Generazione automatica è possibile';
									|pl = 'Jest możliwa automatyczne generowanie';
									|tr = 'Otomatik oluşturma mümkün'"));
			ArrayOfTexts.Add(" ");
		EndIf;
		
		Items.LabelConfiguringTheUseOfSeries.Title = New FormattedString(ArrayOfTexts);
		
		Items.GenerateBatchAutomatically.Visible =
			Catalogs.ItemKinds.AutomaticSeriesGenerationIsProvided(SeriesUseSettings);
		Items.SpecifyNumberWhenRegisteringBatch.Enabled = Not Object.GenerateBatchAutomatically;
		
		Items.PrecisionOfBatchShelfLifeIndication.Enabled =
			Object.UseShelfLifeOnBatchRegistration Or Object.UseBatchProductionDate;
		
		Items.UseRFIDTags.Enabled = 
			Object.BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem;
	Else
		
		Items.CollapsibleGroupForConfiguringTheCompositionOfSeriesDetails.Visible = False;
		
	EndIf;

	#EndRegion
	
	#EndRegion
	
	#Region UnitOfMeasure
	If IsService
	 Or ThisIsWork
	 Or IsRecordsSet Then
		UnitHeader = NStr("vi = 'Đơn vị tính';
							|ru = 'Ед. измерения';
							|en = 'Unit of measure'; fa = 'واحد اندازه‌گیری';
							|it = 'Unità di misura';
							|pl = 'J.m.';
							|tr = 'Ölçü birimleri'");
		GroupTitleUnitOfMeasurement = NStr("vi = 'Đơn vị tính';
											|ru = 'Единицы измерения';
											|en = 'Units of measure'; fa = 'واحدهای اندازه‌گیری';
											|it = 'Unità di misura';
											|pl = 'Jednostki miary';
											|tr = 'Ölçü birimleri'");
	Else
		UnitHeader = NStr("vi = 'Đơn vị lưu kho';
							|ru = 'Ед. хранения';
							|en = 'Stock UOM'; fa = 'واحد انبار';
							|it = 'Unità di stoccaggio';
							|pl = 'J. przechowywania';
							|tr = 'Stok ölçü birimi'");
		GroupTitleUnitOfMeasurement = NStr("vi = 'Đơn vị tính và điều kiện cất giữ';
											|ru = 'Единицы измерения и условия хранения';
											|en = 'Units of measure and storage conditions'; fa = 'واحدهای اندازه‌گیری و شرایط نگهداری';
											|it = 'Le unità di misura e condizioni di conservazione';
											|pl = 'Jednostki miary i warunki przechowywania';
											|tr = 'Ölçü birimleri ve depolama koşulları'");
	EndIf;
	Items.UnitOfMeasure.Title                       = UnitHeader;
	Items.GroupUnitsOfMeasureAndStorageConditions.Title = GroupTitleUnitOfMeasurement;
	
	Items.UnitOfMeasure.Enabled = (PackagingUsage = "Individual_Set"
											And Object.UsePackages)
											Or Not Object.UsePackages;
	
	#EndRegion
	
	#Region NameTemplatesAndSettingUpProductDetails
	Items.GroupSettingsCreateRadioButtons.Visible =  (Object.KeepAccountingByBatch
																	And Not Object.BatchSettingsAreTakenFromOtherItemsKind)
																Or (Object.UseCharacteristics
																	And Not UseCharacteristicsFromAnotherView);
	
	If Items.PageCreationSettingsGroup.CurrentPage <> Items.GroupDetailsForItemControl
		And (Not Object.KeepAccountingByBatch
		  		And Items.PageCreationSettingsGroup.CurrentPage = Items.GroupDetailsForSeriesControl
			Or Not Object.UseCharacteristics
				And Items.PageCreationSettingsGroup.CurrentPage = Items.GroupDetailsForMonitoringCharacteristics) Then																	
				
		Items.PageCreationSettingsGroup.CurrentPage = Items.GroupDetailsForItemControl;
		SetAppearanceOfClickedHyperlink(Items.ShowAttributesForProductsControl, FormTextColor);
		SetStandardHyperlinkLayout(Items.ShowTheDetailsForMonitoringTheCharacteristics);	
		SetStandardHyperlinkLayout(Items.ShowDetailsForSeriesControl);	
		
	EndIf;
	
	If Items.PageCreationSettingsGroup.CurrentPage = Items.GroupDetailsForItemControl Then
		SetAppearanceOfClickedHyperlink(Items.ShowAttributesForProductsControl, FormTextColor);
		SetStandardHyperlinkLayout(Items.ShowTheDetailsForMonitoringTheCharacteristics);	
		SetStandardHyperlinkLayout(Items.ShowDetailsForSeriesControl);	
	EndIf;
	
	ConfigureByNameTemplate("WorkingNameTemplateOfProductItem"); 
	ConfigureByNameTemplate("NameTemplateForPrintingOfProductItem"); 
	ConfigureByNameTemplate("WorkingNameTemplateCharacteristics"); 
	ConfigureByNameTemplate("NameTemplateForPrintingCharacteristics"); 
	ConfigureByNameTemplate("WorkingNameTemplateSetOfSeries"); 
	
	Items.EditNamingTemplateToPrintProducts.Enabled   = Not ThisObject.ReadOnly;
	Items.EditNamingTemplateToPrintCharacteristic.Enabled = Not ThisObject.ReadOnly;
	Items.EditWorkNamingTemplateOfProducts.Enabled    = Not ThisObject.ReadOnly;
	Items.EditWorkNamingTemplateOfTheCharacteristic.Enabled  = Not ThisObject.ReadOnly;
	Items.EditWorkNamingTemplateOfTheSeries.Enabled           = Not ThisObject.ReadOnly;
	
	If UseIndividualName = "UseIndividualName" Then
		Items.NameForPrinting.Enabled = True;
	Else
		Items.NameForPrinting.Enabled = False;
	EndIf;
	#EndRegion

	#Region AdditionalDetailsAndAdditionalInformation
	Items.AdditionalBankingDetailsPage.Visible	= UseAdditionalAttributesAndInfo;
	Items.AddInformationPage.Visible	= UseAdditionalAttributesAndInfo;
	
	Items.TheItemGroupToCreateTheDetails_3.Visible	= ThereIsTheRightToEdit;
	Items.CharacteristicsGroupCreateBankDetails.Visible = ThereIsTheRightToEdit;
	Items.SeriesGroupCreateBankDetails.Visible			= ThereIsTheRightToEdit;
	Items.TheItemGroupToCreateTheDetails.Visible	= ThereIsTheRightToEdit;
	Items.CharacteristicsGroupCreateInformation.Visible	= ThereIsTheRightToEdit;
	Items.SeriesGroupCreateInformation.Visible			= ThereIsTheRightToEdit;
	
	Items.AttributesForProductsControlPresentationOfHyperlinkProps.CellHyperlink	= ThereIsTheRightToEdit;
	Items.AttributesForItemVariantsControlPresentationOfHyperlinkProps.CellHyperlink	= ThereIsTheRightToEdit;
	Items.AttributesForBatchControlPresentationOfHyperlinkProps.CellHyperlink			= ThereIsTheRightToEdit;
	
	Items.AttributesForProductsControlVisibleWithACondition.CellHyperlink	= ThereIsTheRightToEdit;
	Items.AttributesForItemVariantsControlVisibleWithACondition.CellHyperlink	= ThereIsTheRightToEdit;
	
	Items.AttributesForProductsControlAvailableWithACondition.CellHyperlink	= ThereIsTheRightToEdit;
	Items.AttributesForItemVariantsControlAvailableWithACondition.CellHyperlink	= ThereIsTheRightToEdit;
	#EndRegion
	
	#Region ControlUniqueness
	
	Items.TheDetailsForTheItemControlForTheCellSizeAreUnique.Visible = ControlUniqueness;
	Items.DetailsForControllingCharacteristicsForTheCellSizeAreUnique.Visible = ControlUniqueness;
	
	#EndRegion
	
	#Region PriceManagementSystem
	
	ConfigurePricingSettingsTab();
	
	#EndRegion
	
	AttributesValues = Catalogs.ItemKinds.ValuesOfDetailsAreStrictlyFilledInBySpecificsOfAccounting(KeyTypesOfProducts);
	If AttributesValues <> Undefined Then
		For Each KeyValue In AttributesValues Do
			If Items.Find(KeyValue.Key) <> Undefined Then
				Items[KeyValue.Key].Enabled = False;
			EndIf;
		EndDo
	EndIf;
	
	ConfigureClassifierFieldHint(Items.FEACNCode.Name, Object.FEACNCode);
	CustomizeFormLocalization(VisibilityOfElements);
	
EndProcedure

&AtServer
Procedure ConfigureByNameTemplate(NameOfNameTemplate)
	
	BankingDetailsNameNoNameEditing = BankingDetailsNameNoNameEditing(NameOfNameTemplate);
	
	If BankingDetailsNameNoNameEditing <> "" Then
		FormField = Items[BankingDetailsNameNoNameEditing]; // FormField
		FormField.Enabled = Not IsBlankString(Object[NameOfNameTemplate]);
		FormField.Visible = Not MultilingualismIsEnabled Or Object[BankingDetailsNameNoNameEditing];
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	
	ThereIsTheRightToEdit = Not ValueIsFilled(Object.Ref)
								Or Catalogs.ItemAccessGroups.HasUpdateRight(Object);
	
	AccountingParticularityBeforeChange = Object.AccountingFeature;

	UseProduction     = Catalogs.ItemKinds.UseProduction();
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	UsePriceManagementSystem25          = Parameters.Property("UsePriceManagementSystem25") Or PriceManagementSystemServerCall.UsePriceManagementSystem25();
	ThereAreWarehousesWithoutAnOrderSchemeWhenReflectingSurplusesAndShortages   = WarehousesServer.ThereAreWarehousesWithoutAnOrderSchemeWhenReflectingSurplusesAndShortages();
	ThereAreAdvancedWarehousesForShipment = WarehousesServer.ThereIsOrderWarehouseForShipment();
	ThereAreAdvancedWarehousesForReceiving = WarehousesServer.ThereIsOrderForReceiptWarehouse();
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	// Reset the flag for editing general additional details (details).
	EditingCommonAttributesOfInformation = False;
	
	CommonNameForPrinting = Constants.NameForPrintingItemKinds.Get();
	CommonNameForPrinting = ?(ValueIsFilled(CommonNameForPrinting), CommonNameForPrinting, NStr("vi = '<chưa chỉ định>';
																								|ru = '<не указано>';
																								|en = '<none>'; fa = '<هیچ>';
																								|it = '<non indicato>';
																								|pl = '<nie określono>';
																								|tr = '<belirtilmedi>'"));
	
	BuildTreeOfOperators();
	
	ObjectToFillIn = Object;
	ProductsLocalization.AddFormObject(ThisObject, ObjectToFillIn);
	
	Catalogs.ItemKinds.FillInDetailsForControl(ObjectToFillIn, "Products");
	Catalogs.ItemKinds.FillInAdditionalDetailsForControlAndSelection(ObjectToFillIn, "Products");
	
	Catalogs.ItemKinds.FillInDetailsForControl(ObjectToFillIn, "ItemsCharacteristics");
	Catalogs.ItemKinds.FillInAdditionalDetailsForControlAndSelection(ObjectToFillIn, "ItemsCharacteristics");
	
	Catalogs.ItemKinds.FillInAdditionalDetailsForControlAndSelection(ObjectToFillIn, "ItemsBatches");
	
	ProductsLocalization.RestoreFormObject(ThisObject, ObjectToFillIn);
	
	FillInFormDetailsUsingItemDetails();
	
	LanguagesInformationRecords = NationalLanguageSupportServer.LanguagesInfo();

	MultilingualismIsEnabled = False;
	
	For Each AddnlLanguage In LanguagesInformationRecords.Used Do
		If AddnlLanguage.Value Then
			MultilingualismIsEnabled = True;
			Break;
		EndIf;
	EndDo;
	
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure UnitOfMeasureOnChangeServer()
	
	If Object.UnitFactorForReports = 1
		Or Object.UnitFactorForReports = 0 Then
		Object.UnitForReports = Object.UnitOfMeasure;
	EndIf;
	
	If Object.UnitForReports = Object.UnitOfMeasure Then
		Object.UnitFactorForReports = 1;
	EndIf;
	
	UnitType_ = "";
	
	ThisIsADimensionalUnit = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Object.UnitOfMeasure, UnitType_);
	
	If ThisIsADimensionalUnit Then
		Object.SuppliedInReusablePackage   = False;
	EndIf;
	
	CustomizeForm();

EndProcedure

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	OpenForm("Catalog.ItemKinds.Form.AttributeUnlocking",,,,,, 
		New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, Result);
		CustomizeForm();
    EndIf;

EndProcedure

&AtServer
Procedure EnableFillInVerificationForBankingDetailsOnServer()
	
	If IsBlankString(Object.NameTemplateForPrintingOfProductItem)
		And IsBlankString(Object.WorkingNameTemplateOfProductItem)
		And Object.AttributesOfQuickFilterOfProducts.Count() = 0 Then
		WarningText = NStr("vi = 'Không thay đổi các tùy chỉnh để kiểm tra điền thông tin mặt hàng: chưa đặt mẫu tên gọi nào cho mặt hàng, không có mục tin hiển thị trên thanh chọn nhanh.';
							|ru = 'Настройки проверки заполнения реквизитов номенклатуры не изменены: не заданы ни шаблоны наименований номенклатуры, ни реквизиты, отображаемые в панели быстрого отбора.';
							|en = 'Settings of item attribute filling check are not changed: item name templates and attributes displayed in the quick filter bar are not set.'; fa = 'Settings of item attribute filling check are not changed: item name templates and attributes displayed in the quick filter bar are not set.';
							|it = 'Le impostazioni della verifica di compilazione dei requisiti della articolo non sono state modificate: non sono stati specificati né i modelli dei titoli della articolo, né i requisiti, visualizzabili nel pannello di selezione rapida.';
							|pl = 'Ustawienia weryfikacji wypełnienia atrybutów towarów nie zostały zmienione: nie określono szablonów nazw towarów ani atrybutów, odzwierciedlanych na panelu szybkiego filtrowania.';
							|tr = 'Öğe özniteliklerinin doldurulma kontrolü ayarları değiştirilmedi: Ne öğe tanım şablonları ne de hızlı filtre panelinde görüntülenen ayrıntılar belirtilmedi.'");
		
		CommonClientServer.MessageToUser(WarningText);
	Else
		EnableFillInVerificationForProductDetailsOnServer();
	EndIf;
	
	If Object.UseCharacteristics Then
		If IsBlankString(Object.NameTemplateForPrintingCharacteristics)
			And IsBlankString(Object.WorkingNameTemplateCharacteristics)
			And Object.AttributesOfItemVariantQuickFilter.Count() = 0 Then
			WarningText = NStr("vi = 'Không thay đổi các tùy chỉnh để kiểm tra điền thông tin mặt hàng: chưa đặt mẫu tên gọi nào cho mặt hàng, không có mục tin hiển thị trên thanh chọn nhanh.';
								|ru = 'Настройки проверки заполнения реквизитов характеристик не изменены: не заданы ни шаблоны наименований характеристик, ни реквизиты, отображаемые в панели быстрого отбора.';
								|en = 'Item variant attribute filling check settings are not changed: variant name templates and attributes displayed in the quick filter bar are not set.'; fa = 'Item variant attribute filling check settings are not changed: variant name templates and attributes displayed in the quick filter bar are not set.';
								|it = 'Le impostazioni della verifica di compilazione dei requisiti delle caratteristiche non sono state modificate: non sono stati specificati né i modelli dei titoli delle caratteristiche, né i requisiti, visualizzabili nel pannello di selezione rapida.';
								|pl = 'Ustawienia weryfikacji wypełnienia atrybutów charakterystyk nie zostały zmienione: nie określono szablonów nazw charakterystyk ani atrybutów, odzwierciedlanych na panelu szybkiego filtrowania.';
								|tr = 'Varyant özniteliklerinin doldurulma kontrolü ayarları değiştirilmedi: Ne varyant tanım şablonları ne de hızlı filtre panelinde görüntülenen ayrıntılar belirtilmedi.'");
			
			CommonClientServer.MessageToUser(WarningText);;
		Else
			EnableFillInVerificationForFeatureDetailsOnServer();
		EndIf;
	EndIf;
	
	If Object.KeepAccountingByBatch Then
		If IsBlankString(Object.WorkingNameTemplateSetOfSeries) Then
			WarningText = NStr("vi = 'Không thay đổi tùy chỉnh kiểm tra điền sê-ri: chưa đặt mẫu tên gọi sê-ri.';
								|ru = 'Настройки проверки заполнения серий не изменены: не задан шаблон наименования серий.';
								|en = 'Settings of batch filling check are not changed: batch name template is not set.'; fa = 'Settings of batch filling check are not changed: batch name template is not set.';
								|it = 'Le impostazioni della verifica di compilazione delle serie non sono state modificate: non è stato specificato il modello dei titoli delle serie.';
								|pl = 'Ustawienia weryfikacji wypełnienia serii nie zostały zmienione: nie określono szablonu nazw serii.';
								|tr = 'Parti doldurulma kontrolü ayarları değiştirilmedi: Parti tanım şablonu belirtilmedi.'");
			
			CommonClientServer.MessageToUser(WarningText);;
		Else
			EnableFillInVerificationForSeriesDetailsOnServer();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure EnableFillInVerificationForProductDetailsOnServer()
	
	EnableFillInVerificationForDetailsFromProductTemplatesOnServer();
	EnableFillInVerificationForQuickProductSelectionDetailsOnServer();
	
EndProcedure

&AtServer
Procedure EnableFillInVerificationForDetailsFromProductTemplateOnServer(DescriptionTemplate)
	
	If Not ValueIsFilled(DescriptionTemplate) Then
		Return;
	EndIf;
	
	AdditionalAttributes = Catalogs.Products.AllAdditionalDetails_(Object.Ref, "Products");
	
	TypesDetailsBoolean = New TypeDescription("Boolean");
	
	Filter = New Structure("AttributeName, Property, IsAddlAttribute");
	
	OperandsOfTextFormula = ProcessingOfFormulasClientServer.OperandsOfTextFormula(DescriptionTemplate);
	
	For Each TSRow In Object.AttributesForProductsControl Do
		
		AttributeName = TSRow.AttributeName;
		
		PropsAreUsedInFormula = (OperandsOfTextFormula.Find(AttributeName) <> Undefined);
		
		If Not PropsAreUsedInFormula Then
			Continue;
		EndIf;
		
		// If the type of the props is Boolean, then do not include filling control for it.
		If TSRow.IsAddlAttribute Then
			
			FillPropertyValues(Filter, TSRow);
			
			FoundRows = AdditionalAttributes.FindRows(Filter);
			
			If FoundRows.Count() = 0 Then
				Continue;
			EndIf;
			
			AdditionalInformationDetailsLine = FoundRows[0];
			
			AttributeValueType = AdditionalInformationDetailsLine.Type;
			
		Else
			
			Attribute = Metadata.Catalogs.Products.Attributes.Find(AttributeName);
			
			If Attribute = Undefined Then
				Continue;
			EndIf;
			
			AttributeValueType = Attribute.Type;
			
		EndIf;
		
		If AttributeValueType = TypesDetailsBoolean Then
			Continue;
		EndIf;
		
		TSRow.RequiredToFill = True;
		TSRow.DisplayWhenCreated = True;
		TSRow.DisplayAvailabilityOnCreation = False;
		
		Modified = True;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure EnableFillInVerificationForDetailsFromProductTemplatesOnServer()
	
	EnableFillInVerificationForDetailsFromProductTemplateOnServer(Object.WorkingNameTemplateOfProductItem);
	EnableFillInVerificationForDetailsFromProductTemplateOnServer(Object.NameTemplateForPrintingOfProductItem);
	
EndProcedure

&AtServer
Procedure EnableFillInVerificationForFeatureDetailsOnServer()
	
	EnableFillInVerificationForDetailsFromCharacteristicsTemplatesOnServer();
	EnableFillInVerificationForQuickFeatureSelectionDetailsOnServer();
	
EndProcedure

&AtServer
Procedure EnableFillInVerificationForSeriesDetailsOnServer()
	
	EnableFillInVerificationForDetailsFromSeriesTemplatesOnServer();
	
EndProcedure

&AtServer
Procedure EnableFillInVerificationForDetailsFromCharacteristicsTemplateOnServer(FeatureNameTemplate)
	
	If Not ValueIsFilled(FeatureNameTemplate) Then
		Return;
	EndIf;
	
	AdditionalAttributes = Catalogs.Products.AllAdditionalDetails_(Object.Ref, "ItemsCharacteristics");
	
	TypesDetailsBoolean = New TypeDescription("Boolean");
	
	Filter = New Structure("AttributeName, Property, IsAddlAttribute");
	
	OperandsOfTextFormula = ProcessingOfFormulasClientServer.OperandsOfTextFormula(FeatureNameTemplate);
	
	For Each TSRow In Object.AttributesForItemVariantsControl Do
		
		AttributeName = TSRow.AttributeName;
		
		PropsAreUsedInFormula = (OperandsOfTextFormula.Find(TSRow.AttributeName) <> Undefined);
		
		If Not PropsAreUsedInFormula Then
			Continue;
		EndIf;
		
		// If the type of the props is Boolean, then do not include filling control for it.
		If TSRow.IsAddlAttribute Then
			
			FillPropertyValues(Filter, TSRow);
			
			FoundRows = AdditionalAttributes.FindRows(Filter);
			
			If FoundRows.Count() = 0 Then
				Continue;
			EndIf;
			
			AdditionalInformationDetailsLine = FoundRows[0];
			
			AttributeValueType = AdditionalInformationDetailsLine.Type;
			
		Else
			
			Attribute = Metadata.Catalogs.ItemsCharacteristics.Attributes.Find(AttributeName);
			
			If Attribute = Undefined Then
				Continue;
			EndIf;
			
			AttributeValueType = Attribute.Type;
			
		EndIf;
		
		If AttributeValueType = TypesDetailsBoolean Then
			Continue;
		EndIf;
		
		TSRow.RequiredToFill = True;
		TSRow.DisplayWhenCreated = True;
		TSRow.DisplayAvailabilityOnCreation = False;
		
		Modified = True;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure EnableFillInVerificationForDetailsFromSeriesTemplateOnServer(SeriesNameTemplate)
	
	If Not ValueIsFilled(SeriesNameTemplate) Then
		Return;
	EndIf;
	
	AdditionalAttributes = Catalogs.Products.AllAdditionalDetails_(Object.Ref, "ItemsBatches");
	
	TypesDetailsBoolean = New TypeDescription("Boolean");
	
	Filter = New Structure("AttributeName, Property, IsAddlAttribute");
	
	OperandsOfTextFormula = ProcessingOfFormulasClientServer.OperandsOfTextFormula(SeriesNameTemplate);
	
	For Each TSRow In Object.AttributesForBatchControl Do
		
		AttributeName = TSRow.AttributeName;
		
		PropsAreUsedInFormula = (OperandsOfTextFormula.Find(TSRow.AttributeName) <> Undefined);
		
		If Not PropsAreUsedInFormula Then
			Continue;
		EndIf;
		
		// If the type of the props is Boolean, then do not include filling control for it.
		If TSRow.IsAddlAttribute Then
			
			FillPropertyValues(Filter, TSRow);
			
			FoundRows = AdditionalAttributes.FindRows(Filter);
			
			If FoundRows.Count() = 0 Then
				Continue;
			EndIf;
			
			AdditionalInformationDetailsLine = FoundRows[0];
			
			AttributeValueType = AdditionalInformationDetailsLine.Type;
			
		Else
			
			Attribute = Metadata.Catalogs.ItemsBatches.Attributes.Find(AttributeName);
			
			If Attribute = Undefined Then
				Continue;
			EndIf;
			
			AttributeValueType = Attribute.Type;
			
		EndIf;
		
		If AttributeValueType = TypesDetailsBoolean Then
			Continue;
		EndIf;
		
		TSRow.RequiredToFill = True;
		
		Modified = True;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure EnableFillInVerificationForDetailsFromCharacteristicsTemplatesOnServer()
	
	EnableFillInVerificationForDetailsFromCharacteristicsTemplateOnServer(Object.WorkingNameTemplateCharacteristics);
	EnableFillInVerificationForDetailsFromCharacteristicsTemplateOnServer(Object.NameTemplateForPrintingCharacteristics);
	
EndProcedure

&AtServer
Procedure EnableFillInVerificationForDetailsFromSeriesTemplatesOnServer()
	
	EnableFillInVerificationForDetailsFromSeriesTemplateOnServer(Object.WorkingNameTemplateSetOfSeries);
	
EndProcedure

&AtServer
Procedure EnableFillInVerificationForQuickProductSelectionDetailsOnServer()
	
	Filter = New Structure("AttributeName");
	
	For Each TSRow In Object.AttributesForProductsControl Do
		
		Filter.AttributeName = TSRow.AttributeName;
		
		PropsAreUsedForSelection = (Object.AttributesOfQuickFilterOfProducts.FindRows(Filter).Count() <> 0);
		
		If PropsAreUsedForSelection Then
			
			TSRow.RequiredToFill = True;
			TSRow.DisplayWhenCreated = True;
			TSRow.DisplayAvailabilityOnCreation = False;
			
			Modified = True;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure EnableFillInVerificationForQuickFeatureSelectionDetailsOnServer()
	
	Filter = New Structure("AttributeName");
	
	For Each TSRow In Object.AttributesForItemVariantsControl Do
		
		Filter.AttributeName = TSRow.AttributeName;
		
		If Object.AttributesOfItemVariantQuickFilter.FindRows(Filter).Count() <> 0 Then
			
			TSRow.RequiredToFill = True;
			TSRow.DisplayWhenCreated = True;
			TSRow.DisplayAvailabilityOnCreation = False;
			
			Modified = True;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function AvailabilityConditions()
	
	AvailabilityConditions = New Structure;
	AvailabilityConditions.Insert("ThisIsUnusedTypeForControl");
	AvailabilityConditions.Insert("TypeOfPropsBoolean");
	AvailabilityConditions.Insert("RequiredToFill");
	AvailabilityConditions.Insert("OnlyBeSureToFill", False);
	
	Return AvailabilityConditions;
	
EndFunction

&AtServer
Procedure UseCharacteristicsWhenChangingOnServer()
	
	ObjectToFillIn = Object;
	ProductsLocalization.AddFormObject(ThisObject, ObjectToFillIn);
	
	Catalogs.ItemKinds.FillDefaultAttributes(ObjectToFillIn);
	Catalogs.ItemKinds.WorkOutLogicOfConnectionDetails(ObjectToFillIn);
	
	ProductsLocalization.RestoreFormObject(ThisObject, ObjectToFillIn);
	
	FillInFormDetailsUsingItemDetails();
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure UseSeriesWhenChangingOnServer()
	
	ObjectToFillIn = Object;
	ProductsLocalization.AddFormObject(ThisObject, ObjectToFillIn);
	
	Catalogs.ItemKinds.FillDefaultAttributes(ObjectToFillIn);
	Catalogs.ItemKinds.WorkOutLogicOfConnectionDetails(ObjectToFillIn);
	
	ProductsLocalization.RestoreFormObject(ThisObject, ObjectToFillIn);
	
	FillInFormDetailsUsingItemDetails();
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure UsePackagesWhenChangingOnServer()

	If Object.UsePackages Then
		Object.SuppliedInReusablePackage = False;
		Object.ReusablePackageItems = Undefined;
		Object.ReusablePackageVariant = Undefined;
	EndIf;
	
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure SetOfPackagesWhenChangedOnServer()
	
	AttributesPackagingGroup = Common.ObjectAttributesValues(Object.PackagingGroup, 
				"UnitOfMeasure, UnitForReports, UnitFactorForReports");
	
	If ValueIsFilled(Object.PackagingGroup)
		And Object.PackagingGroup <> PredefinedValue("Catalog.PackagingGroups.SpecialForItem") Then
		Object.UnitOfMeasure = AttributesPackagingGroup.UnitOfMeasure;
	EndIf;
	If ValueIsFilled(AttributesPackagingGroup.UnitForReports) Then
		Object.UnitForReports = AttributesPackagingGroup.UnitForReports;
		Object.UnitFactorForReports = AttributesPackagingGroup.UnitFactorForReports;
	EndIf;
	
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure UseIndividualNameOnChange(Item)
	
	If UseIndividualName = "UseNameFromConstant" Then
		Object.NameForPrinting = "";
	EndIf;
		
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure NoteBeforeChangingProductQuickSelectionPanel()
	
	QueryText = NStr("vi = 'Chỉ có thể điều chỉnh thành phần bảng chọn nhanh
		|sau khi ghi lại phần tử, ghi lại phần tử?';
		|ru = 'Редактирование состава панели быстрого отбора
		|возможно только после записи элемента, записать элемент?';
		|en = 'You cannot edit quick filter bar items 
		|until the item is saved. Do you want to save the item?'; fa = 'You cannot edit quick filter bar items 
		|until the item is saved. Do you want to save the item?';
		|it = 'La modifica della composizione del pannello di selezione rapida
		|è possibile solo dopo la scrittura dell''elemento, scrivere l''elemento?';
		|pl = 'Edycja składu panelu szybkiego filtrowania
		|jest możliwe tylko po zapisie elementu, zapisać element?';
		|tr = 'Hızlı filtre paneli içeriğinin düzenlenmesi
		|sadece öğenin kaydından sonra mümkündür, öğe kaydedilsin mi?'");
		
	ShowQueryBox(New CallbackDescription("NoteBeforeChangingProductQuickSelectionPanelCompletion", ThisObject),
		QueryText, QuestionDialogMode.OKCancel,,,NStr("vi = 'Soạn lệnh lọc nhanh';
														|ru = 'Редактирование панели быстрого отбора';
														|en = 'Edit quick filter bar'; fa = 'Edit quick filter bar';
														|it = 'Modifica del pannello di selezione rapida';
														|pl = 'Edycja panelu szybkiego filtrowania';
														|tr = 'Hızlı filtre panelinin düzenlenmesi'"));
			
EndProcedure

&AtClient
Procedure NoteBeforeChangingProductQuickSelectionPanelCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.OK Then
		If Write() Then
			
			ChangeQuickSelectionPanelForProducts();
				
		EndIf;	
	EndIf;	
	
EndProcedure

&AtClient
Procedure ChangeQuickSelectionPanelForProducts()
	
	Read();
	
	CurrentItemType = "AdditionalAttribute5";
	TheCurrentTypeOfItemSetOwner = "Products";
	
	AddressInStorage = PlaceQuickSelectionDetailsInRepository();
	
	ParametersStructure = New Structure("AddressInStorage", AddressInStorage);
	
	OpenForm("Catalog.ItemKinds.Form.EditFormOfAttributesList", ParametersStructure,,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure		

&AtServer
Function PlaceQuickSelectionDetailsInRepository()
	
	CollectionOfSelectionProps		= Catalogs.ItemKinds.CollectionOfSelectionProps(
										Object,
										TheCurrentTypeOfItemSetOwner);
	CollectionOfPropsForControl	= Catalogs.ItemKinds.CollectionOfPropsForControl(
										Object,
										TheCurrentTypeOfItemSetOwner);
	FormAttributes					= ?(TheCurrentTypeOfItemSetOwner = "Products",
										Catalogs.Products.DetailsOfSettingsTableForm(),
										Undefined);
	
	TableOfSelectionDetails = New ValueTable;
	TableOfSelectionDetails.Columns.Add("AttributeName", New TypeDescription("String"));
	TableOfSelectionDetails.Columns.Add("AttributeRepresentation", New TypeDescription("String"));
	TableOfSelectionDetails.Columns.Add("IsAddlAttribute", New TypeDescription("Boolean"));
	TableOfSelectionDetails.Columns.Add("Property", New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo"));
	TableOfSelectionDetails.Columns.Add("Used", New TypeDescription("Boolean"));
	
	For Each Attribute In CollectionOfPropsForControl Do
		If FormAttributes <> Undefined
			And FormAttributes.Get(Attribute.AttributeName) <> Undefined Then
			
			Continue;
			
		EndIf;
		
		If Attribute.AvailabilityUnique Then
			NewRow = TableOfSelectionDetails.Add();
			FillPropertyValues(NewRow, Attribute);
			NewRow.Used = CollectionOfSelectionProps.FindRows(New Structure("AttributeName",Attribute.AttributeName)).Count() > 0;
		EndIf;
	EndDo;
	
	TableOfSelectionDetails.Sort("AttributeRepresentation");
	
	Return PutToTempStorage(TableOfSelectionDetails, ThisObject.UUID);
	
EndFunction

&AtClient
Procedure SaveCharacteristicsBeforeChangingQuickSelectionPanel()
	
	QueryText = NStr("vi = 'Chỉ có thể điều chỉnh thành phần bảng chọn nhanh
		|sau khi ghi lại phần tử, ghi lại phần tử?';
		|ru = 'Редактирование состава панели быстрого отбора
		|возможно только после записи элемента, записать элемент?';
		|en = 'You cannot edit quick filter bar items 
		|until the item is saved. Do you want to save the item?'; fa = 'You cannot edit quick filter bar items 
		|until the item is saved. Do you want to save the item?';
		|it = 'La modifica della composizione del pannello di selezione rapida
		|è possibile solo dopo la scrittura dell''elemento, scrivere l''elemento?';
		|pl = 'Edycja składu panelu szybkiego filtrowania
		|jest możliwe tylko po zapisie elementu, zapisać element?';
		|tr = 'Hızlı filtre paneli içeriğinin düzenlenmesi
		|sadece öğenin kaydından sonra mümkündür, öğe kaydedilsin mi?'");
		
	ShowQueryBox(New CallbackDescription("SaveCharacteristicsBeforeChangingQuickSelectionPanelCompletion", ThisObject),
		QueryText, QuestionDialogMode.OKCancel,,,NStr("vi = 'Điều chỉnh lệnh lọc nhanh';
														|ru = 'Редактирование панели быстрого отбора';
														|en = 'Edit quick filter bar'; fa = 'Edit quick filter bar';
														|it = 'Modifica del pannello di selezione rapida';
														|pl = 'Edycja panelu szybkiego filtrowania';
														|tr = 'Hızlı filtre panelinin düzenlenmesi'"));
			
EndProcedure

&AtClient
Procedure SaveCharacteristicsBeforeChangingQuickSelectionPanelCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.OK Then
		If Write() Then
			
			ChangeQuickFeatureSelectionPanel();
					
		EndIf;	
	EndIf;	
	
EndProcedure

&AtClient
Procedure ChangeQuickFeatureSelectionPanel()
	Read();
	
	NumberOfAvailable = TableOfAdditionalCharacteristicsAttributes.Count();
	
	If NumberOfAvailable = 0 Then
		
		MessageText = NStr("vi = 'Không thể điều chỉnh thành phần bảng chọn nhanh đặc tính.
		|Chưa chỉ ra mục tin bổ sung của đặc tính.
		|Trước khi điều chỉnh thành phần bảng chọn nhanh, nên tùy chỉnh thành phần
		|mục tin bổ sung của đặc tính.';
		|ru = 'Невозможно отредактировать состав панели быстрого отбора характеристик.
		|Не указаны дополнительные реквизиты характеристик.
		|Перед редактированием состава панели быстрого отбора нужно настроить состав 
		|дополнительных реквизитов характеристик.';
		|en = 'Cannot edit items of the variant quick filter bar.
		|Additional variant attributes were not specified.
		|Before editing quick filter bar items, customize the set
		|of additional variant attributes.'; fa = 'Cannot edit items of the variant quick filter bar.
		|Additional variant attributes were not specified.
		|Before editing quick filter bar items, customize the set
		|of additional variant attributes.';
		|it = 'Non è possibile modificare la composizione del pannello di selezione rapida delle caratteristiche.
		|I requisiti aggiuntivi delle caratteristiche non sono specificati.
		|Prima di modificare la composizione del pannello di selezione rapida è necessario impostare la composizione
		|dei requisiti aggiuntivi delle caratteristiche.';
		|pl = 'Edycja składu panelu szybkiego filtrowania charakterystyk nie jest możliwa.
		|Nie określono atrybutów dodatkowych charakterystyk.
		|Przed edycją składu panelu szybkiego filtrowania należy ustawić skład 
		|atrybutów dodatkowych charakterystyk.';
		|tr = 'Varyantların hızlı filtre panelinin içeriğini düzenlemek mümkün değildir.
		|Varyantların ek öznitelikleri belirtilmedi.
		|Hızlı filtre panelinin içeriğini düzenlemeden önce, özelliklerin 
		|ek özniteliklerinin içeriğini ayarlamanız gerekmektedir.'");
		
		CommonClientServer.MessageToUser(MessageText);
		
		Return;
		
	EndIf;
	
	CurrentItemType = "AdditionalAttribute5";
	TheCurrentTypeOfItemSetOwner = "ItemsCharacteristics";
	
	AddressInStorage = PlaceQuickSelectionDetailsInRepository();
	
	ParametersStructure = New Structure("AddressInStorage", AddressInStorage);
	
	OpenForm("Catalog.ItemKinds.Form.EditFormOfAttributesList", ParametersStructure,,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure		

&AtClient
Procedure AddTheWarehouseToTheSeriesAccountingPoliciesCompletion(ClosingResult, AdditionalParameters) Export

	If TypeOf(ClosingResult) <> Type("CatalogRef.Warehouses") Then
		Return;
	EndIf;
	
	PolicyLine = Object.BatchAccountingPolicies.Add();
	PolicyLine.Warehouse = ClosingResult;
	PolicyLine.ThisIsAWarehousePolicy = True;
	
	AfterAddingNewUnitWarehouseToBatchAccountingPolicies(PolicyLine.Warehouse, PolicyLine.BatchAccountingPolicy);
	
	FilterStructure1 = New Structure();
	FilterStructure1.Insert("Warehouse", ClosingResult);
	
	FoundRows = Object.BatchAccountingPolicies.FindRows(FilterStructure1);
	For Each TableRow In FoundRows Do
		Items.BatchAccountingPolicies.CurrentRow = TableRow.GetID();
	EndDo;
	
EndProcedure

&AtClient
Procedure AddTheDepartmentToTheSeriesAccountingPoliciesCompletion(ClosingResult, AdditionalParameters) Export

	If TypeOf(ClosingResult) <> Type("CatalogRef.BusinessStructure") Then
		Return;
	EndIf;
	
	PolicyLine = Object.BatchAccountingPolicies.Add();
	PolicyLine.Warehouse = ClosingResult;
	PolicyLine.ThisIsAWarehousePolicy = False;
	
	AfterAddingNewUnitWarehouseToBatchAccountingPolicies(PolicyLine.Warehouse, PolicyLine.BatchAccountingPolicy);
	
	FilterStructure1 = New Structure();
	FilterStructure1.Insert("Warehouse", ClosingResult);
	
	FoundRows = Object.BatchAccountingPolicies.FindRows(FilterStructure1);
	For Each TableRow In FoundRows Do
		Items.BatchAccountingPolicies.CurrentRow = TableRow.GetID();
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateAlertOnWarehouseClient()
	
	CurrentData = Items.BatchAccountingPolicies.CurrentData;
	
	If CurrentData = Undefined
		Or Not ValueIsFilled(CurrentData.Warehouse)
		Or TypeOf(CurrentData.Warehouse) = Type("CatalogRef.BusinessStructure") Then
		Items.LabelSeriesAccountingPolicyHint.Visible = False;
		Return;
	EndIf;
	
	Items.LabelSeriesAccountingPolicyHint.Visible = Not ThereIsOrderScheme(CurrentData.Warehouse);
	
EndProcedure

&AtServerNoContext
Function ThereIsOrderScheme(Warehouse)
	
	If Not GetFunctionalOption("UseWarehouseManagementSystem") Then
		Return True;
 	EndIf;
	
	Return GetFunctionalOption("UseWarehouseManagemantSystemForGoodsSurplusesShortages", New Structure("Warehouse", Warehouse));
	
EndFunction

&AtClient
Procedure ChangeCharacteristicsPanelForKey()
	
//	Read();
	
	CurrentItemType = "AdditionalAttribute5";
	TheCurrentTypeOfItemSetOwner = "ItemsCharacteristics";
	
	AddressInStorage = PlaceDetailsForKeyInVault();
	
	ParametersStructure = New Structure("AddressInStorage, NotificationFunction", AddressInStorage, "SelectionOfDetailsInPriceKeyTable");
	
	OpenForm("Catalog.ItemKinds.Form.EditFormOfAttributesList", ParametersStructure,,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure	

&AtClient
Procedure ChangeSeriesPanelForKey()
	
//	Read();
	
	CurrentItemType = "AdditionalAttribute5";
	TheCurrentTypeOfItemSetOwner = "ItemsBatches";
	
	AddressInStorage = PlaceDetailsForKeyInVault();
	
	ParametersStructure = New Structure("AddressInStorage, NotificationFunction", AddressInStorage, "SelectionOfDetailsInPriceKeyTable");
	
	OpenForm("Catalog.ItemKinds.Form.EditFormOfAttributesList", ParametersStructure,,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure	

&AtServer
Function PlaceDetailsForKeyInVault()
	
	CollectionOfPriceKeyDetails    = Catalogs.ItemKinds.CollectionOfKeyDetails(Object, TheCurrentTypeOfItemSetOwner);
	CollectionOfPropsForControl = Catalogs.ItemKinds.CollectionOfPropsForControl(Object, TheCurrentTypeOfItemSetOwner);
	
	TableOfPriceKeyDetails = New ValueTable;
	TableOfPriceKeyDetails.Columns.Add("AttributeName", New TypeDescription("String"));
	TableOfPriceKeyDetails.Columns.Add("AttributeRepresentation", New TypeDescription("String"));
	TableOfPriceKeyDetails.Columns.Add("IsAddlAttribute", New TypeDescription("Boolean"));
	TableOfPriceKeyDetails.Columns.Add("Property", New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo"));
	TableOfPriceKeyDetails.Columns.Add("Used", New TypeDescription("Boolean"));
	
	If TheCurrentTypeOfItemSetOwner = "ItemsBatches" Then
		
		AttributeToAdd = New Structure("AttributeName, AttributeRepresentation");
		
		If Object.SpecifyNumberWhenRegisteringBatch Then
			
			AttributeToAdd.AttributeName			= "Number";
			AttributeToAdd.AttributeRepresentation	= NStr("vi = 'Số';
															|ru = 'Номер';
															|en = 'Number'; fa = 'شماره';
															|it = 'Numero';
															|pl = 'Number';
															|tr = 'Numara'");			
			AddDetailsToPriceKeyDetailsTable(TableOfPriceKeyDetails, CollectionOfPriceKeyDetails, AttributeToAdd);
			
		EndIf;
			
		If Object.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToMonths Then
			PresentationOfPointingAccuracy	= NStr("vi = 'tháng, năm';
													|ru = 'месяц, год';
													|en = 'month, year'; fa = 'month, year';
													|it = 'Mese, anno';
													|pl = 'miesiąc, rok';
													|tr = 'ay, yıl'");			
		ElsIf Object.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToDays Then
			PresentationOfPointingAccuracy	= NStr("vi = 'ngày';
													|ru = 'дата';
													|en = 'date'; fa = 'تاریخ';
													|it = 'data';
													|pl = 'data';
													|tr = 'tarih'");			
		ElsIf Object.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToHours Then
			PresentationOfPointingAccuracy	= NStr("vi = 'ngày, giờ';
													|ru = 'дата, час';
													|en = 'date, hour'; fa = 'date, hour';
													|it = 'dara, ora';
													|pl = 'data, godzina';
													|tr = 'tarih, saat'");			
		Else
			PresentationOfPointingAccuracy	= "";			
		EndIf;

		If Object.UseShelfLifeOnBatchRegistration Then
			AttributeRepresentation = NStr("vi = 'Hạn sử dụng đến (%AccuracyOfIndication%)';
											|ru = 'Годен до (%AccuracyOfIndication%)';
											|en = 'Valid until (%AccuracyOfIndication%)'; fa = 'Valid until (%AccuracyOfIndication%)';
											|it = 'Dovuto per (%AccuracyOfIndication%)';
											|pl = 'Ważny do (%AccuracyOfIndication%)';
											|tr = 'Son kullanma tarihi (%AccuracyOfIndication%)'");
			AttributeRepresentation = StrReplace(AttributeRepresentation, "%AccuracyOfIndication%", PresentationOfPointingAccuracy);
			
			AttributeToAdd.AttributeName= "ValidUntil_";
			AttributeToAdd.AttributeRepresentation = AttributeRepresentation;			
			AddDetailsToPriceKeyDetailsTable(TableOfPriceKeyDetails, CollectionOfPriceKeyDetails, AttributeToAdd);
		EndIf;
		
		If Object.UseBatchProductionDate Then
			AttributeRepresentation = NStr("vi = 'Ngày sản xuất (%AccuracyOfIndication%)';
											|ru = 'Дата производства (%AccuracyOfIndication%)';
											|en = 'Production date (%AccuracyOfIndication%)'; fa = 'Production date (%AccuracyOfIndication%)';
											|it = 'Data produzione (%AccuracyOfIndication%)';
											|pl = 'Data produkcji (%AccuracyOfIndication%)';
											|tr = 'Üretim tarihi (%AccuracyOfIndication%)'");
			AttributeRepresentation = StrReplace(AttributeRepresentation, "%AccuracyOfIndication%", PresentationOfPointingAccuracy);
			
			AttributeToAdd.AttributeName           = "ProductionDate";
			AttributeToAdd.AttributeRepresentation = AttributeRepresentation;
			AddDetailsToPriceKeyDetailsTable(TableOfPriceKeyDetails, CollectionOfPriceKeyDetails, AttributeToAdd);
		EndIf;
		
		If Object.CIMSPMSNumber Then
			AttributeToAdd.AttributeName	= "NumberOfSPMSControlIdentificationMark";
			AttributeToAdd.AttributeRepresentation	= NStr("vi = '%1';
															|ru = '%1';
															|en = '%1'; fa = '%1';
															|it = '%1';
															|pl = '%1';
															|tr = '%1'");
			AttributeToAdd.AttributeRepresentation = StrTemplate(AttributeToAdd.AttributeRepresentation, "KiZ");
			AddDetailsToPriceKeyDetailsTable(TableOfPriceKeyDetails, CollectionOfPriceKeyDetails, AttributeToAdd);
		EndIf;
		
		If Object.UseUSAISManufacturerBatch Then
			AttributeToAdd.AttributeName	= "ManufacturerUSAIS";
			AttributeToAdd.AttributeRepresentation	= NStr("vi = 'Nhà sản xuất (EGAIS)';
															|ru = 'Производитель (ЕГАИС)';
															|en = 'Manufacturer (EGAIS)'; fa = 'تولیدکننده (EGAIS)';
															|it = 'Produttore (EGAIS, Sistema Informativo Unico Statale Automatizzato)';
															|pl = 'Producent (Jednolity państwowy zautomatyzowany system informacyjny)';
															|tr = 'Üretici (EGAİS)'");
			AddDetailsToPriceKeyDetailsTable(TableOfPriceKeyDetails, CollectionOfPriceKeyDetails, AttributeToAdd);
		EndIf;
		
		If Object.UseCertificate2USAISBatch Then
			AttributeToAdd.AttributeName	= "Certificate2USAIS";
			AttributeToAdd.AttributeRepresentation	= NStr("vi = 'Trợ giúp 2 (EGAIS)';
															|ru = 'Справка 2 (ЕГАИС)';
															|en = 'Certificate 2 (EGAIS)'; fa = 'گواهی 2 (EGAIS)';
															|it = 'Nota informativa 2 (EGAIS, Sistema Informativo Unico Statale Automatizzato)';
															|pl = 'Pomoc 2 (Jednolity państwowy zautomatyzowany system informacyjny)';
															|tr = 'Yardım 2 (EGAIS)'");
			AddDetailsToPriceKeyDetailsTable(TableOfPriceKeyDetails, CollectionOfPriceKeyDetails, AttributeToAdd);
		EndIf;
		
		If Object.UseManufacturerVetISBatch Then
			AttributeToAdd.AttributeName	= "ManufacturerVetIS";
			AttributeToAdd.AttributeRepresentation	= NStr("vi = 'Nhà sản xuất (%1)';
															|ru = 'Производитель (%1)';
															|en = 'Manufacturer (%1)'; fa = 'Manufacturer (%1)';
															|it = 'Produttore (%1)';
															|pl = 'Producent (%1)';
															|tr = 'Üretici (%1)'");
			AttributeToAdd.AttributeRepresentation = StrTemplate(AttributeToAdd.AttributeRepresentation, "VetIS");
			AddDetailsToPriceKeyDetailsTable(TableOfPriceKeyDetails, CollectionOfPriceKeyDetails, AttributeToAdd);
		EndIf;
		
		If Object.UseWarehouseJournalRecordVetISBatch Then
			AttributeToAdd.AttributeName	= "WarehouseBookRecordVetIS";
			AttributeToAdd.AttributeRepresentation	= NStr("vi = 'Bản ghi sổ chứng từ kho (%1)';
															|ru = 'Запись складского журнала (%1)';
															|en = 'Warehouse book record (%1)'; fa = 'Warehouse book record (%1)';
															|it = 'Registrazione del registro di magazzino (%1)';
															|pl = 'Wpis dziennika magazynowego (%1)';
															|tr = 'Ambar günlük kaydı (%1)'");
			AttributeToAdd.AttributeRepresentation = StrTemplate(AttributeToAdd.AttributeRepresentation, "VetIS");
			AddDetailsToPriceKeyDetailsTable(TableOfPriceKeyDetails, CollectionOfPriceKeyDetails, AttributeToAdd);
		EndIf;
		
		If Object.UseVetISLotIDBatch Then
			AttributeToAdd.AttributeName	= "LotIDVetIS";
			AttributeToAdd.AttributeRepresentation	= NStr("vi = 'Tên định danh lô hàng (%1)';
															|ru = 'Идентификатор партии (%1)';
															|en = 'Lot ID (%1)'; fa = 'Lot ID (%1)';
															|it = 'ID lotto (%1)';
															|pl = 'Identyfikator partii (%1)';
															|tr = 'Lot kimliği (%1)'");
			AttributeToAdd.AttributeRepresentation = StrTemplate(AttributeToAdd.AttributeRepresentation, "VetIS");
			AddDetailsToPriceKeyDetailsTable(TableOfPriceKeyDetails, CollectionOfPriceKeyDetails, AttributeToAdd);
		EndIf;
	EndIf;
	
	For Each Attribute In CollectionOfPropsForControl Do
		
		If Attribute.RequiredToFill Then
			NewRow = TableOfPriceKeyDetails.Add();
			FillPropertyValues(NewRow, Attribute);
			NewRow.Used = CollectionOfPriceKeyDetails.FindRows(New Structure("AttributeName",Attribute.AttributeName)).Count() > 0;
		EndIf;
		
	EndDo;
	
	TableOfPriceKeyDetails.Sort("AttributeRepresentation");
	
	Return PutToTempStorage(TableOfPriceKeyDetails, ThisObject.UUID);

EndFunction

&AtServer
Procedure AddDetailsToPriceKeyDetailsTable(TableOfPriceKeyDetails, CollectionOfPriceKeyDetails, Val AttributeToAdd)
	
	NewRow = TableOfPriceKeyDetails.Add();
	FillPropertyValues(NewRow, AttributeToAdd);
//			New line.ReqUisitname	= addedrequisit.ReqUisitname;
//			New line.Session viewerequisit	= addedrequisit.Introduction of the Session;
	NewRow.IsAddlAttribute	= False;
	NewRow.Used = CollectionOfPriceKeyDetails.FindRows(New Structure("AttributeName",AttributeToAdd.AttributeName)).Count() > 0;
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure ItemsTypeOnChangeServer()
	
	Enums.ItemAccountingFeatures.ProcessItemTypeChanges(Object.ItemsType,
		Object.AccountingFeature);
	
	ObjectToFillIn = Object;
	ProductsLocalization.AddFormObject(ThisObject, ObjectToFillIn);
	
	Catalogs.ItemKinds.FillDefaultAttributes(ObjectToFillIn);
	Catalogs.ItemKinds.WorkOutLogicOfConnectionDetails(ObjectToFillIn);
	
	Catalogs.ItemKinds.FillInDetailsForControl(ObjectToFillIn, "Products");
	
	ProductsLocalization.RestoreFormObject(ThisObject, ObjectToFillIn);
	
	FillInFormDetailsUsingItemDetails();
	
	CustomizeForm();
	AccountingParticularityBeforeChange = Object.AccountingFeature;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
		
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BatchAccountingPoliciesBatchAccountingPolicy.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BatchAccountingPolicies.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn kho bãi>';
													|ru = '<выберите склад>';
													|en = '<select warehouse>'; fa = '<select warehouse>';
													|it = '<scegliere il magazzino>';
													|pl = '<wybierz magazyn>';
													|tr = '<ambar seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
		
	SetConditionalAppearanceDetailsForControl(
		"AttributesForProductsControl",
		"TableOfAdditionalAttributesOfProducts",
		"TableOfAdditionalSeriesAttributes");
	SetConditionalAppearanceDetailsForControl(
		"AttributesForItemVariantsControl",
		"TableOfAdditionalCharacteristicsAttributes",
		"TableOfAdditionalCharacteristicsAttributes");
	SetConditionalAppearanceDetailsForControl(
		"AttributesForBatchControl",
		"TableOfAdditionalSeriesAttributes",
		"TableOfAdditionalSeriesAttributes");
	
	If GetFunctionalOption("UseItemPackages") Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.UsingPackagesCommonSet.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = Items.UsePackages.ReadOnly;
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.UseOfPackagesIndividualSet.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = Items.UsePackages.ReadOnly;
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
	EndIf;
		
EndProcedure

&AtServer
Procedure SetConditionalAppearanceDetailsForControl(NameOfTableDetailsForControl, NameOfAdditionalDetailsTable, NameOfAdditionalInformationTable)
	
	ThisIsTableForSeriesControl = (NameOfTableDetailsForControl = "AttributesForBatchControl");
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	FormItem = Items[NameOfAdditionalDetailsTable]; // FormTable
	ItemField.Field = New DataCompositionField(FormItem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(NameOfAdditionalDetailsTable + ".CommonProperty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	FormItem = Items[NameOfAdditionalInformationTable]; // FormTable
	ItemField.Field = New DataCompositionField(FormItem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(NameOfAdditionalInformationTable + ".CommonProperty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//
			
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	FormItem = Items[NameOfTableDetailsForControl + "RequiredToFill"]; // FormField
	ItemField.Field = New DataCompositionField(FormItem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + NameOfTableDetailsForControl + ".MandatoryFillingOfAvailability");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	If Not ThisIsTableForSeriesControl Then 
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		FormItem = Items[NameOfTableDetailsForControl + "DisplayWhenCreated"]; // FormField
		ItemField.Field = New DataCompositionField(FormItem.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object." + NameOfTableDetailsForControl + ".DisplayAvailabilityOnCreation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		FormItem = Items[NameOfTableDetailsForControl + "Uniqueness"]; // FormField
		ItemField.Field = New DataCompositionField(FormItem.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object." + NameOfTableDetailsForControl + ".AvailabilityUnique");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
	EndIf;
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	FormItem = Items[NameOfTableDetailsForControl + "PresentationOfHyperlinkProps"]; // FormField
	ItemField.Field = New DataCompositionField(FormItem.Name);
		
	If Not ThisIsTableForSeriesControl Then 
		ItemField = Item.Fields.Items.Add();
		FormItem = Items[NameOfTableDetailsForControl + "VisibleWithACondition"]; // FormField
		ItemField.Field = New DataCompositionField(FormItem.Name);
		
		ItemField = Item.Fields.Items.Add();
		FormItem = Items[NameOfTableDetailsForControl + "AvailableWithACondition"]; // FormField
		ItemField.Field = New DataCompositionField(FormItem.Name);
	EndIf;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + NameOfTableDetailsForControl + ".IsAddlAttribute");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	FormItem = Items[NameOfTableDetailsForControl + "AttributeRepresentation"]; // FormField
	ItemField.Field = New DataCompositionField(FormItem.Name);
	
	If Not ThisIsTableForSeriesControl Then 
		ItemField = Item.Fields.Items.Add();
		FormItem = Items[NameOfTableDetailsForControl + "ForCellSizeIsVisibleWithCondition"]; // FormField
		ItemField.Field = New DataCompositionField(FormItem.Name);
		
		ItemField = Item.Fields.Items.Add();
		FormItem = Items[NameOfTableDetailsForControl + "ForCellSizeIsAvailableWithCondition"]; // FormField
		ItemField.Field = New DataCompositionField(FormItem.Name);
	EndIf;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + NameOfTableDetailsForControl + ".IsAddlAttribute");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
		
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	FormItem = Items[NameOfTableDetailsForControl + "ForCellSizeItIsMandatoryToFillIn"]; // FormField
	ItemField.Field = New DataCompositionField(FormItem.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + NameOfTableDetailsForControl + ".IsAddlAttribute");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + NameOfTableDetailsForControl + ".RequiredToFill");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	FormItem = Items[NameOfTableDetailsForControl + "ForCellSizeItIsMandatoryToFillIn"]; // FormField
	ItemField.Field = New DataCompositionField(FormItem.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + NameOfTableDetailsForControl + ".IsAddlAttribute");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	//Element.Decoration.Set the value of the parameter ("Color text", color style.Hyperlink color);
	Item.Appearance.SetParameterValue("Format", NStr("vi = 'BF=''luôn luôn''; BT=''với điều kiện''';
													|ru = 'БЛ=''всегда''; БИ=''с условием''';
													|en = 'BF=''always''; BT=''with condition'''; fa = 'BF=''always''; BT=''with condition''';
													|it = 'BF=''sempre''; BT=''con condizione''';
													|pl = 'BF=''zawsze''; BT=''z warunkiem''';
													|tr = 'BF=''her zaman''; BT=''şartlı'''"));
	
	//
	
	If Not ThisIsTableForSeriesControl Then 
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		FormItem = Items[NameOfTableDetailsForControl + "ForCellSizeIsAvailableWithCondition"]; // FormField
		ItemField.Field = New DataCompositionField(FormItem.Name);
		
		ItemField = Item.Fields.Items.Add();
		FormItem = Items[NameOfTableDetailsForControl + "ForCellSizeIsVisibleWithCondition"]; // FormField
		ItemField.Field = New DataCompositionField(FormItem.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object." + NameOfTableDetailsForControl + ".IsAddlAttribute");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<dành cho mục tin bổ sung>';
														|ru = '<для доп. реквизитов>';
														|en = '<for add. attributes>'; fa = '<for add. attributes>';
														|it = '<per i requisiti aggiuntivi>';
														|pl = '<dla dod. atrybutów>';
														|tr = '<ek öznitelikler için>'"));
		Item.Appearance.SetParameterValue("Enabled", False);
		Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);	
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		FormItem = Items[NameOfTableDetailsForControl + "AvailableWithACondition"]; // FormField
		ItemField.Field = New DataCompositionField(FormItem.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object." + NameOfTableDetailsForControl + ".IsAddlAttribute");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		//Element.Decoration.Set the value of the parameter ("Color text", color style.Hyperlink color);
		Item.Appearance.SetParameterValue("Format", NStr("vi = 'BF=''luôn có sẵn''; BT=''có sẵn với điều kiện''';
														|ru = 'БЛ=''доступен всегда''; БИ=''доступен с условием''';
														|en = 'BF=''always available''; BT=''available with condition'''; fa = 'BF=''always available''; BT=''available with condition''';
														|it = 'BF=''disponibile sempre''; BT=''disponibile con condizione''';
														|pl = 'BF=''zawsze dostępny''; BT=''dostępny z warunkiem''';
														|tr = 'BF=''her zaman mevcut''; BT=''şartlı mevcut'''"));
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		FormItem = Items[NameOfTableDetailsForControl + "VisibleWithACondition"]; // FormField
		ItemField.Field = New DataCompositionField(FormItem.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object." + NameOfTableDetailsForControl + ".IsAddlAttribute");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		//Element.Decoration.Set the value of the parameter ("Color text", color style.Hyperlink color);
		Item.Appearance.SetParameterValue("Format", NStr("vi = 'BF=''luôn hiển thị''; BT=''hiển thị với điều kiện''';
														|ru = 'БЛ=''виден всегда''; БИ=''виден с условием''';
														|en = 'BF=''always visible''; BT=''visible with condition'''; fa = 'BF=''always visible''; BT=''visible with condition''';
														|it = 'BF=''visibile sempre''; BT=''visibile con condizione''';
														|pl = 'BF=''zawsze widoczny''; BT=''widoczny z warunkiem''';
														|tr = 'BF=''her zaman görünür''; BT=''şartlı görünür'''"));
		
		//
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowAttributesForProductsControl(Command)
	Items.PageCreationSettingsGroup.CurrentPage = Items.GroupDetailsForItemControl;
	SetAppearanceOfClickedHyperlink(Items.ShowAttributesForProductsControl, FormTextColor);
	SetStandardHyperlinkLayout(Items.ShowTheDetailsForMonitoringTheCharacteristics);	
	SetStandardHyperlinkLayout(Items.ShowDetailsForSeriesControl);	
EndProcedure

&AtClient
Procedure ShowTheDetailsForMonitoringTheCharacteristics(Command)
	Items.PageCreationSettingsGroup.CurrentPage = Items.GroupDetailsForMonitoringCharacteristics;
	SetStandardHyperlinkLayout(Items.ShowAttributesForProductsControl);
	SetAppearanceOfClickedHyperlink(Items.ShowTheDetailsForMonitoringTheCharacteristics, FormTextColor);	
	SetStandardHyperlinkLayout(Items.ShowDetailsForSeriesControl);	
EndProcedure

&AtClient
Procedure ShowDetailsForSeriesControl(Command)
	Items.PageCreationSettingsGroup.CurrentPage = Items.GroupDetailsForSeriesControl;
	SetStandardHyperlinkLayout(Items.ShowAttributesForProductsControl);
	SetStandardHyperlinkLayout(Items.ShowTheDetailsForMonitoringTheCharacteristics);	
	SetAppearanceOfClickedHyperlink(Items.ShowDetailsForSeriesControl, FormTextColor);	
EndProcedure

&AtClientAtServerNoContext 
Procedure SetStandardHyperlinkLayout(Button)
	
	Button.Font = New Font;
	Button.TextColor = New Color;
	
EndProcedure

&AtClientAtServerNoContext 
Procedure SetAppearanceOfClickedHyperlink(Button, TextColor)
	
	Button.Font = New Font(,,True);
	Button.TextColor = TextColor;
	
EndProcedure

&AtServer
Procedure SetPricingDetails()
	
	Catalogs.ItemKinds.SetDefaultPricingDetails(Object);
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure SelectViewOwner(MeaningfulPartOfInscriptionName)
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("CurrentKind", Object.Ref);
	ChoiceFormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
	
	SelectionFormSelection = ThisObject[NameOfOwnerSAccountDetails(MeaningfulPartOfInscriptionName)];
	
	ChoiceFormParameters.Insert("Filter", SelectionFormSelection);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("MeaningfulPartOfInscriptionName", MeaningfulPartOfInscriptionName);
	
	CallbackDescription = New CallbackDescription("SelectViewOwnerCompletion", ThisObject, AdditionalParameters);
	
	OpenForm("Catalog.ItemKinds.Form.ChoiceForm",
				ChoiceFormParameters,
				ThisObject,
				,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectViewOwnerCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		CustomizeForm();
	Else
		Object[NameOfOwnerSProps(AdditionalParameters.MeaningfulPartOfInscriptionName)] = Result;
		SelectViewOwnerServer(AdditionalParameters.MeaningfulPartOfInscriptionName);	
	EndIf;
	
EndProcedure

&AtServer
Procedure SelectViewOwnerServer(MeaningfulPartOfInscriptionName)
	
	Catalogs.ItemKinds.SetDefaultPricingDetails(Object);
	FillInListOfProductTypesWithSameOwner(MeaningfulPartOfInscriptionName);
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure FillInListOfProductTypesWithSameOwner(MeaningfulPartOfInscriptionName)
	
	Specifics = FeaturesOfOutputOfInscriptionByOwner(MeaningfulPartOfInscriptionName);
	
	ListOfSpecies = ThisObject[ListNameTypesOfProductsWithSameOwner(MeaningfulPartOfInscriptionName)];
	OwnerView = Object[NameOfOwnerSProps(MeaningfulPartOfInscriptionName)];
		
	If (Not Specifics.ThisSpeciesItselfIsOwner 
		And Not ValueIsFilled(OwnerView))
		Or Not Specifics.NeedTextInCaption Then
		ListOfSpecies.Clear();
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	ItemKinds.Ref AS Ref
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|WHERE
	|	&OwnerDetails_ = &OwnerView
	|	AND &OwnerView <> VALUE(Catalog.ItemKinds.EmptyRef)
	|	AND ItemKinds.Ref <> &Ref
	|	AND NOT ItemKinds.DeletionMark";
	
	QueryText = StrReplace(QueryText, "&OwnerDetails_", "ItemKinds." + NameOfOwnerSProps(MeaningfulPartOfInscriptionName));
	
	Query = New Query;
	Query.Text = QueryText;
	If Specifics.ThisSpeciesItselfIsOwner Then
		Query.SetParameter("OwnerView", Object.Ref);
	Else
		Query.SetParameter("OwnerView", OwnerView);
	EndIf;
	Query.SetParameter("Ref", Object.Ref);
	
	ListOfSpecies.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

&AtServer
Function FeaturesOfOutputOfInscriptionByOwner(MeaningfulPartOfInscriptionName)
	Specifics = New Structure("ThisSpeciesItselfIsOwner,NeedTextInCaption,YouCanEditOwner");
	
	Specifics.ThisSpeciesItselfIsOwner = False;
	Specifics.NeedTextInCaption           = False;
	Specifics.YouCanEditOwner  = False;
	
	If MeaningfulPartOfInscriptionName = "OfProductCategories" Then
		If Not Object.ProductCategoriesCommonWithAnotherKindOfItems Then
			Specifics.ThisSpeciesItselfIsOwner = True;
		EndIf;
		
		Specifics.NeedTextInCaption = GetFunctionalOption("UseProductCategories");
		Specifics.YouCanEditOwner = Not Items.ConfigureProductCategories.ReadOnly;
		
	ElsIf MeaningfulPartOfInscriptionName = "Series_" Then
		If Not Object.BatchSettingsAreTakenFromOtherItemsKind Then
			Specifics.ThisSpeciesItselfIsOwner = True;
		EndIf;
		
		Specifics.NeedTextInCaption = Object.KeepAccountingByBatch;
		Specifics.YouCanEditOwner = Not Items.KeepAccountingByBatch.ReadOnly;
		
	ElsIf MeaningfulPartOfInscriptionName = "Features" Then
		If Object.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind Then
			Specifics.ThisSpeciesItselfIsOwner = True;
		EndIf;	
		
		Specifics.NeedTextInCaption =  Object.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind
											Or  Object.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind;
		Specifics.YouCanEditOwner = Not Items.UseVariants.ReadOnly;
		
	EndIf;
	
	Return Specifics;
EndFunction

&AtServer
Function FeaturesOfOutputOfInscriptionChangesInSetOfPricingDetails(MeaningfulPartOfInscriptionName)
	Specifics = New Structure("NeedTextInCaption,CanBeEdited");
	
	Specifics.NeedTextInCaption           = False;
	Specifics.CanBeEdited  = False;
	
	If MeaningfulPartOfInscriptionName = "SetOfSeries" Then
		
		Specifics.NeedTextInCaption = Object.SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.UseByAttributes;
		Specifics.CanBeEdited = Not Items.SettingsOfPriceKeyByBatch.ReadOnly;
		
	ElsIf MeaningfulPartOfInscriptionName = "Characteristics" Then
		
		Specifics.NeedTextInCaption =  Object.SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.UseByAttributes;
		Specifics.CanBeEdited = Not Items.SettingsOfPriceKeyByItemVariant.ReadOnly;
		
	EndIf;
	
	Return Specifics;
EndFunction

&AtServer
Procedure FormInscriptionByTypeOfOwner(MeaningfulPartOfInscriptionName);
	Specifics = FeaturesOfOutputOfInscriptionByOwner(MeaningfulPartOfInscriptionName);
	
	RowsArray = New Array;
	If Specifics.NeedTextInCaption Then
		
		ListOfSpecies = ThisObject[ListNameTypesOfProductsWithSameOwner(MeaningfulPartOfInscriptionName)];
		PresentationOfNumberOfSpecies = "";
		
		If Specifics.ThisSpeciesItselfIsOwner Then
			
			If MeaningfulPartOfInscriptionName <> "Series_" Then
				RowsArray.Add(New FormattedString(NStr("vi = 'Danh sách';
														|ru = 'Список';
														|en = 'List'; fa = 'فهرست';
														|it = 'Elenco';
														|pl = 'List';
														|tr = 'Listenin'"),,,,"OpenList"));
				If ListOfSpecies.Count() > 0 Then
					RowsArray.Add(" ");
					RowsArray.Add(NStr("vi = 'vẫn dùng trong';
										|ru = 'используется еще в';
										|en = 'also used in'; fa = 'also used in';
										|it = 'viene anche utilizzato in';
										|pl = 'jest używane jeszcze w';
										|tr = 'hala kullanıldığı'"));
					RowsArray.Add(" ");
					PresentationOfNumberOfSpecies = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(ListOfSpecies.Count(),
																													NStr("vi = 'dạng, dạng, dạng';
																														|ru = 'видом,видами,видами';
																														|en = 'kind, kinds, kinds'; fa = 'kind, kinds, kinds';
																														|it = 'con il tipo, con i tipi, con i tipi';
																														|pl = 'rodzajem,rodzajami,rodzajami';
																														|tr = 'türüyle,türleriyle,türleriyle'"));
				EndIf;
			Else
				If ListOfSpecies.Count() > 0 Then
					RowsArray.Add(" ");
					RowsArray.Add(NStr("vi = 'và hơn nữa';
										|ru = 'и еще';
										|en = 'and'; fa = 'و';
										|it = 'e anche';
										|pl = 'i jeszcze';
										|tr = 've daha'"));
					RowsArray.Add(" ");
					PresentationOfNumberOfSpecies = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(ListOfSpecies.Count(),
																													NStr("vi = 'dạng, dạng, dạng';
																														|ru = 'видом,видами,видами';
																														|en = 'kind, kinds, kinds'; fa = 'kind, kinds, kinds';
																														|it = 'con il tipo, con i tipi, con i tipi';
																														|pl = 'rodzajem,rodzajami,rodzajami';
																														|tr = 'türüyle,türleriyle,türleriyle'"));
				EndIf;
			EndIf;
			
		Else
			OwnerView = Object[NameOfOwnerSProps(MeaningfulPartOfInscriptionName)];
			
			If Not ValueIsFilled(OwnerView) Then
				RowsArray.Add(New FormattedString(NStr("vi = '<chưa chọn dạng>';
														|ru = '<вид не выбран>';
														|en = '<kind is not selected>'; fa = '<kind is not selected>';
														|it = '<nessun tipo è selezionato>';
														|pl = '<nie wybrano rodzaju>';
														|tr = '<tür seçilmedi>'"),New Font(,,True),StyleColors.SpecialTextColor));
				RowsArray.Add(" ");
				RowsArray.Add(New FormattedString(NStr("vi = 'Chọn';
														|ru = 'Выбрать';
														|en = 'Select'; fa = 'انتخاب';
														|it = 'Selezionare';
														|pl = 'Select';
														|tr = 'Seç'"),,,,"ChangeOwner"));
			Else	
				
				KindPresentaion = TMCommonUseClientServer.PresentationOfStringWithMaximumLengthOf(String(OwnerView), 40);
				RowsArray.Add(New FormattedString(KindPresentaion,,,,"OpenOwner"));
				
				If Specifics.YouCanEditOwner Then
					RowsArray.Add(" (");
					RowsArray.Add(New FormattedString(NStr("vi = 'thay đổi';
															|ru = 'изменить';
															|en = 'change'; fa = 'change';
															|it = 'modificare';
															|pl = 'change';
															|tr = 'değiştir'"),,,,"ChangeOwner"));
					RowsArray.Add(")");
				EndIf;	
				
				If ListOfSpecies.Count() > 0 Then
					RowsArray.Add(" ");
					RowsArray.Add(NStr("vi = 'và hơn nữa';
										|ru = 'и еще с';
										|en = 'and with'; fa = 'and with';
										|it = 'e anche con';
										|pl = 'i jeszcze z';
										|tr = 've daha'"));
					RowsArray.Add(" ");
					PresentationOfNumberOfSpecies = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(ListOfSpecies.Count(),
																													NStr("vi = 'dạng, dạng, dạng';
																														|ru = 'видом,видами,видами';
																														|en = 'kind, kinds, kinds'; fa = 'kind, kinds, kinds';
																														|it = 'con il tipo, con i tipi, con i tipi';
																														|pl = 'rodzajem,rodzajami,rodzajami';
																														|tr = 'türüyle,türleriyle,türleriyle'"));
				EndIf;
			EndIf;
		EndIf;
		
		If Not IsBlankString(PresentationOfNumberOfSpecies) Then
			RowsArray.Add(New FormattedString(PresentationOfNumberOfSpecies,
													,
													,
													,
													"OpenListOfViewsWithSameOwner"));
		EndIf;
	EndIf;
	FormItem = Items[NameOfOwnerSProps(MeaningfulPartOfInscriptionName)]; // FormDecoration
	FormItem.Title = New FormattedString(RowsArray);
	
EndProcedure

&AtServer
Procedure CreatePricingSectionLabel(MeaningfulPartOfInscriptionName);
	Specifics = FeaturesOfOutputOfInscriptionChangesInSetOfPricingDetails(MeaningfulPartOfInscriptionName);
	
	If Specifics.NeedTextInCaption Then
		
		RowsArray = New Array;
	
		If MeaningfulPartOfInscriptionName = "Characteristics" Then
			
			ArrayOfDetailsDescriptions = GetDetailsForPriceKey(MeaningfulPartOfInscriptionName);
			
			If ArrayOfDetailsDescriptions.Count() Then
				
				RowsArray.Add("<");
				RowsArray.Add(StrConcat(ArrayOfDetailsDescriptions, ", "));
				RowsArray.Add(">");
				
			Else
				
				RowsArray.Add(NStr("vi = '<Chưa chọn các mục tin>';
									|ru = '<Реквизиты не выбраны>';
									|en = '<Attributes are not selected>'; fa = '<Attributes are not selected>';
									|it = '<Attributi non selezionati>';
									|pl = '<Atrybuty nie są wybrane>';
									|tr = '<Öznitelikler seçilmedi>'"));
					
			EndIf;
			
			FormItem = Items.ChangeTheSetOfDetailsForTheKeyPriceCharacteristics;
			
		ElsIf MeaningfulPartOfInscriptionName = "SetOfSeries" Then
			
			ArrayOfDetailsDescriptions = GetDetailsForPriceKey(MeaningfulPartOfInscriptionName);

			If ArrayOfDetailsDescriptions.Count() Then
				
				RowsArray.Add("<");
				RowsArray.Add(StrConcat(ArrayOfDetailsDescriptions, ", "));
				RowsArray.Add(">");
				
			Else
				
				RowsArray.Add(NStr("vi = '<Chưa chọn các mục tin>';
									|ru = '<Реквизиты не выбраны>';
									|en = '<Attributes are not selected>'; fa = '<Attributes are not selected>';
									|it = '<Attributi non selezionati>';
									|pl = '<Atrybuty nie są wybrane>';
									|tr = '<Öznitelikler seçilmedi>'"));
					
			EndIf;
			
			FormItem = Items.ChangeTheSetOfDetailsForTheSeriesPriceKey;
			
		EndIf;
		
		If Specifics.CanBeEdited Then
			RowsArray.Add(" (");
			RowsArray.Add(New FormattedString(NStr("vi = 'thay đổi';
													|ru = 'изменить';
													|en = 'change'; fa = 'change';
													|it = 'modificare';
													|pl = 'change';
													|tr = 'değiştir'"),,,,"ChangeSettingsForUsingBankingDetails"));
			RowsArray.Add(")");
		EndIf;
		
		FormItem.Title = New FormattedString(RowsArray);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingNavigationLinkOfLabelByType(Var_URL, MeaningfulPartOfInscriptionName, StandardProcessing);
	
	StandardProcessing = False;
	
	If Var_URL = "OpenOwner" Then
		ShowValue(,Object[NameOfOwnerSProps(MeaningfulPartOfInscriptionName)]);
	ElsIf Var_URL = "ChangeOwner" Then
		SelectViewOwner(MeaningfulPartOfInscriptionName);
	ElsIf Var_URL = "OpenListOfViewsWithSameOwner" Then
		ShowValue(,ThisObject[ListNameTypesOfProductsWithSameOwner(MeaningfulPartOfInscriptionName)]);
	ElsIf Var_URL = "OpenList" Then
		If Not ValueIsFilled(Object.Ref) Then
			
			QueryText = NStr("vi = 'Vẫn chưa ghi lại dữ liệu.
			|Chỉ có thể chuyển đến danh sách sau khi ghi lại dữ liệu.';
			|ru = 'Данные еще не записаны.
			|Переход к списку возможен только после записи данных.';
			|en = 'Data has not been saved yet.
			|You can go to the list only after the data is saved.'; fa = 'Data has not been saved yet.
			|You can go to the list only after the data is saved.';
			|it = 'Dati non ancora salvati.
			|Il passaggio all''elenco è possibile solo dopo la scrittura dei dati.';
			|pl = 'Dane nie zostały jeszcze zapisane.
			|Przejście do listy jest możliwe tylko po zapisaniu danych.';
			|tr = 'Veriler henüz kaydedilmedi.
			|Listeye geçiş sadece verilerin kaydından sonra mümkündür.'");
			
			QuestionButtons = New ValueList;
			QuestionButtons.Add(DialogReturnCode.OK, NStr("vi = 'Ghi lại';
															|ru = 'Записать';
															|en = 'Save'; fa = 'ذخیره';
															|it = 'Salvare';
															|pl = 'Save';
															|tr = 'Kaydet'"));
			QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																|ru = 'Отмена';
																|en = 'Cancel'; fa = 'انصراف';
																|it = 'Annulla';
																|pl = 'Cancel';
																|tr = 'İptal'"));
			
			AdditionalQuestionParameters_ = New Structure;
			AdditionalQuestionParameters_.Insert("MeaningfulPartOfInscriptionName", MeaningfulPartOfInscriptionName);
			
			ShowQueryBox(New CallbackDescription("OpenListCompletion", ThisObject, AdditionalQuestionParameters_),
							QueryText,
							QuestionButtons);
			Return;
			
		EndIf;
		
		OpenFragmentList(MeaningfulPartOfInscriptionName);
	Else
		ExceptionText = NStr("vi = 'Tham chiếu dẫn hướng không xác định.';
							|ru = 'Неизвестная навигационная ссылка.';
							|en = 'Unknown URL'; fa = 'Unknown URL';
							|it = 'Indirizzo di navigazione sconosciuto.';
							|pl = 'Nieznany odnośnik nawigacyjny.';
							|tr = 'Bilinmeyen URL.'");
		
		Raise ExceptionText;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenListCompletion(QuestionResult, AdditionalParameters) Export
    
    If QuestionResult = DialogReturnCode.Cancel Then
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
    
   OpenFragmentList(AdditionalParameters.MeaningfulPartOfInscriptionName);

EndProcedure

&AtClient
Procedure OpenFragmentList(MeaningfulPartOfInscriptionName)
    
	If MeaningfulPartOfInscriptionName = "OfProductCategories" Then
		OpeningParameters = New Structure;
	    OpeningParameters.Insert("Filter", New Structure("Owner", Object.Ref));
	    OpeningParameters.Insert("CloseOnOwnerClose", True);
	    
	    OpenForm("Catalog.ProductCategories.ListForm",
					OpeningParameters,
					ThisObject,
					,
					,
					,
					,
					FormWindowOpeningMode.LockOwnerWindow);
				
	ElsIf MeaningfulPartOfInscriptionName = "Features" Then
				
	    OpeningParameters = New Structure;
	    OpeningParameters.Insert("Filter", New Structure("Owner", Object.Ref));
	    OpeningParameters.Insert("CloseOnOwnerClose", True);
	    
	    OpenForm("Catalog.ItemsCharacteristics.Form.ListForm",
					OpeningParameters,
					ThisObject,
					,
					,
					,
					,
					FormWindowOpeningMode.LockOwnerWindow);
	EndIf;

EndProcedure

&AtServer
Procedure RecordCommonPropertyOnServer(ValueSelected, SetOfAdditionalInformationDetails, IsAdditionalInfoSets)
	
	Block = New DataLock;
	
	LockItem = Block.Add("Catalog.AdditionalAttributesAndInfoSets");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.SetValue("Ref", SetOfAdditionalInformationDetails);
	
	Try
		LockDataForEdit(SetOfAdditionalInformationDetails);
		BeginTransaction();
		Try
			Block.Lock();
			LockDataForEdit(SetOfAdditionalInformationDetails);
			
			CurrentSetObject = SetOfAdditionalInformationDetails.GetObject();
			If CurrentSetObject.DataVersion <> DataVersionOfTheCurrentSet Then
				If IsAdditionalInfoSets Then
					Raise
					NStr("vi = 'Chưa thực hiện thao tác vì thành phần thông tin bổ sung
					|đã thay đổi bởi người sử dụng khác.
					|Đã đọc thành phần mới của thông tin bổ sung.
					|
					|Hãy thử thao tác lại, nếu cần.';
					|ru = 'Действие не выполнено, так как состав дополнительных сведений
					|был изменен другим пользователем.
					|Новый состав дополнительных сведений прочитан.
					|
					|Повторите действие, если требуется.';
					|en = 'The action is not performed because additional information 
					|was changed by another user.
					|New additional information is read.
					|
					|Repeat the action if necessary.'; fa = 'The action is not performed because additional information 
					|was changed by another user.
					|New additional information is read.
					|
					|Repeat the action if necessary.';
					|it = 'L''azione non è stata completata poiché la composizione delle informazioni aggiuntive
					|è stata modificata da un altro utente.
					|La nuova composizione delle informazioni aggiuntive è stata letta.
					|
					|Se necessario, ripetere l''azione.';
					|pl = 'Działanie nie zostało wykonane, ponieważ skład informacji dodatkowych
					|został zmieniony przez innego użytkownika.
					|Nowy skład informacji dodatkowych został odczytany.
					|
					|Powtórz działanie, jeśli jest to konieczne.';
					|tr = 'Ek bilgilerin 
					|içeriği başka bir kullanıcı tarafından değiştirildiği için eylem gerçekleştirilemez. 
					|Ek bilgilerin yeni içeriği hazır. 
					|
					|Gerekirse işlemi tekrarlayın.'");
				Else
					Raise
					NStr("vi = 'Chưa thực hiện thao tác vì thành phần mục tin bổ sung
					|đã thay đổi bởi người sử dụng khác.
					|Đã đọc thành phần mới của mục tin bổ sung.
					|
					|Hãy thử thao tác lại, nếu cần.';
					|ru = 'Действие не выполнено, так как состав дополнительных реквизитов
					|был изменен другим пользователем.
					|Новый состав дополнительных реквизитов прочитан.
					|
					|Повторите действие, если требуется.';
					|en = 'The action is not performed because additional attributes 
					|were changed by another user.
					|New additional attributes are read.
					|
					|Repeat the action if necessary.'; fa = 'The action is not performed because additional attributes 
					|were changed by another user.
					|New additional attributes are read.
					|
					|Repeat the action if necessary.';
					|it = 'L''azione non è stata completata poiché la composizione dei requisiti aggiuntivi
					|è stata modificata da un altro utente.
					|La nuova composizione dei requisiti aggiuntivi è stata letta.
					|
					|Se necessario, ripetere l''azione.';
					|pl = 'Działanie nie zostało wykonane, ponieważ skład atrybutów dodatkowych
					|został zmieniony przez innego użytkownika
					|Nowy skład atrybutów dodatkowych został odczytany.
					|
					|Powtórz działanie, jeśli jest to konieczne.';
					|tr = 'Ek özniteliklerin
					|içeriği başka bir kullanıcı tarafından değiştirildiği için eylem gerçekleştirilemez.
					|Ek özniteliklerin yeni içeriği hazır.
					|
					|Gerekirse işlemi tekrarlayın.'");
				EndIf;
			EndIf;
			
			TabularSection = CurrentSetObject[?(IsAdditionalInfoSets,
				"AdditionalInfo", "AdditionalAttributes")];
			
			FoundRow = TabularSection.Find(ValueSelected.CommonProperty, "Property");
			
			If FoundRow = Undefined Then
				NewRow = TabularSection.Add();
				NewRow.Property = ValueSelected.CommonProperty;
				CurrentSetObject.Write();
				
			ElsIf FoundRow.DeletionMark Then
				FoundRow.DeletionMark = False;
				CurrentSetObject.Write();
			EndIf;
			
			Modified = True;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	Except
		UnlockDataForEdit(SetOfAdditionalInformationDetails);
		Raise;
	EndTry;
	
	WhenRecordingSetOfAdditionalDetailsAndInformationOnServer();
	
EndProcedure

&AtServerNoContext
Function GetSetDataVersion(Set)
	Return Common.ObjectAttributeValue(Set, "DataVersion");
EndFunction

&AtClient
Procedure ThereAreIndividualSettingsOfSeriesAccountingPolicyOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		ThereAreIndividualSettingsOfSeriesAccountingPolicy = True;
		Return;
	EndIf;
	
	SetDefaultSeriesAccountingPolicy();
	ThereAreIndividualSettingsOfSeriesAccountingPolicyOnChangeServer();
	UpdateAlertOnWarehouseClient();
	
EndProcedure

&AtServer
Procedure ThereAreIndividualSettingsOfSeriesAccountingPolicyOnChangeServer()
	
	ActionWhenChangingSeriesAccountingPolicies();
	DeleteDuplicatesOfWarehousesWithoutAccountingForProductSeries();
	
EndProcedure

&AtServer
Procedure ActionWhenChangingSeriesAccountingPolicies()
	
	FillInFormDetailsUsingItemDetails();
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure DeleteDuplicatesOfWarehousesWithoutAccountingForProductSeries()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BatchAccountingPolicies.Warehouse AS Warehouse,
	|	1                        AS NumberOfWarehouses
	|INTO BatchAccountingPolicies
	|FROM
	|	&PolicyTable AS BatchAccountingPolicies
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BatchAccountingPolicies.Warehouse                    AS Warehouse,
	|	SUM(BatchAccountingPolicies.NumberOfWarehouses) AS NumberOfWarehouses
	|FROM
	|	BatchAccountingPolicies AS BatchAccountingPolicies
	|
	|GROUP BY
	|	BatchAccountingPolicies.Warehouse
	|
	|HAVING
	|	SUM(BatchAccountingPolicies.NumberOfWarehouses) > 1";
	
	Query.SetParameter("PolicyTable", Object.BatchAccountingPolicies.Unload());
	
	WarehouseDuplicates      = Query.Execute().Unload().UnloadColumn("Warehouse");
	PoliciesToRemove = New Array;
	
	For Each RepeatableWarehouse In WarehouseDuplicates Do
		RowFilter    = New Structure("Warehouse", RepeatableWarehouse);
		PolicyLines = Object.BatchAccountingPolicies.FindRows(RowFilter);
		
		For Cnt = 0 To PolicyLines.UBound() Do
			If Cnt = 0 Then
				Continue;
			EndIf;
			
			PoliciesToRemove.Add(PolicyLines[Cnt]);
		EndDo;
	EndDo;
	
	For Each PolicyToDelete In PoliciesToRemove Do
		Object.BatchAccountingPolicies.Delete(PolicyToDelete);
	EndDo;
	
EndProcedure

// Deletes duplicates of strings, as well as hidden strings if an overriding string is entered.
//
// Parameters:
//  Warehouse				 - CatalogRef.Warehouses, CatalogRef.BusinessStructure - new line warehouse or division
//  BatchAccountingPolicy	 - CatalogRef.BatchAccountingPolicies - accounting policy for series a new line.
//
&AtServer
Procedure AfterAddingNewUnitWarehouseToBatchAccountingPolicies(Warehouse, BatchAccountingPolicy)
	
	LinesToDelete = New Array();
	LinesWithMatchingPolicies = New Array();
	
	// Search for all available lines for the current warehouse
	FilterStructure1 = New Structure();
	FilterStructure1.Insert("Warehouse", Warehouse);
	
	FoundRows = Object.BatchAccountingPolicies.FindRows(FilterStructure1);
	
	IndexesOfFoundRows = FoundRows.Count() - 1;
	For IndexOf = 0 To IndexesOfFoundRows Do
		String = FoundRows[IndexOf];
		
		If String.BatchAccountingPolicy = Object.BatchAccountingPolicy Then
			// Deleting hidden rows.
			LinesToDelete.Add(String);
		ElsIf String.BatchAccountingPolicy = BatchAccountingPolicy Then
			// Filling in duplicate lines for the subsequent removal of unnecessary ones
			LinesWithMatchingPolicies.Add(String);
		Else
			// The lines where the policy differs from the default remain - the user
			// must explicitly choose which line to leave.
		EndIf;
		
	EndDo;
	
	For Each String In LinesToDelete Do
		Object.BatchAccountingPolicies.Delete(String);
		
		StringInArrayOfMatchingPolicies = LinesWithMatchingPolicies.Find(String);
		If StringInArrayOfMatchingPolicies <> Undefined Then
			LinesWithMatchingPolicies.Delete(StringInArrayOfMatchingPolicies);
		EndIf;
	EndDo;
	
	If LinesWithMatchingPolicies.Count() > 1 Then
		For IndexOf = 1 To LinesWithMatchingPolicies.Count() - 1 Do
			String = LinesWithMatchingPolicies[IndexOf];
			Object.BatchAccountingPolicies.Delete(String);
		EndDo;
	EndIf;
	
	ActionWhenChangingSeriesAccountingPolicies();
	
EndProcedure

&AtClient
Procedure SetDefaultSeriesAccountingPolicy()
	
	For Each String In Object.BatchAccountingPolicies Do
		String.BatchAccountingPolicy = Object.BatchAccountingPolicy;
	EndDo;
	
EndProcedure

&AtServer
Procedure DeleteEmptyRowsOfSeriesAccountingPolicies()
	
	FilterParameters = New Structure();
	FilterParameters.Insert("Warehouse", Undefined);
	FilterParameters.Insert("BatchAccountingPolicy", Catalogs.BatchAccountingPolicies.EmptyRef());
	LinesToDelete = Object.BatchAccountingPolicies.FindRows(FilterParameters);
	
	For Each ElementToDelete In LinesToDelete Do
		Object.BatchAccountingPolicies.Delete(ElementToDelete);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInFormDetailsUsingItemDetails()
	
	If Object.UseCustomNameForPrinting Then
		UseIndividualName = "UseIndividualName";
	Else
		UseIndividualName = "UseNameFromConstant";
	EndIf;
	
	If Object.KeepAccountingByBatch Then
		If Object.BatchSettingsAreTakenFromOtherItemsKind Then
			OptionOfSeriesSettings = "AreUsedAlsoAsInOtherKindOfProductList";
		Else
			OptionOfSeriesSettings = "ConfiguredForProductType";
		EndIf;
	Else
		OptionOfSeriesSettings = "";
	EndIf;
	
	If Object.ProductCategoriesCommonWithAnotherKindOfItems Then
		ConfigureProductCategories = "CommonWithOtherItemKind";
	Else
		ConfigureProductCategories = "ConfiguredForThisProductKind";
	EndIf;
	
	If Object.UsePackages Then
		If Object.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem Then
			PackagingUsage = "Individual_Set";
		Else
			PackagingUsage = "SharedSet";
		EndIf;
	EndIf;
	
	ProductCategoriesOwnerSelection = ProductsServer.SelectionOfOwnerOfSubordinateCatalogs(Object, "ProductCategoryOwner");
	CharacteristicsOwnerSelection     = ProductsServer.SelectionOfOwnerOfSubordinateCatalogs(Object, "ItemVariantsOwner");
	SeriesOwnerSelection             = ProductsServer.SelectionOfOwnerOfSubordinateCatalogs(Object, "BatchOwner");
	
	FillInListOfProductTypesWithSameOwner("OfProductCategories");
	FillInListOfProductTypesWithSameOwner("Features");
	FillInListOfProductTypesWithSameOwner("Series_");
	
	ThereAreIndividualSettingsOfSeriesAccountingPolicy = False;
	
	For Each RowOfTables In Object.BatchAccountingPolicies Do
		
		RowOfTables.ThisIsAWarehousePolicy = Not ValueIsFilled(RowOfTables.Warehouse)
										Or (TypeOf(RowOfTables.Warehouse) = Type("CatalogRef.Warehouses"));
		RowOfTables.CorrespondsToThePolicyByDefault = RowOfTables.BatchAccountingPolicy = Object.BatchAccountingPolicy;
		
		If Not RowOfTables.CorrespondsToThePolicyByDefault Then
			ThereAreIndividualSettingsOfSeriesAccountingPolicy = True;
		EndIf;
		
	EndDo;
	
	ParametersThatAffectSelectionOfPoliciesSpecifyingSeriesBeforeChangingStructure = ProductsClientServer.SelectionParametersForSeriesAccountingPolicies();
	FillPropertyValues(ParametersThatAffectSelectionOfPoliciesSpecifyingSeriesBeforeChangingStructure, Object);
	ParametersAffectingTheSelectionOfPoliciesSpecifyingTheSeriesBeforeChange = New FixedStructure(ParametersThatAffectSelectionOfPoliciesSpecifyingSeriesBeforeChangingStructure);
	
	FillInListsOfAdditionalInformationDetails();

EndProcedure

&AtClientAtServerNoContext
Procedure CollapseExpandAllGroups(Form)
	
	NamesOfGroupsToCollapse = NamesOfGroupsToCollapse();
	
	For Each GroupName In NamesOfGroupsToCollapse Do
		
		If Form.ConfigureFormVisibility = "ShowAllItems" Then
			Form.Items[GroupName].Show();
		Else
			Form.Items[GroupName].Hide();
		EndIf;
		
	EndDo;

EndProcedure

&AtClientAtServerNoContext
Function NamesOfGroupsToCollapse()
	
	NamesOfGroupsToCollapse = New Array;
	
	NamesOfGroupsToCollapse.Add("PageGeneral");
	NamesOfGroupsToCollapse.Add("AdditionalBankingDetailsPage");
	NamesOfGroupsToCollapse.Add("PricingSettingsPage");	
	NamesOfGroupsToCollapse.Add("PageNameTemplates");
	NamesOfGroupsToCollapse.Add("QuickSelectionPanelSettingsPage");
	NamesOfGroupsToCollapse.Add("CreationSettingsPage");
	NamesOfGroupsToCollapse.Add("DefaultValuePage");
	NamesOfGroupsToCollapse.Add("AddInformationPage");
	
	Return NamesOfGroupsToCollapse;
EndFunction

&AtClient
Procedure DetailsForControlSelection(MeaningfulPartOfName, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData	= Items[NameOfTableDetailsForControl(MeaningfulPartOfName)].CurrentData;
	SettingKind	= TypeOfAttributeSettingsForMonitoringByFieldName(Items, Field.Name);
	
	If Not ThereIsTheRightToEdit Then
		Return;
	ElsIf CurrentData = Undefined Then
		Return;
	ElsIf Not CurrentData.IsAddlAttribute Then
		Return;
	ElsIf Not CurrentData.RequiredToFill
		And SettingKind = "RequiredToFill" Then
		
		Return;
		
	EndIf;
	
	ProcessingParameters = New Structure;
	ProcessingParameters.Insert("CurrentProperty",		CurrentData.Property);
	ProcessingParameters.Insert("MeaningfulPartOfName",	MeaningfulPartOfName);
	ProcessingParameters.Insert("Field",					Field);
	
	If Modified Then
		CallbackDescription	= New CallbackDescription("DetailsForControlSelectionCompletion", ThisObject, ProcessingParameters);
		QueryText		= NStr("vi = 'Trước khi mở biểu mẫu tùy chỉnh, cần ghi lại phần tử. Tiếp tục?';
								|ru = 'Перед открытием формы настройки необходимо записать элемент. Продолжить?';
								|en = 'Before opening the settings form, you should save the item. Continue?'; fa = 'Before opening the settings form, you should save the item. Continue?';
								|it = 'Prima di aprire il modulo di configurazione è necessario salvare l''elemento. Continuare?';
								|pl = 'Przed otwarciem formularza należy zapisać element. Kontynuować?';
								|tr = 'Ayar formunu açmadan önce öğeyi kaydetmeniz gerekmektedir. Devam edilsin mi?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel);
		
		Return;
	EndIf;
	
	DetailsForControlSelectionCompletion(Undefined, ProcessingParameters);
	
EndProcedure

&AtClient
Procedure DetailsForControlSelectionCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined
		And Result <> DialogReturnCode.OK Then
		
		Return;
		
	EndIf;
	
	If Result = DialogReturnCode.OK Then
		If Not Write() Then
			Return;
		EndIf;
	EndIf;
	
	CurrentProperty		= AdditionalParameters.CurrentProperty;
	MeaningfulPartOfName	= AdditionalParameters.MeaningfulPartOfName;
	Field				= AdditionalParameters.Field;
	
	FilterBankingDetails_			= New Structure("Property", CurrentProperty);
	LinesOfBankingDetails		= Object[NameOfTableDetailsForControl(MeaningfulPartOfName)].FindRows(FilterBankingDetails_);
	CurrentRow			= Undefined;
	EditableProperty	= Undefined;
	
	If LinesOfBankingDetails.Count() > 0 Then
		CurrentRow			= LinesOfBankingDetails[0];
		EditableProperty	= LinesOfBankingDetails[0].Property;
	Else
		Return;
	EndIf;
	
	If CurrentRow.IsCommonAttribute Then
		
		If MeaningfulPartOfName = "OfProductItem" Then
			CurrentPropertiesSet = PropertiesSetByName("Catalog_Products_Overall");
		ElsIf MeaningfulPartOfName = "Features" Then
			CurrentPropertiesSet = PropertiesSetByName("Catalog_ItemsCharacteristics_Overall");
		ElsIf MeaningfulPartOfName = "Series_" Then
			CurrentPropertiesSet = PropertiesSetByName("Catalog_ItemsBatches_Overall");
		EndIf;
		
	Else
		
		If MeaningfulPartOfName = "OfProductItem" Then
			CurrentPropertiesSet = Object.PropertiesSet;
		ElsIf MeaningfulPartOfName = "Features" Then
			CurrentPropertiesSet = Object.CharacteristicsPropertySet;
		ElsIf MeaningfulPartOfName = "Series_" Then
			CurrentPropertiesSet = Object.BatchPropertySet;
		EndIf;
		
	EndIf;
	
	SettingKind = TypeOfAttributeSettingsForMonitoringByFieldName(Items, Field.Name);
	EditablePropertySettingsKind = "";
	
	If SettingKind = "AttributeRepresentation" Then
		
		FormParametersProperties = New Structure;
		FormParametersProperties.Insert("CurrentPropertiesSet",	CurrentPropertiesSet);
		FormParametersProperties.Insert("Key",					EditableProperty);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.ObjectForm",
					FormParametersProperties,
					ThisObject,
					,
					,
					,
					,
					FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf SettingKind = "isVisible"
		Or SettingKind = "Available"
		Or SettingKind = "RequiredToFill" Then
		
		FillInDependenciesOfPropertyBeingEdited();
		
		EditablePropertySettingsKind = SettingKind;
		
		FormParameters = New Structure;
		FormParameters.Insert("AdditionalAttribute",	EditableProperty);
		FormParameters.Insert("AttributesDependencies",	EditablePropertyOfDependence);
		FormParameters.Insert("Set",					CurrentPropertiesSet);
		FormParameters.Insert("PropertyToConfigure",	EditablePropertySettingsKind);
		
		OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.AttributesDependency",
					FormParameters,
					ThisObject,
					,
					,
					,
					,
					FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function TypeOfAttributeSettingsForMonitoringByFieldName(Items, TagName)
	
	SettingKind = "";
	
	If TagName = Items.AttributesForProductsControlAttributeRepresentation.Name
		Or TagName = Items.AttributesForProductsControlPresentationOfHyperlinkProps.Name
		Or TagName = Items.AttributesForItemVariantsControlAttributeRepresentation.Name
		Or TagName = Items.AttributesForItemVariantsControlPresentationOfHyperlinkProps.Name
		Or TagName = Items.AttributesForBatchControlAttributeRepresentation.Name
		Or TagName = Items.AttributesForBatchControlPresentationOfHyperlinkProps.Name Then
		
		SettingKind = "AttributeRepresentation";
		
	ElsIf TagName = Items.AttributesForProductsControlVisibleWithACondition.Name
		Or TagName = Items.AttributesForProductsControlForCellSizeIsVisibleWithCondition.Name
		Or TagName = Items.AttributesForItemVariantsControlVisibleWithACondition.Name
		Or TagName = Items.AttributesForItemVariantsControlForCellSizeIsVisibleWithCondition.Name Then
		
		SettingKind = "isVisible";
		
	ElsIf TagName = Items.AttributesForProductsControlAvailableWithACondition.Name
		Or TagName = Items.AttributesForProductsControlForCellSizeIsAvailableWithCondition.Name
		Or TagName = Items.AttributesForItemVariantsControlAvailableWithACondition.Name
		Or TagName = Items.AttributesForItemVariantsControlForCellSizeIsAvailableWithCondition.Name Then
		
		SettingKind = "Available";
		
	ElsIf TagName = Items.AttributesForProductsControlRequiredToFill.Name
		Or TagName = Items.AttributesForProductsControlForCellSizeItIsMandatoryToFillIn.Name
		Or TagName = Items.AttributesForItemVariantsControlRequiredToFill.Name
		Or TagName = Items.AttributesForItemVariantsControlForCellSizeItIsMandatoryToFillIn.Name
		Or TagName = Items.AttributesForBatchControlRequiredToFill.Name
		Or TagName = Items.AttributesForBatchControlForCellSizeItIsMandatoryToFillIn.Name Then
		
		SettingKind = "RequiredToFill";
		
	EndIf;
	
	Return SettingKind;
	
EndFunction

&AtServer
Procedure FillInDependenciesOfPropertyBeingEdited()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.DependentProperty AS DependentProperty,
	|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.PropertiesSet AS PropertiesSet,
	|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.Attribute AS Attribute,
	|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.Condition AS Condition,
	|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.Value AS Value
	|FROM
	|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.AdditionalAttributesDependencies AS AdditionalAttributesAndInfoAdditionalAttributesDependencies
	|WHERE
	|	AdditionalAttributesAndInfoAdditionalAttributesDependencies.Ref = &Ref";
	
	Query.SetParameter("Ref", EditableProperty);
	
	EditablePropertyOfDependence.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Procedure RecordPropertySettings(StorageSelectionSettings)
	
	MeaningfulPartOfName = "OfProductItem";
	
	If Items.PageCreationSettingsGroup.CurrentPage = Items.GroupDetailsForMonitoringCharacteristics Then
		MeaningfulPartOfName = "Features";
	ElsIf Items.PageCreationSettingsGroup.CurrentPage = Items.GroupDetailsForSeriesControl Then
		MeaningfulPartOfName = "Series_";
	EndIf;
	
	NameOfTableDetailsForControl = NameOfTableDetailsForControl(MeaningfulPartOfName);
	
	SelectionOfProperties	= New Structure("Property", EditableProperty);
	PropertyStrings	= Object[NameOfTableDetailsForControl].FindRows(SelectionOfProperties);
	
	If MeaningfulPartOfName = "OfProductItem" Then
		PropertiesSet = Object.PropertiesSet;
	ElsIf MeaningfulPartOfName = "Features" Then
		PropertiesSet = Object.CharacteristicsPropertySet;
	ElsIf MeaningfulPartOfName = "Series_" Then
		PropertiesSet = Object.BatchPropertySet;
	Else
		Raise StrTemplate(NStr("vi = 'Chưa xác định tập hợp thuộc tính đối với ""%1""';
								|ru = 'Не определен набор свойств для ""%1""';
								|en = 'No property set defined for ""%1""'; fa = 'No property set defined for ""%1""';
								|it = 'Insieme di proprietà per ""%1"" non è definito';
								|pl = 'Nie określono zestawu właściwości dla ""%1""';
								|tr = '""%1"" için özellik kümesi tanımlanmadı'"), MeaningfulPartOfName);
	EndIf;
	
	If PropertyStrings.Count() > 0 Then
		If PropertyStrings[0].IsCommonAttribute Then
			PropertiesSet = ?(MeaningfulPartOfName = "OfProductItem",
							PropertyManager.PropertiesSetByName("Catalog_Products_Overall"),
							?(MeaningfulPartOfName = "Features",
								PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall"),
								PropertyManager.PropertiesSetByName("Catalog_ItemsBatches_Overall")));
		EndIf;
	EndIf;
	
	ObjectProperty = EditableProperty.GetObject();

	For Each KeyValue In StorageSelectionSettings Do
		
		RowFilter = New Structure;
		RowFilter.Insert("PropertiesSet",			PropertiesSet);
		RowFilter.Insert("DependentProperty",	KeyValue.Key);
		
		FoundRows = ObjectProperty.AdditionalAttributesDependencies.FindRows(RowFilter);
		
		For Each ArrRow In FoundRows Do
			ObjectProperty.AdditionalAttributesDependencies.Delete(ArrRow);
		EndDo;
		
		If KeyValue.Value <> Undefined Then
			StorageData = KeyValue.Value; // ValueStorage -
			SettingsTable = StorageData.Get();
			
			For Each RowOfTables In SettingsTable Do
				NewRow = ObjectProperty.AdditionalAttributesDependencies.Add();
				
				FillPropertyValues(NewRow, RowOfTables);
			EndDo;
		EndIf;
		
	EndDo;
	
	ObjectProperty.Write();
	
	WhenRecordingSetOfAdditionalDetailsAndInformationOnServer();
	
EndProcedure

&AtServer
Procedure UpdatePricingSections()

	ArrayOfTexts = New Array;
	
	ArrayOfTexts.Add(NStr("vi = 'Mặt hàng';
							|ru = 'Номенклатура';
							|en = 'Items'; fa = 'اقلام';
							|it = 'Articolo';
							|pl = 'Items';
							|tr = 'Öğe'"));
	
	If Object.SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.Use 
		Or Object.SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.UseByAttributes Then
	
		ArrayOfTexts.Add(NStr("vi = ', Đặc tính';
								|ru = ', Характеристика';
								|en = ', Variant'; fa = ', Variant';
								|it = ', Caratteristica';
								|pl = ', Charakterystyka';
								|tr = ', Varyant'"));
		
		If Object.SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.UseByAttributes Then
			
			ArrayOfDetailsDescriptions = GetDetailsForPriceKey("Characteristics");
			
			If ArrayOfDetailsDescriptions.Count() Then
				
				ArrayOfTexts.Add(" (");			
				ArrayOfTexts.Add(StrConcat(ArrayOfDetailsDescriptions, ", "));
				ArrayOfTexts.Add(")");
				
			EndIf;
			
		EndIf;
	
	EndIf;	
	
	If Object.SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.Use
		Or Object.SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.UseByAttributes Then
	
		ArrayOfTexts.Add(NStr("vi = ', Sê-ri';
								|ru = ', Серия';
								|en = ', Batch'; fa = ', Batch';
								|it = ', Serie';
								|pl = ', Seria';
								|tr = ', Parti'"));
	
		If Object.SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.UseByAttributes Then
			
			ArrayOfDetailsDescriptions = GetDetailsForPriceKey("SetOfSeries");
			
			If ArrayOfDetailsDescriptions.Count() Then
				
				ArrayOfTexts.Add(" (");			
				ArrayOfTexts.Add(StrConcat(ArrayOfDetailsDescriptions, ", "));
				ArrayOfTexts.Add(")");
				
			EndIf;
			
		EndIf;
	
	EndIf;	
	
	If Object.SettingsOfPriceKeyByPackage = Enums.FilterOptionForPriceKey.Use Then
	
		ArrayOfTexts.Add(NStr("vi = ', Bộ đóng gói';
								|ru = ', Упаковка';
								|en = ', Packaging unit'; fa = ', Packaging unit';
								|it = ', Imballaggio';
								|pl = ', Opakowanie';
								|tr = ', Paketleme Ünitesi'"));

	EndIf;	
	
	If Object.PricingBreakdowns <> StrConcat(ArrayOfTexts) Then		
		Object.PricingBreakdowns = StrConcat(ArrayOfTexts);
	EndIf;
	
EndProcedure

&AtServer
Function GetDetailsForPriceKey(Val MeaningfulPartOfInscriptionName)
	
	ArrayOfDetailsDescriptions = New Array;			
	
	If MeaningfulPartOfInscriptionName = "Characteristics" Then
		
		If Object.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind Then
			
			For Each Attribute In Object.ItemVariantsAttributesForPriceKey Do				
				ArrayOfDetailsDescriptions.Add(String(Attribute.AttributeRepresentation));
			EndDo;
			
		ElsIf Object.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then 
			
			Query = New Query;
			Query.Text =
				"SELECT
				|	ItemKindsItemVariantsAttributesForPriceKey.Ref,
				|	ItemKindsItemVariantsAttributesForPriceKey.AttributeRepresentation
				|FROM
				|	Catalog.ItemKinds.ItemVariantsAttributesForPriceKey AS ItemKindsItemVariantsAttributesForPriceKey
				|WHERE
				|	ItemKindsItemVariantsAttributesForPriceKey.Ref = &ProductKind";
			
			Query.SetParameter("ProductKind", Object.ItemVariantsOwner);
			
			QueryResultTable_ = Query.Execute().Unload();
			
			ArrayOfDetailsDescriptions = QueryResultTable_.UnloadColumn("AttributeRepresentation");
			
		EndIf;
	ElsIf MeaningfulPartOfInscriptionName = "SetOfSeries" Then 

		If Not Object.BatchSettingsAreTakenFromOtherItemsKind Then
			
			For Each Attribute In Object.BatchAttributesForPriceKey Do				
				ArrayOfDetailsDescriptions.Add(String(Attribute.AttributeRepresentation));
			EndDo;
			
		Else 
			
			Query = New Query;
			Query.Text =
				"SELECT
				|	ItemKindsBatchAttributesForPriceKey.Ref,
				|	ItemKindsBatchAttributesForPriceKey.AttributeRepresentation
				|FROM
				|	Catalog.ItemKinds.BatchAttributesForPriceKey AS ItemKindsBatchAttributesForPriceKey
				|WHERE
				|	ItemKindsBatchAttributesForPriceKey.Ref = &ProductKind";
			
			Query.SetParameter("ProductKind", Object.BatchOwner);
			
			QueryResultTable_ = Query.Execute().Unload();
			
			ArrayOfDetailsDescriptions = QueryResultTable_.UnloadColumn("AttributeRepresentation");
			
		EndIf;
		
	EndIf;
	
	Return ArrayOfDetailsDescriptions;
	
EndFunction

&AtServer
Procedure FEACNCodeOnChangeServer()
	
	If Common.ObjectAttributeValue(Object.FEACNCode, "TracedGoods") Then
		Object.KeepRecordsByCCD = True;
	EndIf;
	
	ConfigureClassifierFieldHint(Items.FEACNCode.Name, Object.FEACNCode);
	
EndProcedure

&AtServer
Function PropertiesSetByName(SetName)
	
	Return PropertyManager.PropertiesSetByName(SetName);
	
EndFunction

&AtClientAtServerNoContext
Function NameOfTableDetailsForControl(MeaningfulPartOfName)
	
	If MeaningfulPartOfName = "OfProductItem" Then
		Return "AttributesForProductsControl";
	ElsIf MeaningfulPartOfName = "Features" Then
		Return "AttributesForItemVariantsControl";
	ElsIf MeaningfulPartOfName = "Series_" Then
		Return "AttributesForBatchControl";
	Else
		Raise StrTemplate(NStr("vi = 'Chưa xác định tên bảng mục tin kiểm soát đối với %1';
								|ru = 'Не определено имя таблицы реквизитов контроля для %1';
								|en = 'No control attribute table name defined for %1'; fa = 'No control attribute table name defined for %1';
								|it = 'Nome della tabella dei requisiti di controllo per %1 non definito';
								|pl = 'Nie określono nazwy tabeli atrybutów kontroli dla %1';
								|tr = 'Kontrol özniteliği tablo adı %1 için tanımlanmadı'"), MeaningfulPartOfName);
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function BankingDetailsNameNoNameEditing(PropsNameNameTemplate)
	
	If PropsNameNameTemplate = "NameTemplateForPrintingOfProductItem" Then
		Return "RestrictNameChangeToPrintItems";
	ElsIf PropsNameNameTemplate = "NameTemplateForPrintingCharacteristics" Then
		Return "DisableNameChangeToPrintItemVariant";
	ElsIf PropsNameNameTemplate = "WorkingNameTemplateOfProductItem" Then
		Return "ProhibitEditingWorkingTitleOfItems";
	ElsIf PropsNameNameTemplate = "WorkingNameTemplateCharacteristics" Then
		Return "ProhibitEditingWorkingTitleOfItemVariants";
	EndIf;
	
	Return "";
	
EndFunction

&AtClientAtServerNoContext
Function NameOfOwnerSProps(MeaningfulPartOfName)
	
	If MeaningfulPartOfName = "Features" Then
		Return "ItemVariantsOwner";
	ElsIf MeaningfulPartOfName = "Series_" Then
		Return "BatchOwner";
	ElsIf MeaningfulPartOfName = "OfProductCategories" Then
		Return "ProductCategoryOwner";
	Else
		Raise StrTemplate(NStr("vi = 'Chưa xác định tên mục tin-đối tượng chủ đối với %1';
								|ru = 'Не определено имя реквизита-владельца для %1';
								|en = 'No owner attribute name defined for %1'; fa = 'No owner attribute name defined for %1';
								|it = 'Nome del requisito titolare per %1 non definito';
								|pl = 'Nie określono nazwy atrybutu-właściciela dla %1';
								|tr = 'Sahibin öznitelik adı %1 için tanımlanmadı'"), MeaningfulPartOfName);
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function ListNameTypesOfProductsWithSameOwner(MeaningfulPartOfName)
	
	If MeaningfulPartOfName = "Features" Then
		Return "ProductKindsWithTheSameCharacteristicOwner";
	ElsIf MeaningfulPartOfName = "Series_" Then
		Return "ProductKindsWithTheSameSeriesOwner";
	ElsIf MeaningfulPartOfName = "OfProductCategories" Then
		Return "ProductKindsWithTheSameOwnerOfProductCategories";
	Else
		Raise StrTemplate(NStr("vi = 'Chưa xác định tên danh sách dạng mặt hàng có đối tượng chủ như vậy đối với %1';
								|ru = 'Не определено имя списка видов номенклатуры с тем же владельцем для %1';
								|en = 'No item kinds list name with the same owner defined for %1'; fa = 'No item kinds list name with the same owner defined for %1';
								|it = 'Non è stato indicato il nome dell''elenco dei tipi di articolo con il medesimo proprietario per %1';
								|pl = 'Nie określono nazwy listy rodzajów pozycji z tym samym właścicielem dla %1';
								|tr = 'Aynı sahibi olan öğe türleri listesinin adı %1 için tanımlanmadı'"), MeaningfulPartOfName);
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function NameOfOwnerSAccountDetails(MeaningfulPartOfName)
	
	If MeaningfulPartOfName = "Features" Then
		Return "CharacteristicsOwnerSelection";
	ElsIf MeaningfulPartOfName = "Series_" Then
		Return "SeriesOwnerSelection";
	ElsIf MeaningfulPartOfName = "OfProductCategories" Then
		Return "ProductCategoriesOwnerSelection";
	Else
		Raise StrTemplate(NStr("vi = 'Chưa xác định tên mục tin lọc đối tượng chủ %1';
								|ru = 'Не определено имя реквизита отбора владельца %1';
								|en = 'No owner filter attribute name defined for %1'; fa = 'No owner filter attribute name defined for %1';
								|it = 'Nome del requisito di selezione del titolare %1 non definito';
								|pl = 'Nie określono nazwy atrybutu selekcji właściciela %1';
								|tr = '%1 sahibinin filtre özniteliklerinin adı tanımlanmadı'"), MeaningfulPartOfName);
	EndIf;
	
EndFunction

&AtServer
Procedure UpdateSettingsOfAdditionalAttributesForRecordingControl(CurrentObject, AssigningAdditionalRequesters)
	
	SelectionColumns		= "IsAddlAttribute, Property";
	ColumnsToFillIn	= "RequiredToFill, DisplayWhenCreated, AvailabilityUnique,
							|MandatoryFillingOfAvailability, DisplayAvailabilityOnCreation";
	
	If AssigningAdditionalRequesters = "Products" Then
		AttributesForControl	= CurrentObject.AttributesForProductsControl;
		Current_Attributes		= Object.AttributesForProductsControl;
	ElsIf AssigningAdditionalRequesters = "ItemsCharacteristics" Then
		AttributesForControl	= CurrentObject.AttributesForItemVariantsControl;
		Current_Attributes		= Object.AttributesForItemVariantsControl;
	ElsIf AssigningAdditionalRequesters = "ItemsBatches" Then
		AttributesForControl	= CurrentObject.AttributesForBatchControl;
		Current_Attributes		= Object.AttributesForBatchControl;
		ColumnsToFillIn		= "RequiredToFill, MandatoryFillingOfAvailability";
	EndIf;
	
	AttributesTable = AttributesForControl.Unload();
	AttributesTable.Indexes.Add(SelectionColumns);
	
	FilterBankingDetails_ = New Structure("IsAddlAttribute", True);
	AdditionalAttributes = Current_Attributes.FindRows(FilterBankingDetails_);
	
	RowFilter = New Structure(SelectionColumns);
	
	For Each AdditionalAttribute5 In AdditionalAttributes Do
		FillPropertyValues(RowFilter, AdditionalAttribute5);
		
		FoundRows = AttributesTable.FindRows(RowFilter);
		
		If FoundRows.Count() > 0 Then
			FillPropertyValues(FoundRows[0], AdditionalAttribute5, ColumnsToFillIn);
		EndIf;
	EndDo;
	
	AttributesForControl.Load(AttributesTable);
	
EndProcedure

&AtServer
Procedure RecordPropertiesOfAdditionalBankingDetails(AssigningAdditionalRequesters, Cancel)
	
	TempTablesManager = New TempTablesManager;
	
	Catalogs.Products.AllAdditionalDetails_(Object.Ref, AssigningAdditionalRequesters, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	AttributesForControl.Property				AS Property,
	|	AttributesForControl.RequiredToFill	AS RequiredToFill,
	|	AttributesForControl.IsCommonAttribute		AS IsCommonAttribute
	|INTO AttributesForControl
	|FROM
	|	&AttributesForControl AS AttributesForControl
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	NestedQuery.Property				AS Property,
	|	NestedQuery.RequiredToFill	AS RequiredToFill,
	|	NestedQuery.IsCommonAttribute AS	IsCommonAttribute
	|INTO MutableProperties
	|FROM
	|	(SELECT
	|		AttributesForControl.Property				AS Property,
	|		AttributesForControl.RequiredToFill	AS RequiredToFill,
	|		AttributesForControl.IsCommonAttribute		AS IsCommonAttribute,
	|		1											AS Control
	|	FROM
	|		AttributesForControl AS AttributesForControl
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTDetailsForControl.Property				AS Property,
	|		TTDetailsForControl.RequiredToFill	AS RequiredToFill,
	|		TTDetailsForControl.IsCommonAttribute		AS IsCommonAttribute,
	|		-1											AS Control
	|	FROM
	|		TTAllAdditionalDetails AS TTDetailsForControl) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Property,
	|	NestedQuery.RequiredToFill,
	|	NestedQuery.IsCommonAttribute
	|
	|HAVING
	|	SUM(NestedQuery.Control) > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	SetsOfAdditionalProps.Ref	AS PropertiesSet,
	|	MutableProperties.Property	AS Property,
	|	ItemKinds.Ref		AS ProductKind
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetsOfAdditionalProps
	|		INNER JOIN MutableProperties AS MutableProperties
	|		ON SetsOfAdditionalProps.Property = MutableProperties.Property
	|		
	|		INNER JOIN Catalog.ItemKinds AS ItemKinds
	|		ON (SetsOfAdditionalProps.Ref = ItemKinds.PropertiesSet
	|			OR SetsOfAdditionalProps.Ref = ItemKinds.CharacteristicsPropertySet
	|			OR SetsOfAdditionalProps.Ref = ItemKinds.BatchPropertySet)
	|WHERE
	|	SetsOfAdditionalProps.Ref <> &Current_Set
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	AttributesForControl.Property				AS Property,
	|	AttributesForControl.RequiredToFill	AS RequiredToFill,
	|	AttributesForControl.IsCommonAttribute		AS IsCommonAttribute
	|FROM
	|	AttributesForControl AS AttributesForControl
	|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.AdditionalAttributesDependencies AS AdditionalAttributesDependencies
	|		ON AttributesForControl.Property = AdditionalAttributesDependencies.Ref
	|			AND AdditionalAttributesDependencies.Condition = ""NotEqual""
	|			AND AdditionalAttributesDependencies.PropertiesSet = &Current_Set
	|			AND AdditionalAttributesDependencies.Value = &ProductKind
	|			AND AdditionalAttributesDependencies.Attribute = ""ProductKind""
	|			AND AdditionalAttributesDependencies.DependentProperty LIKE ""RequiredToFill""
	|		
	|		LEFT JOIN MutableProperties AS MutableProperties
	|		ON AttributesForControl.Property = MutableProperties.Property
	|
	|WHERE
	|	NOT AttributesForControl.IsCommonAttribute
	|	AND NOT AttributesForControl.RequiredToFill
	|	AND MutableProperties.Property IS NULL
	|	AND AdditionalAttributesDependencies.Ref IS NULL";
	
	If AssigningAdditionalRequesters = "Products" Then
		AttributesForControl	= Object.AttributesForProductsControl;
		PropertiesSet			= Object.PropertiesSet;
		SharedSet				= PropertyManager.PropertiesSetByName("Catalog_Products_Overall");
	ElsIf AssigningAdditionalRequesters = "ItemsCharacteristics" Then
		AttributesForControl	= Object.AttributesForItemVariantsControl;
		PropertiesSet			= Object.CharacteristicsPropertySet;
		SharedSet				= PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall");
	ElsIf AssigningAdditionalRequesters = "ItemsBatches" Then
		AttributesForControl	= Object.AttributesForBatchControl;
		PropertiesSet			= Object.BatchPropertySet;
		SharedSet				= PropertyManager.PropertiesSetByName("Catalog_ItemsBatches_Overall");
	EndIf;
	
	RowFilter = New Structure("IsAddlAttribute", True);
	
	Query.SetParameter("AttributesForControl",	AttributesForControl.Unload(RowFilter));
	Query.SetParameter("Current_Set",			PropertiesSet);
	Query.SetParameter("ProductKind",		Object.Ref);
	
	Results = Query.ExecuteBatchWithIntermediateData();
	
	SelectionByProperties = Results[1].Select();
	
	PropertiesSets = Results[2].Unload(); // ValueTable
	PropertiesSets.Indexes.Add("Property");
	
	While SelectionByProperties.Next() Do
		
		ObjectProperty = SelectionByProperties.Property.GetObject(); // ChartOfCharacteristicTypesObject.AdditionalAttributesAndInfo
		
		If SelectionByProperties.IsCommonAttribute Then
			
			RowFilter = New Structure;
			RowFilter.Insert("DependentProperty",	"RequiredToFill");
			RowFilter.Insert("PropertiesSet",			SharedSet);
			RowFilter.Insert("Attribute",				"ProductKind");
			RowFilter.Insert("Value",				Object.Ref);
			
			FoundRows = ObjectProperty.AdditionalAttributesDependencies.FindRows(RowFilter);
			
			If SelectionByProperties.RequiredToFill Then
				
				ObjectProperty.RequiredToFill = True;
				
				If FoundRows.Count() = 0 Then
					TSRow = ObjectProperty.AdditionalAttributesDependencies.Add();
					TSRow.DependentProperty	= "RequiredToFill";
					TSRow.PropertiesSet		= SharedSet;
					TSRow.Attribute			= "ProductKind";
					TSRow.Value			= Object.Ref;
				Else
					TSRow = FoundRows[0];
				EndIf;
				
				TSRow.Condition = "InList";
				
			Else
				
				For Each ArrRow In FoundRows Do
					ObjectProperty.AdditionalAttributesDependencies.Delete(ArrRow);
				EndDo;
				
				RowFilter = New Structure;
				RowFilter.Insert("DependentProperty",	"RequiredToFill");
				RowFilter.Insert("PropertiesSet",			SharedSet);
				RowFilter.Insert("Attribute",				"ProductKind");
				
				FoundRows = ObjectProperty.AdditionalAttributesDependencies.FindRows(RowFilter);
				
				If FoundRows.Count() = 0 Then
					ObjectProperty.RequiredToFill = False;
				EndIf;
				
			EndIf;
			
		Else
			
			If SelectionByProperties.RequiredToFill Then
				
				If Not ObjectProperty.RequiredToFill Then
					
					RowFilter = New Structure;
					RowFilter.Insert("DependentProperty",	"RequiredToFill");
					RowFilter.Insert("Attribute",				"ProductKind");
					
					FoundRows = ObjectProperty.AdditionalAttributesDependencies.FindRows(RowFilter);
					
					For Each ArrRow In FoundRows Do
						ObjectProperty.AdditionalAttributesDependencies.Delete(ArrRow);
					EndDo;
					
					RowFilter = New Structure("Property", SelectionByProperties.Property);
					FoundRows = PropertiesSets.FindRows(RowFilter);
					
					For Each RowOfTables In FoundRows Do
						If RowOfTables.ProductKind = Object.Ref Then
							Continue;
						EndIf;
						
						TSRow = ObjectProperty.AdditionalAttributesDependencies.Add();
						TSRow.DependentProperty	= "RequiredToFill";
						TSRow.PropertiesSet		= RowOfTables.PropertiesSet;
						TSRow.Attribute			= "ProductKind";
						TSRow.Value			= RowOfTables.ProductKind;
						TSRow.Condition			= "NotEqual";
					EndDo;
					
					ObjectProperty.RequiredToFill = True;
					
				EndIf;
				
				RowFilter = New Structure;
				RowFilter.Insert("DependentProperty",	"RequiredToFill");
				RowFilter.Insert("PropertiesSet",			PropertiesSet);
				RowFilter.Insert("Attribute",				"ProductKind");
				
				FoundRows = ObjectProperty.AdditionalAttributesDependencies.FindRows(RowFilter);
				
				If FoundRows.Count() > 0 Then
					TSRow = FoundRows[0];
				Else
					TSRow = ObjectProperty.AdditionalAttributesDependencies.Add();
				EndIf;
				
				TSRow.DependentProperty	= "RequiredToFill";
				TSRow.PropertiesSet		= PropertiesSet;
				TSRow.Attribute			= "ProductKind";
				TSRow.Value			= Object.Ref;
				TSRow.Condition			= "Equal";
				
			Else
				
				ThereArePropsWhereSetIsUsed	= False;
				LineOnCurSetIsAlreadyThere		= False;
				
				For Each RowOfTables In ObjectProperty.AdditionalAttributesDependencies Do
					
					If RowOfTables.DependentProperty = "RequiredToFill"
						And RowOfTables.PropertiesSet <> PropertiesSet
						And RowOfTables.Attribute = "ProductKind"
						And RowOfTables.Condition = "Equal" Then
						
						ThereArePropsWhereSetIsUsed = True;
						
					ElsIf RowOfTables.DependentProperty = "RequiredToFill"
						And RowOfTables.PropertiesSet = PropertiesSet
						And RowOfTables.Attribute = "ProductKind" Then
						
						LineOnCurSetIsAlreadyThere = True;
						
						RowOfTables.Condition		= "NotEqual";
						RowOfTables.Value	= Object.Ref;
						
					EndIf;
					
				EndDo;
				
				If Not ThereArePropsWhereSetIsUsed Then
					
					ObjectProperty.RequiredToFill = False;
					
					RowFilter = New Structure;
					RowFilter.Insert("DependentProperty",	"RequiredToFill");
					RowFilter.Insert("Attribute",				"ProductKind");
					
					FoundRows = ObjectProperty.AdditionalAttributesDependencies.FindRows(RowFilter);
					
					For Each ArrRow In FoundRows Do
						ObjectProperty.AdditionalAttributesDependencies.Delete(ArrRow);
					EndDo;
					
				ElsIf Not LineOnCurSetIsAlreadyThere Then
					
					TSRow = ObjectProperty.AdditionalAttributesDependencies.Add();
					TSRow.DependentProperty	= "RequiredToFill";
					TSRow.PropertiesSet		= PropertiesSet;
					TSRow.Attribute			= "ProductKind";
					TSRow.Value			= Object.Ref;
					TSRow.Condition			= "NotEqual";
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		ObjectProperty.Write();
		
	EndDo;
	
	SelectionByProperties = Results[3].Select();
	
	While SelectionByProperties.Next() Do
		
		ObjectProperty = SelectionByProperties.Property.GetObject(); // ChartOfCharacteristicTypesObject.AdditionalAttributesAndInfo
		
		ThereArePropsWhereSetIsUsed = False;
		
		For Each RowOfTables In ObjectProperty.AdditionalAttributesDependencies Do
			
			If RowOfTables.DependentProperty = "RequiredToFill"
				And RowOfTables.PropertiesSet <> PropertiesSet
				And RowOfTables.Attribute = "ProductKind"
				And RowOfTables.Condition = "Equal" Then
				
				ThereArePropsWhereSetIsUsed = True;
				
			EndIf;
			
		EndDo;
		
		If Not ThereArePropsWhereSetIsUsed Then
			
			ObjectProperty.RequiredToFill = False;
			
			RowFilter = New Structure;
			RowFilter.Insert("DependentProperty",	"RequiredToFill");
			RowFilter.Insert("Attribute",				"ProductKind");
			
			FoundRows = ObjectProperty.AdditionalAttributesDependencies.FindRows(RowFilter);
			
			For Each ArrRow In FoundRows Do
				ObjectProperty.AdditionalAttributesDependencies.Delete(ArrRow);
			EndDo;
			
		Else
			
			TSRow = ObjectProperty.AdditionalAttributesDependencies.Add();
			TSRow.DependentProperty	= "RequiredToFill";
			TSRow.PropertiesSet		= PropertiesSet;
			TSRow.Attribute			= "ProductKind";
			TSRow.Value			= Object.Ref;
			TSRow.Condition			= "NotEqual";
			
		EndIf;
		
		ObjectProperty.Write();
		
	EndDo;
	
EndProcedure

// Sets the property settings for the extended hint of the classifier field.
//
// Parameters:
//	TagName - String - name of the classifier element field.
//	ClassifierData - AnyRef, String - classifier data. For the classifier code of the reference type,
//													its value is passed as a parameter, otherwise
//													the string name of the value is passed.
//
&AtServer
Procedure ConfigureClassifierFieldHint(TagName, ClassifierData)
	
	If Not Items[TagName].Visible Then
		Return;
	EndIf;
	
	DataTypeString	= TypeOf(ClassifierData) = Type("String");
	CodeIsSpecified		= ?(DataTypeString, IsBlankString(ClassifierData), ClassifierData.IsEmpty());
	
	If CodeIsSpecified Then
		Items[TagName].ToolTipRepresentation				= ToolTipRepresentation.Auto;
		Items[TagName].ExtendedTooltip.Title	= "";
	Else
		DescriptionByClassifier = ?(DataTypeString,
										ClassifierData,
										Common.ObjectAttributeValue(ClassifierData, "Description"));
		
		Items[TagName].ToolTipRepresentation				= ToolTipRepresentation.Button;
		Items[TagName].ExtendedTooltip.Title	= DescriptionByClassifier;
	EndIf;
	
EndProcedure


#EndRegion

#Region Localization

&AtServer
Procedure OnCreateAtServerLocalization()
	

	Return;
	
EndProcedure

&AtServer
Procedure OnWriteAtServerLocalization(Cancel, CurrentObject)
	

	Return;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServerLocalization(Cancel, CheckedAttributes)
	

	Return;
	
EndProcedure

&AtServer
Procedure CustomizeFormLocalization(VisibilityOfElements)
	
	
EndProcedure



#EndRegion

&AtServer
Procedure ConfigurePricingSettingsTab()
	
	If Not UsePriceManagementSystem25 Then
		
		Items.PricingSettingsPage.Visible   = False;
		Return;
				
	EndIf;
	
	UseItemVariants 	= UsePriceManagementSystem25 And GetFunctionalOption("UseItemVariants");
	UseItemsBatch          	= UsePriceManagementSystem25 And GetFunctionalOption("UseItemsBatch");
	UseItemPackages 		= UsePriceManagementSystem25 And GetFunctionalOption("UseItemPackages");
	
	SettingUpSeriesForPricing = GetSeriesUsageSettingsForPricing();
	
	Items.PricingSettingsGroupByCharacteristics.Visible   = UseItemVariants;
	Items.SeriesPricingSettingsGroup.Visible            = UseItemsBatch;
	Items.PackagePricingSettingsGroup.Visible         = UseItemPackages;

	Items.SettingsOfPriceKeyByItemVariant.Enabled = Object.UseCharacteristics 
																And Not Object.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind;
	Items.SettingsOfPriceKeyByBatch.Enabled          = SettingUpSeriesForPricing.Use
																And Not Object.BatchSettingsAreTakenFromOtherItemsKind;

	If UseItemVariants Then
		
		If Not Object.UseCharacteristics Then
			Items.GroupPricingSettingsByCharacteristicsInformation.Visible = True;
			Items.CommentOnTheUseOfCharacteristics.Title = NStr("vi = 'Không thể bật thiết lập giá theo đặc tính vì các lý do sau:
																		| - do dạng mặt hàng không hạch toán theo từng đặc tính';
																		|ru = 'Невозможно включение ведения ценообразования по характеристикам по следующим причинам:
																		| - по виду номенклатуры не ведется учет в разрезе характеристик';
																		|en = 'Cannot enable pricing by item variants for the following reasons:
																		| - the accounting broken down by variants is not kept by items kind'; fa = 'فعال‌سازی قیمت‌گذاری بر اساس گونه‌های قلم به دلایل زیر امکان‌پذیر نیست:
																		| - حسابداری به تفکیک گونه‌ها برای نوع اقلام نگهداری نمی‌شود';
																		|it = 'Impossibile includere l''esecuzione dell''elaborazione di prezzo in base alle caratteristiche a causa di:
																		|- a causa del tipo di nomenclatura, la contabilità non viene eseguita nella sezione delle caratteristiche';
																		|pl = 'Niemożliwe jest włączenie prowadzenia tworzenia cen wg charakterystyk z następujących przyczyn:
																		| - dla rodzaju pozycji nie jest prowadzona ewidencja w przekroju charakterystyk';
																		|tr = 'Aşağıdaki nedenlerden dolayı varyant fiyatlandırmasının etkinleştirilmesi mümkün değildir:
																		| - Öğe türüne göre varyant kesitinde muhasebe yapılmamaktadır'"); 	
		ElsIf Object.UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems Then 
			Items.GroupPricingSettingsByCharacteristicsInformation.Visible = True;
			Items.CommentOnTheUseOfCharacteristics.Title = NStr("vi = 'Không thể bật thiết lập giá theo các mục tin của đặc tính vì những lý do sau:
																		| - dạng mặt hàng không tiến hành hạch toán chung theo đặc tính. Để thiết lập giá theo các mục tin mặt hàng, cần thay đổi sang chế độ hạch toán chung';
																		|ru = 'Невозможно включение ведения ценообразования по реквизитам характеристик по следующим причинам:
																		| - по виду номенклатуры учет в разрезе характеристик не общий. Для ведения ценообразования по реквизитам номенклатуры, необходимо изменить режим на общий';
																		|en = 'Cannot enable pricing by variant attributes for the following reasons:
																		| - the accounting broken down by variants is not common by items kind. Change the mode to common to conduct pricing by item attributes'; fa = 'Cannot enable pricing by variant attributes for the following reasons:
																		| - the accounting broken down by variants is not common by items kind. Change the mode to common to conduct pricing by item attributes';
																		|it = 'Impossibile includere l''esecuzione dell''elaborazione di prezzo in base agli attributi delle caratteristiche a causa di:
																		| - a causa del tipo di nomenclatura, la contabilità nella sezione delle caratteristiche non è generale. Per l''esecuzione dell''elaborazione di prezzo per attributi della nomenclatura è necessario cambiare il regime in generale';
																		|pl = 'Nie możliwe jest włączenie wprowadzenia tworzenia cen wg atrybutów charakterystyk z następujących przyczyn:
																		| - wg rodzaju pozycji ewidencja w przekroju charakterystyk nie ogólny. Do wprowadzenia tworzenia cen wg atrybutów pozycji, należy zmienić tryb na ogólny';
																		|tr = 'Aşağıdaki nedenlerden dolayı varyant öznitelikleri fiyatlandırmasının etkinleştirilmesi mümkün değildir:
																		| - Öğe türüne göre, varyant kesitinde muhasebe genel değildir. Öğe özniteliklerine göre fiyatlandırmayı sürdürmek için modu ortak olarak değiştirmeniz gerekmektedir'"); 	
		ElsIf Object.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then 
			Items.GroupPricingSettingsByCharacteristicsInformation.Visible = True;
			Items.CommentOnTheUseOfCharacteristics.Title = NStr("vi = 'Không thể thay đổi tùy chỉnh theo đặc tính do các nguyên nhân sau:
																		| - dạng mặt hàng tiến hành hạch toán theo đặc tính chung với các dạng mặt hàng khác. 
																		|Chỉ có thể thay đổi tùy chỉnh đặc tính mặt hàng trong biểu mẫu đối tượng chủ của dạng mặt hàng';
																		|ru = 'Изменение настроек по характеристикам не возможно по следующим причинам:
																		| - по виду номенклатуры учет в разрезе характеристик общий с другими видами номенклатуры. 
																		|Изменение настроек характеристик номенклатуры возможно только в форме владельца вида номенклатуры';
																		|en = 'Changing the settings by item variants is not available for the following reasons:
																		| - the accounting broken down by variants is common with other item kinds for the item kind. 
																		|Changing the item variants settings is only available in the item kind owner form'; fa = 'Changing the settings by item variants is not available for the following reasons:
																		| - the accounting broken down by variants is common with other item kinds for the item kind. 
																		|Changing the item variants settings is only available in the item kind owner form';
																		|it = 'La modifica delle impostazioni per caratteristiche non è possibile a causa di:
																		| - a causa del tipo di nomenclatura, la contabilità nella sezione delle caratteristiche è comune agli altri tipi di nomenclatura. 
																		|La modifica delle impostazioni delle caratteristiche della nomenclatura è possibile solamente nel form del proprietario del tipo di nomenclatura';
																		|pl = 'Zmiana ustawień wg charakterystyk jest niemożliwa z następujących przyczyn:
																		| - wg rodzaju pozycji ewidencja w przekroju charakterystyk ogólny z innymi rodzajami pozycji. 
																		|Zmiana ustawień charakterystyk pozycji możliwa jest tylko w postaci właściciela rodzaju pozycji';
																		|tr = 'Aşağıdaki nedenlerden dolayı varyantlara ilişkin özelliklerin değiştirilmesi mümkün değildir:
																		| - Öğe türüne göre, varyantlar açısından muhasebe diğer öğe türleriyle ortaktır. 
																		|Öğe varyantları ayarlarının değiştirilmesi sadece öğe türü sahibi formunda mümkündür'"); 	
		Else
			
			Items.GroupPricingSettingsByCharacteristicsInformation.Visible = False;
			 	
		EndIf;
		
		Items.ChangeTheSetOfDetailsForTheKeyPriceCharacteristics.Enabled = (Object.SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.UseByAttributes 
																					And Object.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind
																					And Not Items.SettingsOfPriceKeyByItemVariant.ReadOnly);
																						
		ChoiceList = Items.SettingsOfPriceKeyByItemVariant.ChoiceList;
		ChoiceList.Clear();
	
		ChoiceList.Add(Enums.FilterOptionForPriceKey.DontUse, NStr("vi = 'không có đặc tính';
																	|ru = 'без характеристик';
																	|en = 'without variants'; fa = 'بدون گونه‌ها';
																	|it = 'Senza caratteristiche';
																	|pl = 'bez charakterystyk';
																	|tr = 'varyantsız'"));
		ChoiceList.Add(Enums.FilterOptionForPriceKey.Use, NStr("vi = 'theo đặc tính';
																|ru = 'по характеристикам';
																|en = 'by item variants'; fa = 'بر اساس گونه‌های قلم';
																|it = 'per caratteristiche';
																|pl = 'według charakterystyk';
																|tr = 'varyantlara göre'"));
		If Object.UseVariants <> Enums.ItemVariantsUsageOptions.SpecialForItems Then
			ChoiceList.Add(Enums.FilterOptionForPriceKey.UseByAttributes, NStr("vi = 'theo mục tin đặc tính';
																				|ru = 'по реквизитам характеристик';
																				|en = 'by variant attributes'; fa = 'بر اساس ویژگی‌های گونه';
																				|it = 'Per i requisiti delle caratteristiche';
																				|pl = 'wg atrybutów charakterystyk';
																				|tr = 'varyant özniteliklerine göre'"));
			Items.ChangeTheSetOfDetailsForTheKeyPriceCharacteristics.Visible = True;
		Else
			Items.ChangeTheSetOfDetailsForTheKeyPriceCharacteristics.Visible = False;
		EndIf;
		
		CreatePricingSectionLabel("Characteristics");
		
	EndIf;
	
	If UseItemsBatch Then
		
		Items.GroupPricingSettingsBySeriesInformation.Visible = Not SettingUpSeriesForPricing.Use;
		Items.CommentOnUsingTheSeries.Title = SettingUpSeriesForPricing.Comment;
	
		Items.ChangeTheSetOfDetailsForTheSeriesPriceKey.Enabled         = (Object.SettingsOfPriceKeyByBatch = Enums.FilterOptionForPriceKey.UseByAttributes
																					And Not Object.BatchSettingsAreTakenFromOtherItemsKind
																					And Not Items.SettingsOfPriceKeyByBatch.ReadOnly);
																					
		CreatePricingSectionLabel("SetOfSeries");
		
	EndIf;
	
	UpdatePricingSections();
	
EndProcedure

&AtServer
Function GetSeriesUsageSettingsForPricing()
	
	SettingUpSeriesForPricing = New Structure("Use, Comment", True, "");
	
	If Not Object.KeepAccountingByBatch Then
		SettingUpSeriesForPricing.Use = False;
		SettingUpSeriesForPricing.Comment = NStr("vi = 'Không thể bật thiết lập giá theo sê-ri vì các lý do sau:
															| - do dạng mặt hàng không hạch toán theo sê-ri';
															|ru = 'Невозможно включение ведения ценообразования по сериям по следующим причинам:
															| - по виду номенклатуры не ведется учет в разрезе серий';
															|en = 'Cannot enable pricing by batch for the following reasons:
															| - the accounting broken down by batch is not kept by items kind'; fa = 'فعال‌سازی قیمت‌گذاری بر اساس بچ به دلایل زیر امکان‌پذیر نیست:
															| - حسابداری به تفکیک بچ برای نوع اقلام نگهداری نمی‌شود';
															|it = 'Impossibile includere l''esecuzione dell''elaborazione di prezzo in base alle caratteristiche a causa di:
															|- a causa del tipo di nomenclatura, la contabilità non viene eseguita nella sezione delle serie';
															|pl = 'Niemożliwe jest włączenie prowadzenia tworzenia cen wg serii z następujących przyczyn:
															| - dla rodzaju pozycji nie jest prowadzona ewidencja w przekroju serii';
															|tr = 'Aşağıdaki nedenlerden dolayı parti fiyatlandırmasının etkinleştirilmesi mümkün değildir:
															| - Öğe türüne göre parti kesitinde muhasebe yapılmamaktadır'");
	ElsIf Object.BatchSettingsAreTakenFromOtherItemsKind Then
		SettingUpSeriesForPricing.Use = False;
		SettingUpSeriesForPricing.Comment = NStr("vi = 'Không thể bật tùy chỉnh thiết lập giá theo sê-ri do các nguyên nhân sau:
															| - dạng mặt hàng tiến hành hạch toán theo sê-ri chung với các dạng mặt hàng khác. 
															|Chỉ có thể thay đổi tùy chỉnh sê-ri mặt hàng trong biểu mẫu đối tượng chủ của dạng mặt hàng';
															|ru = 'Невозможно включение ведения ценообразования по сериям по следующим причинам:
															| - по виду номенклатуры учет в разрезе серий общий с другими видами номенклатуры. 
															|Изменение настроек серий номенклатуры возможно только в форме владельца вида номенклатуры';
															|en = 'Cannot enable pricing by batch for the following reasons:
															| - the accounting broken down by batch is common with other item kinds for the item kind. 
															|Changing the item batch settings is only available in the item kind owner form'; fa = 'Cannot enable pricing by batch for the following reasons:
															| - the accounting broken down by batch is common with other item kinds for the item kind. 
															|Changing the item batch settings is only available in the item kind owner form';
															|it = 'L''esecuzione dell''elaborazione di prezzo per serie non è possibile a causa di:
															| - a causa del tipo di nomenclatura, la contabilità nella sezione delle serie è comune agli altri tipi di nomenclatura. 
															|La modifica delle impostazioni delle serie della nomenclatura è possibile solamente nel form del proprietario del tipo di nomenclatura';
															|pl = 'Niemożliwe jest włączenie wprowadzenia tworzenia cen wg serii z następujących przyczyn:
															| - wg rodzaju pozycji ewidencja w przekroju serii ogólny z innymi rodzajami pozycji. 
															|Zmiana ustawień serii pozycji możliwa jest tylko w postaci właściciela rodzaju pozycji';
															|tr = 'Aşağıdaki nedenlerden dolayı parti fiyatlandırmasının etkinleştirilmesi mümkün değildir:
															| - ürün türüne göre, partiler açısından muhasebe diğer öğe türleriyle ortaktır. 
															|Ürün partileri ayarlarının değiştirilmesi sadece öğe türü sahibi formunda mümkündür'");
	EndIf;
	
	Return SettingUpSeriesForPricing;
	
EndFunction

&AtClient
Procedure SettingsOfPriceKeyByItemVariantOnChange(Item)
	SettingsOfPriceKeyByCharacteristicWhenChangingOnServer();
EndProcedure

&AtServer
Procedure SettingsOfPriceKeyByCharacteristicWhenChangingOnServer()
	ConfigurePricingSettingsTab();
EndProcedure

&AtClient
Procedure SettingsOfPriceKeyByBatchOnChange(Item)
	SettingsOfPriceKeyBySeriesWhenChangingOnServer();
EndProcedure

&AtServer
Procedure SettingsOfPriceKeyBySeriesWhenChangingOnServer()
	ConfigurePricingSettingsTab();
EndProcedure

&AtServer
Procedure PackagePriceKeySettingsWhenChangedOnServer()
	ConfigurePricingSettingsTab();
EndProcedure

&AtClient
Procedure SettingsOfPriceKeyByPackageOnChange(Item)
	PackagePriceKeySettingsWhenChangedOnServer();
EndProcedure

&AtClient
Procedure ChangeTheSetOfCharacteristicsDetailsForThePriceKeyNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "ChangeSettingsForUsingBankingDetails" Then
		ChangeCharacteristicsPanelForKey();
	EndIf;	

EndProcedure

&AtClient
Procedure ChangeTheSetOfSeriesDetailsForThePriceKeyNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "ChangeSettingsForUsingBankingDetails" Then
		ChangeSeriesPanelForKey();
	EndIf;	
EndProcedure
