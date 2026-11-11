
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnCreatReadAtServer(True);
	EndIf;

	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();

	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.AttributesForControl.Load(
		AttributesForControl.Unload(
			New Structure("RequiredForFilling", True)));

	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetAvailabilityOfItemsOnServer();
	
	FillInDetailsForControl(CurrentObject.AttributesForControl, CurrentObject.UseOfSubclasses);
	
	Items.DescriptionPage.Picture = CommonClientServer.CommentPicture(Object.LongDesc);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	Items.RMCycleRMType.CreateButton = True;
	Items.OtherRMActivitiesRMType.CreateButton = True;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("CatalogRef.RunningTimeValues") Then
		
		FoundRows = Object.RunningTimeValues.FindRows(New Structure("RunningTimeValue", ValueSelected));
		If FoundRows.Count() = 0 Then
			
			Object.RunningTimeValues.Add().RunningTimeValue = ValueSelected;
			Modified = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_MaintenanceSchemes");
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ThisNodeClassOnChange(Item)
	ThisIsNodeClassWhenModifiedOnServer();
EndProcedure

&AtServer
Procedure ThisIsNodeClassWhenModifiedOnServer()
	
	FillInDetailsForControl(AttributesForControl, Object.UseOfSubclasses);
	
EndProcedure

&AtClient
Procedure UseOfSubclassesOnChange(Item)
	SubclassesAreUsedWhenChangingOnServer();
EndProcedure

&AtServer
Procedure SubclassesAreUsedWhenChangingOnServer()
	
	FillInDetailsForControl(AttributesForControl, Object.UseOfSubclasses);
	SetAvailabilityOfItemsOnServer();
	
EndProcedure

&AtClient
Procedure PropertiesSetOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Object.PropertiesSet) Then
		
		OpenForm(
			"Catalog.AdditionalAttributesAndInfoSets.Form.ItemForm",
			New Structure("Key", Object.PropertiesSet));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PropertiesSetCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(Object.Description) Then
		
		CommonClientServer.MessageToUser(NStr("vi = 'Tên phải được điền';
												|ru = 'Наименование должно быть заполнено';
												|en = 'The name is required'; fa = 'The name is required';
												|it = 'Il nome deve essere compilato';
												|pl = 'Nazwa musi być wypełniona';
												|tr = 'İsim giriniz.'"),,"Object.Description");
		Return;
		
	EndIf;
	
	SetOfPropertiesCreateOnServer();
	
	If ValueIsFilled(Object.PropertiesSet) Then
		
		OpenForm(
			"Catalog.AdditionalAttributesAndInfoSets.Form.ItemForm",
			New Structure("Key", Object.PropertiesSet));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetOfPropertiesCreateOnServer()
	
	SetObject_ = Catalogs.AdditionalAttributesAndInfoSets.CreateItem();
	SetObject_.Description = Object.Description;
	SetObject_.Used = True;
	SetObject_.Parent = ?(
		Object.ThisNodeClass,
		PropertyManager.PropertiesSetByName("Catalog_SubAssets"),
		PropertyManager.PropertiesSetByName("Catalog_Assets"));
	
	SetObject_.Write();
	
	Object.PropertiesSet = SetObject_.Ref;
	
EndProcedure

&AtClient
Procedure PagesGroupOnCurrentPageChange(Item, CurrentPage)

	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
	        And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
	    
	    PropertiesExecuteDeferredInitialization();
	    PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRunningTimeValues

&AtClient
Procedure RunningTimeValuesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.RunningTimeValues.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	If NewRow And Not Copy Then
		CurrentData.RegistrationMethod = PredefinedValue("Enum.RunningTimeRegistrationMethods.Independently");
	EndIf;
	
EndProcedure

&AtClient
Procedure RunningTimeValuesRegistrationMethodOnChange(Item)
	
	CurrentData = Items.RunningTimeValues.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	CurrentData.RegisterBySource = 
		CurrentData.RegistrationMethod = PredefinedValue("Enum.RunningTimeRegistrationMethods.FromAsset");

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectRunningTimeValues(Command)
	
	ArrayOfSelected = New Array;
	For Each String In Object.RunningTimeValues Do
		ArrayOfSelected.Add(String.RunningTimeValue);
	EndDo;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("ArrayOfSelected", ArrayOfSelected);
	ParametersStructure.Insert("CloseOnChoice", False);
	
	OpenForm("Catalog.RunningTimeValues.ChoiceForm", ParametersStructure, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure DeleteRunningTimeValue(Command)
	
	CurrentRow = Items.RunningTimeValues.CurrentRow;
	If CurrentRow <> Undefined Then
		
		Object.RunningTimeValues.Delete(Object.RunningTimeValues.FindByID(CurrentRow));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region Private

#Region StandardSubsystems

// StandardSubsystems.Properties 

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
    PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMCycleRunningTimeInterval.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMCycleRunningTimeValue.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMCycleRunningTimeValueUnitOfMeasure.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RMIntervalByActivityRecords");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMCycleTimeInterval.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RMCycleTimeUnit.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RMIntervalByActivityRecords");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherRMActivitiesRunningTimeInterval.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherRMActivitiesRunningTimeValue.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherRMActivitiesRunningTimeValueUnitOfMeasure.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherRMActivities.ByAssetActivity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherRMActivitiesTimeInterval.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OtherRMActivitiesTimeUnit.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OtherRMActivities.ByAssetActivity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RunningTimeValuesMinimumCalculationPeriod.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RunningTimeValuesMaximumCalculationPeriod.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RunningTimeValues.RecalculateAverageDailyValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không cần>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RunningTimeValuesFrequencyOfRegistrationDays.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RunningTimeValues.RegisterBySource");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không cần>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttributesForControlRequiredForFilling.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AttributesForControl.RequiredForViewOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtServer
Procedure OnCreatReadAtServer(IsNew=False)
	
	InitializingFormWhenCreatingItOnServer();
	
	Items.DescriptionPage.Picture = CommonClientServer.CommentPicture(Object.LongDesc);
	
	FillInDetailsForControl(Object.AttributesForControl, Object.UseOfSubclasses);
	SetAvailabilityOfItemsOnServer();
	
	Items.RMCycleRMType.CreateButton = Not IsNew;
	Items.OtherRMActivitiesRMType.CreateButton = Not IsNew;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsOnServer()
	
	ItemArray = New Array;
	ItemArray.Add("RepairCyclePage_3");
	ItemArray.Add("OtherRepairsPage");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", Not Object.UseOfSubclasses);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, "ThisNodeClass", "Visible", UseSubAssets);
	
EndProcedure

&AtServer
Procedure FillInDetailsForControl(FillingData, UseOfSubclasses)
	
	Query = New Query(
		"SELECT
		|	CAST(MetadataSettings.Name AS STRING(255)) AS AttributeName,
		|	CAST(MetadataSettings.Synonym AS STRING) AS AttributeSynonym,
		|	CAST(MetadataSettings.RequiredForFilling AS BOOLEAN) AS RequiredForFilling,
		|	CAST(MetadataSettings.RequiredForViewOnly AS BOOLEAN) AS RequiredForViewOnly
		|INTO MetadataSettings
		|FROM
		|	&MetadataSettings AS MetadataSettings
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CAST(SettingUpCur.AttributeName AS STRING(255)) AS AttributeName,
		|	CAST(SettingUpCur.RequiredForFilling AS BOOLEAN) AS RequiredForFilling
		|INTO CurSettings_
		|FROM
		|	&CurSettings_ AS SettingUpCur
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MetadataSettings.AttributeName AS AttributeName,
		|	MetadataSettings.AttributeSynonym AS AttributeSynonym,
		|	CASE
		|		WHEN MetadataSettings.RequiredForViewOnly
		|			THEN MetadataSettings.RequiredForFilling
		|		ELSE CurSettings_.RequiredForFilling
		|	END AS RequiredForFilling,
		|	MetadataSettings.RequiredForViewOnly
		|FROM
		|	MetadataSettings AS MetadataSettings
		|		LEFT JOIN CurSettings_ AS CurSettings_
		|		ON MetadataSettings.AttributeName = CurSettings_.AttributeName");
	
	Query.SetParameter("CurSettings_", FillingData.Unload( ,"AttributeName, RequiredForFilling"));
	Query.SetParameter(
		"MetadataSettings",
		?(Object.ThisNodeClass,
			Catalogs.SubAssets.AttributeSet(),
			Catalogs.Assets.CompositionOfDetailsOfObjectOfOperation()));
	
	Selection = Query.Execute().Select();
	AttributesForControl.Clear();
	
	SettingsForIndividualBankingDetails = New Structure;
	SettingsForIndividualBankingDetails.Insert("Subclass", New Structure("RequiredForFilling", UseOfSubclasses));
	
	While Selection.Next() Do
		
		PropsString = AttributesForControl.Add();
		PropsString.AttributeName = TrimAll(Selection.AttributeName);
		FillPropertyValues(PropsString, Selection, , "AttributeName");
		
		If SettingsForIndividualBankingDetails.Property(PropsString.AttributeName) Then
			FillPropertyValues(PropsString, SettingsForIndividualBankingDetails[PropsString.AttributeName]);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()
	
	UseSubAssets = GetFunctionalOption("UseSubAssets");

	AvailablePropertySets = New Array;
	AvailablePropertySets.Add(PropertyManager.PropertiesSetByName("Catalog_Assets"));
	AvailablePropertySets.Add(PropertyManager.PropertiesSetByName("Catalog_SubAssets"));
	
	ListOfSelectionParameters = New Array();
	ListOfSelectionParameters.Add(New ChoiceParameter("Filter.Parent", AvailablePropertySets));
	
	Items.PropertiesSet.ChoiceParameters = New FixedArray(ListOfSelectionParameters);
	
EndProcedure

#EndRegion

#EndRegion
