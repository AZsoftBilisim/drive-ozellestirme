
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	PayrollPayment.Load(GetFromTempStorage(Parameters.AddressPayrollInVault));
	
	Statement = Parameters.Statement;
	DocumentPayments = Parameters.DocumentPayments;
	Organization = Parameters.Organization;
	

	//++ WE
	UsePayrollAccrualZIKWE = GetFunctionalOption("PayrollAndHumanResourcesWE");
	If UsePayrollAccrualZIKWE Then
		Query = New Query("
		|SELECT DISTINCT
		|	Content.Individual
		|FROM
		|	Document.PayrollStatementHR.Content AS Content
		|WHERE
		|	Content.Ref = &Statement
		|");
		Query.SetParameter("Statement", Statement);
		
		Employees_Array = Query.Execute().Unload().UnloadColumn("Individual");
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Ref", New FixedArray(Employees_Array)));
		
		Items.PaymentOfWagesByEmployee.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
		InstructionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Cho phép để thêm cá nhân từ chứng từ %1.';
				|ru = 'Доступны для добавления физические лица из документа %1.';
				|en = 'Persons from document %1 are available for adding.'; fa = 'Persons from document %1 are available for adding.';
				|it = 'Persons from document %1 are available for adding.';
				|pl = 'Persons from document %1 are available for adding.';
				|tr = '%1Belgedeki gerçek kişiler eklenebilir.'"),
			Statement);
			
		Items.DecorationInstructions.Title = InstructionText;
		Items.DecorationInstructions.Visible = True;
		Items.PayrollPaymentFillInByBalance.Visible = Not UsePayrollAccrualZIKWE;
		Items.PayrollPaymentSum.ReadOnly = True;
		
	EndIf;
	//-- WE
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If Modified Then
		CallbackDescription = New CallbackDescription("TransferData_Completion", ThisForm, New Structure("Cancel", Cancel));
		ShowQueryBox(CallbackDescription, NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
												|ru = 'Данные были изменены. Сохранить изменения?';
												|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
												|it = 'I dati sono stati modificati. Salvare le modifiche?';
												|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
												|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'"), QuestionDialogMode.YesNoCancel);
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure TransferData_Completion(QuestionResult, AdditionalParameters) Export
	
	Cancel = AdditionalParameters.Cancel;
	
	Response = QuestionResult;
	If Response = DialogReturnCode.Yes Then
		TransferData_(Cancel);
	ElsIf Response = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPayrollPayment

&AtClient
Procedure PaymentOfWagesByEmployeeOnChange(Item)
	
	
	Return // in ut empty
	
EndProcedure

&AtClient
Procedure PayrollPaymentOnChange(Item)
	FormModified = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInByBalance(Command)


	Return;
	
EndProcedure


&AtClient
Procedure WriteAndClose(Command)
	
	TransferData_();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Modified = False;
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure TransferData_(Cancel = False)
	
	ClearMessages();
	
	ListOfPaymentRecipients = New ValueList;
	For IndexOf = 0 To PayrollPayment.Count() - 1 Do
		
		String = PayrollPayment[IndexOf];
		
		If Not ValueIsFilled(String.Individual) Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong dòng %1 chưa điền nhân viên.';
					|ru = 'В строке %1 не заполнен сотрудник.';
					|en = 'Employee is not populated in line %1.'; fa = 'Employee is not populated in line %1.';
					|it = 'Employee is not populated in line %1.';
					|pl = 'Employee is not populated in line %1.';
					|tr = '%1satırında çalışan doldurulmadı.'"),
				IndexOf + 1);
			CommonClientServer.MessageToUser(
					Text,
					,
					CommonClientServer.PathToTabularSection("PayrollPayment", IndexOf + 1, "Individual"),
					,
					Cancel);
		EndIf;
		
		If Not ValueIsFilled(String.Sum) Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong dòng %1 chưa điền số tiền.';
					|ru = 'В строке %1 не заполнена сумма.';
					|en = 'Amount is not populated in line %1.'; fa = 'Amount is not populated in line %1.';
					|it = 'Amount is not populated in line %1.';
					|pl = 'Amount is not populated in line %1.';
					|tr = '%1satırında tutar doldurulmadı'"),
				IndexOf + 1);
			CommonClientServer.MessageToUser(
				Text,
				,
				CommonClientServer.PathToTabularSection("PayrollPayment", IndexOf + 1, "Sum"),
				,
				Cancel);
		EndIf;
		
	EndDo;
	
	If Not Cancel Then
		Modified = False;
		NotifyChoice(PlacePayrollPaymentInVault());
	EndIf;
	
EndProcedure

&AtServer
Function PlacePayrollPaymentInVault()
	
	Return PutToTempStorage(PayrollPayment.Unload());
	
EndFunction


#EndRegion

#EndRegion
