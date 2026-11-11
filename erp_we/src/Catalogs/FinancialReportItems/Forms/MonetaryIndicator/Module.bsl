
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisObject);
	
	ThisIsRemainder = StrFind(TotalType,"Balance_")> 0;
	Items.PeriodBoundary.Visible = ThisIsRemainder;
	CurrentTotalKind = ThisIsRemainder;
	If GLAccount_ <> Undefined Then
		AccountAttributes = New Structure;
		AccountAttributes.Insert("NameOfAccount", "Description");
		If TypeOf(GLAccount_) = FinancialAccountingClientServer.TypeChartOfAccounts() Then
			AccountAttributes.Insert("FinancialAccountingChartOfAccounts", "ChartOfAccounts");
		EndIf;
		AttributesValues = Common.ObjectAttributesValues(GLAccount_, AccountAttributes);
		FillPropertyValues(ThisObject, AttributesValues);
		Items.GLAccount_.TypeRestriction = FinancialReportingServer.TypeDescriptionByValue(GLAccount_);
	EndIf;
	Items.GroupAddAttributes.Visible = Parameters.ShowRowCodeNote;
	Items.ReverseSign.Visible = Parameters.ShowRowCodeNote;
	Items.SelectItem.Visible = Parameters.ShowRowCodeNote;
	RefreshFormTitle();

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisObject, CurrentObject, Cancel);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	RefreshFormTitle();
	
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
Procedure NameForPrintingOnChange(Item)
	
	Object.Description = Object.NameForPrinting;
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure TotalTypeOnChange(Item)
	
	ThisIsRemainder = StrFind(Item.EditText,"Balance_")> 0;
	Items.PeriodBoundary.Visible = ThisIsRemainder;
	If CurrentTotalKind <> ThisIsRemainder Then
		ConfigureSelectionField();
	EndIf;
	CurrentTotalKind = ThisIsRemainder;
	
EndProcedure

&AtClient
Procedure GLAccount_OnChange(Item)
	
	GLAccount_OnChangeServer();
	
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

#Region OnChangeAttributes

&AtServer
Procedure GLAccount_OnChangeServer()
	
	// By default, we fill in the name 
	// for printing by the name of the account until the user enters his name for printing.
	NewAccountName = Common.ObjectAttributeValue(GLAccount_, "Description");
	If Not ValueIsFilled(Object.NameForPrinting)
		Or Object.NameForPrinting = NameOfAccount Then
		Object.NameForPrinting = NewAccountName;
	EndIf;
	Object.Description = Object.NameForPrinting;
	NameOfAccount = NewAccountName;
	ConfigureSelectionField();
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure RefreshFormTitle()
	
	TypePresentation = NStr("vi = 'Chỉ tiêu tiền tệ';
							|ru = 'Монетарный показатель';
							|en = 'Monetary indicator'; fa = 'شاخص پولی';
							|it = 'Indicatore monetario';
							|pl = 'Wskaźnik monetarny';
							|tr = 'Nakdi gösterge'");
	If TypeOf(GLAccount_) = FinancialAccountingClientServer.TypeChartOfAccounts() Then
		TypePresentation = NStr("vi = 'Chỉ tiêu tiền tệ phát sinh';
								|ru = 'Монетарный показатель международный';
								|en = 'International monetary indicator'; fa = 'International monetary indicator';
								|it = 'Indicatore monetario internazionale';
								|pl = 'Wskaźnik monetarny międzynarodowy';
								|tr = 'Uluslararası nakdi gösterge'");
	ElsIf TypeOf(GLAccount_) = LocalAccntingClientServer.TypeChartOfAccounts() Then
		TypePresentation = NStr("vi = 'Chỉ tiêu tiền tệ được điều chỉnh';
								|ru = 'Монетарный показатель регламентированный';
								|en = 'Local monetary indicator'; fa = 'Local monetary indicator';
								|it = 'Indicatore monetario regolamentato';
								|pl = 'Wskaźnik monetarny reglamentowany';
								|tr = 'Yerel nakdi gösterge'");
	EndIf;
	If Not ValueIsFilled(Object.NameForPrinting) Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (tạo mới)';
				|ru = '%1 (создание)';
				|en = '%1 (Create)'; fa = '%1 (Create)';
				|it = '%1 (creazione)';
				|pl = '%1 (utworzenie)';
				|tr = '%1 (oluşturma)'"),
			TypePresentation);
	Else
		Title = Object.NameForPrinting + " (" + TypePresentation + ")";
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureSelectionField()
	
	Catalogs.FinancialReportItems.SetFilterSettings(ThisObject,
	                                                                Composer,
	                                                                Object.ItemKind,
	                                                                Composer.Settings);
	
EndProcedure

#EndRegion

#EndRegion
