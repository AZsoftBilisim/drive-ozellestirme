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
	
	UseSimplifiedPaymentSchemeInPurchasing = GetFunctionalOption("UseSimplifiedPaymentSchemeInPurchasing");
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Parameters.Organization);
	CalledFormID = Parameters.UUID;
	
	If Not UseNegativePaymentAmounts Then
		LimitTypeOfPaymentAmountElements();
	EndIf;
	
	Parameters.CloseOnChoice            = True;
	Parameters.CloseOnOwnerClose = False;
	FillPropertyValues(ThisObject, Parameters);
	
	If ValueIsFilled(Parameters.AddressInTempStorage) Then
		PaymentScheduleSteps.Load(GetFromTempStorage(Parameters.AddressInTempStorage));
		DeleteFromTempStorage(Parameters.AddressInTempStorage);
	EndIf;
	
	If ValueIsFilled(Parameters.AddressOfOrderAmounts) Then
		DocumentTable = GetFromTempStorage(Parameters.AddressOfOrderAmounts);
		TabularSection.Load(DocumentTable);
		DeleteFromTempStorage(Parameters.AddressOfOrderAmounts);
	EndIf;
	
	VariousDates = PaymentStepsServer.VariousDates(TabularSection);
	MultipleShippingDates = VariousDates.ShippingDates.Count() > 1;
	If VariousDates.ShippingDates.Count() = 1 Then
		DateOfShipment = VariousDates.ShippingDates[0];
	EndIf;
	
	If VariousDates.DatesOfReceipt.Count() = 1 Then
		DateOfReceipt = VariousDates.DatesOfReceipt[0];
	EndIf;
	
	If ThisIsOrder And OrderDate = Date(1,1,1) Then
		OrderDate = CurrentSessionDate();
	ElsIf ValueIsFilled(ContractSchedule) And Not ThisIsOrder Then
		OrderDate = Common.ObjectAttributeValue(Contract,"Date");
	ElsIf VariousDates.OrderDates.Count() = 1 Then
		OrderDate = VariousDates.OrderDates[0];
	EndIf;
	
	If VariousDates.ApprovalDates.Count() = 1 Then
		ApprovalDate = VariousDates.ApprovalDates[0];
	EndIf;
	
	If Not GetFunctionalOption("UseTermsOfPurchases") Then
		Terms = Undefined;
	Else
		AgreementScheduleIsFilledIn = PaymentStepsServerCall.AgreementScheduleIsFilledIn(Terms);
	EndIf;
	
	UpdateServiceDetails();
	
	If Not ValueIsFilled(AddressInTempStorage)Then
		OptionForCountingPostpaid = Enums.PaymentDateCalculationOptions.FromShipmentDate;
		OptionOfPostpaidControl = Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt;
		CalculationParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
		CalculationParameters.CalculateFrom = OptionForCountingPostpaid;
		CalculationParameters.PaymentDate = PaymentDate;
		CalculationParameters.DateOfShipment = DateOfShipment;
		CalculationParameters.Calendar = Calendar;
		If ValueIsFilled(PaymentDate) And ValueIsFilled(DateOfShipment) Then
			If ValueIsFilled(CalculationParameters.Calendar) Then
				PostpaidShift = PaymentStepsServerCall.CalendarShift(CalculationParameters);
			Else
				PostpaidShift = PaymentStepsServerCall.ShiftWithoutCalendar(CalculationParameters);
			EndIf;
			If PostpaidShift < 0 Then
				PostpaidShift = 0;
				CalculationParameters.Move = 0;
				
				If ValueIsFilled(Calendar) Then
					DateCredit = PaymentStepsServerCall.PaymentDateByCalendar(CalculationParameters);
				Else
					DateCredit = PaymentStepsServerCall.PaymentDateWithoutCalendar(CalculationParameters);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	ConfigureFormElementsByParameters();
	SetTextOfFillButton(ThisObject);
	
	If Parameters.AttributeSelectionParameters <> Undefined Then
		For Each EmailSettings In Parameters.AttributeSelectionParameters Do
			TMCommonUseClientServer.SetFormItemProperty(Items, EmailSettings.Key, "ChoiceParameters", EmailSettings.Value);
		EndDo;
	EndIf;
	
	FillInPaymentFormSelectionList();
	SetAvailabilityOfItemsByPaymentForm();
	SetAvailabilityOfElementsByReferenceOption();
	
	CalculateTotals_(ThisObject);
	
	WindowOptionsKey = String(New UUID);
	
	SetElementPropertiesCalculationOrder();
	
	CheckAdjustmentsToSettlementSchedules(Parameters.Key);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ClosingInProgress = False;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
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

&AtClient
Procedure ARAPObjectSettingsOnChange(Item)
	
	ARAPObjectSettingsOnChangeServer();
	
EndProcedure

&AtClient
Procedure PaymentMethodOnChange(Item)
	
	WhenChangingPaymentFormServer();
	
EndProcedure

&AtClient
Procedure PaymentAmountPrepaymentOnChange(Item)
	
	PaymentAmountOnChange(PaymentAmountPrepayment, PaymentPercentagePrepayment, 
							PaymentAmountCredit, PercentageOfPaymentCredit, PaymentAmountAgainstTheDocument);
	
EndProcedure

&AtClient
Procedure PaymentPercentagePrepaymentOnChange(Item)
	
	PaymentPercentageOnChange(PaymentAmountPrepayment, PaymentPercentagePrepayment,
								PaymentAmountCredit, PercentageOfPaymentCredit, PaymentAmountAgainstTheDocument);
	
EndProcedure

&AtClient
Procedure DepositAmountForPackagingPrepaymentOnChange(Item)
	
	PaymentAmountOnChange(DepositAmountForPackagingPrepayment, PercentageOfTheDepositForTheContainerPrepayment, 
							TheAmountOfTheDepositForTheContainerLoan, ThePercentageOfTheDepositForTheContainerLoan, DepositAmountUnderTheDocument);
	
EndProcedure

&AtClient
Procedure PercentageOfTheDepositForTheContainerPrepaymentOnChange(Item)
	
	PaymentPercentageOnChange(DepositAmountForPackagingPrepayment, PercentageOfTheDepositForTheContainerPrepayment, 
							TheAmountOfTheDepositForTheContainerLoan, ThePercentageOfTheDepositForTheContainerLoan, DepositAmountUnderTheDocument);
	
EndProcedure

&AtClient
Procedure PaymentAmountCreditOnChange(Item)
	
	PaymentAmountOnChange(PaymentAmountCredit, PercentageOfPaymentCredit, 
							PaymentAmountPrepayment, PaymentPercentagePrepayment, PaymentAmountAgainstTheDocument);
	
EndProcedure

&AtClient
Procedure PercentageOfPaymentCreditOnChange(Item)
	
	PaymentPercentageOnChange(PaymentAmountCredit, PercentageOfPaymentCredit, 
							PaymentAmountPrepayment, PaymentPercentagePrepayment, PaymentAmountAgainstTheDocument);
	
EndProcedure

&AtClient
Procedure TheAmountOfTheDepositForTheContainerLoanOnChange(Item)
	
	PaymentAmountOnChange(TheAmountOfTheDepositForTheContainerLoan, ThePercentageOfTheDepositForTheContainerLoan,
							DepositAmountForPackagingPrepayment, PercentageOfTheDepositForTheContainerPrepayment, DepositAmountUnderTheDocument);
	
EndProcedure

&AtClient
Procedure ThePercentageOfTheDepositForTheContainerLoanOnChange(Item)
	
	PaymentPercentageOnChange(TheAmountOfTheDepositForTheContainerLoan, ThePercentageOfTheDepositForTheContainerLoan,
							DepositAmountForPackagingPrepayment, PercentageOfTheDepositForTheContainerPrepayment, DepositAmountUnderTheDocument);
	
EndProcedure

&AtClient
Procedure ShiftPrepaymentOnChange(Item)
	
	Structure = New Structure;
	Structure.Insert("PaymentDate",    Date(1,1,1));
	Structure.Insert("Move",          ShiftPrepayment);
	Structure.Insert("CalculateFrom", CountdownOptionPrepayment);
	Structure.Insert("PaymentOption",  PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt"));
	Structure.Insert("Formula",        Undefined);
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = OrderDate;
	ParametersForFillingInPaymentDate.ApprovalDate               = ApprovalDate;
	ParametersForFillingInPaymentDate.DateOfShipment                   = DateOfShipment;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		Structure,ParametersForFillingInPaymentDate);
	
	DatePrepayment = Structure.PaymentDate;
	
EndProcedure

&AtClient
Procedure ReferenceControlledOptionOnChange(Item)
	
	If CountdownOptionPrepayment = PredefinedValue("Enum.PaymentDateCalculationOptions.FixedDate") Then
		ShiftPrepayment = 0;
	EndIf;
	SetAvailabilityOfElementsByReferenceOption();
	
	Structure = New Structure;
	Structure.Insert("PaymentDate",    DatePrepayment);
	Structure.Insert("Move",          ShiftPrepayment);
	Structure.Insert("CalculateFrom", CountdownOptionPrepayment);
	Structure.Insert("PaymentOption",  PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt"));
	Structure.Insert("Formula",        Undefined);
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = OrderDate;
	ParametersForFillingInPaymentDate.ApprovalDate               = ApprovalDate;
	ParametersForFillingInPaymentDate.DateOfShipment                   = DateOfShipment;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		Structure,ParametersForFillingInPaymentDate);
	
	DatePrepayment = Structure.PaymentDate;
	
EndProcedure

&AtClient
Procedure DatePrepaymentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Structure = New Structure;
	Structure.Insert("PaymentDate",    DatePrepayment);
	Structure.Insert("Move",          0);
	Structure.Insert("CalculateFrom", CountdownOptionPrepayment);
	Structure.Insert("PaymentOption", PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt"));
	Structure.Insert("Formula",        Undefined);
	
	ShiftFillParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ShiftFillParameters.OrderDate                     = OrderDate;
	ShiftFillParameters.ApprovalDate               = ApprovalDate;
	ShiftFillParameters.DateOfShipment                   = DateOfShipment;
	ShiftFillParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ShiftFillParameters.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ShiftFillParameters.Calendar                      = Calendar;
	
	PaymentStepsClient.PaymentScheduleStepsPaymentDateOnChange(
		Structure,ShiftFillParameters);
	
	ShiftPrepayment = Structure.Move;
	
EndProcedure

&AtClient
Procedure PostpaidShiftOnChange(Item)
	
	Structure = New Structure;
	Structure.Insert("PaymentDate",    Date(1,1,1));
	Structure.Insert("Move",          PostpaidShift);
	Structure.Insert("CalculateFrom", OptionForCountingPostpaid);
	Structure.Insert("PaymentOption",  PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterReceipt"));
	Structure.Insert("Formula",        Undefined);
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = OrderDate;
	ParametersForFillingInPaymentDate.ApprovalDate               = ApprovalDate;
	ParametersForFillingInPaymentDate.DateOfShipment                   = DateOfShipment;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		Structure,ParametersForFillingInPaymentDate);
	
	DateCredit = Structure.PaymentDate;
	
EndProcedure

&AtClient
Procedure ReferenceOptionIsNotControlledOnChange(Item)
	
	If OptionForCountingPostpaid = PredefinedValue("Enum.PaymentDateCalculationOptions.FixedDate") Then
		PostpaidShift = 0;
	EndIf;
	SetAvailabilityOfElementsByReferenceOption();
	
	Structure = New Structure;
	Structure.Insert("PaymentDate",    DateCredit);
	Structure.Insert("Move",          PostpaidShift);
	Structure.Insert("CalculateFrom", OptionForCountingPostpaid);
	Structure.Insert("PaymentOption",  PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterReceipt"));
	Structure.Insert("Formula",        Undefined);
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = OrderDate;
	ParametersForFillingInPaymentDate.ApprovalDate               = ApprovalDate;
	ParametersForFillingInPaymentDate.DateOfShipment                   = DateOfShipment;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		Structure,ParametersForFillingInPaymentDate);
	
	DateCredit = Structure.PaymentDate;
	
EndProcedure

&AtClient
Procedure DateCreditOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Structure = New Structure;
	Structure.Insert("PaymentDate",    DateCredit);
	Structure.Insert("Move",          0);
	Structure.Insert("CalculateFrom", OptionForCountingPostpaid);
	Structure.Insert("PaymentOption", PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterReceipt"));
	Structure.Insert("Formula",        Undefined);
	
	ShiftFillParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ShiftFillParameters.OrderDate                     = OrderDate;
	ShiftFillParameters.ApprovalDate               = ApprovalDate;
	ShiftFillParameters.DateOfShipment                   = DateOfShipment;
	ShiftFillParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ShiftFillParameters.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ShiftFillParameters.Calendar                      = Calendar;
	
	PaymentStepsClient.PaymentScheduleStepsPaymentDateOnChange(
		Structure,ShiftFillParameters);
	
	PostpaidShift = Structure.Move;
	
EndProcedure

&AtClient
Procedure ForeignCurrencyTransactionOnChange(Item)
	
	IfYouChangePaymentInServerCurrency();
	
EndProcedure

&AtClient
Procedure InscriptionPaymentSBPURLProcessing(Item, FormattedStringURL, StandardProcessing)

	ClearMessages();
	StandardProcessing = False;
	
	If Not ValueIsFilled(Key) Then
		
		MessageText = NStr("ru = 'Необходимо записать документ.';
							|vi = 'Save the document.';
							|en = 'Save the document.'; fa = 'Save the document.';
							|it = 'Save the document.';
							|pl = 'Save the document.';
							|tr = 'Belgenin kaydedilmesi gerekmektedir.'");
		CommonClient.MessageToUser(MessageText);
		
	Else
		CashClientLocalization.ProcessingOfNavigationLinkSBP(
			ThisObject, Key, FormattedStringURL);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentScheduleSteps

&AtClient
Procedure PaymentScheduleStepsAfterDeleteRow(Item)
	
	SortPaymentStages();
	CalculateTotals_(ThisObject);
	ThereAreManualChangesToPaymentSchedule = True;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsOnEditEnd(Item, NewRow, CancelEdit)
	
	SortPaymentStages();
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsPaymentPercentageOnChange(Item)

	PaymentStepsClient.PaymentScheduleStepsPaymentPercentageOnChange(
		Items.PaymentScheduleSteps.CurrentData,
		PaymentScheduleSteps,
		PaymentAmountAgainstTheDocument);
	
	ThereAreManualChangesToPaymentSchedule = True;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsPaymentAmountOnChange(Item)

	PaymentStepsClient.PaymentScheduleStepsPaymentAmountOnChange(
		Items.PaymentScheduleSteps.CurrentData,
		PaymentScheduleSteps,
		PaymentAmountAgainstTheDocument);
	
	ThereAreManualChangesToPaymentSchedule = True;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsPackageDepositPercentageOnChange(Item)

	PaymentStepsClient.PaymentScheduleStepsPackageDepositPercentageOnChange(
		Items.PaymentScheduleSteps.CurrentData,
		PaymentScheduleSteps,
		DepositAmountUnderTheDocument);
	
	ThereAreManualChangesToPaymentSchedule = True;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsPackageDepositValueOnChange(Item)

	PaymentStepsClient.PaymentScheduleStepsPackageDepositValueOnChange(
		Items.PaymentScheduleSteps.CurrentData,
		PaymentScheduleSteps,
		DepositAmountUnderTheDocument);
	
	ThereAreManualChangesToPaymentSchedule = True;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsMoveOnChange(Item)
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	If ValueIsFilled(CurrentData.OrderDocument) Then
		OrderLines_ = TabularSection.FindRows(New Structure("OrderDocument", CurrentData.OrderDocument));
		If OrderLines_.Count() > 0 Then
			OrderDate = OrderLines_[0].OrderDate;
			ApprovalDate = OrderLines_[0].ApprovalDate;
		EndIf;
	EndIf;
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = OrderDate;
	ParametersForFillingInPaymentDate.ApprovalDate               = ApprovalDate;
	ParametersForFillingInPaymentDate.DateOfShipment                   = DateOfShipment;
	ParametersForFillingInPaymentDate.DateOfReceipt                = DateOfReceipt;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		Items.PaymentScheduleSteps.CurrentData,ParametersForFillingInPaymentDate);
	
	ThereAreManualChangesToPaymentSchedule = True;
	
	SortPaymentStages();
	
EndProcedure

&AtClient
Procedure StagesOfPaymentScheduleControlOptionForChanges(Item)
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	If ValueIsFilled(CurrentData.OrderDocument) Then
		OrderLines_ = TabularSection.FindRows(New Structure("OrderDocument", CurrentData.OrderDocument));
		If OrderLines_.Count() > 0 Then
			OrderDate = OrderLines_[0].OrderDate;
			ApprovalDate = OrderLines_[0].ApprovalDate;
		EndIf;
	EndIf;
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = OrderDate;
	ParametersForFillingInPaymentDate.ApprovalDate               = ApprovalDate;
	ParametersForFillingInPaymentDate.DateOfShipment                   = DateOfShipment;
	ParametersForFillingInPaymentDate.DateOfReceipt                = DateOfReceipt;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleControlOptionForChanges(
		CurrentData,ParametersForFillingInPaymentDate);
	
	ThereAreManualChangesToPaymentSchedule = True;
	
	SortPaymentStages();
	
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
		CalculatePaymentDateONChangingReferenceOption();
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentStagesReferenceOptionOnChangeCompletion(Result, AdditionalParameters) Export
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrentData.Formula = Result;
	
	CalculatePaymentDateONChangingReferenceOption();
	
EndProcedure

&AtClient
Procedure CalculatePaymentDateONChangingReferenceOption()
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	If ValueIsFilled(CurrentData.OrderDocument) Then
		OrderLines_ = TabularSection.FindRows(New Structure("OrderDocument", CurrentData.OrderDocument));
		If OrderLines_.Count() > 0 Then
			OrderDate = OrderLines_[0].OrderDate;
			ApprovalDate = OrderLines_[0].ApprovalDate;
		EndIf;
	EndIf;
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = OrderDate;
	ParametersForFillingInPaymentDate.ApprovalDate               = ApprovalDate;
	ParametersForFillingInPaymentDate.DateOfShipment                   = DateOfShipment;
	ParametersForFillingInPaymentDate.DateOfReceipt                = DateOfReceipt;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		CurrentData,ParametersForFillingInPaymentDate);
	
	SortPaymentStages();
	
	ThereAreManualChangesToPaymentSchedule = True;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsPaymentDateOnChange(Item)
	
	CurrentData = Items.PaymentScheduleSteps.CurrentData;
	
	If ValueIsFilled(CurrentData.OrderDocument) Then
		OrderLines_ = TabularSection.FindRows(New Structure("OrderDocument", CurrentData.OrderDocument));
		If OrderLines_.Count() > 0 Then
			OrderDate = OrderLines_[0].OrderDate;
			ApprovalDate = OrderLines_[0].ApprovalDate;
		EndIf;
	EndIf;
	
	ShiftFillParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ShiftFillParameters.OrderDate                     = OrderDate;
	ShiftFillParameters.ApprovalDate               = ApprovalDate;
	ShiftFillParameters.DateOfShipment                   = DateOfShipment;
	ShiftFillParameters.DateOfReceipt                = DateOfReceipt;
	ShiftFillParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ShiftFillParameters.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ShiftFillParameters.Calendar                      = Calendar;
	
	PaymentStepsClient.PaymentScheduleStepsPaymentDateOnChange(
		CurrentData,ShiftFillParameters);
	
	ThereAreManualChangesToPaymentSchedule = True;
	
	SortPaymentStages();
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Notification = New CallbackDescription("PaymentScheduleStepsBeforeAddRowCompletion", ThisObject);
	
	EditParameters = EditParameters();
	
	PaymentStepsClient.PaymentScheduleStepsBeforeAddRow(ThisObject,
		EditParameters,
		Cancel,
		Copy,
		Notification);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsBeforeAddRowCompletion(Result, Var_Parameters) Export
	
	If Result <> Undefined Then
		CollapsePaymentStages();
		SortPaymentStages();
		CalculateTotals_(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsBeforeDeleteRow(Item, Cancel)
	
	PaymentStepsClient.PaymentScheduleStepsBeforeDeleteRow(ThisObject, Cancel, PaymentScheduleSteps);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsBeforeRowChange(Item, Cancel)
	
	Notification = New CallbackDescription("PaymentScheduleStepsBeforeRowChangeCompletion", ThisObject);
	
	EditParameters = EditParameters();
	
	PaymentStepsClient.PaymentScheduleStepsBeforeRowChange(ThisObject,
		EditParameters,
		Cancel,
		Notification);
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsBeforeRowChangeCompletion(Result, Var_Parameters) Export
	
	If Result <> Undefined Then
		CollapsePaymentStages();
		SortPaymentStages();
		CalculateTotals_(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillByDefault()
	
	ClearMessages();
	
	FillInPaymentScheduleSteps();
	
EndProcedure

&AtClient
Procedure FillInTheScheduleStepsByPreviousOrders(Command)
	
	ClearMessages();
	
	If SimplifiedMode Then
		PaymentStagesNotFilledIn = PaymentAmountPrepayment = 0 And PaymentAmountCredit = 0 And DepositAmountForPackagingPrepayment = 0 And TheAmountOfTheDepositForTheContainerLoan = 0;
	Else
		PaymentStagesNotFilledIn = PaymentScheduleSteps.Count() = 0;
	EndIf;
	
	If PaymentAmountAgainstTheDocument = 0 And DepositAmountUnderTheDocument = 0 Then
		
		If PaymentStagesNotFilledIn Then
			ShowMessageBox(Undefined, NStr("vi = 'Số tiền của dòng đã đặt hàng bằng 0. Không cần điền giai đoạn thanh toán.';
											|ru = 'Сумма заказанных строк нулевая. Заполнение этапов оплаты не требуется.';
											|en = 'Amount of order lines is zero. It is not required to fill in payment milestones.'; fa = 'Amount of order lines is zero. It is not required to fill in payment milestones.';
											|it = 'La somma delle righe ordinate è nulla. La compilazione delle fasi del pagamento non è richiesta.';
											|pl = 'Wartość zamówionych wierszy jest zerowa. Wypełnienie etapów płatności nie jest wymagane.';
											|tr = 'Sipariş edilen satırların toplamı sıfırdır. Ödeme aşamalarının tamamlanmasına gerek yoktur.'"));
			Return;
		EndIf;
		
		PaymentScheduleSteps.Clear();
		ClearSimplifiedModeData(ThisObject);
		PaymentStepsClient.NotifyAboutImpossibilityOfFillingInStagesOfPaymentSchedule();
		CalculateTotals_(ThisObject);
		Return;
		
	EndIf;
	
	DocumentsCount = FillInChartTemplates();
	ScheduleCode = Undefined;
	
	If ChartTemplates.Count() > 1 Then
		
		TemplateTableAddress = PutGraphTemplatesInTemporaryStorage();
		OpenForm(
			"Document.PurchaseOrder.Form.SelectionFormOfScheduleFromPreviousOrders", 
			New Structure("TemplateTableAddress, DocumentsCount", TemplateTableAddress, DocumentsCount),,,,, New CallbackDescription("FillInStagesOfScheduleForPreviousOrdersAfterSelection", ThisObject), FormWindowOpeningMode.LockWholeInterface);
		Return;
		
	ElsIf ChartTemplates.Count() = 1 Then
		
		ScheduleCode = ChartTemplates[0].ScheduleCode;
		
	Else
		
		MessageText = NStr("vi = 'Đối với nhà cung cấp ""%Vendor%"" không có đơn hàng đã kết chuyển. Việc điền các giai đoạn bị hủy bỏ.';
							|ru = 'Для поставщика ""%Vendor%"", нет проведенных заказов. Заполнение этапов отменено.';
							|en = 'No posted orders for the ""%Vendor%"" vendor. Stage population is canceled.'; fa = 'No posted orders for the ""%Vendor%"" vendor. Stage population is canceled.';
							|it = 'Per il fornitore ""%Vendor%"" non ci sono ordini condotti. La compilazione delle fasi è stata annullata.';
							|pl = 'Brak zatwierdzonych zamówień dla dostawcy ""%Vendor%"". Wypełnienie etapów jest anulowane.';
							|tr = '""%Vendor%"" tedarikçisi için kaydedilen sipariş mevcut değil. Aşamaların dolumu iptal edildi.'");
		MessageText = StrReplace(MessageText, "%Vendor%", Partner);
		ShowMessageBox(New CallbackDescription("FillInTheScheduleStepsByPreviousOrdersCompletion", ThisObject, New Structure("ScheduleCode", ScheduleCode)), MessageText);
		Return;
		
	EndIf;
	
	FillInStagesOfScheduleForPreviousOrdersFragment(ScheduleCode);
EndProcedure

&AtClient
Procedure FillInStagesOfScheduleForPreviousOrdersAfterSelection(Result, AdditionalParameters) Export
	ScheduleCode = Result;
	FillInStagesOfScheduleForPreviousOrdersFragment(ScheduleCode);
EndProcedure

&AtClient
Procedure FillInTheScheduleStepsByPreviousOrdersCompletion(AdditionalParameters) Export
	ScheduleCode = AdditionalParameters.ScheduleCode;
	FillInStagesOfScheduleForPreviousOrdersFragment(ScheduleCode);
EndProcedure

&AtClient
Procedure FillInStagesOfScheduleForPreviousOrdersFragment(Val ScheduleCode)
	If ScheduleCode <> Undefined Then
		Modified = True;
		FillInStagesOfPaymentScheduleUsingTemplate(ScheduleCode);
		PaymentStepsClient.NotifyEndOfFillingInStagesOfPaymentSchedule();
		SortPaymentStages();
		CalculateTotals_(ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure DivideAmount(Command)
	
	ClearMessages();
	
	DistributeAmountByStagesOfPaymentSchedule();
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If Not Modified Or ReadOnly Then
		
		Close();
		
	Else
		
		ObjectStructure = New Structure;
		ObjectStructure.Insert("ARAPObjectSettings",           ARAPObjectSettings);
		ObjectStructure.Insert("PaymentMethod",               PaymentMethod);
		ObjectStructure.Insert("CashAccount",                     CashAccount);
		ObjectStructure.Insert("CompanyBankAccount", BankAccount);
		ObjectStructure.Insert("ForeignCurrencyTransaction",             ForeignCurrencyTransaction);
		ObjectStructure.Insert("ThereAreManualChangesToPaymentSchedule", ThereAreManualChangesToPaymentSchedule);
		
		If ItIsAllowedToChangeUIP Then
			ObjectStructure.Insert("PaymentID", PaymentID);
		EndIf;
		
		If SimplifiedMode Then
			
			SkipCheck = ThisIsOrder 
								And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")
									Or ValueIsFilled(ContractSchedule) 
										And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts")
											Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice")));
			
			ErrorText = "";
			
			If SimplifiedMode And PaymentAmountAgainstTheDocument + DepositAmountUnderTheDocument > 0 And Not SkipCheck Then
				If Not ValueIsFilled(DatePrepayment) And Not ValueIsFilled(DateCredit) And PaymentAmountAgainstTheDocument <> 0 Then
					ErrorText = NStr("vi = 'Chưa điền trường ""Ngày thanh toán""';
									|ru = 'Поле ""Дата платежа"" не заполнено';
									|en = '""Payment date"" is required'; fa = '""Payment date"" is required';
									|it = 'Il campo ""Data del pagamento"" non è compilato';
									|pl = 'Pole ""Data płatności"" nie jest wypełnione';
									|tr = '""Ödeme tarihi"" alanı doldurulmadı'");
					ErrorField = "DateCredit";
				ElsIf Not ValueIsFilled(CountdownOptionPrepayment) And Not ValueIsFilled(OptionForCountingPostpaid) And PaymentAmountAgainstTheDocument <> 0 Then
					ErrorText = NStr("vi = 'Chưa điền trường ""Phương án đếm ngược""';
									|ru = 'Поле ""Вариант отсчета"" не заполнено';
									|en = 'The ""Calculate from"" field is not filled in'; fa = 'The ""Calculate from"" field is not filled in';
									|it = 'Campo ""Variante di calcolo"" non compilato';
									|pl = 'Nie wypełniono pola ""Wariant odliczenia""';
									|tr = '""Rapor seçeneği"" alanı doldurulmadı'");
					ErrorField = "OptionForCountingPostpaid";
				ElsIf Not ValueIsFilled(DatePrepayment) And PaymentAmountPrepayment + DepositAmountForPackagingPrepayment > 0 Then
					ErrorText = NStr("vi = 'Chưa điền trường ""Ngày thanh toán""';
									|ru = 'Поле ""Дата платежа"" не заполнено';
									|en = '""Payment date"" is required'; fa = '""Payment date"" is required';
									|it = 'Il campo ""Data del pagamento"" non è compilato';
									|pl = 'Pole ""Data płatności"" nie jest wypełnione';
									|tr = '""Ödeme tarihi"" alanı doldurulmadı'");
					ErrorField = "DatePrepayment";
				ElsIf Not ValueIsFilled(CountdownOptionPrepayment) And PaymentAmountPrepayment + DepositAmountForPackagingPrepayment > 0 Then
					ErrorText = NStr("vi = 'Chưa điền trường ""Phương án đếm ngược""';
									|ru = 'Поле ""Вариант отсчета"" не заполнено';
									|en = 'The ""Calculate from"" field is not filled in'; fa = 'The ""Calculate from"" field is not filled in';
									|it = 'Campo ""Variante di calcolo"" non compilato';
									|pl = 'Nie wypełniono pola ""Wariant odliczenia""';
									|tr = '""Rapor seçeneği"" alanı doldurulmadı'");
					ErrorField = "CountdownOptionPrepayment";
				ElsIf ValueIsFilled(DateOfShipment) And DatePrepayment > DateOfShipment Then
					ErrorText = NStr("vi = 'Ngày thanh toán trước khi giao hàng không được lớn hơn ngày giao hàng %DateOfShipment%';
									|ru = 'Дата платежа до отгрузки должна быть не больше даты отгрузки %DateOfShipment%';
									|en = 'Date of payment before shipment must be earlier than shipment date %DateOfShipment%'; fa = 'Date of payment before shipment must be earlier than shipment date %DateOfShipment%';
									|it = 'La data del pagamento prima della spedizione non deve essere successiva alla data di spedizione %DateOfShipment%';
									|pl = 'Data płatności do wysyłki powinna być nie większa niż data wysyłki %DateOfShipment%';
									|tr = 'Sevkiyattan önceki ödeme tarihi, sevkiyat tarihinden eski olmamalıdır %DateOfShipment%'");
					ErrorText = StrReplace(ErrorText,"%DateOfShipment%", Format(DateOfShipment, "DLF=DD"));
					ErrorField = "DatePrepayment";
				ElsIf DatePrepayment < OrderDate And PaymentAmountPrepayment + DepositAmountForPackagingPrepayment > 0 And ThisIsOrder Then
					ErrorText = NStr("vi = 'Ngày thanh toán trước khi giao hàng không được nhỏ hơn ngày chứng từ %OrderDate%';
									|ru = 'Дата платежа до отгрузки должна быть не меньше даты документа %OrderDate%';
									|en = 'The payment date before shipment cannot be earlier than the document date %OrderDate%'; fa = 'The payment date before shipment cannot be earlier than the document date %OrderDate%';
									|it = 'Дата платежа до отгрузки должна быть не меньше даты документа %OrderDate%';
									|pl = 'The payment date before shipment cannot be earlier than the document date %OrderDate%';
									|tr = 'Sevkiyat öncesi ödeme tarihi belgenin tarihinden az olmamalıdır  %OrderDate%'");
					ErrorText = StrReplace(ErrorText,"%OrderDate%", Format(OrderDate, "DLF=DD"));
					ErrorField = "DatePrepayment";
				ElsIf DateCredit < OrderDate And PaymentAmountCredit + TheAmountOfTheDepositForTheContainerLoan > 0 And ThisIsOrder Then
					ErrorText = NStr("vi = 'Ngày thanh toán không được nhỏ hơn ngày chứng từ %OrderDate%';
									|ru = 'Дата платежа должна быть не меньше даты документа %OrderDate%';
									|en = 'The payment date cannot be earlier than the document date %OrderDate%'; fa = 'The payment date cannot be earlier than the document date %OrderDate%';
									|it = 'Дата платежа должна быть не меньше даты документа %OrderDate%';
									|pl = 'The payment date cannot be earlier than the document date %OrderDate%';
									|tr = 'Ödeme tarihi belgenin tarihinden az olmamalıdır %OrderDate%'");
					ErrorText = StrReplace(ErrorText,"%OrderDate%", Format(OrderDate, "DLF=DD"));
					ErrorField = "DateCredit";
				EndIf;
			EndIf;
			
			If ErrorText = "" Then
				ObjectStructure.Insert("PaymentDate", DateCredit);
				ObjectStructure.Insert("Move", PostpaidShift);
				AddressInTempStorage = CheckPaymentPutInStorage();
				If Not IsBlankString(AddressInTempStorage) Then
					Done = True;
					ObjectStructure.Insert("AddressInTempStorage", AddressInTempStorage);
					Close(ObjectStructure);
				EndIf;
			Else
				CommonClient.MessageToUser(ErrorText,, ErrorField);
			EndIf;
		
		Else
			
			AddressInTempStorage = CheckPaymentPutInStorage();
			
			If Not IsBlankString(AddressInTempStorage) Then
				Done = True;
				ObjectStructure.Insert("AddressInTempStorage", AddressInTempStorage);
				Close(ObjectStructure);
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateCredit.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DateCredit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("DatePrepayment");

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.PercentageIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentPercentagePrepayment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentageOfPaymentCredit.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalPaymentPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 100;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PayAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentPercentagePrepayment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentageOfPaymentCredit.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TotalPaymentPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 100;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PayAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DatePrepayment.Name);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentAmountPrepayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PayAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PackageDepositIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepositAmountForPackagingPrepayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepositAmount_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateCredit.Name);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentAmountCredit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PayAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PackageDepositIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheAmountOfTheDepositForTheContainerLoan");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepositAmount_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.LineNumber");
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
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPackageDepositPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.DepositPercentageIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentageOfTheDepositForTheContainerPrepayment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ThePercentageOfTheDepositForTheContainerLoan.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepositPercentageTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 100;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepositAmount_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentageOfTheDepositForTheContainerPrepayment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ThePercentageOfTheDepositForTheContainerLoan.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepositPercentageTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 100;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepositAmount_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPackageDepositPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.LineNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = New DataCompositionField("LineNumberOfDepositFullPayment");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LineNumberOfDepositFullPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPaymentPercentage.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPackageDepositPercentage.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.PaymentPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.PackageDepositPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPackageDepositPercentage.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsPackageDepositValue.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PackageDepositIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	//
	Item = ConditionalAppearance.Items.Add();

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentScheduleStepsCalculateFrom.Name);

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.CalculateFrom");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PaymentDateCalculationOptions.FromOrderDate;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ContractSchedule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	
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

#Region CompletingPaymentScheduleStages

&AtClient
Procedure FillInPaymentScheduleSteps()

	AnswersOptions = New ValueList;
	AnswersOptions.Add(DialogReturnCode.Yes, NStr("vi = 'Điền lại giai đoạn thanh toán';
													|ru = 'Перезаполнить этапы оплаты';
													|en = 'Refill payment milestones'; fa = 'Refill payment milestones';
													|it = 'Ricompilare le fasi del pagamento';
													|pl = 'Ponownie wypełnij etapy płatności';
													|tr = 'Ödeme aşamalarını doldur'"));
	AnswersOptions.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
	
	QueryText = "";
	
	FillParameters = New Structure;
	FillParameters.Insert("ReFillStages", False);
	
	If SimplifiedMode Then
		PaymentAmountByStage    = PaymentAmountPrepayment + PaymentAmountCredit;
		AmountOfCollateralByStages    = DepositAmountForPackagingPrepayment + TheAmountOfTheDepositForTheContainerLoan;
		PaymentStagesNotFilledIn = PaymentAmountPrepayment = 0 And PaymentAmountCredit = 0 And AmountOfCollateralByStages = 0;
	Else
		PaymentAmountByStage    = PaymentScheduleSteps.Total("PaymentAmount");
		AmountOfCollateralByStages    = PaymentScheduleSteps.Total("PackageDepositValue");
		PaymentStagesNotFilledIn = PaymentScheduleSteps.Count() = 0;
	EndIf;
	
	If PaymentAmountAgainstTheDocument = 0 And DepositAmountUnderTheDocument = 0 Then
		
		If PaymentStagesNotFilledIn Then
			
			ShowMessageBox(Undefined, NStr("vi = 'Số tiền tại các dòng chưa hủy của đơn hàng bằng 0. Không cần điền giai đoạn thanh toán.';
											|ru = 'Сумма неотмененных строк заказа нулевая. Заполнение этапов оплаты не требуется.';
											|en = 'Amount of uncanceled order lines is zero. It is not required to fill in payment milestones.'; fa = 'Amount of uncanceled order lines is zero. It is not required to fill in payment milestones.';
											|it = 'La somma delle righe dell''ordine non annullate è nulla. La compilazione delle fasi del pagamento non è richiesta.';
											|pl = 'Wartość nieanulowanych wierszy zamówienia jest zerowa. Wypełnienie etapów płatności nie jest wymagane.';
											|tr = 'İptal edilmemiş sipariş satırlarının toplamı sıfırdır. Ödeme aşamalarını tamamlamaya gerek yoktur.'"));
			Return;
			
		EndIf;
		
		PaymentScheduleSteps.Clear();
		ClearSimplifiedModeData(ThisObject);
		PaymentStepsClient.NotifyAboutImpossibilityOfFillingInStagesOfPaymentSchedule();
		CalculateTotals_(ThisObject);
		Return;
		
	EndIf;
	
	If PaymentAmountAgainstTheDocument = PaymentAmountByStage And DepositAmountUnderTheDocument = AmountOfCollateralByStages Then
		
		QueryText = NStr("vi = 'Số tiền các dòng đã đặt hàng trùng với số tiền của giai đoạn thanh toán';
						|ru = 'Сумма заказанных строк совпадает с суммой этапов оплаты';
						|en = 'Amount of order lines is equal to the amount of payment milestones'; fa = 'Amount of order lines is equal to the amount of payment milestones';
						|it = 'La somma delle righe ordinate coincide con la somma delle fasi del pagamento';
						|pl = 'Wartość zamówionych wierszy równa się wartości etapów płatności';
						|tr = 'Sipariş edilen satırların toplamı, ödeme aşamalarının toplamı ile aynıdır'") + Chars.LF +
							NStr("vi = 'Điền lại giai đoạn thanh toán %SourceOfFilling%?';
								|ru = 'Перезаполнить этапы оплаты %SourceOfFilling%?';
								|en = 'Refill steps of payment %SourceOfFilling%?'; fa = 'Refill steps of payment %SourceOfFilling%?';
								|it = 'Ricompilare le fasi del pagamento %SourceOfFilling%?';
								|pl = 'Wypełnić ponownie etapy płatności %SourceOfFilling%?';
								|tr = 'Ödeme aşamalarını doldur %SourceOfFilling%?'");
		
	ElsIf Not PaymentStagesNotFilledIn Then
		
		AnswersOptions.Insert(1, DialogReturnCode.No, NStr("vi = 'Phân bổ số tiền';
															|ru = 'Распределить сумму';
															|en = 'Allocate amount'; fa = 'تسهیم مبلغ';
															|it = 'Distribuire l''importo';
															|pl = 'Przydziel wartość';
															|tr = 'Tutarı dağıt'"));
		
		QueryText = NStr("vi = 'Đã điền giai đoạn thanh toán';
						|ru = 'Этапы оплаты заполнены';
						|en = 'Payment milestones are filled in'; fa = 'Payment milestones are filled in';
						|it = 'Fasi del pagamento compilate';
						|pl = 'Etapy płatności są wypełnione';
						|tr = 'Ödeme aşamaları dolduruldu'")+ Chars.LF +
							NStr("vi = 'Điền lại giai đoạn thanh toán %SourceOfFilling% hoặc phân bổ số tiền theo các giai đoạn hiện có?';
								|ru = 'Перезаполнить этапы оплаты %SourceOfFilling% или распределить сумму по имеющимся этапам?';
								|en = 'Refill payment milestones %SourceOfFilling% or allocate the amount to steps?'; fa = 'Refill payment milestones %SourceOfFilling% or allocate the amount to steps?';
								|it = 'Ricompilare le fasi del pagamento %SourceOfFilling% o ridistribuire l''importo sulle fasi presenti?';
								|pl = 'Wypełnić ponownie etapy płatności %SourceOfFilling% lub przydzielić wartość według istniejących etapów?';
								|tr = '%SourceOfFilling% ödeme aşamalarını yeniden doldur veya tutarı mevcut aşamalar arasında dağıt?'");
		
	Else
		FillParameters.ReFillStages = True;
	EndIf;
	
	If Not IsBlankString(QueryText) Then
		
		QueryText = StrReplace(QueryText, "%SourceOfFilling%", ?(AgreementScheduleIsFilledIn,NStr("vi = 'theo thỏa thuận';
																									|ru = 'по соглашению';
																									|en = 'by agreement'; fa = 'by agreement';
																									|it = 'secondo l''accordo';
																									|pl = 'według umowy';
																									|tr = 'anlaşmaya göre'"),NStr("vi = 'theo mặc định';
																																|ru = 'по умолчанию';
																																|en = 'default'; fa = 'پیش‌فرض';
																																|it = 'per default';
																																|pl = 'domyślnie';
																																|tr = 'varsayılan'")));
		
		Notification = New CallbackDescription("SelectingFillSourceCompletion", ThisObject, FillParameters);
		ShowQueryBox(Notification, QueryText, AnswersOptions);
		Return;
		
	EndIf;
	
	FillInPaymentScheduleStepsCompletion(FillParameters);
	
EndProcedure

&AtClient
Procedure SelectingFillSourceCompletion(QuestionResult, FillParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillParameters.ReFillStages = True;
	ElsIf QuestionResult = DialogReturnCode.No Then
		FillParameters.ReFillStages = False;
	Else
		Return;
	EndIf;
	
	FillInPaymentScheduleStepsCompletion(FillParameters);

EndProcedure

&AtClient
Procedure FillInPaymentScheduleStepsCompletion(FillParameters)
	
	Modified = True;
	If FillParameters.ReFillStages Then
		
		PaymentScheduleSteps.Clear();
		
		If InvoiceForOrders 
			And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByOrders")
				Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice")
				Or Not ValueIsFilled(ContractSchedule) And ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")) Then
			FillInStagesForOrdersServer();
		Else
			FillInPaymentStages();
		EndIf;
	Else
		If InvoiceForOrders
			And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByOrders")
				Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts") 
					 And Not ValueIsFilled(ContractSchedule)) Then
			DistributeAmountByStagesAndOrdersOfPaymentSchedule ();
		Else
			DistributeAmountByStagesOfPaymentSchedule();
		EndIf;
	EndIf;
	
	PaymentStepsClient.NotifyEndOfFillingInStagesOfPaymentSchedule();
	SortPaymentStages();
	CalculateTotals_(ThisObject);
	SetAvailabilityOfElementsByReferenceOption();
	ThereAreManualChangesToPaymentSchedule = False;
	
EndProcedure

&AtServer
Procedure FillInStagesForOrdersServer()
	
	FillParameters = PaymentStepsServer.ParametersForFillingPaymentStagesForOrders();
	
	FillParameters.TabularSection                  = TabularSection.Unload();
	FillParameters.DateOfShipment                    = DateOfShipment;
	FillParameters.DateOfTransferOfTitleToGoods  = DateOfTransferOfTitleToGoods;
	FillParameters.ThereIsDateOfTransferOfOwnership = ThereIsDateOfTransferOfOwnership;
	FillParameters.Calendar                       = Calendar;
	FillParameters.ARAPObjectSettings                 = ARAPObjectSettings;
	FillParameters.TheseAreSettlementsWithCustomers            = False;
	
	PaymentStepsServer.FillInPaymentStagesOfDocumentForOrders(PaymentScheduleSteps, FillParameters);
		
	If SimplifiedMode Then
		ConvertStageTableToSimplifiedModeData(PaymentScheduleSteps.Unload());
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPaymentStages()
	
	FillParameters = PaymentStepsServer.ParametersForFillingInPaymentStages();
	FillParameters.TheseAreSettlementsWithCustomers            = False;
	FillParameters.InvoiceForOrders              = InvoiceForOrders;
	FillParameters.ARAPObjectSettings                 = ARAPObjectSettings;
	FillParameters.ThisIsOrder                        = ThisIsOrder;
	FillParameters.NoPrepaymentControl           = NoPrepaymentControl;
	FillParameters.DateOfTransferOfTitleToGoods  = DateOfTransferOfTitleToGoods;
	FillParameters.ThereIsDateOfTransferOfOwnership = ThereIsDateOfTransferOfOwnership;
	FillParameters.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	FillParameters.OrderDate = OrderDate;
	FillParameters.ApprovalDate = ApprovalDate;
	FillParameters.AgreementScheduleIsFilledIn = AgreementScheduleIsFilledIn;
	FillParameters.Terms = Terms;
	FillParameters.ContractSchedule = ContractSchedule;
	FillParameters.Calendar = Calendar;
	
	FillParameters.PayAmount                     = PaymentAmountAgainstTheDocument;
	FillParameters.PackageDepositValue               = DepositAmountUnderTheDocument;
	
	If MultipleShippingDates Then
		FillParameters.TabularSection = TabularSection.Unload();
	Else
		FillParameters.DateOfShipment = DateOfShipment;
		FillParameters.DateOfReceipt = DateOfReceipt;
	EndIf;
	
	PaymentStepsServer.FillInPaymentStages(PaymentScheduleSteps, FillParameters);
	
	If SimplifiedMode Then
		ConvertStageTableToSimplifiedModeData(PaymentScheduleSteps.Unload());
	EndIf;
	
EndProcedure

&AtServer
Procedure DistributeAmountByStagesAndOrdersOfPaymentSchedule()
	
	FillParameters = PaymentStepsServer.ParametersForFillingPaymentStagesForOrders();
	
	FillParameters.TabularSection                  = TabularSection.Unload();
	FillParameters.Calendar                       = Calendar;
	FillParameters.DateOfShipment                    = DateOfShipment;
	FillParameters.DateOfTransferOfTitleToGoods  = DateOfTransferOfTitleToGoods;
	FillParameters.ARAPObjectSettings                 = ARAPObjectSettings;
	FillParameters.TheseAreSettlementsWithCustomers            = False;
	
	PaymentStepsServer.DistributeAmountsOfDocumentPaymentStagesByOrders(PaymentScheduleSteps, FillParameters);
	
	If SimplifiedMode Then
		ConvertStageTableToSimplifiedModeData(PaymentScheduleSteps.Unload());
	EndIf;
	
EndProcedure

&AtServer
Procedure DistributeAmountByStagesOfPaymentSchedule()
	
	If SimplifiedMode Then
		
		PaymentSteps = ConvertSimplifiedModeDataToStepTable();
		
		PaymentStepsClientServer.DistributeAmountByStagesOfPaymentSchedule(
			PaymentSteps,
			PaymentAmountAgainstTheDocument,
			DepositAmountUnderTheDocument);
		PaymentStepsServer.FillInInterestOnAmounts(PaymentSteps);
		
		ConvertStageTableToSimplifiedModeData(PaymentSteps);
		
	Else
		
		PaymentStepsClientServer.DistributeAmountByStagesOfPaymentSchedule(
			PaymentScheduleSteps,
			PaymentAmountAgainstTheDocument,
			DepositAmountUnderTheDocument);
		PaymentStepsServer.FillInInterestOnAmounts(PaymentScheduleSteps);
			
	EndIf;
	
EndProcedure

#Region FillingInScheduleForPreviousOrders

&AtServer
Procedure FillInStagesOfPaymentScheduleUsingTemplate(ScheduleCode)
	
	StagesOfSelectedTemplate = TemplateSteps.Unload(New Structure("ScheduleCode", ScheduleCode));
	
	FillParameters = PaymentStepsServer.ParametersForFillingInPaymentStages();
	FillPropertyValues(FillParameters, ThisObject, , "TabularSection");
	FillParameters.PayAmount                     = PaymentAmountAgainstTheDocument;
	FillParameters.PackageDepositValue               = DepositAmountUnderTheDocument;
	FillParameters.ScheduleTemplate                   = StagesOfSelectedTemplate;
	FillParameters.DateOfTransferOfTitleToGoods  = DateOfTransferOfTitleToGoods;
	FillParameters.NoPrepaymentControl           = NoPrepaymentControl;
	FillParameters.TheseAreSettlementsWithCustomers            = False;
	
	PaymentStepsServer.FillInPaymentStagesOfDocumentUsingTemplate(PaymentScheduleSteps, FillParameters);
	
	If SimplifiedMode Then
		ConvertStageTableToSimplifiedModeData(PaymentScheduleSteps.Unload());
	EndIf;
	
EndProcedure

&AtServer
Function GeneratePresentationOfChartTemplate(ArrayOfGraphStages)
	
	GraphView = "";
	
	FormatString = "LB = FALSE";
	NumerationItemOptions=NStr("vi = 'ngày,ngày,ngày,m,ngày,ngày,ngày,m,0';
								|ru = 'день,дня,дней,м,день,дня,дней,м,0';
								|en = 'day, days, day, days, 0'; fa = 'day, days, day, days, 0';
								|it = 'день,дня,дней,м,день,дня,дней,м,0';
								|pl = 'day, days, day, days, 0';
								|tr = 'gün,gün,günler,ay,gün,gün,günler,ay,0'");
	
	StagePresentationTemplate = NStr("ru = '%PaymentPercentage%% (%PostponementIsVariantOfCountdown%) %PaymentOption%';
									|vi = '%PaymentPercentage%% (%PostponementIsVariantOfCountdown%) %PaymentOption%';
									|en = '%PaymentPercentage%% (%PostponementIsVariantOfCountdown%) %PaymentOption%'; fa = '%PaymentPercentage%% (%PostponementIsVariantOfCountdown%) %PaymentOption%';
									|it = '%PaymentPercentage%% (%PostponementIsVariantOfCountdown%) %PaymentOption%';
									|pl = '%PaymentPercentage%% (%PostponementIsVariantOfCountdown%) %PaymentOption%';
									|tr = '%PaymentPercentage%% (%PostponementIsVariantOfCountdown%) %PaymentOption%'");
	
	FirstStage = True;
	
	For Each ScheduleStage In ArrayOfGraphStages Do
		
		If ScheduleStage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt Then
			PaymentOptionText = NStr("vi = 'trước khi tiếp nhận';
									|ru = 'до поступления';
									|en = 'before receipt'; fa = 'before receipt';
									|it = 'prima della ricezione';
									|pl = 'przed wpłatą';
									|tr = 'tahsilata kadar'");
		ElsIf ScheduleStage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation Then
			PaymentOptionText = NStr("vi = 'trước khi xác nhận';
									|ru = 'до подтверждения';
									|en = 'before confirmation'; fa = 'before confirmation';
									|it = 'prima della conferma';
									|pl = 'przed potwierdzeniem';
									|tr = 'onaya kadar'");
		Else
			PaymentOptionText = ""
		EndIf;
		
		ArrayOfTexts = New Array;
		PresentationStage = StrReplace(StagePresentationTemplate, "%PaymentOption%", PaymentOptionText);
		If ScheduleStage.CalculateFrom <> Enums.PaymentDateCalculationOptions.FixedDate Then
			DeferralText = Format(ScheduleStage.Move, "NZ=0; NG=0") + " " + StrReplace(Right(NumberInWords(ScheduleStage.Move, FormatString, NumerationItemOptions), 4)," ", "");
			ArrayOfTexts.Add(DeferralText);
		EndIf;
		PresentationStage = StrReplace(PresentationStage, "%PaymentPercentage%", ScheduleStage.PaymentPercentage);
		ArrayOfTexts.Add(ScheduleStage.CalculateFrom);
		PresentationStage = StrReplace(PresentationStage, "%PostponementIsVariantOfCountdown%", StrConcat(ArrayOfTexts," "));
		
		If FirstStage Then
			FirstStage = False;
			GraphView = GraphView + PresentationStage;
		Else
			GraphView = GraphView + ", " + PresentationStage;
		EndIf;
		
	EndDo;
	
	Return GraphView + ".";
	
EndFunction

&AtServer
Procedure PutGraphInTemplateTable(GraphView,
	                                      ArrayOfGraphStages,
	                                      ScheduleCode,
	                                      DateOfLastUse,
	                                      DocumentOfTheLastUsage)
	
	ChartTableRow = ChartTemplates.Add();
	ChartTableRow.GraphView            = GraphView;
	ChartTableRow.ScheduleCode                      = ScheduleCode;
	ChartTableRow.UsageFrequency            = 1;
	ChartTableRow.DateOfLastUse     = DateOfLastUse;
	ChartTableRow.DocumentOfTheLastUsage = DocumentOfTheLastUsage;
	
	For Each ScheduleStage In ArrayOfGraphStages Do
		
		StageString_ = TemplateSteps.Add();
		FillPropertyValues(StageString_, ScheduleStage);
		StageString_.ScheduleCode = ScheduleCode;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure GenerateQueryTextBasedOnDocumentGraphs(QueryText)
	
	QueryText = 
	"SELECT ALLOWED DISTINCT TOP 50
	|	OrderToSupplierStagesOfPaymentSchedule.Ref AS Ref,
	|	OrderToSupplierStagesOfPaymentSchedule.Ref.Terms AS Terms,
	|	OrderToSupplierStagesOfPaymentSchedule.Ref.Date AS Date,
	|	OrderToSupplierStagesOfPaymentSchedule.Ref.RequestedDeliveryDate AS RequestedDeliveryDate,
	|	OrderToSupplierStagesOfPaymentSchedule.Ref.PointInTime AS PointInTime
	|INTO OrderDocuments
	|FROM
	|	Document.PurchaseOrder.PaymentScheduleSteps AS OrderToSupplierStagesOfPaymentSchedule
	|WHERE
	|	OrderToSupplierStagesOfPaymentSchedule.Ref.DeletionMark = FALSE
	|	AND OrderToSupplierStagesOfPaymentSchedule.Ref.Posted = TRUE
	|	AND OrderToSupplierStagesOfPaymentSchedule.Ref.Partner = &Partner
	|	AND OrderToSupplierStagesOfPaymentSchedule.Ref.Ref <> &LinkToCurOrder
	|	AND OrderToSupplierStagesOfPaymentSchedule.Ref.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PurchaseFromSupplier),
	|		VALUE(Enum.BusinessTransactions.PurchaseByImport)
	|	)
	|
	|UNION ALL
	|
	|SELECT DISTINCT TOP 50
	|	OrderToSupplierStagesOfPaymentSchedule.Ref AS Ref,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	OrderToSupplierStagesOfPaymentSchedule.Ref.Date AS Date,
	|	OrderToSupplierStagesOfPaymentSchedule.Ref.RequestedDeliveryDate AS RequestedDeliveryDate,
	|	OrderToSupplierStagesOfPaymentSchedule.Ref.PointInTime AS PointInTime
	|FROM
	|	Document.SubcontractOrder2_5.PaymentScheduleSteps AS OrderToSupplierStagesOfPaymentSchedule
	|WHERE
	|	OrderToSupplierStagesOfPaymentSchedule.Ref.DeletionMark = FALSE
	|	AND OrderToSupplierStagesOfPaymentSchedule.Ref.Posted = TRUE
	|	AND OrderToSupplierStagesOfPaymentSchedule.Ref.Partner = &Partner
	|	AND OrderToSupplierStagesOfPaymentSchedule.Ref.Ref <> &LinkToCurOrder
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderDocuments.PointInTime AS PointInTime,
	|	OrderToSupplierStagesOfPaymentSchedule.LineNumber AS LineNumber,
	|	OrderDocuments.Ref AS DocumentOfTheLastUsage,
	|	ISNULL(TermsOfPurchaseFromVendors.Calendar, UNDEFINED) AS Calendar,
	|	BEGINOFPERIOD(OrderDocuments.Date, DAY) AS DocumentDate,
	|	BEGINOFPERIOD(OrderDocuments.RequestedDeliveryDate, DAY) AS DateOfReceipt,
	|	BEGINOFPERIOD(OrderToSupplierStagesOfPaymentSchedule.PaymentDate, DAY) AS PaymentDate,
	|	OrderToSupplierStagesOfPaymentSchedule.PaymentOption AS PaymentOption,
	|	OrderToSupplierStagesOfPaymentSchedule.CalculateFrom AS CalculateFrom,
	|	OrderToSupplierStagesOfPaymentSchedule.Formula AS Formula,
	|	OrderToSupplierStagesOfPaymentSchedule.Move AS Move,
	|	OrderToSupplierStagesOfPaymentSchedule.PaymentPercentage AS PaymentPercentage,
	|	OrderToSupplierStagesOfPaymentSchedule.PackageDepositPercentage AS PackageDepositPercentage,
	|	OrderDocuments.Date AS DateOfLastUse
	|FROM
	|	OrderDocuments AS OrderDocuments
	|		INNER JOIN Document.PurchaseOrder.PaymentScheduleSteps AS OrderToSupplierStagesOfPaymentSchedule
	|			ON (OrderToSupplierStagesOfPaymentSchedule.Ref = OrderDocuments.Ref)
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|		ON OrderDocuments.Terms = TermsOfPurchaseFromVendors.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	OrderDocuments.PointInTime AS PointInTime,
	|	OrderToSupplierStagesOfPaymentSchedule.LineNumber AS LineNumber,
	|	OrderDocuments.Ref AS DocumentOfTheLastUsage,
	|	UNDEFINED AS Calendar,
	|	BEGINOFPERIOD(OrderDocuments.Date, DAY) AS DocumentDate,
	|	BEGINOFPERIOD(OrderDocuments.RequestedDeliveryDate, DAY) AS DateOfReceipt,
	|	BEGINOFPERIOD(OrderToSupplierStagesOfPaymentSchedule.PaymentDate, DAY) AS PaymentDate,
	|	OrderToSupplierStagesOfPaymentSchedule.PaymentOption AS PaymentOption,
	|	OrderToSupplierStagesOfPaymentSchedule.CalculateFrom AS CalculateFrom,
	|	OrderToSupplierStagesOfPaymentSchedule.Formula AS Formula,
	|	OrderToSupplierStagesOfPaymentSchedule.Move AS Move,
	|	OrderToSupplierStagesOfPaymentSchedule.PaymentPercentage AS PaymentPercentage,
	|	OrderToSupplierStagesOfPaymentSchedule.PackageDepositPercentage AS PackageDepositPercentage,
	|	OrderDocuments.Date AS DateOfLastUse
	|FROM
	|	OrderDocuments AS OrderDocuments
	|		INNER JOIN Document.SubcontractOrder2_5.PaymentScheduleSteps AS OrderToSupplierStagesOfPaymentSchedule
	|		ON (OrderToSupplierStagesOfPaymentSchedule.Ref = OrderDocuments.Ref)
	|
	|ORDER BY
	|	OrderDocuments.PointInTime,
	|	OrderToSupplierStagesOfPaymentSchedule.LineNumber
	|TOTALS
	|	MAX(Calendar),
	|	COUNT(PaymentOption),
	|	MAX(DateOfLastUse)
	|BY
	|	DocumentOfTheLastUsage
	|";
	
EndProcedure

&AtServer
Function FillInChartTemplates()
	
	ChartTemplates.Clear();
	TemplateSteps.Clear();
	
	Query = New Query;
	GenerateQueryTextBasedOnDocumentGraphs(Query.Text);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("LinkToCurOrder", Key);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return 0;
	EndIf;
	
	CountingCharts = 0;
	
	SampleDocument = Result.Select(QueryResultIteration.ByGroups);
	While SampleDocument.Next() Do
		
		NumberOfScheduleStages = SampleDocument.PaymentOption;
		
		If NumberOfScheduleStages = 0 Then
			Continue;
		EndIf;
		
		NewSchedule_ = New Array();
		SampleGraph = SampleDocument.Select();
		While SampleGraph.Next() Do
			
			StageStructure_ = New Structure("PaymentOption, CalculateFrom, Formula, Move, PaymentPercentage, PackageDepositPercentage");
			FillPropertyValues(StageStructure_, SampleGraph);
			
			NewSchedule_.Add(StageStructure_);
			
		EndDo;
		
		GraphView = GeneratePresentationOfChartTemplate(NewSchedule_);
		LinesOfGraphs = ChartTemplates.FindRows(New Structure("GraphView", GraphView));
		If LinesOfGraphs.Count() = 0 Then
			
			PutGraphInTemplateTable(
				GraphView,
				NewSchedule_,
				CountingCharts,
				SampleDocument.DateOfLastUse,
				SampleDocument.DocumentOfTheLastUsage);
			CountingCharts = CountingCharts + 1;
			
		Else
			
			ChartStructure = LinesOfGraphs[0];
			ChartStructure.UsageFrequency = ChartStructure.UsageFrequency + 1;
			If ChartStructure.DateOfLastUse < SampleDocument.DateOfLastUse Then
				ChartStructure.DateOfLastUse = SampleDocument.DateOfLastUse;
				ChartStructure.DocumentOfTheLastUsage = SampleDocument.DocumentOfTheLastUsage;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ChartTemplates.Sort("UsageFrequency Desc, DateOfLastUse Desc");
	
	Return SampleDocument.Count();
	
EndFunction

#EndRegion

&AtServer
Function CheckPaymentPutInStorage()
	
	If SimplifiedMode Then
		PaymentScheduleSteps.Load(ConvertSimplifiedModeDataToStepTable());
	EndIf;
	
	Cancel = False;
	
	For Each Page1 In PaymentScheduleSteps Do
		DependsOnShipmentDate = PaymentStepsCached.StringOfStagesDependsOnDateOfShipment(Page1.CalculateFrom,Page1.Formula);
		If Not DependsOnShipmentDate And ValueIsFilled(Page1.DateOfShipment) Then
			Page1.DateOfShipment = Date(1,1,1);
		ElsIf DependsOnShipmentDate And ValueIsFilled(DateOfShipment) And Not ValueIsFilled(Page1.DateOfShipment) Then
			Page1.DateOfShipment = DateOfShipment;
		EndIf;
	EndDo;
	
	If Not (ThisIsOrder And ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
		Or ValueIsFilled(ContractSchedule) 
			And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
				Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)) Then
		
		ParametersStructure = PaymentStepsServer.ParametersForCheckingWhetherStagesAreFilledInCorrectly();
		If ThisIsOrder Or InvoiceForOrders Then
			ParametersStructure.Date               = OrderDate;
		Else
			ParametersStructure.Date               = DateOfShipment;
		EndIf;
		ParametersStructure.Currency                 = Currency;
		ParametersStructure.ThisIsOrder               = ThisIsOrder;
		ParametersStructure.InvoiceSourceOfGraph = Not ThisIsOrder 
		                                               	And Not InvoiceForOrders 
		                                               	And Not (ValueIsFilled(ContractSchedule) 
		                                               		And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		                                               			Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice));
		ParametersStructure.PaymentAmountAgainstTheDocument = PaymentAmountAgainstTheDocument;
		ParametersStructure.DepositAmountUnderTheDocument = DepositAmountUnderTheDocument;
		
		If PaymentAmountAgainstTheDocument = PaymentScheduleSteps.Total("PaymentAmount")
				And PaymentScheduleSteps.Total("PaymentPercentage") <> 100
			Or DepositAmountUnderTheDocument > 0 
				And DepositAmountUnderTheDocument = PaymentScheduleSteps.Total("PackageDepositValue")
				And PaymentScheduleSteps.Total("PackageDepositPercentage") <> 100 Then
			PaymentStepsServer.FillInInterestOnAmounts(PaymentScheduleSteps);
		EndIf;
		
		PaymentStepsServer.CheckCorrectnessOfPaymentScheduleStages(
			PaymentScheduleSteps,
			Cancel,
			ParametersStructure,
			SimplifiedMode);
			
	EndIf;
	
	Return ?(Cancel, "", PutItInTemporaryStorageOnServer());
	
EndFunction

#EndRegion

#Region OnChangeAttributes

&AtServer
Procedure WhenChangingPaymentFormServer()

	SetAvailabilityOfItemsByPaymentForm();
	
	PaymentInRubles = Not ForeignCurrencyTransaction;

	ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
	ParametersStructure.Organization 			= Organization;
	ParametersStructure.LineOfBusiness = LineOfBusiness;
	ParametersStructure.Currency					= CurrencyOfComplianceAccounting;
	ParametersStructure.ExcludeCurrencyAccounts	= ForeignCurrencyTransaction;

	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersStructure,
		BankAccount);

	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization 			= Organization;
	ParametersStructure.LineOfBusiness = LineOfBusiness;
	ParametersStructure.PaymentMethod 			= PaymentMethod;
	ParametersStructure.CashAccount 					= CashAccount;

	If PaymentInRubles Then
		ParametersStructure.Currency				= CurrencyOfComplianceAccounting;
	EndIf;

	CashAccount          = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);

EndProcedure

&AtServer
Procedure ARAPObjectSettingsOnChangeServer()
	
	UpdateServiceDetails();
	
	If Not ValueIsFilled(ARAPObjectSettings) Then
		ARAPObjectSettings = Items.ARAPObjectSettings.ChoiceList[0].Value;
	EndIf;
	
	If ThisIsOrder 
		And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
			Or ValueIsFilled(ContractSchedule) 
				And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
					Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)) Then
		
		PaymentScheduleSteps.Clear();
		PaymentAmountPrepayment      = 0;
		PaymentAmountCredit          = 0;
		DepositAmountForPackagingPrepayment = 0;
		TheAmountOfTheDepositForTheContainerLoan     = 0;
		
	EndIf;
	
	SetAvailabilityOfItemsInOrderOfCalculation();
	ConfigureFormElementsWhenChangingOrderOfCalculations();
	
EndProcedure

&AtClient
Procedure PaymentAmountOnChange(Sum, Percent, DependentAmount, DependentPercentage, AmountTotal)

	If AmountTotal <> 0 Then
		
		Percent           = Min(Sum * 100 / AmountTotal, 100);
		DependentAmount    = Max(AmountTotal - Sum, 0);
		DependentPercentage  = 100 - Percent;
		
	EndIf;
	
	CalculateTotals_(ThisObject);

EndProcedure

&AtClient
Procedure PaymentPercentageOnChange(Sum, Percent, DependentAmount, DependentPercentage, AmountTotal)

	Sum            = AmountTotal * Percent / 100;
	DependentAmount   = AmountTotal - Sum;
	DependentPercentage = 100 - Percent;

	CalculateTotals_(ThisObject);

EndProcedure

&AtServer
Procedure IfYouChangePaymentInServerCurrency()
	
	If Not ForeignCurrencyTransaction Then
		
		If ValueIsFilled(CashAccount) And Not Common.ObjectAttributeValue(CashAccount,"CashCurrency") = CurrencyOfComplianceAccounting Then
			CashAccount = Catalogs.CashAccounts.EmptyRef();
		EndIf;
		
	EndIf;
	
	BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	
	SetParametersForSelectingCashRegisterOfAccount();
	WhenChangingPaymentFormServer();
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure ConfigureFormElementsByParameters()
	
	ConfigureFormElementsWhenChangingOrderOfCalculations();
	
	ItemArray = New Array;
	ItemArray.Add("TheAmountOfTheDepositForTheContainerLoan");
	ItemArray.Add("DepositAmountForPackagingPrepayment");
	ItemArray.Add("ThePercentageOfTheDepositForTheContainerLoan");
	ItemArray.Add("PercentageOfTheDepositForTheContainerPrepayment");
	ItemArray.Add("CurrencyOfTheDepositForTheContainerCredit");
	ItemArray.Add("CurrencyOfTheDepositForTheContainerPrepayment");
	ItemArray.Add("DepositAmountUnderTheDocument");
	ItemArray.Add("TheCurrencyOfTheDepositOnTheDocument");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemArray, "Visible", Parameters.PackageDepositIsRequired);
	
	If PaymentAmountAgainstTheDocument = 0 Then 
		
		ItemArray = New Array;
		ItemArray.Add("PaymentAmountPrepayment");
		ItemArray.Add("PaymentAmountCredit");
		ItemArray.Add("PaymentPercentagePrepayment");
		ItemArray.Add("PercentageOfPaymentCredit");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items, "PaymentSourcesGroup", "Visible", Not Parameters.DoNotSpecifyPaymentSources);
	
	If UseNegativePaymentAmounts Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "PaymentScheduleStepsDateShift", "Title",
			NStr("vi = 'Ngày thanh toán';
				|ru = 'Дата платежа';
				|en = 'Payment date'; fa = 'تاریخ پرداخت';
				|it = 'Data di pagamento';
				|pl = 'Data płatności';
				|tr = 'Ödeme tarihi'"));
	EndIf;
	
	If Not Parameters.Property("CashAccount") Or Parameters.CashAccount = Undefined Then
		Items.CashAccount.Visible = False;
	EndIf;
	
	If Not Parameters.Property("BankAccount") Or Parameters.BankAccount = Undefined Then
		Items.BankAccount.Visible = False;
	EndIf;
	
	If ValueIsFilled(AddressInTempStorage) Then
		
		Items.PaymentScheduleStepsPaymentOption.ListChoiceMode = True;
		If ThisIsOrder Then
			Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation);
		EndIf;
		If Not NoPrepaymentControl Then
			Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt);
		EndIf;
		Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment);
		Items.PaymentScheduleStepsPaymentOption.ChoiceList.Add(Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt);
		
		Items.PaymentScheduleStepsCalculateFrom.ListChoiceMode = True;
		Items.ReferenceControlledOption.ListChoiceMode = True;
		Items.ReferenceOptionIsNotControlled.ListChoiceMode = True;
		
		Items.ReferenceOptionIsNotControlled.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FixedDate);
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FixedDate);
		Items.ReferenceControlledOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FixedDate);
		
		If ThisIsOrder Then
			Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate);
			Items.ReferenceControlledOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate);
			Items.ReferenceOptionIsNotControlled.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate);
			
			If GetFunctionalOption("NotBaseVersion") Then
				Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromApprovalDate);
				Items.ReferenceControlledOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromApprovalDate);
				Items.ReferenceOptionIsNotControlled.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromApprovalDate);
			EndIf;
			
		ElsIf ValueIsFilled(ContractSchedule) And Not ThisIsOrder Then
			Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate, NStr("vi = 'từ ngày hợp đồng';
																															|ru = 'от даты договора';
																															|en = 'from contract date'; fa = 'from contract date';
																															|it = 'dalla data dell''accordo';
																															|pl = 'od daty umowy';
																															|tr = 'sözleşme tarihinden'"));
			Items.ReferenceControlledOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate, NStr("vi = 'từ ngày hợp đồng';
																													|ru = 'от даты договора';
																													|en = 'from contract date'; fa = 'from contract date';
																													|it = 'dalla data dell''accordo';
																													|pl = 'od daty umowy';
																													|tr = 'sözleşme tarihinden'"));
			Items.ReferenceOptionIsNotControlled.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate, NStr("vi = 'từ ngày hợp đồng';
																														|ru = 'от даты договора';
																														|en = 'from contract date'; fa = 'from contract date';
																														|it = 'dalla data dell''accordo';
																														|pl = 'od daty umowy';
																														|tr = 'sözleşme tarihinden'"));
		EndIf;
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		Items.ReferenceControlledOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		Items.ReferenceOptionIsNotControlled.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromShipmentDate);
		Items.ReferenceOptionIsNotControlled.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromShipmentDate);
		
		If ThereIsDateOfTransferOfOwnership Then
			Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods);
			Items.ReferenceOptionIsNotControlled.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods);
		EndIf;
		
		Items.ReferenceOptionIsNotControlled.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfReceipt);
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfReceipt);
		Items.PaymentScheduleStepsCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.Formula);
		
	Else
		
		Items.ReferenceOptionIsNotControlled.ReadOnly = True;
		Items.PaymentAmountCredit.ReadOnly = True;
		Items.PercentageOfPaymentCredit.ReadOnly = True;
		
	EndIf;
	
	Items.ForeignCurrencyTransaction.Visible = ARAPCurrency <> CurrencyOfComplianceAccounting Or ForeignCurrencyTransaction;
	Items.PaymentID.ReadOnly = ReadOnly Or Not ItIsAllowedToChangeUIP;
	
	SetSBPPaymentLabel();
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(ThisObject);
	
EndProcedure

&AtServer
Procedure ConfigureFormElementsWhenChangingOrderOfCalculations()
	
	ItemArray = New Array;
	If SimplifiedMode Then
		Items.GroupPages.CurrentPage = Items.PageSimplifiedScheme;
		ItemArray.Add("AdvancedSetupPage");
		If Not ThereIsPrepayment Then
			ItemArray.Add("DistributeAmountForm");
		EndIf;
	Else
		Items.GroupPages.CurrentPage = Items.AdvancedSetupPage;
		ItemArray.Add("PageSimplifiedScheme");
		ItemArray.Add("FillInTheStagesOfThePaymentScheduleForm");
		ItemArray.Add("FillInTheScheduleStagesForPreviousOrdersForm");
		ItemArray.Add("DistributeAmountForm");
	EndIf;
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", False);
	
	Items.PrepaymentGroup.Visible = ThereIsPrepayment;
	
	ByOrders = 
		InvoiceForOrders 
			And ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")
			And Not ValueIsFilled(ContractSchedule)
		Or InvoiceForOrders
			And Not ValueIsFilled(ContractSchedule) 
			And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts")
				Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice"));
	
	AccordingToExecutionSchedule = Not ThisIsOrder 
		And ValueIsFilled(ContractSchedule)
		And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts")
				Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice"));
	
	//It is prohibited to change the schedule if the invoice for orders and orders have formed a payment plan, or if it is an invoice according to the contract execution schedule.
	Items.PaymentScheduleSteps.ChangeRowSet = Not ByOrders And Not AccordingToExecutionSchedule;
	
	//The order is visible when calculating orders and when calculating contracts and contracts/invoices - if the payment schedule is specified in the orders.
	Items.PaymentScheduleStepsOrderDocument.Visible = ByOrders;
	Items.PaymentScheduleStepsExceedingOrder.Visible = ByOrders;
	
	ItemArray = New Array;
	ItemArray.Add("PaymentMethod");
	ItemArray.Add("ForeignCurrencyTransaction");
	ItemArray.Add("CashAccount");
	ItemArray.Add("BankAccount");
	//tare is not in the execution schedules
	ItemArray.Add("PaymentScheduleStepsPackageDepositPercentage");
	ItemArray.Add("PaymentScheduleStepsPackageDepositValue");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", ByOrders);
	
	//In the invoices for orders and the execution schedule, you can only change the shift and the payment date.
	ItemArray = New Array;
	ItemArray.Add("PaymentScheduleStepsPaymentOption");
	ItemArray.Add("PaymentScheduleStepsCalculateFrom");
	ItemArray.Add("PaymentScheduleStepsFormula");
	ItemArray.Add("PaymentScheduleStepsPaymentPercentage");
	ItemArray.Add("PaymentScheduleStepsPaymentAmount");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", ByOrders Or AccordingToExecutionSchedule);
	
	ItemArray = New Array;
	ItemArray.Add("AdvancedSetupPage");
	ItemArray.Add("PageSimplifiedScheme");
	
	If ThisIsOrder And ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")
		Or ThisIsOrder And ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts And ValueIsFilled(ContractSchedule)
		Or ThisIsOrder And ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice And ValueIsFilled(ContractSchedule) Then
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", False);
	Else
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", True);
	EndIf;
	
	Items.GroupFillIn.Type = FormGroupType.Popup;
	If DisableFillingInForPreviousOrders
		Or Not ValueIsFilled(Partner)
		Or Not ThisIsOrder Then
		
		ItemArray = New Array;
		ItemArray.Add("FillInTheScheduleStagesForPreviousOrdersForm");
		ItemArray.Add("FillInTheScheduleStagesForPreviousOrdersTable");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", False);
		
		Items.GroupFillIn.Type = FormGroupType.ButtonGroup;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAccessibilityOfFillButtons()
	
	ElementAvailability = DepositAmountUnderTheDocument <> 0 Or PaymentAmountAgainstTheDocument <> 0;
	Items.FillInTheStagesOfThePaymentScheduleForm.Enabled                = ElementAvailability;
	Items.FillInTheStagesOfThePaymentScheduleTable.Enabled              = ElementAvailability;
	Items.FillInTheScheduleStagesForPreviousOrdersForm.Enabled   = ElementAvailability;
	Items.FillInTheScheduleStagesForPreviousOrdersTable.Enabled = ElementAvailability;
	Items.DistributeAmountForm.Enabled                          = ElementAvailability;
	Items.DistributeAmountTable.Enabled                        = ElementAvailability;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByPaymentForm()
	
	AnyPayment      = Not ValueIsFilled(PaymentMethod);
	CheckoutAvailability = AnyPayment Or (PaymentMethod = Enums.PaymentForms.CashAccountPayment_);
	AccountItemAvailability = AnyPayment
						Or (PaymentMethod = Enums.PaymentForms.BankAccountPayment)
						Or PaymentMethod = Enums.PaymentForms.InstantPayments;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "CashAccount", "Enabled", CheckoutAvailability);
	TMCommonUseClientServer.SetFormItemProperty(Items, "BankAccount", "Enabled", AccountItemAvailability);
	
	PaymentStepsServerLocalization.SetAvailabilityOfItemsByPaymentForm(ThisObject, True);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfElementsByReferenceOption()
	
	Items.PostpaidShift.Enabled = OptionForCountingPostpaid <> Enums.PaymentDateCalculationOptions.FixedDate;
	Items.ShiftPrepayment.Enabled = CountdownOptionPrepayment <> Enums.PaymentDateCalculationOptions.FixedDate;
	
EndProcedure

&AtServer
Procedure SetElementPropertiesCalculationOrder()
	
	If Parameters.Property("ARAPObjectSettings") Then
		
		ARAPObjectSettings = Parameters.ARAPObjectSettings;
		AvailablePaymentTerms = Undefined;
		
		If Parameters.Property("AvailablePaymentTerms") Then
			AvailablePaymentTerms = Parameters.AvailablePaymentTerms;
		Else
			AvailablePaymentTerms = ARAPAccountingServer.AvailableCalculationProceduresForDocument(
				ARAPObjectSettings,
				ARAPAccountingServer.ARAPObjectSettings(Parameters.ThisIsOrder,,Terms,Contract),
				Parameters.InvoiceForOrders,
				Parameters.ThisIsOrder);
		EndIf;
			
		If AvailablePaymentTerms.Count() > 1 Then
			
			Items.ARAPObjectSettings.ChoiceList.Clear();
			For Each SelectionRow In AvailablePaymentTerms Do
				Items.ARAPObjectSettings.ChoiceList.Add(SelectionRow.Value, SelectionRow.Presentation);
			EndDo;
			Items.ARAPObjectSettings.ReadOnly = False;
			Items.ARAPObjectSettings.ListChoiceMode = True;
			
		EndIf;
		
		SetAvailabilityOfItemsInOrderOfCalculation();
		
	Else
		
		Items.ARAPObjectSettings.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsInOrderOfCalculation()
	
	If ThisIsOrder And ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
		Or ThisIsOrder And ValueIsFilled(ContractSchedule) 
			And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
				Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		Or PaymentAmountAgainstTheDocument < 0 
		Or DepositAmountUnderTheDocument < 0 Then
		
		Items.GroupPages.Enabled                                = False;
		Items.FillInTheStagesOfThePaymentScheduleForm.Enabled              = False;
		Items.FillInTheScheduleStagesForPreviousOrdersForm.Enabled = False;
		Items.DistributeAmountForm.Enabled                        = False;
		Items.PaymentMethod.Enabled                                   = False;
		Items.ForeignCurrencyTransaction.Enabled                                 = False;
		Items.CashAccount.Enabled                                         = False;
		Items.BankAccount.Enabled                                = False;
		
		If PaymentAmountAgainstTheDocument < 0 
			Or DepositAmountUnderTheDocument < 0 Then
			Items.GroupPages.Visible                 = False;
			Items.FooterGroup.Visible                   = False;
		EndIf;
		
	Else
		
		Items.GroupPages.Enabled = True;
		Items.PaymentMethod.Enabled    = True;
		Items.ForeignCurrencyTransaction.Enabled  = True;
		
		SetAccessibilityOfFillButtons();
		SetAvailabilityOfItemsByPaymentForm();
		
	EndIf;
	
	ScheduleEditingIsProhibited = (ValueIsFilled(ContractSchedule) And ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts And ThisIsOrder);
	If ScheduleEditingIsProhibited Then
		Items.ARAPObjectSettings.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
	Else
		Items.ARAPObjectSettings.ToolTipRepresentation = ToolTipRepresentation.None;
	EndIf;
	Items.PrepaymentGroup.Enabled = Not ScheduleEditingIsProhibited;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetTextOfFillButton(Form)
	
	TextOfFillButton = NStr("vi = 'Điền theo mặc định';
							|ru = 'Заполнить по умолчанию';
							|en = 'Fill in by default'; fa = 'پرکردن پیش‌فرض';
							|it = 'Compilare di default';
							|pl = 'Wypełnij domyślnie';
							|tr = 'Varsayılan olarak doldur'");
	
	If Form.InvoiceForOrders 
			And (Form.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByOrders")
				Or Form.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice")
				Or Not ValueIsFilled(Form.ContractSchedule) And Form.ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")) Then
		TextOfFillButton = NStr("vi = 'Điền theo đơn hàng';
								|ru = 'Заполнить по заказам';
								|en = 'Fill in from orders'; fa = 'Fill in from orders';
								|it = 'Compilare per ordini';
								|pl = 'Wypełniej według zamówień';
								|tr = 'Siparişlere göre doldur'");
	ElsIf Not Form.ThisIsOrder 
		And ValueIsFilled(Form.ContractSchedule)
		And Form.ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments") Then
		TextOfFillButton = NStr("vi = 'Điền vào theo lịch trình của hợp đồng';
								|ru = 'Заполнить по графику договора';
								|en = 'Fill in by contract schedule'; fa = 'Fill in by contract schedule';
								|it = 'Compilare in base al programma di lavoro';
								|pl = 'Wypełnij według harmonogramu kontraktu';
								|tr = 'Sözleşme programına göre doldur'");
	ElsIf Form.AgreementScheduleIsFilledIn Then
		TextOfFillButton = NStr("vi = 'Điền theo thỏa thuận';
								|ru = 'Заполнить по соглашению';
								|en = 'Fill in by terms of purchase'; fa = 'تکمیل بر اساس شرایط خرید';
								|it = 'Compilare in base all''accordo';
								|pl = 'Wypełnij według umowy';
								|tr = 'Anlaşmaya göre doldur'");
	EndIf;
	
	ItemArray = New Array;
	ItemArray.Add("FillInTheStagesOfThePaymentScheduleForm");
	ItemArray.Add("FillInTheStagesOfThePaymentScheduleTable");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items, ItemArray, "Title", TextOfFillButton);
	
EndProcedure

&AtServer
Procedure LimitTypeOfPaymentAmountElements()
	
	RestrictedType = New TypeDescription("Number",New NumberQualifiers(31, 2, AllowedSign.Nonnegative));
	
	ItemArray = New Array;
	
	ItemArray.Add("PaymentScheduleStepsPaymentAmount");
	ItemArray.Add("PaymentAmountPrepayment");
	ItemArray.Add("PaymentAmountCredit");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "TypeRestriction", RestrictedType);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function PutItInTemporaryStorageOnServer()
	
	Return PutToTempStorage(PaymentScheduleSteps.Unload(), CalledFormID);
	
EndFunction

&AtServer
Function ConvertSimplifiedModeDataToStepTable()
	
	ResultTable1 = PaymentScheduleSteps.Unload();
	ResultTable1.Clear();
	
	If StageContainsData("Prepayment") And ThereIsPrepayment And PaymentAmountPrepayment + DepositAmountForPackagingPrepayment > 0 Then
		
		PrepaymentLine = ResultTable1.Add();
		PrepaymentLine.PaymentOption           = ?(ValueIsFilled(ControlOptionPrepayment),
		                                             ControlOptionPrepayment,
		                                             Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt);
		PrepaymentLine.CalculateFrom          = CountdownOptionPrepayment;
		PrepaymentLine.Move                   = ShiftPrepayment;
		PrepaymentLine.PaymentDate             = DatePrepayment;
		PrepaymentLine.PaymentAmount            = PaymentAmountPrepayment;
		PrepaymentLine.PaymentPercentage          = PaymentPercentagePrepayment;
		If PackageDepositIsRequired Then
			PrepaymentLine.PackageDepositValue   = DepositAmountForPackagingPrepayment;
			PrepaymentLine.PackageDepositPercentage = PercentageOfTheDepositForTheContainerPrepayment;
		EndIf;
		
	EndIf;
	
	If StageContainsData("Credit")  And PaymentAmountCredit + TheAmountOfTheDepositForTheContainerLoan > 0 Then
		
		CreditLine_ = ResultTable1.Add();
		CreditLine_.PaymentOption           = ?(ValueIsFilled(OptionOfPostpaidControl),
		                                          OptionOfPostpaidControl,
		                                          Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt);
		CreditLine_.CalculateFrom          = OptionForCountingPostpaid;
		CreditLine_.Move                   = PostpaidShift;
		CreditLine_.PaymentDate             = DateCredit;
		CreditLine_.PaymentAmount            = PaymentAmountCredit;
		CreditLine_.PaymentPercentage          = PercentageOfPaymentCredit;
		If PackageDepositIsRequired Then
			CreditLine_.PackageDepositValue   = TheAmountOfTheDepositForTheContainerLoan;
			CreditLine_.PackageDepositPercentage = ThePercentageOfTheDepositForTheContainerLoan;
		EndIf;
		
	EndIf;
	
	Return ResultTable1;
	
EndFunction

&AtServer
Function StageContainsData(PaymentOption)
	
	If PaymentOption = "Credit" Then
		Return ValueIsFilled(PaymentAmountCredit)
			Or ?(PackageDepositIsRequired, ValueIsFilled(TheAmountOfTheDepositForTheContainerLoan), False);
	Else
		Return ValueIsFilled(PaymentAmountPrepayment)
			Or ?(PackageDepositIsRequired, ValueIsFilled(DepositAmountForPackagingPrepayment), False);
	EndIf;
	
EndFunction

&AtServer
Procedure ConvertStageTableToSimplifiedModeData(PaymentSteps)
	
	ClearSimplifiedModeData(ThisObject);
	
	Result = PaymentStepsServer.SimplifiedModeData(PaymentSteps,DateOfShipment,ThereIsPrepayment,Calendar);
	
	PaymentAmountPrepayment = Result.PaymentAmountPrepayment;
	PaymentPercentagePrepayment = Result.PaymentPercentagePrepayment;
	DepositAmountForPackagingPrepayment = Result.DepositAmountForPackagingPrepayment;
	PercentageOfTheDepositForTheContainerPrepayment = Result.PercentageOfTheDepositForTheContainerPrepayment;
	DatePrepayment = Result.DatePrepayment;
	CountdownOptionPrepayment = Result.CountdownOptionPrepayment;
	ControlOptionPrepayment = Result.ControlOptionPrepayment;
	ShiftPrepayment = Result.ShiftPrepayment;
	
	PaymentAmountCredit = Result.PaymentAmountCredit;
	PercentageOfPaymentCredit = Result.PercentageOfPaymentCredit;
	TheAmountOfTheDepositForTheContainerLoan = Result.TheAmountOfTheDepositForTheContainerLoan;
	ThePercentageOfTheDepositForTheContainerLoan = Result.ThePercentageOfTheDepositForTheContainerLoan;
	DateCredit = Result.DateCredit;
	OptionForCountingPostpaid = Result.CreditReferenceOption;
	OptionOfPostpaidControl = Result.CreditControlOption;
	PostpaidShift = Result.ShiftCredit;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ClearSimplifiedModeData(Form)
	
	Form.DatePrepayment                = Undefined;
	Form.DateCredit                    = Undefined;
	Form.PaymentAmountPrepayment        = 0;
	Form.PaymentAmountCredit            = 0;
	Form.PaymentPercentagePrepayment      = 0;
	Form.PercentageOfPaymentCredit          = 0;
	Form.DepositAmountForPackagingPrepayment   = 0;
	Form.TheAmountOfTheDepositForTheContainerLoan       = 0;
	Form.PercentageOfTheDepositForTheContainerPrepayment = 0;
	Form.ThePercentageOfTheDepositForTheContainerLoan     = 0;
	
EndProcedure

&AtServer
Function PutGraphTemplatesInTemporaryStorage()
	
	ChartTemplatesData = FormAttributeToValue("ChartTemplates");
	Return PutToTempStorage(ChartTemplatesData);
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form)
	
	Form.LineNumberOfFullPayment = 0;
	Form.LineNumberOfDepositFullPayment = 0;
	Form.TotalPaymentPercentage = 0;
	Form.DepositPercentageTotal = 0;
	
	If Form.SimplifiedMode Then
		
		Form.TotalPaymentPercentage = Form.PaymentPercentagePrepayment + Form.PercentageOfPaymentCredit;
		Form.DepositPercentageTotal   = Form.PercentageOfTheDepositForTheContainerPrepayment + Form.ThePercentageOfTheDepositForTheContainerLoan;
		
	Else
		
		For Each CurRow In Form.PaymentScheduleSteps Do
			
			Form.TotalPaymentPercentage = Form.TotalPaymentPercentage + CurRow.PaymentPercentage;
			CurRow.PercentageIsFilledInIncorrectly = (Form.TotalPaymentPercentage > 100);
			If Form.TotalPaymentPercentage = 100 Then
				Form.LineNumberOfFullPayment = CurRow.LineNumber;
			EndIf;
			
			Form.DepositPercentageTotal = Form.DepositPercentageTotal + CurRow.PackageDepositPercentage;
			CurRow.DepositPercentageIsFilledInIncorrectly = (Form.DepositPercentageTotal > 100);
			If Form.DepositPercentageTotal = 100 Then
				Form.LineNumberOfDepositFullPayment = CurRow.LineNumber;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SortPaymentStages()
	
	If Not SimplifiedMode Then
		
		PaymentStepsClientServer.SortStageTable(PaymentScheduleSteps);
		
		LineNumber = 1;
		For Each TableRow In PaymentScheduleSteps Do
			TableRow.LineNumber = LineNumber;
			LineNumber = LineNumber + 1;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPaymentFormSelectionList()
	
	Var FilterByReference_;
	
	AvailableFormsOfPayment = CashServer.AvailableFormsOfPaymentToChooseFrom();
	
	For Each CurParameter In Items.PaymentMethod.ChoiceParameters Do
		If CurParameter.Name = "Filter.Ref" Then
			FilterByReference_ = CurParameter.Value;
			Break;
		EndIf;
	EndDo;
	
	Query = New Query;
	QueryText =
	"SELECT
	|	PaymentForms.Ref
	|FROM
	|	Enum.PaymentForms AS PaymentForms
	|WHERE
	|	&Condition";
	
	If FilterByReference_ <> Undefined Then
		QueryText = StrReplace(QueryText, "&Condition", "Ref IN(&FilterByReference_)");
		Query.SetParameter("FilterByReference_", FilterByReference_);
	Else
		QueryText = StrReplace(QueryText, "&Condition", "TRUE");
	EndIf;
	
	Query.Text = QueryText;
	
	Selection      = Query.Execute().Select();
	ChoiceList = Items.PaymentMethod.ChoiceList;
	While Selection.Next() Do
		If AvailableFormsOfPayment.Find(Selection.Ref) <> Undefined Then
			ChoiceList.Add(Selection.Ref);
		EndIf;
	EndDo;
	
	ChoiceList.Add(Enums.PaymentForms.EmptyRef(), NStr("vi = 'Bất kỳ';
														|ru = 'Любая';
														|en = 'Any'; fa = 'هر';
														|it = 'Qualsiasi';
														|pl = 'Any';
														|tr = 'Herhangi'"));
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingCashRegisterOfAccount()
	
	If Not ForeignCurrencyTransaction Then
		NewArray = New Array();
		NewArray.Add(New ChoiceParameter("Filter.CashCurrency", CurrencyOfComplianceAccounting));
		NewArray.Add(New ChoiceParameter("Filter.Closed", False));
		NewParameters = New FixedArray(NewArray);
	Else
		NewArray = New Array();
		CurrencySelection = Catalogs.Currencies.Select();
		ListOfCurrencies = New ValueList;
		While CurrencySelection.Next() Do
			If CurrencySelection.Ref = CurrencyOfComplianceAccounting Then 
				Continue;
			EndIf;
			ListOfCurrencies.Add(CurrencySelection.Ref);
		EndDo;
		NewArray.Add(New ChoiceParameter("Filter.CashCurrency", ListOfCurrencies));
		NewArray.Add(New ChoiceParameter("Filter.Closed", False));
		NewParameters = New FixedArray(NewArray)
	EndIf;
	
	Items.BankAccount.ChoiceParameters = NewParameters; 
	Items.CashAccount.ChoiceParameters          = NewParameters;
	
EndProcedure

&AtServer
Procedure UpdateServiceDetails()
	
	SimplifiedMode = Not ValueIsFilled(AddressInTempStorage)
		Or UseSimplifiedPaymentSchemeInPurchasing
			And Not (InvoiceForOrders And ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments);
	
	//More than one payment date
	ThereIsPrepayment = SimplifiedMode And ValueIsFilled(AddressInTempStorage) And Not NoPrepaymentControl;
	
	If SimplifiedMode Then
		If PaymentScheduleSteps.Count() > 0 Then
			ConvertStageTableToSimplifiedModeData(PaymentScheduleSteps.Unload());
		ElsIf Not ThereIsPrepayment Then
			PaymentAmountCredit        = PaymentAmountAgainstTheDocument;
			TheAmountOfTheDepositForTheContainerLoan   = DepositAmountUnderTheDocument;
			ThePercentageOfTheDepositForTheContainerLoan = 100;
			PercentageOfPaymentCredit      = 100;
			DateCredit                = PaymentDate;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function EditParameters()
	
	OpenStructure = New Structure;
	OpenStructure.Insert("Currency",                         Currency);
	OpenStructure.Insert("TheseAreSettlementsWithCustomers",           False);
	OpenStructure.Insert("Calendar",                      Calendar);
	OpenStructure.Insert("OrderDate",                     OrderDate);
	OpenStructure.Insert("ApprovalDate",               ApprovalDate);
	OpenStructure.Insert("DeadlineOfTransferOfTitleToGoods", DeadlineOfTransferOfTitleToGoods);
	OpenStructure.Insert("DateOfTransferOfTitleToGoods", DateOfTransferOfTitleToGoods);
	OpenStructure.Insert("PaymentAmountAgainstTheDocument",         PaymentAmountAgainstTheDocument);
	OpenStructure.Insert("DepositAmountUnderTheDocument",         DepositAmountUnderTheDocument);
	OpenStructure.Insert("ThisIsContract",                     False);
	OpenStructure.Insert("ShipmentDates",                   TabularSection);
	OpenStructure.Insert("PaymentScheduleSteps",             PaymentScheduleSteps);
	OpenStructure.Insert("ThereIsPackage",                       PackageDepositIsRequired);
	OpenStructure.Insert("InvoiceForOrders",              InvoiceForOrders);
	
	Return OpenStructure;
	
EndFunction

&AtServer
Procedure CollapsePaymentStages()
	
	VT = PaymentScheduleSteps.Unload();
	VT.GroupBy("PaymentOption, PaymentDate, CalculateFrom, Formula, Move, DateOfShipment","PaymentAmount,PaymentPercentage");
	PaymentScheduleSteps.Load(VT);
	
EndProcedure

&AtServer
Procedure CheckAdjustmentsToSettlementSchedules(Ref)
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text = "
		|SELECT
		|	ARAPAccountingScheduleAdjustment.Ref AS Ref
		|FROM
		|	Document.ARAPAccountingScheduleAdjustment AS ARAPAccountingScheduleAdjustment
		|WHERE
		|	ARAPAccountingScheduleAdjustment.DocumentBasis = &Ref
		|	AND ARAPAccountingScheduleAdjustment.BusinessOperation = VALUE(Enum.BusinessTransactions.AdjustVendorPaymentSchedule)
		|	AND ARAPAccountingScheduleAdjustment.Posted";
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	If Selection.Next() Then
		MessageTemplate = NStr("vi = 'Đã nhập %1 trên cơ sở chứng từ hiện tại.';
								|ru = 'На основании текущего документа введена %1.';
								|en = '%1 is entered based on the current document.'; fa = '%1 is entered based on the current document.';
								|it = '%1 is entered based on the current document.';
								|pl = '%1 is entered based on the current document.';
								|tr = 'Mevcut belge temelinde %1 girildi.'");
		Common.MessageToUser(
			StrTemplate(MessageTemplate, Selection.Ref),
			Selection.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterEnteringSBPPaymentLink(Result, AdditionalParameters) Export

	SetSBPPaymentLabel();

EndProcedure

&AtServer
Procedure SetSBPPaymentLabel()

	PaymentStepsServerLocalization.SetSBPPaymentLabel(ThisObject, True);

EndProcedure

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_F_DatePrepayment" Then
		DatePrepaymentOnChange(Items.DatePrepayment);
	ElsIf Item.Name = "sh_ShamsiInput_F_DateCredit" Then
		DateCreditOnChange(Items.DateCredit);
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
