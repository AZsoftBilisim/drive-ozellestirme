
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisObject,Parameters,,"ReadOnly,CloseOnChoice,CloseOnOwnerClose,PurposeUseKey");
	
	SetConditionalAppearance();
	
	ThereIsPackage = DepositAmountUnderTheDocument <> 0;
	If Operation = "Create" Then
		If Not ValueIsFilled(PaymentOption) Then
			PaymentOption = ?(TheseAreSettlementsWithCustomers,
				Enums.CustomerPaymentControlOptions.CreditPlanned,
				Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt);
		EndIf;
		If Not ValueIsFilled(CalculateFrom) Then
			CalculateFrom = Enums.PaymentDateCalculationOptions.FromOrderDate;
			PaymentDate = OrderDate;
		EndIf;
	EndIf;
	
	If ThisIsContract Then
		Items.CalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate, NStr("vi = 'từ ngày hợp đồng';
																									|ru = 'от даты договора';
																									|en = 'from contract date'; fa = 'from contract date';
																									|it = 'dalla data dell''accordo';
																									|pl = 'od daty umowy';
																									|tr = 'sözleşme tarihinden'"));
	Else
		Items.CalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate);
		If GetFunctionalOption("NotBaseVersion") Then
			Items.CalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromApprovalDate);
		EndIf;
	EndIf;
	Items.CalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
	Items.CalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromShipmentDate);
	If TheseAreSettlementsWithCustomers
		And GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0") Then
		Items.CalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods);
	EndIf;
	If Not TheseAreSettlementsWithCustomers Then
		Items.CalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfReceipt);
	EndIf;
	Items.CalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FixedDate);
	Items.CalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.Formula);
	
	If TheseAreSettlementsWithCustomers Then
		If Not ThisIsContract Then
			Items.PaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeProvision);
		EndIf;
		Items.PaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment);
		Items.PaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.CreditAfterShipment);
		Items.PaymentOption.ChoiceList.Add(Enums.CustomerPaymentControlOptions.CreditPlanned);
	Else
		If Not ThisIsContract Then
			Items.PaymentOption.ChoiceList.Add(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation);
		EndIf;
		Items.PaymentOption.ChoiceList.Add(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt);
		Items.PaymentOption.ChoiceList.Add(Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment);
		Items.PaymentOption.ChoiceList.Add(Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt);
	EndIf;
	
	SetItemsVisibility();
	
	InitialVersionOfReferenceDependsOnDateOfShipment = PaymentStepsCached.StringOfStagesDependsOnDateOfShipment(CalculateFrom, Formula);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MoveOnChange(Item)
	
	Data_Stage = New Structure;
	Data_Stage.Insert("PaymentDate",    PaymentDate);
	Data_Stage.Insert("Move",          Move);
	Data_Stage.Insert("CalculateFrom", CalculateFrom);
	Data_Stage.Insert("PaymentOption",  PaymentOption);
	Data_Stage.Insert("Formula",        Formula);
	
	PaymentDateCalculationParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
	PaymentDateCalculationParameters.OrderDate                     = OrderDate;
	PaymentDateCalculationParameters.ApprovalDate               = ApprovalDate;
	PaymentDateCalculationParameters.DateOfShipment                   = Date(1,1,1);
	PaymentDateCalculationParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	PaymentDateCalculationParameters.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	PaymentDateCalculationParameters.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		Data_Stage,PaymentDateCalculationParameters);
	
	PaymentDate = Data_Stage.PaymentDate;
	PaymentOption = Data_Stage.PaymentOption;
	
EndProcedure

&AtClient
Procedure CalculateFromOnChange(Item)
	
	If CalculateFrom <> PredefinedValue("Enum.PaymentDateCalculationOptions.Formula") Then
		Formula = Undefined;
		
		Data_Stage = New Structure;
		Data_Stage.Insert("PaymentDate",    PaymentDate);
		Data_Stage.Insert("Move",          Move);
		Data_Stage.Insert("CalculateFrom", CalculateFrom);
		Data_Stage.Insert("PaymentOption",  PaymentOption);
		Data_Stage.Insert("Formula",        Formula);
		
		//This element is only available for reference options that do not depend on the date of shipment
		PaymentDateCalculationParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
		PaymentDateCalculationParameters.OrderDate                     = OrderDate;
		PaymentDateCalculationParameters.ApprovalDate               = ApprovalDate;
		PaymentDateCalculationParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
		PaymentDateCalculationParameters.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
		PaymentDateCalculationParameters.Calendar                      = Calendar;
		
		PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
			Data_Stage,PaymentDateCalculationParameters);
		
		PaymentDate = Data_Stage.PaymentDate;
		PaymentOption = Data_Stage.PaymentOption;
	EndIf;
	
	If CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FixedDate") Then
		Move = 0;
	EndIf;
	
	SetItemsVisibility();
	
EndProcedure

&AtClient
Procedure FormulaOnChange(Item)
	
	Data_Stage = New Structure;
	Data_Stage.Insert("PaymentDate",    PaymentDate);
	Data_Stage.Insert("Move",          Move);
	Data_Stage.Insert("CalculateFrom", CalculateFrom);
	Data_Stage.Insert("PaymentOption",  PaymentOption);
	Data_Stage.Insert("Formula",        Formula);
	
	//This element is only available for reference options that do not depend on the date of shipment
	PaymentDateCalculationParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
	PaymentDateCalculationParameters.OrderDate                     = OrderDate;
	PaymentDateCalculationParameters.ApprovalDate               = ApprovalDate;
	PaymentDateCalculationParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	PaymentDateCalculationParameters.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	PaymentDateCalculationParameters.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
		Data_Stage,PaymentDateCalculationParameters);
	
	PaymentDate = Data_Stage.PaymentDate;
	PaymentOption = Data_Stage.PaymentOption;
	
	SetItemsVisibility();
	
EndProcedure

&AtClient
Procedure PaymentDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromOrderDate")
		And PaymentDate < OrderDate Then
		PaymentDate = OrderDate;
	ElsIf CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromApprovalDate")
		And ValueIsFilled(ApprovalDate) And PaymentDate < ApprovalDate Then
		PaymentDate = ApprovalDate;  
	ElsIf CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromApprovalDate")
		And Not ValueIsFilled(ApprovalDate) And PaymentDate < OrderDate Then
		PaymentDate = OrderDate;
	EndIf;
	
	Structure = New Structure;
	Structure.Insert("PaymentDate",    PaymentDate);
	Structure.Insert("Move",          Move);
	Structure.Insert("CalculateFrom", CalculateFrom);
	Structure.Insert("PaymentOption",  PaymentOption);
	Structure.Insert("Formula",        Formula);
	
	ShiftFillParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ShiftFillParameters.OrderDate                     = OrderDate;
	ShiftFillParameters.ApprovalDate               = ApprovalDate;
	ShiftFillParameters.DateOfShipment                   = Date(1,1,1);
	ShiftFillParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ShiftFillParameters.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ShiftFillParameters.Calendar                      = Calendar;
	
	PaymentStepsClient.PaymentScheduleStepsPaymentDateOnChange(
		Structure,ShiftFillParameters);
	
	Move = Structure.Move;
	
EndProcedure

&AtClient
Procedure PaymentPercentageOnChange(Item)
	PaymentAmount = PaymentAmountAgainstTheDocument * PaymentPercentage / 100;
EndProcedure

&AtClient
Procedure PackageDepositPercentageOnChange(Item)
	PackageDepositValue = DepositAmountUnderTheDocument * PackageDepositPercentage / 100;
EndProcedure

&AtClient
Procedure PaymentAmountOnChange(Item)
	PaymentPercentage = ?(PaymentAmountAgainstTheDocument = 0, 0, PaymentAmount / PaymentAmountAgainstTheDocument * 100);
EndProcedure

&AtClient
Procedure PackageDepositValueOnChange(Item)
	PackageDepositPercentage = PackageDepositValue / DepositAmountUnderTheDocument * 100;
EndProcedure

&AtClient
Procedure PaymentOptionOnChange(Item)
	
	Data_Stage = New Structure;
	Data_Stage.Insert("PaymentDate",    PaymentDate);
	Data_Stage.Insert("Move",          Move);
	Data_Stage.Insert("CalculateFrom", CalculateFrom);
	Data_Stage.Insert("PaymentOption",  PaymentOption);
	Data_Stage.Insert("Formula",        Formula);
	
	ShiftFillParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ShiftFillParameters.OrderDate                     = OrderDate;
	ShiftFillParameters.ApprovalDate               = ApprovalDate;
	ShiftFillParameters.DateOfShipment                   = Date(1,1,1);
	ShiftFillParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
	ShiftFillParameters.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
	ShiftFillParameters.Calendar                      = Calendar;
	
	PaymentStepsClient.StagesOfPaymentScheduleControlOptionForChanges(Data_Stage,ShiftFillParameters);
	
	PaymentDate = Data_Stage.PaymentDate;
	CalculateFrom = Data_Stage.CalculateFrom;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

&AtClient
Procedure MoveTo_(Command)
	ClearMessages();
	
	ResultStructure1 = New Structure;
	ResultStructure1.Insert("PaymentOption",         PaymentOption);
	If Not ReferenceOptionDependsOnDateOfShipment() Then
		
		If Not ValueIsFilled(PaymentDate) Then
			CommonClient.MessageToUser(NStr("ru = 'Не заполнена дата платежа.';
											|vi = 'The payment date is not filled.';
											|en = 'The payment date is not filled.'; fa = 'The payment date is not filled.';
											|it = 'The payment date is not filled.';
											|pl = 'The payment date is not filled.';
											|tr = 'Ödeme tarihi doldurulmadı.'"),,"PaymentDate");
			Return;
		EndIf;
		
		ResultStructure1.Insert("PaymentDate",           PaymentDate);
		ResultStructure1.Insert("DeleteModifiedStage", InitialVersionOfReferenceDependsOnDateOfShipment);
		
	Else
		ResultStructure1.Insert("PaymentDate",           Date(1,1,1));
	EndIf;
	ResultStructure1.Insert("PaymentPercentage",        PaymentPercentage);
	ResultStructure1.Insert("PaymentAmount",          PaymentAmount);
	ResultStructure1.Insert("CalculateFrom",        CalculateFrom);
	ResultStructure1.Insert("Formula",               Formula);
	ResultStructure1.Insert("Move",                 Move);
	ResultStructure1.Insert("PackageDepositValue",     PackageDepositValue);
	ResultStructure1.Insert("PackageDepositPercentage",   PackageDepositPercentage);
	
	If Operation = "Update" Then
		ResultStructure1.Insert("PaymentOptionBeforeChange",         PaymentOptionBeforeChange);
		ResultStructure1.Insert("OptionOfReferenceBeforeChange",        OptionOfReferenceBeforeChange);
		ResultStructure1.Insert("FormulaBeforeChange",               FormulaBeforeChange);
		ResultStructure1.Insert("ShiftBeforeChange",                 ShiftBeforeChange);
	EndIf;
	
	ResultStructure1.Insert("Modified", Modified);
	
	Close(ResultStructure1);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetItemsVisibility()
	
	Items.PaymentDate.Visible = Not PaymentStepsCached.StringOfStagesDependsOnDateOfShipment(CalculateFrom, Formula);
		
	// Conversion from the payment date to the offset is not available for the formula
	Items.PaymentDate.ReadOnly = CalculateFrom = Enums.PaymentDateCalculationOptions.Formula;
	Items.Formula.Visible = CalculateFrom = Enums.PaymentDateCalculationOptions.Formula;
	Items.Move.Visible = CalculateFrom <> Enums.PaymentDateCalculationOptions.FixedDate;
	If Not Items.Move.Visible Then
		Move = 0;
	EndIf;
	
	If Not Items.PaymentDate.Visible Then
		PaymentDate = Date(1,1,1);
	EndIf;
	
	Items.PackageDepositValue.Visible = ThereIsPackage;
	Items.PackageDepositPercentage.Visible = ThereIsPackage;
	Items.CurrencyOfPledgePerContainer.Visible = ThereIsPackage;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CalculateFrom.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CalculateFrom");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PaymentDateCalculationOptions.FromOrderDate;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'từ ngày hợp đồng';
													|ru = 'от даты договора';
													|en = 'from contract date'; fa = 'from contract date';
													|it = 'dalla data dell''accordo';
													|pl = 'od daty umowy';
													|tr = 'sözleşme tarihinden'"));
	
EndProcedure

&AtServer
Function ReferenceOptionDependsOnDateOfShipment()
	Return PaymentStepsCached.StringOfStagesDependsOnDateOfShipment(CalculateFrom,Formula);
EndFunction

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
	If Item.Name = "sh_ShamsiInput_F_PaymentDate" Then
		PaymentDateOnChange(Items.PaymentDate);
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
