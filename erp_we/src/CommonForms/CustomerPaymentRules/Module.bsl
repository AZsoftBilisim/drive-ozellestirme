#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UsePaymentSchedules               = GetFunctionalOption("UsePaymentSchedules");
	UseAllowableDeviationOfMeasuringGoodsShipmentReceiving =
		GetFunctionalOption("UseAllowableDeviationOfMeasuringGoodsShipmentReceiving");
	UseSimplifiedPaymentSchemeInSales = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Parameters.Organization);
	
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
	
	//Single order date
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
	
	If Not GetFunctionalOption("ToUseTermsOfSales") Then
		Terms = Undefined;
	Else
		AgreementScheduleIsFilledIn = PaymentStepsServerCall.AgreementScheduleIsFilledIn(Terms);
	EndIf;
	
	CompletedCalendarsInPaymentStages = False;
	If Not GetFunctionalOption("UsePaymentSchedules") Then
		PaymentSchedule = Catalogs.PaymentSchedules.EmptyRef();
	ElsIf Not ThisIsOrder 
		And TabularSection.Count() > 0 Then
		AnArrayOfOrders = New Array;
		For Each TSRow In TabularSection Do
			If ValueIsFilled(TSRow.OrderDocument) Then
				AnArrayOfOrders.Add(TSRow.OrderDocument);
			EndIf;
		EndDo;
		PaymentSchedules = Common.ObjectsAttributeValue(AnArrayOfOrders, "PaymentSchedule");
		ArrayOfGraphs = New Array;
		For Each KeyAndValue In PaymentSchedules Do
			If ValueIsFilled(KeyAndValue.Value) Then
				ArrayOfGraphs.Add(KeyAndValue.Value);
			EndIf;
		EndDo;
		Calendars = Common.ObjectsAttributeValue(ArrayOfGraphs, "Calendar");
		For Each StageString_ In PaymentScheduleSteps Do
			If PaymentSchedules[StageString_.OrderDocument] <> Undefined Then
				StageString_.Calendar = Calendars[PaymentSchedules[StageString_.OrderDocument]];
				If ValueIsFilled(StageString_.Calendar) Then
					CompletedCalendarsInPaymentStages = True;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If Not CompletedCalendarsInPaymentStages Then
		For Each StageString_ In PaymentScheduleSteps Do
			StageString_.Calendar = Calendar;
		EndDo;
	EndIf;
	
	UpdateServiceDetails();
	
	If Not ValueIsFilled(AddressInTempStorage) Then
		OptionForCountingPostpaid = Enums.PaymentDateCalculationOptions.FromShipmentDate;
		OptionOfPostpaidControl = Enums.CustomerPaymentControlOptions.CreditPlanned;
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
	
	CalledFormID        = Parameters.UUID;
	
	If Not Parameters.UseNegativePaymentAmounts Then
		LimitTypeOfPaymentAmountElements();
	EndIf;
	
	If Parameters.AttributeSelectionParameters <> Undefined Then
		For Each EmailSettings In Parameters.AttributeSelectionParameters Do
			TMCommonUseClientServer.SetFormItemProperty(Items, EmailSettings.Key, "ChoiceParameters", EmailSettings.Value);
		EndDo;
	EndIf;
	
	FillInPaymentFormSelectionList();
	SetAvailabilityOfItemsByPaymentForm();
	SetAvailabilityOfElementsByReferenceOption();
	
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	CustomizeFormElements();
	SetTextOfFillButton(ThisObject);
	
	CalculateTotals_(ThisObject);

	WindowOptionsKey = String(New UUID);
	
	SetElementPropertiesCalculationOrder();
	SetParametersForSelectingCashRegisterOfAccount();
	
	CheckAdjustmentsToSettlementSchedules(Parameters.Key);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit Then
		
		StandardProcessing = False;
		
		If Modified And Not Done Then
			
			Cancel = True;
			
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
			
			ShowQueryBox(
				New CallbackDescription("BeforeCloseCompletion", ThisObject), 
				NStr("vi = 'Tất cả dữ liệu đã thay đổi sẽ bị mất. Đóng biểu mẫu?';
					|ru = 'Все измененные данные будут потеряны. Закрыть форму?';
					|en = 'All changed data will be lost. Close the form?'; fa = 'All changed data will be lost. Close the form?';
					|it = 'Tutti i dati modificati andranno persi. Chiudere il form?';
					|pl = 'Wszystkie zmodyfikowane dane zostaną utracone. Chcesz zamknąć formularz?';
					|tr = 'Tüm değişiklikler kaybolacak. Kapatılsın mı?'"), 
				ButtonsList);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "Close" Then
		Modified = False;
		Close();
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
		ObjectStructure.Insert("PaymentSchedule",              PaymentSchedule);
		ObjectStructure.Insert("ForeignCurrencyTransaction",             ForeignCurrencyTransaction);
		ObjectStructure.Insert("ThereAreManualChangesToPaymentSchedule", ThereAreManualChangesToPaymentSchedule);
		
		If SelfServiceMode Then
			Done = True;
		ElsIf SimplifiedMode Then
			
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
				AddressInTempStorage = ConvertPutIntoTemporaryStorage();
				Done = AddressInTempStorage <> "";
			Else
				CommonClient.MessageToUser(ErrorText,, ErrorField);
				AddressInTempStorage = "";
			EndIf;
			
		Else
			AddressInTempStorage = CheckPaymentPutInStorage();
		EndIf;
		
		If Not IsBlankString(AddressInTempStorage) Then
			Done = True;
			ObjectStructure.Insert("AddressInTempStorage", AddressInTempStorage);
		EndIf;
		
		If Done Then
			Close(ObjectStructure);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ARAPObjectSettingsOnChange(Item)
	
	ARAPObjectSettingsOnChangeServer();
	
EndProcedure

&AtClient
Procedure PaymentScheduleOnChange(Item)
	
	If ValueIsFilled(PaymentSchedule) Then
		FillInPaymentStages(True);
		SortPaymentStages();
		CalculateTotals_(ThisObject);
	EndIf;
	
	SetTextOfFillButton(ThisObject);
	
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
	
	Data_Stage = New Structure;
	Data_Stage.Insert("PaymentDate", Date(1,1,1));
	Data_Stage.Insert("Move", ShiftPrepayment);
	Data_Stage.Insert("CalculateFrom", CountdownOptionPrepayment);
	Data_Stage.Insert("PaymentOption",  PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment"));
	Data_Stage.Insert("Formula",        Undefined);
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = OrderDate;
	ParametersForFillingInPaymentDate.ApprovalDate               = ApprovalDate;
	ParametersForFillingInPaymentDate.DateOfShipment                   = DateOfShipment;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		Data_Stage,ParametersForFillingInPaymentDate);
	
	DatePrepayment = Data_Stage.PaymentDate;
	
EndProcedure

&AtClient
Procedure CountdownOptionPrepaymentOnChange(Item)
	
	If CountdownOptionPrepayment = PredefinedValue("Enum.PaymentDateCalculationOptions.FixedDate") Then
		ShiftPrepayment = 0;
	EndIf;
	SetAvailabilityOfElementsByReferenceOption();
	
	Data_Stage = New Structure;
	Data_Stage.Insert("PaymentDate",    DatePrepayment);
	Data_Stage.Insert("Move",          ShiftPrepayment);
	Data_Stage.Insert("CalculateFrom", CountdownOptionPrepayment);
	Data_Stage.Insert("PaymentOption",  PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment"));
	Data_Stage.Insert("Formula",        Undefined);
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = OrderDate;
	ParametersForFillingInPaymentDate.ApprovalDate               = ApprovalDate;
	ParametersForFillingInPaymentDate.DateOfShipment                   = DateOfShipment;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		Data_Stage,ParametersForFillingInPaymentDate);
	
	DatePrepayment = Data_Stage.PaymentDate;
	
EndProcedure

&AtClient
Procedure DatePrepaymentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Data_Stage = New Structure;
	Data_Stage.Insert("PaymentDate",    DatePrepayment);
	Data_Stage.Insert("Move",          0);
	Data_Stage.Insert("CalculateFrom", CountdownOptionPrepayment);
	Data_Stage.Insert("PaymentOption",  PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment"));
	Data_Stage.Insert("Formula",        Undefined);
	
	ShiftFillParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ShiftFillParameters.OrderDate                     = OrderDate;
	ShiftFillParameters.ApprovalDate               = ApprovalDate;
	ShiftFillParameters.DateOfShipment                   = DateOfShipment;
	ShiftFillParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ShiftFillParameters.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ShiftFillParameters.Calendar                      = Calendar;
	
	PaymentStepsClient.PaymentScheduleStepsPaymentDateOnChange(
		Data_Stage,ShiftFillParameters);
	
	ShiftPrepayment = Data_Stage.Move;
	
EndProcedure

&AtClient
Procedure PostpaidShiftOnChange(Item)
	
	Data_Stage = New Structure;
	Data_Stage.Insert("PaymentDate",    Date(1,1,1));
	Data_Stage.Insert("Move",          PostpaidShift);
	Data_Stage.Insert("CalculateFrom", OptionForCountingPostpaid);
	Data_Stage.Insert("PaymentOption",  PredefinedValue("Enum.CustomerPaymentControlOptions.CreditPlanned"));
	Data_Stage.Insert("Formula",        Undefined);
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = OrderDate;
	ParametersForFillingInPaymentDate.ApprovalDate               = ApprovalDate;
	ParametersForFillingInPaymentDate.DateOfShipment                   = DateOfShipment;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		Data_Stage,ParametersForFillingInPaymentDate);
	
	DateCredit = Data_Stage.PaymentDate;
	
EndProcedure

&AtClient
Procedure OptionForCountingPostpaidOnChange(Item)
	
	If OptionForCountingPostpaid = PredefinedValue("Enum.PaymentDateCalculationOptions.FixedDate") Then
		PostpaidShift = 0;
	EndIf;
	SetAvailabilityOfElementsByReferenceOption();
	
	Data_Stage = New Structure;
	Data_Stage.Insert("PaymentDate",    DateCredit);
	Data_Stage.Insert("Move",          PostpaidShift);
	Data_Stage.Insert("CalculateFrom", OptionForCountingPostpaid);
	Data_Stage.Insert("PaymentOption",  PredefinedValue("Enum.CustomerPaymentControlOptions.CreditPlanned"));
	Data_Stage.Insert("Formula",        Undefined);
	
	ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersForFillingInPaymentDate.OrderDate                     = OrderDate;
	ParametersForFillingInPaymentDate.ApprovalDate               = ApprovalDate;
	ParametersForFillingInPaymentDate.DateOfShipment                   = DateOfShipment;
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		Data_Stage,ParametersForFillingInPaymentDate);
	
	DateCredit = Data_Stage.PaymentDate;
	
EndProcedure

&AtClient
Procedure DateCreditOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Data_Stage = New Structure;
	Data_Stage.Insert("PaymentDate",    DateCredit);
	Data_Stage.Insert("Move",          0);
	Data_Stage.Insert("CalculateFrom", OptionForCountingPostpaid);
	Data_Stage.Insert("PaymentOption",  PredefinedValue("Enum.CustomerPaymentControlOptions.CreditPlanned"));
	Data_Stage.Insert("Formula",        Undefined);
	
	ShiftFillParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ShiftFillParameters.OrderDate                     = OrderDate;
	ShiftFillParameters.ApprovalDate               = ApprovalDate;
	ShiftFillParameters.DateOfShipment                   = DateOfShipment;
	ShiftFillParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ShiftFillParameters.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ShiftFillParameters.Calendar                      = Calendar;
	
	PaymentStepsClient.PaymentScheduleStepsPaymentDateOnChange(
		Data_Stage,ShiftFillParameters);
	
	PostpaidShift = Data_Stage.Move;
	
EndProcedure

&AtClient
Procedure ForeignCurrencyTransactionOnChange(Item)
	
	IfYouChangePaymentInServerCurrency();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentScheduleSteps

&AtClient
Procedure PaymentScheduleStepsAfterDeleteRow(Item)
	
	SortPaymentStages();
	ClearSumsOfDeviationsOfMeasuredGoods();
	CalculateTotals_(ThisObject);
	ThereAreManualChangesToPaymentSchedule = True;
	
EndProcedure

&AtClient
Procedure PaymentScheduleStepsOnEditEnd(Item, NewRow, CancelEdit)
	
	SortPaymentStages();
	ClearSumsOfDeviationsOfMeasuredGoods();
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
Procedure PaymentStagesPercentageOfTheDepositForTheContainerOnChange(Item)
	
	PaymentStepsClient.PaymentScheduleStepsPackageDepositPercentageOnChange(
		Items.PaymentScheduleSteps.CurrentData,
		PaymentScheduleSteps,
		DepositAmountUnderTheDocument);
	
	ThereAreManualChangesToPaymentSchedule = True;
	
EndProcedure

&AtClient
Procedure StagesOfPaymentTheAmountOfTheDepositForTheContainerOnChange(Item)
	
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
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = CurrentData.Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		CurrentData,ParametersForFillingInPaymentDate);
	
	ThereAreManualChangesToPaymentSchedule = True;
	
	SortPaymentStages();
	
EndProcedure

&AtClient
Procedure PaymentStagesPaymentOptionOnChange(Item)
	
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
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = CurrentData.Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleControlOptionForChanges(
		CurrentData,ParametersForFillingInPaymentDate);
	
	ThereAreManualChangesToPaymentSchedule = True;
	
	SortPaymentStages();
	
EndProcedure

&AtClient
Procedure PaymentStagesReferenceOptionOnChange(Item)
	
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
	ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ParametersForFillingInPaymentDate.Calendar                      = CurrentData.Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		CurrentData,ParametersForFillingInPaymentDate);
	
	ThereAreManualChangesToPaymentSchedule = True;
	
	SortPaymentStages();
	
EndProcedure

&AtClient
Procedure PaymentStagesPaymentDateOnChange(Item)
	
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
	ShiftFillParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ShiftFillParameters.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ShiftFillParameters.Calendar                      = CurrentData.Calendar;
	
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

&AtClient
Procedure PaymentScheduleStepsSelection(Item, RowSelected, Field, StandardProcessing)
	If Field.Name = "StagesOfPaymentOrder" 
		And ValueIsFilled(Items.PaymentScheduleSteps.CurrentData.OrderDocument) Then
		ShowValue(Undefined, Items.PaymentScheduleSteps.CurrentData.OrderDocument);
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
	ItemField.Field = New DataCompositionField(Items.DateCredit.Name);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DateCredit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("DatePrepayment");

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DateCredit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Date(1,1,1);

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentStagesPaymentPercentage.Name);

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
	ItemFilter.LeftValue = New DataCompositionField("PaymentAmountAgainstTheDocument");
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
	ItemFilter.LeftValue = New DataCompositionField("PaymentAmountAgainstTheDocument");
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
	ItemFilter.LeftValue = New DataCompositionField("PaymentAmountAgainstTheDocument");
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
	ItemFilter.LeftValue = New DataCompositionField("DepositAmountUnderTheDocument");
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
	ItemFilter.LeftValue = New DataCompositionField("PaymentAmountAgainstTheDocument");
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
	ItemFilter.LeftValue = New DataCompositionField("DepositAmountUnderTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentStagesPaymentPercentage.Name);

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
	ItemField.Field = New DataCompositionField(Items.PaymentStagesPercentageOfTheDepositForTheContainer.Name);

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
	ItemFilter.LeftValue = New DataCompositionField("DepositAmountUnderTheDocument");
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
	ItemFilter.LeftValue = New DataCompositionField("DepositAmountUnderTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentStagesPercentageOfTheDepositForTheContainer.Name);

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
	ItemField.Field = New DataCompositionField(Items.PaymentStagesPaymentPercentage.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentStagesPercentageOfTheDepositForTheContainer.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.PackageDepositPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.PaymentPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentStagesPercentageOfTheDepositForTheContainer.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesOfPaymentTheAmountOfTheDepositForTheContainer.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PackageDepositIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//
	Item = ConditionalAppearance.Items.Add();

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentStagesReferenceOption.Name);

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
	ItemField.Field = New DataCompositionField(Items.StagesOfPaymentShift.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.CalculateFrom");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PaymentDateCalculationOptions.FixedDate;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);

	If Parameters.SpecialStageHeadersForTheReturn Then

		Item = ConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.PaymentStagesPaymentOption.Name);

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.PaymentOption");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.CustomerPaymentControlOptions.PrepaymentBeforeProvision;

		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ứng trước hoặc trả lại (trước khi đảm bảo)';
														|ru = 'Аванс или возврат (до обеспечения)';
														|en = 'Advance or return (before supply)'; fa = 'Advance or return (before supply)';
														|it = 'Anticipo o reso (prima della cauzione)';
														|pl = 'Zaliczka lub zwrot (do zaopatrzenia)';
														|tr = 'Avans veya iade (tedarike kadar)'"));

		//

		Item = ConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.PaymentStagesPaymentOption.Name);

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.PaymentOption");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment;

		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Trả trước hoặc trả lại (trước khi giao hàng)';
														|ru = 'Предоплата или возврат (до отгрузки)';
														|en = 'Prepayment or return (before shipment)'; fa = 'Prepayment or return (before shipment)';
														|it = 'Prepagamento o reso (prima dello scarico)';
														|pl = 'Przedpłata lub zwrot (do wysyłki)';
														|tr = 'Ön ödeme veya iade (sevkiyata kadar)'"));

		
		//

		Item = ConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.PaymentStagesPaymentOption.Name);

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("PaymentScheduleSteps.PaymentOption");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.CustomerPaymentControlOptions.CreditAfterShipment;

		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Trả sau hoặc trả lại (sau khi giao hàng)';
														|ru = 'Кредит или возврат (после отгрузки)';
														|en = 'Credit or return (after shipment)'; fa = 'Credit or return (after shipment)';
														|it = 'Credito o reso (dopo lo scarico)';
														|pl = 'Pożyczka lub zwrot (po wysyłce)';
														|tr = 'Kredi veya iade (sevkiyattan sonra)'"));

	EndIf;
	
EndProcedure

#Region PaymentSchedule

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
	FillParameters.Insert("PaymentScheduleCompleted", UsePaymentSchedules And ValueIsFilled(PaymentSchedule));
	FillParameters.Insert("DivideAmount", False);
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
		PaymentAmountPrepayment      = 0;
		PaymentAmountCredit          = 0;
		DepositAmountForPackagingPrepayment = 0;
		TheAmountOfTheDepositForTheContainerLoan     = 0;
		PaymentStepsClient.NotifyAboutImpossibilityOfFillingInStagesOfPaymentSchedule();
		CalculateTotals_(ThisObject);
		Return;
	
	EndIf;
	
	If PaymentAmountAgainstTheDocument = PaymentAmountByStage  And DepositAmountUnderTheDocument = AmountOfCollateralByStages Then
	
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
								|pl = 'Wypełnić ponownie etapy płatności%SourceOfFilling%?';
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
							|pl = 'Wypełnić ponownie etapy płatności%SourceOfFilling% lub przydzielić wartość według istniejących etapów?';
							|tr = '%SourceOfFilling% ödeme aşamalarını yeniden doldur veya tutarı mevcut aşamalar arasında dağıt?'");
	
	Else
		FillParameters.ReFillStages = True;
	EndIf;
	
	If Not IsBlankString(QueryText) Then
		
		If ValueIsFilled(ContractSchedule) Then 
			QueryText = StrReplace(QueryText, "%SourceOfFilling%", NStr("vi = 'theo lịch biểu thực hiện hợp đồng';
																		|ru = 'по графику исполнения договора';
																		|en = 'under contract schedule'; fa = 'under contract schedule';
																		|it = 'in base al grafico di esecuzione dell''accordo';
																		|pl = 'według harmonogramu wykonania umowy';
																		|tr = 'sözleşme programına göre'"));
		ElsIf ValueIsFilled(PaymentSchedule) Then 
			QueryText = StrReplace(QueryText, "%SourceOfFilling%", NStr("vi = 'theo lịch biểu thanh toán';
																		|ru = 'по графику оплаты';
																		|en = 'under payment schedule'; fa = 'under payment schedule';
																		|it = 'in base al grafico di pagamento';
																		|pl = 'według harmonogramu płatności';
																		|tr = 'ödeme planına göre'"));
		ElsIf AgreementScheduleIsFilledIn Then
			QueryText = StrReplace(QueryText, "%SourceOfFilling%", NStr("vi = 'theo thỏa thuận';
																		|ru = 'по соглашению';
																		|en = 'by agreement'; fa = 'by agreement';
																		|it = 'secondo l''accordo';
																		|pl = 'według umowy';
																		|tr = 'anlaşmaya göre'"));
		Else
			QueryText = StrReplace(QueryText, "%SourceOfFilling%", NStr("vi = 'theo mặc định';
																		|ru = 'по умолчанию';
																		|en = 'default'; fa = 'پیش‌فرض';
																		|it = 'per default';
																		|pl = 'domyślnie';
																		|tr = 'varsayılan'"));
		EndIf;
		
		Notification = New CallbackDescription("SelectingFillSourceCompletion", ThisObject, FillParameters);
		ShowQueryBox(Notification , QueryText, AnswersOptions);
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
			DistributeAmountByStagesAndOrdersOfPaymentSchedule();
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
	FillParameters.TheseAreSettlementsWithCustomers            = True;
	FillParameters.ThisIsTransferOfOwnership2_5 = ThisIsTransferOfOwnership2_5;
	
	PaymentStepsServer.FillInPaymentStagesOfDocumentForOrders(PaymentScheduleSteps, FillParameters);
	
	If SimplifiedMode Then
		ConvertStageTableToSimplifiedModeData(PaymentScheduleSteps.Unload());
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPaymentStages(FillOutPaymentForm = False)
	
	FillParameters = PaymentStepsServer.ParametersForFillingInPaymentStages();
	
	FillParameters.OrderDate                      = OrderDate;
	FillParameters.ApprovalDate                = ApprovalDate;
	If MultipleShippingDates Then
		FillParameters.TabularSection                  = TabularSection.Unload();
	Else
		FillParameters.DateOfShipment                    = DateOfShipment;
	EndIf;
	FillParameters.DateOfTransferOfTitleToGoods  = DateOfTransferOfTitleToGoods;
	FillParameters.ThereIsDateOfTransferOfOwnership = ThereIsDateOfTransferOfOwnership;
	FillParameters.DeadlineOfTransferOfTitleToGoods  = DeadlineOfTransferOfTitleToGoods;
	
	FillParameters.PayAmount                     = PaymentAmountAgainstTheDocument;
	FillParameters.PackageDepositValue               = DepositAmountUnderTheDocument;
	
	FillParameters.AgreementScheduleIsFilledIn        = AgreementScheduleIsFilledIn;
	FillParameters.Terms                      = Terms;
	FillParameters.ContractSchedule        = ContractSchedule;
	FillParameters.PaymentSchedule                    = PaymentSchedule;
	
	FillParameters.ARAPObjectSettings                 = ARAPObjectSettings;
	FillParameters.TheseAreSettlementsWithCustomers            = True;
	FillParameters.ThisIsOrder                        = ThisIsOrder;
	FillParameters.NoPrepaymentControl           = NoPrepaymentControl;
	FillParameters.InvoiceForOrders              = InvoiceForOrders;
	FillParameters.Calendar                       = Calendar;
	FillParameters.ThisIsTransferOfOwnership2_5 = ThisIsTransferOfOwnership2_5;
	
	PaymentStepsServer.FillInPaymentStages(PaymentScheduleSteps, FillParameters);
	
	If FillOutPaymentForm Then
		FillInPaymentForm();
	EndIf;
	
	If SimplifiedMode Then
		ConvertStageTableToSimplifiedModeData(PaymentScheduleSteps.Unload());
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPaymentForm()
	
	If UsePaymentSchedules And ValueIsFilled(PaymentSchedule) Then
		SourceOfPaymentForm = PaymentSchedule;
	ElsIf ValueIsFilled(Terms) Then
		SourceOfPaymentForm = Terms;
	EndIf;
	
	If ValueIsFilled(SourceOfPaymentForm) Then
		
		SourcePaymentForm = Common.ObjectAttributeValue(SourceOfPaymentForm, "PaymentMethod");
	
		If ValueIsFilled(SourcePaymentForm) And PaymentMethod <> SourcePaymentForm Then
			PaymentMethod = SourcePaymentForm;
			WhenChangingPaymentFormServer();
		EndIf;
		
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

&AtServer
Procedure DistributeAmountByStagesAndOrdersOfPaymentSchedule()
	
	FillParameters = PaymentStepsServer.ParametersForFillingPaymentStagesForOrders();
	
	FormTabularSection = TabularSection.Unload();
	FormTabularSection.Columns.OrderDocument.Name               = FieldNameOrder;
	FillParameters.TabularSection                  = FormTabularSection;
	FillParameters.DateOfShipment                    = DateOfShipment;
	FillParameters.DateOfTransferOfTitleToGoods  = DateOfTransferOfTitleToGoods;
	FillParameters.Calendar                       = Calendar;
	FillParameters.ARAPObjectSettings                 = ARAPObjectSettings;
	FillParameters.TheseAreSettlementsWithCustomers            = True;
	
	PaymentStepsServer.DistributeAmountsOfDocumentPaymentStagesByOrders(PaymentScheduleSteps, FillParameters);
	
EndProcedure

&AtServer
Function CheckPaymentPutInStorage()
	
	Cancel = False;
	
	For Each Page1 In PaymentScheduleSteps Do
		DependsOnShipmentDate = PaymentStepsCached.StringOfStagesDependsOnDateOfShipment(Page1.CalculateFrom,Page1.Formula);
		If Not DependsOnShipmentDate And ValueIsFilled(Page1.DateOfShipment) Then
			Page1.DateOfShipment = Date(1,1,1);
		ElsIf DependsOnShipmentDate And ValueIsFilled(DateOfShipment) And Not ValueIsFilled(Page1.DateOfShipment) Then
			Page1.DateOfShipment = DateOfShipment;
		EndIf;
	EndDo;
	
	If Not ((ThisIsOrder And ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments)
		Or ThisIsOrder And ValueIsFilled(ContractSchedule) And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
																		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)) Then
		
		ParametersStructure = PaymentStepsServer.ParametersForCheckingWhetherStagesAreFilledInCorrectly();
		If ThisIsOrder Or InvoiceForOrders Then
			ParametersStructure.Date               = OrderDate;
		ElsIf ThisIsTransferOfOwnership2_5 Then
			ParametersStructure.Date               = DateOfTransferOfTitleToGoods;
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
		MeasuringGoodsVarianceAmount= 0;
		DepositAmountForPackagingPrepayment = 0;
		TheAmountOfTheDepositForTheContainerLoan     = 0;
		
	EndIf;
	
	SetAvailabilityOfItemsInOrderOfCalculation();
	ConfigureFormElementsWhenChangingOrderOfCalculations();
	
EndProcedure

&AtClient
Procedure PaymentAmountOnChange(Sum, Percent, DependentAmount, DependentPercentage, AmountTotal)

	If Not ThereIsPrepayment Then
		Return;
	EndIf;

	If AmountTotal <> 0 Then
		
		Percent           = Min(Sum * 100 / AmountTotal, 100);
		DependentAmount    = Max(AmountTotal - Sum, 0);
		DependentPercentage  = 100 - Percent;
		
	EndIf;
	
	ClearSumsOfDeviationsOfMeasuredGoods();
	
	CalculateTotals_(ThisObject);

EndProcedure

&AtClient
Procedure PaymentPercentageOnChange(Sum, Percent, DependentAmount, DependentPercentage, AmountTotal)

	If Not ThereIsPrepayment Then
		Return;
	EndIf;

	Sum            = AmountTotal * Percent / 100;
	DependentAmount   = AmountTotal - Sum;
	DependentPercentage = 100 - Percent;

	ClearSumsOfDeviationsOfMeasuredGoods();
	
	CalculateTotals_(ThisObject);

EndProcedure

&AtServer
Procedure IfYouChangePaymentInServerCurrency()
	
	If Not ForeignCurrencyTransaction Then
		
		If ValueIsFilled(CashAccount) And Not Common.ObjectAttributeValue(CashAccount,"CashCurrency")=CurrencyOfComplianceAccounting Then
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
Procedure CustomizeFormElements()
	
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
		Items, ItemArray, "Visible", PackageDepositIsRequired);
	
	If Not Parameters.Property("CashAccount") Or Parameters.CashAccount = Undefined Then
		Items.CashAccount.Visible = False;
	EndIf;
	
	If Not Parameters.Property("BankAccount") Or Parameters.BankAccount = Undefined Then
		Items.BankAccount.Visible = False;
	EndIf;
	
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
	
	SetAccessibilityOfFillButtons();
	
	If SelfServiceMode And Not InvoiceForOrders Then
		
		ItemArray = New Array;
		ItemArray.Add("ARAPObjectSettings");
		ItemArray.Add("CashAccount");
		ItemArray.Add("BankAccount");
		ItemArray.Add("DatePrepayment");
		ItemArray.Add("PaymentAmountPrepayment");
		ItemArray.Add("PaymentPercentagePrepayment");
		ItemArray.Add("DepositAmountForPackagingPrepayment");
		ItemArray.Add("DateCredit");
		ItemArray.Add("PaymentAmountCredit");
		ItemArray.Add("TheAmountOfTheDepositForTheContainerLoan");
		ItemArray.Add("PercentageOfPaymentCredit");
		ItemArray.Add("ThePercentageOfTheDepositForTheContainerLoan");
		ItemArray.Add("PaymentScheduleSteps");
		If ValueIsFilled(Terms) And ValueIsFilled(Common.ObjectAttributeValue(Terms, "PaymentMethod")) Then
			ItemArray.Add("PaymentMethod");
		EndIf;
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
		SelfServiceServer.ManagingFormElementPaymentForm(ThisObject, Terms, Items.PaymentMethod);
		
		ItemArray = New Array;
		ItemArray.Add("PaymentSchedule");
		ItemArray.Add("FillInTheStagesOfThePaymentScheduleForm");
		ItemArray.Add("FillInTheStagesOfThePaymentScheduleTable");
		ItemArray.Add("DistributeAmountForm");
		ItemArray.Add("DistributeAmountTable");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", False);
		
	EndIf;
	
	If AllowedDocumentVarianceAmount > 0 And ThisIsOrder
		And UseAllowableDeviationOfMeasuringGoodsShipmentReceiving Then
		
		Array = New Array;
		Array.Add(PictureLib.Attention16);
		Array.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Do giao hàng vượt quá biên chênh lệch cho phép
						| số tiền trả trước có thể vượt quá %1 %2';
						|ru = 'Вследствие превышения отгрузки мерных товаров в пределах допустимых отклонений
						| сумма предоплаты может быть превышена на %1 %2';
						|en = 'As measured goods shipment is exceeded within the allowable deviation,
						| the prepayment amount can be exceeded by %1 %2'; fa = 'As measured goods shipment is exceeded within the allowable deviation,
						| the prepayment amount can be exceeded by %1 %2';
						|it = 'A causa del superamento dei limiti concessi per la spedizione di merci
						| l''importo del pagamento anticipato può essere maggiore di %1 %2';
						|pl = 'Z powodu przekroczenia wysyłki wyrobów metrażowych w granicach odchyłki dopuszczalnej,
						| wartość przedpłaty może zostać przekroczona o %1 %2';
						|tr = 'Ölçülü ürün sevkiyatının mümkün sapma
						| limitleri içinde aşılması nedeniyle ön ödeme tutarı şu kadar aşılabilir %1%2'"),
			AllowedDocumentVarianceAmount,
			Currency));
		
		Items.LabelRejectionOfPaymentForDimensionalGoods.Title = New FormattedString(Array);
		
	Else
		
		ItemArray = New Array;
		ItemArray.Add("GroupRejectionOfPaymentForMeasuredGoods");
		ItemArray.Add("LabelRejectionOfPaymentForDimensionalGoods");
		ItemArray.Add("MeasuringGoodsVarianceAmount");
		ItemArray.Add("TheAmountOfVarianceInTheDocument");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", False);
		
	EndIf;
	
	If UserRightsCached.ThisIsPartner() Then
		Items.FillInTheStagesOfThePaymentScheduleForm.Visible = False;
		Items.FillInTheStagesOfThePaymentScheduleTable.Visible = False;
	EndIf;
	
	If UseNegativePaymentAmounts Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "PaymentScheduleStepsDateShift", "Title",
			NStr("vi = 'Ngày thanh toán';
				|ru = 'Дата платежа';
				|en = 'Payment date'; fa = 'تاریخ پرداخت';
				|it = 'Data di pagamento';
				|pl = 'Data płatności';
				|tr = 'Ödeme tarihi'"));
	EndIf;
	
	Items.PaymentStagesPaymentOption.ListChoiceMode = True;
	
	If Parameters.SpecialStageHeadersForTheReturn Then
		
		TMCommonUseClientServer.SetFormItemProperty(Items, "PrepaymentGroup", "Title",
			NStr("vi = 'Thanh toán hoặc trả lại trước khi giao hàng';
				|ru = 'Оплата или возврат до отгрузки';
				|en = 'Payment or return before shipment'; fa = 'Payment or return before shipment';
				|it = 'Pagamento o reso prima della spedizione';
				|pl = 'Płatność lub zwrot przed wysyłką';
				|tr = 'Ödeme veya sevkiyat öncesi iade'"));
		TMCommonUseClientServer.SetFormItemProperty(Items, "CreditGroup", "Title",
			NStr("vi = 'Thanh toán tùy ý hoặc trả lại';
				|ru = 'Произвольная оплата или возврат';
				|en = 'Arbitrary payment or return'; fa = 'Arbitrary payment or return';
				|it = 'Pagamento arbitrario o reso';
				|pl = 'Dowolna płatność lub zwrot';
				|tr = 'İsteğe bağlı ödeme veya iade'"));
		
	EndIf;
	
	If ValueIsFilled(AddressInTempStorage) Then
	
		If ThisIsOrder Then
			Items.PaymentStagesPaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeProvision);
		EndIf;
		If Not NoPrepaymentControl Then
			Items.PaymentStagesPaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment);
		EndIf;
		Items.PaymentStagesPaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.CreditAfterShipment);
		Items.PaymentStagesPaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.CreditPlanned);
		
		Items.PaymentStagesReferenceOption.ListChoiceMode = True;
		Items.CountdownOptionPrepayment.ListChoiceMode = True;
		Items.OptionForCountingPostpaid.ListChoiceMode = True;
		
		Items.PaymentStagesReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FixedDate);
		Items.CountdownOptionPrepayment.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FixedDate);
		Items.OptionForCountingPostpaid.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FixedDate);
		
		If ThisIsOrder Then
			Items.PaymentStagesReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate);
			Items.CountdownOptionPrepayment.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate);
			Items.OptionForCountingPostpaid.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate);
			
			If GetFunctionalOption("NotBaseVersion") Then
				Items.PaymentStagesReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromApprovalDate);
				Items.CountdownOptionPrepayment.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromApprovalDate);
				Items.OptionForCountingPostpaid.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromApprovalDate);
			EndIf;
			
		ElsIf ValueIsFilled(ContractSchedule) And Not ThisIsOrder Then
			Items.PaymentStagesReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate, NStr("vi = 'từ ngày hợp đồng';
																														|ru = 'от даты договора';
																														|en = 'from contract date'; fa = 'from contract date';
																														|it = 'dalla data dell''accordo';
																														|pl = 'od daty umowy';
																														|tr = 'sözleşme tarihinden'"));
			Items.CountdownOptionPrepayment.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate, NStr("vi = 'từ ngày hợp đồng';
																													|ru = 'от даты договора';
																													|en = 'from contract date'; fa = 'from contract date';
																													|it = 'dalla data dell''accordo';
																													|pl = 'od daty umowy';
																													|tr = 'sözleşme tarihinden'"));
			Items.OptionForCountingPostpaid.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate, NStr("vi = 'từ ngày hợp đồng';
																													|ru = 'от даты договора';
																													|en = 'from contract date'; fa = 'from contract date';
																													|it = 'dalla data dell''accordo';
																													|pl = 'od daty umowy';
																													|tr = 'sözleşme tarihinden'"));
		EndIf;
		
		Items.PaymentStagesReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		Items.CountdownOptionPrepayment.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		Items.OptionForCountingPostpaid.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
		
		Items.PaymentStagesReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromShipmentDate);
		Items.OptionForCountingPostpaid.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromShipmentDate);
		
		If ThereIsDateOfTransferOfOwnership Then
			Items.PaymentStagesReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods);
			Items.OptionForCountingPostpaid.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods);
		EndIf;
		
		Items.PaymentStagesReferenceOption.ChoiceList.Add(Enums.PaymentDateCalculationOptions.Formula);
		
	Else
		
		Items.OptionForCountingPostpaid.ReadOnly = True;
		Items.PaymentAmountCredit.ReadOnly = True;
		Items.PercentageOfPaymentCredit.ReadOnly = True;
		
	EndIf;
	
	Items.ForeignCurrencyTransaction.Visible = ARAPCurrency <> CurrencyOfComplianceAccounting Or ForeignCurrencyTransaction;
	
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
		ItemArray.Add("DistributeAmountForm");
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", False);
	
	Items.PrepaymentGroup.Visible = ThereIsPrepayment;
	UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	
	ByOrders = 
		InvoiceForOrders
			And Not ValueIsFilled(ContractSchedule)
			And ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments");
	
	AccordingToExecutionSchedule = Not ThisIsOrder 
		And ValueIsFilled(ContractSchedule)
		And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts")
				Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice"));
	//It is prohibited to change the schedule if the invoice for orders and orders have formed a payment plan, or if it is an invoice according to the contract execution schedule.
	Items.PaymentScheduleSteps.ChangeRowSet = Not ByOrders And Not AccordingToExecutionSchedule;
	
	// If the Contract schedule is set, then the calendar is taken from the Contract schedule, and the payment schedule is hidden
	// For a non-order invoice, the payment schedule is visible in any order of calculations
	// For the order of calculations according to settlement documents, the payment schedule is visible in the invoice and hidden in the order
	Items.PaymentSchedule.Visible = Not ValueIsFilled(ContractSchedule) 
		And (ThisIsOrder 
				And ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")
			Or InvoiceForOrders 
				And ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")
			Or Not ThisIsOrder
				And Not InvoiceForOrders);
			
	
	//The order is visible when calculating orders and when calculating contracts and contracts/invoices - if the payment schedule is specified in the orders.
	Items.StagesOfPaymentOrder.Visible = ByOrders;
	Items.StagesOfPaymentInExcessOfOrder.Visible = ByOrders And UseAdvancedFeaturesOfSalesOrder And Not OrderAsAProformaInvoice;
	
	If ByOrders Then
		
		ItemArray = New Array;
		ItemArray.Add("PaymentMethod");
		ItemArray.Add("ForeignCurrencyTransaction");
		ItemArray.Add("CashAccount");
		ItemArray.Add("BankAccount");
		ItemArray.Add("PaymentStagesPaymentOption");
		ItemArray.Add("PaymentStagesPaymentPercentage");
		ItemArray.Add("PaymentScheduleStepsPaymentAmount");
		//tare is not in the execution schedules
		ItemArray.Add("PaymentStagesPercentageOfTheDepositForTheContainer");
		ItemArray.Add("StagesOfPaymentTheAmountOfTheDepositForTheContainer");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
	EndIf;
	
	ItemArray = New Array;
	
	ItemArray.Add("PaymentMethod");
	ItemArray.Add("ForeignCurrencyTransaction");
	ItemArray.Add("CashAccount");
	ItemArray.Add("BankAccount");
	ItemArray.Add("PaymentStagesPercentageOfTheDepositForTheContainer");
	ItemArray.Add("StagesOfPaymentTheAmountOfTheDepositForTheContainer");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", ByOrders);
	
	ItemArray = New Array;
	
	ItemArray.Add("PaymentStagesPaymentOption");
	ItemArray.Add("PaymentStagesReferenceOption");
	ItemArray.Add("PaymentMilestonesFormula");
	ItemArray.Add("PaymentStagesPaymentPercentage");
	ItemArray.Add("PaymentStagesPaymentAmount");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", ByOrders Or AccordingToExecutionSchedule);
	
	//Hiding the payment stages for an order that does not form a payment plan.
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
	
EndProcedure

&AtServer
Procedure SetAccessibilityOfFillButtons()
	
	ElementAvailability = DepositAmountUnderTheDocument <> 0 Or PaymentAmountAgainstTheDocument <> 0;
	Items.FillInTheStagesOfThePaymentScheduleForm.Enabled   = ElementAvailability;
	Items.FillInTheStagesOfThePaymentScheduleTable.Enabled = ElementAvailability;
	Items.DistributeAmountForm.Enabled             = ElementAvailability;
	Items.DistributeAmountTable.Enabled           = ElementAvailability;
	
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
		
		If Parameters.Property("AvailablePaymentTerms") Then
			AvailablePaymentTerms = Parameters.AvailablePaymentTerms;
		Else
			AvailablePaymentTerms = ARAPAccountingServer.AvailableCalculationProceduresForDocument(
				ARAPObjectSettings,
				ARAPAccountingServer.ARAPObjectSettings(Parameters.ThisIsOrder,,Terms,Contract),
				Parameters.InvoiceForOrders,
				Parameters.ThisIsOrder);
		EndIf;
			
		If AvailablePaymentTerms.Count() > 1 And Not SelfServiceMode Then
			
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
	
	ScheduleEditingIsProhibited = ValueIsFilled(ContractSchedule) And ThisIsOrder
									And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
										Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice) ;
	
	If ThisIsOrder And ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
		Or ScheduleEditingIsProhibited
		Or PaymentAmountAgainstTheDocument < 0 
		Or DepositAmountUnderTheDocument < 0 Then
		
		Items.GroupPages.Enabled                   = False;
		Items.FillInTheStagesOfThePaymentScheduleForm.Enabled = False;
		Items.DistributeAmountForm.Enabled           = False;
		Items.PaymentSchedule.Enabled                     = False;
		Items.PaymentMethod.Enabled                      = False;
		Items.ForeignCurrencyTransaction.Enabled                    = False;
		Items.CashAccount.Enabled                            = False;
		Items.BankAccount.Enabled                   = False;
		
		If PaymentAmountAgainstTheDocument < 0 
			Or DepositAmountUnderTheDocument < 0 Then
			Items.GroupPages.Visible                 = False;
			Items.FooterGroup.Visible                   = False;
		EndIf;
		
	Else
		
		Items.GroupPages.Enabled = True;
		Items.PaymentSchedule.Enabled   = True;
		Items.PaymentMethod.Enabled    = True;
		Items.ForeignCurrencyTransaction.Enabled  = True;
		
		SetAccessibilityOfFillButtons();
		SetAvailabilityOfItemsByPaymentForm();
		
	EndIf;
	
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
	ElsIf Form.UsePaymentSchedules And ValueIsFilled(Form.PaymentSchedule) Then
		TextOfFillButton = NStr("vi = 'Điền theo lịch biểu';
								|ru = 'Заполнить по графику';
								|en = 'Fill in by schedule'; fa = 'تکمیل بر اساس برنامه زمان‌بندی';
								|it = 'Compilare il programma';
								|pl = 'Wypełnij według harmonogramu';
								|tr = 'Programa göre doldur'");
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
	
	ItemArray.Add("PaymentStagesPaymentAmount");
	ItemArray.Add("PaymentAmountPrepayment");
	ItemArray.Add("PaymentAmountCredit");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "TypeRestriction", RestrictedType);
	
EndProcedure

&AtServer
Procedure UpdateServiceDetails();
	
	SimplifiedMode = Not ValueIsFilled(AddressInTempStorage)
		Or UseSimplifiedPaymentSchemeInSales
			And Not (InvoiceForOrders And ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments);
	
	//More than one payment date
	ThereIsPrepayment = SimplifiedMode And ValueIsFilled(AddressInTempStorage) And Not NoPrepaymentControl;
	
	If SimplifiedMode Then
		
		If PaymentScheduleSteps.Count() > 0 Then
			ConvertStageTableToSimplifiedModeData(PaymentScheduleSteps);
		ElsIf Not ThereIsPrepayment Then
			PaymentAmountCredit            = PaymentAmountAgainstTheDocument;
			TheAmountOfTheDepositForTheContainerLoan       = DepositAmountUnderTheDocument;
			MeasuringGoodsVarianceAmount  = DocumentVarianceAmount;
			ThePercentageOfTheDepositForTheContainerLoan     = 100;
			PercentageOfPaymentCredit          = 100;
			DateCredit                    = PaymentDate;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function PutItInTemporaryStorageOnServer()
	
	Return PutToTempStorage(PaymentScheduleSteps.Unload(), CalledFormID);
	
EndFunction

&AtServer
Function ConvertPutIntoTemporaryStorage()
	
	PaymentScheduleSteps.Load(ConvertSimplifiedModeDataToStepTable());
	Return PutItInTemporaryStorageOnServer();
	
EndFunction

&AtServer
Function ConvertSimplifiedModeDataToStepTable()
	
	ResultTable1 = PaymentScheduleSteps.Unload();
	ResultTable1.Clear();
	
	Total_PaymentAmount = PaymentAmountPrepayment + PaymentAmountCredit;
	SumOfDeviationToDistribution = MeasuringGoodsVarianceAmount;

	If StageContainsData("Prepayment") And PaymentAmountPrepayment + DepositAmountForPackagingPrepayment > 0 Then
		
		PrepaymentLine = ResultTable1.Add();
		PrepaymentLine.PaymentOption           = ?(ValueIsFilled(ControlOptionPrepayment),
		                                             ControlOptionPrepayment,
		                                             Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment);
		PrepaymentLine.CalculateFrom          = CountdownOptionPrepayment;
		PrepaymentLine.Move                   = ShiftPrepayment;
		PrepaymentLine.PaymentDate             = DatePrepayment;
		PrepaymentLine.PaymentAmount            = PaymentAmountPrepayment;
		PrepaymentLine.PaymentPercentage          = PaymentPercentagePrepayment;
		If PackageDepositIsRequired Then
			PrepaymentLine.PackageDepositValue   = DepositAmountForPackagingPrepayment;
			PrepaymentLine.PackageDepositPercentage = PercentageOfTheDepositForTheContainerPrepayment;
		EndIf;
		
		If Total_PaymentAmount > 0 Then
			CoefficientOfTotal = PaymentAmountPrepayment/Total_PaymentAmount;
		Else
			CoefficientOfTotal = 0;
		EndIf;
		
		PrepaymentLine.MeasuringGoodsVarianceAmount = Round(SumOfDeviationToDistribution * CoefficientOfTotal, 2, RoundMode.Round15as20);
		SumOfDeviationToDistribution = SumOfDeviationToDistribution - PrepaymentLine.MeasuringGoodsVarianceAmount;
		
	EndIf;
	
	If StageContainsData("Credit") And PaymentAmountCredit + TheAmountOfTheDepositForTheContainerLoan > 0 Then
		
		CreditLine_ = ResultTable1.Add();
		CreditLine_.PaymentOption           = ?(ValueIsFilled(OptionOfPostpaidControl),
		                                          OptionOfPostpaidControl,
		                                          Enums.CustomerPaymentControlOptions.CreditPlanned);
		CreditLine_.CalculateFrom          = OptionForCountingPostpaid;
		CreditLine_.Move                   = PostpaidShift;
		CreditLine_.PaymentDate             = DateCredit;
		CreditLine_.PaymentAmount            = PaymentAmountCredit;
		CreditLine_.PaymentPercentage          = PercentageOfPaymentCredit;
		If PackageDepositIsRequired Then
			CreditLine_.PackageDepositValue   = TheAmountOfTheDepositForTheContainerLoan;
			CreditLine_.PackageDepositPercentage = ThePercentageOfTheDepositForTheContainerLoan;
		EndIf;
		
		CreditLine_.MeasuringGoodsVarianceAmount = SumOfDeviationToDistribution;
		
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
	
	MeasuringGoodsVarianceAmount = Result.MeasuringGoodsVarianceAmount;
	
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
	Form.MeasuringGoodsVarianceAmount  = 0;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form)
	
	Form.LineNumberOfFullPayment = 0;
	Form.LineNumberOfDepositFullPayment = 0;
	Form.TotalPaymentPercentage = 0;
	Form.DepositPercentageTotal   = 0;
	
	If Form.SimplifiedMode Then
		
		Form.TotalPaymentPercentage = Form.PaymentPercentagePrepayment + Form.PercentageOfPaymentCredit;
		Form.DepositPercentageTotal   = Form.PercentageOfTheDepositForTheContainerPrepayment + Form.ThePercentageOfTheDepositForTheContainerLoan;
		
	Else
		
		Form.MeasuringGoodsVarianceAmount = 0;
		
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
			
			Form.MeasuringGoodsVarianceAmount = Form.MeasuringGoodsVarianceAmount + CurRow.MeasuringGoodsVarianceAmount;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SortPaymentStages()
	
	PaymentStepsClientServer.SortStageTable(PaymentScheduleSteps);
	
	If Not SimplifiedMode Then
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
	
	If Not SelfServiceMode Then
		ChoiceList.Add(Enums.PaymentForms.EmptyRef(), NStr("vi = 'Bất kỳ';
															|ru = 'Любая';
															|en = 'Any'; fa = 'هر';
															|it = 'Qualsiasi';
															|pl = 'Any';
															|tr = 'Herhangi'"));
	EndIf;
	
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

&AtClient
Procedure ClearSumsOfDeviationsOfMeasuredGoods()
	
	If MeasuringGoodsVarianceAmount > 0 Then
		
		TMCommonUseClientServer.FillInCollectionPropertyValues(PaymentScheduleSteps, 0, "MeasuringGoodsVarianceAmount");
		MeasuringGoodsVarianceAmount = 0;
		
		If SimplifiedMode Then
			PaymentPercentageOnChange(PaymentAmountPrepayment, PaymentPercentagePrepayment,
									PaymentAmountCredit, PercentageOfPaymentCredit, PaymentAmountAgainstTheDocument);
			PaymentPercentageOnChange(DepositAmountForPackagingPrepayment, PercentageOfTheDepositForTheContainerPrepayment, 
								TheAmountOfTheDepositForTheContainerLoan, ThePercentageOfTheDepositForTheContainerLoan, DepositAmountUnderTheDocument);
			PaymentPercentageOnChange(PaymentAmountCredit, PercentageOfPaymentCredit, 
								PaymentAmountPrepayment, PaymentPercentagePrepayment, PaymentAmountAgainstTheDocument);
			PaymentPercentageOnChange(TheAmountOfTheDepositForTheContainerLoan, ThePercentageOfTheDepositForTheContainerLoan,
								DepositAmountForPackagingPrepayment, PercentageOfTheDepositForTheContainerPrepayment, DepositAmountUnderTheDocument);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Function EditParameters()
	
	OpenStructure = New Structure;
	OpenStructure.Insert("Currency",                          Currency);
	OpenStructure.Insert("TheseAreSettlementsWithCustomers",            True);
	OpenStructure.Insert("Calendar",                       Calendar);
	OpenStructure.Insert("OrderDate",                      OrderDate);
	OpenStructure.Insert("ApprovalDate",                ApprovalDate);
	OpenStructure.Insert("DeadlineOfTransferOfTitleToGoods",  DeadlineOfTransferOfTitleToGoods);
	OpenStructure.Insert("DateOfTransferOfTitleToGoods",  DateOfTransferOfTitleToGoods);
	OpenStructure.Insert("PaymentAmountAgainstTheDocument",          PaymentAmountAgainstTheDocument);
	OpenStructure.Insert("DepositAmountUnderTheDocument",          DepositAmountUnderTheDocument);
	OpenStructure.Insert("ThisIsContract",                      False);
	OpenStructure.Insert("ShipmentDates",                    TabularSection);
	OpenStructure.Insert("PaymentScheduleSteps",              PaymentScheduleSteps);
	OpenStructure.Insert("ThereIsPackage",                        PackageDepositIsRequired);
	
	Return OpenStructure;
	
EndFunction

&AtServer
Procedure CollapsePaymentStages()
	
	ValueTable = PaymentScheduleSteps.Unload();
	ValueTable.GroupBy("PaymentOption, PaymentDate, CalculateFrom, ExceedingOrder, Formula, Move, DateOfShipment","PaymentAmount,PaymentPercentage,PackageDepositValue,PackageDepositPercentage");
	PaymentScheduleSteps.Load(ValueTable);
	
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
		|	AND ARAPAccountingScheduleAdjustment.BusinessOperation = VALUE(Enum.BusinessTransactions.AdjustCustomerPaymentSchedule)
		|	AND ARAPAccountingScheduleAdjustment.Posted";
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	If Selection.Next() Then
		MessageTemplate = NStr("vi = 'Đã nhập %1 trên cơ sở chứng từ hiện tại.';
								|ru = 'На основании текущего документа уже введена %1.';
								|en = '%1 is already entered based on the current document.'; fa = '%1 is already entered based on the current document.';
								|it = '%1 is already entered based on the current document.';
								|pl = '%1 is already entered based on the current document.';
								|tr = 'Mevcut belge temelinde %1 zaten girildi.'");
		Common.MessageToUser(
			StrTemplate(MessageTemplate, Selection.Ref),
			Selection.Ref);
	EndIf;
	
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
