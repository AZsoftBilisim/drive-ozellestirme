
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// Work Selection Options
	ChoiceParameters = New Array;
	ChoiceParameters.Add(New ChoiceParameter("Filter.ItemsType", Enums.ItemsTypes.Work_5));
	
	VariantList = New ValueList();
	VariantList.Add(Enums.ItemVariantsUsageOptions.SpecialForItems);
	VariantList.Add(Enums.ItemVariantsUsageOptions.CommonForItemKind);
	VariantList.Add(Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind);
	ChoiceParameters.Add(New ChoiceParameter("Filter.UseVariants", VariantList));
	
	Items.Work_5.ChoiceParameters = New FixedArray(ChoiceParameters);
	
	// System settings
	UseQuality = UseQuality();
	
	// Reading general settings
	SetPrivilegedMode(True);
	SettingsValue = Constants.SettingsOfProductionLotDivision.Get().Get();
	SetPrivilegedMode(False);
	If TypeOf(SettingsValue) = Type("Structure") Then
		FillPropertyValues(ThisObject, SettingsValue);
	EndIf;
	
	// Reading user settings
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.ProductionLotDivision", "");
	If TypeOf(SettingsValue) = Type("Structure") Then
		FillPropertyValues(ThisObject, SettingsValue);
	EndIf;
	
	// Configuring elements
	Items.AnalogsGroup.Visible = GetFunctionalOption("UseAlternativeMaterials");
	FillInByBillOfMaterialsForm = FillInByBOM;
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not UseWork Then
		SequenceNumber = CheckedAttributes.Find("Work_5");
		If SequenceNumber <> Undefined Then
			CheckedAttributes.Delete(SequenceNumber);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConstantsSet"
		And Source = "UseGoodsQuality" Then
		
		UseQuality = UseQuality();
		
		If Not UseQuality
			And UseGoodsOfDifferentQuality Then
			UseGoodsOfDifferentQuality = False;
		EndIf;
		
		ConfigureDependentFormElements(ThisObject, "UseQuality");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseWorkOnChange(Item)
	
	If Not UseWork Then
		Work_5 = Undefined
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "UseWork");
	
EndProcedure

&AtClient
Procedure FillInFormAccordingToBillOfMaterialsWhenChanging(Item)
	
	FillInByBOM = FillInByBillOfMaterialsForm;
	
	If Not FillInByBOM Then
		ReserveMaterials = False;
		ReplaceMaterialsWithAnalogs = False;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "FillInByBOM");
	
EndProcedure

&AtClient
Procedure ReserveMaterialsOnChange(Item)
	
	If Not ReserveMaterials Then
		ReplaceMaterialsWithAnalogs = False;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "ReserveMaterials");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)
	
	Cancel = False;
	SaveAtServer(Cancel);
	
	If Cancel Then
		Return;
	Else
		Close(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("UseWork")
		Or Initialize Then
		
		Items.Work_5.Enabled = Form.UseWork;
		
	EndIf;
	
	If AttributesStructure1.Property("UseQuality")
		Or Initialize Then
		
		Items.UseGoodsOfDifferentQuality.Enabled = Form.UseQuality;
		Items.UseQualityWarning.Visible = Not Form.UseQuality;
		
	EndIf;
	
	If AttributesStructure1.Property("FillInByBOM")
		Or Initialize Then
		
		Items.ReserveMaterials.Enabled = Form.FillInByBOM;
		
	EndIf;
	
	If AttributesStructure1.Property("FillInByBOM")
		Or AttributesStructure1.Property("ReserveMaterials")
		Or Initialize Then
			
		Items.ReplaceMaterialsWithAnalogs.Enabled = Form.FillInByBOM
			And Form.ReserveMaterials;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function UseQuality()
	
	Return GetFunctionalOption("UseGoodsQuality");
	
EndFunction

&AtServer
Procedure SaveAtServer(Cancel)
	
	If Not CheckFilling() Then
		Cancel = True;
		Return;
	EndIf;
	
	// Saving general settings
	SettingsValue = New Structure;
	SettingsValue.Insert("UseWork", UseWork);
	SettingsValue.Insert("Work_5", Work_5);
	SettingsValue.Insert("UseGoodsOfDifferentQuality", UseGoodsOfDifferentQuality);
	
	SetPrivilegedMode(True);
	Constants.SettingsOfProductionLotDivision.Set(New ValueStorage(SettingsValue));
	SetPrivilegedMode(False);
	
	// Saving user settings
	SettingsValue = New Structure;
	SettingsValue.Insert("FillInByBOM", FillInByBOM);
	SettingsValue.Insert("ReserveMaterials", ReserveMaterials);
	SettingsValue.Insert("ReplaceMaterialsWithAnalogs", ReplaceMaterialsWithAnalogs);
	
	Common.CommonSettingsStorageSave("DataProcessor.ProductionLotDivision", "", SettingsValue);
	
EndProcedure

#EndRegion
