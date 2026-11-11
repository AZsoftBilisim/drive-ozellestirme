#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("AttributeNameObjectDM", AttributeNameObjectDM);
	Parameters.Property("ObjectAttributePresentationDM", ObjectAttributePresentationDM);
	Parameters.Property("ObjectAttributeTypeDM", ObjectAttributeTypeDM);
	Parameters.Property("Variant", Variant);
	Parameters.Property("IsFullUser", IsFullUser);
	Parameters.Property("AttributeNameObjectIS", AttributeNameObjectIS);
	Parameters.Property("AttributeValueDM", AttributeValueDM);
	Parameters.Property("AttributeValueDMID", AttributeValueDMID);
	Parameters.Property("AttributeValueDMType", AttributeValueDMType);
	Parameters.Property("ComputedExpression", ComputedExpression);
	Parameters.Property("ObjectTypeDM", ObjectTypeDM);
	Parameters.Property("ObjectTypeIS", ObjectTypeIS);
	Parameters.Property("ShouldUpdate", ShouldUpdate);
	Parameters.Property("UpdateParent", UpdateParent);
	Parameters.Property("AdditionalAttributeDMID", AdditionalAttributeDMID);
	Parameters.Property("AdditionalAttributeDMType", AdditionalAttributeDMType);
	Parameters.Property("KeyAttribute_", KeyAttribute_);
	Parameters.Property("TemplateMeaning", TemplateMeaning);
	Parameters.Property("TemplateID", TemplateID);
	Parameters.Property("FilledInTemplate", FilledInTemplate);
	Parameters.Property("Table", Table);
	Parameters.Property("DependentItem", DependentItem);
	Parameters.Property("DocumentKindDM", DocumentKindDM);
	
	ObjectAttribute = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute");
	SpecifiedValue = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue");
	ScriptExpression =
		PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ScriptExpression");
	FromTemplate = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.FromTemplate");
	DontFill = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.EmptyRef");
	
	If FilledInTemplate Then
		
		VariantList = Items.Variant.ChoiceList;
		VariantList.Delete(VariantList.FindByValue(DontFill));
		VariantList.Add(FromTemplate, NStr("vi = 'Từ khuôn mẫu';
											|ru = 'Из шаблона';
											|en = 'From template'; fa = 'از الگو';
											|it = 'Da modello';
											|pl = 'Z szablonu';
											|tr = 'Şablondan'"));
			
		Items.TemplatePages.CurrentPage = Items.PageFilledInTemplate;
			
		If Parameters.TemplateForbidModification = True Or AttributeNameObjectDM = "documentType" Then
			
			TemplateForbidModification = True;
			
			Variant = FromTemplate;
			Items.Variant.Enabled = False;
			
			If AttributeNameObjectDM = "documentType" Then
				HelpText = NStr("vi = 'Dạng chứng từ được chọn trong khuôn mẫu và không thể thay đổi.';
								|ru = 'Вид документа выбран в шаблоне и не может быть изменен.';
								|en = 'Document kind is selected in the template and cannot be changed.'; fa = 'Document kind is selected in the template and cannot be changed.';
								|it = 'Tipo di documento selezionato nel modello e impossibile modificarlo.';
								|pl = 'Rodzaj dokumentu jest wybrany w szablonie i nie może być zmieniony.';
								|tr = 'Belge türü numunede seçildi ve değiştirilemez.'");
			Else
				HelpText = NStr("vi = 'Khuôn mẫu cấm thay đổi các mục tin đã đặt trong đó.';
								|ru = 'Шаблон запрещает изменение заданных в нем реквизитов.';
								|en = 'Template prohibits changing the attributes specified in it.'; fa = 'Template prohibits changing the attributes specified in it.';
								|it = 'Il modello viene la modifica degli attributi in esso indicati.';
								|pl = 'Szablon zabrania zmianę zadanych w nim atrybutów.';
								|tr = 'Numune, içinde belirtilen özniteliklerin değiştirilmesini yasaklar.'");
			EndIf;
			
		EndIf;
		
	Else // Not filled in in the template.
		
		Items.TemplatePages.CurrentPage = Items.PageNotFilledInTemplate;
		
		If AttributeNameObjectDM = "documentType" Then
			Variant = SpecifiedValue;
			Items.Variant.Enabled = False;
		EndIf;
		
	EndIf;
	
	// Let's choose the default option.
	If Not ValueIsFilled(Variant) Then
		
		If Not FilledInTemplate Then
			If AttributeNameObjectDM = "folder"
					Or AttributeNameObjectDM = "accessLevel"
					Or AttributeNameObjectDM = "activityMatter" Then
				ShouldUpdate = False;
			Else
				ShouldUpdate = True;
			EndIf;
		Else
			Variant = Enums.VariantsOfTheRulesForFillingInAttributes.FromTemplate;
		EndIf;
		
	EndIf;
	
	If DependentItem Then
		ShouldUpdate = UpdateParent;
	EndIf;
	
	// Configure the input field for primitive types.
	If ObjectAttributeTypeDM.Count() = 0 Then
		Items.Variant.ChoiceList.Delete(Items.Variant.ChoiceList.FindByValue(SpecifiedValue));
		Items.AttributeValueDM.Visible = False;
	Else
		FirstType = ObjectAttributeTypeDM[0].Value;
		If AttributeValueDM = Undefined Then
			
			If FirstType = "Number" Then
				AttributeValueDM = 0;
				
			ElsIf FirstType = "Date" Then
				AttributeValueDM = Date(1, 1, 1);
				
			ElsIf FirstType = "Boolean" Then
				AttributeValueDM = False;
				
			Else // String or reference type BEFORE.
				AttributeValueDM = "";
				
			EndIf;
		EndIf;
		
		If FirstType = "Number" Or FirstType = "Date" Then
			Items.AttributeValueDM.SpinButton = True;
		EndIf;
		
	EndIf;
	
	// We will limit the choice of filling options and the Key checkbox.
	If AttributeNameObjectDM = "documentType" Then
		KeyAttribute_ = True;
		Items.KeyAttribute_.Enabled = False;
		Items.ShouldUpdate.Enabled = False;
	Else
		If Variant = ScriptExpression
			Or Variant = ObjectAttribute
			Or Variant = DontFill Then
			Items.KeyAttribute_.Enabled = False;
		Else
			Items.KeyAttribute_.Enabled = True;
		EndIf;
	EndIf;
	
	ExchangeFunctionalityIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable(
		"1.3.2.3.CORP");
	Items.ShouldUpdate.Visible = ExchangeFunctionalityIsAvailable;
	
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
		If FilledInTemplate Then
			If TemplateForbidModification Then
				Variant = FromTemplate;
				SetAvailability();
			EndIf;
		Else
			Variant = SpecifiedValue;
			SetAvailability();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure VariantOnChange(Item)
	
	If Variant = ScriptExpression Or Variant = ObjectAttribute
			Or (Variant = DontFill And Not FilledInTemplate) Then
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
Procedure AttributeNameObjectISStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectDetailsOfConsumerObject();
	
EndProcedure

&AtClient
Procedure AttributeValueDMStartChoice(Item, ChoiceData, StandardProcessing)
	
	If TypeOf(AttributeValueDM) = Type("Number")
		Or TypeOf(AttributeValueDM) = Type("Date")
		Or TypeOf(AttributeValueDM) = Type("Boolean") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	ChooseValueOfAttributeBefore(Items.AttributeValueDM);
	
EndProcedure

&AtClient
Procedure AttributeValueDMChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		AttributeValueDM = ValueSelected.name;
		AttributeValueDMID = ValueSelected.ID;
		AttributeValueDMType = ValueSelected.type;
	Else
		AttributeValueDM = ValueSelected;
	EndIf;
	
EndProcedure

&AtClient
Procedure AttributeValueDMAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		FirstType = ObjectAttributeTypeDM[0].Value;
		If FirstType = "String"
			Or FirstType = "Boolean"
			Or FirstType = "Date"
			Or FirstType = "Number" Then
			Return;
		EndIf;
			
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			FirstType, ChoiceData, Text, StandardProcessing);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AttributeValueDMTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		FirstType = ObjectAttributeTypeDM[0].Value;
		If FirstType = "String"
			Or FirstType = "Boolean"
			Or FirstType = "Date"
			Or FirstType = "Number" Then
			Return;
		EndIf;
			
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			FirstType, ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			AttributeValueDMChoiceProcessing(
				Items.AttributeValueDM,
				ChoiceData[0].Value,
				StandardProcessing);
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ComputedExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
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
	Result.Insert("Variant", Variant);
	Result.Insert("AttributeNameObjectIS");
	Result.Insert("AttributeValueDM");
	Result.Insert("AttributeValueDMID");
	Result.Insert("AttributeValueDMType");
	Result.Insert("ComputedExpression");
	Result.Insert("Picture");
	Result.Insert("ShouldUpdate", ShouldUpdate);
	Result.Insert("IsAdditionalAttributeIS", IsAdditionalAttributeIS);
	Result.Insert("AdditionalAttributeIS", AdditionalAttributeIS);
	Result.Insert("KeyAttribute_", KeyAttribute_);
	Result.Insert("TemplatePresentation");
	
	If Variant = ObjectAttribute Then
		
		Result.AttributeNameObjectIS = AttributeNameObjectIS;
		Result.Picture = 1;
		
	ElsIf Variant = SpecifiedValue Then
		
		Result.AttributeValueDM = AttributeValueDM;
		Result.AttributeValueDMID = AttributeValueDMID;
		Result.AttributeValueDMType = AttributeValueDMType;
		
		// Let's check if there is a conflict between the rule and the template.
		If FilledInTemplate
				And ((ValueIsFilled(AttributeValueDMID) And AttributeValueDMID <> TemplateID)
					Or (Not ValueIsFilled(AttributeValueDMID) And AttributeValueDM <> TemplateMeaning)) Then
			
			Result.Picture = 4;
			Result.TemplatePresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'khuôn mẫu: %1';
					|ru = 'шаблон: %1';
					|en = 'template: %1'; fa = 'template: %1';
					|it = 'modello: %1';
					|pl = 'szablon: %1';
					|tr = 'numune: %1'"),
				TemplateMeaning);
			
		Else // There is no conflict.
			
			Result.Picture = 2;
			
		EndIf;
		
	ElsIf Variant = ScriptExpression Then
		
		Result.ComputedExpression = ComputedExpression;
		Result.Picture = 3;
		
	ElsIf Variant = FromTemplate Then
		
		Result.TemplatePresentation = TemplateMeaning;
		Result.Picture = 5;
		
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectDetailsOfConsumerObject()
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectType", ObjectTypeIS);
	FormParameters.Insert("AttributeNameObjectIS", AttributeNameObjectIS);
	FormParameters.Insert("ObjectAttributePresentationDM", ObjectAttributePresentationDM);
	FormParameters.Insert("Table", Table);
	FormParameters.Insert("ThisIsTable", False);
	
	ChoiceFormName = "Catalog.RulesForIntegrationWith1CDocumentManagement.Form.SelectAttributeIS";
	Notification = New CallbackDescription("SelectDetailsOfConsumerObjectCompletion", ThisObject);
	
	OpenForm(ChoiceFormName, FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectDetailsOfConsumerObjectCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		Result.Property("Name", AttributeNameObjectIS);
		Result.Property("IsAdditionalAttributeIS", IsAdditionalAttributeIS);
		Result.Property("AdditionalAttributeIS", AdditionalAttributeIS);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChooseValueOfAttributeBefore(Item)
	
	Types = ObjectAttributeTypeDM;
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("TypeDetails", ObjectAttributeTypeDM);
	ChoiceParameters.Insert("EditText", Item.EditText);
	
	If Types.Count() = 1 Then
		ChooseValueOfAttributeBeforeCompletion(Types[0].Value, ChoiceParameters);
	Else
		CallbackDescription = New CallbackDescription(
			"ChooseValueOfAttributeBeforeCompletion",
			ThisObject,
			ChoiceParameters);
		TypesList = New ValueList;
		TypesList.LoadValues(Types);
		ShowChooseFromList(CallbackDescription, TypesList, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChooseValueOfAttributeBeforeCompletion(TypeValue, ChoiceParameters) Export
	
	Notification = New CallbackDescription("ChooseValueOfAttributeDMCompletionInputValue", ThisObject);
	
	If TypeValue = "String" Then
		AttributeValue = ChoiceParameters.EditText;
		ShowInputString(
			Notification,
			StrReplace(AttributeValue, "¶", Chars.LF),
			ObjectAttributePresentationDM,,
			True);
		
	ElsIf TypeValue = "Number" Then
		AttributeValue = AttributeValueDM;
		ShowInputNumber(
			Notification,
			AttributeValue,
			ObjectAttributePresentationDM,
			15,
			5);
		
	ElsIf TypeValue = "Date" Then
		AttributeValue = AttributeValueDM;
		ShowInputDate(
			Notification,
			AttributeValue,
			ObjectAttributePresentationDM,
			DateFractions.Date);
		
	ElsIf TypeValue = "DateTime" Then
		AttributeValue = AttributeValueDM;
		ShowInputDate(
			Notification,
			AttributeValue,
			ObjectAttributePresentationDM,
			DateFractions.DateTime);
		
	ElsIf TypeValue = "Time" Then
		AttributeValue = AttributeValueDM;
		ShowInputDate(
			Notification,
			AttributeValue,
			ObjectAttributePresentationDM,
			DateFractions.Time);
		
	ElsIf TypeValue = "Boolean" Then
		AttributeValue = AttributeValueDM;
		ShowInputValue(
			Notification,
			AttributeValue,
			ObjectAttributePresentationDM,
			Type("Boolean"));
		
	ElsIf TypeValue = "DMParty" Then
		TypesOfXDTO = New Array;
		TypesOfXDTO.Add("DMOrganization");
		TypesOfXDTO.Add("DMCorrespondent");
		TypesOfXDTO.Add("DMUser");
		AvailableTypeList = New ValueList;
		For Each XDTOType In TypesOfXDTO Do
			Presentation = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(XDTOType);
			AvailableTypeList.Add(
				New Structure("XDTOClassName, Presentation", XDTOType, Presentation));
		EndDo;
		
		FormCaption = NStr("vi = 'Chọn kiểu giá trị';
							|ru = 'Выбор типа значения';
							|en = 'Select value type'; fa = 'انتخاب نوع مقدار';
							|it = 'Selezione del tipo di valore';
							|pl = 'Wybór typu wartości';
							|tr = 'Değer türü seçimi'");
		
		FormParameters = New Structure("AvailableTypeList, FormCaption",
			AvailableTypeList, FormCaption);
		NotificationTypeSelection = New CallbackDescription(
			"SelectingTypeOfCompletion",
			ThisObject,
			New Structure("Notification", Notification));
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingOneTypeFromCompositeType",
			FormParameters,,,,, NotificationTypeSelection);
		
	ElsIf TypeValue = "DMPartyRowContact" Then
		TypesOfXDTO = New Array;
		TypesOfXDTO.Add("DMContactPerson");
		TypesOfXDTO.Add("DMUser");
		AvailableTypeList = New ValueList;
		For Each XDTOType In TypesOfXDTO Do
			Presentation = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(XDTOType);
			AvailableTypeList.Add(
				New Structure("XDTOClassName, Presentation", XDTOType, Presentation));
		EndDo;
		
		FormCaption = NStr("vi = 'Chọn kiểu giá trị';
							|ru = 'Выбор типа значения';
							|en = 'Select value type'; fa = 'انتخاب نوع مقدار';
							|it = 'Selezione del tipo di valore';
							|pl = 'Wybór typu wartości';
							|tr = 'Değer türü seçimi'");
		
		FormParameters = New Structure("AvailableTypeList, FormCaption",
			AvailableTypeList, FormCaption);
		NotificationTypeSelection = New CallbackDescription(
			"SelectingTypeOfCompletion",
			ThisObject,
			New Structure("Notification", Notification));
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingOneTypeFromCompositeType",
			FormParameters,,,,, NotificationTypeSelection);
		
	Else
		FormParameters = New Structure;
		FormParameters.Insert("TypeOfSelectionObject", TypeValue);
		If ValueIsFilled(AttributeValueDMID)
			And TypeValue = AttributeValueDMType Then
			FormParameters.Insert("SelectedElement", AttributeValueDMID);
		EndIf;
		If TypeValue = "DMObjectPropertyValue" Then
			Owner = New Structure;
			Owner.Insert("ID", 	AdditionalAttributeDMID);
			Owner.Insert("Type", 	AdditionalAttributeDMType);
			
			Filter = New Structure;
			Filter.Insert("AdditionalProperty", Owner);
			
			FormParameters.Insert("Filter", Filter);
		EndIf;
		
		ChoiceFormName = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList";
		OpenForm(ChoiceFormName, FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectingTypeOfCompletion(Selected_2Type, Var_Parameters) Export
	
	If Selected_2Type = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", Selected_2Type);
	If ValueIsFilled(AttributeValueDMID) And Selected_2Type = AttributeValueDMType Then
		FormParameters.Insert("SelectedElement", AttributeValueDMID);
	EndIf;
	
	ChoiceFormName = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList";
	OpenForm(
		ChoiceFormName,
		FormParameters,
		ThisObject,,,,
		Var_Parameters.Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChooseValueOfAttributeDMCompletionInputValue(Result, NotificationParameters) Export
	
	If Result <> Undefined Then
		If TypeOf(Result) = Type("Structure") Then
			AttributeValueDM = Result.AttributePresentation;
			AttributeValueDMID = Result.AttributeID;
			AttributeValueDMType = Result.AttributeType;
		Else
			AttributeValueDM = Result;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectCalculatedExpression()
	
	FormParameters = New Structure;
	FormParameters.Insert("ComputedExpression", ComputedExpression);
	FormParameters.Insert("TypeOfExpression", "ExportRule");
	FormParameters.Insert("ObjectTypeIS", ObjectTypeIS);
	FormParameters.Insert("ObjectTypeDM", ObjectTypeDM);
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
	
	Items.AttributeNameObjectIS.Enabled = (Variant = ObjectAttribute);
	Items.AttributeNameObjectIS.AutoMarkIncomplete = (Variant = ObjectAttribute);
	Items.AttributeNameObjectIS.MarkIncomplete = (Variant = ObjectAttribute) And Not ValueIsFilled(AttributeNameObjectIS);
	
	Items.AttributeValueDM.Enabled = (Variant = SpecifiedValue);
	Items.AttributeValueDM.AutoMarkIncomplete = (Variant = SpecifiedValue);
	Items.AttributeValueDM.MarkIncomplete = (Variant = SpecifiedValue) And Not ValueIsFilled(AttributeValueDM);
	
	Items.ComputedExpression.Enabled = IsFullUser And (Variant = ScriptExpression);
	Items.ComputedExpression.AutoMarkIncomplete = (Variant = ScriptExpression);
	Items.ComputedExpression.MarkIncomplete = (Variant = ScriptExpression) And Not ValueIsFilled(ComputedExpression);
	
	AllowedUpdate = Not TemplateForbidModification
		And (Variant <> SpecifiedValue)
		And (Variant <> FromTemplate);
	Items.ShouldUpdate.Enabled = AllowedUpdate And Not DependentItem;
	
	If DependentItem Then
		ShouldUpdate = UpdateParent;
	Else
		ShouldUpdate = ShouldUpdate And AllowedUpdate;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Variant = ObjectAttribute Then
		CheckedAttributes.Add("AttributeNameObjectIS");
		
	ElsIf Variant = SpecifiedValue Then
		CheckedAttributes.Add("AttributeValueDM");
		
	ElsIf Variant = ScriptExpression Then
		CheckedAttributes.Add("ComputedExpression");
		
	EndIf;
	
EndProcedure

#EndRegion