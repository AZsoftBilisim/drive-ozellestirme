#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FillPropertyValues(Object, Parameters);
	BusinessOperation = Parameters.BusinessOperation;
	Object.PaymentScheduleSteps.Clear();
	CalledFormID = Parameters.UUID;
	FillInPaymentStagesFromTemporaryStorageServer(Parameters.AddressInTempStorage);
	CalculateTotalsOfAgreementWithClient(ThisForm);
	ThisForm.ReadOnly = Parameters.ReadOnly;
	
	If ValueIsFilled(Object.Calendar) Then 
		DeferredPaymentMode = 1;
	Else
		Items.Calendar.Enabled = False;
	EndIf;
	Items.FormOK.Visible = Object.Status <> Enums.PlanStatuses.Upholded;
	Items.GroupStatusApproved.Visible = Object.Status = Enums.PlanStatuses.Upholded;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If Not ClosingInProgress Then
		
		StandardProcessing = False;
		
		If Modified And Not Done Then
			
			ButtonsList = New ValueList();
			ButtonsList.Add("Close", NStr("vi = 'Đóng';
											|ru = 'Закрыть';
											|en = 'Close'; fa = 'بستن';
											|it = 'Chiudere';
											|pl = 'Zamknij';
											|tr = 'Kapat'"));
			ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
											|ru = 'Не закрывать';
											|en = 'Do not close'; fa = 'بسته نشود';
											|it = 'Non chiudere';
											|pl = 'Nie zamykaj';
											|tr = 'Kapatmayın'"));
			
			Cancel = True;
			ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NStr("vi = 'Tất cả dữ liệu đã thay đổi sẽ bị mất. Đóng biểu mẫu?';
																							|ru = 'Все измененные данные будут потеряны. Закрыть форму?';
																							|en = 'All changed data will be lost. Close the form?'; fa = 'All changed data will be lost. Close the form?';
																							|it = 'Tutti i dati modificati andranno persi. Chiudere il form?';
																							|pl = 'Wszystkie zmodyfikowane dane zostaną utracone. Chcesz zamknąć formularz?';
																							|tr = 'Tüm değişiklikler kaybolacak. Kapatılsın mı?'"), ButtonsList);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = "Close" Then
		ClosingInProgress = True;
		Close();
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtServer
Procedure FillInPaymentStagesFromTemporaryStorageServer(AddressInTempStorage)
	
	PaymentSteps = GetFromTempStorage(AddressInTempStorage);
	
	For Each CurRow In PaymentSteps Do
		NewRow = Object.PaymentScheduleSteps.Add();
		FillPropertyValues(NewRow, CurRow);
	EndDo;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsAfterDeleteRow(Item)
	
	CalculateTotalsOfAgreementWithClient(ThisForm);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTotalsOfAgreementWithClient(ThisForm);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsPaymentOptionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = (BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"));
	
	If Not StandardProcessing 
		And BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		
		ChoiceData = New ValueList;
		ChoiceData.Add(PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeferredPaymentModeOnChange(Item)
	
	Items.Calendar.Enabled = ?(DeferredPaymentMode = 1, True, False);
	Items.Calendar.AutoMarkIncomplete = ?(DeferredPaymentMode = 1, True, False);
	
	If DeferredPaymentMode = 1 Then
		FillProductionCalendarOnServer();
	Else
		Object.Calendar = PredefinedValue("Catalog.BusinessCalendars.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsCalculateFromOnChange(Item)
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	If CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FixedDate") Then
		CurrentData.Move = 0;
		CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditPlanned");
	EndIf;
	
	If CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.Formula") Then
		ChoiceProcessing = New CallbackDescription("PaymentStagesReferenceOptionOnChangeCompletion",ThisObject);
		OpenForm("Catalog.FormulasForCalculatingPaymentDate.Form.ChoiceForm",
			New Structure("CurrentRow",CurrentData.Formula),
			ThisObject,,,,ChoiceProcessing,FormWindowOpeningMode.LockOwnerWindow);
	Else
		CurrentData.Formula = Undefined;
	EndIf;
EndProcedure

&AtClient
Procedure PaymentStagesReferenceOptionOnChangeCompletion(Result, AdditionalParameters) Export
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrentData.Formula = Result;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	Done = True;
	ObjectStructure = New Structure();
	ObjectStructure.Insert("Calendar", Object.Calendar);
	ObjectStructure.Insert("AddressInTempStorage", PutItInTemporaryStorageOnServer());
	ObjectStructure.Insert("Status", Object.Status);
	
	Close(ObjectStructure);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsMove.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.OffsetIsIncorrect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.PercentageIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.OffsetIsIncorrect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.LineNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = New DataCompositionField("LineNumberOfFullPayment");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LineNumberOfFullPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.PaymentPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Function PutItInTemporaryStorageOnServer()
	
	Return PutToTempStorage(Object.PaymentScheduleSteps.Unload(), CalledFormID);
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateTotalsOfAgreementWithClient(Form)
	
	TotalPaymentPercentage = 0;
	PreviousShiftValue = 0;
	Form.LineNumberOfFullPayment = 0;
	For Each CurRow In Form.Object.PaymentScheduleSteps Do
		
		TotalPaymentPercentage = TotalPaymentPercentage + CurRow.PaymentPercentage;
		CurRow.PercentageIsFilledInIncorrectly = (TotalPaymentPercentage > 100);
		If TotalPaymentPercentage = 100 Then
			Form.LineNumberOfFullPayment = CurRow.LineNumber;
		EndIf;
		
		CurRow.OffsetIsIncorrect = (PreviousShiftValue > CurRow.Move);
		PreviousShiftValue = CurRow.Move;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillProductionCalendarOnServer()
	
	CalendarSchedules.FillBusinessCalendarInForm(ThisForm, "Object.Calendar");
	
EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion