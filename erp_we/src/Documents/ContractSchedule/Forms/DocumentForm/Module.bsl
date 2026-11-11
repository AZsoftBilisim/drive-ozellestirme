
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	SetItemsVisibility();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ScheduleParameters = New Structure;
	ScheduleParameters.Insert("Contract", Object.Contract);
	ScheduleParameters.Insert("ContractAmount", ContractAmount);
	
	Notify("Write_ContractSchedule", ScheduleParameters, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ContractAmountOnChange(Item)
	
	RecalculatePercentages(ThisObject);
	
EndProcedure

&AtClient
Procedure DeliveryDurationOnChange(Item)
	
	If Object.DeliveryDuration = 0 Then
		For Each LineOfExecution In Object.ContractScheduleSteps Do
			LineOfExecution.DateAccordingToSchedule =  LineOfExecution.DateOfShipment;
		EndDo;
	EndIf;
	
	ReFillInDatesAccordingToScheduleAndPaymentDates();
	
	SetItemsVisibility();
	
EndProcedure

&AtClient
Procedure DeferredPaymentModeOnChange(Item)
	
	DeferredPaymentModeOnChangeServer();
	
EndProcedure

&AtClient
Procedure CalendarOnChange(Item)
	
	ReFillInDatesAccordingToScheduleAndPaymentDates();
	
EndProcedure

&AtClient
Procedure ScheduleIsPartiallyFulfilledOnChange(Item)
	SetItemsVisibility();
	If Not Object.ScheduleIsPartiallyFulfilled Then
		For Each StageString_ In Object.ContractScheduleSteps Do
			StageString_.AlreadyShipped = False;
		EndDo;
		For Each StageString_ In Object.PaymentScheduleSteps Do
			StageString_.AlreadyPaid = False;
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersContractScheduleSteps

&AtClient
Procedure ContractScheduleStepsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.ContractScheduleSteps.CurrentData;
	
	If CurrentData <> Undefined
		And Not CancelEdit
		And InStageTableThereAreStagesFromDateOfShipment()
		And Object.PaymentScheduleSteps.Count() > 0
		And (TypeOf(LineToEdit) = Type("Structure")
				And (LineToEdit.FulfillmentPercentage <> CurrentData.FulfillmentPercentage
					Or LineToEdit.ActualAmount <> CurrentData.ActualAmount
					Or LineToEdit.DateAccordingToSchedule <> CurrentData.DateAccordingToSchedule) 
			Or NewRow 
				And (ValueIsFilled(CurrentData.DateAccordingToSchedule) 
					Or ValueIsFilled(CurrentData.FulfillmentPercentage)
					Or ValueIsFilled(CurrentData.ActualAmount))) Then
				
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("StageString_",Items.ContractScheduleSteps.CurrentRow);
		AdditionalParameters.Insert("DateAccordingToSchedule", CurrentData.DateAccordingToSchedule);
		AdditionalParameters.Insert("ActualAmount",CurrentData.ActualAmount);
		AdditionalParameters.Insert("FulfillmentPercentage",CurrentData.FulfillmentPercentage);
		
		QueryText = NStr("vi = 'Lịch thanh toán sẽ bị xóa, tiếp tục?';
						|ru = 'График оплаты будет очищен, продолжить?';
						|en = 'The payment schedule will be cleared. Continue?'; fa = 'The payment schedule will be cleared. Continue?';
						|it = 'Il grafico di pagamento sarà svuotato, continuare?';
						|pl = 'Harmonogram płatności zostanie wyczyszczony, kontynuować?';
						|tr = 'Ödeme planı temizlenecek, devam edilsin mi?'");
		ShowQueryBox(
			New CallbackDescription("ContractScheduleStepsOnEditEndCompletion", ThisObject, AdditionalParameters), 
				QueryText, QuestionDialogMode.YesNo);
	Else
		CollapseExecutionStages();
		SortStagesOfExecution();
		CalculateTotals_(ThisObject);
		
	EndIf;
	
	SetHeadersScheduleIsPartiallyExecuted();
	
EndProcedure

&AtClient
Procedure ContractScheduleStepsOnEditEndCompletion(QuestionResult, AdditionalParameters) Export

	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		StageString_ = Object.ContractScheduleSteps.FindByID(AdditionalParameters.StageString_);
		If LineToEdit = Undefined Then
			Object.ContractScheduleSteps.Delete(StageString_);
		Else
			StageString_.FulfillmentPercentage = LineToEdit.FulfillmentPercentage;
			StageString_.ActualAmount = LineToEdit.ActualAmount;
			StageString_.DateAccordingToSchedule = LineToEdit.DateAccordingToSchedule;
			StageString_.DateOfShipment = StageString_.DateAccordingToSchedule - 86400 * Object.DeliveryDuration;
		EndIf;
		
		CollapseExecutionStages();
		SortStagesOfExecution();
		CalculateTotals_(ThisObject);
		
	Else
		Object.PaymentScheduleSteps.Clear();
		CalculateTotals_(ThisObject);
		SetItemsVisibility();
		SetHeadersScheduleIsPartiallyExecuted();
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractScheduleStepsFulfillmentPercentageOnChange(Item)
	
	CurrentData = Items.ContractScheduleSteps.CurrentData;
	
	If CurrentData.FulfillmentPercentage > 0 And Object.ContractScheduleSteps.Total("FulfillmentPercentage") = 100 Then
		
		ActualAmount = 0;
		For Each CurRow In Object.ContractScheduleSteps Do
			If CurRow.LineNumber <> CurrentData.LineNumber Then
				ActualAmount = ActualAmount + CurRow.ActualAmount;
			EndIf;
		EndDo;
		CurrentData.ActualAmount = ContractAmount - ActualAmount;
	Else
		
		CurrentData.ActualAmount = ContractAmount * CurrentData.FulfillmentPercentage / 100;
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractScheduleStepsActualAmountOnChange(Item)
	
	RecalculatePercentages(ThisObject);
	
EndProcedure

&AtClient
Procedure ContractScheduleStepsDateOfShipmentOnChange(Item)
	
	CurrentData = Items.ContractScheduleSteps.CurrentData;
	
	If CurrentData <> Undefined Then
		If ValueIsFilled(Object.Calendar) Then
			CurrentData.DateAccordingToSchedule = CalendarDateOfReceipt(CurrentData.DateOfShipment);
		Else
			CurrentData.DateAccordingToSchedule = CurrentData.DateOfShipment + 86400 * Object.DeliveryDuration;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractScheduleStepsDateAccordingToScheduleOnChange(Item)
	
	CurrentData = Items.ContractScheduleSteps.CurrentData;
	
	If CurrentData <> Undefined Then
		If ValueIsFilled(Object.Calendar) Then
			CurrentData.DateOfShipment = CalendarDateOfReceipt(CurrentData.DateAccordingToSchedule,True);
		Else
			CurrentData.DateOfShipment = CurrentData.DateAccordingToSchedule - 86400 * Object.DeliveryDuration;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractScheduleStepsBeforeDeleteRow(Item, Cancel)
	
	If InStageTableThereAreStagesFromDateOfShipment() Then
		
		Cancel = True;
		
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("StageString_",Items.ContractScheduleSteps.CurrentRow);
		
		QueryText = NStr("vi = 'Lịch thanh toán sẽ bị xóa, tiếp tục?';
						|ru = 'График оплаты будет очищен, продолжить?';
						|en = 'The payment schedule will be cleared. Continue?'; fa = 'The payment schedule will be cleared. Continue?';
						|it = 'Il grafico di pagamento sarà svuotato, continuare?';
						|pl = 'Harmonogram płatności zostanie wyczyszczony, kontynuować?';
						|tr = 'Ödeme planı temizlenecek, devam edilsin mi?'");
		ShowQueryBox(
			New CallbackDescription("ContractScheduleStepsBeforeDeleteRowCompletion", ThisObject, AdditionalParameters), 
				QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractScheduleStepsBeforeRowChange(Item, Cancel)
	
	CurrentData = Items.ContractScheduleSteps.CurrentData;
	
	LineToEdit = New Structure;
	LineToEdit.Insert("DateAccordingToSchedule", CurrentData.DateAccordingToSchedule);
	LineToEdit.Insert("FulfillmentPercentage", CurrentData.FulfillmentPercentage);
	LineToEdit.Insert("ActualAmount", CurrentData.ActualAmount);
	
EndProcedure

&AtClient
Procedure ContractScheduleStepsAfterDeleteRow(Item)
	CollapseExecutionStages();
	CalculateTotals_(ThisObject);
EndProcedure

&AtClient
Procedure ContractScheduleStepsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	CurrentData = Items.ContractScheduleSteps.CurrentData;
	If NewRow And Not CancelEdit Then
		
		ClearMessages();
		
		If Not ValueIsFilled(CurrentData.DateAccordingToSchedule) Then
			CommonClient.MessageToUser(NStr("vi = 'Điền ngày giao hàng';
											|ru = 'Заполните дату отгрузки';
											|en = 'Fill in shipment date'; fa = 'تکمیل تاریخ ارسال';
											|it = 'Compilare data di spedizione';
											|pl = 'Wypełnij datę wysyłki';
											|tr = 'Sevkiyat tarihini doldur'"),
				Object.Ref,
				"Object.ContractScheduleSteps",,Cancel);
		EndIf;
		
		If Not ValueIsFilled(CurrentData.ActualAmount) Then
			CommonClient.MessageToUser(NStr("vi = 'Điền số tiền giao hàng';
											|ru = 'Заполните сумму отгрузки';
											|en = 'Fill in shipment amount'; fa = 'Fill in shipment amount';
											|it = 'Compilare importo di spedizione';
											|pl = 'Wypełnij wartość wysyłki';
											|tr = 'Sevkiyat tutarını doldur'"),
				Object.Ref,
				"Object.ContractScheduleSteps",,Cancel);
		EndIf;
		
	EndIf;
	If Not CancelEdit Then
		SetHeadersScheduleIsPartiallyExecuted();
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentScheduleSteps

&AtClient
Procedure PaymentScheduleStepsMoveOnChange(Item)
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = ContractDate_;
	ParametersForFillingInPaymentDate.ApprovalDate               = ContractDate_;
	ParametersForFillingInPaymentDate.DateOfShipment                   = CurrentData.DateOfShipment;
	If ValueIsFilled(Object.Calendar) Then
		ParametersForFillingInPaymentDate.DateOfReceipt                = CalendarDateOfReceipt(CurrentData.DateOfShipment);
	Else
		ParametersForFillingInPaymentDate.DateOfReceipt                = CurrentData.DateOfShipment+Object.DeliveryDuration*86400;
	EndIf;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = Date(1,1,1);
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = Object.DeliveryDuration;
	ParametersForFillingInPaymentDate.Calendar                      = Object.Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		CurrentData,ParametersForFillingInPaymentDate);
	
	SortPaymentStages();
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsCalculateFromOnChange(Item)
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	If CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FixedDate") Then
		CurrentData.Move = 0;
	EndIf;
	
	If CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.Formula") Then
		ChoiceProcessing = New CallbackDescription("PaymentStagesReferenceOptionOnChangeCompletion",ThisObject);
		OpenForm("Catalog.FormulasForCalculatingPaymentDate.Form.ChoiceForm",,ThisObject,,,,ChoiceProcessing,FormWindowOpeningMode.LockOwnerWindow);
	Else
		CurrentData.Formula = Undefined;
		CalculatePaymentDateONChangingReferenceOption();
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentStagesReferenceOptionOnChangeCompletion(Result, AdditionalParameters) Export
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	If Result = Undefined Then
		CurrentData.CalculateFrom = Undefined;
		CurrentData.Formula = Undefined;
		Return;
	EndIf;
	
	CurrentData.Formula = Result;
	
	CalculatePaymentDateONChangingReferenceOption();
	
EndProcedure

&AtClient
Procedure CalculatePaymentDateONChangingReferenceOption()
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	CurrentData.DateOfShipment = DefaultShippingDate(CurrentData.CalculateFrom, CurrentData.Formula);
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = ContractDate_;
	ParametersForFillingInPaymentDate.ApprovalDate               = ContractDate_;
	ParametersForFillingInPaymentDate.DateOfShipment                   = CurrentData.DateOfShipment;
	If ValueIsFilled(Object.Calendar) Then
		ParametersForFillingInPaymentDate.DateOfReceipt                = CalendarDateOfReceipt(CurrentData.DateOfShipment);
	Else
		ParametersForFillingInPaymentDate.DateOfReceipt                = CurrentData.DateOfShipment+Object.DeliveryDuration*86400;
	EndIf;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = Date(1,1,1);
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = Object.DeliveryDuration;
	ParametersForFillingInPaymentDate.Calendar                      = Object.Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		CurrentData, ParametersForFillingInPaymentDate);
	
	SortPaymentStages();
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsPaymentOptionOnChange(Item)
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = ContractDate_;
	ParametersForFillingInPaymentDate.ApprovalDate               = ContractDate_;
	ParametersForFillingInPaymentDate.DateOfShipment                   = CurrentData.DateOfShipment;
	If ValueIsFilled(Object.Calendar) Then
		ParametersForFillingInPaymentDate.DateOfReceipt                = CalendarDateOfReceipt(CurrentData.DateOfShipment);
	Else
		ParametersForFillingInPaymentDate.DateOfReceipt                = CurrentData.DateOfShipment+Object.DeliveryDuration*86400;
	EndIf;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = Date(1,1,1);
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = Object.DeliveryDuration;
	ParametersForFillingInPaymentDate.Calendar                      = Object.Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleControlOptionForChanges(
		CurrentData,ParametersForFillingInPaymentDate);
	
	SortPaymentStages();
	
EndProcedure

&AtClient
Procedure StagesOfPaymentSchedulePaymentPercentageOnChange(Item)
	PaymentStepsClient.PaymentScheduleStepsPaymentPercentageOnChange(
		Items.PaymentScheduleSteps.CurrentData,
		Object.PaymentScheduleSteps,
		ContractAmount);
EndProcedure

&AtClient
Procedure PaymentScheduleStagesPaymentAmountOnChange(Item)
	PaymentStepsClient.PaymentScheduleStepsPaymentAmountOnChange(
		Items.PaymentScheduleSteps.CurrentData,
		Object.PaymentScheduleSteps,
		ContractAmount);
	RecalculatePercentages(ThisObject);
EndProcedure

&AtClient
Procedure PaymentScheduleStepsOnStartEdit(Item, NewRow, Copy)
	If NewRow Then
		Items.PaymentScheduleSteps.CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromOrderDate");
		If TheseAreSettlementsWithCustomers Then
			Items.PaymentScheduleSteps.CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment");
		Else
			Items.PaymentScheduleSteps.CurrentData.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment");
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure StagesOfPaymentScheduleDateOnScheduleOnChange(Item)
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	ShiftFillParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ShiftFillParameters.OrderDate                     = ContractDate_;
	ShiftFillParameters.ApprovalDate               = ContractDate_;
	ShiftFillParameters.DateOfShipment                   = CurrentData.DateOfShipment;
	If ValueIsFilled(Object.Calendar) Then
		ShiftFillParameters.DateOfReceipt                = CalendarDateOfReceipt(CurrentData.DateOfShipment);
	Else
		ShiftFillParameters.DateOfReceipt                = CurrentData.DateOfShipment+Object.DeliveryDuration*86400;
	EndIf;
	ShiftFillParameters.DateOfTransferOfTitleToGoods = Date(1,1,1);
	ShiftFillParameters.DeadlineOfTransferOfTitleToGoods = Object.DeliveryDuration;
	ShiftFillParameters.Calendar                      = Object.Calendar;
	
	PaymentStepsClient.PaymentScheduleStepsPaymentDateOnChange(
		CurrentData,ShiftFillParameters);
	
	SortPaymentStages();
	
EndProcedure

&AtClient
Procedure StagesOfPaymentScheduleAlreadyPaidOnChange(Item)
	SetHeadersScheduleIsPartiallyExecuted();
EndProcedure

&AtClient
Procedure PaymentScheduleStepsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Notification = New CallbackDescription("PaymentScheduleStepsBeforeAddRowCompletion", ThisObject);
	
	EditParameters = EditingOptionsForMultiplePaymentMilestones();
	
	PaymentStepsClient.PaymentScheduleStepsBeforeAddRow(ThisForm,
		EditParameters,
		Cancel,
		Copy,
		Notification);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsBeforeAddRowCompletion(Result, Var_Parameters) Export
	
	If Result <> Undefined Then
		SetItemsVisibility();
		SetHeadersScheduleIsPartiallyExecuted();
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsBeforeDeleteRow(Item, Cancel)
	
	PaymentStepsClient.PaymentScheduleStepsBeforeDeleteRow(ThisForm, Cancel, Object.PaymentScheduleSteps);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsBeforeRowChange(Item, Cancel)
	
	Notification = New CallbackDescription("PaymentScheduleStepsBeforeRowChangeCompletion", ThisObject);
	
	EditParameters = EditingOptionsForMultiplePaymentMilestones();
	
	PaymentStepsClient.PaymentScheduleStepsBeforeRowChange(ThisForm,
		EditParameters,
		Cancel,
		Notification);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsBeforeRowChangeCompletion(Result, Var_Parameters) Export
	
	If Result <> Undefined Then
		
		RecalculatePercentages(ThisObject);
		SetHeadersScheduleIsPartiallyExecuted();
		SortPaymentStages();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsAfterDeleteRow(Item)
	SetItemsVisibility();
	SetHeadersScheduleIsPartiallyExecuted();
EndProcedure

&AtClient
Procedure PaymentScheduleStepsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	SetItemsVisibility();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure FillInPaymentScheduleByAgreement(Command)
	
	Notification = New CallbackDescription("FillInPaymentScheduleByAgreementCompletion", ThisObject);
	
	OpeningParameters = New Structure("Counterparty",Counterparty);
	
	If TheseAreSettlementsWithCustomers Then
		OpenForm("Catalog.TermsOfSale.Form.ChoiceForm",OpeningParameters,ThisObject,,,,Notification);
	Else
		OpenForm("Catalog.TermsOfPurchaseFromVendors.Form.ChoiceForm",OpeningParameters,ThisObject,,,,Notification);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	If ValueIsFilled(Object.Contract) Then
		
		ContractDetails_ = Common.ObjectAttributesValues(Object.Contract,
			"Sum,ContractType,Date,Counterparty,ARAPCurrency,OptionOfDeterminingExecutionScheduleInContract");
		
		ContractAmount = ContractDetails_.Sum;
		TheseAreSettlementsWithCustomers =
			ContractDetails_.ContractType = Enums.ContractTypes.WithCustomer
			Or ContractDetails_.ContractType = Enums.ContractTypes.ReceiptForTolling2_5
			Or False;
		ContractDate_ = ContractDetails_.Date;
		Counterparty = ContractDetails_.Counterparty;
		Currency = ContractDetails_.ARAPCurrency;
		
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate, NStr("vi = 'từ ngày hợp đồng';
																														|ru = 'от даты договора';
																														|en = 'from contract date'; fa = 'from contract date';
																														|it = 'dalla data dell''accordo';
																														|pl = 'od daty umowy';
																														|tr = 'sözleşme tarihinden'"));
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromShipmentDate);
		If Not TheseAreSettlementsWithCustomers Then
			Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfReceipt);
		EndIf;
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FixedDate);
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.Formula);
		
		If TheseAreSettlementsWithCustomers Then
			Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment);
			Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.CreditAfterShipment);
			Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.CreditPlanned);
			
			If GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0") Then
				Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods);
			EndIf;
			
		Else
			Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt);
			Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment);
			Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt);
		EndIf;
		
		RegularPayments = Enums.OptionsForDeterminingExecutionScheduleInContract.RegularPayments;
		If ContractDetails_.OptionOfDeterminingExecutionScheduleInContract = RegularPayments Then
			ReadOnly = True;
			Common.MessageToUser(NStr("ru = 'Документ не поддерживает интерактивное изменение.';
										|vi = 'The document does not support manual editing.';
										|en = 'The document does not support manual editing.'; fa = 'The document does not support manual editing.';
										|it = 'The document does not support manual editing.';
										|pl = 'The document does not support manual editing.';
										|tr = 'Belge etkileşimli değişikliği desteklemiyor.'"));
		EndIf;
	EndIf;
	
	SetConditionalAppearance();
	CalculateTotals_(ThisObject);
	SetHeadersScheduleIsPartiallyExecuted();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesOfPaymentSchedulePaymentPercentage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.PaymentPercentIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContractScheduleStepsFulfillmentPercentage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ContractScheduleSteps.ExecutionPercentIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsCalculateFrom.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentScheduleSteps.CalculateFrom");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PaymentDateCalculationOptions.FromOrderDate;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'từ ngày hợp đồng';
													|ru = 'от даты договора';
													|en = 'from contract date'; fa = 'from contract date';
													|it = 'dalla data dell''accordo';
													|pl = 'od daty umowy';
													|tr = 'sözleşme tarihinden'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsMove.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.CalculateFrom");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PaymentDateCalculationOptions.FixedDate;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure SetItemsVisibility()
	
	Items.DeliveryDuration.Visible = Not TheseAreSettlementsWithCustomers;
	
	Items.FillInPaymentScheduleByAgreement.Visible = GetFunctionalOption("ToUseTermsOfSales") And TheseAreSettlementsWithCustomers
		Or GetFunctionalOption("UseTermsOfPurchases") And Not TheseAreSettlementsWithCustomers;
	
	If TheseAreSettlementsWithCustomers Then
		
		Items.ContractScheduleStepsDateAccordingToSchedule.Visible = False;
		
	Else
		
		Items.ContractScheduleStepsDateAccordingToSchedule.Visible = Object.DeliveryDuration <> 0;
		
	EndIf;
	
	DeferredPaymentMode = ValueIsFilled(Object.Calendar);
	Items.Calendar.Visible = DeferredPaymentMode;
	Items.ContractScheduleStepsAlreadyShipped.Visible = Object.ScheduleIsPartiallyFulfilled;
	Items.PaymentScheduleStepsAlreadyPaid.Visible = Object.ScheduleIsPartiallyFulfilled;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form)
	
	Form.PercentageOfTotalPayments = 0;
	Form.OverallProgressPercentage = 0;
	
	For Each CurRow In Form.Object.ContractScheduleSteps Do
		
		Form.OverallProgressPercentage = Form.OverallProgressPercentage + CurRow.FulfillmentPercentage;
		CurRow.ExecutionPercentIsFilledInIncorrectly = (Form.OverallProgressPercentage > 100);
		If Form.OverallProgressPercentage = 100 Then
			Form.FullExecutionLineNumber = CurRow.LineNumber;
		EndIf;
		
	EndDo;
	
	For Each CurRow In Form.Object.PaymentScheduleSteps Do
		
		Form.PercentageOfTotalPayments = Form.PercentageOfTotalPayments + CurRow.PaymentPercentage;
		CurRow.PaymentPercentIsFilledInIncorrectly = (Form.PercentageOfTotalPayments > 100);
		If Form.PercentageOfTotalPayments = 100 Then
			Form.LineNumberOfFullPayment = CurRow.LineNumber;
		EndIf;
		
	EndDo;
	
	Form.MultipleShippingDates = Form.Object.ContractScheduleSteps.Count() > 1;
	Form.DateOfShipment = ?(Form.Object.ContractScheduleSteps.Count() = 1,Form.Object.ContractScheduleSteps[0].DateOfShipment,Date(1,1,1));
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculatePercentages(Form)
	
	If Form.ContractAmount <> 0 Then
		
		FulfillmentPercentage = Round(Form.Object.ContractScheduleSteps.Total("ActualAmount") * 100 / Form.ContractAmount, 2);
		ArrayOfStages = New Array();
		For Each ScheduleStage In Form.Object.ContractScheduleSteps Do 
			ArrayOfStages.Add(ScheduleStage.ActualAmount);
		EndDo; 
		If ArrayOfStages.Count() > 0 Then
			ArrayOfPercentages = TMCommonUseClientServer.DistributeProportionally(FulfillmentPercentage, ArrayOfStages);
			For Counter = 0 To ArrayOfStages.Count() - 1 Do 
				If ArrayOfPercentages <> Undefined Then
					Form.Object.ContractScheduleSteps[Counter].FulfillmentPercentage = ArrayOfPercentages[Counter];
				Else
					Form.Object.ContractScheduleSteps[Counter].FulfillmentPercentage = 0;
				EndIf;
			EndDo;
		EndIf;
		
		PayPercentage = Round(Form.Object.PaymentScheduleSteps.Total("PaymentAmount") * 100 / Form.ContractAmount, 2);
		ArrayOfStages.Clear();
		For Each ScheduleStage In Form.Object.PaymentScheduleSteps Do 
			ArrayOfStages.Add(ScheduleStage.PaymentAmount);
		EndDo; 
		If ArrayOfStages.Count() > 0 Then
			ArrayOfPercentages = TMCommonUseClientServer.DistributeProportionally(PayPercentage, ArrayOfStages);
			For Counter = 0 To ArrayOfStages.Count() - 1 Do
				If ArrayOfPercentages <> Undefined Then
					Form.Object.PaymentScheduleSteps[Counter].PaymentPercentage = ArrayOfPercentages[Counter];
				Else
					Form.Object.PaymentScheduleSteps[Counter].PaymentPercentage = 0;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPaymentScheduleByAgreementCompletion(Result, Var_Parameters) Export
	
	If Result <> Undefined Then
		FillInPaymentScheduleAccordingToAgreementOnServer(Result);
		Modified = True;
	EndIf;
	
	SortPaymentStages();
	
EndProcedure

&AtServer
Procedure FillInPaymentScheduleAccordingToAgreementOnServer(Result)
	
	StageFillingParameters = PaymentStepsServer.ParametersForFillingInPaymentStages();
	StageFillingParameters.InvoiceForOrders = False;
	StageFillingParameters.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts;
	StageFillingParameters.ThisIsOrder = True;
	StageFillingParameters.OrderDate = ContractDate_;
	StageFillingParameters.DateOfShipment = DateOfShipment;
	StageFillingParameters.Terms = Result;
	StageFillingParameters.PayAmount = ContractAmount;
	StageFillingParameters.TheseAreSettlementsWithCustomers = TheseAreSettlementsWithCustomers;
	
	ShipmentTable = Object.ContractScheduleSteps.Unload();
	ShipmentTable.Columns.ActualAmount.Name = "PaymentAmount";
	ShipmentTable.Columns.Add("PackageDepositValue",Common.TypeDescriptionNumber(1));
	StageFillingParameters.TabularSection = ShipmentTable;
	
	PaymentStepsServer.FillInPaymentStagesByAgreement(Object.PaymentScheduleSteps, StageFillingParameters);
	
	Object.Calendar = Common.ObjectAttributeValue(Result,"Calendar");
	
	For Each Page1 In Object.PaymentScheduleSteps Do
		If Page1.PaymentOption = Enums.CustomerPaymentControlOptions.PrepaymentBeforeProvision Then
			Page1.PaymentOption = Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment;
		EndIf;
		If Page1.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation Then
			Page1.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt;
		EndIf;
		If Page1.CalculateFrom = Enums.PaymentDateCalculationOptions.FromApprovalDate Then
			Page1.CalculateFrom = Enums.PaymentDateCalculationOptions.FromOrderDate;
		EndIf;
	EndDo;
	
	SetItemsVisibility();
	
EndProcedure

&AtClient
Procedure SortPaymentStages()
	
	For Each Page1 In Object.PaymentScheduleSteps Do
		Page1.PaymentOptionNumber = ?(Page1.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment")
									Or Page1.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt"),
									1,
									?(Page1.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision")
										Or Page1.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation"),
										0,
										2));
	EndDo;
	
	Object.PaymentScheduleSteps.Sort("PaymentOptionNumber, PaymentDate");
	
EndProcedure

&AtClient
Procedure SortStagesOfExecution()
	
	Object.ContractScheduleSteps.Sort("DateAccordingToSchedule");
	
EndProcedure

&AtServer
Procedure FillProductionCalendarOnServer()
	
	CalendarSchedules.FillBusinessCalendarInForm(ThisObject, "Object.Calendar");
	
EndProcedure

&AtClient
Function EditingOptionsForMultiplePaymentMilestones()
	
	OpenStructure = New Structure;
	OpenStructure.Insert("Currency",                         Currency);
	OpenStructure.Insert("TheseAreSettlementsWithCustomers",           TheseAreSettlementsWithCustomers);
	OpenStructure.Insert("Calendar",                      Object.Calendar);
	OpenStructure.Insert("OrderDate",                     ContractDate_);
	OpenStructure.Insert("ApprovalDate",               Date(1,1,1));
	OpenStructure.Insert("DeadlineOfTransferOfTitleToGoods", 0);
	OpenStructure.Insert("DateOfTransferOfTitleToGoods", Date(1,1,1));
	OpenStructure.Insert("PaymentAmountAgainstTheDocument",         ContractAmount);
	OpenStructure.Insert("DepositAmountUnderTheDocument",         0);
	OpenStructure.Insert("ThisIsContract",                     True);
	OpenStructure.Insert("ShipmentDates",                   Object.ContractScheduleSteps);
	OpenStructure.Insert("PaymentScheduleSteps",             Object.PaymentScheduleSteps);
	OpenStructure.Insert("ThereIsPackage",                       False);
	
	Return OpenStructure;
	
EndFunction

&AtServer
Procedure CollapseExecutionStages()
	Stages = Object.ContractScheduleSteps.Unload();
	Stages.GroupBy("DateAccordingToSchedule,Comment,DateOfShipment,AlreadyShipped","FulfillmentPercentage,ActualAmount");
	Object.ContractScheduleSteps.Load(Stages);
	SetItemsVisibility();
EndProcedure

&AtClient
Procedure ContractScheduleStepsBeforeDeleteRowCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	Else
		Object.PaymentScheduleSteps.Clear();
		Object.ContractScheduleSteps.Delete(Object.ContractScheduleSteps.FindByID(AdditionalParameters.StageString_));
		CalculateTotals_(ThisObject);
		SetItemsVisibility();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetHeadersScheduleIsPartiallyExecuted()
	FlagHeader = NStr("vi = 'Lịch biểu đã được thực hiện một phần trước khi bắt đầu tiến hành kế toán';
						|ru = 'График частично исполнен до начала ведения учета';
						|en = 'Schedule is partially fulfilled before start of accounting'; fa = 'برنامه پیش از شروع حسابداری به‌طور جزئی اجرا شده است';
						|it = 'График частично исполнен до начала ведения учета';
						|pl = 'Schedule is partially fulfilled before start of accounting';
						|tr = 'Program, muhasebenin tutulmaya başlanmasından önce kısmen gerçekleştirildi'");
	If Object.ScheduleIsPartiallyFulfilled Then
		AmountShipped = 0;
		For Each StageString_ In Object.ContractScheduleSteps Do
			AmountShipped = AmountShipped + ?(StageString_.AlreadyShipped, StageString_.ActualAmount, 0);
		EndDo;
		AmountPaid = 0;
		For Each StageString_ In Object.PaymentScheduleSteps Do
			AmountPaid = AmountPaid + ?(StageString_.AlreadyPaid, StageString_.PaymentAmount, 0);
		EndDo;
		If AmountShipped = AmountPaid
			Or Object.ContractScheduleSteps.Total("ActualAmount") <> ContractAmount
			Or Object.ContractScheduleSteps.Total("ActualAmount") <> Object.PaymentScheduleSteps.Total("PaymentAmount") Then
			Items.ScheduleIsPartiallyFulfilled.Title = FlagHeader;
			Items.DecorationScheduleIsPartiallyExecuted.Visible = False;
		Else
			StateOfBalanceInput = StateOfEnteringBalanceOfSettlementsUnderContract(Object.Contract, AmountShipped, AmountPaid);
			Items.ScheduleIsPartiallyFulfilled.Title = FlagHeader + ":";
			Items.DecorationScheduleIsPartiallyExecuted.Visible = True;
			Items.DecorationScheduleIsPartiallyExecuted.Title = StateOfBalanceInput.ToolTipText;
			Items.DecorationScheduleIsPartiallyExecuted.TextColor = StateOfBalanceInput.TooltipColor;
		EndIf;
	Else
		Items.ScheduleIsPartiallyFulfilled.Title = FlagHeader;
		Items.DecorationScheduleIsPartiallyExecuted.Visible = False;
	EndIf;
EndProcedure

&AtServerNoContext
Function StateOfEnteringBalanceOfSettlementsUnderContract(LinkToContract, AmountShipped, AmountPaid)
	Result = New Structure;
	Result.Insert("TooltipColor", StyleColors.TextColorIssue);
	Result.Insert("ToolTipText", NStr("vi = 'không nhập số dư hạch toán công nợ theo lịch biểu';
										|ru = 'ввод остатков взаиморасчетов не соответствует графику';
										|en = 'AR/AP accounting balance entry does not match the schedule'; fa = 'AR/AP accounting balance entry does not match the schedule';
										|it = 'ввод остатков взаиморасчетов не соответствует графику';
										|pl = 'AR/AP accounting balance entry does not match the schedule';
										|tr = 'alacak/borç muhasebesi bakiyelerin girişi programa uygun değildir'"));
	Query = New Query;
	Query.SetParameter("Object", LinkToContract);
	Query.Text = 
		"SELECT
		|	OBEntryARAPPartnersARAPAccounting.Ref.BusinessOperation AS BusinessOperation,
		|	SUM(OBEntryARAPPartnersARAPAccounting.Sum) AS Sum,
		|	ARAPObjects.ARAPCurrency AS ARAPCurrency,
		|	ARAPObjects.PaymentType_ AS PaymentType_
		|FROM
		|	 Catalog.ARAPObjects AS ARAPObjects
		|		LEFT JOIN Document.OBEntryARAP.PartnersARAPAccounting AS OBEntryARAPPartnersARAPAccounting
		|		ON OBEntryARAPPartnersARAPAccounting.ARAPObjectSender = ARAPObjects.Ref
		|			AND OBEntryARAPPartnersARAPAccounting.Ref.Posted
		|WHERE
		|	ARAPObjects.Object = &Object
		|
		|GROUP BY
		|	OBEntryARAPPartnersARAPAccounting.Ref.BusinessOperation,
		|	ARAPObjects.ARAPCurrency,
		|	ARAPObjects.PaymentType_";
	Selection = Query.Execute().Select();
	If AmountPaid > AmountShipped Then
		If Selection.Next()Then
			If ValueIsFilled(Selection.BusinessOperation)
				And Selection.Count() = 1
				And (Selection.BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer
					Or Selection.BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor)
				And Selection.Sum = AmountPaid - AmountShipped Then
				Result.TooltipColor = New Color;
				Result.ToolTipText = NStr("vi = 'nhập số dư đầu ứng trước theo lịch biểu';
											|ru = 'ввод начальных остатков авансов соответствует графику';
											|en = 'Opening prepayment balance entry matches the schedule'; fa = 'Opening prepayment balance entry matches the schedule';
											|it = 'ввод начальных остатков авансов соответствует графику';
											|pl = 'Opening prepayment balance entry matches the schedule';
											|tr = 'ön ödemelerin açılış bakiyelerinin girişi programa uygundur'");
			ElsIf Not ValueIsFilled(Selection.BusinessOperation) Then
				If Selection.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
					Result.ToolTipText = StrTemplate(NStr("vi = 'cần nhập số dư ứng trước của khách hàng với số tiền %1 %2';
															|ru = 'необходимо ввести остатки аванса клиента на сумму %1 %2';
															|en = 'enter the unmatched prepayment from customer in the amount of %1 %2'; fa = 'enter the unmatched prepayment from customer in the amount of %1 %2';
															|it = 'необходимо ввести остатки аванса клиента на сумму %1 %2';
															|pl = 'enter the unmatched prepayment from customer in the amount of %1 %2';
															|tr = 'müşterinin %1 %2 tutarındaki ön ödeme bakiyesinin girilmesi gerekmektedir'"),
					                                     Format(AmountPaid - AmountShipped, "NFD=2"),
					                                     Selection.ARAPCurrency);
				Else
					Result.ToolTipText = StrTemplate(NStr("vi = 'cần nhập số dư ứng trước cho nhà cung cấp với số tiền %1 %2';
															|ru = 'необходимо ввести остатки аванса поставщику на сумму %1 %2';
															|en = 'enter the unmatched prepayment to vendor in the amount of %1 %2'; fa = 'enter the unmatched prepayment to vendor in the amount of %1 %2';
															|it = 'необходимо ввести остатки аванса поставщику на сумму %1 %2';
															|pl = 'enter the unmatched prepayment to vendor in the amount of %1 %2';
															|tr = 'tedarikçiye olan %1 %2 tutarındaki ön ödeme bakiyesinin girilmesi gerekmektedir'"),
					                                     Format(AmountPaid - AmountShipped, "NFD=2"),
					                                     Selection.ARAPCurrency);
				EndIf;
			EndIf;
		EndIf;
	Else
		If Selection.Next()Then
			If ValueIsFilled(Selection.BusinessOperation)
				And Selection.Count() = 1
				And (Selection.BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable
					Or Selection.BusinessOperation = Enums.BusinessTransactions.OBEntryVendorAccountsPayable)
				And Selection.Sum = AmountShipped - AmountPaid Then
				Result.TooltipColor = New Color;
				Result.ToolTipText = NStr("vi = 'nhập số dư đầu công nợ theo lịch biểu';
											|ru = 'ввод начальных остатков задолженности соответствует графику';
											|en = 'Opening debt balance entry matches the schedule'; fa = 'Opening debt balance entry matches the schedule';
											|it = 'ввод начальных остатков задолженности соответствует графику';
											|pl = 'Opening debt balance entry matches the schedule';
											|tr = 'borç açılış bakiyelerinin girişi programa uygundur'");
			ElsIf Not ValueIsFilled(Selection.BusinessOperation) Then
				If Selection.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
					Result.ToolTipText = StrTemplate(NStr("vi = 'cần nhập số dư đầu công nợ phải thu khách hàng với số tiền %1 %2';
															|ru = 'необходимо ввести остатки задолженности клиента на сумму %1 %2';
															|en = 'enter customer receivables in the amount of %1 %2'; fa = 'enter customer receivables in the amount of %1 %2';
															|it = 'необходимо ввести остатки задолженности клиента на сумму %1 %2';
															|pl = 'enter customer receivables in the amount of %1 %2';
															|tr = 'müşterinin %1 %2 tutarındaki borç bakiyesinin girilmesi gerekmektedir'"),
					                                     Format(AmountShipped - AmountPaid, "NFD=2"),
					                                     Selection.ARAPCurrency);
				Else
					Result.ToolTipText = StrTemplate(NStr("vi = 'cần nhập số dư công nợ phải trả nhà cung cấp với số tiền %1 %2';
															|ru = 'необходимо ввести остатки задолженности поставщику на сумму %1 %2';
															|en = 'enter vendor payables in the amount of %1 %2'; fa = 'enter vendor payables in the amount of %1 %2';
															|it = 'необходимо ввести остатки задолженности поставщику на сумму %1 %2';
															|pl = 'enter vendor payables in the amount of %1 %2';
															|tr = 'tedarikçiye olan %1 %2 tutarındaki borç bakiyesinin girilmesi gerekmektedir'"),
					                                     Format(AmountShipped - AmountPaid, "NFD=2"),
					                                     Selection.ARAPCurrency);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function InStageTableThereAreStagesFromDateOfShipment()
	Return PaymentStepsServerCall.InStageTableThereAreStagesFromDateOfShipment(Object.PaymentScheduleSteps);
EndFunction

&AtServer
Function DefaultShippingDate(CalculateFrom, Formula)
	If PaymentStepsCached.StringOfStagesDependsOnDateOfShipment(CalculateFrom, Formula) Then
		Return DateOfShipment;
	Else
		Return Date(1,1,1);
	EndIf;
EndFunction

&AtServer
Function CalendarDateOfReceipt(DateOfShipment, WeCalculateDateOfShipment = False)
	If WeCalculateDateOfShipment Then
		Return PaymentStepsServerCall.DateByCalendar(Object.Calendar,DateOfShipment,-Object.DeliveryDuration)
	Else
		Return PaymentStepsServerCall.DateByCalendar(Object.Calendar,DateOfShipment,Object.DeliveryDuration)
	EndIf;
EndFunction

&AtServer
Procedure ReFillInDatesAccordingToScheduleAndPaymentDates()
	
	If Object.DeliveryDuration <> 0 Then
		For Each LineOfExecution In Object.ContractScheduleSteps Do
			If ValueIsFilled(Object.Calendar) Then
				LineOfExecution.DateAccordingToSchedule = CalendarDateOfReceipt(LineOfExecution.DateOfShipment);
			Else
				LineOfExecution.DateAccordingToSchedule = LineOfExecution.DateOfShipment + 86400 * Object.DeliveryDuration;
			EndIf;
		EndDo;
	EndIf;
	
	For Each PaymentLine_ In Object.PaymentScheduleSteps Do
		If PaymentLine_.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfReceipt") Then
			ParametersStructure = PaymentStepsClientServer.PaymentDateCalculationParameters();
			ParametersStructure.OrderDate                     = ContractDate_;
			ParametersStructure.ApprovalDate               = ContractDate_;
			ParametersStructure.DateOfShipment                   = PaymentLine_.DateOfShipment;
			If Object.DeliveryDuration = 0 Then
				ParametersStructure.DateOfReceipt                = PaymentLine_.DateOfShipment;
			ElsIf ValueIsFilled(Object.Calendar) Then
				ParametersStructure.DateOfReceipt                = CalendarDateOfReceipt(PaymentLine_.DateOfShipment);
			Else
				ParametersStructure.DateOfReceipt                = PaymentLine_.DateOfShipment + 86400 * Object.DeliveryDuration;
			EndIf;
			ParametersStructure.DateOfTransferOfTitleToGoods = Date(1,1,1);
			ParametersStructure.DeadlineOfTransferOfTitleToGoods = Object.DeliveryDuration;
			ParametersStructure.Calendar                      = Object.Calendar;
			ParametersStructure.CalculateFrom                 = PaymentLine_.CalculateFrom;
			ParametersStructure.Formula                        = PaymentLine_.Formula;
			ParametersStructure.Move                          = PaymentLine_.Move;
			ParametersStructure.PaymentDate                    = PaymentLine_.PaymentDate;
			
			If ValueIsFilled(ParametersStructure.Calendar) Then
				PaymentLine_.PaymentDate = PaymentStepsServerCall.PaymentDateByCalendar(ParametersStructure);
			Else
				PaymentLine_.PaymentDate = PaymentStepsServerCall.PaymentDateWithoutCalendar(ParametersStructure);
			EndIf;
			
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure DeferredPaymentModeOnChangeServer()
	If DeferredPaymentMode Then
		FillProductionCalendarOnServer()
	Else
		Object.Calendar = PredefinedValue("Catalog.BusinessCalendars.EmptyRef");
	EndIf;
	
	ReFillInDatesAccordingToScheduleAndPaymentDates();
EndProcedure

#EndRegion
