
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Ref = Parameters.Ref;
	ReferenceOrder = Parameters.ReferenceOrder;
	Items.ResultDate.EditFormat = Parameters.ScheduleDateFormat;
	
	If ValueIsFilled(Parameters.PlanNotEarlierThan) Then
		
		If TypeOf(Parameters.PlanNotEarlierThan) = Type("Date") Then
			
			Mode = DateMode();
			ResultDate = Parameters.PlanNotEarlierThan;
			
		Else
			
			Mode = StageMode();
			ResultStage = Parameters.PlanNotEarlierThan;
			ResultStagePresentation = PresentationStage(ResultStage);
			
		EndIf;
		
	EndIf;
	
	AvailabilityControl(ThisForm);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	CommonClient.ShowFormClosingConfirmation(
		New CallbackDescription("BeforeClosingApplyAndClose", ThisObject),
		Cancel,
		Exit,
		NStr("vi = 'Dữ liệu đã được thay đổi. Áp dụng thay đổi?';
			|ru = 'Данные были изменены. Применить изменения?';
			|en = 'Data has changed. Apply changes?'; fa = 'Data has changed. Apply changes?';
			|it = 'I dati sono stati modificati. Applicare le modifiche?';
			|pl = 'Dane zostały zmienione. Zapisać zmiany?';
			|tr = 'Veriler değiştirildi. Değişiklikler uygulansın mı?'"));
	
EndProcedure

&AtClient
Procedure BeforeClosingApplyAndClose(QuestionResult, AdditionalParameters) Export
	
	MoveChangesToADocument();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Mode = DateMode() Then
		NotCheckedAttributeArray.Add("ResultStagePresentation");
	Else
		NotCheckedAttributeArray.Add("ResultDate");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)
	
	MoveChangesToADocument();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Modified = False;
	Close();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ModeOnChange(Item)
	
	If Mode = DateMode() Then
		ClearResult(ThisForm);
	Else
		ResultDate = Undefined;
	EndIf;
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClient
Procedure ResultStagePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Filter = New Structure;
	Filter.Insert("DeletionMark", False);
	
	If ResultStage.IsEmpty()
		Or StageOrder(ResultStage) = ReferenceOrder Then
		Filter.Insert("ReferenceOrder", ReferenceOrder);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentRow", ResultStage);
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("ExcludeLink", Ref);
	
	OpenForm(
		"Document.ProductionStage2_2.ChoiceForm",
		FormParameters,
		ThisForm,,,,
		New CallbackDescription("StageSelectionCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure StageSelectionCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		
		ResultStage = ClosingResult;
		ResultStagePresentation = PresentationStage(ResultStage);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ResultStagePresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ClearResult(ThisForm);
	
EndProcedure

&AtClient
Procedure ResultStagePresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(ResultStage) Then
		ShowValue(, ResultStage);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ResultDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Mode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = StageMode();
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ResultStagePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Mode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = DateMode();
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	Form.Items.ResultDate.Enabled = (Form.Mode = DateMode());
	Form.Items.ResultStagePresentation.Enabled = (Form.Mode = StageMode());
	
EndProcedure

&AtClientAtServerNoContext
Function DateMode()
	
	Return 0;
	
EndFunction

&AtClientAtServerNoContext
Function StageMode()
	
	Return 1;
	
EndFunction

&AtClient
Procedure MoveChangesToADocument()
	
	If CheckFilling() Then
		
		If Mode = DateMode() Then
			Result = ResultDate;
		Else
			Result = ResultStage;
		EndIf;
		
		Modified = False;
		Close(Result);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function PresentationStage(Stage)
	
	Return Documents.ProductionStage2_2.PresentationStage(Stage);
	
EndFunction

&AtServerNoContext
Function StageOrder(Stage)
	
	Return Common.ObjectAttributeValue(Stage, "ReferenceOrder");
	
EndFunction

&AtClientAtServerNoContext
Procedure ClearResult(Form)
	
	Form.ResultStage = Undefined;
	Form.ResultStagePresentation = "";
	
	Form.Modified = True;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
