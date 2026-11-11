
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisObject);
	MainStorageID = Parameters.MainStorageID;
	
	If Parameters.Property("ArbitraryIndicator") Then
		Title = NStr("vi = 'Toán hạng: %1 %2';
					|ru = 'Операнд: %1 %2';
					|en = 'Operand: %1 %2'; fa = 'Operand: %1 %2';
					|it = 'Operando:%1%2';
					|pl = 'Operand: %1 %2';
					|tr = 'İşlenen: %1 %2'");
	Else
		Title = "%1 %2";
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(Title,
		String(Parameters.ItemKind),
		String(NonFinancialItem));

	Items.SettingThePeriodOffset.Title = BudgetReportingClientServer.OffsetPresentation(ThisObject);
	
	ObjectAttributes = Common.ObjectAttributesValues(NonFinancialItem, "ByCompanies, ByBusinessUnits, ByScenarios");
	If Not ObjectAttributes.ByCompanies Then
		Items.UseTheFilterByOrganization.Visible = False;
	EndIf;
	If Not ObjectAttributes.ByBusinessUnits Then
		Items.UseTheDefaultFilterDepartment.Visible = False;
	EndIf;
	If Not ObjectAttributes.ByScenarios Then
		Items.UseTheDefaultFilterScenario.Visible = False;
	EndIf;
	
	PrivilegedModeRadioButton = Number(PrivilegedMode);
	
	FormControl(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisObject, CurrentObject, Cancel);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_NonFinancialItemsOfBudgets" Then
		If ValueIsFilled(Object.Ref) Then
			Read();
		Else
			Object.NameForPrinting = Parameter;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure SettingThePeriodOffsetClick(Item)
	
	CallbackDescription = New CallbackDescription("SetOffsetPeriod", ThisObject);
	OffsetParameters = BudgetReportingClientServer.ParametersForOpeningPeriodSettingsForm(ThisObject);
	OffsetParameters.Insert("NonFinancialItem", True);
	
	OpenForm("Catalog.FinancialReportItems.Form.SetUpDataSourcePeriod",
		OffsetParameters,,,,,CallbackDescription);
	
EndProcedure

&AtClient
Procedure NotUseAFilterOnChange(Item)
	
	InstallSelectionOnServer();
	
EndProcedure

&AtClient
Procedure PrivilegedModeRadioButtonOnChange(Item)
	
	PrivilegedMode = Boolean(PrivilegedModeRadioButton);
	
EndProcedure

&AtClient
Procedure PresentationExpressionStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	BudgetReportingClient.ChangingExpressionOfSortingViewInFormulaEditor(ThisObject,
		"PresentationExpression", Object.NameForPrinting);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	FinancialReportingClient.FinishEditingReportElement(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Form.Items.PresentationExpression.Visible = ValueIsFilled(Form.NonFinancialItem);
	
	Form.Items.NameForPrinting.Enabled = IsBlankString(Form.PresentationExpression);
	
EndProcedure

&AtClient
Procedure SetOffsetPeriod(Result, AdditionalParameters) Export
	
	BudgetReportingClient.SetOffsetPeriod(Object, ThisObject, Result);
	
EndProcedure

&AtServer
Procedure InstallSelectionOnServer()
	
	Catalogs.FinancialReportItems.SetFilterSettings(ThisObject,
		Composer,
		Object.ItemKind,
		Composer.Settings);
	
EndProcedure

#EndRegion

