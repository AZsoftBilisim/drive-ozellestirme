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
	CalculateTotalsOfAgreementWithSupplier(ThisForm);
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
			ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NStr("vi = 'Sẽ mất tất cả dữ liệu đã thay đổi. Đóng biểu mẫu?';
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
	
	CalculateTotalsOfAgreementWithSupplier(ThisForm);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTotalsOfAgreementWithSupplier(ThisForm);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsPaymentOptionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = (BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseByImport"));
	
	If Not StandardProcessing 
		And BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement") Then
		
		ChoiceData = New ValueList;
		ChoiceData.Add(PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment"));
		ChoiceData.Add(PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterReceipt"));
		
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
		CurrentData.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterReceipt");
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
	
	If PaymentIsCorrect() Then
		
		Done = True;
		ObjectStructure = New Structure();
		ObjectStructure.Insert("Calendar", Object.Calendar);
		ObjectStructure.Insert("AddressInTempStorage", PutItInTemporaryStorageOnServer());
		ObjectStructure.Insert("Status", Object.Status);
		
		Close(ObjectStructure);
		
	EndIf;
	
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
Function PaymentIsCorrect()

	Cancel = False;
	NumberOfStages = Object.PaymentScheduleSteps.Count();
	
	For CurIndex__ = 0 To Object.PaymentScheduleSteps.Count()-1 Do
		
		CurRow = Object.PaymentScheduleSteps[CurIndex__];
		
		ErrorAddress = NStr("vi = 'tại dòng %LineNumber% trong danh sách ""Giai đoạn lịch biểu thanh toán""';
							|ru = 'в строке %LineNumber% списка ""Этапы графика оплаты""';
							|en = 'in line %LineNumber% of the ""Payment milestones"" list'; fa = 'in line %LineNumber% of the ""Payment milestones"" list';
							|it = 'nella riga %LineNumber% dell''elenco ""Fasi del programma di pagamento""';
							|pl = 'w wierszu %LineNumber% listy ""Этапы графика оплаты""';
							|tr = '""ödeme planı aşamaları"" listenin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", CurRow.LineNumber);
		
		If Not ValueIsFilled(CurRow.PaymentOption) Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Phương án thanh toán""';
							|ru = 'Не заполнена колонка ""Вариант оплаты""';
							|en = 'Payment terms required'; fa = 'Payment terms required';
							|it = 'Non è stata compilata la colonna ""Opzione di pagamento""';
							|pl = 'Nie wypełniono pola  ""Вариант оплаты""';
							|tr = '""Ödeme seçeneği"" sütunu doldurulmadı'");
			Common.MessageToUser(
				ErrorText + " " + ErrorAddress,
				,
				CommonClientServer.PathToTabularSection("Object.PaymentScheduleSteps", CurRow.LineNumber, "PaymentOption"),
				,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(CurRow.PaymentPercentage) Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Phần trăm thanh toán""';
							|ru = 'Не заполнена колонка ""Процент платежа""';
							|en = 'Column ""Payment percentage"" is not filled in'; fa = 'Column ""Payment percentage"" is not filled in';
							|it = 'La colonna ""Percentuale di pagamento"" non è compilata';
							|pl = 'Nie wypełniono kolumny ""Процент платежа""';
							|tr = '""Ödeme yüzdesi"" sütunu boş'");
			Common.MessageToUser(
			ErrorText + ErrorAddress,
			,
			CommonClientServer.PathToTabularSection(
			"Object.PaymentScheduleSteps",
			CurRow.LineNumber,
			"PaymentPercentage"),
			,
			Cancel);
			
		EndIf;
		
	EndDo;
	
	If NumberOfStages > 0 Then
		
		If Object.PaymentScheduleSteps.Total("PaymentPercentage") <> 100 Then
			
			ErrorText = NStr("vi = 'Phần trăm thanh toán theo tất cả giai đoạn cần phải bằng 100%';
							|ru = 'Процент платежей по всем этапам должен быть равен 100%';
							|en = 'Payment percentage at all stages should be equal to 100 %'; fa = 'Payment percentage at all stages should be equal to 100 %';
							|it = 'La percentuale di pagamento per tutte le fasi deve essere pari al 100%';
							|pl = 'Procent płatności dla wszystkich etapów powinien wynosić 100%';
							|tr = 'Tüm aşamalar için ödeme yüzdesi 100% olmalıdır'");
			
			Common.MessageToUser(
				ErrorText,
				,
				"Object.PaymentScheduleSteps",
				,
				Cancel);
			
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
			
			For Each PaymentScheduleStage In Object.PaymentScheduleSteps Do
				
				If PaymentScheduleStage.PaymentOption <> Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment
					And PaymentScheduleStage.PaymentOption <> Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt Then
					
					ErrorText = NStr("vi = 'Không thể sử dụng phương án kiểm soát ""%PaymentOption%"" 
						|trong giao dịch kinh tế đã thiết lập ""Tiếp nhận ký gửi""';
						|ru = 'Вариант контроля ""%PaymentOption%"" нельзя использовать
						|при установленной хозяйственной операции ""Прием на комиссию""';
						|en = 'Cannot use the ""%PaymentOption%"" control option
						|when the ""Consignment procurement"" business transaction is set'; fa = 'Cannot use the ""%PaymentOption%"" control option
						|when the ""Consignment procurement"" business transaction is set';
						|it = 'Impossibile utilizzare la variante di controllo ""%PaymentOption%""
						|in caso di operazione commerciale impostata ""Ricezione in commissione""';
						|pl = 'Wariantu kontroli ""%PaymentOption%"" nie można używać
						|przy operacji gospodarczej ""Przyjęcie do komisu""';
						|tr = '""%PaymentOption%"" kontrol seçeneği ayarlanan ""Komisyona kabul"" 
						|ticari işlemi için kullanılamaz'");
					ErrorText = StrReplace(ErrorText, "%PaymentOption%", PaymentScheduleStage.PaymentOption);
					
					Common.MessageToUser(
						ErrorText,
						,
						"Object." + CommonClientServer.PathToTabularSection("PaymentScheduleSteps", PaymentScheduleStage.LineNumber,"PaymentOption"),
						,
						Cancel);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	If DeferredPaymentMode = 1 And Not ValueIsFilled(Object.Calendar) Then
		
		ErrorText = NStr("vi = 'Chưa chỉ ra lịch để tính thời hạn hoán lại theo ngày làm việc.';
						|ru = 'Не указан календарь для учета отсрочки по рабочим дням.';
						|en = 'Calendar for deferred payments by work days is not specified.'; fa = 'Calendar for deferred payments by work days is not specified.';
						|it = 'Non è indicato il calendario per la contabilità di posticipazione nei giorni lavorativi.';
						|pl = 'Nie wskazano kalendarza dla ewidencji prolongaty w dni robocze.';
						|tr = 'İş gününe göre ertelemeyi açıklamak için herhangi bir takvim belirtilmemiştir.'");
		
		Common.MessageToUser(
		ErrorText,
		,
		"Object.Calendar",
		,
		Cancel);
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

&AtServer
Function PutItInTemporaryStorageOnServer()
	
	Return PutToTempStorage(Object.PaymentScheduleSteps.Unload(), CalledFormID);
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateTotalsOfAgreementWithSupplier(Form)
	
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