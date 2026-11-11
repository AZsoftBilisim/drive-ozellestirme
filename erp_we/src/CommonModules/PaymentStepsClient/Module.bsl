
////////////////////////////////////////////////////////////////////////////////
// The "Stages of Payment Client" module contains procedures and functions for 
// the user to work with the table of payment stages,
// notifying the user about the completion of payment stages.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ProceduresAndFunctionsForCompletingPaymentStages

// Standard handler for the " when Changing "event in the" stage graphicopaymentpayment " field.
//
// Parameters:
// CurrentData          - FormDataCollectionItem - a row with the current data of the payment stages table
// PaymentScheduleSteps     - FormDataCollection - table of payment stages
// PaymentAmountAgainstTheDocument - Number - the amount of payment for the document.
//
Procedure PaymentScheduleStepsPaymentPercentageOnChange(CurrentData, PaymentScheduleSteps, Val PaymentAmountAgainstTheDocument) Export
	
	If CurrentData.PaymentPercentage > 0 And PaymentScheduleSteps.Total("PaymentPercentage") = 100 Then
		
		PaymentAmount = 0;
		For Each CurRow In PaymentScheduleSteps Do
			If CurRow.GetID() <> CurrentData.GetID() Then
				PaymentAmount = PaymentAmount + CurRow.PaymentAmount;
			EndIf;
		EndDo;
		
		CurrentData.PaymentAmount = PaymentAmountAgainstTheDocument - PaymentAmount;
	Else
		
		CurrentData.PaymentAmount = PaymentAmountAgainstTheDocument * CurrentData.PaymentPercentage / 100;
		
	EndIf;
	
	If CurrentData.Property("AmountARAP") Then
		CurrentData.AmountARAP = 0;
	EndIf;
	
EndProcedure

// Standard event handler for " when Changing "the field" stages of payment Graphysumplayment".
//
// Parameters:
// CurrentData          - FormDataCollectionItem - a row with the current data of the payment stages table
// PaymentScheduleSteps     - FormDataCollection - table of payment stages
// PaymentAmountAgainstTheDocument - Number - the amount of payment for the document.
//
Procedure PaymentScheduleStepsPaymentAmountOnChange(CurrentData, PaymentScheduleSteps, Val PaymentAmountAgainstTheDocument) Export
	
	If PaymentAmountAgainstTheDocument <> 0 Then
		
		If CurrentData.PaymentAmount <> 0 And
			PaymentScheduleSteps.Total("PaymentAmount") = PaymentAmountAgainstTheDocument Then
			
			PaymentPercentage = 0;
			For Each CurRow In PaymentScheduleSteps Do
				If CurRow <> CurrentData Then
					PaymentPercentage = PaymentPercentage + CurRow.PaymentPercentage;
				EndIf;
			EndDo;
			
			CurrentData.PaymentPercentage = 100 - PaymentPercentage;
			
		Else
			CurrentData.PaymentPercentage = CurrentData.PaymentAmount * 100 / PaymentAmountAgainstTheDocument;
		EndIf;
	EndIf;
	
	If CurrentData.Property("AmountARAP") Then
		CurrentData.AmountARAP = 0;
	EndIf;
	
EndProcedure

// Standard event handler for "when Changing" the field "stages of Graphicoplatyprocentsalogazataru".
//
// Parameters:
// CurrentData          - FormDataCollectionItem - a row with the current data of the payment stages table
// PaymentScheduleSteps     - FormDataCollection - table of payment stages
// DepositAmountUnderTheDocument - Number - the amount of the Deposit for the container according to the document.
//
Procedure PaymentScheduleStepsPackageDepositPercentageOnChange(CurrentData, PaymentScheduleSteps, Val DepositAmountUnderTheDocument) Export
	
	If CurrentData.PackageDepositPercentage > 0 And PaymentScheduleSteps.Total("PackageDepositPercentage") = 100 Then
		
		PackageDepositValue = 0;
		For Each CurRow In PaymentScheduleSteps Do
			If CurRow.GetID() <> CurrentData.GetID() Then
				PackageDepositValue = PackageDepositValue + CurRow.PackageDepositValue;
			EndIf;
		EndDo;
		
		CurrentData.PackageDepositValue = DepositAmountUnderTheDocument - PackageDepositValue;
	Else
		
		CurrentData.PackageDepositValue = DepositAmountUnderTheDocument * CurrentData.PackageDepositPercentage / 100;
		
	EndIf;
	
	If CurrentData.Property("AmountARAP") Then
		CurrentData.AmountARAP = 0;
	EndIf;
	
EndProcedure

// Standard event handler for " when Changing "the" stages of Graphicoplatysummazalogazataru " field.
//
// Parameters:
// CurrentData          - FormDataCollectionItem - a row with the current data of the payment stages table
// PaymentScheduleSteps     - FormDataCollection - table of payment stages
// DepositAmountUnderTheDocument - Number - the amount of the Deposit for the container according to the document.
//
Procedure PaymentScheduleStepsPackageDepositValueOnChange(CurrentData, PaymentScheduleSteps, Val DepositAmountUnderTheDocument) Export
	
	If DepositAmountUnderTheDocument <> 0 Then
		
		If CurrentData.PackageDepositValue <> 0 And
			PaymentScheduleSteps.Total("PackageDepositValue") = DepositAmountUnderTheDocument Then
			
			PackageDepositPercentage = 0;
			For Each CurRow In PaymentScheduleSteps Do
				If CurRow.GetID() <> CurrentData.GetID() Then
					PackageDepositPercentage = PackageDepositPercentage + CurRow.PackageDepositPercentage;
				EndIf;
			EndDo;
			
			CurrentData.PackageDepositPercentage = 100 - PackageDepositPercentage;
			
		Else
			CurrentData.PackageDepositPercentage = CurrentData.PackageDepositValue * 100 / DepositAmountUnderTheDocument;
		EndIf;
	EndIf;
	
	If CurrentData.Property("AmountARAP") Then
		CurrentData.AmountARAP = 0;
	EndIf;
	
EndProcedure

// The standard handler of the event "Before the start of the addition" of the tabular part of the "Stages of the Payment Graph".
//
// Parameters:
// Form                 - ClientApplicationForm - The form of the document/directory.
// ParametersOfStages       - See PaymentStepsServer.ParametersForFillingInPaymentStages
// Cancel                 - Boolean - flag for refusing to add a new line.
// Copy           - Boolean - the line is copied.
// Notification            - CallbackDescription - Description of the form notification to be executed after adding a line.
//
Procedure PaymentScheduleStepsBeforeAddRow(Form, ParametersOfStages, Cancel, Copy, Notification) Export
	
	If Form.MultipleShippingDates Then
		
		Cancel = True;
		If Not Copy Then
			ParametersOfStages.Insert("Operation","Create");
		Else
			CurrentData = Form.Items.PaymentScheduleSteps.CurrentData;
			If CurrentData = Undefined Then
				Return;
			Else
				ParametersOfStages.Insert("Operation",        "Copy");
				ParametersOfStages.Insert("PaymentOption",   CurrentData.PaymentOption);
				ParametersOfStages.Insert("CalculateFrom",  CurrentData.CalculateFrom);
				ParametersOfStages.Insert("Formula",         CurrentData.Formula);
				ParametersOfStages.Insert("Move",           CurrentData.Move);
				ParametersOfStages.Insert("PaymentDate",     CurrentData.PaymentDate);
				
				PackageDepositPercentage = 0;
				PaymentPercentage      = 0;
				PackageDepositValue   = 0;
				PaymentAmount        = 0;
				
				For Each Page1 In ParametersOfStages.PaymentScheduleSteps Do
					If Page1.Move = CurrentData.Move
						And Page1.PaymentOption = CurrentData.PaymentOption
						And Page1.CalculateFrom = CurrentData.CalculateFrom
						And Page1.Formula = CurrentData.Formula Then
						
						PaymentPercentage = PaymentPercentage + Page1.PaymentPercentage;
						PaymentAmount = PaymentAmount + Page1.PaymentAmount;
						
						If ParametersOfStages.ThereIsPackage Then
							PackageDepositValue = PackageDepositValue + Page1.PackageDepositValue;
							PackageDepositPercentage = PackageDepositPercentage + Page1.PackageDepositPercentage;
						EndIf;
					EndIf;
				EndDo;
				
				ParametersOfStages.Insert("PackageDepositPercentage", PackageDepositPercentage);
				ParametersOfStages.Insert("PaymentPercentage",      PaymentPercentage);
				ParametersOfStages.Insert("PackageDepositValue",   PackageDepositValue);
				ParametersOfStages.Insert("PaymentAmount",        PaymentAmount);
			EndIf;
			
		EndIf;
		
		AdditionalParameters = CommonClient.CopyRecursive(ParametersOfStages);
		AdditionalParameters.Insert("NotificationAfterCompletion", Notification);
		AdditionalParameters.Insert("Form", Form);
		
		CurAlert = New CallbackDescription("PaymentScheduleStepsBeforeAddRowCompletion", ThisObject, AdditionalParameters);
		
		OpenForm("CommonForm.PaymentStage", ParametersOfStages, Form,,,,CurAlert,FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

// The service handler of the notification "Before the start of the addition".
Procedure PaymentScheduleStepsBeforeAddRowCompletion(Result, Parameters) Export
	
	If Result <> Undefined Then
		
		Form = Parameters.Form;
		PaymentScheduleSteps = Parameters.PaymentScheduleSteps; // ValueTable
		
		If ValueIsFilled(Result.PaymentDate) Then
			NwRw = PaymentScheduleSteps.Add();
			FillPropertyValues(NwRw,Result);
		Else
			
			ColumnName = "Sum";
			
			If Parameters.ShipmentDates.Count() > 0 Then
				If CommonClientServer.HasAttributeOrObjectProperty(Parameters.ShipmentDates[0],"PaymentAmount") Then
					ColumnName = "PaymentAmount";
				ElsIf CommonClientServer.HasAttributeOrObjectProperty(Parameters.ShipmentDates[0],"ActualAmount") Then
					ColumnName = "ActualAmount";
				EndIf;
			EndIf;
			
			AmountOfPaymentToBeDistributed_ = Result.PaymentAmount;
			PercentageOfPaymentToDistribution = Result.PaymentPercentage;
			AmountOfCollateralForDistribution = Result.PackageDepositValue;
			PercentageOfCollateralToBeDistributed = Result.PackageDepositPercentage;
			
			ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
			ParametersForFillingInPaymentDate.OrderDate                     = Parameters.OrderDate;
			ParametersForFillingInPaymentDate.ApprovalDate               = Parameters.ApprovalDate;
			ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = Parameters.DateOfTransferOfTitleToGoods;
			ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = Parameters.DeadlineOfTransferOfTitleToGoods;
			ParametersForFillingInPaymentDate.Calendar                      = Parameters.Calendar;
			
			IndexOf = 1;
			For Each Page1 In Parameters.ShipmentDates Do
				
				If Page1[ColumnName] = 0 And (Not Parameters.ThereIsPackage Or Page1.PackageDepositValue = 0) Then
					IndexOf = IndexOf + 1;
					Continue;
				EndIf;
				
				NwRw = PaymentScheduleSteps.Add();
				FillPropertyValues(NwRw,Result);
				NwRw.DateOfShipment = Page1.DateOfShipment;
				
				If IndexOf <> Parameters.ShipmentDates.Count() Then
					NwRw.PaymentAmount = Page1[ColumnName]/Parameters.PaymentAmountAgainstTheDocument * Result.PaymentAmount;
					NwRw.PaymentPercentage = Page1[ColumnName]/Parameters.PaymentAmountAgainstTheDocument * Result.PaymentPercentage;
					AmountOfPaymentToBeDistributed_ = AmountOfPaymentToBeDistributed_ - NwRw.PaymentAmount;
					PercentageOfPaymentToDistribution = PercentageOfPaymentToDistribution - NwRw.PaymentPercentage;
					
					If Parameters.ThereIsPackage Then
						NwRw.PackageDepositValue = Page1.PackageDepositValue/Parameters.DepositAmountUnderTheDocument * Result.PackageDepositValue;
						NwRw.PackageDepositPercentage = Page1.PackageDepositValue/Parameters.DepositAmountUnderTheDocument * Result.PackageDepositPercentage;
						AmountOfCollateralForDistribution = AmountOfCollateralForDistribution - Result.PackageDepositValue;
						PercentageOfCollateralToBeDistributed = PercentageOfCollateralToBeDistributed - Result.PackageDepositPercentage;
					EndIf;
				Else
					NwRw.PaymentAmount = AmountOfPaymentToBeDistributed_;
					NwRw.PaymentPercentage = PercentageOfPaymentToDistribution;
					
					If Parameters.ThereIsPackage Then
						NwRw.PackageDepositValue = AmountOfCollateralForDistribution;
						NwRw.PackageDepositPercentage = PercentageOfCollateralToBeDistributed;
					EndIf;
				EndIf;
				
				ParametersForFillingInPaymentDate.DateOfShipment  = NwRw.DateOfShipment;
				If CommonClientServer.HasAttributeOrObjectProperty(Page1,"DateAccordingToSchedule") Then
					ParametersForFillingInPaymentDate.DateOfReceipt = Page1.DateAccordingToSchedule;
				ElsIf CommonClientServer.HasAttributeOrObjectProperty(Page1,"DateOfReceipt") Then
					ParametersForFillingInPaymentDate.DateOfReceipt = Page1.DateOfReceipt;
				EndIf;
				StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
					NwRw,ParametersForFillingInPaymentDate);
				
				IndexOf = IndexOf + 1;
			EndDo;
		EndIf;
		
		Form.Modified = True;
		If CommonClientServer.HasAttributeOrObjectProperty(Form,"ThereAreManualChangesToPaymentSchedule") Then
			Form.ThereAreManualChangesToPaymentSchedule = True;
		EndIf;
		
		If Parameters.NotificationAfterCompletion <> Undefined Then
			RunCallback(Parameters.NotificationAfterCompletion, Result);
		EndIf;
		
	EndIf;
	
EndProcedure

// The standard event handler "Before deleting" the tabular part of the "Stages of the Payment Graph".
//
// Parameters:
// Form                 - ClientApplicationForm - The form of the document/directory.
// Cancel                 - Boolean - flag for refusing to add a new line.
// PaymentScheduleSteps    - ValueTable, FormDataCollection - table of payment stages.
//
Procedure PaymentScheduleStepsBeforeDeleteRow(Form, Cancel, PaymentScheduleSteps) Export
	
	CurrentData = Form.Items.PaymentScheduleSteps.CurrentData;
	
	If Form.MultipleShippingDates 
		// Depends On The Date Of Shipment
		And ValueIsFilled(CurrentData.DateOfShipment) Then
		
		Cancel = True;
		Move = CurrentData.Move;
		PaymentOption = CurrentData.PaymentOption;
		CalculateFrom = CurrentData.CalculateFrom;
		Formula = CurrentData.Formula;
		
		IndexOf = 0;
		While IndexOf < PaymentScheduleSteps.Count() Do
			String = PaymentScheduleSteps[IndexOf];
			If String.Move = Move
				And String.PaymentOption = PaymentOption
				And String.CalculateFrom = CalculateFrom
				And String.Formula = Formula Then
				PaymentScheduleSteps.Delete(IndexOf);
			Else
				IndexOf = IndexOf + 1;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// The standard handler for the event "Before the start of the change" of the tabular part of the "Stages of the Payment Graph".
//
// Parameters:
// Form                 - ClientApplicationForm - The form of the document/directory.
// ParametersOfStages       - See PaymentStepsServer.ParametersForFillingInPaymentStages
// Cancel                 - Boolean - flag for refusing to add a new line.
// Notification            - CallbackDescription - Description of the form notification to be executed after changing the line.
//
Procedure PaymentScheduleStepsBeforeRowChange(Form, ParametersOfStages, Cancel, Notification) Export
	
	If Form.MultipleShippingDates Then
		Cancel = True;
		CurrentData = Form.Items.PaymentScheduleSteps.CurrentData;
		If CurrentData = Undefined Then
			Return;
		Else
			ParametersOfStages.Insert("Operation",        "Update");
			ParametersOfStages.Insert("PaymentOption",   CurrentData.PaymentOption);
			ParametersOfStages.Insert("CalculateFrom",  CurrentData.CalculateFrom);
			ParametersOfStages.Insert("Formula",         CurrentData.Formula);
			ParametersOfStages.Insert("Move",           CurrentData.Move);
			ParametersOfStages.Insert("PaymentDate",     CurrentData.PaymentDate);
			
			ParametersOfStages.Insert("PaymentOptionBeforeChange",   CurrentData.PaymentOption);
			ParametersOfStages.Insert("OptionOfReferenceBeforeChange",  CurrentData.CalculateFrom);
			ParametersOfStages.Insert("FormulaBeforeChange",         CurrentData.Formula);
			ParametersOfStages.Insert("ShiftBeforeChange",           CurrentData.Move);
			
			PackageDepositPercentage = 0;
			PaymentPercentage      = 0;
			PackageDepositValue   = 0;
			PaymentAmount        = 0;
			
			For Each Page1 In ParametersOfStages.PaymentScheduleSteps Do
				If Page1.Move = CurrentData.Move
					And Page1.PaymentOption = CurrentData.PaymentOption
					And Page1.CalculateFrom = CurrentData.CalculateFrom
					And Page1.Formula = CurrentData.Formula Then
					PaymentPercentage = PaymentPercentage + Page1.PaymentPercentage;
					PaymentAmount = PaymentAmount + Page1.PaymentAmount;
					If ParametersOfStages.ThereIsPackage Then
						PackageDepositValue = PackageDepositValue + Page1.PackageDepositValue;
						PackageDepositPercentage = PackageDepositPercentage + Page1.PackageDepositPercentage;
					EndIf;
				EndIf;
			EndDo;
			
			ParametersOfStages.Insert("PackageDepositPercentage", PackageDepositPercentage);
			ParametersOfStages.Insert("PaymentPercentage",      PaymentPercentage);
			ParametersOfStages.Insert("PackageDepositValue",   PackageDepositValue);
			ParametersOfStages.Insert("PaymentAmount",        PaymentAmount);
		EndIf;
		
		AdditionalParameters = CommonClient.CopyRecursive(ParametersOfStages);
		AdditionalParameters.Insert("NotificationAfterCompletion", Notification);
		AdditionalParameters.Insert("Form", Form);
		
		CurAlert = New CallbackDescription("PaymentScheduleStepsBeforeRowChangeCompletion", ThisObject, AdditionalParameters);
		
		OpenForm("CommonForm.PaymentStage",ParametersOfStages, Form,,,,CurAlert,FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

// The service handler for the "Pre-Change" notification.
Procedure PaymentScheduleStepsBeforeRowChangeCompletion(Result, Parameters) Export
	
	If Result <> Undefined Then
		
		Form = Parameters.Form;
		CurrentData = Form.Items.PaymentScheduleSteps.CurrentData;
		
		// The stage does not depend on the date of shipment
		If ValueIsFilled(Result.PaymentDate) Then
			FillPropertyValues(CurrentData, Result);
			CurrentData.DateOfShipment = Date(1,1,1);
			
			// If there was a countdown option from the shipment date, then it is necessary to delete the lines of this stage from other shipment dates
			If Result.DeleteModifiedStage Then
				IndexOf = 0;
				While IndexOf < Parameters.PaymentScheduleSteps.Count() Do
					String = Parameters.PaymentScheduleSteps[IndexOf];
					If String.Move = Result.ShiftBeforeChange
						And String.PaymentOption = Result.PaymentOptionBeforeChange
						And String.CalculateFrom = Result.OptionOfReferenceBeforeChange
						And String.Formula = Result.FormulaBeforeChange Then
						Parameters.PaymentScheduleSteps.Delete(IndexOf);
					Else
						IndexOf = IndexOf + 1;
					EndIf;
				EndDo;
			EndIf;
		Else
			
			AmountOfPaymentToBeDistributed_ = Result.PaymentAmount;
			PercentageOfPaymentToDistribution = Result.PaymentPercentage;
			AmountOfCollateralForDistribution = Result.PackageDepositValue;
			PercentageOfCollateralToBeDistributed = Result.PackageDepositPercentage;
			
			IndexOf = 0;
			While IndexOf < Parameters.PaymentScheduleSteps.Count() Do
				String = Parameters.PaymentScheduleSteps[IndexOf];
				If String.Move = Result.ShiftBeforeChange
					And String.PaymentOption = Result.PaymentOptionBeforeChange
					And String.CalculateFrom = Result.OptionOfReferenceBeforeChange
					And String.Formula = Result.FormulaBeforeChange Then
					Parameters.PaymentScheduleSteps.Delete(IndexOf);
				Else
					IndexOf = IndexOf + 1;
				EndIf;
			EndDo;
			
			ColumnName = "Sum";
			
			If Parameters.ShipmentDates.Count() > 0 Then
				If CommonClientServer.HasAttributeOrObjectProperty(Parameters.ShipmentDates[0],"PaymentAmount") Then
					ColumnName = "PaymentAmount";
				ElsIf CommonClientServer.HasAttributeOrObjectProperty(Parameters.ShipmentDates[0],"ActualAmount") Then
					ColumnName = "ActualAmount";
				EndIf;
			EndIf;
			
			ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
			ParametersForFillingInPaymentDate.OrderDate                     = Parameters.OrderDate;
			ParametersForFillingInPaymentDate.ApprovalDate               = Parameters.ApprovalDate;
			ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = Parameters.DateOfTransferOfTitleToGoods;
			ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = Parameters.DeadlineOfTransferOfTitleToGoods;
			ParametersForFillingInPaymentDate.Calendar                      = Parameters.Calendar;
			
			IndexOf = 1;
			For Each Page1 In Parameters.ShipmentDates Do
				
				If Page1[ColumnName] = 0 And (Not Parameters.ThereIsPackage Or Page1.PackageDepositValue = 0) Then
					IndexOf = IndexOf + 1;
					Continue;
				EndIf;
				
				NwRw = Parameters.PaymentScheduleSteps.Add();
				FillPropertyValues(NwRw,Result);
				NwRw.DateOfShipment = Page1.DateOfShipment;
				If CommonClientServer.HasAttributeOrObjectProperty(Page1,"ExceedingOrder") Then
					NwRw.ExceedingOrder = Page1.ExceedingOrder;
				EndIf;
				
				If IndexOf <> Parameters.ShipmentDates.Count() Then
					NwRw.PaymentAmount = Page1[ColumnName]/Parameters.PaymentAmountAgainstTheDocument * Result.PaymentAmount;
					NwRw.PaymentPercentage = Page1[ColumnName]/Parameters.PaymentAmountAgainstTheDocument * Result.PaymentPercentage;
					AmountOfPaymentToBeDistributed_ = AmountOfPaymentToBeDistributed_ - NwRw.PaymentAmount;
					PercentageOfPaymentToDistribution = PercentageOfPaymentToDistribution - NwRw.PaymentPercentage;
					
					If Parameters.ThereIsPackage Then
						NwRw.PackageDepositValue = Page1.PackageDepositValue/Parameters.DepositAmountUnderTheDocument * Result.PackageDepositValue;
						NwRw.PackageDepositPercentage = Page1.PackageDepositValue/Parameters.DepositAmountUnderTheDocument * Result.PackageDepositPercentage;
						AmountOfCollateralForDistribution = AmountOfCollateralForDistribution - Result.PackageDepositValue;
						PercentageOfCollateralToBeDistributed = PercentageOfCollateralToBeDistributed - Result.PackageDepositPercentage;
					EndIf;
					
				Else
					NwRw.PaymentAmount = AmountOfPaymentToBeDistributed_;
					NwRw.PaymentPercentage = PercentageOfPaymentToDistribution;
					If Parameters.ThereIsPackage Then
						NwRw.PackageDepositValue = AmountOfCollateralForDistribution;
						NwRw.PackageDepositPercentage = PercentageOfCollateralToBeDistributed;
					EndIf;
				EndIf;
				
				ParametersForFillingInPaymentDate.DateOfShipment = NwRw.DateOfShipment;
				If CommonClientServer.HasAttributeOrObjectProperty(Page1,"DateAccordingToSchedule") Then
					ParametersForFillingInPaymentDate.DateOfReceipt = Page1.DateAccordingToSchedule;
				ElsIf CommonClientServer.HasAttributeOrObjectProperty(Page1,"DateOfReceipt") Then
					ParametersForFillingInPaymentDate.DateOfReceipt = Page1.DateOfReceipt;
				EndIf;
				StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
					NwRw,ParametersForFillingInPaymentDate);
				
				IndexOf = IndexOf + 1;
			EndDo;
		EndIf;
		
		If Result.Modified And CommonClientServer.HasAttributeOrObjectProperty(Form, "ThereAreManualChangesToPaymentSchedule") Then
			Form.ThereAreManualChangesToPaymentSchedule = True;
		EndIf;
		Form.Modified = True;
		
		If Parameters.NotificationAfterCompletion <> Undefined Then
			RunCallback(Parameters.NotificationAfterCompletion, Result);
		EndIf;
		
	EndIf;
	
EndProcedure

// The standard handler for the event "When changing" the "Shift" and "Account variant" fields.
// Fills in the payment date based on the changed offset and reference option.
//
// Parameters:
//  CurrentData                    - FormDataCollectionItem - a row with the current data of the payment stages table
//  ParametersForFillingInPaymentDate   - See PaymentStepsClientServer.PaymentDateCalculationParameters
//
Procedure StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(CurrentData, ParametersForFillingInPaymentDate) Export
	
	ParametersStructure = PaymentStepsClientServer.PaymentDateCalculationParameters();
	ParametersStructure.CalculateFrom                 = CurrentData.CalculateFrom;
	ParametersStructure.Formula                        = CurrentData.Formula;
	ParametersStructure.Move                          = CurrentData.Move;
	ParametersStructure.PaymentDate                    = CurrentData.PaymentDate;
	ParametersStructure.OrderDate                     = ParametersForFillingInPaymentDate.OrderDate;
	ParametersStructure.ApprovalDate               = ParametersForFillingInPaymentDate.ApprovalDate;
	ParametersStructure.DateOfShipment                   = ParametersForFillingInPaymentDate.DateOfShipment;
	ParametersStructure.DateOfReceipt                = ParametersForFillingInPaymentDate.DateOfReceipt;
	ParametersStructure.DateOfTransferOfTitleToGoods = ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods;
	ParametersStructure.DeadlineOfTransferOfTitleToGoods = ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods;
	ParametersStructure.Calendar                      = ParametersForFillingInPaymentDate.Calendar;
	
	If ValueIsFilled(ParametersForFillingInPaymentDate.Calendar) Then
		CurrentData.PaymentDate = PaymentStepsServerCall.PaymentDateByCalendar(ParametersStructure);
	Else
		CurrentData.PaymentDate = PaymentStepsServerCall.PaymentDateWithoutCalendar(ParametersStructure);
	EndIf;
	
	If CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FixedDate") Then
		CurrentData.Move = 0;
	EndIf;
	
	EliminateContradictionBetweenPaymentOptionAndReferenceOption(CurrentData);
	
EndProcedure

// Standard event handler for "When changing" the "Control Option" field.
//
// Parameters:
//  CurrentData                    - FormDataCollectionItem - a row with the current data of the payment stages table
//  ShiftFillParameters        - See PaymentStepsClientServer.PaymentDateCalculationParameters
//
Procedure PaymentScheduleStepsPaymentDateOnChange(CurrentData, ShiftFillParameters) Export
	
	If Not ValueIsFilled(ShiftFillParameters.ApprovalDate) Then
		ShiftFillParameters.ApprovalDate = ShiftFillParameters.OrderDate;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.CalculateFrom) Then
		Move = 0;
	Else
		
		ParametersStructure = PaymentStepsClientServer.PaymentDateCalculationParameters();
		ParametersStructure.CalculateFrom                 = CurrentData.CalculateFrom;
		ParametersStructure.Formula                        = CurrentData.Formula;
		ParametersStructure.PaymentDate                    = CurrentData.PaymentDate;
		ParametersStructure.OrderDate                     = ShiftFillParameters.OrderDate;
		ParametersStructure.ApprovalDate               = ShiftFillParameters.ApprovalDate;
		ParametersStructure.DateOfShipment                   = ShiftFillParameters.DateOfShipment;
		ParametersStructure.DateOfReceipt                = ShiftFillParameters.DateOfReceipt;
		ParametersStructure.DateOfTransferOfTitleToGoods = ShiftFillParameters.DateOfTransferOfTitleToGoods;
		ParametersStructure.DeadlineOfTransferOfTitleToGoods = ShiftFillParameters.DeadlineOfTransferOfTitleToGoods;
		ParametersStructure.Calendar                      = ShiftFillParameters.Calendar;
		
		If ValueIsFilled(ShiftFillParameters.Calendar) Then
			Move = PaymentStepsServerCall.CalendarShift(ParametersStructure);
		Else
			Move = PaymentStepsServerCall.ShiftWithoutCalendar(ParametersStructure);
		EndIf;
		
	EndIf;
	
	If Move < 0 Then
		CurrentData.Move = 0;
		
		ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
		ParametersForFillingInPaymentDate.OrderDate                     = ShiftFillParameters.OrderDate;
		ParametersForFillingInPaymentDate.ApprovalDate               = ShiftFillParameters.ApprovalDate;
		ParametersForFillingInPaymentDate.DateOfShipment                   = ShiftFillParameters.DateOfShipment;
		ParametersForFillingInPaymentDate.DateOfReceipt                = ShiftFillParameters.DateOfReceipt;
		ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = ShiftFillParameters.DateOfTransferOfTitleToGoods;
		ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = ShiftFillParameters.DeadlineOfTransferOfTitleToGoods;
		ParametersForFillingInPaymentDate.Calendar                      = ShiftFillParameters.Calendar;
		
		StagesOfPaymentScheduleShiftReferenceOptionWhenChanging(
			CurrentData, ParametersForFillingInPaymentDate);
	Else
		CurrentData.Move = Move;
	EndIf;
	
EndProcedure

// Standard event handler for "When changing" the "Control Option" field.
//
// Parameters:
//  CurrentData - FormDataCollectionItem - a row with the current data of the payment stages table
//  ParametersForFillingInPaymentDate - See PaymentStepsClientServer.PaymentDateCalculationParameters
//
Procedure StagesOfPaymentScheduleControlOptionForChanges(CurrentData,ParametersForFillingInPaymentDate) Export
	
	ReferenceOptionHasChanged = False;
	If (CurrentData.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation")
			Or CurrentData.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt")
			Or CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision")
			Or CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment")) 
		And (CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate")
			Or CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods")
			Or CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfReceipt")) Then
		CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate");
		ReferenceOptionHasChanged = True;
	ElsIf CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate") 
				And (CurrentData.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment")
					Or CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment")) Then
		CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate");
		ReferenceOptionHasChanged = True;
	EndIf;
	
	If ReferenceOptionHasChanged Then
		CurrentData.Move = 0;
		ParametersStructure = PaymentStepsClientServer.PaymentDateCalculationParameters();
		ParametersStructure.CalculateFrom                 = CurrentData.CalculateFrom;
		ParametersStructure.Formula                        = CurrentData.Formula;
		ParametersStructure.Move                          = CurrentData.Move;
		ParametersStructure.OrderDate                     = ParametersForFillingInPaymentDate.OrderDate;
		ParametersStructure.ApprovalDate               = ParametersForFillingInPaymentDate.ApprovalDate;
		ParametersStructure.DateOfShipment                   = ParametersForFillingInPaymentDate.DateOfShipment;
		ParametersStructure.DateOfReceipt                = ParametersForFillingInPaymentDate.DateOfReceipt;
		ParametersStructure.DateOfTransferOfTitleToGoods = ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods;
		ParametersStructure.DeadlineOfTransferOfTitleToGoods = ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods;
		ParametersStructure.Calendar                      = ParametersForFillingInPaymentDate.Calendar;
		
		If ValueIsFilled(ParametersForFillingInPaymentDate.Calendar) Then
			CurrentData.PaymentDate = PaymentStepsServerCall.PaymentDateByCalendar(ParametersStructure);
		Else
			CurrentData.PaymentDate = PaymentStepsServerCall.PaymentDateWithoutCalendar(ParametersStructure);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresForNotifyingUserOfCompletedActions

// Displays a notification to the user when the payment schedule stages are completed.
//
Procedure NotifyEndOfFillingInStagesOfPaymentSchedule() Export

	ShowUserNotification(
		NStr("vi = 'Đã điền giai đoạn thanh toán';
			|ru = 'Этапы оплаты заполнены';
			|en = 'Payment milestones are filled in'; fa = 'Payment milestones are filled in';
			|it = 'Fasi del pagamento compilate';
			|pl = 'Etapy płatności są wypełnione';
			|tr = 'Ödeme aşamaları dolduruldu'"),
		,
		NStr("vi = 'Đã điền giai đoạn lịch thanh toán';
			|ru = 'Этапы графика оплаты заполнены';
			|en = 'Payment milestones are set'; fa = 'Payment milestones are set';
			|it = 'Fasi del grafico di pagamento compilate';
			|pl = 'Etapy harmonogramu płatności są wypełniane';
			|tr = 'Ödeme planı aşamaları dolduruldu'"),
		PictureLib.Information32);

EndProcedure

// Displays a notification to the user that the payment schedule stages cannot be filled in.
//
Procedure NotifyAboutImpossibilityOfFillingInStagesOfPaymentSchedule() Export

	ShowUserNotification(
		NStr("vi = 'Đã xóa các giai đoạn thanh toán';
			|ru = 'Этапы оплаты очищены';
			|en = 'Payment milestones are cleared'; fa = 'Payment milestones are cleared';
			|it = 'Fasi di pagamento sono eliminate';
			|pl = 'Kroki płatności wyczyszczone';
			|tr = 'Ödeme aşamaları temizlendi'"),
		,
		NStr("vi = 'Số tiền tại các dòng chưa hủy của đơn hàng bằng 0. Đã xóa bảng giai đoạn thanh toán';
			|ru = 'Сумма неотмененных строк заказа нулевая. Таблица этапов оплаты очищена';
			|en = 'Amount of uncanceled order lines is zero. Table of payment milestones is cleared'; fa = 'Amount of uncanceled order lines is zero. Table of payment milestones is cleared';
			|it = 'L''importo delle righe dell''ordine non annullate è zero. Tabella dei passaggi di pagamento deselezionata';
			|pl = 'Liczba nieusuniętych linii zamówienia wynosi zero. Tabela kroków płatności została wyczyszczona';
			|tr = 'İptal edilmemiş sipariş satırlarının tutarı sıfırdır. Ödeme aşamaları tablosu temizlendi'"),
		PictureLib.Information32);

EndProcedure

#EndRegion

//@skip-check export-procedure-missing-comment
Procedure AskQuestionAboutResettingScheduleONChangesInShippingDate(Form, CallbackDescription, Cancel) Export 
	
	ThereAreOptionsFromDateOfShipment = PaymentStepsServerCall.InStageTableThereAreStagesFromDateOfShipment(Form.Object.PaymentScheduleSteps);
	
	If ThereAreOptionsFromDateOfShipment Then
		
		AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
		ParametersArray = AugmentedMechanismParameters.ParametersArray;
		
		For Each ParametersStructure In ParametersArray Do
			If ParametersStructure.SeveralShippingDatesHaveChanged Then
				
				If ParametersStructure.ThereAreManualChangesToPaymentSchedule Then
					Cancel = True;
					AdditionalParameters = New Structure;
					AdditionalParameters.Insert("Form", Form);
					AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
					ShowQueryBox(
						CallbackDescription,
						NStr("vi = 'Đã thay đổi ngày dự tính giao hàng, điền lại lịch thanh toán theo mặc định?';
							|ru = 'Были изменены плановые даты отгрузки, перезаполнить график оплат по умолчанию?';
							|en = 'Scheduled shipment dates were changed. Do you want to refill the default payment schedule?'; fa = 'Scheduled shipment dates were changed. Do you want to refill the default payment schedule?';
							|it = 'Были изменены плановые даты отгрузки, перезаполнить график оплат по умолчанию?';
							|pl = 'Scheduled shipment dates were changed. Do you want to refill the default payment schedule?';
							|tr = 'Planlanan sevkiyat tarihleri değiştirildi, varsayılan ödeme planını yeniden doldur?'"),
						QuestionDialogMode.YesNo);
				Else
					Cancel = True;
					RunCallback(CallbackDescription, DialogReturnCode.Yes);
				EndIf;
				
				Break;
			EndIf;
		EndDo;
	EndIf;

EndProcedure

// Eliminate the contradiction between the payment option and the reference option.
// 
// Parameters:
//  CurrentData - FormDataCollectionItem, ValueTableRow - Current data
Procedure EliminateContradictionBetweenPaymentOptionAndReferenceOption(CurrentData) Export
	If (CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision")
			Or CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment")
			Or CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.EmptyRef")) 
		And (CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate")
			Or CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods")) Then
		CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment");
	ElsIf (CurrentData.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation")
			Or CurrentData.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt")
			Or CurrentData.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.EmptyRef")) 
		And (CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate")
			Or CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods")
			Or CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfReceipt")) Then
		CurrentData.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment");
	ElsIf CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate") 
				And (CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment")
					Or CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.EmptyRef")) Then
		CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment");
	ElsIf CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate") 
				And (CurrentData.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment")
					Or CurrentData.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.EmptyRef")) Then
		CurrentData.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt");
	EndIf;
EndProcedure

#EndRegion
