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
	Parameters.Property("PlaceWhereExpressionIsExecuted", PlaceWhereExpressionIsExecuted);
	Parameters.Property("ShouldUpdate", ShouldUpdate);
	Parameters.Property("UpdateParent", UpdateParent);
	Parameters.Property("DependentItem", DependentItem);
	Parameters.Property("IsAdditionalAttributeDM", IsAdditionalAttributeDM);
	Parameters.Property("AdditionalAttributeDMID", AdditionalAttributeDMID);
	Parameters.Property("AdditionalAttributeDMType", AdditionalAttributeDMType);
	Parameters.Property("IsAdditionalAttributeIS", IsAdditionalAttributeIS);
	Parameters.Property("AdditionalAttributeIS", AdditionalAttributeIS);
	Parameters.Property("Table", Table);
	
	If Parameters.Property("ToolTip") And ValueIsFilled(Parameters.ToolTip) Then
		Items.ObjectAttributePresentationIS.ToolTip = Parameters.ToolTip;
		Items.ObjectAttributePresentationIS.ToolTipRepresentation = ToolTipRepresentation.Button;
	EndIf;
	
	ObjectAttribute = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute");
	SpecifiedValue = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue");
	ScriptExpression =
		PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ScriptExpression");
	DontFill = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.EmptyRef");
	
	If DependentItem Then
		ShouldUpdate = UpdateParent And (Variant <> DontFill);
		Items.ShouldUpdate.Title = NStr("vi = 'cập nhật (tùy chỉnh cho toàn bộ bảng)';
										|ru = 'обновлять (настраивается для всей таблицы)';
										|en = 'update (configured for the entire table)'; fa = 'update (configured for the entire table)';
										|it = 'update (configured for the entire table)';
										|pl = 'update (configured for the entire table)';
										|tr = 'güncelleme (tüm tablo için ayarlanabilir)'");
	EndIf;
	
	AttributeValueIS = ObjectAttributeTypeIS.AdjustValue(AttributeValueIS);
	
	IntegrationWith1CDocumentManagementCoreClientServer.ConfigureInputFieldByType(
		Items.AttributeValueIS,
		ObjectAttributeTypeIS);
	
	YouCanFillInFromAttributesDM = True;
	For Each AttributeType In ObjectAttributeTypeIS.Types() Do
		If AttributeType = Type("String")
				Or AttributeType = Type("Number")
				Or AttributeType = Type("Date")
				Or AttributeType = Type("Boolean") Then
			// Primitive types can be filled from the Attributes TO.
			Continue;
		EndIf;
		If Not Common.IsReference(AttributeType) Then
			// Other non-reference types cannot be filled in from the Attributes BEFORE.
			YouCanFillInFromAttributesDM = False;
			Break;
		EndIf;
		AttributeMetadata = Metadata.FindByType(AttributeType);
		If Not Common.IsCatalog(AttributeMetadata)
				And Not Common.IsEnum(AttributeMetadata) Then
			// You can use the DO Attribute to select only an element of the Catalog or enumeration.
			YouCanFillInFromAttributesDM = False;
			Break;
		EndIf;
	EndDo;
	If YouCanFillInFromAttributesDM = False Then
		Items.Variant.ChoiceList.Delete(Items.Variant.ChoiceList.FindByValue(ObjectAttribute));
		Items.ObjectAttributePresentationDM.Visible = False;
	EndIf;
	
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
	
	Items.ModeOfChangingTheDataOfThePostedDocument.Visible = Parameters.FillingInDocument;
	If Parameters.FillingInDocument Then
		Parameters.Property("ModeOfChangingTheDataOfThePostedDocument", ModeOfChangingTheDataOfThePostedDocument);
		If Not ValueIsFilled(ModeOfChangingTheDataOfThePostedDocument) Then
			ModeOfChangingTheDataOfThePostedDocument =
				Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
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
	
	If PlaceWhereExpressionIsExecuted = Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnDocumentManagementSide Then
		Items.ComputedExpression.ToolTip =
			NStr("vi = 'Biểu thức sẽ được thực hiện trong cơ sở của 1C:Document Management';
				|ru = 'Выражение будет выполняться в базе 1С:Документооборот';
				|en = 'The expression will be executed in 1C:Document Management'; fa = 'The expression will be executed in 1C:Document Management';
				|it = 'Выражение будет выполняться в базе 1С:Документооборот';
				|pl = 'The expression will be executed in 1C:Document Management';
				|tr = 'İfade, 1C:Document Management tabanında yürütülecektir'");
	Else
		Items.ComputedExpression.ToolTip =
			StrTemplate(NStr("vi = 'Biểu thức sẽ được thực hiện trong cơ sở %1';
							|ru = 'Выражение будет выполняться в базе %1';
							|en = 'The expression will be executed in %1'; fa = 'The expression will be executed in %1';
							|it = 'Выражение будет выполняться в базе %1';
							|pl = 'The expression will be executed in %1';
							|tr = 'İfade, %1 tabanında yürütülecektir'"), AbbreviatedNameOfConfiguration);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetAvailability();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure VariantOnChange(Item)
	
	If DependentItem Then
		ShouldUpdate = UpdateParent And (Variant <> DontFill);
	Else
		ShouldUpdate =
			(ShouldUpdate Or Variant = ObjectAttribute)
				And (Variant <> DontFill)
				And (Variant <> SpecifiedValue);
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
	Result.Insert("PlaceWhereExpressionIsExecuted");
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
		Result.PlaceWhereExpressionIsExecuted = ?(ValueIsFilled(PlaceWhereExpressionIsExecuted),
			PlaceWhereExpressionIsExecuted,
			PredefinedValue("Enum.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnIntegratedSystemSide"));
		Result.Picture = 3;
		
	EndIf;
	
	Result.Insert("Variant", Variant);
	Result.Insert("ShouldUpdate", ShouldUpdate);
	Result.Insert("IsAdditionalAttributeDM", IsAdditionalAttributeDM);
	Result.Insert("AdditionalAttributeDMID", AdditionalAttributeDMID);
	Result.Insert("AdditionalAttributeDMType", AdditionalAttributeDMType);
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
	FormParameters.Insert("PlaceWhereExpressionIsExecuted", PlaceWhereExpressionIsExecuted);
	FormParameters.Insert("ObjectTypeDM", ObjectTypeDM);
	FormParameters.Insert("ObjectTypeIS", ObjectTypeIS);
	FormParameters.Insert("ThisIsTable", False);
	FormParameters.Insert("Table", Table);
	FormParameters.Insert("DocumentKindDM", DocumentKindDM);
	FormParameters.Insert("CurCurrentLineIsAvailable", (DependentItem And Table <> ""));
	
	CallbackDescription = New CallbackDescription("SelectCalculatedExpressionCompletion", ThisObject);
	
	OpenForm(
		"Catalog.RulesForIntegrationWith1CDocumentManagement3.Form.ScriptExpression",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure SelectCalculatedExpressionCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ComputedExpression = Result.ComputedExpression;
		PlaceWhereExpressionIsExecuted = Result.PlaceWhereExpressionIsExecuted;
		
		If PlaceWhereExpressionIsExecuted =
				PredefinedValue("Enum.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnDocumentManagementSide") Then
			Items.ComputedExpression.ToolTip =
				NStr("vi = 'Biểu thức sẽ được thực hiện trong cơ sở của 1C:Document Management';
					|ru = 'Выражение будет выполняться в базе 1С:Документооборот';
					|en = 'The expression will be executed in 1C:Document Management'; fa = 'The expression will be executed in 1C:Document Management';
					|it = 'Выражение будет выполняться в базе 1С:Документооборот';
					|pl = 'The expression will be executed in 1C:Document Management';
					|tr = 'İfade, 1C:Document Management tabanında yürütülecektir'");
		Else
			Items.ComputedExpression.ToolTip =
				StrTemplate(NStr("vi = 'Biểu thức sẽ được thực hiện trong cơ sở %1';
								|ru = 'Выражение будет выполняться в базе %1';
								|en = 'The expression will be executed in %1'; fa = 'The expression will be executed in %1';
								|it = 'Выражение будет выполняться в базе %1';
								|pl = 'The expression will be executed in %1';
								|tr = 'İfade, %1 tabanında yürütülecektir'"), AbbreviatedNameOfConfiguration);
		EndIf;
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
	
	Items.ShouldUpdate.Enabled = (Variant <> SpecifiedValue) And (Variant <> DontFill) And Not DependentItem;
	Items.ModeOfChangingTheDataOfThePostedDocument.Enabled = Items.ShouldUpdate.Enabled;
	
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