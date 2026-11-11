#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	CheckWhetherRuleCanBeRecorded();
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Catalogs.RulesForIntegrationWith1CDocumentManagement3.RefreshPresentation(ThisObject);
	
	For Each String In AttributeFillingRulesIS Do
		If Not ValueIsFilled(String.id) Then
			String.id = String(New UUID);
		EndIf;
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	RefreshReusableValues();
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	ApplicabilityConditionOnExport = "Parameters.Result = True;";
	ApplicabilityConditionOnImport = "Parameters.Result = True;";
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckWhetherRuleCanBeRecorded()
	
	If Users.IsFullUser() Then
		Return;
	EndIf;
	
	ExpressionTemplates =
		IntegrationWith1CDocumentManagementCoreServerCall.ExpressionTemplatesInEmbeddedLanguage();
	
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
	
	If ListOfExpressionsForFillingInIPAttributes.Count() = 0 Then
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
	
	OldRulesForFillingInIPAttributes =
		Common.ObjectAttributeValue(Ref, "AttributeFillingRulesIS").Unload();
	
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