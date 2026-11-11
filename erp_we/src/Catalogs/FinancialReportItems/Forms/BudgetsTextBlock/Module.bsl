
#Region FormEventHandlers

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisForm);
	Title = Parameters.ItemKind;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	Items.OnlyForPrinting.Visible = Parameters.Property("UseToEnterPlan") 
		And Parameters.UseToEnterPlan;
	
	SubstitutionParameters = GetReportSubstitutionParameters();
	AddSubstitutionParameterCommands(SubstitutionParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisForm, CurrentObject, Cancel);
	
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
Procedure TextBlockOnChange(Item)
	
	Object.NameForPrinting = TrimAll(StrGetLine(Text, 1));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	AdditionalProperties = New Structure("PresentationIsForPrintingOnly");
	If OnlyForPrinting = 1 Then
		PresentationIsForPrintingOnly = NStr("vi = 'Không hiển thị khi điền ngân sách';
											|ru = 'Не выводится при заполнении бюджета';
											|en = 'Not displayed while populating the budget'; fa = 'Not displayed while populating the budget';
											|it = 'Не выводится при заполнении бюджета';
											|pl = 'Nie jest pokazywany podczas wypełniania budżetu';
											|tr = 'Bütçenin doldurulması durumunda gösterme'");
	ElsIf OnlyForPrinting = 2 Then
		PresentationIsForPrintingOnly = NStr("vi = 'Chỉ hiển thị khi điền ngân sách';
											|ru = 'Выводится только при заполнении бюджета';
											|en = 'Displayed only when filling budget'; fa = 'Displayed only when filling budget';
											|it = 'Выводится только при заполнении бюджета';
											|pl = 'Displayed only when filling budget';
											|tr = 'Sadece bütçe doldurulduğunda görüntülenir'");
	Else
		PresentationIsForPrintingOnly = "";
	EndIf;
	
	AdditionalProperties.PresentationIsForPrintingOnly = PresentationIsForPrintingOnly;
	
	FinancialReportingClient.FinishEditingReportElement(ThisForm, AdditionalProperties);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddSubstitutionParameterCommands(SubstitutionParameters)
	
	NameOfCommandAction = "Attachable_AddSubstitutionTemplate";
	
	For Each ParameterNameAndPresentation In SubstitutionParameters Do
		
		FormCommand = ThisForm.Commands.Add(ParameterNameAndPresentation.Name);
		FormCommand.Action = NameOfCommandAction;
		
		NewFormButton = Items.Add(ParameterNameAndPresentation.Name, Type("FormButton"), Items.AddParameter);
		NewFormButton.CommandName = ParameterNameAndPresentation.Name;
		NewFormButton.Title = ParameterNameAndPresentation.Presentation;
		
	EndDo;
	
EndProcedure

&AtServer
Function GetReportSubstitutionParameters()
	
	ParametersArray = SubstitutionParametersByBudgetType();
	
	Return ParametersArray;
	
EndFunction

&AtServer
Function SubstitutionParametersByBudgetType()
	
	ParametersArray = New Array;
	
	OrderedVariables = BudgetReportingClientServer.OrderedVariablesOfBudgetReports();
	
	BudgetsByCompanies = False;
	BudgetsByBusinessUnits = False;
	BudgetingModel = Parameters.BudgetingModel;
	
	If ValueIsFilled(BudgetingModel) Then
		DetailsOfBudgetingModel = Common.ObjectAttributesValues(Parameters.BudgetingModel,
			New Structure("BudgetsByCompanies,BudgetsByBusinessUnits"));
			
		If DetailsOfBudgetingModel.BudgetsByCompanies Then
			BudgetsByCompanies = True;
		EndIf;
		
		If DetailsOfBudgetingModel.BudgetsByBusinessUnits Then
			BudgetsByBusinessUnits = True;
		EndIf;
	EndIf;
	
	UseToEnterPlan = Parameters.Property("UseToEnterPlan") And Parameters.UseToEnterPlan;
	
	For Each NameAndPresentation In OrderedVariables Do
		If NameAndPresentation.Name = "Organization"
		   And Not BudgetsByCompanies Then
			Continue;
		EndIf;
		If NameAndPresentation.Name = "Department"
		   And Not BudgetsByBusinessUnits Then
			Continue;
		EndIf;
		If Not UseToEnterPlan
			And (NameAndPresentation.Name = "DocumentStatus"
			Or NameAndPresentation.Name = "Approving"
			Or NameAndPresentation.Name = "EmployeeResponsible") Then
			
			Continue;
		EndIf;
		
		ParametersArray.Add(NameAndPresentation);
	EndDo;
	
	If Parameters.Property("AddressOfTheAnalyticsList") Then
		HeaderAnalystTable = GetFromTempStorage(Parameters.AddressOfTheAnalyticsList);
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	HeaderAnalystTable.LineNumber AS LineNumber,
		|	HeaderAnalystTable.DimensionKind AS DimensionKind
		|INTO HeaderDimensions
		|FROM
		|	&HeaderAnalystTable AS HeaderAnalystTable
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	HeaderDimensions.LineNumber AS LineNumber,
		|	HeaderDimensions.DimensionKind AS DimensionKind,
		|	BudgetFlowItemDimensions.Id AS Id,
		|	BudgetFlowItemDimensions.Presentation AS Presentation
		|FROM
		|	HeaderDimensions AS HeaderDimensions
		|		LEFT JOIN ChartOfCharacteristicTypes.BudgetFlowItemDimensions AS BudgetFlowItemDimensions
		|		ON HeaderDimensions.DimensionKind = BudgetFlowItemDimensions.Ref
		|ORDER BY
		|	LineNumber";
		Query.SetParameter("HeaderAnalystTable", HeaderAnalystTable);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			NameAndPresentation = New Structure;
			NameAndPresentation.Insert("Name", Selection.Id);
			NameAndPresentation.Insert("Presentation", Selection.Presentation);
			
			ParametersArray.Add(NameAndPresentation);
		EndDo;
	EndIf;
	
	Return ParametersArray;
	
EndFunction


// The command to connect. Adds a wildcard template.
// 
// Parameters:
// 	Command - FormCommand -
&AtClient
Procedure Attachable_AddSubstitutionTemplate(Command)
	 
	InsertTextInTitle("["+ Command.Name +"]");
	
EndProcedure

&AtClient
Procedure InsertTextInTitle(TextForInsert, Move = 0)
	
	RowStart = 0;
	RowEnd = 0;
	ColumnStart = 0;
	ColumnEnd = 0;
	
	Items.TextBlock.GetTextSelectionBounds(RowStart, ColumnStart, RowEnd, ColumnEnd);
	
	If (ColumnEnd = ColumnStart) And (ColumnEnd + StrLen(TextForInsert)) > Items.TextBlock.Width / 8 Then
		Items.TextBlock.SelectedText = "";
	EndIf;
	
	Items.TextBlock.SelectedText = TextForInsert;
	
	If Not Move = 0 Then
		Items.TextBlock.GetTextSelectionBounds(RowStart, ColumnStart, RowEnd, ColumnEnd);
		Items.TextBlock.SetTextSelectionBounds(RowStart, ColumnStart - Move, RowEnd, ColumnEnd - Move);
	EndIf;
	CurrentItem = Items.TextBlock;
	
EndProcedure

#EndRegion

