#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	TypeOfSavedPrintedFormFile =
		IntegrationWith1CDocumentManagementCore.DefaultFileTypeOfSavedPrintedForm();
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	CheckWhetherRuleCanBeRecorded();
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ExportChanges = False;
	ImportChanges = False;
	
	RefreshPresentation();
	
	// We will set the auto-update flags if necessary.
	
	If ValueIsFilled(ObjectTypeIS) Then
		
		ConsumerObject = Metadata.FindByFullName(ObjectTypeIS);
		If ConsumerObject <> Undefined Then
			
			If Metadata.ExchangePlans.IntegrationWith1CDocumentManagementSubsystemOverridable.Content.Contains(ConsumerObject) Then
				TheStructureOfTheSearch = New Structure("ShouldUpdate", True);
				UpdatedBankingDetails = AttributeFillingRulesDM.FindRows(TheStructureOfTheSearch);
				UpdatedPrintingForms = AttachedPrintedForms.FindRows(TheStructureOfTheSearch);
				ExportChanges = (UpdatedBankingDetails.Count() <> 0
					Or UpdatedPrintingForms.Count() <> 0);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(ObjectTypeDM) Then
		
		TheStructureOfTheSearch = New Structure("ShouldUpdate", True);
		UpdatedBankingDetails = AttributeFillingRulesIS.FindRows(TheStructureOfTheSearch);
		ImportChanges = (UpdatedBankingDetails.Count() <> 0);
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	RefreshReusableValues();
	
EndProcedure

#EndRegion

#Region Private

// Updates the rule representation according to the representations of objects and key details.
//
Procedure RefreshPresentation()
	
	// Let's assemble a representation of the IP object.
	ObjectPresentationIS = "";
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDefiningPresentationOfConsumerObject(
		ThisObject,
		ObjectPresentationIS);
	
	If ObjectPresentationIS = "" And ValueIsFilled(ObjectTypeIS) Then
		
		ConsumerObject = Metadata.FindByFullName(ObjectTypeIS);
		If ConsumerObject <> Undefined Then
			
			ObjectPresentationIS = ?(ConsumerObject.Synonym = "",
				ConsumerObject.Name,
				ConsumerObject.Synonym);
			
			// Let's add the key details to the presentation.
			TheStructureOfTheSearch = New Structure("KeyAttribute_", True);
			KeyAttributes = AttributeFillingRulesIS.FindRows(TheStructureOfTheSearch);
			For Each KeyAttribute In KeyAttributes Do
				If KeyAttribute.Variant = Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue Then
					ObjectPresentationIS = ObjectPresentationIS + ", " + String(KeyAttribute.AttributeValueIS);
				EndIf;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	ObjectPresentationDM = "";
	
	If ValueIsFilled(ObjectTypeDM) Then
		
		ObjectPresentationDM = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(ObjectTypeDM);
		
		// Let's add the key details to the presentation.
		TheStructureOfTheSearch = New Structure("KeyAttribute_", True);
		KeyAttributes = AttributeFillingRulesDM.FindRows(TheStructureOfTheSearch);
		For Each KeyAttribute In KeyAttributes Do
			If KeyAttribute.Variant = Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue Then
				ObjectPresentationDM = ObjectPresentationDM + ", " + String(KeyAttribute.AttributeValueDM);
			ElsIf KeyAttribute.Variant = Enums.VariantsOfTheRulesForFillingInAttributes.FromTemplate Then
				ObjectPresentationDM = ObjectPresentationDM + ", " + String(KeyAttribute.TemplateMeaning);
			EndIf;
		EndDo;
		
	EndIf;
	
	// Let's collect the name.
	If ValueIsFilled(ObjectPresentationIS) And ValueIsFilled(ObjectPresentationDM) Then
		Description = ObjectPresentationIS + " - " + ObjectPresentationDM;
	Else
		Description = "";
	EndIf;
	
EndProcedure

Procedure CheckWhetherRuleCanBeRecorded()
	
	If Users.IsFullUser() Then
		Return;
	EndIf;
	
	ExpressionTemplates =
		IntegrationWith1CDocumentManagementCoreServerCall.ExpressionTemplatesInEmbeddedLanguage();
	
	ListOfExpressionsToFillInAttributesDM = New Map;
	For Each String In AttributeFillingRulesDM Do
		If ValueIsFilled(String.ComputedExpression) Then
			IsTemplate1 = False;
			For Each ExpressionPattern In ExpressionTemplates Do
				If ExpressionPattern.Value = String.ComputedExpression Then
					IsTemplate1 = True;
					Break;
				EndIf;
			EndDo;
			If IsTemplate1 Then
				Continue;
			EndIf;
			Var_Key = New Structure("AttributeNameObjectDM, ThisIsTable, Table");
			FillPropertyValues(Var_Key, String);
			ListOfExpressionsToFillInAttributesDM.Insert(Var_Key, String.ComputedExpression);
		EndIf;
	EndDo;
	
	ListOfExpressionsForFillingInIPAttributes = New Map;
	For Each String In AttributeFillingRulesIS Do
		If ValueIsFilled(String.ComputedExpression) Then
			IsTemplate1 = False;
			For Each ExpressionPattern In ExpressionTemplates Do
				If ExpressionPattern.Value = String.ComputedExpression Then
					IsTemplate1 = True;
					Break;
				EndIf;
			EndDo;
			If IsTemplate1 Then
				Continue;
			EndIf;
			Var_Key = New Structure("AttributeNameObjectIS, ThisIsTable, Table");
			FillPropertyValues(Var_Key, String);
			ListOfExpressionsForFillingInIPAttributes.Insert(Var_Key, String.ComputedExpression);
		EndIf;
	EndDo;
	
	If ListOfExpressionsToFillInAttributesDM.Count() = 0
			And ListOfExpressionsForFillingInIPAttributes.Count() = 0 Then
		Return;
	EndIf;
	
	If IsNew() Then
		Raise NStr("vi = 'Trong quy tắc tích hợp với 1C:Document Management cấm thay đổi biểu thức bằng ngôn ngữ hệ thống.
			|Hãy liên hệ với người quản trị.';
			|ru = 'В правилах интеграции с 1С:Документооборотом запрещено изменять выражения на встроенном языке.
			|Обратитесь к администратору.';
			|en = 'You cannot change expressions in 1C:Enterprise language in the rules of integration with 1C:Document Management.
			|Contact the administrator.'; fa = 'You cannot change expressions in 1C:Enterprise language in the rules of integration with 1C:Document Management.
			|Contact the administrator.';
			|it = 'В правилах интеграции с 1С:Документооборотом запрещено изменять выражения на встроенном языке.
			|Обратитесь к администратору.';
			|pl = 'You cannot change expressions in 1C:Enterprise language in the rules of integration with 1C:Document Management.
			|Contact the administrator.';
			|tr = '1C:Document Management ile entegrasyon kurallarında yerleşik dildeki ifadelerin değiştirilmesi yasaktır. 
			|Yöneticiniz ile iletişime geçin.'");
	EndIf;
	
	PreviousValues1 = Common.ObjectAttributesValues(Ref,
		"AttributeFillingRulesDM, AttributeFillingRulesIS");
	OldRulesForFillingInAttributesDM = PreviousValues1.AttributeFillingRulesDM.Unload();
	OldRulesForFillingInIPAttributes = PreviousValues1.AttributeFillingRulesIS.Unload();
	
	For Each CurrentExpression In ListOfExpressionsToFillInAttributesDM Do
		Rows = OldRulesForFillingInAttributesDM.FindRows(CurrentExpression.Key);
		If Rows.Count() = 1 And Rows[0].ComputedExpression = CurrentExpression.Value Then
			Continue;
		EndIf;
		Raise NStr("vi = 'Trong quy tắc tích hợp với 1C:Document Management cấm thay đổi biểu thức bằng ngôn ngữ hệ thống.
			|Hãy liên hệ với người quản trị.';
			|ru = 'В правилах интеграции с 1С:Документооборотом запрещено изменять выражения на встроенном языке.
			|Обратитесь к администратору.';
			|en = 'You cannot change expressions in 1C:Enterprise language in the rules of integration with 1C:Document Management.
			|Contact the administrator.'; fa = 'You cannot change expressions in 1C:Enterprise language in the rules of integration with 1C:Document Management.
			|Contact the administrator.';
			|it = 'В правилах интеграции с 1С:Документооборотом запрещено изменять выражения на встроенном языке.
			|Обратитесь к администратору.';
			|pl = 'You cannot change expressions in 1C:Enterprise language in the rules of integration with 1C:Document Management.
			|Contact the administrator.';
			|tr = '1C:Document Management ile entegrasyon kurallarında yerleşik dildeki ifadelerin değiştirilmesi yasaktır. 
			|Yöneticiniz ile iletişime geçin.'");
	EndDo;
	
	For Each CurrentExpression In ListOfExpressionsForFillingInIPAttributes Do
		Rows = OldRulesForFillingInIPAttributes.FindRows(CurrentExpression.Key);
		If Rows.Count() = 1 And Rows[0].ComputedExpression = CurrentExpression.Value Then
			Continue;
		EndIf;
		Raise NStr("vi = 'Trong quy tắc tích hợp với 1C:Document Management cấm thay đổi biểu thức bằng ngôn ngữ hệ thống.
			|Hãy liên hệ với người quản trị.';
			|ru = 'В правилах интеграции с 1С:Документооборотом запрещено изменять выражения на встроенном языке.
			|Обратитесь к администратору.';
			|en = 'You cannot change expressions in 1C:Enterprise language in the rules of integration with 1C:Document Management.
			|Contact the administrator.'; fa = 'You cannot change expressions in 1C:Enterprise language in the rules of integration with 1C:Document Management.
			|Contact the administrator.';
			|it = 'В правилах интеграции с 1С:Документооборотом запрещено изменять выражения на встроенном языке.
			|Обратитесь к администратору.';
			|pl = 'You cannot change expressions in 1C:Enterprise language in the rules of integration with 1C:Document Management.
			|Contact the administrator.';
			|tr = '1C:Document Management ile entegrasyon kurallarında yerleşik dildeki ifadelerin değiştirilmesi yasaktır. 
			|Yöneticiniz ile iletişime geçin.'");
	EndDo;
	
EndProcedure

#EndRegion

#EndIf