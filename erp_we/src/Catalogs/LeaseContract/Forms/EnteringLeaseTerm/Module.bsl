
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	LeaseStartDate = Parameters.LeaseStartDate;
	TermYears = Parameters.TermYears;
	TermMonths = Parameters.TermMonths;
	TermDays = Parameters.TermDays;
	
	FillInEndDate(ThisObject);
	
	If ReadOnly Then
		Items.BasementDecoration.Visible = False;
		Items.FooterText.Visible = False;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If TermYears = 0 And TermMonths = 0 And TermDays = 0 Then
		MessageText = NStr("vi = 'Chưa chỉ ra thời hạn thuê (số năm, tháng hoặc ngày)';
							|ru = 'Не указан срок аренды (количество лет, месяцев или дней)';
							|en = 'The rental period is not specified (number of years, months or days)'; fa = 'The rental period is not specified (number of years, months or days)';
							|it = 'Periodo di affitto non indicato (quantità anni, mesi o giorni)';
							|pl = 'Nie podano okresu dzierżawy (ilość lat, miesięcy lub dni)';
							|tr = 'Kira süresi (yıl, ay veya gün sayısı) belirtilmemiş'");
		Common.MessageToUser(MessageText,,,, Cancel);
	EndIf;

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndCloseOnClient", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit, WarningText);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LeaseStartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	FillInLeaseTerm(ThisObject);
EndProcedure

&AtClient
Procedure RentalEndDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	FillInLeaseTerm(ThisObject);
EndProcedure

&AtClient
Procedure TermYearsOnChange(Item)
	FillInEndDate(ThisObject);
EndProcedure

&AtClient
Procedure TermMonthsOnChange(Item)
	FillInEndDate(ThisObject);
EndProcedure

&AtClient
Procedure TermDaysOnChange(Item)
	FillInEndDate(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	FinishEditingAndClose();
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure FillInEndDate(Form)
	
	Form.RentalEndDate = NonCurrentAssetsClientServer.EndDateByDeadline(
		Form.LeaseStartDate, Form.TermYears, Form.TermMonths, Form.TermDays);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInLeaseTerm(Form)
	
	NonCurrentAssetsClientServer.CalculateTermByPeriod(
		Form.LeaseStartDate, Form.RentalEndDate, Form.TermYears, Form.TermMonths, Form.TermDays);
	
EndProcedure

&AtClient
Procedure WriteAndCloseOnClient(Result, AdditionalParameters) Export 
	
	FinishEditingAndClose();
	
EndProcedure

&AtClient
Procedure FinishEditingAndClose()
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
			
	ClosingResult = New Structure;
	ClosingResult.Insert("TermYears", TermYears);
	ClosingResult.Insert("TermMonths", TermMonths);
	ClosingResult.Insert("TermDays", TermDays);
	ClosingResult.Insert("LeaseStartDate", LeaseStartDate);
	
	Modified = False;
	
	Close(ClosingResult);
	
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
	If Item.Name = "sh_ShamsiInput_F_LeaseStartDate" Then
		LeaseStartDateOnChange(Items.LeaseStartDate);
	ElsIf Item.Name = "sh_ShamsiInput_F_RentalEndDate" Then
		RentalEndDateOnChange(Items.RentalEndDate);
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
