#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ObjectTypeDM", ObjectTypeDM);
	Parameters.Property("ObjectTypeIS", ObjectTypeIS);
	Parameters.Property("DocumentKindDM", DocumentKindDM);
	Parameters.Property("Variant", Variant);
	Parameters.Property("IsFullUser", IsFullUser);
	Parameters.Property("ObjectAttributePresentationIS", ObjectAttributePresentationIS);
	Parameters.Property("ObjectAttributeTypeIS", ObjectAttributeTypeIS);
	Parameters.Property("AttributeNameObjectDM", AttributeNameObjectDM);
	Parameters.Property("ObjectAttributePresentationDM", ObjectAttributePresentationDM);
	Parameters.Property("ObjectAttributesBefore", ObjectAttributesBefore);
	Parameters.Property("AttributeValueIS", AttributeValueIS);
	Parameters.Property("ComputedExpression", ComputedExpression);
	Parameters.Property("ShouldUpdate", ShouldUpdate);
	Parameters.Property("UpdateParent", UpdateParent);
	Parameters.Property("DependentItem", DependentItem);
	Parameters.Property("IsAdditionalAttributeDM", IsAdditionalAttributeDM);
	Parameters.Property("AdditionalAttributeDMID", AdditionalAttributeDMID);
	Parameters.Property("AdditionalAttributeDMType", AdditionalAttributeDMType);
	Parameters.Property("IsAdditionalAttributeIS", IsAdditionalAttributeIS);
	Parameters.Property("AdditionalAttributeIS", AdditionalAttributeIS);
	Parameters.Property("KeyAttribute_", KeyAttribute_);
	Parameters.Property("Table", Table);
	
	ObjectAttribute = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute");
	SpecifiedValue = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue");
	ScriptExpression =
		PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ScriptExpression");
	DontFill = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.EmptyRef");
	
	// Let's choose the default option.
	If Not ValueIsFilled(Variant) And Not KeyAttribute_ Then
		ShouldUpdate = True;
	EndIf;
	
	If DependentItem Then
		ShouldUpdate = UpdateParent;
	EndIf;
	
	AttributeValueIS = ObjectAttributeTypeIS.AdjustValue(AttributeValueIS);
	
	IntegrationWith1CDocumentManagementCoreClientServer.ConfigureInputFieldByType(
		Items.AttributeValueIS,
		ObjectAttributeTypeIS);
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
		Title = StrTemplate(NStr("vi = 'Quy tắc điền mục tin %1';
								|ru = 'Правило заполнения реквизита %1';
								|en = '%1 attribute filling rule'; fa = '%1 attribute filling rule';
								|it = 'Regola di compilazione dell''attributo %1';
								|pl = 'Reguła wypełnienia atrybutu %1';
								|tr = 'Öznitelik doldurma kuralı %1'"), AbbreviatedNameOfConfiguration);
	EndIf;
	
	// We will limit the choice of filling options and the Key checkbox.
	If Variant = ScriptExpression Or Variant = ObjectAttribute Or Variant = DontFill Then
		Items.KeyAttribute_.Enabled = False;
	Else
		Items.KeyAttribute_.Enabled = True;
	EndIf;
	ExchangeFunctionalityIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable(
		"1.3.2.3.CORP");
	Items.ShouldUpdate.Visible = ExchangeFunctionalityIsAvailable;
	
	Items.ModeOfChangingTheDataOfThePostedDocument.Visible =
		(Parameters.FillingInDocument And ExchangeFunctionalityIsAvailable);
	If Items.ModeOfChangingTheDataOfThePostedDocument.Visible Then
		Parameters.Property("ModeOfChangingTheDataOfThePostedDocument", ModeOfChangingTheDataOfThePostedDocument);
		If Not ValueIsFilled(ModeOfChangingTheDataOfThePostedDocument) Then
			ModeOfChangingTheDataOfThePostedDocument =
				Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.Prohibited;
		EndIf;
		// We will set the available modes of change in the conducted document.
		Items.ModeOfChangingTheDataOfThePostedDocument.ChoiceList.Add(
			Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting);
		Items.ModeOfChangingTheDataOfThePostedDocument.ChoiceList.Add(
			Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithoutReposting);
		Items.ModeOfChangingTheDataOfThePostedDocument.ChoiceList.Add(
			Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.Prohibited);
		IntegrationWith1CDocumentManagementCoreOverridable.SetModesOfChangeInConductedDocument(
			ObjectTypeIS,
			ObjectAttributePresentationIS,
			Items.ModeOfChangingTheDataOfThePostedDocument.ChoiceList);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetAvailability();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure KeyAttribute_OnChange(Item)
	
	If KeyAttribute_ Then
		Variant = SpecifiedValue;
		SetAvailability();
	EndIf;
	
EndProcedure

&AtClient
Procedure VariantOnChange(Item)
	
	If Variant = ScriptExpression Or Variant = ObjectAttribute Or Variant = DontFill Then
		KeyAttribute_ = False;
		Items.KeyAttribute_.Enabled = False;
	Else
		Items.KeyAttribute_.Enabled = True;
	EndIf;
	
	If DependentItem Then
		ShouldUpdate = UpdateParent;
	Else
		ShouldUpdate =
			ExchangeFunctionalityIsAvailable
			And (ShouldUpdate Or Variant = ObjectAttribute)
			And Not (Variant = DontFill)
			And Not (Variant = SpecifiedValue);
	EndIf;
	
	SetAvailability();
	
EndProcedure

&AtClient
Procedure ObjectAttributePresentationDMStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectThe1CDocumentManagementObjectAttribute();
	
EndProcedure

&AtClient
Procedure AttributeValueISStartChoice(Item, ChoiceData, StandardProcessing)
	
	If TypeOf(AttributeValueIS) = Type("Number")
		Or TypeOf(AttributeValueIS) = Type("Date")
		Or TypeOf(AttributeValueIS) = Type("Boolean") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("ChooseValueOfAttributeISCompletionInputValue", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.ChooseValueOfAttributeIS(
		ThisObject,
		Items.AttributeValueIS,
		ObjectAttributeTypeIS,
		ObjectAttributePresentationIS,
		AttributeValueIS,
		AdditionalAttributeIS,
		Notification);
	
EndProcedure

&AtClient
Procedure ChooseValueOfAttributeISCompletionInputValue(Result, NotificationParameters) Export
	
	If Result <> Undefined Then
		AttributeValueIS = Result;
	EndIf;
	
EndProcedure

&AtClient
Procedure ComputedExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectCalculatedExpression();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("AttributeNameObjectDM");
	Result.Insert("ObjectAttributePresentationDM");
	Result.Insert("AttributeValueIS");
	Result.Insert("ComputedExpression");
	Result.Insert("Picture");
	
	If Variant = ObjectAttribute Then
		Result.AttributeNameObjectDM = AttributeNameObjectDM;
		Result.ObjectAttributePresentationDM = ObjectAttributePresentationDM;
		Result.Picture = 1;
		
	ElsIf Variant = SpecifiedValue Then
		Result.AttributeValueIS = AttributeValueIS;
		Result.Picture = 2;
		
	ElsIf Variant = ScriptExpression Then
		Result.ComputedExpression = ComputedExpression;
		Result.Picture = 3;
		
	EndIf;
	
	Result.Insert("Variant", Variant);
	Result.Insert("ShouldUpdate", ShouldUpdate);
	Result.Insert("IsAdditionalAttributeDM", IsAdditionalAttributeDM);
	Result.Insert("AdditionalAttributeDMID", AdditionalAttributeDMID);
	Result.Insert("AdditionalAttributeDMType", AdditionalAttributeDMType);
	Result.Insert("KeyAttribute_", KeyAttribute_);
	Result.Insert("ModeOfChangingTheDataOfThePostedDocument", ModeOfChangingTheDataOfThePostedDocument);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectThe1CDocumentManagementObjectAttribute()
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectTypeDM", ObjectTypeDM);
	FormParameters.Insert("ObjectAttributesBefore", ObjectAttributesBefore);
	FormParameters.Insert("AttributeNameObjectDM", AttributeNameObjectDM);
	FormParameters.Insert("ObjectAttributePresentationIS", ObjectAttributePresentationIS);
	FormParameters.Insert("Table", Table);
	FormParameters.Insert("ThisIsTable", False);
	
	Notification = New CallbackDescription("SelectThe1CDocumentManagementObjectAttributeCompletion", ThisObject);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectAttributeDM",
		FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectThe1CDocumentManagementObjectAttributeCompletion(Result, NotificationParameters) Export

	If TypeOf(Result) = Type("Structure") Then
		Result.Property("Name", AttributeNameObjectDM);
		Result.Property("Presentation", ObjectAttributePresentationDM);
		Result.Property("IsAdditionalAttributeDM", IsAdditionalAttributeDM);
		Result.Property("AdditionalAttributeDMID", AdditionalAttributeDMID);
		Result.Property("AdditionalAttributeDMType", AdditionalAttributeDMType);
	EndIf;

EndProcedure

&AtClient
Procedure SelectCalculatedExpression()
	
	FormParameters = New Structure;
	FormParameters.Insert("ComputedExpression", ComputedExpression);
	FormParameters.Insert("TypeOfExpression", "LoadingRule");
	FormParameters.Insert("ObjectTypeDM", ObjectTypeDM);
	FormParameters.Insert("ObjectTypeIS", ObjectTypeIS);
	FormParameters.Insert("ThisIsTable", False);
	FormParameters.Insert("DocumentKindDM", DocumentKindDM);
	
	CallbackDescription = New CallbackDescription("SelectCalculatedExpressionCompletion", ThisObject);
	
	OpenForm("Catalog.RulesForIntegrationWith1CDocumentManagement.Form.ScriptExpression",
		FormParameters, ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure SelectCalculatedExpressionCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("String") Then
		ComputedExpression = Result;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAvailability()
	
	Items.ObjectAttributePresentationDM.Enabled = (Variant = ObjectAttribute);
	Items.ObjectAttributePresentationDM.AutoMarkIncomplete =
		(Variant = ObjectAttribute);
	Items.ObjectAttributePresentationDM.MarkIncomplete =
		(Variant = ObjectAttribute) And Not ValueIsFilled(ObjectAttributePresentationDM);
	
	Items.AttributeValueIS.Enabled = (Variant = SpecifiedValue);
	Items.AttributeValueIS.AutoMarkIncomplete = (Variant = SpecifiedValue);
	Items.AttributeValueIS.MarkIncomplete =
		(Variant = SpecifiedValue) And Not ValueIsFilled(AttributeValueIS);
	
	Items.ComputedExpression.Enabled = IsFullUser And (Variant = ScriptExpression);
	Items.ComputedExpression.AutoMarkIncomplete = (Variant = ScriptExpression);
	Items.ComputedExpression.MarkIncomplete =
		(Variant = ScriptExpression) And Not ValueIsFilled(ComputedExpression);
	
	Items.ModeOfChangingTheDataOfThePostedDocument.Enabled =
		(Variant = ObjectAttribute)
		Or (Variant = ScriptExpression);
	
	Items.ShouldUpdate.Enabled = Not (Variant = SpecifiedValue) And Not DependentItem;
	Items.ModeOfChangingTheDataOfThePostedDocument.Enabled = Not (Variant = SpecifiedValue) And Not DependentItem;
	
	If DependentItem Then
		ShouldUpdate = UpdateParent;
	Else
		ShouldUpdate = ShouldUpdate And Not (Variant = SpecifiedValue);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute Then
		CheckedAttributes.Add("ObjectAttributePresentationDM");
		If Parameters.FillingInDocument Then
			CheckedAttributes.Add("ModeOfChangingTheDataOfThePostedDocument");
		EndIf;
		
	ElsIf Variant = Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue Then
		CheckedAttributes.Add("AttributeValueIS");
		
	ElsIf Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression Then
		CheckedAttributes.Add("ComputedExpression");
		If Parameters.FillingInDocument Then
			CheckedAttributes.Add("ModeOfChangingTheDataOfThePostedDocument");
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion